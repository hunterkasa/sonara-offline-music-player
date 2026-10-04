import 'package:flutter/material.dart';

/// Sonara 4-pt grid spacing tokens and design geometry constants.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double s = 12.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border radius tokens per UX spec.
class AppRadii {
  const AppRadii._();

  static const double artwork = 14.0;
  static const double card = 12.0;
  static const double sheet = 24.0;
  static const double pill = 999.0;

  static const BorderRadius artworkRadius = BorderRadius.all(
    Radius.circular(artwork),
  );
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius sheetRadius = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );
}

/// Animation motion curve and duration tokens per UX spec:
/// 150/250/400 ms durations with emphasized easing.
class AppMotion {
  const AppMotion._();

  static const Duration quick = Duration(milliseconds: 150);
  static const Duration regular = Duration(milliseconds: 250);
  static const Duration emphasized = Duration(milliseconds: 400);

  static const Curve easeIn = Curves.easeInCubic;
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve emphasizedEasing = Curves.easeInOutCubicEmphasized;
}
