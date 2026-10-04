import 'package:flutter/material.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/shared/artwork/artwork_widget.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final String? artistName;
  final String? albumName;
  final VoidCallback? onTap;
  final VoidCallback? onMore;
  final bool isPlaying;
  final int? trackNumber;

  const TrackTile({
    super.key,
    required this.track,
    this.artistName,
    this.albumName,
    this.onTap,
    this.onMore,
    this.isPlaying = false,
    this.trackNumber,
  });

  String _formatDuration(int ms) {
    final totalSeconds = (ms / 1000).floor();
    final minutes = (totalSeconds / 60).floor();
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final subtitleParts = <String>[];
    if (artistName != null && artistName!.isNotEmpty) {
      subtitleParts.add(artistName!);
    }
    if (albumName != null && albumName!.isNotEmpty) {
      subtitleParts.add(albumName!);
    }
    final subtitle = subtitleParts.join(' • ');

    return SizedBox(
      height: 64.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                if (trackNumber != null) ...[
                  SizedBox(
                    width: 28.0,
                    child: Text(
                      '$trackNumber',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isPlaying
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: isPlaying
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                ],
                ArtworkWidget(
                  artworkKey: track.artworkKey,
                  filePath: track.path,
                  title: track.title,
                  size: 48.0,
                  borderRadius: 8.0,
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isPlaying
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                          fontWeight: isPlaying
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 15.0,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2.0),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  _formatDuration(track.durationMs),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (onMore != null)
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20.0),
                    color: colorScheme.onSurfaceVariant,
                    onPressed: onMore,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
