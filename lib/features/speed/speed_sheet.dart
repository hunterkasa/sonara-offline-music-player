import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_tokens.dart';
import '../../audio/playback_controller.dart';
import '../../core/services/haptic_service.dart';
import '../../core/utils/pitch_calculator.dart';
import '../../domain/services/audio_settings_service.dart';

class SpeedSheet extends ConsumerWidget {
  const SpeedSheet({super.key});

  static const List<double> _presetSpeeds = [
    0.5,
    0.75,
    0.9,
    1.0,
    1.1,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final snapshotAsync = ref.watch(playbackSnapshotProvider);
    final currentSpeed = snapshotAsync.value?.speed ?? 1.0;
    final haptics = ref.read(hapticServiceProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: AppSpacing.m),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PLAYBACK SPEED',
                  style: theme.textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${currentSpeed.toStringAsFixed(2)}x',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Audio pitch is preserved automatically',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _presetSpeeds.map((speed) {
                final isSelected = (speed - currentSpeed).abs() < 0.01;
                return ChoiceChip(
                  label: Text(speed == 1.0 ? '1.0x (Normal)' : '${speed}x'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      haptics.selection();
                      ref.read(playbackControllerProvider).setSpeed(speed);
                    }
                  },
                  selectedColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                );
              }).toList(),
            ),
            const Divider(height: 32),

            // KEY TRANSPOSITION SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'KEY TRANSPOSITION',
                  style: theme.textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
                    PitchCalculator.formatSemitones(
                      snapshotAsync.value?.pitchSemitones ?? 0,
                    ),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              PitchCalculator.getIntervalName(
                snapshotAsync.value?.pitchSemitones ?? 0,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Slider(
              value: (snapshotAsync.value?.pitchSemitones ?? 0).toDouble(),
              min: -12.0,
              max: 12.0,
              divisions: 24,
              label: '${snapshotAsync.value?.pitchSemitones ?? 0}',
              onChanged: (val) {
                final semitones = val.round();
                haptics.selection();
                ref
                    .read(playbackControllerProvider)
                    .setPitchSemitones(semitones);
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
                  onPressed: (snapshotAsync.value?.pitchSemitones ?? 0) == 0
                      ? null
                      : () {
                          haptics.selection();
                          ref
                              .read(playbackControllerProvider)
                              .setPitchSemitones(0);
                          ref
                              .read(audioSettingsProvider.notifier)
                              .setPitchSemitones(0);
                        },
                  child: const Text('Reset Key'),
                ),
                Text('+12 (Octave Up)', style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
          ],
        ),
      ),
    );
  }
}
