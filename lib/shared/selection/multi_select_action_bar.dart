import 'package:flutter/material.dart';

import '../../app/theme/theme_tokens.dart';

class MultiSelectActionBar extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final VoidCallback onClear;
  final VoidCallback onSelectAll;
  final VoidCallback onPlay;
  final VoidCallback onAddToQueue;
  final VoidCallback onAddToPlaylist;
  final VoidCallback? onFavorite;
  final VoidCallback? onDelete;
  final String deleteLabel;
  final IconData? deleteIcon;

  const MultiSelectActionBar({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.onClear,
    required this.onSelectAll,
    required this.onPlay,
    required this.onAddToQueue,
    required this.onAddToPlaylist,
    this.onFavorite,
    this.onDelete,
    this.deleteLabel = 'Delete',
    this.deleteIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAllSelected = selectedCount > 0 && selectedCount == totalCount;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16.0,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close selection',
                  onPressed: onClear,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$selectedCount selected',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: Icon(
                    isAllSelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                    size: 18,
                  ),
                  label: Text(isAllSelected ? 'Deselect All' : 'Select All'),
                  onPressed: isAllSelected ? onClear : onSelectAll,
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'Play',
                  onTap: selectedCount > 0 ? onPlay : null,
                ),
                _ActionButton(
                  icon: Icons.queue_music_rounded,
                  label: 'Queue',
                  onTap: selectedCount > 0 ? onAddToQueue : null,
                ),
                _ActionButton(
                  icon: Icons.playlist_add_rounded,
                  label: 'Playlist',
                  onTap: selectedCount > 0 ? onAddToPlaylist : null,
                ),
                if (onFavorite != null)
                  _ActionButton(
                    icon: Icons.favorite_border_rounded,
                    label: 'Favorite',
                    onTap: selectedCount > 0 ? onFavorite : null,
                  ),
                if (onDelete != null)
                  _ActionButton(
                    icon: deleteIcon ?? Icons.delete_outline_rounded,
                    label: deleteLabel,
                    onTap: selectedCount > 0 ? onDelete : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = onTap != null;

    final color = isEnabled
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.38);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24.0),
            const SizedBox(height: 4.0),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
