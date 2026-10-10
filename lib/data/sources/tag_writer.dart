import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Metadata fields editable by the user.
class EditableMetadata {
  final String title;
  final String artist;
  final String album;
  final int? year;
  final int? trackNumber;
  final int? discNumber;
  final String? genre;
  final Uint8List? artworkBytes;
  final String? artworkMime;

  const EditableMetadata({
    required this.title,
    required this.artist,
    required this.album,
    this.year,
    this.trackNumber,
    this.discNumber,
    this.genre,
    this.artworkBytes,
    this.artworkMime,
  });
}

/// In-place tag writer for audio files (ID3v2 for MP3, Vorbis Comments for FLAC).
class TagWriter {
  /// Writes metadata into [file]. Returns `true` if file tags were written to disk.
  static Future<bool> writeTags(File file, EditableMetadata metadata) async {
    if (!await file.exists()) return false;

    final ext = file.path.split('.').last.toLowerCase();
    if (ext == 'mp3') {
      return await _writeMp3Tags(file, metadata);
    } else if (ext == 'flac') {
      return await _writeFlacTags(file, metadata);
    }

    // Other formats or unsupported in-place rewrite
    return false;
  }

  // ---------------------------------------------------------------------------
  static Future<void> _replaceFileSafely(File tempFile, File targetFile) async {
    try {
      await tempFile.rename(targetFile.path);
    } catch (_) {
      // If rename fails across filesystems or scoped storage, copy bytes stream
      final outRaf = await targetFile.open(mode: FileMode.write);
      final tempRaf = await tempFile.open(mode: FileMode.read);
      try {
        const chunkSize = 64 * 1024;
        var rem = await tempRaf.length();
        while (rem > 0) {
          final toRead = rem > chunkSize ? chunkSize : rem;
          final chunk = await tempRaf.read(toRead);
          await outRaf.writeFrom(chunk);
          rem -= chunk.length;
        }
      } finally {
        await tempRaf.close();
        await outRaf.close();
      }
    } finally {
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------------
  // MP3 / ID3v2.3 tag writing
  // ---------------------------------------------------------------------------
  static Future<bool> _writeMp3Tags(
    File file,
    EditableMetadata metadata,
  ) async {
    final tempFile = File(
      p.join(
        Directory.systemTemp.path,
        'sonara_mp3_${DateTime.now().microsecondsSinceEpoch}.tmp',
      ),
    );
    RandomAccessFile? inRaf;
    IOSink? outSink;

    try {
      inRaf = await file.open(mode: FileMode.read);
      final fileLength = await inRaf.length();

      // Check existing ID3v2 header
      var audioStartOffset = 0;
      await inRaf.setPosition(0);
      final header = await inRaf.read(10);
      if (header.length >= 10 &&
          header[0] == 0x49 &&
          header[1] == 0x44 &&
          header[2] == 0x33) {
        // ID3 tag present
        final synchsafeSize =
            (header[6] << 21) |
            (header[7] << 14) |
            (header[8] << 7) |
            header[9];
        final flags = header[5];
        final hasFooter = (flags & 0x10) != 0;
        audioStartOffset = 10 + synchsafeSize + (hasFooter ? 10 : 0);
      }

      // Build new ID3v2.3 tag bytes
      final tagBytes = _buildId3v2Tag(metadata);

      // Write new tag + original audio stream into temp file
      outSink = tempFile.openWrite();
      outSink.add(tagBytes);

      await inRaf.setPosition(audioStartOffset);
      const chunkSize = 64 * 1024;
      var remaining = fileLength - audioStartOffset;

      while (remaining > 0) {
        final toRead = remaining > chunkSize ? chunkSize : remaining;
        final chunk = await inRaf.read(toRead);
        outSink.add(chunk);
        remaining -= chunk.length;
      }

      await outSink.flush();
      await outSink.close();
      outSink = null;

      await inRaf.close();
      inRaf = null;

      // Safe replace
      await _replaceFileSafely(tempFile, file);
      return true;
    } catch (_) {
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
      return false;
    } finally {
      await outSink?.close();
      await inRaf?.close();
    }
  }

  static Uint8List _buildId3v2Tag(EditableMetadata metadata) {
    final framesBytes = BytesBuilder();

    // Text frames helper: ID3v2.3 frame structure
    // 4 bytes ID + 4 bytes size + 2 bytes flags (0) + 1 byte encoding + text
    void addTextFrame(String frameId, String text) {
      if (text.isEmpty) return;
      final framePayload = BytesBuilder();

      final isAsciiOrLatin1 = text.runes.every((r) => r <= 255);
      if (isAsciiOrLatin1) {
        framePayload.addByte(0x00); // ISO-8859-1 (Latin-1)
        framePayload.add(latin1.encode(text));
      } else {
        framePayload.addByte(0x01); // UTF-16 with BOM
        framePayload.add([0xFF, 0xFE]); // Little-endian BOM
        final codeUnits = text.codeUnits;
        final utf16Bytes = Uint8List(codeUnits.length * 2);
        for (var i = 0; i < codeUnits.length; i++) {
          utf16Bytes[i * 2] = codeUnits[i] & 0xFF;
          utf16Bytes[i * 2 + 1] = (codeUnits[i] >> 8) & 0xFF;
        }
        framePayload.add(utf16Bytes);
      }

      final payloadBytes = framePayload.takeBytes();
      framesBytes.add(ascii.encode(frameId));

      // 4-byte big-endian size
      final sizeBytes = Uint8List(4);
      ByteData.view(sizeBytes.buffer)
          .setUint32(0, payloadBytes.length, Endian.big);
      framesBytes.add(sizeBytes);

      // Flags (2 bytes: 0x00, 0x00)
      framesBytes.add([0x00, 0x00]);
      framesBytes.add(payloadBytes);
    }

    addTextFrame('TIT2', metadata.title);
    addTextFrame('TPE1', metadata.artist);
    addTextFrame('TALB', metadata.album);
    if (metadata.year != null && metadata.year! > 0) {
      addTextFrame('TYER', metadata.year.toString());
    }
    if (metadata.trackNumber != null && metadata.trackNumber! > 0) {
      addTextFrame('TRCK', metadata.trackNumber.toString());
    }
    if (metadata.discNumber != null && metadata.discNumber! > 0) {
      addTextFrame('TPOS', metadata.discNumber.toString());
    }
    if (metadata.genre != null && metadata.genre!.isNotEmpty) {
      addTextFrame('TCON', metadata.genre!);
    }

    // Artwork (APIC)
    if (metadata.artworkBytes != null && metadata.artworkBytes!.isNotEmpty) {
      final apicPayload = BytesBuilder();
      apicPayload.addByte(0x00); // ISO-8859-1
      final mime = metadata.artworkMime ?? 'image/jpeg';
      apicPayload.add(ascii.encode(mime));
      apicPayload.addByte(0x00); // Null terminator for mime
      apicPayload.addByte(0x03); // Picture type: Cover (front)
      apicPayload.addByte(
        0x00,
      ); // Description (empty string null-terminated in Latin-1)
      apicPayload.add(metadata.artworkBytes!);

      final apicBytes = apicPayload.takeBytes();
      framesBytes.add(ascii.encode('APIC'));
      final sizeBytes = Uint8List(4);
      ByteData.view(sizeBytes.buffer)
          .setUint32(0, apicBytes.length, Endian.big);
      framesBytes.add(sizeBytes);
      framesBytes.add([0x00, 0x00]);
      framesBytes.add(apicBytes);
    }

    final allFrames = framesBytes.takeBytes();

    // 10-byte ID3 header
    final header = Uint8List(10);
    header[0] = 0x49; // 'I'
    header[1] = 0x44; // 'D'
    header[2] = 0x33; // '3'
    header[3] = 0x03; // Version 2.3
    header[4] = 0x00; // Revision 0
    header[5] = 0x00; // Flags

    // Synchsafe integer (7 bits per byte)
    final tagSize = allFrames.length;
    header[6] = (tagSize >> 21) & 0x7F;
    header[7] = (tagSize >> 14) & 0x7F;
    header[8] = (tagSize >> 7) & 0x7F;
    header[9] = tagSize & 0x7F;

    final completeTag = BytesBuilder();
    completeTag.add(header);
    completeTag.add(allFrames);

    return completeTag.takeBytes();
  }

  // ---------------------------------------------------------------------------
  // FLAC / Vorbis comment tag writing
  // ---------------------------------------------------------------------------
  static Future<bool> _writeFlacTags(
    File file,
    EditableMetadata metadata,
  ) async {
    final tempFile = File(
      p.join(
        Directory.systemTemp.path,
        'sonara_flac_${DateTime.now().microsecondsSinceEpoch}.tmp',
      ),
    );
    RandomAccessFile? inRaf;
    IOSink? outSink;

    try {
      inRaf = await file.open(mode: FileMode.read);
      final fileLength = await inRaf.length();

      // Verify 'fLaC' magic
      final magic = await inRaf.read(4);
      if (magic.length < 4 ||
          magic[0] != 0x66 ||
          magic[1] != 0x4C ||
          magic[2] != 0x61 ||
          magic[3] != 0x43) {
        return false;
      }

      Uint8List? streamInfoBlock;
      var audioStartOffset = 4;

      // Scan existing metadata blocks to extract STREAMINFO and find audio start
      var isLast = false;
      while (!isLast && audioStartOffset < fileLength) {
        await inRaf.setPosition(audioStartOffset);
        final blockHeader = await inRaf.read(4);
        if (blockHeader.length < 4) break;

        isLast = (blockHeader[0] & 0x80) != 0;
        final blockType = blockHeader[0] & 0x7F;
        final blockLength =
            (blockHeader[1] << 16) | (blockHeader[2] << 8) | blockHeader[3];

        if (blockType == 0) {
          // STREAMINFO
          final blockData = await inRaf.read(blockLength);
          final streamInfoBuilder = BytesBuilder();
          streamInfoBuilder.add([0x00]); // isLast=0, type=0
          streamInfoBuilder.add([
            (blockLength >> 16) & 0xFF,
            (blockLength >> 8) & 0xFF,
            blockLength & 0xFF,
          ]);
          streamInfoBuilder.add(blockData);
          streamInfoBlock = streamInfoBuilder.takeBytes();
        }

        audioStartOffset += 4 + blockLength;
      }

      if (streamInfoBlock == null) {
        return false;
      }

      // Build new VORBIS_COMMENT block
      final vorbisBlock = _buildVorbisCommentBlock(
        metadata,
        isLast: metadata.artworkBytes == null,
      );

      // Build PICTURE block if artwork present
      Uint8List? pictureBlock;
      if (metadata.artworkBytes != null && metadata.artworkBytes!.isNotEmpty) {
        pictureBlock = _buildFlacPictureBlock(metadata, isLast: true);
      }

      outSink = tempFile.openWrite();
      // 'fLaC' magic
      outSink.add([0x66, 0x4C, 0x61, 0x43]);
      // STREAMINFO
      outSink.add(streamInfoBlock);
      // VORBIS_COMMENT
      outSink.add(vorbisBlock);
      // PICTURE
      if (pictureBlock != null) {
        outSink.add(pictureBlock);
      }

      // Copy remaining audio data
      await inRaf.setPosition(audioStartOffset);
      const chunkSize = 64 * 1024;
      var remaining = fileLength - audioStartOffset;

      while (remaining > 0) {
        final toRead = remaining > chunkSize ? chunkSize : remaining;
        final chunk = await inRaf.read(toRead);
        outSink.add(chunk);
        remaining -= chunk.length;
      }

      await outSink.flush();
      await outSink.close();
      outSink = null;

      await inRaf.close();
      inRaf = null;

      // Safe replace
      await _replaceFileSafely(tempFile, file);
      return true;
    } catch (_) {
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
      return false;
    } finally {
      await outSink?.close();
      await inRaf?.close();
    }
  }

  static Uint8List _buildVorbisCommentBlock(
    EditableMetadata metadata, {
    required bool isLast,
  }) {
    final payload = BytesBuilder();

    // Vendor string
    const vendor = 'Sonara Tag Engine';
    final vendorBytes = utf8.encode(vendor);
    final vendorLenBytes = Uint8List(4);
    ByteData.view(vendorLenBytes.buffer)
        .setUint32(0, vendorBytes.length, Endian.little);
    payload.add(vendorLenBytes);
    payload.add(vendorBytes);

    // Comments list
    final comments = <String>[];
    if (metadata.title.isNotEmpty) comments.add('TITLE=${metadata.title}');
    if (metadata.artist.isNotEmpty) comments.add('ARTIST=${metadata.artist}');
    if (metadata.album.isNotEmpty) comments.add('ALBUM=${metadata.album}');
    if (metadata.year != null && metadata.year! > 0) {
      comments.add('DATE=${metadata.year}');
    }
    if (metadata.trackNumber != null && metadata.trackNumber! > 0) {
      comments.add('TRACKNUMBER=${metadata.trackNumber}');
    }
    if (metadata.discNumber != null && metadata.discNumber! > 0) {
      comments.add('DISCNUMBER=${metadata.discNumber}');
    }
    if (metadata.genre != null && metadata.genre!.isNotEmpty) {
      comments.add('GENRE=${metadata.genre}');
    }

    // User comment list length (32-bit little endian)
    final countBytes = Uint8List(4);
    ByteData.view(countBytes.buffer)
        .setUint32(0, comments.length, Endian.little);
    payload.add(countBytes);

    for (final comment in comments) {
      final commentBytes = utf8.encode(comment);
      final lenBytes = Uint8List(4);
      ByteData.view(lenBytes.buffer)
          .setUint32(0, commentBytes.length, Endian.little);
      payload.add(lenBytes);
      payload.add(commentBytes);
    }

    final commentPayloadBytes = payload.takeBytes();
    final blockLength = commentPayloadBytes.length;

    final block = BytesBuilder();
    // Block header: isLast (1 bit) + type=4 (7 bits)
    final headerByte0 = (isLast ? 0x80 : 0x00) | 0x04;
    block.add([
      headerByte0,
      (blockLength >> 16) & 0xFF,
      (blockLength >> 8) & 0xFF,
      blockLength & 0xFF,
    ]);
    block.add(commentPayloadBytes);

    return block.takeBytes();
  }

  static Uint8List _buildFlacPictureBlock(
    EditableMetadata metadata, {
    required bool isLast,
  }) {
    final payload = BytesBuilder();
    final data = ByteData(4);

    // Picture type 3: Cover (front) (32-bit big endian)
    data.setUint32(0, 3, Endian.big);
    payload.add(data.buffer.asUint8List());

    // MIME type length & string
    final mime = metadata.artworkMime ?? 'image/jpeg';
    final mimeBytes = ascii.encode(mime);
    data.setUint32(0, mimeBytes.length, Endian.big);
    payload.add(data.buffer.asUint8List());
    payload.add(mimeBytes);

    // Description length (0)
    data.setUint32(0, 0, Endian.big);
    payload.add(data.buffer.asUint8List());

    // Width, Height, Color depth, Indexed colors (0s)
    data.setUint32(0, 0, Endian.big);
    payload.add(data.buffer.asUint8List());
    payload.add(data.buffer.asUint8List());
    payload.add(data.buffer.asUint8List());
    payload.add(data.buffer.asUint8List());

    // Picture data length & bytes
    final artBytes = metadata.artworkBytes!;
    data.setUint32(0, artBytes.length, Endian.big);
    payload.add(data.buffer.asUint8List());
    payload.add(artBytes);

    final picturePayload = payload.takeBytes();
    final blockLength = picturePayload.length;

    final block = BytesBuilder();
    final headerByte0 = (isLast ? 0x80 : 0x00) | 0x06; // type=6 PICTURE
    block.add([
      headerByte0,
      (blockLength >> 16) & 0xFF,
      (blockLength >> 8) & 0xFF,
      blockLength & 0xFF,
    ]);
    block.add(picturePayload);

    return block.takeBytes();
  }
}
