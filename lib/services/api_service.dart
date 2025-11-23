import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/health_data_model.dart';
import '../models/leaderboard_model.dart';
import 'auth_service.dart';
import '../main.dart';
import '../screens/login_screen.dart';

class ApiService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getStoredJWT();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> authenticatedRequest(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(url, headers: headers);
        break;
      case 'POST':
        response = await http.post(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(url, headers: headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      // Token expired or invalid - try to refresh
      try {
        final refreshed = await _authService.refreshJWTToken();
        if (refreshed) {
          // Retry the request with new token
          return await authenticatedRequest(endpoint, method, body: body);
        }
      } catch (e) {
        // Refresh failed - clear token and logout
        await _authService.signOut();
        // Navigate to login screen immediately
        _navigateToLogin();
        throw Exception('Session expired. Please login again.');
      }
      // If refresh returned false, clear token and logout
      await _authService.signOut();
      // Navigate to login screen immediately
      _navigateToLogin();
      throw Exception('Session expired. Please login again.');
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        errorBody['message'] as String? ?? 'Request failed with status ${response.statusCode}',
      );
    }
  }

  Future<HealthDataModel> fetchHealthData() async {
    final response = await authenticatedRequest(
      ApiConstants.healthFetch,
      'POST',
    );
    return HealthDataModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<HealthDataModel?> getLatestHealthData() async {
    try {
      final response = await authenticatedRequest(
        ApiConstants.healthLatest,
        'GET',
      );
      if (response['data'] == null) {
        return null;
      }
      return HealthDataModel.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      return null;
    }
  }

  Future<DashboardData> getDashboardData() async {
    try {
      print('Fetching dashboard data from: ${ApiConstants.healthDashboard}');
      final response = await authenticatedRequest(
        ApiConstants.healthDashboard,
        'GET',
      );
      print('Dashboard API response: $response');
      final dashboardData = DashboardData.fromJson(response);
      print('Parsed dashboard data: steps=${dashboardData.steps}, heartRate=${dashboardData.heartRate}');
      return dashboardData;
    } catch (e) {
      print('Error in getDashboardData: $e');
      rethrow;
    }
  }

  Future<List<HealthDataModel>> getHealthHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String endpoint = ApiConstants.healthHistory;
    if (startDate != null || endDate != null) {
      final params = <String>[];
      if (startDate != null) {
        params.add('startDate=${startDate.toIso8601String().split('T')[0]}');
      }
      if (endDate != null) {
        params.add('endDate=${endDate.toIso8601String().split('T')[0]}');
      }
      endpoint += '?${params.join('&')}';
    }

    try {
      print('Fetching health history from: $endpoint');
      final response = await authenticatedRequest(endpoint, 'GET');
      print('History API response: $response');
      final dataList = response['data'] as List<dynamic>;
      print('History data count: ${dataList.length}');
      final historyList = dataList
          .map((item) => HealthDataModel.fromJson(item as Map<String, dynamic>))
          .toList();
      print('Parsed history data: ${historyList.length} records');
      return historyList;
    } catch (e) {
      print('Error in getHealthHistory: $e');
      rethrow;
    }
  }

  /// Insert test heart rate data into Google Fit
  /// This is for testing purposes
  Future<Map<String, dynamic>> insertTestHeartRate({int? heartRate}) async {
    final response = await authenticatedRequest(
      '/health/test/heart-rate',
      'POST',
      body: {'heartRate': heartRate ?? 72},
    );
    return response;
  }

  /// Fetch real health data from Google Fit for last N days
  Future<Map<String, dynamic>> fetchRealDataFromGoogleFit({int? days}) async {
    final response = await authenticatedRequest(
      '/health/test/fetch-real-data',
      'POST',
      body: {'days': days ?? 30},
    );
    return response;
  }

  /// Get leaderboard data
  Future<LeaderboardResponse> getLeaderboard({
    String metric = 'steps',
    int limit = 50,
    String? period, // 'today', 'week', 'month'
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      print('Fetching leaderboard with metric: $metric, limit: $limit, period: $period');
      String endpoint = '${ApiConstants.healthLeaderboard}?metric=$metric&limit=$limit';
      if (period != null) {
        endpoint += '&period=$period';
      } else if (startDate != null && endDate != null) {
        endpoint += '&startDate=${startDate.toIso8601String().split('T')[0]}&endDate=${endDate.toIso8601String().split('T')[0]}';
      }
      final response = await authenticatedRequest(endpoint, 'GET');
      print('Leaderboard API response received: ${response['data']?.length} entries');
      return LeaderboardResponse.fromJson(response);
    } catch (e) {
      print('Error in getLeaderboard: $e');
      rethrow;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await authenticatedRequest(
        ApiConstants.authProfile,
        'GET',
      );
      return response;
    } catch (e) {
      print('Error in getProfile: $e');
      rethrow;
    }
  }

  /// Update user profile (location)
  Future<Map<String, dynamic>> updateProfile({String? location}) async {
    try {
      final response = await authenticatedRequest(
        ApiConstants.authProfile,
        'PUT',
        body: {'location': location},
      );
      return response;
    } catch (e) {
      print('Error in updateProfile: $e');
      rethrow;
    }
  }

  /// Get location statistics
  Future<List<Map<String, dynamic>>> getLocationStatistics({
    String? period, // 'today', 'week', 'month'
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String endpoint = ApiConstants.healthLocationsStats;
      final params = <String>[];
      if (period != null) {
        params.add('period=$period');
      } else if (startDate != null && endDate != null) {
        params.add('startDate=${startDate.toIso8601String().split('T')[0]}');
        params.add('endDate=${endDate.toIso8601String().split('T')[0]}');
      }
      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }
      final response = await authenticatedRequest(endpoint, 'GET');
      return List<Map<String, dynamic>>.from(response['data'] as List);
    } catch (e) {
      print('Error in getLocationStatistics: $e');
      rethrow;
    }
  }

  /// Get location leaderboard
  Future<LeaderboardResponse> getLocationLeaderboard({
    String? location,
    String metric = 'steps',
  }) async {
    try {
      String endpoint = ApiConstants.healthLocationsLeaderboard;
      final params = <String>[];
      if (location != null && location.isNotEmpty) {
        params.add('location=${Uri.encodeComponent(location)}');
      }
      params.add('metric=$metric');
      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }
      final response = await authenticatedRequest(endpoint, 'GET');
      return LeaderboardResponse.fromJson(response);
    } catch (e) {
      print('Error in getLocationLeaderboard: $e');
      rethrow;
    }
  }

  /// Get all locations
  Future<List<String>> getAllLocations() async {
    try {
      final response = await authenticatedRequest(
        ApiConstants.healthLocationsList,
        'GET',
      );
      return List<String>.from(response['data'] as List);
    } catch (e) {
      print('Error in getAllLocations: $e');
      rethrow;
    }
  }

  /// Navigate to login screen when token expires
  void _navigateToLogin() {
    // Use navigator key to navigate from anywhere
    if (navigatorKey.currentContext != null) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

