import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:addis_information_highway_mobile/features/auth/login_screen.dart'; // For the TestUser model

class TestUserService extends ChangeNotifier {
  final Dio _dio = Dio();

  List<TestUser> _testUsers = [];
  List<TestUser> get testUsers => _testUsers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Fetches the list of test users from the backend.
  /// This should only be called once, typically at app startup.
  Future<void> fetchTestUsers() async {
    // Only fetch if we haven't already and are not currently fetching.
    if (_testUsers.isNotEmpty || _isLoading) return;

    print("TestUserService: Fetching test users...");
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dio.get(
          '${dotenv.env['BFF_BASE_URL']!}/api/v1/mobile/debug/test-users'
      );
      if (response.statusCode == 200) {
        final users = (response.data as List)
            .map((json) => TestUser.fromJson(json))
            .toList();
        _testUsers = users;
        print("TestUserService: Successfully fetched ${_testUsers.length} test users.");
      }
    } catch (e) {
      _error = 'Failed to load test users.';
      print('TestUserService: Error fetching test users: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners of the final state (success or error)
    }
  }
}