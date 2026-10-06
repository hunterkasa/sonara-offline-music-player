import 'dart:math';

import 'package:flutter/material.dart';

enum VisualizerStyle { spectrum, vuMeter, fluidWave }

class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final VisualizerStyle style;
  final Color? accentColor;
  final double height;

  const AudioVisualizer({
    super.key,
    required this.isPlaying,
    this.style = VisualizerStyle.spectrum,
    this.accentColor,
    this.height = 120.0,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _rng = Random(42);

  // Simulated frequency bands for spectrum
  final List<double> _bandValues = List.filled(24, 0.1);
  final List<double> _peakValues = List.filled(24, 0.1);

  // VU meter needle values
  double _leftVu = -20.0;
  double _rightVu = -20.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tick);

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      // Smoothly let values decay to zero then stop
      _controller.stop();
      _decayToZero();
    }
  }

  void _decayToZero() {
    for (var i = 0; i < _bandValues.length; i++) {
      _bandValues[i] = 0.05;
      _peakValues[i] = 0.05;
    }
    _leftVu = -20.0;
    _rightVu = -20.0;
    if (mounted) setState(() {});
  }

  void _tick() {
    if (!widget.isPlaying) return;

    // Update spectrum bands with dynamic movement
    final t = _controller.value * 2 * pi;
    for (var i = 0; i < _bandValues.length; i++) {
      final target =
          (sin(t * (1.5 + (i * 0.2)) + i) * 0.4 + 0.5) *
          (0.7 + _rng.nextDouble() * 0.3);
      _bandValues[i] = _bandValues[i] * 0.6 + target * 0.4;
      if (_bandValues[i] > _peakValues[i]) {
        _peakValues[i] = _bandValues[i];
      } else {
        _peakValues[i] = max(0.05, _peakValues[i] - 0.02);
      }
    }

    // Update VU meters (-20 dB to +3 dB)
    final vuNoise = _rng.nextDouble() * 4.0;
    _leftVu = (_leftVu * 0.7) + (-6.0 + sin(t * 2) * 5.0 + vuNoise) * 0.3;
    _rightVu = (_rightVu * 0.7) + (-5.0 + cos(t * 2.2) * 4.5 + vuNoise) * 0.3;

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accentColor ?? theme.colorScheme.primary;

    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: CustomPaint(
          painter: _VisualizerPainter(
            style: widget.style,
            isPlaying: widget.isPlaying,
            accentColor: accent,
            surfaceColor: theme.colorScheme.surfaceContainerHighest,
            bands: _bandValues,
            peaks: _peakValues,
            leftVuDb: _leftVu,
            rightVuDb: _rightVu,
            animationValue: _controller.value,
          ),
        ),
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final VisualizerStyle style;
  final bool isPlaying;
  final Color accentColor;
  final Color surfaceColor;
  final List<double> bands;
  final List<double> peaks;
  final double leftVuDb;
  final double rightVuDb;
  final double animationValue;

  _VisualizerPainter({
    required this.style,
    required this.isPlaying,
    required this.accentColor,
    required this.surfaceColor,
    required this.bands,
    required this.peaks,
    required this.leftVuDb,
    required this.rightVuDb,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case VisualizerStyle.spectrum:
        _paintSpectrum(canvas, size);
        break;
      case VisualizerStyle.vuMeter:
        _paintVuMeters(canvas, size);
        break;
      case VisualizerStyle.fluidWave:
        _paintFluidWave(canvas, size);
        break;
    }
  }

  void _paintSpectrum(Canvas canvas, Size size) {
    final count = bands.length;
    final spacing = size.width * 0.2 / (count - 1);
    final barWidth = (size.width - (spacing * (count - 1))) / count;

    final barPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [accentColor.withValues(alpha: 0.7), accentColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final peakPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < count; i++) {
      final x = i * (barWidth + spacing);
      final h = (bands[i] * size.height * 0.85).clamp(4.0, size.height);
      final y = size.height - h;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, h),
        Radius.circular(barWidth / 3.0),
      );
      canvas.drawRRect(rrect, barPaint);

      // Draw peak dot
      final peakH = (peaks[i] * size.height * 0.85).clamp(4.0, size.height);
      final peakY = size.height - peakH - 3.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, peakY, barWidth, 2.0),
          const Radius.circular(1.0),
        ),
        peakPaint,
      );
    }
  }

  void _paintVuMeters(Canvas canvas, Size size) {
    final meterWidth = (size.width - 24.0) / 2.0;
    _paintSingleVu(
      canvas,
      Rect.fromLTWH(0, 0, meterWidth, size.height),
      leftVuDb,
      'LEFT (L)',
    );
    _paintSingleVu(
      canvas,
      Rect.fromLTWH(meterWidth + 24.0, 0, meterWidth, size.height),
      rightVuDb,
      'RIGHT (R)',
    );
  }

  void _paintSingleVu(
    Canvas canvas,
    Rect rect,
    double dbValue,
    String channelLabel,
  ) {
    // Background dial card
    final bgPaint = Paint()..color = surfaceColor.withValues(alpha: 0.5);
    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dialRRect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(dialRRect, bgPaint);
    canvas.drawRRect(dialRRect, borderPaint);

    final centerX = rect.center.dx;
    final pivotY = rect.bottom + (rect.height * 0.2);
    final radius = rect.height * 1.0;

    // Scale arc: -20 dB to +3 dB mapped to -45 deg to +45 deg
    // dB to angle formula:
    final clampedDb = dbValue.clamp(-20.0, 3.0);
    final normalized = (clampedDb + 20.0) / 23.0; // 0.0 to 1.0
    final angle = (-40.0 + (normalized * 80.0)) * (pi / 180.0);

    // Needle line
    final needleX = centerX + (sin(angle) * radius);
    final needleY = pivotY - (cos(angle) * radius);

    final needlePaint = Paint()
      ..color = clampedDb >= 0 ? Colors.redAccent : accentColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX, rect.bottom - 4),
      Offset(needleX, needleY.clamp(rect.top + 8, rect.bottom)),
      needlePaint,
    );

    // Peak LED
    final ledPaint = Paint()
      ..color = clampedDb >= 0
          ? Colors.redAccent
          : Colors.grey.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(rect.right - 14, rect.top + 14), 4.0, ledPaint);
  }

  void _paintFluidWave(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          accentColor.withValues(alpha: 0.1),
          accentColor.withValues(alpha: 0.4),
          accentColor.withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path();
    path.moveTo(0, size.height);

    final t = animationValue * 2 * pi;
    final midY = size.height * 0.55;

    for (var x = 0.0; x <= size.width; x += 10.0) {
      final normX = x / size.width;
      final y =
          midY +
          sin(normX * 4 * pi + t) * (size.height * 0.22) +
          cos(normX * 2 * pi - t) * (size.height * 0.12);
      if (x == 0) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, wavePaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.style != style ||
        oldDelegate.isPlaying != isPlaying;
  }
}
