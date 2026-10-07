import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonara/app/theme/theme_tokens.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/core/services/haptic_service.dart';
import 'package:sonara/domain/services/daily_mix_service.dart';

class DailyMixCard extends ConsumerWidget {
  const DailyMixCard({super.key, required this.mix});

  final DailyMix mix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final playback = ref.read(playbackControllerProvider);
    final haptics = ref.read(hapticServiceProvider);

    // Rebuild only when mix playing state changes, ignoring position stream updates
    final isMixPlaying = ref.watch(
      playbackSnapshotProvider.select((s) {
        final snap = s.value;
        if (snap == null) return false;
        return snap.isPlaying &&
            mix.tracks.any((t) => t.trackKey == snap.currentTrackKey);
      }),
    );

    return SizedBox(
      width: 144.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () {
          haptics.selection();
          context.push('/playlist/${mix.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Artwork Container
              Stack(
                children: [
                  Container(
                    width: 136.0,
                    height: 136.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.0),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [mix.primaryColor, mix.secondaryColor],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: mix.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 12.0,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Subtle equalizer bar lines in background
                        Positioned(
                          right: -10,
                          bottom: -10,
                          child: Icon(
                            Icons.graphic_eq_rounded,
                            size: 90.0,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        // Header pill
                        Positioned(
                          top: 10.0,
                          left: 10.0,
                          child: Text(
                            'DAILY MIX',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                        // Big Number
                        Center(
                          child: Text(
                            '${mix.index}',
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 48.0,
                              height: 1.0,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8.0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Floating Play Button
                  Positioned(
                    right: 8.0,
                    bottom: 8.0,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20.0),
                        onTap: () async {
                          haptics.selection();
                          if (mix.tracks.isEmpty) return;
                          final keys = mix.tracks
                              .map((t) => t.trackKey)
                              .toList();
                          await playback.playQueue(keys, initialIndex: 0);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Playing ${mix.title}'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 38.0,
                          height: 38.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1DB954), // Spotify Green
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 8.0,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            isMixPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 24.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // Title
              Text(
                mix.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Subtitle (Featured Artists)
              Text(
                mix.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
