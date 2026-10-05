import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_tokens.dart';
import '../../core/services/haptic_service.dart';
import '../../domain/models/equalizer_preset.dart';
import '../../domain/services/audio_settings_service.dart';

class EqualizerScreen extends ConsumerWidget {
  const EqualizerScreen({super.key});

  static const List<String> bandLabels = [
    '60 Hz',
    '230 Hz',
    '910 Hz',
    '3.6 kHz',
    '14 kHz',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(audioSettingsProvider);
    final notifier = ref.read(audioSettingsProvider.notifier);
    final haptics = ref.read(hapticServiceProvider);

    final isEnabled = settings.equalizerEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equalizer'),
        actions: [
          Row(
            children: [
              Text(
                isEnabled ? 'ON' : 'OFF',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Switch(
                value: isEnabled,
                onChanged: (val) {
                  haptics.selection();
                  notifier.setEqualizerEnabled(val);
                },
              ),
              const SizedBox(width: AppSpacing.s),
            ],
          ),
        ],
      ),
      body: AnimatedOpacity(
        opacity: isEnabled ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !isEnabled,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
            children: [
              // Presets selector
              Text(
                'PRESETS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...EqualizerPreset.defaultPresets.map((preset) {
                      final isSelected = settings.equalizerPreset == preset.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: ChoiceChip(
                          label: Text(preset.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              haptics.selection();
                              notifier.setEqualizerPreset(preset.id);
                            }
                          },
                        ),
                      );
                    }),
                    ChoiceChip(
                      label: const Text('Custom'),
                      selected: settings.equalizerPreset == 'custom',
                      onSelected: (selected) {
                        if (selected) {
                          haptics.selection();
                          notifier.setEqualizerPreset('custom');
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // Frequency response curve graphic
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.s),
                child: CustomPaint(
                  painter: _EqualizerCurvePainter(
                    bandGains: settings.bandGains,
                    primaryColor: theme.colorScheme.primary,
                    gridColor: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
                    textColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              // 5-Band Vertical Sliders
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.s,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    final gain = index < settings.bandGains.length
                        ? settings.bandGains[index]
                        : 0.0;
                    return _BandSlider(
                      label: bandLabels[index],
                      gainDb: gain,
                      onChanged: (newGain) {
                        notifier.setBandGain(index, newGain);
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              // Sound Effects Section: Bass Boost & Loudness
              Text(
                'SOUND ENHANCEMENTS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.s),

              // Bass Boost Card
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                margin: const EdgeInsets.only(bottom: AppSpacing.s),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.speaker_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Bass Boost',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${(settings.bassBoost * 100).round()}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: settings.bassBoost,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        onChanged: (val) {
                          notifier.setBassBoost(val);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Loudness Enhancer Card
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                margin: const EdgeInsets.only(bottom: AppSpacing.s),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.volume_up_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Loudness Enhancer',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '+${settings.loudnessGain.toStringAsFixed(1)} dB',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: settings.loudnessGain,
                        min: 0.0,
                        max: 10.0,
                        divisions: 20,
                        onChanged: (val) {
                          notifier.setLoudnessGain(val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s),

              // Reset to Flat Action
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    haptics.light();
                    notifier.setEqualizerPreset('flat');
                    notifier.setBassBoost(0.0);
                    notifier.setLoudnessGain(0.0);
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset All to Flat'),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _BandSlider extends StatelessWidget {
  const _BandSlider({
    required this.label,
    required this.gainDb,
    required this.onChanged,
  });

  final String label;
  final double gainDb;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sign = gainDb > 0 ? '+' : '';
    final formattedDb = '$sign${gainDb.toStringAsFixed(1)}';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          formattedDb,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: gainDb != 0
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: gainDb.clamp(-15.0, 15.0),
                min: -15.0,
                max: 15.0,
                divisions: 60,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EqualizerCurvePainter extends CustomPainter {
  final List<double> bandGains;
  final Color primaryColor;
  final Color gridColor;
  final Color textColor;

  _EqualizerCurvePainter({
    required this.bandGains,
    required this.primaryColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerY = h / 2;

    // Draw grid lines: +15dB, 0dB, -15dB
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, centerY), Offset(w, centerY), gridPaint);
    canvas.drawLine(const Offset(0, 4), Offset(w, 4), gridPaint);
    canvas.drawLine(Offset(0, h - 4), Offset(w, h - 4), gridPaint);

    if (bandGains.isEmpty) return;

    // Calculate node points
    final count = bandGains.length;
    final stepX = w / (count + 1);
    final points = <Offset>[];

    // Left boundary anchor at 0 dB
    points.add(Offset(0, centerY));

    for (var i = 0; i < count; i++) {
      final x = stepX * (i + 1);
      final gain = bandGains[i].clamp(-15.0, 15.0);
      // Normalized: -15 dB is bottom (h - 10), +15 dB is top (10)
      final y = centerY - (gain / 15.0) * (centerY - 10);
      points.add(Offset(x, y));
    }

    // Right boundary anchor at 0 dB
    points.add(Offset(w, centerY));

    // Build smooth cubic Bezier path
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : p2;

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;

      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    // Gradient fill under the curve
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.35),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final strokePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // Draw node dots
    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    for (var i = 1; i <= count; i++) {
      canvas.drawCircle(points[i], 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EqualizerCurvePainter oldDelegate) {
    return oldDelegate.bandGains != bandGains ||
        oldDelegate.primaryColor != primaryColor;
  }
}
