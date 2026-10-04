import 'package:drift/drift.dart' as d;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonara/app/theme/theme_tokens.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/domain/services/library_scanner.dart';
import 'package:sonara/shared/cards/media_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final db = ref.watch(databaseProvider);
    final scanProgress = ref.watch(libraryScannerProvider);
    final playback = ref.watch(playbackControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getGreeting(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Rescan Library',
            onPressed: () {
              ref
                  .read(libraryScannerProvider.notifier)
                  .scanLibrary(isFullScan: true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(libraryScannerProvider.notifier)
              .scanLibrary(isFullScan: true);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.s,
          ),
          children: [
            // Live scanning indicator
            if (scanProgress.isScanning)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.m),
                padding: const EdgeInsets.all(AppSpacing.s),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18.0,
                      height: 18.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        scanProgress.statusMessage ?? 'Scanning local music...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Quick Access Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.xs,
              crossAxisSpacing: AppSpacing.xs,
              childAspectRatio: 3.0,
              children: [
                _buildQuickCard(
                  context,
                  icon: Icons.favorite_rounded,
                  title: 'Liked Songs',
                  color: Colors.redAccent,
                  onTap: () => context.go('/library'),
                ),
                _buildQuickCard(
                  context,
                  icon: Icons.shuffle_rounded,
                  title: 'Shuffle All',
                  color: Colors.deepPurpleAccent,
                  onTap: () async {
                    final tracks = await (db.select(
                      db.tracks,
                    )..orderBy([(t) => d.OrderingTerm.asc(t.titleSort)])).get();
                    if (tracks.isNotEmpty) {
                      final shuffled = List<Track>.from(tracks)..shuffle();
                      await playback.playTrack(shuffled.first.trackKey);
                    }
                  },
                ),
                _buildQuickCard(
                  context,
                  icon: Icons.history_rounded,
                  title: 'Recently Added',
                  color: Colors.teal,
                  onTap: () => context.go('/library'),
                ),
                _buildQuickCard(
                  context,
                  icon: Icons.repeat_rounded,
                  title: 'On Repeat',
                  color: Colors.amber,
                  onTap: () => context.go('/library'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),

            // Real Albums Shelf
            Text(
              'Jump back in',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            StreamBuilder<List<Album>>(
              stream:
                  (db.select(db.albums)
                        ..orderBy([(a) => d.OrderingTerm.desc(a.year)])
                        ..limit(10))
                      .watch(),
              builder: (context, snapshot) {
                final albums = snapshot.data ?? [];
                if (albums.isEmpty) {
                  return Container(
                    height: 120.0,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.library_music_rounded,
                            color: colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Scan your library to see albums here',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 190.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return SizedBox(
                        width: 140.0,
                        child: MediaCard(
                          title: album.title,
                          subtitle: album.year != null ? '${album.year}' : null,
                          artworkKey: album.artworkKey,
                          onTap: () => context.push('/album/${album.id}'),
                        ),
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

  Widget _buildQuickCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.cardRadius,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: AppRadii.cardRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
