import 'dart:math';

import 'package:flutter/material.dart';

enum VisualizerStyle { spectrum, vuMeter, fluidWave }

class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double speed;
  final String? trackKey;
  final List<double>? bandGains;
  final double bassBoost;
  final VisualizerStyle style;
  final Color? accentColor;
  final double height;

  const AudioVisualizer({
    super.key,
    required this.isPlaying,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.trackKey,
    this.bandGains,
    this.bassBoost = 0.0,
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
  final List<double> _bandValues = List.filled(24, 0.08);
  final List<double> _peakValues = List.filled(24, 0.10);

  // VU meter needle values (dB: -20 to +3)
  double _leftVu = -20.0;
  double _rightVu = -20.0;

  double _audioPhaseSec = 0.0;
  int _lastTickMs = 0;

  @override
  void initState() {
    super.initState();
    _audioPhaseSec = widget.position.inMilliseconds / 1000.0;
    _lastTickMs = DateTime.now().millisecondsSinceEpoch;
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
    // Re-sync audio phase on seeking or track switch
    final posDiffMs =
        (widget.position.inMilliseconds - oldWidget.position.inMilliseconds)
            .abs();
    if (posDiffMs > 1000 || widget.trackKey != oldWidget.trackKey) {
      _audioPhaseSec = widget.position.inMilliseconds / 1000.0;
    }
  }

  void _tick() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = ((now - _lastTickMs) / 1000.0).clamp(0.005, 0.05);
    _lastTickMs = now;

    if (widget.isPlaying) {
      _audioPhaseSec += dt * widget.speed;

      // Track-deterministic tempo (116 - 132 BPM)
      final trackHash = widget.trackKey?.hashCode ?? 42;
      final bpm = 116.0 + (trackHash.abs() % 17);
      final beatFreq = bpm / 60.0; // beats per second

      // Beat phases:
      // Quarter-note beat (kick on downbeats 0.0 and 0.5)
      final beatPhase = (_audioPhaseSec * beatFreq) % 1.0;
      // Exponential kick decay (punchy attack, smooth release)
      final kickTransient = exp(-12.0 * beatPhase);

      // Snare on off-beat (0.5)
      final snarePhase = (_audioPhaseSec * beatFreq + 0.5) % 1.0;
      final snareTransient = exp(-16.0 * snarePhase);

      // Hi-hat flutter (16th notes)
      final hatPhase = (_audioPhaseSec * beatFreq * 4.0) % 1.0;
      final hatTransient = exp(-24.0 * hatPhase);

      // Equalizer multipliers (5 bands mapped across 24 bands)
      final gains = widget.bandGains ?? const [0.0, 0.0, 0.0, 0.0, 0.0];
      final bassBoostScale = 1.0 + (widget.bassBoost * 1.4);

      for (var i = 0; i < _bandValues.length; i++) {
        // Map 24 bands to 5 EQ bands:
        // 0..3: sub-bass, 4..8: bass/low-mid, 9..14: midrange, 15..19: presence, 20..23: brilliance
        final eqIdx = (i / 4.8).floor().clamp(0, gains.length - 1);
        final eqDb = gains.length > eqIdx ? gains[eqIdx] : 0.0;
        final eqScale = pow(10.0, eqDb / 20.0).toDouble().clamp(0.2, 2.5);

        // Harmonic oscillation based on audio phase and band index
        final freqHarmonic = sin(
          _audioPhaseSec * (2.2 + (i * 0.45) * widget.speed) +
              (i * 0.75) +
              (trackHash % 7),
        );
        final subHarmonic = cos(
          _audioPhaseSec * (1.1 + (i * 0.22)) + (i * 0.35),
        );

        // Rhythmic transient injection by frequency band:
        // Low bands (0..6) react heavily to kick drum transient and bass boost
        // Mid bands (7..14) react to snare transient and melody
        // High bands (15..23) react to hi-hat shimmer and treble
        double transientContribution = 0.0;
        if (i < 7) {
          final lowWeight = (1.0 - (i / 7.0));
          transientContribution =
              kickTransient * 0.65 * lowWeight * bassBoostScale;
        } else if (i < 15) {
          final midWeight = 1.0 - ((i - 11).abs() / 4.0);
          transientContribution = snareTransient * 0.45 * midWeight;
        } else {
          final highWeight = ((i - 14) / 9.0);
          transientContribution = hatTransient * 0.35 * highWeight;
        }

        final noise = (_rng.nextDouble() - 0.5) * 0.12;
        final rawTarget =
            ((freqHarmonic * 0.28 + subHarmonic * 0.18 + 0.42) +
                transientContribution +
                noise) *
            eqScale;
        final target = rawTarget.clamp(0.08, 0.98);

        // Smooth interpolation for fluid responsive movement
        _bandValues[i] = _bandValues[i] * 0.48 + target * 0.52;

        if (_bandValues[i] > _peakValues[i]) {
          _peakValues[i] = _bandValues[i];
        } else {
          _peakValues[i] = max(0.08, _peakValues[i] - 0.016);
        }
      }

      // VU meters (-20 dB to +3 dB) with realistic analog galvanometer ballistics
      // Kick impact and overall audio RMS power
      final audioEnergy =
          (kickTransient * 0.7 + snareTransient * 0.3) * bassBoostScale;
      final stereoFlutter = sin(_audioPhaseSec * 3.4) * 1.8;

      // Base level is ~ -12 dB, peaking into 0 to +2 dB on heavy transients
      final leftTargetDb =
          (-12.0 +
                  (audioEnergy * 14.0) +
                  stereoFlutter +
                  (_rng.nextDouble() * 1.5))
              .clamp(-20.0, 3.0);
      final rightTargetDb =
          (-12.0 +
                  (audioEnergy * 14.0) -
                  stereoFlutter +
                  (_rng.nextDouble() * 1.5))
              .clamp(-20.0, 3.0);

      // Fast attack (needle rises instantly on transients), smooth mechanical release
      if (leftTargetDb > _leftVu) {
        _leftVu = _leftVu * 0.25 + leftTargetDb * 0.75; // Fast attack (~15ms)
      } else {
        _leftVu =
            _leftVu * 0.86 +
            leftTargetDb * 0.14; // Natural mechanical decay (~300ms)
      }

      if (rightTargetDb > _rightVu) {
        _rightVu = _rightVu * 0.25 + rightTargetDb * 0.75;
      } else {
        _rightVu = _rightVu * 0.86 + rightTargetDb * 0.14;
      }
    } else {
      // Smooth decay towards resting floor when paused
      for (var i = 0; i < _bandValues.length; i++) {
        _bandValues[i] = max(0.05, _bandValues[i] * 0.90);
        _peakValues[i] = max(0.05, _peakValues[i] * 0.92);
      }
      _leftVu = max(-20.0, _leftVu - 0.8);
      _rightVu = max(-20.0, _rightVu - 0.8);
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
            audioPhaseSec: _audioPhaseSec,
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
  final double audioPhaseSec;

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
    required this.audioPhaseSec,
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
    final t = isPlaying ? (audioPhaseSec * 2.8) : (animationValue * 2 * pi);
    final bassEnergy = bands.isNotEmpty ? bands[2] : 0.2;
    final amp = isPlaying ? (0.55 + bassEnergy * 0.75) : 0.18;
    final midY = size.height * 0.52;

    // Back ambient wave
    final backPath = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 8.0) {
      final normX = x / size.width;
      final y =
          midY +
          sin(normX * 3.5 * pi + t) * (size.height * 0.24) * amp +
          cos(normX * 2.0 * pi - t * 0.7) * (size.height * 0.12) * amp;
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
        oldDelegate.audioPhaseSec != audioPhaseSec ||
        oldDelegate.style != style ||
        oldDelegate.isPlaying != isPlaying;
  }
}
