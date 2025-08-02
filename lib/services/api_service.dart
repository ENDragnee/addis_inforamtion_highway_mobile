import 'package:addis_information_highway_mobile/models/data_request.dart';
import 'package:addis_information_highway_mobile/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A service dedicated to making authenticated API calls to the backend.
/// It relies on an `AuthService` instance to get the current session token.
class ApiService {
  final Dio _dio;
  final AuthService _authService;
  final String _baseUrl = dotenv.env['BFF_BASE_URL']!;

  ApiService(this._authService) : _dio = Dio() {
    // Add the custom interceptor to the Dio instance upon creation.
    _dio.interceptors.add(AuthInterceptor(_authService, _dio));
  }

  Future<void> registerPushToken(String token) async {
    try {
      await _dio.post(
        '$_baseUrl/api/mobile/users/register-push-token',
        data: {'token': token},
      );
      print('Push token registered successfully with backend.');
    } on DioException catch (e) {
      // Don't throw a fatal error, just log it.
      print('Failed to register push token: ${_handleDioError(e, "Unknown error")}');
    }
  }

  /// Fetches all data requests (pending and historical) for the logged-in user.
  Future<List<DataRequest>> fetchDataRequests() async {
    try {
      final response = await _dio.get('$_baseUrl/api/mobile/requests');
      return (response.data as List)
          .map((json) => DataRequest.fromJson(json))
          .toList();
    } on DioException catch (e) {
      // Provide more specific error messages
      throw _handleDioError(e, 'Failed to fetch data requests');
    }
  }

  /// Responds to a data request with either 'APPROVE' or 'DENY'.
  /// If approving, it gets a signed consent token from the AuthService.
  Future<String> respondToRequest(String requestId, String action) async {
    try {
      String? consentToken;
      if (action == 'APPROVE') {
        // Delegate the complex and secure task of signing to the AuthService
        consentToken = await _authService.signConsentToken(requestId);
      }

      final response = await _dio.post(
        '$_baseUrl/api/mobile/requests/$requestId/respond',
        data: {
          'action': action,
          'consentToken': consentToken, // Will be null for 'DENY' actions
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
      return e.response!.data['error'] ?? defaultMessage;
    }
    return e.message ?? defaultMessage;
  }
}

/// A custom Dio interceptor to automatically add the Authorization header.
class AuthInterceptor extends Interceptor {
  final AuthService authService;
  final Dio dio; // Pass dio instance to handle token refresh logic if needed

  AuthInterceptor(this.authService, this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Get the current session token from the AuthService
    final token = authService.appSessionToken;

    // If a token exists, add it to the request header
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Continue with the request
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Optional: Advanced logic to handle 401 Unauthorized errors.
    // You could attempt to refresh the OIDC token here and retry the request.
    if (err.response?.statusCode == 401) {
      print('AuthInterceptor: Received 401. User should be logged out.');
      // Forcing a logout if the session token is rejected by the backend
      authService.logout();
    }
    return handler.next(err);
  }


}