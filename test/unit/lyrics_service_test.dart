import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/lrc_parser.dart';
import 'package:sonara/domain/services/lyrics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LyricsService lyricsService;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase.inMemory();
    lyricsService = LyricsService(db: db);
    tempDir = await Directory.systemTemp.createTemp('sonara_lyrics_test_');
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('loadLyrics finds and parses sidecar .lrc file', () async {
    final audioFile = File('${tempDir.path}/song.mp3');
    await audioFile.writeAsString('dummy mp3 content');

    final lrcFile = File('${tempDir.path}/song.lrc');
    await lrcFile.writeAsString(
      '[00:10.00]First line\n[00:20.00]Second line\n',
    );

    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            trackKey: 'key_1',
            contentUri: 'content://test/1',
            path: audioFile.path,
            title: 'Test Song',
            titleSort: 'test song',
            durationMs: 60000,
            sizeBytes: 1000,
          ),
        );

    final track = await (db.select(
      db.tracks,
    )..where((t) => t.trackKey.equals('key_1'))).getSingle();

    final lyrics = await lyricsService.loadLyrics(track);
    expect(lyrics.isSynced, isTrue);
    expect(lyrics.lines.length, equals(2));
    expect(lyrics.lines[0].text, equals('First line'));
    expect(lyrics.lines[1].text, equals('Second line'));

    // Cache hit verification
    await lrcFile.delete();
    final cached = await lyricsService.loadLyrics(track);
    expect(cached.lines.length, equals(2));
  });

  test(
    'loadLyrics returns empty SongLyrics when file does not exist',
    () async {
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'key_missing',
              contentUri: 'content://test/2',
              path: '${tempDir.path}/nonexistent.mp3',
              title: 'Missing Song',
              titleSort: 'missing song',
              durationMs: 60000,
              sizeBytes: 1000,
            ),
          );

      final track = await (db.select(
        db.tracks,
      )..where((t) => t.trackKey.equals('key_missing'))).getSingle();

      final lyrics = await lyricsService.loadLyrics(track);
      expect(lyrics.isEmpty, isTrue);
      expect(lyrics, equals(SongLyrics.empty));
    },
  );

  test('clearCache empties the memory cache', () async {
    final audioFile = File('${tempDir.path}/song2.mp3');
    await audioFile.writeAsString('dummy');
    final lrcFile = File('${tempDir.path}/song2.lrc');
    await lrcFile.writeAsString('[00:05.00]Line 1');

    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            trackKey: 'key_2',
            contentUri: 'content://test/3',
            path: audioFile.path,
            title: 'Song 2',
            titleSort: 'song 2',
            durationMs: 30000,
            sizeBytes: 1000,
          ),
        );

    final track = await (db.select(
      db.tracks,
    )..where((t) => t.trackKey.equals('key_2'))).getSingle();

    await lyricsService.loadLyrics(track);
    await lrcFile.delete();

    lyricsService.clearCache();
    final fresh = await lyricsService.loadLyrics(track);
    expect(fresh.isEmpty, isTrue);
  });
}
