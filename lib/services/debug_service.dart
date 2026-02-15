import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// ============================================================================
/// 调试服务 - 收集应用行为和进程信息
/// ============================================================================

class DebugLogEntry {
  final DateTime timestamp;
  final String level; // 'info', 'warning', 'error', 'debug'
  final String message;
  final String? source;

  DebugLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.source,
  });

  @override
  String toString() {
    final time = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    return '[$time] [$level] ${source != null ? '[$source] ' : ''}$message';
  }
}

class DebugService {
  static final DebugService _instance = DebugService._internal();
  factory DebugService() => _instance;
  DebugService._internal();

  // 日志存储
  final List<DebugLogEntry> _logs = [];
  final int _maxLogs = 500; // 最多保存500条日志

  // 路由历史
  final List<String> _routeHistory = [];
  final int _maxRoutes = 50;

  // 应用状态
  String _appState = 'Unknown';
  final Map<String, dynamic> _systemInfo = {};
  
  // 监听器
  final List<VoidCallback> _listeners = [];

  // Getters
  List<DebugLogEntry> get logs => List.unmodifiable(_logs);
  List<String> get routeHistory => List.unmodifiable(_routeHistory);
  String get appState => _appState;
  Map<String, dynamic> get systemInfo => Map.unmodifiable(_systemInfo);

  /// 添加监听器
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// 移除监听器
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// 通知监听器
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// 记录日志
  void log(String message, {String level = 'info', String? source}) {
    final entry = DebugLogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      source: source,
    );

    _logs.add(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    // 同时输出到调试控制台
    debugPrint('[DebugService] ${entry.toString()}');

    _notifyListeners();
  }

  /// 记录信息日志
  void info(String message, {String? source}) {
    log(message, level: 'info', source: source);
  }

  /// 记录警告日志
  void warning(String message, {String? source}) {
    log(message, level: 'warning', source: source);
  }

  /// 记录错误日志
  void error(String message, {String? source}) {
    log(message, level: 'error', source: source);
  }

  /// 记录调试日志
  void debug(String message, {String? source}) {
    log(message, level: 'debug', source: source);
  }

  /// 记录路由导航
  void recordRoute(String route) {
    final timeStr = _formatTime(DateTime.now());
    _routeHistory.add('$timeStr -> $route');
    if (_routeHistory.length > _maxRoutes) {
      _routeHistory.removeAt(0);
    }
    log('Navigation: $route', level: 'debug', source: 'Router');
    _notifyListeners();
  }

  /// 格式化时间为 HH:mm:ss
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  /// 更新应用状态
  void updateAppState(String state) {
    _appState = state;
    log('App state changed: $state', level: 'info', source: 'AppLifecycle');
    _notifyListeners();
  }

  /// 收集系统信息
  Future<void> collectSystemInfo() async {
    try {
      _systemInfo['Platform'] = Platform.operatingSystem;
      _systemInfo['Platform Version'] = Platform.operatingSystemVersion;
      _systemInfo['Dart Version'] = Platform.version;
      _systemInfo['Processors'] = Platform.numberOfProcessors.toString();
      _systemInfo['Locale'] = Platform.localeName;
      
      // 获取环境信息
      if (Platform.isAndroid) {
        _systemInfo['OS'] = 'Android';
      } else if (Platform.isIOS) {
        _systemInfo['OS'] = 'iOS';
      }

      log('System info collected', level: 'info', source: 'System');
      _notifyListeners();
    } catch (e) {
      error('Failed to collect system info: $e', source: 'System');
    }
  }

  /// 清空日志
  void clearLogs() {
    _logs.clear();
    log('Logs cleared', level: 'info', source: 'DebugService');
    _notifyListeners();
  }

  /// 清空路由历史
  void clearRouteHistory() {
    _routeHistory.clear();
    log('Route history cleared', level: 'info', source: 'DebugService');
    _notifyListeners();
  }

  /// 初始化
  Future<void> initialize() async {
    await collectSystemInfo();
    log('Debug service initialized', level: 'info', source: 'DebugService');
  }
}
