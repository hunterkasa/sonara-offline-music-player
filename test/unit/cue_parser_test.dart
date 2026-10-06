import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/core/utils/cue_parser.dart';

void main() {
  group('CueParser Tests', () {
    test(
      'parses standard CUE sheet with multiple tracks, performer and titles',
      () {
        const cueContent = '''
REM GENRE "Progressive Rock"
REM DATE 1973
PERFORMER "Pink Floyd"
TITLE "The Dark Side of the Moon"
FILE "The Dark Side of the Moon.flac" WAVE
  TRACK 01 AUDIO
    TITLE "Speak to Me"
    PERFORMER "Pink Floyd"
    INDEX 01 00:00:00
  TRACK 02 AUDIO
    TITLE "Breathe"
    PERFORMER "Pink Floyd"
    INDEX 01 01:05:35
  TRACK 03 AUDIO
    TITLE "On the Run"
    PERFORMER "Pink Floyd"
    INDEX 01 03:54:62
''';

        final sheet = CueParser.parse(
          cueContent,
          parentDuration: const Duration(minutes: 7, seconds: 30),
        );

        expect(sheet.album, 'The Dark Side of the Moon');
        expect(sheet.albumArtist, 'Pink Floyd');
        expect(sheet.defaultAudioFile, 'The Dark Side of the Moon.flac');
        expect(sheet.tracks.length, 3);

        // Track 1
        final t1 = sheet.tracks[0];
        expect(t1.trackNumber, 1);
        expect(t1.title, 'Speak to Me');
        expect(t1.artist, 'Pink Floyd');
        expect(t1.startTime, Duration.zero);
        // 01:05:35 = 65 seconds + 35 frames (35*1000/75 = 467ms) = 65467ms
        expect(t1.endTime?.inSeconds, 65);
        expect(t1.duration?.inSeconds, 65);

        // Track 2
        final t2 = sheet.tracks[1];
        expect(t2.trackNumber, 2);
        expect(t2.title, 'Breathe');
        expect(t2.startTime.inSeconds, 65);
        // 03:54:62 = 234 seconds + 62 frames (62*1000/75 = 827ms) = 234827ms
        expect(t2.endTime?.inSeconds, 234);

        // Track 3
        final t3 = sheet.tracks[2];
        expect(t3.trackNumber, 3);
        expect(t3.title, 'On the Run');
        expect(t3.startTime.inSeconds, 234);
        expect(t3.endTime, const Duration(minutes: 7, seconds: 30));
      },
    );

    test(
      'handles empty and malformed CUE content gracefully without crashing',
      () {
        final empty = CueParser.parse('');
        expect(empty.tracks, isEmpty);
        expect(empty.album, isEmpty);

        final malformed = CueParser.parse('FOOBAR BAZ\nINVALID DATA\n');
        expect(malformed.tracks, isEmpty);
      },
    );

    test('inherits album performer if track performer is not specified', () {
      const cueContent = '''
PERFORMER "Miles Davis"
TITLE "Kind of Blue"
FILE "album.wav" WAVE
  TRACK 01 AUDIO
    TITLE "So What"
    INDEX 01 00:00:00
  TRACK 02 AUDIO
    TITLE "Freddie Freeloader"
    INDEX 01 09:22:00
''';

      final sheet = CueParser.parse(cueContent);
      expect(sheet.tracks.length, 2);
      expect(sheet.tracks[0].artist, 'Miles Davis');
      expect(sheet.tracks[1].artist, 'Miles Davis');
      expect(sheet.tracks[0].audioFileName, 'album.wav');
    });
  });
}
