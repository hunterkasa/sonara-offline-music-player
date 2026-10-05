import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';

const int kLongAudioThresholdMs = 20 * 60 * 1000; // 20 minutes

class LongAudioState {
  final int positionMs;
  final double speed;
  final int lastUpdated;

  const LongAudioState({
    required this.positionMs,
    this.speed = 1.0,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
    'positionMs': positionMs,
    'speed': speed,
    'lastUpdated': lastUpdated,
  };

  factory LongAudioState.fromMap(Map<String, dynamic> map) => LongAudioState(
    positionMs: map['positionMs'] as int? ?? 0,
    speed: (map['speed'] as num?)?.toDouble() ?? 1.0,
    lastUpdated: map['lastUpdated'] as int? ?? 0,
  );

  String toJson() => jsonEncode(toMap());
  factory LongAudioState.fromJson(String str) =>
      LongAudioState.fromMap(jsonDecode(str) as Map<String, dynamic>);
}

class LongAudioService {
  final AppDatabase db;

  LongAudioService(this.db);

  bool isLongAudio(int durationMs) {
    return durationMs >= kLongAudioThresholdMs;
  }

  String _settingKey(String trackKey) => 'long_audio_pos_$trackKey';

  Future<void> savePosition(
    String trackKey, {
    required int positionMs,
    double speed = 1.0,
  }) async {
    // Only save if position is beyond 10 seconds and not at the very end
    if (positionMs < 10000) return;

    final state = LongAudioState(
      positionMs: positionMs,
      speed: speed,
      lastUpdated: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    await db.setSetting(_settingKey(trackKey), state.toJson());
  }

  Future<LongAudioState?> getSavedPosition(String trackKey) async {
    final raw = await db.getSetting(_settingKey(trackKey));
    if (raw == null || raw.isEmpty) return null;
    try {
      return LongAudioState.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSavedPosition(String trackKey) async {
    await db.setSetting(_settingKey(trackKey), '');
  }
}

final longAudioServiceProvider = Provider<LongAudioService>((ref) {
  final db = ref.watch(databaseProvider);
  return LongAudioService(db);
});
