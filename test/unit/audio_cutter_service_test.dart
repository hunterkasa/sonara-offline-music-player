import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/core/services/audio_cutter_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AudioCutterService service;
  final log = <MethodCall>[];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.example.sonara/audio_cutter'),
          (MethodCall methodCall) async {
            log.add(methodCall);
            switch (methodCall.method) {
              case 'trimAudio':
                return true;
              case 'setAsRingtone':
                return true;
              case 'canWriteSystemSettings':
                return true;
              case 'openWriteSettings':
                return true;
              case 'shareAudio':
                return true;
              default:
                return null;
            }
          },
        );

    service = AudioCutterService();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.example.sonara/audio_cutter'),
          null,
        );
  });

  group('AudioCutterService Range & Validation Tests', () {
    test('trimAudio throws ArgumentError on negative startMs', () async {
      expect(
        () => service.trimAudio(
          sourcePath: 'dummy.mp3',
          destinationPath: 'dest.mp3',
          startMs: -500,
          endMs: 5000,
        ),
        throwsArgumentError,
      );
    });

    test('trimAudio throws ArgumentError when startMs >= endMs', () async {
      expect(
        () => service.trimAudio(
          sourcePath: 'dummy.mp3',
          destinationPath: 'dest.mp3',
          startMs: 5000,
          endMs: 5000,
        ),
        throwsArgumentError,
      );

      expect(
        () => service.trimAudio(
          sourcePath: 'dummy.mp3',
          destinationPath: 'dest.mp3',
          startMs: 6000,
          endMs: 5000,
        ),
        throwsArgumentError,
      );
    });

    test(
      'trimAudio throws FileNotFoundException when source does not exist',
      () async {
        expect(
          () => service.trimAudio(
            sourcePath: 'non_existent_file_path.mp3',
            destinationPath: 'dest.mp3',
            startMs: 1000,
            endMs: 5000,
          ),
          throwsA(isA<FileNotFoundException>()),
        );
      },
    );
  });

  group('AudioCutterService Export Path Tests', () {
    test(
      'getDefaultExportPath generates valid file path with sanitized title',
      () async {
        final path = await service.getDefaultExportPath(
          originalPath: '/storage/music/my_song.mp3',
          title: 'Bohemian Rhapsody: Live / Queen',
          extension: 'm4a',
        );

        expect(path, contains('Bohemian_Rhapsody__Live___Queen_clip_'));
        expect(path, endsWith('.m4a'));
      },
    );
  });

  group('AudioCutterService WAV Trimmer Fallback', () {
    test('Trims synthetic WAV file accurately', () async {
      final tempDir = Directory.systemTemp.createTempSync('wav_test');
      final srcWav = File('${tempDir.path}/test.wav');
      final destWav = File('${tempDir.path}/test_cut.wav');

      // 44-byte standard PCM 16-bit 44100Hz stereo WAV header
      const sampleRate = 44100;
      const channels = 2;
      const bitsPerSample = 16;
      const byteRate =
          sampleRate * channels * (bitsPerSample ~/ 8); // 176400 bytes/sec
      const blockAlign = channels * (bitsPerSample ~/ 8); // 4 bytes

      // Generate 2 seconds of audio (352800 bytes)
      const dataSize = byteRate * 2;
      final wavBytes = Uint8List(44 + dataSize);
      final byteData = ByteData.sublistView(wavBytes);

      // RIFF header
      wavBytes.setRange(0, 4, 'RIFF'.codeUnits);
      byteData.setUint32(4, 36 + dataSize, Endian.little);
      wavBytes.setRange(8, 12, 'WAVE'.codeUnits);

      // fmt subchunk
      wavBytes.setRange(12, 16, 'fmt '.codeUnits);
      byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
      byteData.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
      byteData.setUint16(22, channels, Endian.little);
      byteData.setUint32(24, sampleRate, Endian.little);
      byteData.setUint32(28, byteRate, Endian.little);
      byteData.setUint16(32, blockAlign, Endian.little);
      byteData.setUint16(34, bitsPerSample, Endian.little);

      // data subchunk
      wavBytes.setRange(36, 40, 'data'.codeUnits);
      byteData.setUint32(40, dataSize, Endian.little);

      // Fill with dummy PCM samples
      for (var i = 44; i < wavBytes.length; i++) {
        wavBytes[i] = (i % 256);
      }

      await srcWav.writeAsBytes(wavBytes);

      // Slice from 500ms to 1500ms (1 second total)
      final success = await service.trimAudio(
        sourcePath: srcWav.path,
        destinationPath: destWav.path,
        startMs: 500,
        endMs: 1500,
      );

      expect(success, isTrue);
      expect(await destWav.exists(), isTrue);

      final cutBytes = await destWav.readAsBytes();
      final cutByteData = ByteData.sublistView(cutBytes);
      final cutDataSize = cutByteData.getUint32(40, Endian.little);

      // 1 second of data should equal byteRate = 176400 bytes
      expect(cutDataSize, equals(byteRate));
      expect(cutBytes.length, equals(44 + byteRate));

      tempDir.deleteSync(recursive: true);
    });
  });
}
