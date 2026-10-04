import 'package:flutter/material.dart';
import 'package:sonara/shared/artwork/artwork_widget.dart';

class MediaCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? artworkKey;
  final String? filePath;
  final bool isCircular;
  final VoidCallback? onTap;

  const MediaCard({
    super.key,
    required this.title,
    this.subtitle,
    this.artworkKey,
    this.filePath,
    this.isCircular = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: isCircular
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final dimension = constraints.biggest.shortestSide;
                      return ArtworkWidget(
                        title: title,
                        artworkKey: artworkKey,
                        filePath: filePath,
                        size: dimension.isFinite ? dimension : 120.0,
                        borderRadius: 12.0,
                        isCircular: isCircular,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: isCircular ? TextAlign.center : TextAlign.start,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 2.0),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: isCircular ? TextAlign.center : TextAlign.start,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
