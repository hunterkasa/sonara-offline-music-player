import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/sources/tag_reader.dart';
import 'package:sonara/data/sources/tag_writer.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tag_writer_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'TagWriter writes ID3v2 tags to MP3 and TagReader reads them back',
    () async {
      final mp3File = File('${tempDir.path}/test.mp3');

      // Create a dummy MP3 with 500 bytes of dummy frame data
      final dummyData = Uint8List(500);
      // Dummy MP3 sync word
      dummyData[0] = 0xFF;
      dummyData[1] = 0xFB;
      await mp3File.writeAsBytes(dummyData);

      const metadata = EditableMetadata(
        title: 'Comfortably Numb',
        artist: 'Pink Floyd',
        album: 'The Wall',
        year: 1979,
        trackNumber: 6,
        discNumber: 2,
        genre: 'Progressive Rock',
      );

      final success = await TagWriter.writeTags(mp3File, metadata);
      expect(success, isTrue);

      // Read back using TagReader
      final readBack = await TagReader.readFromFile(mp3File);
      expect(readBack.title, 'Comfortably Numb');
      expect(readBack.artist, 'Pink Floyd');
      expect(readBack.album, 'The Wall');
      expect(readBack.year, 1979);
      expect(readBack.trackNumber, 6);
      expect(readBack.discNumber, 2);
      expect(readBack.genres, contains('Progressive Rock'));
    },
  );

  test('TagWriter writes Vorbis comment blocks to FLAC and TagReader reads them back', () async {
    final flacFile = File('${tempDir.path}/test.flac');

    // Create minimal valid FLAC file with STREAMINFO block (34 bytes)
    final flacBytes = BytesBuilder();
    // 'fLaC' magic
    flacBytes.add([0x66, 0x4C, 0x61, 0x43]);
    // STREAMINFO header (isLast=1, type=0, length=34)
    flacBytes.add([0x80, 0x00, 0x00, 0x22]);
    // 34 bytes dummy streaminfo
    flacBytes.add(Uint8List(34));
    // Dummy audio frame bytes
    flacBytes.add(Uint8List(200));

    await flacFile.writeAsBytes(flacBytes.takeBytes());

    const metadata = EditableMetadata(
      title: 'Time',
      artist: 'Pink Floyd',
      album: 'The Dark Side of the Moon',
      year: 1973,
      trackNumber: 4,
      discNumber: 1,
      genre: 'Rock',
    );

    final success = await TagWriter.writeTags(flacFile, metadata);
    expect(success, isTrue);

    // Read back using TagReader
    final readBack = await TagReader.readFromFile(flacFile);
    expect(readBack.title, 'Time');
    expect(readBack.artist, 'Pink Floyd');
    expect(readBack.album, 'The Dark Side of the Moon');
    expect(readBack.year, 1973);
    expect(readBack.trackNumber, 4);
    expect(readBack.discNumber, 1);
    expect(readBack.genres, contains('Rock'));
  });

  test('TagWriter returns false gracefully for non-existent files', () async {
    final missingFile = File('${tempDir.path}/non_existent.mp3');
    const metadata = EditableMetadata(
      title: 'Test',
      artist: 'Test',
      album: 'Test',
    );
    final result = await TagWriter.writeTags(missingFile, metadata);
    expect(result, isFalse);
  });

  test('TagWriter writes Unicode/multilingual ID3v2 tags (UTF-16) without corruption', () async {
    final mp3File = File('${tempDir.path}/unicode_test.mp3');
    final dummyData = Uint8List(500);
    dummyData[0] = 0xFF;
    dummyData[1] = 0xFB;
    await mp3File.writeAsBytes(dummyData);

    const metadata = EditableMetadata(
      title: '夜に駆ける (Racing into the Night)',
      artist: 'YOASOBI',
      album: 'THE BOOK',
      year: 2021,
      genre: 'J-Pop',
    );

    final success = await TagWriter.writeTags(mp3File, metadata);
    expect(success, isTrue);

    final readBack = await TagReader.readFromFile(mp3File);
    expect(readBack.title, '夜に駆ける (Racing into the Night)');
    expect(readBack.artist, 'YOASOBI');
    expect(readBack.album, 'THE BOOK');
    expect(readBack.year, 2021);
    expect(readBack.genres, contains('J-Pop'));
  });
}
