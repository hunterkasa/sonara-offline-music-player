import 'dart:math';

import '../models/audio_settings.dart';

class ReplayGainCalculator {
  static double computeVolumeMultiplier({
    required double? trackGainDb,
    required double? albumGainDb,
    required ReplayGainMode mode,
    required double preAmpDb,
    required bool preventClipping,
    bool isShuffle = false,
  }) {
    if (mode == ReplayGainMode.off) {
      if (preAmpDb == 0.0) return 1.0;
      final mult = pow(10.0, preAmpDb / 20.0).toDouble();
      return preventClipping ? mult.clamp(0.0, 1.0) : mult.clamp(0.0, 2.0);
    }

    double? selectedGainDb;
    switch (mode) {
      case ReplayGainMode.off:
        selectedGainDb = 0.0;
        break;
      case ReplayGainMode.track:
        selectedGainDb = trackGainDb;
        break;
      case ReplayGainMode.album:
        selectedGainDb = albumGainDb ?? trackGainDb;
        break;
      case ReplayGainMode.smart:
        selectedGainDb = isShuffle
            ? (trackGainDb ?? albumGainDb)
            : (albumGainDb ?? trackGainDb);
        break;
    }

    final totalGainDb = (selectedGainDb ?? 0.0) + preAmpDb;
    final multiplier = pow(10.0, totalGainDb / 20.0).toDouble();

    if (preventClipping) {
      return multiplier.clamp(0.0, 1.0);
    } else {
      return multiplier.clamp(0.0, 2.0);
    }
  }
}
