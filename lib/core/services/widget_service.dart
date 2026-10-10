import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/playback_controller.dart';

class WidgetService {
  final PlaybackController playbackController;
  static const _channel = MethodChannel('com.example.sonara/mediastore');
  StreamSubscription<PlaybackSnapshot>? _subscription;

  String? _lastTitle;
  String? _lastArtist;
  bool? _lastIsPlaying;

  WidgetService({required this.playbackController});

  void startListening() {
    _subscription?.cancel();
    _subscription = playbackController.snapshotStream.listen((snapshot) {
      if (snapshot.title == _lastTitle &&
          snapshot.artist == _lastArtist &&
          snapshot.isPlaying == _lastIsPlaying) {
        return;
      }
      _lastTitle = snapshot.title;
      _lastArtist = snapshot.artist;
      _lastIsPlaying = snapshot.isPlaying;

      updateWidget(
        title: snapshot.title,
        artist: snapshot.artist,
        isPlaying: snapshot.isPlaying,
      );
    });
  }

  Future<void> updateWidget({
    required String title,
    required String artist,
    required bool isPlaying,
  }) async {
    try {
      await _channel.invokeMethod('updateWidget', {
        'title': title,
        'artist': artist,
        'isPlaying': isPlaying,
      });
    } catch (e) {
      debugPrint('WidgetService updateWidget notice: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

final widgetServiceProvider = Provider<WidgetService>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  final service = WidgetService(playbackController: controller);
  service.startListening();
  ref.onDispose(service.dispose);
  return service;
});
