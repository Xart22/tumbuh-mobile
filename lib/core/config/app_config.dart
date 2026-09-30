class AppConfig {
  AppConfig._();

  /// Default API base URL from backend environment (contract: NEXT_PUBLIC_API_URL or mobile default)
  static const String defaultBaseUrl = 'https://api.tumbuhpos.com';
  
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
