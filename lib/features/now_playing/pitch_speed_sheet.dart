import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/playback_controller.dart';
import '../../core/utils/pitch_calculator.dart';
import '../../domain/services/audio_settings_service.dart';

class PitchSpeedSheet extends ConsumerWidget {
  const PitchSpeedSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final snapshotAsync = ref.watch(playbackSnapshotProvider);
    final controller = ref.watch(playbackControllerProvider);
    final snapshot = snapshotAsync.value ?? controller.currentSnapshot;
    final currentSpeed = snapshot.speed;
    final currentSemitones = snapshot.pitchSemitones;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
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
          const SizedBox(height: 16),
          Text(
            'Tempo & Key Transposition',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // 1. Musical Pitch Transposition
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.music_note,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Key Transposition',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  PitchCalculator.formatSemitones(currentSemitones),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            PitchCalculator.getIntervalName(currentSemitones),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Slider(
            value: currentSemitones.toDouble(),
            min: -12.0,
            max: 12.0,
            divisions: 24,
            label: '$currentSemitones',
            onChanged: (val) {
              final semitones = val.round();
              controller.setPitchSemitones(semitones);
              ref
                  .read(audioSettingsProvider.notifier)
                  .setPitchSemitones(semitones);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('-12 (Octave Down)', style: theme.textTheme.labelSmall),
              TextButton(
                onPressed: currentSemitones == 0
                    ? null
                    : () {
                        controller.setPitchSemitones(0);
                        ref
                            .read(audioSettingsProvider.notifier)
                            .setPitchSemitones(0);
                      },
                child: const Text('Reset Key'),
              ),
              Text('+12 (Octave Up)', style: theme.textTheme.labelSmall),
            ],
          ),

          const Divider(height: 28),

          // 2. Playback Speed (Tempo)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.speed, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Playback Speed',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${currentSpeed.toStringAsFixed(2)}x',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: currentSpeed,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            label: '${currentSpeed.toStringAsFixed(2)}x',
            onChanged: (val) {
              controller.setSpeed(val);
              ref.read(audioSettingsProvider.notifier).setPlaybackSpeed(val);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [0.75, 1.0, 1.25, 1.5].map((s) {
              final isSelected = (currentSpeed - s).abs() < 0.05;
              return ChoiceChip(
                label: Text('${s}x'),
                selected: isSelected,
                onSelected: (_) {
                  controller.setSpeed(s);
                  ref.read(audioSettingsProvider.notifier).setPlaybackSpeed(s);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
