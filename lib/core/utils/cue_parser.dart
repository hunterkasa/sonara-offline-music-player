import 'dart:math';

/// A single track parsed from a CUE sheet.
class CueTrack {
  final int trackNumber;
  final String title;
  final String artist;
  final String album;
  final Duration startTime;
  final Duration? endTime;
  final String? audioFileName;

  const CueTrack({
    required this.trackNumber,
    required this.title,
    required this.artist,
    required this.album,
    required this.startTime,
    this.endTime,
    this.audioFileName,
  });

  Duration? get duration {
    if (endTime == null) return null;
    final diff = endTime! - startTime;
    return diff.isNegative ? Duration.zero : diff;
  }

  CueTrack copyWith({
    int? trackNumber,
    String? title,
    String? artist,
    String? album,
    Duration? startTime,
    Duration? endTime,
    String? audioFileName,
  }) {
    return CueTrack(
      trackNumber: trackNumber ?? this.trackNumber,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      audioFileName: audioFileName ?? this.audioFileName,
    );
  }

  @override
  String toString() =>
      'CueTrack(#$trackNumber "$title" by "$artist" [$startTime -> ${endTime ?? "?"}])';
}

/// Result of parsing an entire CUE sheet file.
class CueSheet {
  final String album;
  final String albumArtist;
  final String? defaultAudioFile;
  final List<CueTrack> tracks;

  const CueSheet({
    required this.album,
    required this.albumArtist,
    this.defaultAudioFile,
    required this.tracks,
  });
}

/// Robust parser for standard CUE sheets (.cue).
class CueParser {
  static final RegExp _quotedRegex = RegExp(r'"([^"]*)"|(\S+)');

  /// Parses CUE sheet content into a [CueSheet].
  /// If [parentDuration] is provided, sets the [endTime] for the final track.
  static CueSheet parse(String content, {Duration? parentDuration}) {
    final lines = content.split(RegExp(r'\r?\n'));

    var globalAlbum = '';
    var globalArtist = '';
    String? currentFile;

    final rawTracks = <_RawTrack>[];
    _RawTrack? currentTrack;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final tokens = _tokenize(line);
      if (tokens.isEmpty) continue;

      final command = tokens[0].toUpperCase();

      switch (command) {
        case 'REM':
          // Comment line, ignore
          break;

        case 'TITLE':
          if (tokens.length > 1) {
            final val = tokens[1];
            if (currentTrack == null) {
              globalAlbum = val;
            } else {
              currentTrack.title = val;
            }
          }
          break;

        case 'PERFORMER':
          if (tokens.length > 1) {
            final val = tokens[1];
            if (currentTrack == null) {
              globalArtist = val;
            } else {
              currentTrack.performer = val;
            }
          }
          break;

        case 'FILE':
          if (tokens.length > 1) {
            currentFile = tokens[1];
          }
          break;

        case 'TRACK':
          if (tokens.length > 1) {
            final trackNum = int.tryParse(tokens[1]) ?? (rawTracks.length + 1);
            currentTrack = _RawTrack(number: trackNum, audioFile: currentFile);
            rawTracks.add(currentTrack);
          }
          break;

        case 'INDEX':
          if (currentTrack != null && tokens.length > 2) {
            final indexId = tokens[1];
            final timeStr = tokens[2];
            final parsedTime = _parseCueTime(timeStr);

            if (indexId == '01' ||
                (indexId == '00' && currentTrack.startTime == null)) {
              currentTrack.startTime = parsedTime;
            }
          }
          break;
      }
    }

    // Resolve track durations and calculate end times
    final resolvedTracks = <CueTrack>[];
    for (var i = 0; i < rawTracks.length; i++) {
      final raw = rawTracks[i];
      final start = raw.startTime ?? Duration.zero;

      Duration? end;
      if (i + 1 < rawTracks.length) {
        end = rawTracks[i + 1].startTime;
      } else if (parentDuration != null) {
        end = parentDuration;
      }

      resolvedTracks.add(
        CueTrack(
          trackNumber: raw.number,
          title: raw.title.isNotEmpty ? raw.title : 'Track ${raw.number}',
          artist: raw.performer.isNotEmpty ? raw.performer : globalArtist,
          album: globalAlbum.isNotEmpty ? globalAlbum : 'Unknown Album',
          startTime: start,
          endTime: end,
          audioFileName: raw.audioFile ?? currentFile,
        ),
      );
    }

    return CueSheet(
      album: globalAlbum,
      albumArtist: globalArtist,
      defaultAudioFile: currentFile,
      tracks: resolvedTracks,
    );
  }

  /// Parses a MM:SS:FF timestamp where FF is frames (75 frames per second).
  static Duration _parseCueTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 3) {
      return Duration.zero;
    }

    final minutes = int.tryParse(parts[0]) ?? 0;
    final seconds = int.tryParse(parts[1]) ?? 0;
    final frames = int.tryParse(parts[2]) ?? 0;

    // 75 frames per second in standard CD audio CUE sheets
    final frameMs = (frames * 1000 / 75).round();
    final totalMs = (minutes * 60 + seconds) * 1000 + frameMs;

    return Duration(milliseconds: max(0, totalMs));
  }

  static List<String> _tokenize(String line) {
    final matches = _quotedRegex.allMatches(line);
    final result = <String>[];
    for (final m in matches) {
      final quoted = m.group(1);
      final unquoted = m.group(2);
      if (quoted != null) {
        result.add(quoted);
      } else if (unquoted != null) {
        result.add(unquoted);
      }
    }
    return result;
  }
}

class _RawTrack {
  final int number;
  String title = '';
  String performer = '';
  Duration? startTime;
  String? audioFile;

  _RawTrack({required this.number, this.audioFile});
}
