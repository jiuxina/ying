import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../tools/generate_unlock_keys.dart' as generator;

void main() {
  test('generates prefixed unique keys with the configured length', () {
    final random = Random(42);
    final keys = generator.generateUnlockKeys(50, random: random);

    expect(keys, hasLength(50));
    expect(keys.toSet(), hasLength(50));
    for (final key in keys) {
      expect(key, startsWith('YING-'));
      expect(key, hasLength('YING-'.length + 40));
      expect(RegExp(r'^YING-[A-Za-z0-9]{40}$').hasMatch(key), isTrue);
    }
  });
}
