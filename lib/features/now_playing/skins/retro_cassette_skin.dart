import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/theme_tokens.dart';
import '../../../audio/playback_controller.dart';

class RetroCassetteSkin extends StatefulWidget {
  const RetroCassetteSkin({super.key, required this.snapshot});

  final PlaybackSnapshot snapshot;

  @override
  State<RetroCassetteSkin> createState() => _RetroCassetteSkinState();
}

class _RetroCassetteSkinState extends State<RetroCassetteSkin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spoolController;

  @override
  void initState() {
    super.initState();
    _spoolController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (widget.snapshot.isPlaying) {
      _spoolController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RetroCassetteSkin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.snapshot.isPlaying && !_spoolController.isAnimating) {
      _spoolController.repeat();
    } else if (!widget.snapshot.isPlaying && _spoolController.isAnimating) {
      _spoolController.stop();
    }
  }

  @override
  void dispose() {
    _spoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.snapshot.duration.inMilliseconds > 0
        ? (widget.snapshot.position.inMilliseconds /
                  widget.snapshot.duration.inMilliseconds)
              .clamp(0.0, 1.0)
        : 0.0;

    return Center(
      child: AspectRatio(
        aspectRatio: 1.58, // Standard Compact Cassette ratio
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E22), // Cassette shell
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF323238), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Corner Screws
              ..._buildCornerScrews(),

              // Tape Shell Details & Label
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Vintage Paper Label
                    Container(
                      height: 52,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E0D2), // Vintage cream paper
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF8D7B68)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC0392B),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'SIDE A',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.snapshot.title.isNotEmpty
                                      ? widget.snapshot.title
                                      : 'Untitled Track',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF1A1A1A),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                Text(
                                  widget.snapshot.artist.isNotEmpty
                                      ? widget.snapshot.artist
                                      : 'Unknown Artist',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF555555),
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'NORMAL BIAS\nTYPE I / 120µs',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Central Transparent Window with Tape Reels
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C0C0E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF282830)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left Supply Spool
                            _buildTapeReel(
                              radiusRatio: (1.0 - (progress * 0.7)),
                              controller: _spoolController,
                            ),

                            // Middle Tape Window Ruler / Head Cutout
                            Container(
                              width: 38,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF161618),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: const Center(
                                child: Text(
                                  '100 · 50 · 0',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 6,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            // Right Take-up Spool
                            _buildTapeReel(
                              radiusRatio: (0.3 + (progress * 0.7)),
                              controller: _spoolController,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Bottom Tape Head Housing
                    Container(
                      height: 14,
                      width: 140,
                      decoration: const BoxDecoration(
                        color: Color(0xFF282830),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          4,
                          (_) => Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF121214),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTapeReel({
    required double radiusRatio,
    required AnimationController controller,
  }) {
    final spoolRadius = 24.0 * radiusRatio.clamp(0.4, 1.0);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final angle = controller.value * 2.0 * math.pi;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Dark Brown Magnetic Tape Pack
              Container(
                width: spoolRadius * 2,
                height: spoolRadius * 2,
                decoration: const BoxDecoration(
                  color: Color(0xFF382319), // Magnetic oxide brown
                  shape: BoxShape.circle,
                ),
              ),
              // White Toothed Spool Hub
              Transform.rotate(
                angle: angle,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFBBBBBB)),
                  ),
                  child: CustomPaint(painter: _ReelToothedHubPainter()),
                ),
              ),
              // Center Spindle Hole
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E22),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildCornerScrews() {
    return [
      Positioned(top: 8, left: 8, child: _buildScrew()),
      Positioned(top: 8, right: 8, child: _buildScrew()),
      Positioned(bottom: 8, left: 8, child: _buildScrew()),
      Positioned(bottom: 8, right: 8, child: _buildScrew()),
    ];
  }

  Widget _buildScrew() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFF555560),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(width: 5, height: 1.2, color: const Color(0xFF222226)),
      ),
    );
  }
}

class _ReelToothedHubPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFF777777)
      ..style = PaintingStyle.fill;

    // 6-tooth gear notches
    for (var i = 0; i < 6; i++) {
      final angle = (i * math.pi) / 3;
      final x = center.dx + math.cos(angle) * 11;
      final y = center.dy + math.sin(angle) * 11;
      canvas.drawCircle(Offset(x, y), 2.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
