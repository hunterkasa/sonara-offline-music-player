import 'package:path/path.dart' as p;

class MetadataUtils {
  /// Strips leading English articles ("The ", "A ", "An ") for alphabetical sorting.
  static String normalizeSortName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('the ')) {
      return trimmed.substring(4).trim();
    }
    if (lower.startsWith('a ')) {
      return trimmed.substring(2).trim();
    }
    if (lower.startsWith('an ')) {
      return trimmed.substring(3).trim();
    }
    return trimmed;
  }

  /// Splits multi-artist strings using common delimiters (; / feat. ft. & ,)
  static List<String> splitArtists(String rawArtist) {
    if (rawArtist.trim().isEmpty) return ['Unknown Artist'];

    // Regex pattern matching delimiters: ;, /, &, " feat. ", " ft. ", " featuring ", and commas
    final delimiterPattern = RegExp(
      r'(?:\s*;\s*|\s*\/\s*|\s+feat\.?\s+|\s+ft\.?\s+|\s+featuring\s+|\s+&\s+|\s*,\s*)',
      caseSensitive: false,
    );

    final parts = rawArtist
        .split(delimiterPattern)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return parts.isEmpty ? ['Unknown Artist'] : parts;
  }

  /// Resolves title with fallback to filename without extension.
  static String resolveTitle(String? tagTitle, String filePath) {
    final trimmed = tagTitle?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    final basename = p.basenameWithoutExtension(filePath).trim();
    return basename.isNotEmpty ? basename : 'Untitled';
  }

  /// Resolves album with fallback to parent directory name.
  static String resolveAlbum(String? tagAlbum, String filePath) {
    final trimmed = tagAlbum?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    final parentDir = p.basename(p.dirname(filePath)).trim();
    return parentDir.isNotEmpty && parentDir != '.' && parentDir != '/'
        ? parentDir
        : 'Unknown Album';
  }

  /// Resolves artist with fallback to "Unknown Artist".
  static String resolveArtist(String? tagArtist) {
    final trimmed = tagArtist?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    return 'Unknown Artist';
  }

  /// Resolves album artist with fallback to primary artist.
  static String resolveAlbumArtist(
    String? tagAlbumArtist,
    String primaryArtist,
  ) {
    final trimmed = tagAlbumArtist?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    return primaryArtist;
  }
}
