import 'dart:math';

/// Seeded Fisher-Yates shuffler ensuring full exhaustion before repeating
/// and maintaining the active track at index 0 when enabled mid-playback.
class ShuffleStrategy {
  const ShuffleStrategy._();

  /// Generates a shuffled permutation of indices [0..count-1].
  ///
  /// - If [firstIndex] is provided, it is pinned to index 0.
  /// - If [seed] is provided, results are deterministic for testing and queue restore.
  static List<int> generatePermutation({
    required int count,
    int? firstIndex,
    int? seed,
  }) {
    if (count <= 0) return const [];
    if (count == 1) return [0];

    final random = seed != null ? Random(seed) : Random();
    final list = List<int>.generate(count, (i) => i);

    // Fisher-Yates shuffle
    for (var i = count - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }

    // Pin firstIndex at index 0 if requested
    if (firstIndex != null && firstIndex >= 0 && firstIndex < count) {
      final pos = list.indexOf(firstIndex);
      if (pos > 0) {
        list.removeAt(pos);
        list.insert(0, firstIndex);
      }
    }

    return list;
  }
}
