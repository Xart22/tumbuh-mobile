import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import '../security/secure_storage_service.dart';

class DeviceBindingInfo {
  final String deviceId;
  final String deviceName;
  final String osVersion;
  final String platform;

  const DeviceBindingInfo({
    required this.deviceId,
    required this.deviceName,
    required this.osVersion,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'osVersion': osVersion,
        'platform': platform,
      };
}

class DeviceService {
  final SecureStorageService _storage;
  final DeviceInfoPlugin _deviceInfo;

  DeviceService({
    required SecureStorageService storage,
    DeviceInfoPlugin? deviceInfo,
  })  : _storage = storage,
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  /// Retrieves or generates a unique, persistent hardware binding ID.
  Future<String> getOrCreateDeviceId() async {
    String? existingId = await _storage.getDeviceId();
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    final newId = 'dev_${const Uuid().v4()}';
    await _storage.saveDeviceId(newId);
    return newId;
  }

  /// Retrieves device metadata for activation & backend handshake
  Future<DeviceBindingInfo> getDeviceInfo() async {
    final deviceId = await getOrCreateDeviceId();
    String deviceName = 'Unknown Device';
    String osVersion = 'Unknown OS';
    String platform = Platform.operatingSystem;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
        osVersion = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceName = iosInfo.utsname.machine;
        osVersion = 'iOS ${iosInfo.systemVersion}';
      } else if (Platform.isWindows) {
        final winInfo = await _deviceInfo.windowsInfo;
        deviceName = winInfo.computerName;
        osVersion = 'Windows ${winInfo.displayVersion}';
      }
    } catch (_) {
      // Fallback gracefully
    }

    return DeviceBindingInfo(
      deviceId: deviceId,
      deviceName: deviceName,
      osVersion: osVersion,
      platform: platform,
    );
  }
}
