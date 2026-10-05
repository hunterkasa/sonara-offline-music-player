import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonara/app/theme/theme_tokens.dart';
import 'package:sonara/core/services/haptic_service.dart';
import 'package:sonara/domain/services/playlist_service.dart';

class AddToPlaylistSheet extends ConsumerWidget {
  const AddToPlaylistSheet({super.key, required this.trackKeys});

  final List<String> trackKeys;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playlistsAsync = ref.watch(allPlaylistsStreamProvider);
    final playlistService = ref.read(playlistServiceProvider);
    final haptics = ref.read(hapticServiceProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.s),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                'Add to Playlist',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              title: const Text('New Playlist'),
              onTap: () async {
                haptics.selection();
                await _showCreatePlaylistDialog(context, ref);
              },
            ),
            playlistsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.l),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Text('Error loading playlists: $err'),
              ),
              data: (playlists) {
                if (playlists.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final p = playlists[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            p.isSmart
                                ? Icons.auto_awesome_rounded
                                : Icons.queue_music_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(p.name),
                        subtitle: p.isSmart
                            ? const Text('Smart Playlist')
                            : null,
                        onTap: () async {
                          haptics.selection();
                          await playlistService.addTracksToPlaylist(
                            p.id,
                            trackKeys,
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added to ${p.name}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final playlistService = ref.read(playlistServiceProvider);

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && context.mounted) {
      final id = await playlistService.createPlaylist(name: name);
      await playlistService.addTracksToPlaylist(id, trackKeys);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created "$name" and added track'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
