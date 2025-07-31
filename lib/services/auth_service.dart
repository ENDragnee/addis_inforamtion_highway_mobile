import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart'; // Import the new package

// Enum to represent the user's authentication state
enum AuthState { unknown, unauthenticated, authenticated, needsSetup }

/// Manages all authentication, session, and cryptographic operations for the user.
class AuthService extends ChangeNotifier {
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Dio _dio = Dio();

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

  // Called on app startup to determine the auth state
  Future<void> initAuth() async {
    final storedToken = await _secureStorage.read(key: 'app_session_token');

    // In a real app, you'd verify if the token is still valid by making a call
    // to a protected endpoint on your backend. For this example, we check for presence.
    if (storedToken != null) {
      _appSessionToken = storedToken;
      _authState = AuthState.authenticated;
    } else {
      _authState = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  // Full OIDC login flow
  Future<void> login() async {
    try {
      final AuthorizationTokenResponse result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId, _mobileRedirectUrl,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: _authorizationEndpoint,
            tokenEndpoint: _tokenEndpoint,
          ),
          scopes: _scopes, promptValues: ['login'],
        ),
      );

      if (result.idToken != null) {
        await _verifyTokenWithBackend(result.idToken!);
      } else {
        throw Exception('OIDC login cancelled.');
      }
    } catch (e) {
      _authState = AuthState.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  // Verify OIDC token with our backend
  Future<void> _verifyTokenWithBackend(String idToken) async {
    try {
      final response = await _dio.post(
        '$_bffBaseUrl/api/mobile/auth/token',
        data: { 'idToken': idToken },
      );

      if (response.statusCode == 200) {
        _appSessionToken = response.data['sessionToken'];
        final bool isNewUser = response.data['isNewUser'];

        await _secureStorage.write(key: 'app_session_token', value: _appSessionToken);

        if (isNewUser) {
          _authState = AuthState.needsSetup;
        } else {
          _authState = AuthState.authenticated;
        }
        notifyListeners();
      } else {
        throw Exception('Backend token verification failed.');
      }
    } on DioException catch(e) {
      throw Exception(e.response?.data['error'] ?? 'Backend verification failed');
    }
  }

  // Generate a new key pair and complete the setup
  Future<void> completeSetup(String password) async {
    // 1. Generate ECDSA Key Pair
    final keyPair = _generateEcdsaKeyPair();
    final privateKey = keyPair.privateKey as pc.ECPrivateKey;
    final publicKey = keyPair.publicKey as pc.ECPublicKey;

    // 2. Export public key to a standard format (e.g., JWK)
    final publicKeyJwk = _exportPublicKeyAsJwk(publicKey);

    // 3. Store the private key's sensitive component securely
    // In a real app, this would be encrypted with the password/biometrics before storing.
    await _secureStorage.write(key: 'user_private_key_d', value: privateKey.d.toString());

    // 4. Register the user with their password and public key on the backend
    await _dio.post(
      '$_bffBaseUrl/api/mobile/users/complete-setup',
      data: {
        'password': password,
        'devicePublicKey': jsonEncode(publicKeyJwk),
      },
      options: Options(headers: {'Authorization': 'Bearer $_appSessionToken'}),
    );

    _authState = AuthState.authenticated;
    notifyListeners();
  }

  // --- NEW METHOD ---
  /// Generates and signs a JWT consent token for a specific data request.
  Future<String?> signConsentToken(String requestId) async {
    // 1. Retrieve the user's stored private key component
    final privateKeyComponent = await _secureStorage.read(key: 'user_private_key_d');
    if (privateKeyComponent == null) {
      print("Error: Private key not found in secure storage.");
      return null; // Can't sign without a key
    }

    // 2. Reconstruct the private key object
    final d = BigInt.parse(privateKeyComponent);
    final privateKey = pc.ECPrivateKey(d, pc.ECCurve_secp256r1());

    // 3. Create the JWT payload
    final payload = {
      'jti': const Uuid().v4(), // Unique token ID to prevent replay attacks
      'iss': 'com.asciitechnologies.addisinfway', // Issuer (your app)
      'aud': 'urn:addis-information-highway:broker', // Audience (your backend)
      'exp': (DateTime.now().toUtc().add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000),
      'iat': (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000),
      'requestId': requestId, // Link the consent to the specific request
    };

    // 4. Create the JWT header and signing input
    final header = '{"alg":"ES256","typ":"JWT"}';
    final headerBase64 = base64Url.encode(utf8.encode(header));
    final payloadBase64 = base64Url.encode(utf8.encode(jsonEncode(payload)));
    final signingInput = utf8.encode('$headerBase64.$payloadBase64');

    // 5. Create the ECDSA signer and sign the payload
    final signer = pc.Signer('SHA-256/ECDSA');
    signer.init(true, pc.PrivateKeyParameter<pc.ECPrivateKey>(privateKey));
    final signature = signer.generateSignature(signingInput) as pc.ECSignature;

    // 6. Encode the signature components (r and s) into Base64URL format
    final rBytes = _bigIntToBytes(signature.r);
    final sBytes = _bigIntToBytes(signature.s);
    final signatureBytes = Uint8List.fromList([...rBytes, ...sBytes]);
    final signatureBase64 = base64Url.encode(signatureBytes);

    // 7. Assemble and return the final JWT
    return '$headerBase64.$payloadBase64.$signatureBase64';
  }

  Future<void> logout() async {
    await _secureStorage.deleteAll();
    _appSessionToken = null;
    _authState = AuthState.unauthenticated;
    notifyListeners();
  }

  // --- Cryptography Helpers ---
  pc.AsymmetricKeyPair<pc.PublicKey, pc.PrivateKey> _generateEcdsaKeyPair() {
    final keyParams = pc.ECKeyGeneratorParameters(pc.ECCurve_secp256r1());
    final generator = pc.ECKeyGenerator();
    generator.init(keyParams);
    return generator.generateKeyPair();
  }

  Map<String, String> _exportPublicKeyAsJwk(pc.ECPublicKey publicKey) {
    String bigIntToBase64Url(BigInt number) {
      final bytes = (number.toRadixString(16).padLeft(64, '0'));
      final decoded = Uint8List.fromList(List<int>.generate(bytes.length ~/ 2, (i) => int.parse(bytes.substring(i * 2, i * 2 + 2), radix: 16)));
      return base64Url.encode(decoded).replaceAll('=', '');
    }

    return {
      'kty': 'EC',
      'crv': 'P-256',
      'x': bigIntToBase64Url(publicKey.Q!.x!.toBigInteger()!),
      'y': bigIntToBase64Url(publicKey.Q!.y!.toBigInteger()!),
    };
  }

  // Helper to convert BigInt to a fixed-length byte array for ECDSA signatures
  Uint8List _bigIntToBytes(BigInt number) {
    var hex = number.toRadixString(16);
    // Pad with a leading zero if the hex string has an odd number of characters
    if (hex.length % 2 != 0) {
      hex = '0$hex';
    }
    // Convert hex string to a list of bytes
    final bytes = Uint8List.fromList(List<int>.generate(hex.length ~/ 2, (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16)));

    // P-256 (secp256r1) signature components (r and s) are 32 bytes each.
    // We must pad with leading zeros if the byte representation is shorter.
    if (bytes.length < 32) {
      final paddedBytes = Uint8List(32);
      paddedBytes.setRange(32 - bytes.length, 32, bytes);
      return paddedBytes;
    }
    // If it's somehow longer (e.g., > 32 bytes due to a leading 0x00), take the last 32 bytes.
    if (bytes.length > 32) {
      return bytes.sublist(bytes.length - 32);
    }
    return bytes;
  }
}