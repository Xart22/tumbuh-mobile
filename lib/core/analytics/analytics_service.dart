import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Lightweight analytics: structured log + Sentry breadcrumb for key events
/// (login, shift, checkout, sync failures). No third-party analytics backend
/// is wired yet — swap [log] when one is chosen.
class AnalyticsService {
  const AnalyticsService();

  void log(String event, [Map<String, Object?>? data]) {
    if (kDebugMode) {
      debugPrint('[analytics] $event ${data ?? const {}}');
    }
    Sentry.addBreadcrumb(
      Breadcrumb(message: event, category: 'analytics', data: data),
    );
  }
}
