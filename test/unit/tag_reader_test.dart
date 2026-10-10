import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/sources/tag_reader.dart';

void main() {
  group('TagReader', () {
    test('handles non-existent files gracefully without throwing', () async {
      final meta = await TagReader.readFromFile(
        File('/non/existent/track.mp3'),
      );
      expect(meta.title, 'track');
      expect(meta.artist, 'Unknown Artist');
      expect(meta.album, 'existent');
    });

    test('handles zero-byte or corrupt files gracefully', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_corrupt.mp3');
      await tempFile.writeAsBytes([0x00, 0x01, 0x02, 0x03]);
      try {
        final meta = await TagReader.readFromFile(tempFile);
        expect(meta.title, 'test_corrupt');
        expect(meta.artist, 'Unknown Artist');
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });

    test('parses ID3v1 metadata correctly', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_id3v1.mp3');
      // Create 128 bytes with 'TAG' prefix
      final bytes = List<int>.filled(128, 0);
      bytes[0] = 0x54; // T
      bytes[1] = 0x41; // A
      bytes[2] = 0x47; // G

      // Title: 'Test Title' at offset 3
      final titleBytes = 'Test Title'.codeUnits;
      for (var i = 0; i < titleBytes.length; i++) {
        bytes[3 + i] = titleBytes[i];
      }

      // Artist: 'Test Artist' at offset 33
      final artistBytes = 'Test Artist'.codeUnits;
      for (var i = 0; i < artistBytes.length; i++) {
        bytes[33 + i] = artistBytes[i];
      }

      await tempFile.writeAsBytes(bytes);
      try {
        final meta = await TagReader.readFromFile(tempFile);
        expect(meta.title, 'Test Title');
        expect(meta.artist, 'Test Artist');
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });

    test('parses ID3v2 metadata frames correctly', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_id3v2.mp3');

      // Helper to build a text frame
      List<int> makeTextFrame(String frameId, String text) {
        final textBytes = [0, ...text.codeUnits]; // 0 = ISO-8859-1
        final size = textBytes.length;
        return [
          ...frameId.codeUnits,
          (size >> 24) & 0xFF,
          (size >> 16) & 0xFF,
          (size >> 8) & 0xFF,
          size & 0xFF,
          0x00,
          0x00, // flags
          ...textBytes,
        ];
      }

      final frame1 = makeTextFrame('TIT2', 'ID3v2 Title');
      final frame2 = makeTextFrame('TPE1', 'ID3v2 Artist');
      final frame3 = makeTextFrame('TALB', 'ID3v2 Album');
      final allFrames = [...frame1, ...frame2, ...frame3];

      final tagSize = allFrames.length;
      final header = [
        0x49, 0x44, 0x33, // 'ID3'
        0x03, 0x00, // v2.3.0
        0x00, // flags
        (tagSize >> 21) & 0x7F,
        (tagSize >> 14) & 0x7F,
        (tagSize >> 7) & 0x7F,
        tagSize & 0x7F,
      ];

      // Pad to >= 128 bytes for minimum file size check
      final fullBytes = [...header, ...allFrames];
      while (fullBytes.length < 150) {
        fullBytes.add(0);
      }

      await tempFile.writeAsBytes(fullBytes);
      try {
        final meta = await TagReader.readFromFile(tempFile);
        expect(meta.title, 'ID3v2 Title');
        expect(meta.artist, 'ID3v2 Artist');
        expect(meta.album, 'ID3v2 Album');
        expect(meta.codec, 'MP3');
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });

    test('parses FLAC file with invalid header safely', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_corrupt.flac');
      await tempFile.writeAsBytes(List<int>.filled(140, 0));
      try {
        final meta = await TagReader.readFromFile(tempFile);
        expect(meta.title, 'test_corrupt');
        expect(meta.artist, 'Unknown Artist');
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });

    test('parses ID3v2 USLT unsynced lyrics correctly', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_uslt.mp3');

      // USLT frame:
      // encoding: 0 (latin1), lang: 'eng', descriptor: null (0), text: 'Hello World Lyrics'
      const lyricsText = 'Hello World Lyrics';
      final payload = [
        0x00, // encoding
        0x65, 0x6E, 0x67, // 'eng'
        0x00, // descriptor null terminator
        ...lyricsText.codeUnits,
      ];
      final size = payload.length;
      final frame = [
        ...'USLT'.codeUnits,
        (size >> 24) & 0xFF,
        (size >> 16) & 0xFF,
        (size >> 8) & 0xFF,
        size & 0xFF,
        0x00, 0x00, // flags
        ...payload,
      ];

      final tagSize = frame.length;
      final header = [
        0x49, 0x44, 0x33, // 'ID3'
        0x03, 0x00, // v2.3.0
        0x00, // flags
        (tagSize >> 21) & 0x7F,
        (tagSize >> 14) & 0x7F,
        (tagSize >> 7) & 0x7F,
        tagSize & 0x7F,
      ];

      final fullBytes = [...header, ...frame];
      while (fullBytes.length < 150) {
        fullBytes.add(0);
      }

      await tempFile.writeAsBytes(fullBytes);
      try {
        final meta = await TagReader.readFromFile(tempFile);
        expect(meta.lyrics, equals('Hello World Lyrics'));
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });

    test('parses ID3v2 SYLT synced lyrics into timestamped lines', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_sylt.mp3');

      // SYLT frame:
      // encoding: 0 (latin1), lang: 'eng', time format: 2 (ms), content type: 1 (lyrics), descriptor: 0
      // syllable/line: 'Verse One', null, 4 bytes timestamp (1500ms = 0x000005DC)
      const lineText = 'Verse One';
      const timestampMs = 1500;
      final payload = [
        0x00, // encoding
        0x65, 0x6E, 0x67, // 'eng'
        0x02, // time format (milliseconds)
        0x01, // content type (lyrics)
        0x00, // descriptor null terminator
        ...lineText.codeUnits,
        0x00, // null separator
        (timestampMs >> 24) & 0xFF,
        (timestampMs >> 16) & 0xFF,
        (timestampMs >> 8) & 0xFF,
        timestampMs & 0xFF,
      ];
      final size = payload.length;
      final frame = [
        ...'SYLT'.codeUnits,
        (size >> 24) & 0xFF,
        (size >> 16) & 0xFF,
        (size >> 8) & 0xFF,
        size & 0xFF,
        0x00, 0x00, // flags
        ...payload,
      ];

      final tagSize = frame.length;
      final header = [
        0x49, 0x44, 0x33, // 'ID3'
        0x03, 0x00, // v2.3.0
        0x00, // flags
        (tagSize >> 21) & 0x7F,
        (tagSize >> 14) & 0x7F,
        (tagSize >> 7) & 0x7F,
        tagSize & 0x7F,
      ];

      final fullBytes = [...header, ...frame];
      while (fullBytes.length < 150) {
        fullBytes.add(0);
      }

      await tempFile.writeAsBytes(fullBytes);
      try {
        final meta = await TagReader.readFromFile(tempFile);
        expect(meta.lyrics, isNotNull);
        expect(meta.lyrics, contains('[00:01.50] Verse One'));
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });
  });
}
