import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

class GoogleFitCheckService {
  static const MethodChannel _channel = MethodChannel('com.example.frontend/google_fit_check');
  
  // Google Fit package names
  static const String androidPackageName = 'com.google.android.apps.fitness';
  static const String iosBundleId = 'com.google.Fitness';
  
  // Play Store URLs
  static const String androidPlayStoreUrl = 'https://play.google.com/store/apps/details?id=com.google.android.apps.fitness';
  static const String iosAppStoreUrl = 'https://apps.apple.com/app/google-fit/id1433864494';

  /// Check if running on web platform
  bool get isWeb => kIsWeb;

  /// Check if platform supports Google Fit installation check
  bool isPlatformSupported() {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  /// Check if Google Fit is installed
  /// Returns false for web (as web cannot check installed apps)
  Future<bool> isGoogleFitInstalled() async {
    try {
      // Web platform cannot check installed apps
      if (kIsWeb) {
        return false;
      }
      
      if (Platform.isAndroid) {
        return await _checkAndroidAppInstalled(androidPackageName);
      } else if (Platform.isIOS) {
        return await _checkIOSAppInstalled(iosBundleId);
      }
      return false;
    } catch (e) {
      print('Error checking Google Fit installation: $e');
      return false;
    }
  }

  /// Check if app is installed on Android
  Future<bool> _checkAndroidAppInstalled(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>('isAppInstalled', {'packageName': packageName});
      return result ?? false;
    } catch (e) {
      // Fallback: Try to launch the app and catch error
      try {
        final uri = Uri.parse('$packageName://');
        if (await canLaunchUrl(uri)) {
          return true;
        }
      } catch (_) {}
      return false;
    }
  }

  /// Check if app is installed on iOS
  Future<bool> _checkIOSAppInstalled(String bundleId) async {
    try {
      final uri = Uri.parse('$bundleId://');
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }

  /// Open Google Fit in Play Store / App Store
  Future<void> openGoogleFitStore() async {
    try {
      String url;
      if (Platform.isAndroid) {
        url = androidPlayStoreUrl;
      } else if (Platform.isIOS) {
        url = iosAppStoreUrl;
      } else {
        return;
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening Google Fit store: $e');
    }
  }

  /// Open Google Fit app directly
  Future<void> openGoogleFitApp() async {
    try {
      String url;
      if (Platform.isAndroid) {
        url = '$androidPackageName://';
      } else if (Platform.isIOS) {
        url = '$iosBundleId://';
      } else {
        return;
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening Google Fit app: $e');
    }
  }
}

