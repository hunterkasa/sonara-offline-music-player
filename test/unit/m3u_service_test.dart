import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/m3u_service.dart';

void main() {
  late AppDatabase db;
  late M3uService m3uService;

  setUp(() async {
    db = AppDatabase.inMemory();
    m3uService = M3uService(db);

    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            trackKey: 'key_bohemian',
            contentUri: 'content://audio/101',
            path: '/storage/emulated/0/Music/Queen/Bohemian Rhapsody.mp3',
            relativeDir: const Value('Music/Queen'),
            title: 'Bohemian Rhapsody',
            titleSort: 'bohemian rhapsody',
            durationMs: 354000,
            sizeBytes: 8000000,
          ),
        );
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            trackKey: 'key_hotel',
            contentUri: 'content://audio/102',
            path: '/storage/emulated/0/Music/Eagles/Hotel California.flac',
            relativeDir: const Value('Music/Eagles'),
            title: 'Hotel California',
            titleSort: 'hotel california',
            durationMs: 390000,
            sizeBytes: 25000000,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('M3uService Tests', () {
    test('parseM3u parses extended M3U (#EXTINF) with duration, title, artist, and path', () {
      const m3uContent = '''
#EXTM3U
#EXTINF:354,Queen - Bohemian Rhapsody
/storage/emulated/0/Music/Queen/Bohemian Rhapsody.mp3
#EXTINF:390,Eagles - Hotel California
Music/Eagles/Hotel California.flac
''';

      final entries = m3uService.parseM3u(m3uContent);
      expect(entries.length, equals(2));

      expect(entries[0].durationSeconds, equals(354));
      expect(entries[0].artist, equals('Queen'));
      expect(entries[0].title, equals('Bohemian Rhapsody'));
      expect(
        entries[0].path,
        equals('/storage/emulated/0/Music/Queen/Bohemian Rhapsody.mp3'),
      );

      expect(entries[1].durationSeconds, equals(390));
      expect(entries[1].artist, equals('Eagles'));
      expect(entries[1].title, equals('Hotel California'));
      expect(entries[1].path, equals('Music/Eagles/Hotel California.flac'));
    });

    test('parseM3u handles simple paths without EXTINF metadata', () {
      const simpleM3u = '''
/storage/Music/song1.mp3
/storage/Music/song2.mp3
''';

      final entries = m3uService.parseM3u(simpleM3u);
      expect(entries.length, equals(2));
      expect(entries[0].path, equals('/storage/Music/song1.mp3'));
      expect(entries[0].durationSeconds, equals(-1));
      expect(entries[1].path, equals('/storage/Music/song2.mp3'));
    });

    test('exportPlaylistToM3u generates valid #EXTM3U format', () async {
      final plId = await db.createPlaylist(name: 'Road Trip');
      await db.addTracksToPlaylist(plId, ['key_bohemian', 'key_hotel']);

      final exported = await m3uService.exportPlaylistToM3u(plId);

      expect(exported, contains('#EXTM3U'));
      expect(exported, contains('#PLAYLIST:Road Trip'));
      expect(exported, contains('#EXTINF:354,'));
      expect(exported, contains('Bohemian Rhapsody'));
      expect(exported, contains('#EXTINF:390,'));
      expect(exported, contains('Hotel California'));
    });

    test(
      'matchEntriesToTrackKeys matches by path, filename, and title',
      () async {
        final entries = [
          const M3uEntry(
            path: '/storage/emulated/0/Music/Queen/Bohemian Rhapsody.mp3',
            title: 'Bohemian Rhapsody',
            artist: 'Queen',
          ),
          const M3uEntry(
            path: 'OtherDrive:/Folder/Hotel California.flac',
            title: 'Hotel California',
          ),
          const M3uEntry(
            path: '/unknown/missing.mp3',
            title: 'Non-existent Song',
          ),
        ];

        final matchedKeys = await m3uService.matchEntriesToTrackKeys(entries);
        expect(matchedKeys.length, equals(2));
        expect(matchedKeys, contains('key_bohemian'));
        expect(matchedKeys, contains('key_hotel'));
      },
    );
  });
}
