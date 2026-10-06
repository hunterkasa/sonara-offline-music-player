import 'dart:math';

import '../../domain/services/lrc_parser.dart';

/// Formatter and builder for standard synchronized LRC files.
class LrcBuilder {
  /// Builds a complete .lrc file string with metadata headers and timestamps.
  static String build({
    required List<LyricLine> lines,
    String? title,
    String? artist,
    String? album,
    String? author,
    Duration offset = Duration.zero,
  }) {
    final buffer = StringBuffer();

    // Headers
    if (title != null && title.trim().isNotEmpty) {
      buffer.writeln('[ti:${title.trim()}]');
    }
    if (artist != null && artist.trim().isNotEmpty) {
      buffer.writeln('[ar:${artist.trim()}]');
    }
    if (album != null && album.trim().isNotEmpty) {
      buffer.writeln('[al:${album.trim()}]');
    }
    buffer.writeln(
      '[by:${author?.trim().isNotEmpty == true ? author!.trim() : "Sonara Studio"}]',
    );

    if (offset != Duration.zero) {
      buffer.writeln('[offset:${offset.inMilliseconds}]');
    }

    // Sorted lines
    final sorted = List<LyricLine>.from(lines)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final line in sorted) {
      final formattedTime = formatTimestamp(line.timestamp);
      buffer.writeln('$formattedTime${line.text}');
    }

    return buffer.toString();
  }

  /// Formats a [Duration] into `[mm:ss.xx]` centisecond format.
  static String formatTimestamp(Duration duration) {
    final totalMilliseconds = max(0, duration.inMilliseconds);
    final minutes = totalMilliseconds ~/ 60000;
    final seconds = (totalMilliseconds % 60000) ~/ 1000;
    final centiseconds = (totalMilliseconds % 1000) ~/ 10;

    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    final xx = centiseconds.toString().padLeft(2, '0');

    return '[$mm:$ss.$xx]';
  }

  /// Parses plain-text (unsynchronized) lyrics into untimed [LyricLine] structures (timestamp = zero).
  static List<LyricLine> parsePlainTextLines(String plainText) {
    if (plainText.trim().isEmpty) return [];

    final rawLines = plainText.split(RegExp(r'\r?\n'));
    final result = <LyricLine>[];

    for (final line in rawLines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        result.add(LyricLine(timestamp: Duration.zero, text: trimmed));
      }
    }

    return result;
  }

  /// Shifts all timestamps by a delta duration.
  static List<LyricLine> shiftTimestamps(
    List<LyricLine> lines,
    Duration delta,
  ) {
    return lines.map((line) {
      final shiftedMs = max(
        0,
        line.timestamp.inMilliseconds + delta.inMilliseconds,
      );
      return LyricLine(
        timestamp: Duration(milliseconds: shiftedMs),
        text: line.text,
      );
    }).toList();
  }
}
