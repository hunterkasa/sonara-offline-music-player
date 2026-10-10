import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_tokens.dart';
import '../../audio/sleep_timer.dart';
import '../../core/services/gesture_sensor_service.dart';
import '../../core/services/haptic_service.dart';
import '../../domain/models/audio_settings.dart';

class SleepTimerSheet extends ConsumerStatefulWidget {
  const SleepTimerSheet({super.key});

  @override
  ConsumerState<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends ConsumerState<SleepTimerSheet> {
  double _customMinutes = 20;

  @override
  Widget build(BuildContext context) {
    ref.watch(gestureSensorServiceProvider);
    final theme = Theme.of(context);
    final timerState = ref.watch(sleepTimerProvider);
    final timerController = ref.read(sleepTimerProvider.notifier);
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
                  'SLEEP TIMER',
                  style: theme.textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (timerState.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      timerState.mode == SleepTimerMode.endOfTrack
                          ? 'End of Track'
                          : _formatRemaining(timerState.remaining),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),

            if (timerState.isActive) ...[
              Card(
                color: theme.colorScheme.surfaceContainerHighest,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('+15 min'),
                        onPressed: () {
                          haptics.selection();
                          timerController.extendTimer();
                        },
                      ),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('Turn Off'),
                        onPressed: () {
                          haptics.medium();
                          timerController.cancelTimer();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
            ],

            Text(
              'Presets',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip(
                  context,
                  label: '15 min',
                  duration: const Duration(minutes: 15),
                ),
                _buildPresetChip(
                  context,
                  label: '30 min',
                  duration: const Duration(minutes: 30),
                ),
                _buildPresetChip(
                  context,
                  label: '45 min',
                  duration: const Duration(minutes: 45),
                ),
                _buildPresetChip(
                  context,
                  label: '60 min',
                  duration: const Duration(minutes: 60),
                ),
                ActionChip(
                  avatar: const Icon(Icons.music_note_rounded, size: 18),
                  label: const Text('End of Track'),
                  onPressed: () {
                    haptics.selection();
                    timerController.startEndOfTrack();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),

            Text(
              'Custom: ${_customMinutes.round()} minutes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: _customMinutes,
              min: 5,
              max: 120,
              divisions: 23,
              label: '${_customMinutes.round()} min',
              onChanged: (val) {
                setState(() => _customMinutes = val);
              },
            ),
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.m),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.vibration_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Smart Gestures: Shake phone to add +15 min • Flip face-down to pause',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Fade-Out Curve',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<SleepTimerFadeCurve>(
              segments: const [
                ButtonSegment(
                  value: SleepTimerFadeCurve.linear,
                  label: Text('Linear'),
                  icon: Icon(Icons.show_chart_rounded, size: 16),
                ),
                ButtonSegment(
                  value: SleepTimerFadeCurve.logarithmic,
                  label: Text('Logarithmic'),
                  icon: Icon(Icons.trending_down_rounded, size: 16),
                ),
                ButtonSegment(
                  value: SleepTimerFadeCurve.exponential,
                  label: Text('Exponential'),
                  icon: Icon(Icons.water_drop_outlined, size: 16),
                ),
              ],
              selected: {timerState.fadeCurve},
              onSelectionChanged: (set) {
                haptics.selection();
                timerController.setFadeCurve(set.first);
              },
            ),
            const SizedBox(height: AppSpacing.m),
            FilledButton(
              onPressed: () {
                haptics.selection();
                timerController.startTimer(
                  Duration(minutes: _customMinutes.round()),
                );
                Navigator.of(context).pop();
              },
              child: Text('Start ${_customMinutes.round()} min Timer'),
            ),
            const SizedBox(height: AppSpacing.s),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    BuildContext context, {
    required String label,
    required Duration duration,
  }) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        ref.read(hapticServiceProvider).selection();
        ref.read(sleepTimerProvider.notifier).startTimer(duration);
        Navigator.of(context).pop();
      },
    );
  }

  String _formatRemaining(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
