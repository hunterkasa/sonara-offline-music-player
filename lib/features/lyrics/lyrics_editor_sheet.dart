import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_tokens.dart';
import '../../audio/playback_controller.dart';
import '../../core/services/haptic_service.dart';
import '../../core/utils/lrc_builder.dart';
import '../../data/db/app_database.dart';
import '../../domain/services/lrc_parser.dart';
import '../../domain/services/lyrics_service.dart';

class LyricsEditorSheet extends ConsumerStatefulWidget {
  const LyricsEditorSheet({super.key, required this.track});

  final Track track;

  @override
  ConsumerState<LyricsEditorSheet> createState() => _LyricsEditorSheetState();
}

class _LyricsEditorSheetState extends ConsumerState<LyricsEditorSheet> {
  final List<LyricLine> _lines = [];
  int _activeStampIndex = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLyrics() async {
    final lyricsService = ref.read(lyricsServiceProvider);
    final songLyrics = await lyricsService.loadLyrics(widget.track);

    if (mounted) {
      setState(() {
        if (songLyrics.lines.isNotEmpty) {
          _lines.addAll(songLyrics.lines);
        } else if (songLyrics.rawText != null &&
            songLyrics.rawText!.trim().isNotEmpty) {
          _lines.addAll(LrcBuilder.parsePlainTextLines(songLyrics.rawText!));
        } else {
          // Default template lines if nothing exists
          _lines.addAll([
            const LyricLine(
              timestamp: Duration.zero,
              text: 'First verse starts here...',
            ),
            const LyricLine(
              timestamp: Duration.zero,
              text: 'Second line of the lyrics...',
            ),
            const LyricLine(
              timestamp: Duration.zero,
              text: 'Chorus melody begins...',
            ),
          ]);
        }
        _isLoading = false;
      });
    }
  }

  void _stampCurrentLine(Duration currentPosition) {
    if (_lines.isEmpty || _activeStampIndex >= _lines.length) return;

    final haptics = ref.read(hapticServiceProvider);
    haptics.medium();

    setState(() {
      final current = _lines[_activeStampIndex];
      _lines[_activeStampIndex] = LyricLine(
        timestamp: currentPosition,
        text: current.text,
      );

      if (_activeStampIndex < _lines.length - 1) {
        _activeStampIndex++;
        _scrollToActive();
      }
    });
  }

  void _scrollToActive() {
    if (_scrollController.hasClients) {
      final target = (_activeStampIndex * 56.0) - 100.0;
      _scrollController.animateTo(
        target < 0 ? 0 : target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _shiftOffset(Duration delta) {
    final haptics = ref.read(hapticServiceProvider);
    haptics.selection();
    setState(() {
      final updated = LrcBuilder.shiftTimestamps(_lines, delta);
      _lines.clear();
      _lines.addAll(updated);
    });
  }

  Future<void> _saveLrc() async {
    if (_lines.isEmpty) return;

    final haptics = ref.read(hapticServiceProvider);
    final lyricsService = ref.read(lyricsServiceProvider);
    haptics.medium();

    setState(() => _isSaving = true);

    try {
      final lrcContent = LrcBuilder.build(
        lines: _lines,
        title: widget.track.title,
      );

      final success = await lyricsService.saveLyrics(widget.track, lrcContent);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Synchronized .lrc file saved successfully!'
                  : 'Lyrics saved to library cache',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save lyrics: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _openTextPasteDialog() {
    final textController = TextEditingController(
      text: _lines.map((l) => l.text).join('\n'),
    );

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit / Paste Plain Lyrics'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: textController,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'Paste lyrics lines here...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newLines = LrcBuilder.parsePlainTextLines(
                textController.text,
              );
              if (newLines.isNotEmpty) {
                setState(() {
                  _lines.clear();
                  _lines.addAll(newLines);
                  _activeStampIndex = 0;
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('Apply Lines'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playback = ref.read(playbackControllerProvider);
    final snapshotAsync = ref.watch(playbackSnapshotProvider);
    final snapshot = snapshotAsync.value ?? playback.currentSnapshot;
    final currentPos = snapshot.position;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LRC Lyrics Studio'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.paste_rounded),
            tooltip: 'Paste Plain Text',
            onPressed: _openTextPasteDialog,
          ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveLrc,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save .lrc'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top control bar with slow-mo, offset adjust
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.s,
                  ),
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  child: Row(
                    children: [
                      // Speed chips for precision syncing
                      Text(
                        'Speed:',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Wrap(
                        spacing: 4,
                        children: [0.75, 1.0].map((speed) {
                          final isSelected =
                              (snapshot.speed - speed).abs() < 0.05;
                          return ChoiceChip(
                            label: Text('${speed}x'),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) playback.setSpeed(speed);
                            },
                          );
                        }).toList(),
                      ),
                      const Spacer(),
                      // Offset adjustments
                      IconButton(
                        icon: const Icon(Icons.fast_rewind_rounded, size: 20),
                        tooltip: 'Offset -100ms',
                        onPressed: () =>
                            _shiftOffset(const Duration(milliseconds: -100)),
                      ),
                      Text('±100ms', style: theme.textTheme.labelSmall),
                      IconButton(
                        icon: const Icon(Icons.fast_forward_rounded, size: 20),
                        tooltip: 'Offset +100ms',
                        onPressed: () =>
                            _shiftOffset(const Duration(milliseconds: 100)),
                      ),
                    ],
                  ),
                ),

                // Lyrics Lines List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _lines.length,
                    itemBuilder: (context, index) {
                      final line = _lines[index];
                      final isTarget = index == _activeStampIndex;
                      final isStamped = line.timestamp > Duration.zero;

                      return ListTile(
                        selected: isTarget,
                        selectedTileColor: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.3),
                        leading: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isStamped
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isStamped
                                ? LrcBuilder.formatTimestamp(line.timestamp)
                                      .replaceAll('[', '')
                                      .replaceAll(']', '')
                                : '--:--.--',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isStamped
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        title: Text(
                          line.text,
                          style: TextStyle(
                            fontWeight: isTarget
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isTarget ? theme.colorScheme.primary : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.play_circle_outline_rounded,
                            size: 20,
                          ),
                          tooltip: 'Jump to this line',
                          onPressed: () {
                            if (isStamped) {
                              playback.seek(line.timestamp);
                            }
                            setState(() => _activeStampIndex = index);
                          },
                        ),
                        onTap: () {
                          setState(() => _activeStampIndex = index);
                        },
                      );
                    },
                  ),
                ),

                // Bottom Transport & Big STAMP Bar
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Transport mini row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.replay_5_rounded),
                              tooltip: 'Back 5s',
                              onPressed: () {
                                final pos =
                                    currentPos - const Duration(seconds: 5);
                                playback.seek(
                                  pos.isNegative ? Duration.zero : pos,
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                snapshot.isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                              ),
                              iconSize: 44,
                              color: theme.colorScheme.primary,
                              onPressed: () => playback.togglePlayPause(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.forward_5_rounded),
                              tooltip: 'Forward 5s',
                              onPressed: () {
                                playback.seek(
                                  currentPos + const Duration(seconds: 5),
                                );
                              },
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Text(
                              LrcBuilder.formatTimestamp(currentPos),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s),

                        // Tactile Big STAMP Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => _stampCurrentLine(currentPos),
                            icon: const Icon(
                              Icons.fingerprint_rounded,
                              size: 28,
                            ),
                            label: Text(
                              'STAMP LINE ${_activeStampIndex + 1} / ${_lines.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
