import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/shared/waveform/waveform_data.dart';

void main() {
  group('WaveformGenerator Amplitude Profiling Tests', () {
    setUp(() {
      WaveformGenerator.clearCache();
    });

    test('generates expected default sample count with clamped bounds', () {
      final peaks = WaveformGenerator.getWaveformPeaks('test_track_1');

      expect(peaks.length, equals(WaveformGenerator.defaultSamplesCount));
      for (final peak in peaks) {
        expect(peak, greaterThanOrEqualTo(0.08));
        expect(peak, lessThanOrEqualTo(1.0));
      }
    });

    test(
      'deterministically returns identical peaks for identical track key',
      () {
        final peaks1 = WaveformGenerator.getWaveformPeaks(
          'consistent_track_key',
        );
        final peaks2 = WaveformGenerator.getWaveformPeaks(
          'consistent_track_key',
        );

        expect(peaks1, equals(peaks2));
      },
    );

    test('generates different peak contours for different track keys', () {
      final peaksA = WaveformGenerator.getWaveformPeaks('track_alpha');
      final peaksB = WaveformGenerator.getWaveformPeaks('track_beta');

      expect(peaksA, isNot(equals(peaksB)));
    });

    test('supports custom sample sizes', () {
      final peaksCustom = WaveformGenerator.getWaveformPeaks(
        'custom_track',
        samples: 32,
      );

      expect(peaksCustom.length, equals(32));
    });

    test('clearCache purges memory cache', () {
      final peaksBefore = WaveformGenerator.getWaveformPeaks('cached_track');
      WaveformGenerator.clearCache();
      final peaksAfter = WaveformGenerator.getWaveformPeaks('cached_track');

      // Values should still be deterministic
      expect(peaksBefore, equals(peaksAfter));
    });

    test('extracts peaks from real WAV PCM file', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'waveform_wav_test',
      );
      final wavFile = File('${tempDir.path}/test.wav');

      // Synthesize a valid 16-bit mono 44.1kHz PCM WAV with 1000 samples
      const numSamples = 1000;
      final byteData = ByteData(44 + numSamples * 2);

      // "RIFF"
      byteData.setUint8(0, 0x52);
      byteData.setUint8(1, 0x49);
      byteData.setUint8(2, 0x46);
      byteData.setUint8(3, 0x46);
      byteData.setUint32(4, 36 + numSamples * 2, Endian.little);
      // "WAVE"
      byteData.setUint8(8, 0x57);
      byteData.setUint8(9, 0x41);
      byteData.setUint8(10, 0x56);
      byteData.setUint8(11, 0x45);
      // "fmt "
      byteData.setUint8(12, 0x66);
      byteData.setUint8(13, 0x6D);
      byteData.setUint8(14, 0x74);
      byteData.setUint8(15, 0x20);
      byteData.setUint32(16, 16, Endian.little); // chunk size
      byteData.setUint16(20, 1, Endian.little); // PCM format
      byteData.setUint16(22, 1, Endian.little); // Mono
      byteData.setUint32(24, 44100, Endian.little); // Sample rate
      byteData.setUint32(28, 44100 * 2, Endian.little); // Byte rate
      byteData.setUint16(32, 2, Endian.little); // Block align
      byteData.setUint16(34, 16, Endian.little); // Bits per sample
      // "data"
      byteData.setUint8(36, 0x64);
      byteData.setUint8(37, 0x61);
      byteData.setUint8(38, 0x74);
      byteData.setUint8(39, 0x61);
      byteData.setUint32(40, numSamples * 2, Endian.little);

      for (var i = 0; i < numSamples; i++) {
        final val = (i % 2 == 0) ? 12000 : -12000;
        byteData.setInt16(44 + i * 2, val, Endian.little);
      }

      await wavFile.writeAsBytes(byteData.buffer.asUint8List());

      final extracted = await WaveformGenerator.extractPeaksFromFile(
        trackKey: 'wav_test_key',
        filePath: wavFile.path,
        samples: 16,
      );

      expect(extracted.length, equals(16));
      for (final peak in extracted) {
        expect(peak, greaterThanOrEqualTo(0.08));
        expect(peak, lessThanOrEqualTo(1.0));
      }

      await tempDir.delete(recursive: true);
    });

    test('extracts peaks from simulated compressed audio file', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'waveform_comp_test',
      );
      final compFile = File('${tempDir.path}/test.mp3');

      final bytes = Uint8List(2048);
      for (var i = 0; i < bytes.length; i++) {
        bytes[i] = (i * 17) % 256;
      }
      await compFile.writeAsBytes(bytes);

      final extracted = await WaveformGenerator.extractPeaksFromFile(
        trackKey: 'comp_test_key',
        filePath: compFile.path,
        samples: 16,
      );

      expect(extracted.length, equals(16));
      for (final peak in extracted) {
        expect(peak, greaterThanOrEqualTo(0.08));
        expect(peak, lessThanOrEqualTo(1.0));
      }

      await tempDir.delete(recursive: true);
    });

    test('falls back gracefully to synthesis if file does not exist', () async {
      final extracted = await WaveformGenerator.extractPeaksFromFile(
        trackKey: 'missing_file_key',
        filePath: '/non/existent/audio.mp3',
        samples: 32,
      );

      expect(extracted.length, equals(32));
      for (final peak in extracted) {
        expect(peak, greaterThanOrEqualTo(0.08));
        expect(peak, lessThanOrEqualTo(1.0));
      }
    });
  });
}
