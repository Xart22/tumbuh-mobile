class AppConfig {
  AppConfig._();

  /// API base URL. Override per-run without editing code:
  /// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000`
  /// (10.0.2.2 reaches the host machine from the Android emulator).
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
  
  /// Connection and receive timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  /// Application identification
  static const String appName = 'Tumbuh POS';
  static const String appVersion = '1.0.0';
  static const int minSupportedAndroidSdk = 26; // Android 8.0+

  /// Breakpoint thresholds
  static const double tabletBreakpoint = 768.0;
  static const double desktopBreakpoint = 1280.0;
}
