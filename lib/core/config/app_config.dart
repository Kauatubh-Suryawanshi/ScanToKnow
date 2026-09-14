import 'package:flutter/foundation.dart';

/// Centralized backend configuration.
///
/// Production/staging builds should always provide:
///   --dart-define=BACKEND_URL=https://api.example.com
///
/// The defaults are for local development only. Physical devices should use
/// a LAN-reachable backend URL via BACKEND_URL.
class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:4000',
  );

  static bool get isProductionUrl => baseUrl.startsWith('https://');

  // Kept as a small diagnostic helper so callers can show actionable setup
  // information without exposing secrets.
  static String get platformHint {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}
