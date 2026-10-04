import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme_tokens.dart';
import '../../data/db/database_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tracksAsync = ref.watch(allTracksStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Library',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Pinned Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                _buildFilterChip('Playlists', true, theme),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('Songs', false, theme),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('Albums', false, theme),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('Artists', false, theme),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('Genres', false, theme),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('Folders', false, theme),
              ],
            ),
          ),
          const Divider(height: 1),
          // Reactive library content from Drift DB
          Expanded(
            child: tracksAsync.when(
              data: (tracks) {
                if (tracks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.library_music_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.m),
                          Text(
                            'Your library is empty',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Local audio files will appear here once scanned in Phase 1.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tracks.length,
                  itemExtent: 64.0, // Fixed extent for 60fps performance
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Icon(Icons.music_note_rounded),
                      ),
                      title: Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Track ${track.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        onPressed: () {},
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Error loading tracks: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, ThemeData theme) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {},
      showCheckmark: false,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.pillRadius),
    );
  }
}
