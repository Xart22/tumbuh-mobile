import 'dart:io';

/// Sends raw ESC/POS bytes to a network thermal printer (raw TCP, port 9100).
Future<bool> sendRawToNetwork(String host, int port, List<int> bytes) async {
  Socket? socket;
  try {
    socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 4),
    );
    socket.add(bytes);
    await socket.flush();
    return true;
  } catch (_) {
    return false;
  } finally {
    await socket?.close();
  }
}
