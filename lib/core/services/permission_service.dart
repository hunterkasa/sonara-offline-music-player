import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum AudioPermissionStatus { granted, denied, permanentlyDenied, restricted }

abstract class PermissionService {
  Future<AudioPermissionStatus> checkAudioPermission();
  Future<AudioPermissionStatus> requestAudioPermission();
  Future<bool> openSettings();
}

class SystemPermissionService implements PermissionService {
  final DeviceInfoPlugin _deviceInfo;

  SystemPermissionService({DeviceInfoPlugin? deviceInfo})
    : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  Future<Permission> _getRequiredPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        return Permission.audio;
      } else {
        return Permission.storage;
      }
    }
    return Permission.storage;
  }

  @override
  Future<AudioPermissionStatus> checkAudioPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return AudioPermissionStatus.granted;
    }
    final permission = await _getRequiredPermission();
    final status = await permission.status;
    return _mapStatus(status);
  }

  @override
  Future<AudioPermissionStatus> requestAudioPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return AudioPermissionStatus.granted;
    }
    final permission = await _getRequiredPermission();
    final status = await permission.request();
    return _mapStatus(status);
  }

  @override
  Future<bool> openSettings() async {
    return openAppSettings();
  }

  AudioPermissionStatus _mapStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return AudioPermissionStatus.granted;
    } else if (status.isPermanentlyDenied) {
      return AudioPermissionStatus.permanentlyDenied;
    } else if (status.isRestricted) {
      return AudioPermissionStatus.restricted;
    } else {
      return AudioPermissionStatus.denied;
    }
  }
}

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return SystemPermissionService();
});
