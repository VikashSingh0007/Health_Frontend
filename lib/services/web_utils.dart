import 'dart:html' as html;
import 'dart:async';
import '../models/auth_response.dart';

Future<AuthResponse> signInWithGoogleWeb(String baseUrl, String authEndpoint) async {
  // Get full URL including port (e.g., http://localhost:54321)
  final currentUrl = '${html.window.location.protocol}//${html.window.location.host}';
  html.window.localStorage['oauth_redirect_url'] = currentUrl;
  final oauthUrl = '$baseUrl$authEndpoint?state=${Uri.encodeComponent(currentUrl)}';
  print('Redirecting to OAuth: $oauthUrl');
  print('Current Flutter app URL: $currentUrl');
  await Future.delayed(const Duration(milliseconds: 100));
  html.window.location.href = oauthUrl;
  return Future<AuthResponse>.delayed(
    const Duration(days: 1),
    () => throw Exception('Should not reach here'),
  );
}

void clearTokenFromUrl(String path) {
  html.window.history.replaceState({}, '', path);
}

