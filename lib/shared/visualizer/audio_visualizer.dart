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

  // 24 simulated frequency bands for spectrum
  final List<double> _bandValues = List.filled(24, 0.12);
  final List<double> _peakValues = List.filled(24, 0.15);

  // VU meter needle values (dB: -20 to +3)
  double _leftVu = -18.0;
  double _rightVu = -18.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addListener(_tick);

    _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  void _tick() {
    final t = _controller.value * 2 * pi;

    if (widget.isPlaying) {
      // Dynamic audio spectrum simulation with realistic bass-heavy curve
      for (var i = 0; i < _bandValues.length; i++) {
        // Bass frequencies have larger amplitude, treble has faster flicker
        final freqWeight = (1.0 - (i / _bandValues.length) * 0.45);
        final harmonic = sin(t * (2.0 + (i * 0.35)) + (i * 0.8));
        final noise = (_rng.nextDouble() - 0.5) * 0.25;
        final target = ((harmonic * 0.4 + 0.5) * freqWeight + noise).clamp(
          0.08,
          0.96,
        );

        _bandValues[i] = _bandValues[i] * 0.55 + target * 0.45;

        if (_bandValues[i] > _peakValues[i]) {
          _peakValues[i] = _bandValues[i];
        } else {
          _peakValues[i] = max(0.08, _peakValues[i] - 0.015);
        }
      }

      // VU meters (-20 dB to +3 dB) with realistic analog inertia
      final vuPulse = (sin(t * 2.8) * 6.0) + (cos(t * 1.4) * 4.0);
      final leftTarget = (-7.0 + vuPulse + _rng.nextDouble() * 3.5).clamp(
        -20.0,
        3.0,
      );
      final rightTarget = (-6.5 + vuPulse + _rng.nextDouble() * 3.5).clamp(
        -20.0,
        3.0,
      );

      _leftVu = (_leftVu * 0.65) + (leftTarget * 0.35);
      _rightVu = (_rightVu * 0.65) + (rightTarget * 0.35);
    } else {
      // Smooth decay towards resting floor when paused
      for (var i = 0; i < _bandValues.length; i++) {
        _bandValues[i] = max(0.06, _bandValues[i] * 0.92);
        _peakValues[i] = max(0.06, _peakValues[i] * 0.94);
      }
      _leftVu = max(-20.0, _leftVu - 0.5);
      _rightVu = max(-20.0, _rightVu - 0.5);
    }

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
    if (size.width <= 0 || size.height <= 0) return;

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
    final totalSpacing = size.width * 0.22;
    final spacing = count > 1 ? totalSpacing / (count - 1) : 4.0;
    final barWidth = (size.width - totalSpacing) / count;

    final barShader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        accentColor.withValues(alpha: 0.8),
        accentColor,
        Colors.white.withValues(alpha: 0.9),
      ],
      stops: const [0.0, 0.75, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final barPaint = Paint()..shader = barShader;
    final peakPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (var i = 0; i < count; i++) {
      final x = i * (barWidth + spacing);
      final h = (bands[i] * size.height * 0.88).clamp(6.0, size.height);
      final y = size.height - h;

      final rect = Rect.fromLTWH(x, y, barWidth, h);
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(barWidth * 0.35),
      );

      // Subtle glow behind active bar
      if (isPlaying && bands[i] > 0.4) {
        canvas.drawRRect(rrect, glowPaint);
      }
      canvas.drawRRect(rrect, barPaint);

      // Peak floating indicator cap
      final peakH = (peaks[i] * size.height * 0.88).clamp(6.0, size.height);
      final peakY = size.height - peakH - 3.5;
      final peakRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, peakY, barWidth, 2.5),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(peakRRect, peakPaint);
    }
  }

  void _paintVuMeters(Canvas canvas, Size size) {
    const gap = 16.0;
    final meterWidth = (size.width - gap) / 2.0;
    final meterHeight = size.height;

    _paintSingleVu(
      canvas,
      Rect.fromLTWH(0, 0, meterWidth, meterHeight),
      leftVuDb,
      'L',
      'LEFT CHANNEL',
    );
    _paintSingleVu(
      canvas,
      Rect.fromLTWH(meterWidth + gap, 0, meterWidth, meterHeight),
      rightVuDb,
      'R',
      'RIGHT CHANNEL',
    );
  }

  void _paintSingleVu(
    Canvas canvas,
    Rect rect,
    double dbValue,
    String badge,
    String channelLabel,
  ) {
    // 1. Dial plate casing & warm vintage background
    final bgRRect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1F1C18), Color(0xFF141312), Color(0xFF0D0C0B)],
      ).createShader(rect);
    canvas.drawRRect(bgRRect, bgPaint);

    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(bgRRect, borderPaint);

    final centerX = rect.center.dx;
    final pivotY = rect.bottom + (rect.height * 0.15);
    final radius = rect.height * 0.95;

    // 2. Scale arc graduations (-20 dB to +3 dB)
    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final redArcPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Scale mapping: -20 dB -> -42 deg, 0 dB -> +15 deg, +3 dB -> +38 deg
    double dbToAngle(double db) {
      if (db <= 0) {
        final norm = (db + 20.0) / 20.0; // 0.0 to 1.0
        return (-42.0 + (norm * 57.0)) * (pi / 180.0);
      } else {
        final norm = db / 3.0; // 0.0 to 1.0
        return (15.0 + (norm * 23.0)) * (pi / 180.0);
      }
    }

    final startAngle = dbToAngle(-20);
    final zeroAngle = dbToAngle(0);
    final maxAngle = dbToAngle(3);

    // Draw main scale arcs
    final arcRect = Rect.fromCircle(
      center: Offset(centerX, pivotY),
      radius: radius,
    );
    canvas.drawArc(
      arcRect,
      startAngle - (pi / 2),
      zeroAngle - startAngle,
      false,
      arcPaint,
    );
    canvas.drawArc(
      arcRect,
      zeroAngle - (pi / 2),
      maxAngle - zeroAngle,
      false,
      redArcPaint,
    );

    // Tick marks
    const ticks = [-20.0, -10.0, -7.0, -5.0, -3.0, -1.0, 0.0, 1.0, 2.0, 3.0];
    for (final tickDb in ticks) {
      final tickAngle = dbToAngle(tickDb);
      final isMajor = tickDb == -20 || tickDb == 0 || tickDb == 3;
      final isRed = tickDb >= 0;
      final tickLen = isMajor ? 8.0 : 4.5;

      final p1 = Offset(
        centerX + sin(tickAngle) * radius,
        pivotY - cos(tickAngle) * radius,
      );
      final p2 = Offset(
        centerX + sin(tickAngle) * (radius - tickLen),
        pivotY - cos(tickAngle) * (radius - tickLen),
      );

      final tickPaint = Paint()
        ..color = isRed
            ? Colors.redAccent
            : Colors.white.withValues(alpha: isMajor ? 0.7 : 0.35)
        ..strokeWidth = isMajor ? 1.5 : 1.0;

      canvas.drawLine(p1, p2, tickPaint);
    }

    // 3. Typography: "VU", "0 dB" and channel badge
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.text = TextSpan(
      text: badge,
      style: TextStyle(
        color: accentColor,
        fontWeight: FontWeight.bold,
        fontSize: 11,
        letterSpacing: 1.2,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(centerX - (textPainter.width / 2), rect.top + 10),
    );

    textPainter.text = TextSpan(
      text: 'VU',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontWeight: FontWeight.w900,
        fontSize: 10,
        letterSpacing: 2.0,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(centerX - (textPainter.width / 2), rect.top + 26),
    );

    // 4. Overload Clip LED
    final isOverload = dbValue >= 0;
    final ledPaint = Paint()
      ..color = isOverload ? Colors.redAccent : const Color(0xFF3A1A1A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(rect.right - 14, rect.top + 14), 3.5, ledPaint);

    if (isOverload) {
      final ledGlow = Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(Offset(rect.right - 14, rect.top + 14), 5.5, ledGlow);
    }

    // 5. Analog Needle with ballistics
    final needleAngle = dbToAngle(dbValue.clamp(-20.0, 3.0));
    final needleTip = Offset(
      centerX + sin(needleAngle) * radius,
      pivotY - cos(needleAngle) * radius,
    );

    final needlePaint = Paint()
      ..color = isOverload ? Colors.redAccent : accentColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX, rect.bottom - 6),
      Offset(needleTip.dx, needleTip.dy.clamp(rect.top + 8, rect.bottom)),
      needlePaint,
    );

    // 6. Pivot Hub screw
    final hubPaint = Paint()..color = const Color(0xFF2C2C2C);
    canvas.drawCircle(Offset(centerX, rect.bottom - 4), 6.0, hubPaint);
    final hubCenterPaint = Paint()..color = accentColor.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(centerX, rect.bottom - 4), 2.5, hubCenterPaint);
  }

  void _paintFluidWave(Canvas canvas, Size size) {
    final t = animationValue * 2 * pi;
    final midY = size.height * 0.52;

    // Back ambient wave
    final backPath = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 8.0) {
      final normX = x / size.width;
      final y =
          midY +
          sin(normX * 3.5 * pi + t) * (size.height * 0.24) +
          cos(normX * 2.0 * pi - t * 0.7) * (size.height * 0.12);
      backPath.lineTo(x, y);
    }
    backPath.lineTo(size.width, size.height);
    backPath.close();

    final backPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0.15),
          accentColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(backPath, backPaint);

    // Front primary wave
    final frontPath = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 6.0) {
      final normX = x / size.width;
      final amp = isPlaying ? 1.0 : 0.3;
      final y =
          midY +
          (sin(normX * 4.5 * pi - t * 1.2) * (size.height * 0.28) +
                  cos(normX * 2.5 * pi + t) * (size.height * 0.14)) *
              amp;
      frontPath.lineTo(x, y);
    }
    frontPath.lineTo(size.width, size.height);
    frontPath.close();

    final frontFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0.45),
          accentColor.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(frontPath, frontFill);

    final frontStroke = Paint()
      ..color = accentColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(frontPath, frontStroke);

    // Secondary crest line
    final crestPath = Path()..moveTo(0, midY);
    for (var x = 0.0; x <= size.width; x += 8.0) {
      final normX = x / size.width;
      final amp = isPlaying ? 1.0 : 0.3;
      final y =
          midY +
          (sin(normX * 5.0 * pi + t * 0.9) * (size.height * 0.2) +
                  cos(normX * 3.0 * pi - t) * (size.height * 0.08)) *
              amp;
      crestPath.lineTo(x, y);
    }
    final crestStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(crestPath, crestStroke);
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.style != style ||
        oldDelegate.isPlaying != isPlaying;
  }
}
