import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // IMPORT Firebase Messaging

// Enum to represent the user's authentication state.
// The password/key setup state is no longer needed.
enum AuthState { unknown, unauthenticated, authenticated }

/// Manages all authentication and session operations for the user.
/// This version uses FCM push notifications as the core mechanism for consent.
class AuthService extends ChangeNotifier {
  // --- Core Service Dependencies ---
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Dio _dio = Dio();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance; // Instance of FCM

  // --- Configuration ---
  final String _clientId = dotenv.env['FAYDA_CLIENT_ID']!;
  final String _authorizationEndpoint = dotenv.env['FAYDA_AUTHORIZATION_ENDPOINT']!;
  final String _tokenEndpoint = dotenv.env['FAYDA_TOKEN_ENDPOINT']!;
  final String _mobileRedirectUrl = dotenv.env['FAYDA_MOBILE_REDIRECT_URI']!;
  final List<String> _scopes = dotenv.env['FAYDA_SCOPES']!.split(' ');
  final String _bffBaseUrl = dotenv.env['BFF_BASE_URL']!;

  // --- State ---
  AuthState _authState = AuthState.unknown;
  AuthState get authState => _authState;
  String? _appSessionToken;
  String? get appSessionToken => _appSessionToken;

  AuthService() {
    initAuth();
  }

  /// Called on app startup to determine the auth state from secure storage.
  Future<void> initAuth() async {
    try {
      final storedToken = await _secureStorage.read(key: 'app_session_token');
      if (storedToken != null && storedToken.isNotEmpty) {
        _appSessionToken = storedToken;
        _authState = AuthState.authenticated;
      } else {
        _appSessionToken = null;
        _authState = AuthState.unauthenticated;
      }
    } catch (e) {
      _appSessionToken = null;
      _authState = AuthState.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  /// The canonical OIDC login flow for a mobile app with a BFF.
  Future<void> login() async {
    try {
      final AuthorizationResponse? result = await _appAuth.authorize(
        AuthorizationRequest(
          _clientId,
          _mobileRedirectUrl,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: _authorizationEndpoint,
            tokenEndpoint: _tokenEndpoint,
          ),
          scopes: _scopes,
          promptValues: ['login'],
        ),
      );

      if (result?.authorizationCode != null && result?.codeVerifier != null) {
        await _exchangeCodeWithBackend(result!.authorizationCode!, result.codeVerifier!);
      } else {
        throw Exception('OIDC login process was cancelled by the user.');
      }
    } catch (e) {
      _authState = AuthState.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  /// Sends the authorization code to our backend to exchange it for an app session token.
  Future<void> _exchangeCodeWithBackend(String code, String verifier) async {
    try {
      final response = await _dio.post(
        '$_bffBaseUrl/v1/api/mobile/auth/token',
        data: {
          'authorizationCode': code,
          'codeVerifier': verifier,
        },
      );

      if (response.statusCode == 200) {
        _appSessionToken = response.data['sessionToken'];
        // The backend now tells us if we need to register the FCM token.
        final bool needsFcmTokenSetup = response.data['needsFcmTokenSetup'];

        await _secureStorage.write(key: 'app_session_token', value: _appSessionToken);

        // If it's the first login on this device, or the token was previously
        // cleared, register the new FCM token.
        if (needsFcmTokenSetup) {
          await _registerDeviceForPushNotifications();
        }

        _authState = AuthState.authenticated;
        notifyListeners();
      } else {
        throw Exception('Backend token verification failed.');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Backend verification failed');
    }
  }

  /// NEW METHOD: Replaces the key generation logic with FCM token registration.
  Future<void> _registerDeviceForPushNotifications() async {
    print("AuthService: Registering device for push notifications...");
    try {
      // 1. Request permission from the user for notifications
      NotificationSettings settings = await _fcm.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Get the device's unique FCM token
        final String? fcmToken = await _fcm.getToken();

        if (fcmToken != null) {
          print("AuthService: Got FCM Token, sending to backend.");
          // 3. Send this token to your backend to associate it with the logged-in user
          await _dio.post(
            '$_bffBaseUrl/v1/api/mobile/users/register-push-token',
            data: { 'token': fcmToken },
            options: Options(headers: {'Authorization': 'Bearer $_appSessionToken'}),
          );
          print("AuthService: FCM Token registration complete.");
        } else {
          print("AuthService: Could not get FCM token from Firebase.");
        }
      } else {
        print("AuthService: User did not grant notification permission.");
      }
    } catch (e) {
      // Log the error but don't crash the login flow.
      // The user can still use the app, they just won't get notifications.
      print("AuthService: Error during push notification setup: $e");
    }
  }

  /// The 'signConsentToken' method is NO LONGER NEEDED with this architecture.
  /// The user's action (tapping "Approve" on the notification) is the consent.
  /// The `ApiService` will now have a much simpler `respondToRequest` method.

  /// Clears all stored session data from the device and logs the user out.
  Future<void> logout() async {
    // TODO: Optionally, call a backend endpoint to clear the FCM token
    // for this user before deleting local data.
    await _secureStorage.deleteAll();
    _appSessionToken = null;
    _authState = AuthState.unauthenticated;
    notifyListeners();
  }
}