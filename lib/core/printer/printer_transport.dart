import 'printer_transport_stub.dart'
    if (dart.library.io) 'printer_transport_io.dart' as impl;

/// Sends raw ESC/POS bytes to a network thermal printer (port 9100 by default).
/// Returns false on web/unsupported platforms or when the connection fails.
Future<bool> sendRawToNetwork(String host, int port, List<int> bytes) =>
    impl.sendRawToNetwork(host, port, bytes);
