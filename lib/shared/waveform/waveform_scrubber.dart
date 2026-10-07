import 'package:flutter/material.dart';

import 'waveform_data.dart';

class WaveformScrubber extends StatefulWidget {
  final String trackKey;
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final Color? accentColor;
  final Color? unplayedColor;
  final double height;

  const WaveformScrubber({
    super.key,
    required this.trackKey,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.accentColor,
    this.unplayedColor,
    this.height = 48.0,
  });

  @override
  State<WaveformScrubber> createState() => _WaveformScrubberState();
}

class _WaveformScrubberState extends State<WaveformScrubber> {
  bool _isDragging = false;
  double _dragProgress = 0.0;

  double get _currentProgress {
    if (_isDragging) return _dragProgress;
    final totalMs = widget.duration.inMilliseconds;
    if (totalMs <= 0) return 0.0;
    return (widget.position.inMilliseconds / totalMs).clamp(0.0, 1.0);
  }

  void _handleSeek(double localX, double width) {
    if (width <= 0) return;
    final progress = (localX / width).clamp(0.0, 1.0);
    final targetMs = (progress * widget.duration.inMilliseconds).round();
    widget.onSeek(Duration(milliseconds: targetMs));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playedColor = widget.accentColor ?? theme.colorScheme.primary;
    final unplayed =
        widget.unplayedColor ??
        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35);

    final peaks = WaveformGenerator.getWaveformPeaks(widget.trackKey);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            setState(() {
              _isDragging = true;
              _dragProgress = (details.localPosition.dx / width).clamp(
                0.0,
                1.0,
              );
            });
          },
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dragProgress = (details.localPosition.dx / width).clamp(
                0.0,
                1.0,
              );
            });
          },
          onHorizontalDragEnd: (details) {
            _handleSeek(_dragProgress * width, width);
            setState(() {
              _isDragging = false;
            });
          },
          onTapDown: (details) {
            _handleSeek(details.localPosition.dx, width);
          },
          child: SizedBox(
            height: widget.height,
            width: width,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _WaveformPainter(
                  peaks: peaks,
                  progress: _currentProgress,
                  playedColor: playedColor,
                  unplayedColor: unplayed,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> peaks;
  final double progress;
  final Color playedColor;
  final Color unplayedColor;

  _WaveformPainter({
    required this.peaks,
    required this.progress,
    required this.playedColor,
    required this.unplayedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty || size.width <= 0) return;

    final barCount = peaks.length;
    final totalSpacing = size.width * 0.25;
    final barSpacing = totalSpacing / (barCount - 1);
    final barWidth = (size.width - totalSpacing) / barCount;
    final halfHeight = size.height / 2.0;

    final playedPaint = Paint()
      ..color = playedColor
      ..style = PaintingStyle.fill;

    final unplayedPaint = Paint()
      ..color = unplayedColor
      ..style = PaintingStyle.fill;

    for (var i = 0; i < barCount; i++) {
      final x = i * (barWidth + barSpacing);
      final barProgress = (i + 0.5) / barCount;
      final peak = peaks[i];
      final barHeight = peak * size.height * 0.9;
      final top = halfHeight - (barHeight / 2.0);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        Radius.circular(barWidth / 2.0),
      );

      final isPlayed = barProgress <= progress;
      canvas.drawRRect(rrect, isPlayed ? playedPaint : unplayedPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.peaks != peaks ||
        oldDelegate.playedColor != playedColor ||
        oldDelegate.unplayedColor != unplayedColor;
  }
}
