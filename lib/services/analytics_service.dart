import 'package:flutter/material.dart';
import '../models/countdown_event.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';

/// 统计数据模型 - 分类统计
class CategoryStats {
  final String categoryId;
  final String categoryName;
  final String icon;
  final Color color;
  final int count;
  final double percentage;

  const CategoryStats({
    required this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.color,
    required this.count,
    required this.percentage,
  });
}

/// 统计数据模型 - 月度统计
class MonthlyStats {
  final int year;
  final int month;
  final int count;
  final int upcomingCount;
  final int passedCount;

  const MonthlyStats({
    required this.year,
    required this.month,
    required this.count,
    required this.upcomingCount,
    required this.passedCount,
  });

  String get label => '$year年$month月';
}

/// 统计数据模型 - 时间范围统计
class TimeRangeStats {
  final int totalEvents;
  final int upcomingEvents;
  final int passedEvents;
  final int ongoingEvents;
  final int archivedEvents;
  final double upcomingRatio;
  final double passedRatio;

  const TimeRangeStats({
    required this.totalEvents,
    required this.upcomingEvents,
    required this.passedEvents,
    required this.ongoingEvents,
    required this.archivedEvents,
    required this.upcomingRatio,
    required this.passedRatio,
  });
}

/// 统计数据模型 - 活跃月份
class ActiveMonth {
  final int year;
  final int month;
  final int eventCount;
  final double activityScore;

  const ActiveMonth({
    required this.year,
    required this.month,
    required this.eventCount,
    required this.activityScore,
  });

  String get label => '$year年$month月';
}

/// 统计数据模型 - 事件密度分析
class EventDensityAnalysis {
  final double averageEventsPerMonth;
  final double averageEventsPerWeek;
  final int peakMonthEventCount;
  final int peakMonth;
  final int peakYear;
  final int quietMonthEventCount;
  final int quietMonth;
  final int quietYear;
  final List<MonthlyStats> monthlyDistribution;

  const EventDensityAnalysis({
    required this.averageEventsPerMonth,
    required this.averageEventsPerWeek,
    required this.peakMonthEventCount,
    required this.peakMonth,
    required this.peakYear,
    required this.quietMonthEventCount,
    required this.quietMonth,
    required this.quietYear,
    required this.monthlyDistribution,
  });

  String get peakMonthLabel => '$peakYear年$peakMonth月';
  String get quietMonthLabel => '$quietYear年$quietMonth月';
}

/// 统计数据模型 - 创建趋势
class CreationTrend {
  final DateTime date;
  final int count;
  final int cumulative;

  const CreationTrend({
    required this.date,
    required this.count,
    required this.cumulative,
  });
}

/// 统计数据模型 - 综合统计
class ComprehensiveStats {
  final int totalEvents;
  final int activeEvents;
  final int archivedEvents;
  final int totalCategories;
  final int usedCategories;
  final int totalReminders;
  final int upcomingEvents7Days;
  final int upcomingEvents30Days;
  final TimeRangeStats timeStats;

  const ComprehensiveStats({
    required this.totalEvents,
    required this.activeEvents,
    required this.archivedEvents,
    required this.totalCategories,
    required this.usedCategories,
    required this.totalReminders,
    required this.upcomingEvents7Days,
    required this.upcomingEvents30Days,
    required this.timeStats,
  });
}

/// 分析服务 - 提供数据统计和分析功能
/// 
/// 使用单例模式确保整个应用只有一个实例
class AnalyticsService {
  // 单例实例
  static final AnalyticsService _instance = AnalyticsService._internal();
  
  /// 工厂构造函数，始终返回同一实例
  factory AnalyticsService() => _instance;
  
  /// 私有构造函数
  AnalyticsService._internal();

  final DatabaseService _dbService = DatabaseService();

  // 缓存
  ComprehensiveStats? _cachedStats;
  List<CategoryStats>? _cachedCategoryStats;
  List<MonthlyStats>? _cachedMonthlyStats;
  DateTime? _cacheTimestamp;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// 清除缓存
  void clearCache() {
    _cachedStats = null;
    _cachedCategoryStats = null;
    _cachedMonthlyStats = null;
    _cacheTimestamp = null;
  }

  /// 检查缓存是否有效
  bool get _isCacheValid {
    if (_cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheExpiry;
  }

  /// 获取综合统计数据
  Future<ComprehensiveStats> getComprehensiveStats({
    List<CountdownEvent>? events,
    List<Category>? categories,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isCacheValid && _cachedStats != null) {
      return _cachedStats!;
    }

    // 获取事件列表
    final eventList = events ?? await _dbService.getActiveEvents();
    final archivedList = await _dbService.getArchivedEvents();
    
    // 获取分类列表
    final categoryList = categories ?? 
        (await _dbService.getAllCategories())
            .map((m) => Category.fromJson(m))
            .toList();

    // 获取提醒数量
    final allReminders = await _dbService.getAllRemindersGrouped();
    final totalReminders = allReminders.values
        .fold<int>(0, (sum, list) => sum + list.length);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 计算即将到来的事件
    int upcoming7 = 0;
    int upcoming30 = 0;
    
    for (final event in eventList) {
      if (!event.isCountUp) {
        final targetDay = DateTime(
          event.targetDate.year,
          event.targetDate.month,
          event.targetDate.day,
        );
        final daysUntil = targetDay.difference(today).inDays;
        
        if (daysUntil >= 0 && daysUntil <= 7) upcoming7++;
        if (daysUntil >= 0 && daysUntil <= 30) upcoming30++;
      }
    }

    // 计算使用的分类数量
    final usedCategoryIds = eventList.map((e) => e.categoryId).toSet();

    // 时间范围统计
    final timeStats = _calculateTimeRangeStats(eventList);

    final stats = ComprehensiveStats(
      totalEvents: eventList.length + archivedList.length,
      activeEvents: eventList.length,
      archivedEvents: archivedList.length,
      totalCategories: categoryList.length,
      usedCategories: usedCategoryIds.length,
      totalReminders: totalReminders,
      upcomingEvents7Days: upcoming7,
      upcomingEvents30Days: upcoming30,
      timeStats: timeStats,
    );

    _cachedStats = stats;
    _cacheTimestamp = DateTime.now();
    
    return stats;
  }

  /// 按分类获取统计
  Future<List<CategoryStats>> getEventsByCategoryStats({
    List<CountdownEvent>? events,
    List<Category>? categories,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isCacheValid && _cachedCategoryStats != null) {
      return _cachedCategoryStats!;
    }

    // 获取事件列表
    final eventList = events ?? await _dbService.getActiveEvents();
    
    // 获取分类列表
    final categoryList = categories ?? 
        (await _dbService.getAllCategories())
            .map((m) => Category.fromJson(m))
            .toList();

    // 统计每个分类的事件数量
    final categoryCount = <String, int>{};
    for (final event in eventList) {
      categoryCount[event.categoryId] = (categoryCount[event.categoryId] ?? 0) + 1;
    }

    final total = eventList.length;
    final stats = <CategoryStats>[];

    for (final category in categoryList) {
      final count = categoryCount[category.id] ?? 0;
      if (count > 0) {
        stats.add(CategoryStats(
          categoryId: category.id,
          categoryName: category.name,
          icon: category.icon,
          color: Color(category.color),
          count: count,
          percentage: total > 0 ? count / total : 0,
        ));
      }
    }

    // 按数量降序排序
    stats.sort((a, b) => b.count.compareTo(a.count));

    _cachedCategoryStats = stats;
    _cacheTimestamp = DateTime.now();
    
    return stats;
  }

  /// 按月份获取统计
  Future<List<MonthlyStats>> getEventsByMonthStats({
    List<CountdownEvent>? events,
    int? year,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isCacheValid && _cachedMonthlyStats != null && year == null) {
      return _cachedMonthlyStats!;
    }

    // 获取事件列表
    final eventList = events ?? await _dbService.getActiveEvents();

    final now = DateTime.now();
    final targetYear = year ?? now.year;

    // 按月份分组统计
    final monthlyData = <int, int>{};
    final upcomingData = <int, int>{};
    final passedData = <int, int>{};

    for (final event in eventList) {
      if (event.targetDate.year == targetYear) {
        final month = event.targetDate.month;
        monthlyData[month] = (monthlyData[month] ?? 0) + 1;

        if (event.isCountUp || event.daysRemaining < 0) {
          passedData[month] = (passedData[month] ?? 0) + 1;
        } else {
          upcomingData[month] = (upcomingData[month] ?? 0) + 1;
        }
      }
    }

    final stats = <MonthlyStats>[];
    for (int month = 1; month <= 12; month++) {
      stats.add(MonthlyStats(
        year: targetYear,
        month: month,
        count: monthlyData[month] ?? 0,
        upcomingCount: upcomingData[month] ?? 0,
        passedCount: passedData[month] ?? 0,
      ));
    }

    if (year == null) {
      _cachedMonthlyStats = stats;
      _cacheTimestamp = DateTime.now();
    }
    
    return stats;
  }

  /// 获取即将到来 vs 已过事件比例
  Future<TimeRangeStats> getUpcomingVsPastRatio({
    List<CountdownEvent>? events,
    bool forceRefresh = false,
  }) async {
    final eventList = events ?? await _dbService.getActiveEvents();
    return _calculateTimeRangeStats(eventList);
  }

  /// 计算时间范围统计
  TimeRangeStats _calculateTimeRangeStats(List<CountdownEvent> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int upcoming = 0;
    int passed = 0;
    int ongoing = 0;

    for (final event in events) {
      if (event.isCountUp) {
        ongoing++;
        passed++;
      } else {
        final targetDay = DateTime(
          event.targetDate.year,
          event.targetDate.month,
          event.targetDate.day,
        );
        final daysUntil = targetDay.difference(today).inDays;

        if (daysUntil >= 0) {
          upcoming++;
          ongoing++;
        } else {
          passed++;
        }
      }
    }

    final total = events.length;
    final archivedCount = events.where((e) => e.isArchived).length;

    return TimeRangeStats(
      totalEvents: total,
      upcomingEvents: upcoming,
      passedEvents: passed,
      ongoingEvents: ongoing,
      archivedEvents: archivedCount,
      upcomingRatio: total > 0 ? upcoming / total : 0,
      passedRatio: total > 0 ? passed / total : 0,
    );
  }

  /// 获取最活跃的月份
  Future<List<ActiveMonth>> getMostActiveMonths({
    List<CountdownEvent>? events,
    int limit = 5,
  }) async {
    final eventList = events ?? await _dbService.getActiveEvents();

    // 按年月分组
    final monthCount = <String, int>{};
    for (final event in eventList) {
      final key = '${event.targetDate.year}-${event.targetDate.month}';
      monthCount[key] = (monthCount[key] ?? 0) + 1;
    }

    // 转换为列表并排序
    final entries = monthCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 计算最大值用于评分
    final maxCount = entries.isNotEmpty ? entries.first.value : 1;

    // 取前N个
    final topMonths = entries.take(limit);
    
    final result = <ActiveMonth>[];
    for (final entry in topMonths) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      
      result.add(ActiveMonth(
        year: year,
        month: month,
        eventCount: entry.value,
        activityScore: entry.value / maxCount,
      ));
    }

    return result;
  }

  /// 获取事件密度分析
  Future<EventDensityAnalysis> getEventDensityAnalysis({
    List<CountdownEvent>? events,
    int? year,
  }) async {
    final eventList = events ?? await _dbService.getActiveEvents();
    final targetYear = year ?? DateTime.now().year;

    // 获取月度统计
    final monthlyStats = await getEventsByMonthStats(
      events: eventList,
      year: targetYear,
    );

    // 计算平均值
    final totalEvents = monthlyStats.fold<int>(0, (sum, m) => sum + m.count);
    final monthsWithData = monthlyStats.where((m) => m.count > 0).length;
    
    final avgPerMonth = monthsWithData > 0 
        ? totalEvents / monthsWithData 
        : 0.0;
    final avgPerWeek = avgPerMonth / 4.33; // 平均每月约4.33周

    // 找出峰值和低谷月份
    int peakCount = 0;
    int peakMonth = 1;
    int quietCount = double.maxFinite.toInt();
    int quietMonth = 1;

    for (final stat in monthlyStats) {
      if (stat.count > peakCount) {
        peakCount = stat.count;
        peakMonth = stat.month;
      }
      if (stat.count < quietCount && stat.count > 0) {
        quietCount = stat.count;
        quietMonth = stat.month;
      }
    }

    // 如果所有月份都没有数据，设置默认值
    if (quietCount == double.maxFinite.toInt()) {
      quietCount = 0;
    }

    return EventDensityAnalysis(
      averageEventsPerMonth: avgPerMonth,
      averageEventsPerWeek: avgPerWeek,
      peakMonthEventCount: peakCount,
      peakMonth: peakMonth,
      peakYear: targetYear,
      quietMonthEventCount: quietCount,
      quietMonth: quietMonth,
      quietYear: targetYear,
      monthlyDistribution: monthlyStats,
    );
  }

  /// 获取事件创建趋势（按天）
  Future<List<CreationTrend>> getCreationTrend({
    List<CountdownEvent>? events,
    int days = 30,
  }) async {
    final eventList = events ?? await _dbService.getActiveEvents();

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    // 按创建日期分组
    final dailyCount = <DateTime, int>{};
    
    for (final event in eventList) {
      final createdDate = DateTime(
        event.createdAt.year,
        event.createdAt.month,
        event.createdAt.day,
      );
      
      if (createdDate.isAfter(startDate) || createdDate.isAtSameMomentAs(startDate)) {
        dailyCount[createdDate] = (dailyCount[createdDate] ?? 0) + 1;
      }
    }

    // 生成完整的日期序列（包括没有事件的日期）
    final result = <CreationTrend>[];
    int cumulative = 0;
    
    for (int i = 0; i <= days; i++) {
      final date = startDate.add(Duration(days: i));
      final count = dailyCount[date] ?? 0;
      cumulative += count;
      
      result.add(CreationTrend(
        date: date,
        count: count,
        cumulative: cumulative,
      ));
    }

    return result;
  }

  /// 获取分类使用排名
  Future<List<MapEntry<String, int>>> getCategoryRanking({
    List<CountdownEvent>? events,
    int limit = 10,
  }) async {
    final eventList = events ?? await _dbService.getActiveEvents();

    final categoryCount = <String, int>{};
    for (final event in eventList) {
      categoryCount[event.categoryId] = (categoryCount[event.categoryId] ?? 0) + 1;
    }

    final sorted = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).toList();
  }

  /// 获取重复事件统计
  Future<Map<String, dynamic>> getRepeatingEventStats({
    List<CountdownEvent>? events,
  }) async {
    final eventList = events ?? await _dbService.getActiveEvents();

    final repeatingEvents = eventList.where((e) => e.isRepeating).toList();
    final nonRepeatingEvents = eventList.where((e) => !e.isRepeating).toList();

    return {
      'total': eventList.length,
      'repeating': repeatingEvents.length,
      'nonRepeating': nonRepeatingEvents.length,
      'repeatingPercentage': eventList.isNotEmpty 
          ? repeatingEvents.length / eventList.length 
          : 0,
    };
  }

  /// 获取农历事件统计
  Future<Map<String, dynamic>> getLunarEventStats({
    List<CountdownEvent>? events,
  }) async {
    final eventList = events ?? await _dbService.getActiveEvents();

    final lunarEvents = eventList.where((e) => e.isLunar).toList();
    final solarEvents = eventList.where((e) => !e.isLunar).toList();

    return {
      'total': eventList.length,
      'lunar': lunarEvents.length,
      'solar': solarEvents.length,
      'lunarPercentage': eventList.isNotEmpty 
          ? lunarEvents.length / eventList.length 
          : 0,
    };
  }

  /// 获取正计时 vs 倒计时统计
  Future<Map<String, dynamic>> getCountUpVsCountDownStats({
    List<CountdownEvent>? events,
  }) async {
    final eventList = events ?? await _dbService.getActiveEvents();

    final countUpEvents = eventList.where((e) => e.isCountUp).toList();
    final countDownEvents = eventList.where((e) => !e.isCountUp).toList();

    return {
      'total': eventList.length,
      'countUp': countUpEvents.length,
      'countDown': countDownEvents.length,
      'countUpPercentage': eventList.isNotEmpty 
          ? countUpEvents.length / eventList.length 
          : 0,
    };
  }
}
