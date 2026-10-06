import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:sonara/core/utils/metadata_utils.dart';

class ParsedMetadata {
  final String title;
  final String artist;
  final String album;
  final String albumArtist;
  final List<String> genres;
  final int? year;
  final int? trackNumber;
  final int? discNumber;
  final double? replayGainTrackDb;
  final double? replayGainAlbumDb;
  final String? lyrics;
  final Uint8List? embeddedArtwork;
  final String? artworkMime;
  final String? codec;

  const ParsedMetadata({
    required this.title,
    required this.artist,
    required this.album,
    required this.albumArtist,
    this.genres = const [],
    this.year,
    this.trackNumber,
    this.discNumber,
    this.replayGainTrackDb,
    this.replayGainAlbumDb,
    this.lyrics,
    this.embeddedArtwork,
    this.artworkMime,
    this.codec,
  });
}

class TagReader {
  /// Reads metadata from an audio file, safely falling back to filename/folder on failure.
  static Future<ParsedMetadata> readFromFile(File file) async {
    final filePath = file.path;
    try {
      if (!file.existsSync() || file.lengthSync() < 128) {
        return _fallbackMetadata(filePath);
      }

      final ext = filePath.split('.').last.toLowerCase();
      final raf = await file.open(mode: FileMode.read);
      try {
        final length = file.lengthSync();

        if (ext == 'mp3') {
          return await _parseMp3(raf, length, filePath);
        } else if (ext == 'flac') {
          return await _parseFlac(raf, length, filePath);
        } else if (ext == 'm4a' || ext == 'mp4' || ext == 'aac') {
          return await _parseMp4(raf, length, filePath);
        } else if (ext == 'ogg' || ext == 'opus') {
          return await _parseOgg(raf, length, filePath);
        }
      } finally {
        await raf.close();
      }
    } catch (_) {
      // Never crash on corrupt files
    }

    return _fallbackMetadata(filePath);
  }

  static ParsedMetadata _fallbackMetadata(String filePath) {
    return ParsedMetadata(
      title: MetadataUtils.resolveTitle(null, filePath),
      artist: MetadataUtils.resolveArtist(null),
      album: MetadataUtils.resolveAlbum(null, filePath),
      albumArtist: MetadataUtils.resolveArtist(null),
    );
  }

  // ---------------------------------------------------------------------------
  // MP3 / ID3 parser
  // ---------------------------------------------------------------------------
  static Future<ParsedMetadata> _parseMp3(
    RandomAccessFile raf,
    int fileLength,
    String filePath,
  ) async {
    // Check ID3v2 header in the first 10 bytes
    await raf.setPosition(0);
    final header = await raf.read(10);

    String? title;
    String? artist;
    String? album;
    String? albumArtist;
    final genres = <String>[];
    int? year;
    int? trackNumber;
    int? discNumber;
    double? rgTrack;
    double? rgAlbum;
    String? lyrics;
    Uint8List? artwork;
    String? artMime;

    if (header.length == 10 &&
        header[0] == 0x49 && // 'I'
        header[1] == 0x44 && // 'D'
        header[2] == 0x33) {
      // '3'
      final majorVersion = header[3];
      final tagSize = _readSyncSafeInt(header, 6);

      if (tagSize > 0 && tagSize < fileLength) {
        final tagBytes = await raf.read(tagSize);
        final reader = _ByteReader(tagBytes);

        while (reader.remaining >= 10) {
          final frameId = reader.readString(4);
          if (frameId.isEmpty || frameId.codeUnitAt(0) == 0) break;

          final frameSize = majorVersion == 4
              ? _readSyncSafeIntFromReader(reader)
              : reader.readUint32();
          reader.skip(2); // Flags

          if (frameSize <= 0 || frameSize > reader.remaining) break;
          final frameData = reader.readBytes(frameSize);

          try {
            switch (frameId) {
              case 'TIT2':
                title = _decodeId3Text(frameData);
                break;
              case 'TPE1':
                artist = _decodeId3Text(frameData);
                break;
              case 'TALB':
                album = _decodeId3Text(frameData);
                break;
              case 'TPE2':
                albumArtist = _decodeId3Text(frameData);
                break;
              case 'TCON':
                final genreText = _decodeId3Text(frameData);
                if (genreText.isNotEmpty) genres.add(genreText);
                break;
              case 'TYER':
              case 'TDRC':
                final yearText = _decodeId3Text(frameData);
                year = int.tryParse(
                  RegExp(r'\d{4}').stringMatch(yearText) ?? '',
                );
                break;
              case 'TRCK':
                final trackStr = _decodeId3Text(frameData);
                trackNumber = int.tryParse(trackStr.split('/').first.trim());
                break;
              case 'TPOS':
                final discStr = _decodeId3Text(frameData);
                discNumber = int.tryParse(discStr.split('/').first.trim());
                break;
              case 'USLT':
                lyrics = _decodeUslt(frameData);
                break;
              case 'APIC':
                final pic = _decodeApic(frameData);
                if (pic != null) {
                  artwork = pic.$1;
                  artMime = pic.$2;
                }
                break;
              case 'TXXX':
                final txxx = _decodeTxxx(frameData);
                if (txxx != null) {
                  if (txxx.$1.toLowerCase().contains('replaygain_track_gain')) {
                    rgTrack = _parseDb(txxx.$2);
                  } else if (txxx.$1.toLowerCase().contains(
                    'replaygain_album_gain',
                  )) {
                    rgAlbum = _parseDb(txxx.$2);
                  }
                }
                break;
            }
          } catch (_) {
            // Ignore malformed individual frame
          }
        }
      }
    }

    // Fallback to ID3v1 if title or artist is missing
    if ((title == null || artist == null) && fileLength >= 128) {
      await raf.setPosition(fileLength - 128);
      final id3v1Bytes = await raf.read(128);
      if (id3v1Bytes.length == 128 &&
          id3v1Bytes[0] == 0x54 &&
          id3v1Bytes[1] == 0x41 &&
          id3v1Bytes[2] == 0x47) {
        title ??= _cleanLatin1(id3v1Bytes.sublist(3, 33));
        artist ??= _cleanLatin1(id3v1Bytes.sublist(33, 63));
        album ??= _cleanLatin1(id3v1Bytes.sublist(63, 93));
        final yearStr = _cleanLatin1(id3v1Bytes.sublist(93, 97));
        year ??= int.tryParse(yearStr);
      }
    }

    final resolvedTitle = MetadataUtils.resolveTitle(title, filePath);
    final resolvedArtist = MetadataUtils.resolveArtist(artist);
    final resolvedAlbum = MetadataUtils.resolveAlbum(album, filePath);
    final resolvedAlbumArtist = MetadataUtils.resolveAlbumArtist(
      albumArtist,
      resolvedArtist,
    );

    return ParsedMetadata(
      title: resolvedTitle,
      artist: resolvedArtist,
      album: resolvedAlbum,
      albumArtist: resolvedAlbumArtist,
      genres: genres,
      year: year,
      trackNumber: trackNumber,
      discNumber: discNumber,
      replayGainTrackDb: rgTrack,
      replayGainAlbumDb: rgAlbum,
      lyrics: lyrics,
      embeddedArtwork: artwork,
      artworkMime: artMime,
      codec: 'MP3',
    );
  }

  // ---------------------------------------------------------------------------
  // FLAC / Vorbis parser
  // ---------------------------------------------------------------------------
  static Future<ParsedMetadata> _parseFlac(
    RandomAccessFile raf,
    int fileLength,
    String filePath,
  ) async {
    await raf.setPosition(0);
    final marker = await raf.read(4);
    if (marker.length != 4 ||
        marker[0] != 0x66 ||
        marker[1] != 0x4C ||
        marker[2] != 0x61 ||
        marker[3] != 0x43) {
      return _fallbackMetadata(filePath);
    }

    String? title;
    String? artist;
    String? album;
    String? albumArtist;
    final genres = <String>[];
    int? year;
    int? trackNumber;
    int? discNumber;
    double? rgTrack;
    double? rgAlbum;
    String? lyrics;
    Uint8List? artwork;
    String? artMime;

    bool isLast = false;
    while (!isLast && await raf.position() < fileLength) {
      final blockHeader = await raf.read(4);
      if (blockHeader.length < 4) break;

      isLast = (blockHeader[0] & 0x80) != 0;
      final blockType = blockHeader[0] & 0x7F;
      final blockLength =
          (blockHeader[1] << 16) | (blockHeader[2] << 8) | blockHeader[3];

      if (blockLength <= 0 ||
          (await raf.position()) + blockLength > fileLength) {
        break;
      }

      final blockData = await raf.read(blockLength);

      if (blockType == 4) {
        // Vorbis comment
        final comments = _parseVorbisComments(blockData);
        title = comments['title'];
        artist = comments['artist'];
        album = comments['album'];
        albumArtist = comments['albumartist'] ?? comments['album artist'];
        final genre = comments['genre'];
        if (genre != null) genres.add(genre);
        final date = comments['date'] ?? comments['year'];
        if (date != null) {
          year = int.tryParse(RegExp(r'\d{4}').stringMatch(date) ?? '');
        }
        trackNumber = int.tryParse(comments['tracknumber'] ?? '');
        discNumber = int.tryParse(comments['discnumber'] ?? '');
        lyrics = comments['lyrics'] ?? comments['unsyncedlyrics'];
        if (comments['replaygain_track_gain'] != null) {
          rgTrack = _parseDb(comments['replaygain_track_gain']!);
        }
        if (comments['replaygain_album_gain'] != null) {
          rgAlbum = _parseDb(comments['replaygain_album_gain']!);
        }
      } else if (blockType == 6 && artwork == null) {
        // Picture block
        final pic = _parseFlacPicture(blockData);
        if (pic != null) {
          artwork = pic.$1;
          artMime = pic.$2;
        }
      }
    }

    final resolvedTitle = MetadataUtils.resolveTitle(title, filePath);
    final resolvedArtist = MetadataUtils.resolveArtist(artist);
    final resolvedAlbum = MetadataUtils.resolveAlbum(album, filePath);
    final resolvedAlbumArtist = MetadataUtils.resolveAlbumArtist(
      albumArtist,
      resolvedArtist,
    );

    return ParsedMetadata(
      title: resolvedTitle,
      artist: resolvedArtist,
      album: resolvedAlbum,
      albumArtist: resolvedAlbumArtist,
      genres: genres,
      year: year,
      trackNumber: trackNumber,
      discNumber: discNumber,
      replayGainTrackDb: rgTrack,
      replayGainAlbumDb: rgAlbum,
      lyrics: lyrics,
      embeddedArtwork: artwork,
      artworkMime: artMime,
      codec: 'FLAC',
    );
  }

  // ---------------------------------------------------------------------------
  // OGG / Opus parser
  // ---------------------------------------------------------------------------
  static Future<ParsedMetadata> _parseOgg(
    RandomAccessFile raf,
    int fileLength,
    String filePath,
  ) async {
    // Read first 64KB for Ogg Vorbis/Opus comment packet
    await raf.setPosition(0);
    final buffer = await raf.read(65536.clamp(0, fileLength));
    final str = String.fromCharCodes(buffer);

    String? title;
    String? artist;
    String? album;

    final titleMatch = RegExp(
      r'TITLE=([^\x00-\x1f\r\n]+)',
      caseSensitive: false,
    ).firstMatch(str);
    if (titleMatch != null) title = titleMatch.group(1);

    final artistMatch = RegExp(
      r'ARTIST=([^\x00-\x1f\r\n]+)',
      caseSensitive: false,
    ).firstMatch(str);
    if (artistMatch != null) artist = artistMatch.group(1);

    final albumMatch = RegExp(
      r'ALBUM=([^\x00-\x1f\r\n]+)',
      caseSensitive: false,
    ).firstMatch(str);
    if (albumMatch != null) album = albumMatch.group(1);

    final resolvedTitle = MetadataUtils.resolveTitle(title, filePath);
    final resolvedArtist = MetadataUtils.resolveArtist(artist);
    final resolvedAlbum = MetadataUtils.resolveAlbum(album, filePath);

    return ParsedMetadata(
      title: resolvedTitle,
      artist: resolvedArtist,
      album: resolvedAlbum,
      albumArtist: resolvedArtist,
      codec: filePath.toLowerCase().endsWith('.opus') ? 'Opus' : 'Vorbis',
    );
  }

  // ---------------------------------------------------------------------------
  // MP4 / M4A / AAC parser
  // ---------------------------------------------------------------------------
  static Future<ParsedMetadata> _parseMp4(
    RandomAccessFile raf,
    int fileLength,
    String filePath,
  ) async {
    // Read first 128KB where moov/udta/meta/ilst usually resides
    await raf.setPosition(0);
    final sampleSize = (fileLength < 131072) ? fileLength : 131072;
    final bytes = await raf.read(sampleSize);
    final reader = _ByteReader(bytes);

    String? title;
    String? artist;
    String? album;
    String? albumArtist;
    final genres = <String>[];
    int? year;
    Uint8List? artwork;
    String? artMime;

    // Search for 'ilst' atom
    final ilstOffset = _findPattern(bytes, [0x69, 0x6C, 0x73, 0x74]); // 'ilst'
    if (ilstOffset != -1 && ilstOffset + 4 < bytes.length) {
      reader.setPosition(ilstOffset + 4);
      while (reader.remaining >= 8) {
        final atomSize = reader.readUint32();
        if (atomSize < 8 || atomSize > reader.remaining + 4) break;

        final atomName = reader.readString(4);
        final atomData = reader.readBytes(atomSize - 8);

        final text = _extractMp4DataString(atomData);
        switch (atomName) {
          case '©nam':
            title = text;
            break;
          case '©ART':
            artist = text;
            break;
          case '©alb':
            album = text;
            break;
          case 'aART':
            albumArtist = text;
            break;
          case '©gen':
            if (text != null && text.isNotEmpty) genres.add(text);
            break;
          case '©day':
            if (text != null) {
              year = int.tryParse(RegExp(r'\d{4}').stringMatch(text) ?? '');
            }
            break;
          case 'covr':
            if (atomData.length > 16) {
              // MP4 data atom header is 16 bytes
              final imgBytes = atomData.sublist(16);
              if (imgBytes.length > 4) {
                artwork = Uint8List.fromList(imgBytes);
                artMime = (imgBytes[0] == 0x89 && imgBytes[1] == 0x50)
                    ? 'image/png'
                    : 'image/jpeg';
              }
            }
            break;
        }
      }
    }

    final resolvedTitle = MetadataUtils.resolveTitle(title, filePath);
    final resolvedArtist = MetadataUtils.resolveArtist(artist);
    final resolvedAlbum = MetadataUtils.resolveAlbum(album, filePath);
    final resolvedAlbumArtist = MetadataUtils.resolveAlbumArtist(
      albumArtist,
      resolvedArtist,
    );

    return ParsedMetadata(
      title: resolvedTitle,
      artist: resolvedArtist,
      album: resolvedAlbum,
      albumArtist: resolvedAlbumArtist,
      genres: genres,
      year: year,
      embeddedArtwork: artwork,
      artworkMime: artMime,
      codec: 'AAC',
    );
  }

  // ---------------------------------------------------------------------------
  // Helper methods
  // ---------------------------------------------------------------------------
  static int _readSyncSafeInt(Uint8List bytes, int offset) {
    return ((bytes[offset] & 0x7F) << 21) |
        ((bytes[offset + 1] & 0x7F) << 14) |
        ((bytes[offset + 2] & 0x7F) << 7) |
        (bytes[offset + 3] & 0x7F);
  }

  static int _readSyncSafeIntFromReader(_ByteReader reader) {
    final b = reader.readBytes(4);
    return ((b[0] & 0x7F) << 21) |
        ((b[1] & 0x7F) << 14) |
        ((b[2] & 0x7F) << 7) |
        (b[3] & 0x7F);
  }

  static String _decodeId3Text(Uint8List bytes) {
    if (bytes.isEmpty) return '';
    final encoding = bytes[0];
    final data = bytes.sublist(1);

    try {
      if (encoding == 0x00) {
        return _cleanLatin1(data);
      } else if (encoding == 0x01) {
        // UTF-16 with BOM
        return _decodeUtf16(data);
      } else if (encoding == 0x02) {
        // UTF-16BE
        return _decodeUtf16(data, isBigEndian: true);
      } else if (encoding == 0x03) {
        // UTF-8
        return utf8
            .decode(data, allowMalformed: true)
            .replaceAll('\x00', '')
            .trim();
      }
    } catch (_) {}
    return _cleanLatin1(data);
  }

  static String _cleanLatin1(List<int> bytes) {
    final zeroIdx = bytes.indexOf(0);
    final trimmed = zeroIdx != -1 ? bytes.sublist(0, zeroIdx) : bytes;
    return latin1.decode(trimmed).trim();
  }

  static String _decodeUtf16(Uint8List bytes, {bool? isBigEndian}) {
    if (bytes.length < 2) return '';
    var offset = 0;
    var bigEndian = isBigEndian ?? false;

    if (isBigEndian == null && bytes.length >= 2) {
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
        bigEndian = true;
        offset = 2;
      } else if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
        bigEndian = false;
        offset = 2;
      }
    }

    final chars = <int>[];
    for (var i = offset; i + 1 < bytes.length; i += 2) {
      final code = bigEndian
          ? (bytes[i] << 8) | bytes[i + 1]
          : (bytes[i + 1] << 8) | bytes[i];
      if (code == 0) break;
      chars.add(code);
    }
    return String.fromCharCodes(chars).trim();
  }

  static String? _decodeUslt(Uint8List bytes) {
    if (bytes.length < 5) return null;
    final encoding = bytes[0];
    // bytes 1-3 is language (e.g. 'eng')
    // followed by null-terminated descriptor, then lyrics text
    var offset = 4;
    while (offset < bytes.length && bytes[offset] != 0) {
      offset++;
    }
    offset++; // Skip descriptor null terminator
    if (offset >= bytes.length) return null;

    final lyricsBytes = bytes.sublist(offset);
    if (encoding == 0x03) {
      return utf8.decode(lyricsBytes, allowMalformed: true).trim();
    }
    return latin1.decode(lyricsBytes).trim();
  }

  static (Uint8List, String)? _decodeApic(Uint8List bytes) {
    if (bytes.length < 10) return null;
    var offset = 1; // Skip encoding

    // Find null terminator for mime type
    final mimeStart = offset;
    while (offset < bytes.length && bytes[offset] != 0) {
      offset++;
    }
    final mime = latin1.decode(bytes.sublist(mimeStart, offset)).trim();
    offset++; // Skip null terminator

    if (offset >= bytes.length) return null;
    // Skip picture type byte
    offset++;

    // Skip description null terminator
    while (offset < bytes.length && bytes[offset] != 0) {
      offset++;
    }
    offset++; // Skip null terminator
    if (offset >= bytes.length) return null;

    final imageBytes = bytes.sublist(offset);
    return (
      Uint8List.fromList(imageBytes),
      mime.isNotEmpty ? mime : 'image/jpeg',
    );
  }

  static (String, String)? _decodeTxxx(Uint8List bytes) {
    if (bytes.length < 3) return null;
    final text = _decodeId3Text(bytes);
    final nullIdx = text.indexOf('\x00');
    if (nullIdx != -1) {
      return (
        text.substring(0, nullIdx).trim(),
        text.substring(nullIdx + 1).trim(),
      );
    }
    return null;
  }

  static Map<String, String> _parseVorbisComments(Uint8List data) {
    final comments = <String, String>{};
    final reader = _ByteReader(data);

    if (reader.remaining < 4) return comments;
    final vendorLength = reader.readUint32LittleEndian();
    if (vendorLength > reader.remaining) return comments;
    reader.skip(vendorLength);

    if (reader.remaining < 4) return comments;
    final numComments = reader.readUint32LittleEndian();

    for (var i = 0; i < numComments && reader.remaining >= 4; i++) {
      final commentLength = reader.readUint32LittleEndian();
      if (commentLength > reader.remaining) break;
      final commentStr = reader.readStringUtf8(commentLength);
      final eqIdx = commentStr.indexOf('=');
      if (eqIdx != -1) {
        final key = commentStr.substring(0, eqIdx).toLowerCase().trim();
        final value = commentStr.substring(eqIdx + 1).trim();
        comments[key] = value;
      }
    }
    return comments;
  }

  static (Uint8List, String)? _parseFlacPicture(Uint8List data) {
    final reader = _ByteReader(data);
    if (reader.remaining < 32) return null;

    reader.skip(4); // Picture type
    final mimeLength = reader.readUint32();
    if (mimeLength > reader.remaining) return null;
    final mime = reader.readString(mimeLength);

    final descLength = reader.readUint32();
    if (descLength > reader.remaining) return null;
    reader.skip(descLength);

    reader.skip(16); // width, height, bitDepth, colors
    final picLength = reader.readUint32();
    if (picLength > reader.remaining) return null;
    final picBytes = reader.readBytes(picLength);

    return (picBytes, mime.isNotEmpty ? mime : 'image/jpeg');
  }

  static String? _extractMp4DataString(Uint8List data) {
    // Standard MP4 data atom has 16-byte header: 4-byte size, 'data', 4-byte flags, 4-byte null
    if (data.length < 16) return null;
    final payload = data.sublist(16);
    return utf8.decode(payload, allowMalformed: true).trim();
  }

  static int _findPattern(Uint8List data, List<int> pattern) {
    for (var i = 0; i <= data.length - pattern.length; i++) {
      var match = true;
      for (var j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }

  static double? _parseDb(String text) {
    final match = RegExp(r'[-+]?[0-9]*\.?[0-9]+').firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(0)!);
    }
    return null;
  }
}

class _ByteReader {
  final Uint8List _bytes;
  int _offset = 0;

  _ByteReader(this._bytes);

  int get remaining => _bytes.length - _offset;

  void skip(int count) {
    _offset += count;
  }

  void setPosition(int position) {
    _offset = position.clamp(0, _bytes.length);
  }

  int readUint32() {
    if (remaining < 4) return 0;
    final val =
        (_bytes[_offset] << 24) |
        (_bytes[_offset + 1] << 16) |
        (_bytes[_offset + 2] << 8) |
        _bytes[_offset + 3];
    _offset += 4;
    return val;
  }

  int readUint32LittleEndian() {
    if (remaining < 4) return 0;
    final val =
        _bytes[_offset] |
        (_bytes[_offset + 1] << 8) |
        (_bytes[_offset + 2] << 16) |
        (_bytes[_offset + 3] << 24);
    _offset += 4;
    return val;
  }

  String readString(int count) {
    final len = count.clamp(0, remaining);
    final str = latin1.decode(_bytes.sublist(_offset, _offset + len));
    _offset += len;
    return str;
  }

  String readStringUtf8(int count) {
    final len = count.clamp(0, remaining);
    final str = utf8.decode(
      _bytes.sublist(_offset, _offset + len),
      allowMalformed: true,
    );
    _offset += len;
    return str;
  }

  Uint8List readBytes(int count) {
    final len = count.clamp(0, remaining);
    final res = Uint8List.fromList(_bytes.sublist(_offset, _offset + len));
    _offset += len;
    return res;
  }
}
