import 'package:flutter/services.dart';

const _channel = MethodChannel('ying/device');

/// 返回 Android 支持的 ABI 列表；非 Android 或通道不可用时为空列表。
Future<List<String>> deviceAbis() async {
  try {
    final result = await _channel.invokeMethod<List<dynamic>>('abis');
    if (result != null && result.isNotEmpty) {
      return result.whereType<String>().toList();
    }
  } catch (_) {
    // 非 Android 平台或调试环境没有该通道，回退为按通用包选择。
  }
  return const [];
}
