import 'dart:io';
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

  test('never regenerates keys already in the exclude set', () {
    final random = Random(7);
    final existing = generator.generateUnlockKeys(20, random: random);
    final more = generator.generateUnlockKeys(
      20,
      random: random,
      exclude: existing.toSet(),
    );

    expect(more, hasLength(20));
    expect(more.toSet().intersection(existing.toSet()), isEmpty);
  });

  test('dedupes rows by key and keyId keeping the first occurrence', () {
    final first = generator.KeyRow(
      '1111111111111111',
      'YING-key-one',
      '2026-01-01T00:00:00Z',
    );
    final sameKey = generator.KeyRow(
      '2222222222222222',
      'YING-key-one',
      '2026-01-02T00:00:00Z',
    );
    final sameId = generator.KeyRow(
      '1111111111111111',
      'YING-key-two',
      '2026-01-03T00:00:00Z',
    );
    final third = generator.KeyRow(
      '3333333333333333',
      'YING-key-three',
      '2026-01-04T00:00:00Z',
    );

    final result = generator.dedupeKeyRows([first, sameKey, sameId, third]);

    expect(result, hasLength(2));
    expect(result.first, same(first));
    expect(result.last, same(third));
  });

  test('newKeyRows keeps only rows absent from existing rows', () {
    final existing = [
      generator.KeyRow(
        '1111111111111111',
        'YING-existing-one',
        '2026-01-01T00:00:00Z',
      ),
      generator.KeyRow(
        '2222222222222222',
        'YING-existing-two',
        '2026-01-02T00:00:00Z',
      ),
    ];
    final incoming = [
      generator.KeyRow(
        '3333333333333333',
        'YING-new-one',
        '2026-01-03T00:00:00Z',
      ),
      generator.KeyRow(
        '1111111111111111',
        'YING-new-two',
        '2026-01-04T00:00:00Z',
      ),
      generator.KeyRow(
        '4444444444444444',
        'YING-existing-one',
        '2026-01-05T00:00:00Z',
      ),
    ];

    final result = generator.newKeyRows(incoming, existing);

    expect(result, hasLength(1));
    expect(result.single.keyId, '3333333333333333');
  });

  test('readKeyRows skips marker lines and the header', () {
    final dir = Directory.systemTemp.createTempSync(
      'generate_unlock_keys_test',
    );
    final file = File('${dir.path}/keys.csv')
      ..writeAsStringSync(
        '# batch: 2026-08-11T00:00:00Z keys=1\n'
        'keyId,key,createdAt\n'
        'aaa1111111111111,YING-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa,2026-08-11T00:00:00Z\n',
      );

    final rows = generator.readKeyRows(file);

    expect(rows, hasLength(1));
    expect(rows.single.keyId, 'aaa1111111111111');
    expect(rows.single.key, startsWith('YING-'));
  });
}
