import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Backend base URL - automatically detects production vs development
  // For Production (Vercel): Uses production backend URL
  // For Development: Uses localhost or device IP
  
  // Production backend URL - Update this with your actual production backend URL
  static const String productionBaseUrl = 'https://health-xe8h.onrender.com';
  
  // Development URLs
  static const String localhostUrl = 'http://localhost:3000';
  static const String deviceUrl = 'http://192.168.1.4:3000'; // Update with your device IP
  
  static String get baseUrl {
    // For now, use localhost for web and device IP for mobile
    // For production deployment, you can:
    // 1. Build with different constants using --dart-define
    // 2. Or manually change this before deploying
    if (kIsWeb) {
      // Check if we're in production by checking if URL contains vercel.app
      // Note: This requires runtime check, so for now use localhost
      // For production, change this to productionBaseUrl before deploying
      return localhostUrl; // Change to productionBaseUrl for Vercel deployment
    }
    // Mobile - use device IP
    return deviceUrl;
  }
  
  // API endpoints
  static const String authGoogle = '/auth/google';
  static const String authProfile = '/auth/profile';
    static const String healthFetch = '/health/fetch';
    static const String healthLatest = '/health/latest';
    static const String healthDashboard = '/health/dashboard';
    static const String healthHistory = '/health/history';
    static const String healthLeaderboard = '/health/leaderboard';
    static const String healthLocationsStats = '/health/locations/stats';
    static const String healthLocationsLeaderboard = '/health/locations/leaderboard';
    static const String healthLocationsList = '/health/locations/list';
}

class StorageKeys {
  static const String jwtToken = 'jwt_token';
  static const String userEmail = 'user_email';
}

