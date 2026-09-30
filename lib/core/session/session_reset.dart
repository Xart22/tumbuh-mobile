import 'dart:async';

/// Broadcasts a global "session invalidated" signal (e.g. API 401) so the
/// widget tree can log out and clear per-session state without the network
/// layer holding references to blocs.
class SessionReset {
  SessionReset._();
  static final SessionReset instance = SessionReset._();

  final StreamController<void> _controller =
      StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void fire() => _controller.add(null);
}
