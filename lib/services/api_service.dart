import 'package:addis_information_highway_mobile/models/data_request.dart';
import 'package:addis_information_highway_mobile/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A service dedicated to making authenticated API calls to the backend.
/// It relies on an `AuthService` instance to get the current session token,
/// which is automatically added to every request by the AuthInterceptor.
class ApiService {
  final Dio _dio;
  final AuthService _authService;
  final String _baseUrl = dotenv.env['BFF_BASE_URL']!;

  ApiService(this._authService) : _dio = Dio() {
    // Add the custom interceptor to the Dio instance upon creation.
    _dio.interceptors.add(AuthInterceptor(_authService, _dio));
  }

  /// Registers the device's unique push token with the backend.
  /// This is called by the AuthService during the initial login for a new device.
  Future<void> registerPushToken(String token) async {
    try {
      // Corrected API Path
      await _dio.post(
        '$_baseUrl/api/v1/mobile/users/register-push-token',
        data: {'token': token},
      );
      print('ApiService: Push token registered successfully with backend.');
    } on DioException catch (e) {
      // Don't throw a fatal error that would crash the login flow.
      // The user can still use the app without notifications. Just log the error.
      print('ApiService: Failed to register push token: ${_handleDioError(e, "Unknown error")}');
    }
  }

  /// Fetches all data requests (pending and historical) for the logged-in user.
  Future<List<DataRequest>> fetchDataRequests() async {
    try {
      // Corrected API Path
      final response = await _dio.get('$_baseUrl/v1/api/mobile/requests');
      return (response.data as List)
          .map((json) => DataRequest.fromJson(json))
          .toList();
    } on DioException catch (e) {
      // Provide more specific error messages to the UI.
      throw _handleDioError(e, 'Failed to fetch data requests');
    }
  }

  /// Responds to a data request with either 'APPROVE' or 'DENY'.
  /// In the FCM-based flow, no client-side signing is needed. The authenticated
  /// API call itself is the proof of the user's action on their registered device.
  Future<String> respondToRequest(String requestId, String action) async {
    try {
      // UPDATED AND SIMPLIFIED: The `consentToken` is no longer needed.
      // We only send the action.
      final response = await _dio.post(
        '$_baseUrl/v1/api/mobile/requests/$requestId/respond',
        data: {
          'action': action,
        },
      );
      return response.data['message'] as String;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to respond to request');
    }
  }

  /// A helper to create more user-friendly error messages from Dio exceptions.
  String _handleDioError(DioException e, String defaultMessage) {
    if (e.response != null && e.response!.data is Map) {
      // Attempt to get a specific error message from the backend response.
      return e.response!.data['error'] ?? defaultMessage;
    }
    // Fallback to the generic Dio error message.
    return e.message ?? defaultMessage;
  }
}

/// A custom Dio interceptor to automatically add the Authorization header
/// to every outgoing request. This keeps the API methods clean.
class AuthInterceptor extends Interceptor {
  final AuthService authService;
  final Dio dio;

  AuthInterceptor(this.authService, this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Get the current session token from the AuthService.
    final token = authService.appSessionToken;

    // If a token exists, add it to the request header.
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Continue with the request.
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Optional: Advanced logic to handle 401 Unauthorized errors.
    // If the backend rejects our session token, it means it has expired or is invalid.
    // The most robust action is to log the user out, forcing them to re-authenticate.
    if (err.response?.statusCode == 401) {
      print('AuthInterceptor: Received 401 Unauthorized. Forcing logout.');
      // Defer the logout to a microtask to avoid issues with widget build cycles.
      Future.microtask(() => authService.logout());
    }
    return handler.next(err);
  }
}