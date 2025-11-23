import '../models/auth_response.dart';

Future<AuthResponse> signInWithGoogleWeb(String baseUrl, String authEndpoint) async {
  throw Exception('Web OAuth only available on web platform');
}

void clearTokenFromUrl(String path) {
  // No-op for mobile
}

