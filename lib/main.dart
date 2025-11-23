import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Conditional import for web utilities
import 'services/web_utils_stub.dart'
    if (dart.library.html) 'services/web_utils.dart' as web_utils;
import 'services/auth_service.dart';
import 'screens/google_fit_check_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'providers/health_provider.dart';

void main() {
  runApp(const MyApp());
}

// Global navigator key for navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HealthProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Health Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isChecking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _checkForOAuthToken();
    // Periodically check auth status to detect token expiration
    _startAuthCheckTimer();
  }

  void _startAuthCheckTimer() {
    // Check auth status every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _checkAuthStatus();
        _startAuthCheckTimer();
      }
    });
  }

  // Check for OAuth token in URL (from backend redirect)
  void _checkForOAuthToken() {
    // This will be handled by web platform
    // For now, we'll check auth status normally
  }

  Future<void> _checkAuthStatus() async {
    // Check for token in URL (web OAuth callback)
    if (kIsWeb) {
      final uri = Uri.base;
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        await _authService.storeJWT(token);
        // Clear token from URL using web utilities
        web_utils.clearTokenFromUrl(uri.path);
      }
    }
    
    final isLoggedIn = await _authService.isLoggedIn();
    
    // If user was logged in but now token is gone, navigate to Google Fit check screen
    if (_isLoggedIn && !isLoggedIn) {
      // Token was cleared (likely expired), navigate to Google Fit check screen
      if (navigatorKey.currentContext != null) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const GoogleFitCheckScreen()),
          (route) => false,
        );
      }
    }
    
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If logged in, go to dashboard
    // If not logged in, show Google Fit check screen first (which will navigate to login)
    return _isLoggedIn ? const DashboardScreen() : const GoogleFitCheckScreen();
  }
}
