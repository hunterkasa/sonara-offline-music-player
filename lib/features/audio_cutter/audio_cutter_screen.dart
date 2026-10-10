import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;

import '../../app/theme/theme_tokens.dart';
import '../../core/services/audio_cutter_service.dart';
import '../../core/services/haptic_service.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import '../../domain/services/library_scanner.dart';
import '../../shared/artwork/artwork_widget.dart';
import 'widgets/waveform_trimmer.dart';

class AudioCutterScreen extends ConsumerStatefulWidget {
  final String trackKey;

  const AudioCutterScreen({super.key, required this.trackKey});

  @override
  ConsumerState<AudioCutterScreen> createState() => _AudioCutterScreenState();
}

class _AudioCutterScreenState extends ConsumerState<AudioCutterScreen> {
  Track? _track;
  String? _artistName;
  bool _isLoading = true;
  bool _isProcessing = false;

  late final AudioPlayer _previewPlayer;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;

  int _startMs = 0;
  int _endMs = 30000;
  int _currentPositionMs = 0;
  bool _isPlaying = false;
  bool _isLooping = true;

  @override
  void initState() {
    super.initState();
    _previewPlayer = AudioPlayer();
    _loadTrack();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadTrack() async {
    final db = ref.read(databaseProvider);
    final track = await db.getTrackByKey(widget.trackKey);

    if (!mounted) return;
    if (track == null) {
      setState(() => _isLoading = false);
      return;
    }

    final artist = await db.getArtistName(track.artistId);
    final durationMs = track.durationMs > 0 ? track.durationMs : 180000;
    // Default to 30 second selection (standard ringtone duration)
    final initialEnd = math.min(30000, durationMs);

    if (!mounted) return;
    setState(() {
      _track = track;
      _artistName = artist;
      _startMs = 0;
      _endMs = initialEnd;
      _currentPositionMs = 0;
      _isLoading = false;
    });

    unawaited(_initAudioPlayer(track));
  }

  Future<void> _initAudioPlayer(Track track) async {
    try {
      if (track.path.isNotEmpty && await File(track.path).exists()) {
        await _previewPlayer.setFilePath(track.path);
      } else if (track.contentUri.isNotEmpty) {
        await _previewPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(track.contentUri)),
        );
      }

      _positionSub = _previewPlayer.positionStream.listen((pos) {
        final posMs = pos.inMilliseconds;
        if (!mounted) return;

        setState(() {
          _currentPositionMs = posMs;
        });

        // Loop enforcement
        if (posMs >= _endMs) {
          if (_isLooping) {
            _previewPlayer.seek(Duration(milliseconds: _startMs));
            if (!_previewPlayer.playing) {
              _previewPlayer.play();
            }
          } else {
            _previewPlayer.pause();
            _previewPlayer.seek(Duration(milliseconds: _startMs));
          }
        }
      });

      _stateSub = _previewPlayer.playerStateStream.listen((state) async {
        if (!mounted) return;
        setState(() {
          _isPlaying = state.playing;
        });
        if (state.processingState == ProcessingState.completed) {
          if (_isLooping) {
            await _previewPlayer.seek(Duration(milliseconds: _startMs));
            await _previewPlayer.play();
          } else {
            await _previewPlayer.seek(Duration(milliseconds: _startMs));
          }
        }
      });
    } catch (e) {
      debugPrint('Error initializing preview player: $e');
    }
  }

  void _onRangeChanged(int start, int end) {
    setState(() {
      _startMs = start;
      _endMs = end;
      if (_currentPositionMs < start || _currentPositionMs > end) {
        _currentPositionMs = start;
        _previewPlayer.seek(Duration(milliseconds: start));
      }
    });
  }

  void _onSeek(int seekMs) {
    final clamped = seekMs.clamp(_startMs, _endMs);
    setState(() => _currentPositionMs = clamped);
    _previewPlayer.seek(Duration(milliseconds: clamped));
  }

  void _nudgeStart(int deltaMs) {
    ref.read(hapticServiceProvider).light();
    final newStart = (_startMs + deltaMs).clamp(0, _endMs - 1000);
    _onRangeChanged(newStart, _endMs);
  }

  void _nudgeEnd(int deltaMs) {
    ref.read(hapticServiceProvider).light();
    final maxMs = _track?.durationMs ?? 300000;
    final newEnd = (_endMs + deltaMs).clamp(_startMs + 1000, maxMs);
    _onRangeChanged(_startMs, newEnd);
  }

  Future<void> _togglePlayPreview() async {
    ref.read(hapticServiceProvider).selection();
    if (_isPlaying) {
      await _previewPlayer.pause();
    } else {
      if (_currentPositionMs < _startMs || _currentPositionMs >= _endMs) {
        await _previewPlayer.seek(Duration(milliseconds: _startMs));
      }
      await _previewPlayer.play();
    }
  }

  Future<void> _resetToStart() async {
    ref.read(hapticServiceProvider).light();
    await _previewPlayer.seek(Duration(milliseconds: _startMs));
    setState(() => _currentPositionMs = _startMs);
  }

  String _formatTime(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final millis = (ms % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(2, '0')}';
  }

  Future<void> _exportClip({
    RingtoneType? ringtoneType,
    bool shareAfterExport = false,
  }) async {
    final track = _track;
    if (track == null) return;

    final cutterService = ref.read(audioCutterServiceProvider);
    final haptics = ref.read(hapticServiceProvider);

    // Permission check for ringtones
    if (ringtoneType != null) {
      final canWrite = await cutterService.canWriteSystemSettings();
      if (!canWrite && mounted) {
        final shouldOpen = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Android requires "Modify system settings" permission to set phone ringtones, notifications, and alarms.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (shouldOpen == true) {
          await cutterService.openWriteSettings();
        }
        return;
      }
    }

    setState(() => _isProcessing = true);
    haptics.medium();

    try {
      final exportPath = await cutterService.getDefaultExportPath(
        originalPath: track.path,
        title: track.title,
      );

      final success = await cutterService.trimAudio(
        sourcePath: track.path,
        destinationPath: exportPath,
        startMs: _startMs,
        endMs: _endMs,
      );

      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to cut audio file. Please check storage permissions.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // If setting as ringtone
      if (ringtoneType != null) {
        final ringtoneSet = await cutterService.setAsRingtone(
          filePath: exportPath,
          title: '${track.title} (Clip)',
          type: ringtoneType,
        );

        if (mounted) {
          final typeName = switch (ringtoneType) {
            RingtoneType.ringtone => 'Phone ringtone',
            RingtoneType.notification => 'Notification sound',
            RingtoneType.alarm => 'Alarm tone',
          };

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ringtoneSet
                    ? 'Successfully set as $typeName!'
                    : 'Saved clip, but could not set as $typeName.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (shareAfterExport) {
        await cutterService.shareAudio(
          filePath: exportPath,
          title: '${track.title} (Clip)',
        );
      } else {
        // Normal save
        unawaited(ref.read(libraryScannerProvider.notifier).scanLibrary());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved clip to: ${File(exportPath).uri.pathSegments.last}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final track = _track;
    if (track == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Audio Cutter')),
        body: const Center(child: Text('Track not found')),
      );
    }

    final durationMs = track.durationMs > 0 ? track.durationMs : 180000;
    final clipDurationMs = _endMs - _startMs;
    final ext = p.extension(track.path).replaceAll('.', '').toUpperCase();
    final formatBadge = ext.isNotEmpty ? ext : 'AUDIO';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Cutter & Ringtone Studio'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.s,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Track Info Header
              _buildTrackHeader(theme, track, formatBadge),
              const SizedBox(height: AppSpacing.m),

              // 2. Waveform Trimmer Canvas
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.s),
                child: WaveformTrimmer(
                  totalDurationMs: durationMs,
                  startMs: _startMs,
                  endMs: _endMs,
                  currentPositionMs: _currentPositionMs,
                  onRangeChanged: _onRangeChanged,
                  onSeek: _onSeek,
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // 3. Time Stats Card
              _buildTimeStatsCard(theme, clipDurationMs),
              const SizedBox(height: AppSpacing.m),

              // 4. Precision Nudge Controls
              _buildNudgeControls(theme),
              const SizedBox(height: AppSpacing.m),

              // 5. Preview Transport Bar
              _buildTransportBar(theme),
              const SizedBox(height: AppSpacing.l),

              // 6. Export Actions
              _buildActionsSection(theme),
              const SizedBox(height: AppSpacing.l),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackHeader(ThemeData theme, Track track, String formatBadge) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ArtworkWidget(
            artworkKey: track.artworkKey,
            filePath: track.path,
            title: track.title,
            size: 56,
            borderRadius: 10.0,
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _artistName ?? 'Unknown Artist',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              formatBadge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStatsCard(ThemeData theme, int clipDurationMs) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.m,
        horizontal: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTimeColumn(
            theme,
            'Start Point',
            _formatTime(_startMs),
            Colors.green,
          ),
          Container(
            height: 32,
            width: 1,
            color: theme.colorScheme.outlineVariant,
          ),
          _buildTimeColumn(
            theme,
            'Clip Duration',
            _formatTime(clipDurationMs),
            theme.colorScheme.primary,
          ),
          Container(
            height: 32,
            width: 1,
            color: theme.colorScheme.outlineVariant,
          ),
          _buildTimeColumn(
            theme,
            'End Point',
            _formatTime(_endMs),
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildNudgeControls(ThemeData theme) {
    return Column(
      children: [
        _buildNudgeRow(
          theme: theme,
          label: 'Start Marker',
          color: Colors.green,
          onNudge: _nudgeStart,
        ),
        const SizedBox(height: AppSpacing.s),
        _buildNudgeRow(
          theme: theme,
          label: 'End Marker',
          color: Colors.orange,
          onNudge: _nudgeEnd,
        ),
      ],
    );
  }

  Widget _buildNudgeRow({
    required ThemeData theme,
    required String label,
    required Color color,
    required void Function(int deltaMs) onNudge,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNudgeButton('-1s', () => onNudge(-1000)),
              _buildNudgeButton('-0.1s', () => onNudge(-100)),
              _buildNudgeButton('+0.1s', () => onNudge(100)),
              _buildNudgeButton('+1s', () => onNudge(1000)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNudgeButton(String text, VoidCallback onPressed) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(48, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTransportBar(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          icon: const Icon(Icons.replay_rounded),
          tooltip: 'Seek to start',
          onPressed: _resetToStart,
        ),
        const SizedBox(width: AppSpacing.m),
        IconButton.filled(
          iconSize: 36,
          padding: const EdgeInsets.all(16),
          icon: Icon(
            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          ),
          tooltip: _isPlaying ? 'Pause preview' : 'Play preview',
          onPressed: _togglePlayPreview,
        ),
        const SizedBox(width: AppSpacing.m),
        IconButton.filledTonal(
          icon: Icon(
            _isLooping ? Icons.repeat_one_rounded : Icons.repeat_rounded,
          ),
          style: IconButton.styleFrom(
            backgroundColor: _isLooping
                ? theme.colorScheme.primaryContainer
                : null,
            foregroundColor: _isLooping
                ? theme.colorScheme.onPrimaryContainer
                : null,
          ),
          tooltip: _isLooping ? 'Looping enabled' : 'Looping disabled',
          onPressed: () {
            ref.read(hapticServiceProvider).selection();
            setState(() => _isLooping = !_isLooping);
          },
        ),
      ],
    );
  }

  Widget _buildActionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Export & Assignment Actions',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        if (_isProcessing)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.m),
              child: CircularProgressIndicator(),
            ),
          )
        else ...[
          FilledButton.icon(
            icon: const Icon(Icons.ring_volume_rounded),
            label: const Text('Set as Phone Ringtone'),
            onPressed: () => _exportClip(ringtoneType: RingtoneType.ringtone),
          ),
          const SizedBox(height: AppSpacing.s),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text('Notification'),
                  onPressed: () =>
                      _exportClip(ringtoneType: RingtoneType.notification),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.alarm_rounded),
                  label: const Text('Alarm Tone'),
                  onPressed: () =>
                      _exportClip(ringtoneType: RingtoneType.alarm),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.save_alt_rounded),
                  label: const Text('Save Clip'),
                  onPressed: () => _exportClip(),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share Clip'),
                  onPressed: () => _exportClip(shareAfterExport: true),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
