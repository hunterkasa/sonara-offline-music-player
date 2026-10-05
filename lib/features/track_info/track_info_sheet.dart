import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_tokens.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';

class TrackInfoSheet extends ConsumerWidget {
  const TrackInfoSheet({super.key, required this.trackKey});

  final String trackKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final db = ref.watch(databaseProvider);

    return FutureBuilder<Track?>(
      future: db.getTrackByKey(trackKey),
      builder: (context, snapshot) {
        final track = snapshot.data;
        if (track == null) {
          return const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.l),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final qualityBadge = _computeQualityBadge(track);
        final fileSizeMb = (track.sizeBytes / (1024 * 1024)).toStringAsFixed(2);
        final durationMin = (track.durationMs / 60000).floor();
        final durationSec = ((track.durationMs % 60000) / 1000)
            .floor()
            .toString()
            .padLeft(2, '0');

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.m,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TRACK DETAILS',
                      style: theme.textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        qualityBadge,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),

                // Main Info Card
                Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<String?>(
                          future: db.getArtistName(track.artistId),
                          builder: (context, artistSnap) {
                            return Text(
                              artistSnap.data ?? 'Unknown Artist',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                // Audio Technical Specifications
                Text(
                  'Technical Specifications',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Card(
                  color: theme.colorScheme.surfaceContainerHigh,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      children: [
                        _buildSpecRow(
                          theme,
                          'Format / Codec',
                          _extractFormat(track.path, track.mime),
                        ),
                        const Divider(height: 16),
                        _buildSpecRow(
                          theme,
                          'Bitrate',
                          track.bitrate != null
                              ? '${(track.bitrate! / 1000).round()} kbps'
                              : 'VBR / Auto',
                        ),
                        const Divider(height: 16),
                        _buildSpecRow(
                          theme,
                          'Sample Rate',
                          track.sampleRate != null
                              ? '${(track.sampleRate! / 1000).toStringAsFixed(1)} kHz'
                              : '44.1 kHz',
                        ),
                        const Divider(height: 16),
                        _buildSpecRow(
                          theme,
                          'Bit Depth',
                          track.bitDepth != null
                              ? '${track.bitDepth}-bit'
                              : '16-bit',
                        ),
                        const Divider(height: 16),
                        _buildSpecRow(
                          theme,
                          'Channels',
                          track.channels == 1 ? 'Mono (1 ch)' : 'Stereo (2 ch)',
                        ),
                        const Divider(height: 16),
                        _buildSpecRow(
                          theme,
                          'Duration',
                          '$durationMin:$durationSec',
                        ),
                        const Divider(height: 16),
                        _buildSpecRow(theme, 'File Size', '$fileSizeMb MB'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                // File Path
                Text(
                  'Location',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: track.path));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('File path copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: AppRadii.cardRadius,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: AppRadii.cardRadius,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            track.path,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpecRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _computeQualityBadge(Track track) {
    final ext = track.path.split('.').last.toUpperCase();
    final sampleRate = track.sampleRate != null
        ? (track.sampleRate! / 1000).round()
        : 44;
    final bitDepth = track.bitDepth ?? 16;

    if (ext == 'FLAC' || ext == 'WAV') {
      if (sampleRate >= 88 || bitDepth >= 24) {
        return 'Hi-Res $ext · $bitDepth-bit/${sampleRate}kHz';
      }
      return 'Lossless $ext · $bitDepth-bit';
    }

    if (track.bitrate != null) {
      final kbps = (track.bitrate! / 1000).round();
      return '$ext · $kbps kbps';
    }

    return ext;
  }

  String _extractFormat(String path, String? mime) {
    final ext = path.split('.').last.toUpperCase();
    if (ext.isNotEmpty) return ext;
    return mime ?? 'Audio';
  }
}
