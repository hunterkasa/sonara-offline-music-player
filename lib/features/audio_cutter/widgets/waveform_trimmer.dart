import 'dart:math' as math;

import 'package:flutter/material.dart';

class WaveformTrimmer extends StatefulWidget {
  final int totalDurationMs;
  final int startMs;
  final int endMs;
  final int currentPositionMs;
  final void Function(int startMs, int endMs) onRangeChanged;
  final ValueChanged<int>? onSeek;
  final List<double>? waveformPeaks;

  const WaveformTrimmer({
    super.key,
    required this.totalDurationMs,
    required this.startMs,
    required this.endMs,
    required this.currentPositionMs,
    required this.onRangeChanged,
    this.onSeek,
    this.waveformPeaks,
  });

  @override
  State<WaveformTrimmer> createState() => _WaveformTrimmerState();
}

enum _DragTarget { none, startHandle, endHandle, window }

class _WaveformTrimmerState extends State<WaveformTrimmer> {
  _DragTarget _activeDrag = _DragTarget.none;
  double _dragStartDx = 0;
  int _dragInitialStartMs = 0;
  int _dragInitialEndMs = 0;

  static const double _handleTouchRadius = 24.0;
  static const int _minDurationMs = 1000; // Minimum 1 second clip

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final duration = math.max(1, widget.totalDurationMs);
        final startX = (widget.startMs / duration * width).clamp(0.0, width);
        final endX = (widget.endMs / duration * width).clamp(0.0, width);
        final playheadX = (widget.currentPositionMs / duration * width).clamp(
          0.0,
          width,
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            final x = details.localPosition.dx;
            _dragStartDx = x;
            _dragInitialStartMs = widget.startMs;
            _dragInitialEndMs = widget.endMs;

            if ((x - startX).abs() <= _handleTouchRadius) {
              setState(() => _activeDrag = _DragTarget.startHandle);
            } else if ((x - endX).abs() <= _handleTouchRadius) {
              setState(() => _activeDrag = _DragTarget.endHandle);
            } else if (x > startX && x < endX) {
              setState(() => _activeDrag = _DragTarget.window);
            } else {
              _activeDrag = _DragTarget.none;
              // Tap outside seeks
              final tappedMs = (x / width * duration)
                  .clamp(0.0, duration.toDouble())
                  .toInt();
              widget.onSeek?.call(tappedMs);
            }
          },
          onHorizontalDragUpdate: (details) {
            final dx = details.localPosition.dx - _dragStartDx;
            final msDelta = (dx / width * duration).toInt();

            switch (_activeDrag) {
              case _DragTarget.startHandle:
                final newStart = (_dragInitialStartMs + msDelta).clamp(
                  0,
                  widget.endMs - _minDurationMs,
                );
                widget.onRangeChanged(newStart, widget.endMs);
                break;
              case _DragTarget.endHandle:
                final newEnd = (_dragInitialEndMs + msDelta).clamp(
                  widget.startMs + _minDurationMs,
                  duration,
                );
                widget.onRangeChanged(widget.startMs, newEnd);
                break;
              case _DragTarget.window:
                final windowLen = _dragInitialEndMs - _dragInitialStartMs;
                var newStart = _dragInitialStartMs + msDelta;
                var newEnd = newStart + windowLen;
                if (newStart < 0) {
                  newStart = 0;
                  newEnd = windowLen;
                } else if (newEnd > duration) {
                  newEnd = duration;
                  newStart = duration - windowLen;
                }
                widget.onRangeChanged(newStart, newEnd);
                break;
              case _DragTarget.none:
                break;
            }
          },
          onHorizontalDragEnd: (_) {
            setState(() => _activeDrag = _DragTarget.none);
          },
          onTapUp: (details) {
            final x = details.localPosition.dx;
            final tappedMs = (x / width * duration)
                .clamp(0.0, duration.toDouble())
                .toInt();
            widget.onSeek?.call(tappedMs);
          },
          child: CustomPaint(
            size: Size(width, height),
            painter: _TrimmerPainter(
              startX: startX,
              endX: endX,
              playheadX: playheadX,
              primaryColor: primaryColor,
              surfaceColor: theme.colorScheme.surface,
              onSurfaceColor: theme.colorScheme.onSurface,
              peaks: widget.waveformPeaks,
            ),
          ),
        );
      },
    );
  }
}

class _TrimmerPainter extends CustomPainter {
  final double startX;
  final double endX;
  final double playheadX;
  final Color primaryColor;
  final Color surfaceColor;
  final Color onSurfaceColor;
  final List<double>? peaks;

  _TrimmerPainter({
    required this.startX,
    required this.endX,
    required this.playheadX,
    required this.primaryColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
    this.peaks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    // 1. Draw background waveform bars
    const barCount = 70;
    final barSpacing = width / barCount;
    final barWidth = barSpacing * 0.65;

    final unselectedBarPaint = Paint()
      ..color = onSurfaceColor.withValues(alpha: 0.2)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    final selectedBarPaint = Paint()
      ..color = primaryColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    for (var i = 0; i < barCount; i++) {
      final x = i * barSpacing + barWidth / 2;
      double amplitude;
      if (peaks != null && peaks!.isNotEmpty) {
        final peakIndex = (i / barCount * peaks!.length).floor().clamp(
          0,
          peaks!.length - 1,
        );
        amplitude = peaks![peakIndex];
      } else {
        // Deterministic sinusoidal wave pattern
        final t = i / barCount;
        amplitude =
            (math.sin(t * math.pi * 6).abs() * 0.6 +
                    math.cos(t * math.pi * 14).abs() * 0.3 +
                    0.15)
                .clamp(0.1, 1.0);
      }

      final barH = (amplitude * (height * 0.72)).clamp(4.0, height * 0.85);
      final isInside = x >= startX && x <= endX;
      canvas.drawLine(
        Offset(x, centerY - barH / 2),
        Offset(x, centerY + barH / 2),
        isInside ? selectedBarPaint : unselectedBarPaint,
      );
    }

    // 2. Dim outside non-selected areas
    final dimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    if (startX > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, startX, height),
          const Radius.circular(8),
        ),
        dimPaint,
      );
    }
    if (endX < width) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(endX, 0, width - endX, height),
          const Radius.circular(8),
        ),
        dimPaint,
      );
    }

    // 3. Selection border box
    final borderPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final selectionRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(startX, 0, endX, height),
      const Radius.circular(8),
    );
    canvas.drawRRect(selectionRect, borderPaint);

    // 4. Handles: Left (Start) & Right (End)
    _drawHandle(canvas, startX, height, isStart: true);
    _drawHandle(canvas, endX, height, isStart: false);

    // 5. Playhead indicator line
    if (playheadX >= startX && playheadX <= endX) {
      final playheadPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(playheadX, 0),
        Offset(playheadX, height),
        playheadPaint,
      );

      final playheadDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(playheadX, centerY), 4.0, playheadDot);
    }
  }

  void _drawHandle(
    Canvas canvas,
    double x,
    double height, {
    required bool isStart,
  }) {
    final handlePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // Handle vertical pill
    const handleWidth = 16.0;
    const handleHeight = 36.0;
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, height / 2),
        width: handleWidth,
        height: handleHeight,
      ),
      const Radius.circular(8),
    );

    // Subtle drop shadow
    canvas.drawShadow(Path()..addRRect(handleRect), Colors.black, 4.0, false);

    canvas.drawRRect(handleRect, handlePaint);

    // Inner grip marks
    final gripPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final centerY = height / 2;
    canvas.drawLine(
      Offset(x - 2, centerY - 8),
      Offset(x - 2, centerY + 8),
      gripPaint,
    );
    canvas.drawLine(
      Offset(x + 2, centerY - 8),
      Offset(x + 2, centerY + 8),
      gripPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TrimmerPainter oldDelegate) {
    return oldDelegate.startX != startX ||
        oldDelegate.endX != endX ||
        oldDelegate.playheadX != playheadX ||
        oldDelegate.primaryColor != primaryColor;
  }
}
