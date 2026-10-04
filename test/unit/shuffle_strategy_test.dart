import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/domain/services/shuffle_strategy.dart';

void main() {
  group('ShuffleStrategy Fisher-Yates', () {
    test('handles empty and single items safely', () {
      expect(ShuffleStrategy.generatePermutation(count: 0), isEmpty);
      expect(ShuffleStrategy.generatePermutation(count: 1), equals([0]));
    });

    test(
      'generates full exhaustion of indices without duplicate or omissions',
      () {
        const count = 100;
        final perm = ShuffleStrategy.generatePermutation(
          count: count,
          seed: 42,
        );

        expect(perm.length, equals(count));
        final set = perm.toSet();
        expect(set.length, equals(count));
        for (var i = 0; i < count; i++) {
          expect(set.contains(i), isTrue);
        }
      },
    );

    test('is strictly deterministic with a fixed seed', () {
      const count = 50;
      final perm1 = ShuffleStrategy.generatePermutation(
        count: count,
        seed: 12345,
      );
      final perm2 = ShuffleStrategy.generatePermutation(
        count: count,
        seed: 12345,
      );

      expect(perm1, equals(perm2));
    });

    test('pins firstIndex to position 0 when provided', () {
      const count = 50;
      const targetIndex = 27;
      final perm = ShuffleStrategy.generatePermutation(
        count: count,
        firstIndex: targetIndex,
        seed: 999,
      );

      expect(perm.first, equals(targetIndex));
      expect(perm.toSet().length, equals(count));
    });
  });
}
