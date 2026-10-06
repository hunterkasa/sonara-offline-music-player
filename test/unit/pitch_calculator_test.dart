import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/core/utils/pitch_calculator.dart';

void main() {
  group('PitchCalculator Mathematical & Interval Tests', () {
    test('semitonesToMultiplier calculates exact power-of-two formula', () {
      // 0 semitones = 1.0x
      expect(PitchCalculator.semitonesToMultiplier(0), equals(1.0));

      // +12 semitones = exactly 1 octave up = 2.0x
      expect(PitchCalculator.semitonesToMultiplier(12), equals(2.0));

      // -12 semitones = exactly 1 octave down = 0.5x
      expect(PitchCalculator.semitonesToMultiplier(-12), equals(0.5));

      // +7 semitones (Perfect 5th) = 2^(7/12) ≈ 1.498307
      expect(
        PitchCalculator.semitonesToMultiplier(7),
        closeTo(1.498307, 0.0001),
      );

      // -5 semitones = 2^(-5/12) ≈ 0.749153
      expect(
        PitchCalculator.semitonesToMultiplier(-5),
        closeTo(0.749153, 0.0001),
      );
    });

    test('semitonesToMultiplier clamps to [-12, +12]', () {
      expect(PitchCalculator.semitonesToMultiplier(24), equals(2.0));
      expect(PitchCalculator.semitonesToMultiplier(-24), equals(0.5));
    });

    test('multiplierToSemitones converts multipliers back accurately', () {
      expect(PitchCalculator.multiplierToSemitones(1.0), equals(0));
      expect(PitchCalculator.multiplierToSemitones(2.0), equals(12));
      expect(PitchCalculator.multiplierToSemitones(0.5), equals(-12));
      expect(PitchCalculator.multiplierToSemitones(1.4983), equals(7));
      expect(PitchCalculator.multiplierToSemitones(0.7492), equals(-5));
      expect(PitchCalculator.multiplierToSemitones(-1.0), equals(0));
    });

    test('formatSemitones formats positive, negative, and zero values', () {
      expect(PitchCalculator.formatSemitones(0), equals('Original (0)'));
      expect(PitchCalculator.formatSemitones(3), equals('+3 semitones'));
      expect(PitchCalculator.formatSemitones(-4), equals('-4 semitones'));
    });

    test('formatKeyTranspose formats badge notation', () {
      expect(PitchCalculator.formatKeyTranspose(0), equals('0 st'));
      expect(PitchCalculator.formatKeyTranspose(2), equals('+2 st'));
      expect(PitchCalculator.formatKeyTranspose(-1), equals('-1 st'));
    });

    test('getIntervalName returns canonical musical interval descriptions', () {
      expect(PitchCalculator.getIntervalName(0), equals('Standard Key'));
      expect(PitchCalculator.getIntervalName(1), equals('Minor 2nd Up'));
      expect(PitchCalculator.getIntervalName(2), equals('Major 2nd Up'));
      expect(PitchCalculator.getIntervalName(7), equals('Perfect 5th Up'));
      expect(PitchCalculator.getIntervalName(12), equals('Octave Up'));
      expect(PitchCalculator.getIntervalName(-1), equals('Minor 2nd Down'));
      expect(PitchCalculator.getIntervalName(-7), equals('Perfect 5th Down'));
      expect(PitchCalculator.getIntervalName(-12), equals('Octave Down'));
      expect(PitchCalculator.getIntervalName(15), equals('15 semitones'));
    });
  });
}
