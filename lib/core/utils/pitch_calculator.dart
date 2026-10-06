import 'dart:math';

/// Utility class for calculating pitch multipliers from musical semitones
/// and formatting musical pitch offsets.
class PitchCalculator {
  /// Converts a semitone offset (-12 to +12) into a just_audio pitch multiplier.
  /// Formula: Multiplier = 2^(semitones / 12)
  static double semitonesToMultiplier(int semitones) {
    final clamped = semitones.clamp(-12, 12);
    return pow(2.0, clamped / 12.0).toDouble();
  }

  /// Converts a pitch multiplier back to the closest integer semitone (-12 to +12).
  static int multiplierToSemitones(double multiplier) {
    if (multiplier <= 0) return 0;
    final semitones = (12.0 * log(multiplier) / ln2).round();
    return semitones.clamp(-12, 12);
  }

  /// Formats the semitone offset with sign and musical descriptor.
  static String formatSemitones(int semitones) {
    if (semitones == 0) return 'Original (0)';
    if (semitones > 0) return '+$semitones semitones';
    return '$semitones semitones';
  }

  /// Formats short key transposition badge text (e.g., "+2 st", "-1 st", "0 st").
  static String formatKeyTranspose(int semitones) {
    if (semitones > 0) return '+$semitones st';
    return '$semitones st';
  }

  /// Returns musical interval description (e.g., "+7 = Perfect 5th", "+12 = Octave Up").
  static String getIntervalName(int semitones) {
    switch (semitones) {
      case 0:
        return 'Standard Key';
      case 1:
        return 'Minor 2nd Up';
      case 2:
        return 'Major 2nd Up';
      case 3:
        return 'Minor 3rd Up';
      case 4:
        return 'Major 3rd Up';
      case 5:
        return 'Perfect 4th Up';
      case 6:
        return 'Tritone Up';
      case 7:
        return 'Perfect 5th Up';
      case 8:
        return 'Minor 6th Up';
      case 9:
        return 'Major 6th Up';
      case 10:
        return 'Minor 7th Up';
      case 11:
        return 'Major 7th Up';
      case 12:
        return 'Octave Up';
      case -1:
        return 'Minor 2nd Down';
      case -2:
        return 'Major 2nd Down';
      case -3:
        return 'Minor 3rd Down';
      case -4:
        return 'Major 3rd Down';
      case -5:
        return 'Perfect 4th Down';
      case -6:
        return 'Tritone Down';
      case -7:
        return 'Perfect 5th Down';
      case -8:
        return 'Minor 6th Down';
      case -9:
        return 'Major 6th Down';
      case -10:
        return 'Minor 7th Down';
      case -11:
        return 'Major 7th Down';
      case -12:
        return 'Octave Down';
      default:
        return '$semitones semitones';
    }
  }
}
