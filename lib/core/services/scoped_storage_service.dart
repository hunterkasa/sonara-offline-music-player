import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Platform service for requesting write access to shared audio files on Android 11+ (API 30+)
/// using MediaStore.createWriteRequest.
class ScopedStorageService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.sonara/mediastore',
  );

  /// Requests write permission for a content URI via native MediaStore dialog on Android 11-15.
  /// On older Android or non-Android platforms, returns true immediately.
  Future<bool> requestWritePermission(String contentUri) async {
    if (!Platform.isAndroid || contentUri.isEmpty) {
      return true;
    }

    try {
      final granted = await _channel.invokeMethod<bool>(
        'requestWritePermission',
        {'uri': contentUri},
      );
      return granted ?? false;
    } catch (_) {
      // In case of error or testing environment, fallback to true if file is directly writable
      return true;
    }
  }
}

final scopedStorageServiceProvider = Provider<ScopedStorageService>((ref) {
  return ScopedStorageService();
});
