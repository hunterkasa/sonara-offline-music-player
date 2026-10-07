import 'package:flutter/material.dart';

class SonaraBrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const SonaraBrandLogo({
    super.key,
    this.size = 32.0,
    this.showText = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = color ?? theme.colorScheme.primary;
    final secondary = theme.colorScheme.tertiary;

    final emblem = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SonaraLogoPainter(
          primaryColor: primary,
          secondaryColor: secondary,
        ),
      ),
    );

    if (!showText) return emblem;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        emblem,
        const SizedBox(width: 10),
        Text(
          'Sonara',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _SonaraLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  _SonaraLogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw background rounded squircle badge
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.28),
    );
    final badgePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor.withValues(alpha: 0.22),
          secondaryColor.withValues(alpha: 0.12),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(badgeRect, badgePaint);

    final borderPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor.withValues(alpha: 0.6),
          secondaryColor.withValues(alpha: 0.3),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04;
    canvas.drawRRect(badgeRect, borderPaint);

    // Draw 4 harmonic acoustic soundwave bars
    final barPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [primaryColor, secondaryColor],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final barWidth = w * 0.11;
    final barRadius = Radius.circular(barWidth / 2);
    final spacing = w * 0.08;
    final startX = (w - (4 * barWidth + 3 * spacing)) / 2;

    // Bar heights normalized: 0.45, 0.75, 0.60, 0.35
    final heights = [h * 0.38, h * 0.68, h * 0.54, h * 0.32];

    for (var i = 0; i < 4; i++) {
      final barH = heights[i];
      final x = startX + i * (barWidth + spacing);
      final y = (h - barH) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, barWidth, barH), barRadius),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SonaraLogoPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
