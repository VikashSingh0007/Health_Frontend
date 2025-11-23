import 'package:flutter/foundation.dart' show kIsWeb;
// Conditional import for web to detect production
import 'dart:html' as html if (dart.library.html) 'dart:html' as html;

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
    if (kIsWeb) {
      // Check if running on Vercel (production) by checking hostname
      try {
        final host = html.window.location.host;
        // If host contains vercel.app or is not localhost, use production URL
        if (host.contains('vercel.app') || 
            (!host.contains('localhost') && !host.contains('127.0.0.1'))) {
          return productionBaseUrl;
        }
        // Local development
        return localhostUrl;
      } catch (e) {
        // Fallback to production if can't detect
        return productionBaseUrl;
      }
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

