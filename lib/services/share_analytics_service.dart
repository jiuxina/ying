import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/shared_event.dart';

/// 分享统计
class ShareStatistics {
  final int totalShares;
  final int qrShares;
  final int linkShares;
  final int familyShares;
  final int successfulImports;
  final int activeCollaborations;
  final Map<String, int> sharesByCategory;
  final Map<String, int> sharesByDay;

  const ShareStatistics({
    this.totalShares = 0,
    this.qrShares = 0,
    this.linkShares = 0,
    this.familyShares = 0,
    this.successfulImports = 0,
    this.activeCollaborations = 0,
    this.sharesByCategory = const {},
    this.sharesByDay = const {},
  });

  factory ShareStatistics.fromMap(Map<String, dynamic> map) {
    return ShareStatistics(
      totalShares: map['totalShares'] as int? ?? 0,
      qrShares: map['qrShares'] as int? ?? 0,
      linkShares: map['linkShares'] as int? ?? 0,
      familyShares: map['familyShares'] as int? ?? 0,
      successfulImports: map['successfulImports'] as int? ?? 0,
      activeCollaborations: map['activeCollaborations'] as int? ?? 0,
      sharesByCategory: Map<String, int>.from(map['sharesByCategory'] as Map? ?? {}),
      sharesByDay: Map<String, int>.from(map['sharesByDay'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalShares': totalShares,
      'qrShares': qrShares,
      'linkShares': linkShares,
      'familyShares': familyShares,
      'successfulImports': successfulImports,
      'activeCollaborations': activeCollaborations,
      'sharesByCategory': sharesByCategory,
      'sharesByDay': sharesByDay,
    };
  }
}

/// 分享分析服务
/// 记录和分析分享行为
class ShareAnalyticsService {
  static final ShareAnalyticsService _instance = ShareAnalyticsService._internal();
  factory ShareAnalyticsService() => _instance;
  ShareAnalyticsService._internal();

  static const _uuid = Uuid();
  static const String _historyFile = 'share_history.json';
  static const String _statsFile = 'share_stats.json';

  /// 记录分享事件
  Future<void> recordShare({
    required String eventId,
    required String shareMethod,
    String? recipientName,
    String? categoryId,
  }) async {
    try {
      final entry = ShareHistoryEntry(
        id: _uuid.v4(),
        eventId: eventId,
        shareMethod: shareMethod,
        recipientName: recipientName,
        sharedAt: DateTime.now(),
      );

      // 追加到历史记录
      await _appendHistory(entry);

      // 更新统计
      await _updateStats(
        shareMethod: shareMethod,
        categoryId: categoryId,
      );

      debugPrint('ShareAnalytics: Recorded share for event $eventId');
    } catch (e) {
      debugPrint('ShareAnalytics recordShare error: $e');
    }
  }

  /// 记录成功导入
  Future<void> recordImport({
    required String eventId,
    required String sourceMethod,
  }) async {
    try {
      // 更新历史记录中的导入状态
      await _markAsImported(eventId);

      // 更新统计
      final stats = await getStatistics();
      final newStats = ShareStatistics(
        totalShares: stats.totalShares,
        qrShares: stats.qrShares,
        linkShares: stats.linkShares,
        familyShares: stats.familyShares,
        successfulImports: stats.successfulImports + 1,
        activeCollaborations: stats.activeCollaborations,
        sharesByCategory: stats.sharesByCategory,
        sharesByDay: stats.sharesByDay,
      );
      await _saveStatistics(newStats);

      debugPrint('ShareAnalytics: Recorded import for event $eventId');
    } catch (e) {
      debugPrint('ShareAnalytics recordImport error: $e');
    }
  }

  /// 记录协作加入
  Future<void> recordCollaborationJoin({
    required String shareId,
    required String eventId,
  }) async {
    try {
      final stats = await getStatistics();
      final newStats = ShareStatistics(
        totalShares: stats.totalShares,
        qrShares: stats.qrShares,
        linkShares: stats.linkShares,
        familyShares: stats.familyShares,
        successfulImports: stats.successfulImports,
        activeCollaborations: stats.activeCollaborations + 1,
        sharesByCategory: stats.sharesByCategory,
        sharesByDay: stats.sharesByDay,
      );
      await _saveStatistics(newStats);

      debugPrint('ShareAnalytics: Recorded collaboration join for $shareId');
    } catch (e) {
      debugPrint('ShareAnalytics recordCollaborationJoin error: $e');
    }
  }

  /// 获取分享历史
  Future<List<ShareHistoryEntry>> getHistory({
    String? eventId,
    String? shareMethod,
    int? limit,
  }) async {
    try {
      final file = await _getHistoryFile();
      if (!await file.exists()) return [];

      final json = await file.readAsString();
      final list = jsonDecode(json) as List<dynamic>;

      var history = list
          .map((h) => ShareHistoryEntry.fromMap(h as Map<String, dynamic>))
          .toList();

      // 过滤
      if (eventId != null) {
        history = history.where((h) => h.eventId == eventId).toList();
      }
      if (shareMethod != null) {
        history = history.where((h) => h.shareMethod == shareMethod).toList();
      }

      // 按时间倒序排序
      history.sort((a, b) => b.sharedAt.compareTo(a.sharedAt));

      // 限制数量
      if (limit != null && history.length > limit) {
        history = history.sublist(0, limit);
      }

      return history;
    } catch (e) {
      debugPrint('ShareAnalytics getHistory error: $e');
      return [];
    }
  }

  /// 获取统计数据
  Future<ShareStatistics> getStatistics() async {
    try {
      final file = await _getStatsFile();
      if (!await file.exists()) {
        return const ShareStatistics();
      }

      final json = await file.readAsString();
      return ShareStatistics.fromMap(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('ShareAnalytics getStatistics error: $e');
      return const ShareStatistics();
    }
  }

  /// 获取某时间段的分享趋势
  Future<Map<String, int>> getTrend({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final history = await getHistory();
      final trend = <String, int>{};

      for (final entry in history) {
        if (entry.sharedAt.isAfter(start) && entry.sharedAt.isBefore(end)) {
          final dayKey = '${entry.sharedAt.year}-${entry.sharedAt.month.toString().padLeft(2, '0')}-${entry.sharedAt.day.toString().padLeft(2, '0')}';
          trend[dayKey] = (trend[dayKey] ?? 0) + 1;
        }
      }

      return trend;
    } catch (e) {
      debugPrint('ShareAnalytics getTrend error: $e');
      return {};
    }
  }

  /// 获取热门分享事件
  Future<List<MapEntry<String, int>>> getTopSharedEvents({int limit = 10}) async {
    try {
      final history = await getHistory();
      final countMap = <String, int>{};

      for (final entry in history) {
        countMap[entry.eventId] = (countMap[entry.eventId] ?? 0) + 1;
      }

      final sorted = countMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.take(limit).toList();
    } catch (e) {
      debugPrint('ShareAnalytics getTopSharedEvents error: $e');
      return [];
    }
  }

  /// 清除历史记录
  Future<void> clearHistory() async {
    try {
      final file = await _getHistoryFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('ShareAnalytics clearHistory error: $e');
    }
  }

  /// 重置统计
  Future<void> resetStatistics() async {
    try {
      final file = await _getStatsFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('ShareAnalytics resetStatistics error: $e');
    }
  }

  // ==================== 私有方法 ====================

  Future<File> _getHistoryFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_historyFile');
  }

  Future<File> _getStatsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_statsFile');
  }

  Future<void> _appendHistory(ShareHistoryEntry entry) async {
    try {
      final file = await _getHistoryFile();
      
      List<dynamic> history = [];
      if (await file.exists()) {
        final json = await file.readAsString();
        history = jsonDecode(json) as List<dynamic>;
      }

      history.add(entry.toMap());
      await file.writeAsString(jsonEncode(history));
    } catch (e) {
      debugPrint('ShareAnalytics _appendHistory error: $e');
    }
  }

  Future<void> _markAsImported(String eventId) async {
    try {
      final file = await _getHistoryFile();
      if (!await file.exists()) return;

      final json = await file.readAsString();
      final history = jsonDecode(json) as List<dynamic>;

      // 查找并更新最近的匹配记录
      for (var i = history.length - 1; i >= 0; i--) {
        final entry = history[i] as Map<String, dynamic>;
        if (entry['eventId'] == eventId && entry['wasImported'] != true) {
          entry['wasImported'] = true;
          break;
        }
      }

      await file.writeAsString(jsonEncode(history));
    } catch (e) {
      debugPrint('ShareAnalytics _markAsImported error: $e');
    }
  }

  Future<void> _updateStats({
    required String shareMethod,
    String? categoryId,
  }) async {
    try {
      final stats = await getStatistics();
      final today = DateTime.now();
      final dayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final newCategoryStats = Map<String, int>.from(stats.sharesByCategory);
      if (categoryId != null) {
        newCategoryStats[categoryId] = (newCategoryStats[categoryId] ?? 0) + 1;
      }

      final newDayStats = Map<String, int>.from(stats.sharesByDay);
      newDayStats[dayKey] = (newDayStats[dayKey] ?? 0) + 1;

      final newStats = ShareStatistics(
        totalShares: stats.totalShares + 1,
        qrShares: shareMethod == 'qr' ? stats.qrShares + 1 : stats.qrShares,
        linkShares: shareMethod == 'link' ? stats.linkShares + 1 : stats.linkShares,
        familyShares: shareMethod == 'family' ? stats.familyShares + 1 : stats.familyShares,
        successfulImports: stats.successfulImports,
        activeCollaborations: stats.activeCollaborations,
        sharesByCategory: newCategoryStats,
        sharesByDay: newDayStats,
      );

      await _saveStatistics(newStats);
    } catch (e) {
      debugPrint('ShareAnalytics _updateStats error: $e');
    }
  }

  Future<void> _saveStatistics(ShareStatistics stats) async {
    try {
      final file = await _getStatsFile();
      await file.writeAsString(jsonEncode(stats.toMap()));
    } catch (e) {
      debugPrint('ShareAnalytics _saveStatistics error: $e');
    }
  }
}
