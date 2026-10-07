import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../audio/playback_controller.dart';
import '../../../shared/artwork/artwork_widget.dart';

class SpinningVinylSkin extends StatefulWidget {
  const SpinningVinylSkin({
    super.key,
    required this.snapshot,
    this.artworkKey,
    this.filePath,
    required this.title,
  });

  final PlaybackSnapshot snapshot;
  final String? artworkKey;
  final String? filePath;
  final String title;

  @override
  State<SpinningVinylSkin> createState() => _SpinningVinylSkinState();
}

class _SpinningVinylSkinState extends State<SpinningVinylSkin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    // 33 RPM ~ 1.8 seconds per revolution
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1818),
    );

    if (widget.snapshot.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SpinningVinylSkin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.snapshot.isPlaying && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!widget.snapshot.isPlaying && _rotationController.isAnimating) {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final discSize = size * 0.88;

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Turntable Platter Shadow
                Container(
                  width: discSize + 16,
                  height: discSize + 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 28,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),

                // Rotating Vinyl Disc
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    final angle = _rotationController.value * 2.0 * math.pi;
                    return Transform.rotate(angle: angle, child: child);
                  },
                  child: CustomPaint(
                    size: Size(discSize, discSize),
                    painter: const _VinylGroovePainter(),
                    child: SizedBox(
                      width: discSize,
                      height: discSize,
                      child: Center(
                        child: ClipOval(
                          child: SizedBox(
                            width: discSize * 0.40,
                            height: discSize * 0.40,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ArtworkWidget(
                                  artworkKey: widget.artworkKey,
                                  filePath: widget.filePath,
                                  title: widget.title,
                                  size: discSize * 0.40,
                                  borderRadius: 0,
                                ),
                                // Spindle Hole
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Animated Tonearm
                Positioned(
                  top: 0,
                  right: 12,
                  child: AnimatedRotation(
                    turns: widget.snapshot.isPlaying ? 0.04 : 0.0,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topRight,
                    child: const _TonearmWidget(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VinylGroovePainter extends CustomPainter {
  const _VinylGroovePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Vinyl base black disc
    final discPaint = Paint()
      ..color = const Color(0xFF141416)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, discPaint);

    // Subtle vinyl shine gradient
    final shinePaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, shinePaint);

    // Micro grooves
    final groovePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var r = radius * 0.44; r < radius - 4; r += 5.5) {
      canvas.drawCircle(center, r, groovePaint);
    }

    // Outer vinyl edge ring
    final edgePaint = Paint()
      ..color = const Color(0xFF28282D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius - 2, edgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TonearmWidget extends StatelessWidget {
  const _TonearmWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 140,
      child: CustomPaint(painter: _TonearmPainter()),
    );
  }
}

class _TonearmPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Pivot base
    final pivotPaint = Paint()
      ..color = const Color(0xFF757575)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width - 15, 15), 12, pivotPaint);
    canvas.drawCircle(
      Offset(size.width - 15, 15),
      6,
      Paint()..color = const Color(0xFFBDBDBD),
    );

    // Arm line
    final armPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width - 15, 15)
      ..lineTo(size.width - 25, 80)
      ..lineTo(10, size.height - 15);
    canvas.drawPath(path, armPaint);

    // Cartridge / Headshell
    final headPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(10, size.height - 15),
          width: 14,
          height: 22,
        ),
        const Radius.circular(3),
      ),
      headPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
