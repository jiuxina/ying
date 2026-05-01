import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/countdown_event.dart';
import '../models/intelligence_models.dart';
import '../models/reminder.dart';
import '../services/database_service.dart';
import '../services/natural_language_parser.dart';
import '../services/smart_suggestion_service.dart';
import '../services/smart_reminder_engine.dart';
import '../services/holiday_detector.dart';

/// 智能服务 - 本地智能功能核心
///
/// 提供所有智能功能的统一入口：
/// - 自然语言解析
/// - 智能分类建议
/// - 智能提醒建议
/// - 重复事件检测
/// - 节假日检测
/// - 用户行为学习
///
/// 所有功能均在本地运行，不依赖外部API
class IntelligenceService {
  static final IntelligenceService _instance = IntelligenceService._internal();
  factory IntelligenceService() => _instance;
  IntelligenceService._internal();

  final DatabaseService _dbService = DatabaseService();
  late final NaturalLanguageParser _parser;
  late final SmartSuggestionService _suggestionService;
  late final SmartReminderEngine _reminderEngine;

  IntelligenceSettings _settings = const IntelligenceSettings();
  bool _initialized = false;

  // 学习到的模式缓存
  final Map<String, LearnedPattern> _patternCache = {};

  // ==================== 初始化 ====================

  /// 初始化服务
  Future<void> initialize() async {
    if (_initialized) return;

    // 初始化子服务
    _parser = NaturalLanguageParser();
    _suggestionService = SmartSuggestionService();
    _reminderEngine = SmartReminderEngine();

    // 加载设置
    await _loadSettings();

    // 加载学习到的模式
    await _loadPatterns();

    _initialized = true;
    debugPrint('✓ 智能服务初始化完成');
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('intelligence_settings');
      if (settingsJson != null) {
        // 简单解析
        final enabled = prefs.getBool('intelligence_enabled') ?? true;
        final smartReminders = prefs.getBool('intelligence_smartReminders') ?? true;
        final smartCategorization = prefs.getBool('intelligence_smartCategorization') ?? true;
        final naturalLanguageInput = prefs.getBool('intelligence_naturalLanguageInput') ?? true;
        final duplicateDetection = prefs.getBool('intelligence_duplicateDetection') ?? true;
        final holidayDetection = prefs.getBool('intelligence_holidayDetection') ?? true;
        final seasonalSuggestions = prefs.getBool('intelligence_seasonalSuggestions') ?? true;
        final learnFromBehavior = prefs.getBool('intelligence_learnFromBehavior') ?? true;
        
        _settings = IntelligenceSettings(
          enabled: enabled,
          smartReminders: smartReminders,
          smartCategorization: smartCategorization,
          naturalLanguageInput: naturalLanguageInput,
          duplicateDetection: duplicateDetection,
          holidayDetection: holidayDetection,
          seasonalSuggestions: seasonalSuggestions,
          learnFromBehavior: learnFromBehavior,
        );
      }
    } catch (e) {
      debugPrint('加载智能服务设置失败: $e');
    }
  }

  /// 保存设置
  Future<void> saveSettings(IntelligenceSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('intelligence_enabled', settings.enabled);
      await prefs.setBool('intelligence_smartReminders', settings.smartReminders);
      await prefs.setBool('intelligence_smartCategorization', settings.smartCategorization);
      await prefs.setBool('intelligence_naturalLanguageInput', settings.naturalLanguageInput);
      await prefs.setBool('intelligence_duplicateDetection', settings.duplicateDetection);
      await prefs.setBool('intelligence_holidayDetection', settings.holidayDetection);
      await prefs.setBool('intelligence_seasonalSuggestions', settings.seasonalSuggestions);
      await prefs.setBool('intelligence_learnFromBehavior', settings.learnFromBehavior);
      
      _settings = settings;
      debugPrint('✓ 智能服务设置已保存');
    } catch (e) {
      debugPrint('保存智能服务设置失败: $e');
    }
  }

  /// 加载学习到的模式
  Future<void> _loadPatterns() async {
    try {
      final patterns = await _dbService.getAllLearnedPatterns();
      for (final pattern in patterns) {
        _patternCache[pattern.key] = pattern;
      }
      debugPrint('✓ 已加载 ${patterns.length} 个学习模式');
    } catch (e) {
      debugPrint('加载学习模式失败: $e');
    }
  }

  // ==================== 公共API ====================

  /// 获取当前设置
  IntelligenceSettings get settings => _settings;

  /// 更新设置
  Future<void> updateSettings(IntelligenceSettings settings) async {
    await saveSettings(settings);
  }

  /// 检查功能是否启用
  bool isFeatureEnabled(String feature) {
    if (!_settings.enabled) return false;
    
    switch (feature) {
      case 'smartReminders':
        return _settings.smartReminders;
      case 'smartCategorization':
        return _settings.smartCategorization;
      case 'naturalLanguageInput':
        return _settings.naturalLanguageInput;
      case 'duplicateDetection':
        return _settings.duplicateDetection;
      case 'holidayDetection':
        return _settings.holidayDetection;
      case 'seasonalSuggestions':
        return _settings.seasonalSuggestions;
      case 'learnFromBehavior':
        return _settings.learnFromBehavior;
      default:
        return false;
    }
  }

  // ==================== 自然语言解析 ====================

  /// 解析自然语言输入
  ///
  /// 示例：
  /// - "妈妈生日 下周五" → 提取标题和日期
  /// - "考试 2024年6月15日" → 提取标题和日期
  /// - "春节 农历正月初一" → 提取农历日期
  Future<ParsedEventInput> parseNaturalLanguage(String input) async {
    if (!isFeatureEnabled('naturalLanguageInput')) {
      return const ParsedEventInput();
    }

    await initialize();
    return _parser.parse(input);
  }

  /// 解析并获取完整建议
  ///
  /// 综合解析自然语言并返回所有相关建议
  Future<SmartInputResult> parseAndSuggest(String input) async {
    if (!isFeatureEnabled('naturalLanguageInput')) {
      return const SmartInputResult(parsed: ParsedEventInput());
    }

    await initialize();
    return _suggestionService.parseAndSuggest(input);
  }

  // ==================== 分类建议 ====================

  /// 获取分类建议
  Future<List<SmartSuggestion>> getCategorySuggestions(String title) async {
    if (!isFeatureEnabled('smartCategorization')) {
      return [];
    }

    await initialize();
    return _suggestionService.getCategorySuggestions(title);
  }

  /// 获取标签建议
  Future<List<String>> getTagSuggestions(String title, String? categoryId) async {
    if (!isFeatureEnabled('smartCategorization')) {
      return [];
    }

    await initialize();
    return _suggestionService.getTagSuggestions(title, categoryId);
  }

  // ==================== 提醒建议 ====================

  /// 获取智能提醒建议
  Future<List<SmartReminderSuggestion>> getReminderSuggestions(
    CountdownEvent event,
  ) async {
    if (!isFeatureEnabled('smartReminders')) {
      return [];
    }

    await initialize();
    return _reminderEngine.getSuggestions(event);
  }

  /// 生成智能提醒
  Future<List<Reminder>> generateSmartReminders(
    CountdownEvent event, {
    int maxReminders = 5,
  }) async {
    if (!isFeatureEnabled('smartReminders')) {
      return [];
    }

    await initialize();
    return _reminderEngine.generateReminders(event, maxReminders: maxReminders);
  }

  // ==================== 重复检测 ====================

  /// 检测重复事件
  Future<DuplicateCheckResult> checkDuplicate(
    String title,
    DateTime? targetDate,
  ) async {
    if (!isFeatureEnabled('duplicateDetection')) {
      return const DuplicateCheckResult();
    }

    await initialize();
    return _suggestionService.checkDuplicate(title, targetDate);
  }

  // ==================== 节假日检测 ====================

  /// 检测日期的节假日
  List<HolidayInfo> detectHolidays(DateTime date) {
    if (!isFeatureEnabled('holidayDetection')) {
      return [];
    }

    return HolidayDetector.detectHolidays(date);
  }

  /// 获取即将到来的节假日
  List<HolidayInfo> getUpcomingHolidays({int count = 5}) {
    if (!isFeatureEnabled('holidayDetection')) {
      return [];
    }

    return HolidayDetector.getUpcomingHolidays(count: count);
  }

  /// 获取月份节假日
  List<HolidayInfo> getMonthHolidays(int year, int month) {
    if (!isFeatureEnabled('holidayDetection')) {
      return [];
    }

    return HolidayDetector.getMonthHolidays(year, month);
  }

  // ==================== 季节性建议 ====================

  /// 获取季节性事件建议
  Future<List<SmartSuggestion>> getSeasonalSuggestions() async {
    if (!isFeatureEnabled('seasonalSuggestions')) {
      return [];
    }

    await initialize();
    return _suggestionService.getSeasonalSuggestions();
  }

  // ==================== 用户行为学习 ====================

  /// 记录事件创建行为
  ///
  /// 用于学习用户偏好
  Future<void> recordEventCreation(CountdownEvent event) async {
    if (!isFeatureEnabled('learnFromBehavior')) return;

    await initialize();

    // 记录分类偏好
    await _recordPattern(
      type: PatternType.categoryPreference,
      key: 'category_${event.categoryId}',
      data: {
        'categoryId': event.categoryId,
        'count': 1,
      },
    );

    // 记录时间偏好
    if (event.enableNotification && event.reminders.isNotEmpty) {
      for (final reminder in event.reminders) {
        final daysBefore = event.targetDate.difference(reminder.reminderDateTime).inDays;
        await _recordPattern(
          type: PatternType.reminderTime,
          key: 'reminder_${event.categoryId}_$daysBefore',
          data: {
            'categoryId': event.categoryId,
            'daysBefore': daysBefore,
            'hour': reminder.reminderDateTime.hour,
            'minute': reminder.reminderDateTime.minute,
          },
        );
      }
    }

    // 记录重复偏好
    if (event.isRepeating) {
      await _recordPattern(
        type: PatternType.eventTiming,
        key: 'repeating_${event.categoryId}',
        data: {
          'categoryId': event.categoryId,
          'isRepeating': true,
        },
      );
    }
  }

  /// 记录模式
  Future<void> _recordPattern({
    required PatternType type,
    required String key,
    required Map<String, dynamic> data,
  }) async {
    try {
      final existingPattern = _patternCache[key];
      
      if (existingPattern != null) {
        // 更新现有模式
        final updatedPattern = existingPattern.updateWithNewSample(data);
        await _dbService.updateLearnedPattern(updatedPattern);
        _patternCache[key] = updatedPattern;
      } else {
        // 创建新模式
        final newPattern = LearnedPattern.create(
          type: type,
          key: key,
          data: data,
        );
        await _dbService.insertLearnedPattern(newPattern);
        _patternCache[key] = newPattern;
      }
    } catch (e) {
      debugPrint('记录模式失败: $e');
    }
  }

  /// 获取学习到的模式
  LearnedPattern? getPattern(String key) {
    return _patternCache[key];
  }

  /// 获取所有模式
  List<LearnedPattern> getAllPatterns() {
    return _patternCache.values.toList();
  }

  // ==================== 统计分析 ====================

  /// 获取事件统计
  Future<EventStatistics> getEventStatistics() async {
    final events = await _dbService.getAllEvents();
    final activeEvents = events.where((e) => !e.isArchived).toList();
    final archivedEvents = events.where((e) => e.isArchived).toList();

    // 分类分布
    final categoryDistribution = <String, int>{};
    for (final event in activeEvents) {
      categoryDistribution[event.categoryId] = 
          (categoryDistribution[event.categoryId] ?? 0) + 1;
    }

    // 时间分布
    final hourlyDistribution = <int, int>{};
    final weeklyDistribution = <int, int>{};
    final monthlyDistribution = <int, int>{};
    
    for (final event in events) {
      final created = event.createdAt;
      hourlyDistribution[created.hour] = 
          (hourlyDistribution[created.hour] ?? 0) + 1;
      weeklyDistribution[created.weekday] = 
          (weeklyDistribution[created.weekday] ?? 0) + 1;
      monthlyDistribution[created.month] = 
          (monthlyDistribution[created.month] ?? 0) + 1;
    }

    // 提醒统计
    final allReminders = await _dbService.getAllRemindersGrouped();
    var totalReminders = 0;
    for (final entry in allReminders.entries) {
      totalReminders += entry.value.length;
    }
    final avgReminders = events.isNotEmpty ? totalReminders / events.length : 0.0;

    // 重复事件比例
    final repeatingCount = events.where((e) => e.isRepeating).length;
    final repeatingRatio = events.isNotEmpty ? repeatingCount / events.length : 0.0;

    return EventStatistics(
      totalEvents: events.length,
      activeEvents: activeEvents.length,
      archivedEvents: archivedEvents.length,
      categoryDistribution: categoryDistribution,
      hourlyDistribution: hourlyDistribution,
      weeklyDistribution: weeklyDistribution,
      monthlyDistribution: monthlyDistribution,
      avgRemindersPerEvent: avgReminders,
      repeatingEventRatio: repeatingRatio,
    );
  }

  /// 分析用户提醒偏好
  Future<Map<String, dynamic>> analyzeReminderPatterns() async {
    return _reminderEngine.analyzeUserReminderPatterns();
  }

  // ==================== 数据管理 ====================

  /// 清除所有学习数据
  Future<void> clearLearnedData() async {
    try {
      await _dbService.clearLearnedPatterns();
      _patternCache.clear();
      debugPrint('✓ 已清除所有学习数据');
    } catch (e) {
      debugPrint('清除学习数据失败: $e');
    }
  }

  /// 导出学习数据
  Future<Map<String, dynamic>> exportLearnedData() async {
    return {
      'patterns': _patternCache.values.map((p) => p.toMap()).toList(),
      'settings': _settings.toMap(),
    };
  }

  /// 导入学习数据
  Future<void> importLearnedData(Map<String, dynamic> data) async {
    try {
      // 导入模式
      final patterns = data['patterns'] as List?;
      if (patterns != null) {
        for (final patternMap in patterns) {
          final pattern = LearnedPattern.fromMap(patternMap as Map<String, dynamic>);
          await _dbService.insertLearnedPattern(pattern);
          _patternCache[pattern.key] = pattern;
        }
      }

      // 导入设置
      final settings = data['settings'] as Map<String, dynamic>?;
      if (settings != null) {
        _settings = IntelligenceSettings.fromMap(settings);
        await saveSettings(_settings);
      }

      debugPrint('✓ 已导入学习数据');
    } catch (e) {
      debugPrint('导入学习数据失败: $e');
    }
  }
}
