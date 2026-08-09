import 'dart:io';
import 'dart:math';

/// 生成爱发电自动发货用的赞助解锁密钥库存。
///
/// 用法：dart run tools/generate_unlock_keys.dart [数量] [输出文件]
/// 默认生成 100 把，输出 keys.csv。
void main(List<String> args) {
  final count = args.isNotEmpty ? int.tryParse(args[0]) ?? 100 : 100;
  final output = args.length > 1 ? args[1] : 'keys.csv';
  if (count <= 0 || count > 100000) {
    stderr.writeln('数量需在 1..100000 之间');
    exitCode = 1;
    return;
  }

  final random = Random.secure();
  final rows = <String>['keyId,key,createdAt'];
  final now = DateTime.now().toUtc().toIso8601String();
  for (var i = 0; i < count; i += 1) {
    final keyId = _hex(random, 8);
    final key = 'YING-${_base62(random, 40)}';
    rows.add('$keyId,$key,$now');
  }

  File(output).writeAsStringSync('${rows.join('\n')}\n', flush: true);
  stdout.writeln('已生成 $count 把密钥：$output');
}

String _base62(Random random, int length) {
  const alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  return String.fromCharCodes(
    List.generate(length, (_) => alphabet.codeUnitAt(random.nextInt(alphabet.length))),
  );
}

String _hex(Random random, int bytes) {
  final buffer = StringBuffer();
  for (var i = 0; i < bytes; i += 1) {
    buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}
