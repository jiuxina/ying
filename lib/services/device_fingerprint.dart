import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _deviceSalt = 'ying-sponsor-v1';

/// 生成稳定的设备指纹：Android 用 ANDROID_ID 加盐哈希，
/// 其他平台回退到本地持久化的随机 ID。
class DeviceFingerprint {
  static const _channel = MethodChannel('com.jiuxina.ying/device');
  static const _fallbackKey = 'device_fallback_id';

  Future<String> hash() async {
    return hashDeviceId(await _rawId());
  }

  Future<String> _rawId() async {
    try {
      final id = await _channel.invokeMethod<String>('androidId');
      if (id != null && id.trim().isNotEmpty) return id.trim();
    } catch (_) {
      // 非 Android 平台或通道不可用时走本地随机 ID。
    }
    final preferences = await SharedPreferences.getInstance();
    var id = preferences.getString(_fallbackKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await preferences.setString(_fallbackKey, id);
    }
    return id;
  }
}

String hashDeviceId(String rawId) {
  return sha256.convert(utf8.encode('$_deviceSalt:$rawId')).toString();
}
