import 'package:flutter/services.dart';

class PermissionOpenResult {
  const PermissionOpenResult({required this.opened, required this.fallback});

  final bool opened;
  final bool fallback;
}

/// 系统后台权限引导：电池优化、自启动与应用详情设置。
/// 桌面端或测试环境没有原生实现时返回安全默认值，不打断界面。
class PermissionService {
  PermissionService._();

  static final instance = PermissionService._();
  static const _channel = MethodChannel('ying/permissions');

  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      return await _channel.invokeMethod<bool>(
            'isIgnoringBatteryOptimizations',
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<PermissionOpenResult> requestIgnoreBatteryOptimizations() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
            'requestIgnoreBatteryOptimizations',
          ) ??
          const <String, dynamic>{};
      return PermissionOpenResult(
        opened: result['opened'] == true,
        fallback: result['fallback'] == true,
      );
    } on MissingPluginException {
      return const PermissionOpenResult(opened: false, fallback: false);
    } catch (_) {
      return const PermissionOpenResult(opened: false, fallback: false);
    }
  }

  Future<bool> isAutoStartSupported() async {
    try {
      return await _channel.invokeMethod<bool>('autoStartSupported') ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<PermissionOpenResult> openAutoStartSettings() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
            'openAutoStartSettings',
          ) ??
          const <String, dynamic>{};
      return PermissionOpenResult(
        opened: result['opened'] == true,
        fallback: result['fallback'] == true,
      );
    } on MissingPluginException {
      return const PermissionOpenResult(opened: false, fallback: false);
    } catch (_) {
      return const PermissionOpenResult(opened: false, fallback: false);
    }
  }

  Future<bool> openAppDetailsSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openAppDetailsSettings') ??
          false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
