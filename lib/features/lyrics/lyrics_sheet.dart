import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_tokens.dart';
import '../../audio/playback_controller.dart';
import '../../core/services/haptic_service.dart';
import '../../data/db/app_database.dart';
import '../../domain/services/lyrics_service.dart';

class LyricsSheet extends ConsumerStatefulWidget {
  const LyricsSheet({super.key, required this.track});

  final Track? track;

  @override
  ConsumerState<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends ConsumerState<LyricsSheet> {
  final ScrollController _scrollController = ScrollController();
  double _baseFontSize = 20.0;
  int _lastActiveIndex = -1;
  bool _userIsScrolling = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActive(int index, int totalLines) {
    if (_userIsScrolling || !_scrollController.hasClients || index < 0) return;

    // Approximate line height ~ 60dp
    const estimatedLineHeight = 58.0;
    final targetOffset = (index * estimatedLineHeight) - 150.0;
    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshotAsync = ref.watch(playbackSnapshotProvider);
    final snapshot =
        snapshotAsync.value ??
        ref.read(playbackControllerProvider).currentSnapshot;
    final lyricsAsync = ref.watch(currentTrackLyricsProvider(widget.track));
    final playback = ref.read(playbackControllerProvider);
    final haptics = ref.read(hapticServiceProvider);

    return SafeArea(
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.s,
              bottom: AppSpacing.xs,
            ),
            child: Center(
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
          ),
          // Header & font size adjustment
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LYRICS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.text_decrease_rounded, size: 20),
                      tooltip: 'Decrease font size',
                      onPressed: () {
                        if (_baseFontSize > 14) {
                          setState(() => _baseFontSize -= 2);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_increase_rounded, size: 20),
                      tooltip: 'Increase font size',
                      onPressed: () {
                        if (_baseFontSize < 32) {
                          setState(() => _baseFontSize += 2);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: lyricsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  'Could not load lyrics',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              data: (lyrics) {
                if (lyrics.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lyrics_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        Text(
                          'No lyrics found for this track',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Add a .lrc file in the same folder to see synced lyrics',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // If plain text (not synced)
                if (!lyrics.isSynced) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    child: Text(
                      lyrics.rawText ?? '',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: _baseFontSize,
                        height: 1.8,
                      ),
                    ),
                  );
                }

                // Synced LRC lines
                final activeIndex = lyrics.getActiveIndex(snapshot.position);
                if (activeIndex != _lastActiveIndex) {
                  _lastActiveIndex = activeIndex;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToActive(activeIndex, lyrics.lines.length);
                  });
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification) {
                      _userIsScrolling = true;
                    } else if (notification is ScrollEndNotification) {
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) _userIsScrolling = false;
                      });
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.l,
                      vertical: AppSpacing.xl,
                    ),
                    itemCount: lyrics.lines.length,
                    itemBuilder: (context, index) {
                      final line = lyrics.lines[index];
                      final isActive = index == activeIndex;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: InkWell(
                          onTap: () {
                            haptics.selection();
                            playback.seek(line.timestamp);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            style: TextStyle(
                              fontSize: isActive
                                  ? _baseFontSize + 4
                                  : _baseFontSize,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.35,
                                    ),
                              height: 1.4,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              child: Text(line.text.isEmpty ? '♪' : line.text),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
