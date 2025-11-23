import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
// Conditional import for web utilities
import 'web_utils_stub.dart'
    if (dart.library.html) 'web_utils.dart' as web_utils;
import '../utils/constants.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

class AuthService {
  // Lazy initialization to prevent multiple instances
  GoogleSignIn? _googleSignInInstance;
  GoogleSignIn get _googleSignIn {
    _googleSignInInstance ??= GoogleSignIn(
      // For Android: serverClientId is required to get idToken
      // Use your Web Client ID from Google Cloud Console
      serverClientId: '835165643081-074jug0ngkoa4ksv1or12nusb87f0amc.apps.googleusercontent.com',
      // For web, clientId should be set in index.html meta tag
      // For mobile Android, package name and SHA-1 are configured in Google Cloud Console
      scopes: [
        'email',
        'profile',
        'https://www.googleapis.com/auth/fitness.activity.read',
        'https://www.googleapis.com/auth/fitness.heart_rate.read',
        'https://www.googleapis.com/auth/fitness.body.read',
        'https://www.googleapis.com/auth/fitness.heart_rate.write', // For inserting heart rate data
      ],
    );
    return _googleSignInInstance!;
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<AuthResponse> signInWithGoogle() async {
    // For web, use backend OAuth flow (more reliable)
    if (kIsWeb) {
      return _signInWithGoogleWeb();
    }
    
    // For mobile, use direct Google Sign-In
    try {
      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Validate tokens
      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        throw Exception('Google Sign-In failed: idToken is null or empty');
      }
      
      if (googleAuth.accessToken == null || googleAuth.accessToken!.isEmpty) {
        throw Exception('Google Sign-In failed: accessToken is null or empty');
      }

      // Send token to backend
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authGoogle}/mobile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': googleAuth.idToken!,
          'accessToken': googleAuth.accessToken!,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Debug: Log response (remove in production)
        print('Backend response: $responseBody');
        
        // Check for error in response
        if (responseBody.containsKey('error')) {
          throw Exception(responseBody['error'] as String? ?? 'Authentication failed');
        }
        
        // Validate access_token exists
        if (!responseBody.containsKey('access_token')) {
          throw Exception('Backend response missing access_token. Response: $responseBody');
        }
        
        final authResponse = AuthResponse.fromJson(responseBody);
        
        // Store JWT token
        await storeJWT(authResponse.accessToken);
        
        return authResponse;
      } else {
        // Try to parse error message from response
        try {
          final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
          final errorMessage = errorBody['error'] as String? ?? 
                              errorBody['message'] as String? ?? 
                              'Failed to authenticate with backend';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Failed to authenticate with backend (Status: ${response.statusCode})');
        }
      }
    } catch (e) {
      // Ignore "Future already completed" errors on web (they're harmless)
      if (e.toString().contains('Future already completed')) {
        // This is a known issue with google_sign_in_web, ignore it
        return Future<AuthResponse>.delayed(
          const Duration(days: 1),
          () => throw Exception('Should not reach here'),
        );
      }
      throw Exception('Google sign in failed: $e');
    }
  }

  // Web OAuth flow - redirect to backend
  Future<AuthResponse> _signInWithGoogleWeb() async {
    // Use web utilities with conditional import
    return web_utils.signInWithGoogleWeb(
      ApiConstants.baseUrl,
      ApiConstants.authGoogle,
    );
  }

  Future<void> storeJWT(String jwtToken) async {
    await _storage.write(key: StorageKeys.jwtToken, value: jwtToken);
  }

  Future<String?> getStoredJWT() async {
    return await _storage.read(key: StorageKeys.jwtToken);
  }

  Future<bool> isLoggedIn() async {
    final token = await getStoredJWT();
    return token != null && token.isNotEmpty;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _storage.delete(key: StorageKeys.jwtToken);
    await _storage.delete(key: StorageKeys.userEmail);
  }

  /// Refresh JWT token using stored Google refresh token
  Future<bool> refreshJWTToken() async {
    try {
      final token = await getStoredJWT();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Send old token even if expired
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseBody.containsKey('access_token')) {
          await storeJWT(responseBody['access_token'] as String);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error refreshing JWT token: $e');
      return false;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final token = await getStoredJWT();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authProfile}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

