// Web-specific implementation
import 'dart:html' as html;

bool isProductionWeb() {
  try {
    final host = html.window.location.host;
    // Check if running on Vercel or production domain
    if (host.contains('vercel.app') || 
        (!host.contains('localhost') && !host.contains('127.0.0.1'))) {
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}

