import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/core/utils/lrc_builder.dart';
import 'package:sonara/domain/services/lrc_parser.dart';

void main() {
  group('LrcBuilder Tests', () {
    test('builds valid standard .lrc file with headers and timestamps', () {
      final lines = [
        const LyricLine(
          timestamp: Duration(seconds: 12, milliseconds: 340),
          text: 'First line',
        ),
        const LyricLine(
          timestamp: Duration(seconds: 25, milliseconds: 80),
          text: 'Second line',
        ),
      ];

      final output = LrcBuilder.build(
        lines: lines,
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
      );

      expect(output, contains('[ti:Bohemian Rhapsody]'));
      expect(output, contains('[ar:Queen]'));
      expect(output, contains('[al:A Night at the Opera]'));
      expect(output, contains('[by:Sonara Studio]'));
      expect(output, contains('[00:12.34]First line'));
      expect(output, contains('[00:25.08]Second line'));

      // Verify it round-trips through LrcParser
      final parsed = LrcParser.parse(output);
      expect(parsed.isSynced, isTrue);
      expect(parsed.lines.length, 2);
      expect(parsed.lines[0].text, 'First line');
      expect(parsed.lines[0].timestamp.inSeconds, 12);
      expect(parsed.lines[1].text, 'Second line');
      expect(parsed.lines[1].timestamp.inSeconds, 25);
    });

    test('formatTimestamp formats centiseconds properly', () {
      expect(LrcBuilder.formatTimestamp(Duration.zero), '[00:00.00]');
      expect(
        LrcBuilder.formatTimestamp(
          const Duration(minutes: 1, seconds: 5, milliseconds: 780),
        ),
        '[01:05.78]',
      );
      expect(
        LrcBuilder.formatTimestamp(
          const Duration(minutes: 12, seconds: 34, milliseconds: 560),
        ),
        '[12:34.56]',
      );
    });

    test('parsePlainTextLines converts plain text paragraphs to zero-timestamp lines', () {
      const text = '''
      Hello world
      Is there anybody in there?

      Just nod if you can hear me.
      ''';

      final parsed = LrcBuilder.parsePlainTextLines(text);
      expect(parsed.length, 3);
      expect(parsed[0].text, 'Hello world');
      expect(parsed[0].timestamp, Duration.zero);
      expect(parsed[1].text, 'Is there anybody in there?');
      expect(parsed[2].text, 'Just nod if you can hear me.');
    });

    test(
      'shiftTimestamps adjusts all timestamps by positive or negative delta',
      () {
        final lines = [
          const LyricLine(timestamp: Duration(seconds: 5), text: 'Line 1'),
          const LyricLine(timestamp: Duration(seconds: 10), text: 'Line 2'),
        ];

        final shiftedPositive = LrcBuilder.shiftTimestamps(
          lines,
          const Duration(milliseconds: 500),
        );
        expect(shiftedPositive[0].timestamp.inMilliseconds, 5500);
        expect(shiftedPositive[1].timestamp.inMilliseconds, 10500);

        final shiftedNegative = LrcBuilder.shiftTimestamps(
          lines,
          const Duration(milliseconds: -1000),
        );
        expect(shiftedNegative[0].timestamp.inMilliseconds, 4000);
        expect(shiftedNegative[1].timestamp.inMilliseconds, 9000);

        // Clamps to zero
        final shiftedUnderflow = LrcBuilder.shiftTimestamps(
          lines,
          const Duration(seconds: -10),
        );
        expect(shiftedUnderflow[0].timestamp, Duration.zero);
      },
    );
  });
}
