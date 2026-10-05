import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/domain/services/lrc_parser.dart';

void main() {
  group('LrcParser Unit Tests', () {
    test('parses empty string gracefully', () {
      final lyrics = LrcParser.parse('');
      expect(lyrics.isEmpty, isTrue);
      expect(lyrics.isSynced, isFalse);
      expect(lyrics.lines, isEmpty);
      expect(lyrics.getActiveIndex(Duration.zero), equals(-1));
    });

    test('parses standard timestamped LRC lines', () {
      const lrcContent = '''
[ti:Sample Song]
[ar:Sonara Artist]
[00:01.00]First line of lyrics
[00:03.50]Second line of lyrics
[00:07.250]Third line with 3 digit milliseconds
''';

      final lyrics = LrcParser.parse(lrcContent);
      expect(lyrics.isSynced, isTrue);
      expect(lyrics.lines.length, equals(3));

      expect(lyrics.lines[0].timestamp, equals(const Duration(seconds: 1)));
      expect(lyrics.lines[0].text, equals('First line of lyrics'));

      expect(
        lyrics.lines[1].timestamp,
        equals(const Duration(milliseconds: 3500)),
      );
      expect(lyrics.lines[1].text, equals('Second line of lyrics'));

      expect(
        lyrics.lines[2].timestamp,
        equals(const Duration(milliseconds: 7250)),
      );
      expect(
        lyrics.lines[2].text,
        equals('Third line with 3 digit milliseconds'),
      );
    });

    test('handles repeated timestamps on single line', () {
      const lrcContent = '''
[00:02.00][00:08.00]Chorus repeats here
''';

      final lyrics = LrcParser.parse(lrcContent);
      expect(lyrics.isSynced, isTrue);
      expect(lyrics.lines.length, equals(2));
      expect(lyrics.lines[0].timestamp, equals(const Duration(seconds: 2)));
      expect(lyrics.lines[0].text, equals('Chorus repeats here'));
      expect(lyrics.lines[1].timestamp, equals(const Duration(seconds: 8)));
      expect(lyrics.lines[1].text, equals('Chorus repeats here'));
    });

    test('applies [offset:+/-ms] tag to timestamps', () {
      const lrcContent = '''
[offset:500]
[00:02.00]Line with offset
''';

      final lyrics = LrcParser.parse(lrcContent);
      expect(lyrics.offset, equals(const Duration(milliseconds: 500)));
      // Base line timestamp is 2000ms. With offset +500ms, adjusted time = position - offset.
      // So at position 2500ms, adjusted = 2000ms -> active!
      expect(
        lyrics.getActiveIndex(const Duration(milliseconds: 2400)),
        equals(-1),
      );
      expect(
        lyrics.getActiveIndex(const Duration(milliseconds: 2500)),
        equals(0),
      );
    });

    test('falls back cleanly to plain text if no timestamps found', () {
      const plainText = '''
Verse 1:
This is a plain lyrics text
Without any timestamps
''';

      final lyrics = LrcParser.parse(plainText);
      expect(lyrics.isSynced, isFalse);
      expect(lyrics.lines, isEmpty);
      expect(lyrics.rawText, equals(plainText));
      expect(lyrics.isNotEmpty, isTrue);
    });

    test(
      'getActiveIndex returns correct line index across playback progression',
      () {
        const lrcContent = '''
[00:02.00]Line 1
[00:05.00]Line 2
[00:10.00]Line 3
''';

        final lyrics = LrcParser.parse(lrcContent);

        // Before first line
        expect(lyrics.getActiveIndex(const Duration(seconds: 1)), equals(-1));

        // Exactly at first line
        expect(lyrics.getActiveIndex(const Duration(seconds: 2)), equals(0));

        // Between first and second
        expect(lyrics.getActiveIndex(const Duration(seconds: 3)), equals(0));

        // Exactly at second line
        expect(lyrics.getActiveIndex(const Duration(seconds: 5)), equals(1));

        // Between second and third
        expect(lyrics.getActiveIndex(const Duration(seconds: 8)), equals(1));

        // At third line
        expect(lyrics.getActiveIndex(const Duration(seconds: 10)), equals(2));

        // Past third line
        expect(lyrics.getActiveIndex(const Duration(seconds: 60)), equals(2));
      },
    );
  });
}
