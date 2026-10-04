import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/core/utils/metadata_utils.dart';

void main() {
  group('MetadataUtils', () {
    test('normalizeSortName strips leading English articles', () {
      expect(MetadataUtils.normalizeSortName('The Beatles'), 'Beatles');
      expect(
        MetadataUtils.normalizeSortName('the rolling stones'),
        'rolling stones',
      );
      expect(
        MetadataUtils.normalizeSortName('A Day to Remember'),
        'Day to Remember',
      );
      expect(
        MetadataUtils.normalizeSortName('An Endless Sporadic'),
        'Endless Sporadic',
      );
      expect(MetadataUtils.normalizeSortName('Pink Floyd'), 'Pink Floyd');
      expect(MetadataUtils.normalizeSortName('   The Who   '), 'Who');
      expect(MetadataUtils.normalizeSortName(''), '');
    });

    test('splitArtists handles various delimiters', () {
      expect(MetadataUtils.splitArtists('Queen & David Bowie'), [
        'Queen',
        'David Bowie',
      ]);
      expect(MetadataUtils.splitArtists('Daft Punk feat. Pharrell Williams'), [
        'Daft Punk',
        'Pharrell Williams',
      ]);
      expect(MetadataUtils.splitArtists('Artist A; Artist B / Artist C'), [
        'Artist A',
        'Artist B',
        'Artist C',
      ]);
      expect(MetadataUtils.splitArtists('Eminem ft. Rihanna, Skylar Grey'), [
        'Eminem',
        'Rihanna',
        'Skylar Grey',
      ]);
      expect(MetadataUtils.splitArtists(''), ['Unknown Artist']);
    });

    test('resolveTitle provides correct fallbacks', () {
      expect(
        MetadataUtils.resolveTitle('Bohemian Rhapsody', '/music/01-track.mp3'),
        'Bohemian Rhapsody',
      );
      expect(
        MetadataUtils.resolveTitle(
          null,
          '/music/Rock/01 - Stairway to Heaven.flac',
        ),
        '01 - Stairway to Heaven',
      );
      expect(MetadataUtils.resolveTitle('', '/music/song.mp3'), 'song');
    });

    test('resolveAlbum provides correct folder fallbacks', () {
      expect(
        MetadataUtils.resolveAlbum('Abbey Road', '/music/Abbey Road/01.mp3'),
        'Abbey Road',
      );
      expect(
        MetadataUtils.resolveAlbum(null, '/music/Rock Classics/song.mp3'),
        'Rock Classics',
      );
      expect(MetadataUtils.resolveAlbum('', '/song.mp3'), 'Unknown Album');
    });

    test('resolveArtist provides Unknown Artist fallback', () {
      expect(MetadataUtils.resolveArtist('Led Zeppelin'), 'Led Zeppelin');
      expect(MetadataUtils.resolveArtist(null), 'Unknown Artist');
      expect(MetadataUtils.resolveArtist('   '), 'Unknown Artist');
    });

    test('resolveAlbumArtist resolves primary artist if absent', () {
      expect(
        MetadataUtils.resolveAlbumArtist('Various Artists', 'Queen'),
        'Various Artists',
      );
      expect(
        MetadataUtils.resolveAlbumArtist(null, 'Pink Floyd'),
        'Pink Floyd',
      );
    });
  });
}
