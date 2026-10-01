/// Web/unsupported fallback: raw network printing is not available.
Future<bool> sendRawToNetwork(String host, int port, List<int> bytes) async =>
    false;
