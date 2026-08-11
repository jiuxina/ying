import 'dart:io';
import 'dart:math';

/// 生成或合并爱发电自动发货用的赞助解锁密钥库存。
///
/// 用法：
///   dart run tools/generate_unlock_keys.dart [数量] [输出文件] [--append]
///   dart run tools/generate_unlock_keys.dart --source <密钥文件> [输出文件] [--append]
///
/// 默认生成 100 把，输出 keys.csv；--append 时追加写入并去重；
/// --source 时不生成新密钥，而是读取已有密钥文件并写入输出。
/// 每次写入的批次都以 `# batch: ...` 标记行开头。
void main(List<String> args) {
  final append = args.contains('--append');
  String? source;
  final positional = <String>[];
  for (var i = 0; i < args.length; i += 1) {
    final arg = args[i];
    if (arg == '--append') {
      continue;
    } else if (arg == '--source') {
      if (i + 1 >= args.length) {
        stderr.writeln('--source 需要指定密钥 CSV 文件');
        exitCode = 1;
        return;
      }
      source = args[i + 1];
      i += 1;
    } else {
      positional.add(arg);
    }
  }

  final String output;
  final int count;
  if (source != null) {
    output = positional.isNotEmpty ? positional[0] : 'keys.csv';
    count = 0;
  } else {
    count = positional.isNotEmpty ? int.tryParse(positional[0]) ?? 100 : 100;
    output = positional.length > 1 ? positional[1] : 'keys.csv';
  }
  if (source == null && (count <= 0 || count > 100000)) {
    stderr.writeln('数量需在 1..100000 之间');
    exitCode = 1;
    return;
  }

  final now = DateTime.now().toUtc().toIso8601String();
  final outputFile = File(output);
  final existingRows = append && outputFile.existsSync()
      ? readKeyRows(outputFile)
      : <KeyRow>[];
  final existingKeys = existingRows.map((row) => row.key).toSet();
  final existingIds = existingRows.map((row) => row.keyId).toSet();

  final List<KeyRow> incoming;
  if (source != null) {
    final sourceFile = File(source);
    if (!sourceFile.existsSync()) {
      stderr.writeln('源文件不存在：$source');
      exitCode = 1;
      return;
    }
    incoming = readKeyRows(sourceFile);
  } else {
    final rng = Random.secure();
    incoming = _generateRows(count, existingKeys, existingIds, now, rng);
  }

  final newRows = newKeyRows(incoming, existingRows);

  if (newRows.isEmpty) {
    stdout.writeln('没有新增密钥（全部与 $output 已有密钥重复）');
    return;
  }

  final marker =
      '# batch: $now keys=${newRows.length}${source != null ? ' source=$source' : ''}';
  final rowsText = newRows.map((row) => row.toCsv()).join('\n');
  if (append &&
      outputFile.existsSync() &&
      outputFile.readAsStringSync().trim().isNotEmpty) {
    final existing = outputFile.readAsStringSync().trimRight();
    outputFile.writeAsStringSync(
      '$existing\n$marker\n$rowsText\n',
      flush: true,
    );
  } else {
    outputFile.writeAsStringSync(
      '$marker\nkeyId,key,createdAt\n$rowsText\n',
      flush: true,
    );
  }
  final verb = source != null ? '已合并' : '已生成';
  stdout.writeln('$verb ${newRows.length} 把密钥：$output');
}

/// 单把密钥记录，对应 CSV 中的一行。
class KeyRow {
  const KeyRow(this.keyId, this.key, this.createdAt);

  final String keyId;
  final String key;
  final String createdAt;

  String toCsv() => '$keyId,$key,$createdAt';
}

/// 解析密钥 CSV，跳过空行、`#` 标记行与表头。
List<KeyRow> readKeyRows(File file) {
  final rows = <KeyRow>[];
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#') || line.startsWith('keyId,')) {
      continue;
    }
    final parts = line.split(',');
    if (parts.length < 3) continue;
    rows.add(KeyRow(parts[0].trim(), parts[1].trim(), parts[2].trim()));
  }
  return rows;
}

/// 按 keyId 与 key 去重，保留首次出现的记录。
List<KeyRow> dedupeKeyRows(List<KeyRow> rows) {
  final seenKeys = <String>{};
  final seenIds = <String>{};
  final result = <KeyRow>[];
  for (final row in rows) {
    if (seenKeys.add(row.key) && seenIds.add(row.keyId)) {
      result.add(row);
    }
  }
  return result;
}

/// 生成 [count] 把 `YING-` + 40 位 base62 的密钥，并与 [exclude] 去重。
List<String> generateUnlockKeys(
  int count, {
  Random? random,
  Set<String>? exclude,
}) {
  final rng = random ?? Random.secure();
  final seen = exclude == null ? <String>{} : Set<String>.of(exclude);
  final keys = <String>[];
  var attempts = 0;
  while (keys.length < count && attempts < count * 100 + 1000) {
    attempts += 1;
    final key = 'YING-${_base62(rng, 40)}';
    if (seen.add(key)) {
      keys.add(key);
    }
  }
  return keys;
}

List<KeyRow> _generateRows(
  int count,
  Set<String> existingKeys,
  Set<String> existingIds,
  String createdAt,
  Random rng,
) {
  final usedIds = Set<String>.of(existingIds);
  return generateUnlockKeys(
    count,
    random: rng,
    exclude: existingKeys,
  ).map((key) => KeyRow(_uniqueHex(rng, usedIds), key, createdAt)).toList();
}

/// 返回 [incoming] 中相对 [existing] 真正新增的密钥，并保持 keyId / key 唯一。
List<KeyRow> newKeyRows(List<KeyRow> incoming, List<KeyRow> existing) {
  final existingKeys = existing.map((row) => row.key).toSet();
  final existingIds = existing.map((row) => row.keyId).toSet();
  return dedupeKeyRows(incoming)
      .where(
        (row) =>
            !existingKeys.contains(row.key) && !existingIds.contains(row.keyId),
      )
      .toList();
}

String _uniqueHex(Random random, Set<String> used) {
  while (true) {
    final id = _hex(random, 8);
    if (used.add(id)) return id;
  }
}

String _base62(Random random, int length) {
  const alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  return String.fromCharCodes(
    List.generate(
      length,
      (_) => alphabet.codeUnitAt(random.nextInt(alphabet.length)),
    ),
  );
}

String _hex(Random random, int bytes) {
  final buffer = StringBuffer();
  for (var i = 0; i < bytes; i += 1) {
    buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}
