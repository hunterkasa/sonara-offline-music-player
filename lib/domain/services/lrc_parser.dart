import 'package:flutter/foundation.dart';

@immutable
class LyricLine {
  const LyricLine({required this.timestamp, required this.text});

  final Duration timestamp;
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricLine &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          text == other.text;

  @override
  int get hashCode => timestamp.hashCode ^ text.hashCode;

  @override
  String toString() => '[${timestamp.inMilliseconds}ms] $text';
}

@immutable
class SongLyrics {
  const SongLyrics({
    required this.lines,
    this.rawText,
    required this.isSynced,
    this.offset = Duration.zero,
  });

  final List<LyricLine> lines;
  final String? rawText;
  final bool isSynced;
  final Duration offset;

  static const SongLyrics empty = SongLyrics(
    lines: [],
    rawText: '',
    isSynced: false,
  );

  bool get isEmpty => lines.isEmpty && (rawText == null || rawText!.isEmpty);
  bool get isNotEmpty => !isEmpty;

  /// Returns the index of the active lyric line at [position].
  /// Returns -1 if [position] is before the first lyric line or if [lines] is empty.
  int getActiveIndex(Duration position) {
    if (lines.isEmpty) return -1;
    final adjusted = position - offset;
    if (adjusted < lines.first.timestamp) return -1;

    var low = 0;
    var high = lines.length - 1;
    var best = -1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (lines[mid].timestamp <= adjusted) {
        best = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return best;
  }
}

class LrcParser {
  static final RegExp _tagRegex = RegExp(r'^\[([a-zA-Z]+):([^\]]*)\]');
  static final RegExp _timestampRegex = RegExp(
    r'\[(\d{1,3}):(\d{1,2}(?:\.\d{1,3})?)\]',
  );

  /// Parses raw LRC or plain text content into a [SongLyrics] structure.
  static SongLyrics parse(String content) {
    if (content.trim().isEmpty) {
      return SongLyrics.empty;
    }

    final rawLines = content.split(RegExp(r'\r?\n'));
    final parsedLines = <LyricLine>[];
    var offsetMs = 0;

    for (final rawLine in rawLines) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) continue;

      // Check header tags, e.g. [offset:+/-500]
      final tagMatch = _tagRegex.firstMatch(trimmed);
      if (tagMatch != null) {
        final tag = tagMatch.group(1)?.toLowerCase();
        final val = tagMatch.group(2)?.trim() ?? '';
        if (tag == 'offset') {
          offsetMs = int.tryParse(val) ?? 0;
        }
        continue;
      }

      // Check timestamp matches: [mm:ss.xx]
      final timeMatches = _timestampRegex.allMatches(trimmed).toList();
      if (timeMatches.isEmpty) {
        continue;
      }

      // Extract the text after all timestamp tags
      final lastMatch = timeMatches.last;
      final text = trimmed.substring(lastMatch.end).trim();

      for (final match in timeMatches) {
        final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
        final secondsDouble = double.tryParse(match.group(2) ?? '0') ?? 0.0;
        final totalMs = ((minutes * 60 + secondsDouble) * 1000).round();
        final timestamp = Duration(milliseconds: totalMs);

        parsedLines.add(LyricLine(timestamp: timestamp, text: text));
      }
    }

    if (parsedLines.isEmpty) {
      // Fallback: plain text without timestamps
      return SongLyrics(
        lines: const [],
        rawText: content,
        isSynced: false,
        offset: Duration.zero,
      );
    }

    // Sort chronologically by timestamp
    parsedLines.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return SongLyrics(
      lines: List.unmodifiable(parsedLines),
      rawText: content,
      isSynced: true,
      offset: Duration(milliseconds: offsetMs),
    );
  }
}
