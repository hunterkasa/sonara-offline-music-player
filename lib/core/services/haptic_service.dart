import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hapticsEnabledProvider = StateProvider<bool>((ref) => true);

class HapticService {
  HapticService(this.ref);

  final Ref ref;

  bool get _isEnabled => ref.read(hapticsEnabledProvider);

  void light() {
    if (!_isEnabled) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  void medium() {
    if (!_isEnabled) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  void heavy() {
    if (!_isEnabled) return;
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  void selection() {
    if (!_isEnabled) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }
}

final hapticServiceProvider = Provider<HapticService>((ref) {
  return HapticService(ref);
});
