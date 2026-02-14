import 'dart:collection';
import 'package:flutter/foundation.dart';

/// 调试日志条目
/// 
/// 用于记录应用运行时的各种事件和状态变化
class DebugLogEntry {
  /// 时间戳
  final DateTime timestamp;
  
  /// 日志类型
  final DebugLogType type;
  
  /// 日志消息
  final String message;
  
  /// 附加数据（可选）
  final Map<String, dynamic>? data;

  DebugLogEntry({
    required this.timestamp,
    required this.type,
    required this.message,
    this.data,
  });

  /// 格式化时间戳为可读字符串
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${(timestamp.millisecond ~/ 10).toString().padLeft(2, '0')}';
  }

  /// 获取日志类型的图标
  String get typeIcon {
    switch (type) {
      case DebugLogType.info:
        return 'ℹ️';
      case DebugLogType.success:
        return '✅';
      case DebugLogType.warning:
        return '⚠️';
      case DebugLogType.error:
        return '❌';
      case DebugLogType.notification:
        return '🔔';
      case DebugLogType.permission:
        return '🔐';
      case DebugLogType.timezone:
        return '🌏';
      case DebugLogType.event:
        return '📅';
    }
  }
}

/// 日志类型枚举
enum DebugLogType {
  /// 一般信息
  info,
  
  /// 成功操作
  success,
  
  /// 警告
  warning,
  
  /// 错误
  error,
  
  /// 通知相关
  notification,
  
  /// 权限相关
  permission,
  
  /// 时区配置
  timezone,
  
  /// 事件操作
  event,
}

/// 调试日志服务
/// 
/// 单例模式，用于收集和管理应用的调试日志
/// 
/// 功能：
/// - 记录应用运行时的各种事件（通知、权限、时区、事件操作等）
/// - 提供日志查询接口
/// - 支持日志监听，实时更新UI
/// - 仅在调试模式下启用
class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal();

  /// 是否启用调试日志
  /// 仅在调试模式下启用，生产环境自动禁用
  bool get isEnabled => kDebugMode;

  /// 最大日志条目数（防止内存溢出）
  static const int _maxLogEntries = 500;

  /// 日志条目列表
  final List<DebugLogEntry> _logs = [];

  /// 日志变更监听器
  final List<VoidCallback> _listeners = [];

  /// 获取所有日志（只读）
  UnmodifiableListView<DebugLogEntry> get logs => UnmodifiableListView(_logs);

  /// 添加监听器
  void addListener(VoidCallback listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  /// 移除监听器
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// 通知所有监听器
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// 添加日志条目
  void log(
    DebugLogType type,
    String message, {
    Map<String, dynamic>? data,
  }) {
    // 生产环境不记录日志
    if (!isEnabled) return;

    final entry = DebugLogEntry(
      timestamp: DateTime.now(),
      type: type,
      message: message,
      data: data,
    );

    _logs.add(entry);

    // 限制日志数量，删除最旧的日志
    if (_logs.length > _maxLogEntries) {
      _logs.removeAt(0);
    }

    // 通知监听器
    _notifyListeners();

    // 同时输出到控制台
    debugPrint('${entry.typeIcon} [${entry.formattedTime}] $message');
  }

  /// 记录一般信息
  void info(String message, {Map<String, dynamic>? data}) {
    log(DebugLogType.info, message, data: data);
  }

  /// 记录成功操作
  void success(String message, {Map<String, dynamic>? data}) {
    log(DebugLogType.success, message, data: data);
  }

  /// 记录警告
  void warning(String message, {Map<String, dynamic>? data}) {
    log(DebugLogType.warning, message, data: data);
  }

  /// 记录错误
  void error(String message, {Map<String, dynamic>? data}) {
    log(DebugLogType.error, message, data: data);
  }

  /// 记录通知相关事件
  void notification(String message, {Map<String, dynamic>? data}) {
    log(DebugLogType.notification, message, data: data);
  }

  /// 记录权限相关事件
  void permission(String message, {Map<String, dynamic>? data}) {
    log(DebugLogType.permission, message, data: data);
  }

  /// 记录时区配置事件
  void timezone(String message, {Map<String, dynamic>? data}) {
    log(DebugLogType.timezone, message, data: data);
  }

  /// 记录事件操作
  void event(String message, {Map<String, dynamic>? data}) {
    log(DebugLogType.event, message, data: data);
  }

  /// 清空所有日志
  void clear() {
    _logs.clear();
    _notifyListeners();
  }

  /// 根据类型筛选日志
  List<DebugLogEntry> filterByType(DebugLogType type) {
    return _logs.where((entry) => entry.type == type).toList();
  }

  /// 搜索日志（按消息内容）
  List<DebugLogEntry> search(String query) {
    if (query.isEmpty) return _logs;
    final lowerQuery = query.toLowerCase();
    return _logs
        .where((entry) => entry.message.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// 获取最近的N条日志
  List<DebugLogEntry> getRecent(int count) {
    if (_logs.length <= count) return _logs;
    return _logs.sublist(_logs.length - count);
  }
}
