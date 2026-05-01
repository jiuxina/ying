import '../models/countdown_event.dart';
import '../models/intelligence_models.dart';
import '../models/reminder.dart';
import '../services/database_service.dart';

/// 智能提醒引擎
///
/// 基于用户行为和事件特征，提供智能提醒建议：
/// - 分析用户历史提醒设置
/// - 根据事件类型推荐提醒时间
/// - 学习用户偏好
/// - 考虑事件重要性
class SmartReminderEngine {
  final DatabaseService _dbService;

  SmartReminderEngine({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService();

  // ==================== 默认提醒策略 ====================

  /// 分类默认提醒策略
  static const _categoryDefaultStrategies = {
    'birthday': [
      (daysBefore: 7, hour: 9, reason: '提前一周准备礼物'),
      (daysBefore: 1, hour: 9, reason: '明天就是生日'),
      (daysBefore: 0, hour: 9, reason: '今天生日'),
    ],
    'anniversary': [
      (daysBefore: 7, hour: 9, reason: '提前一周准备'),
      (daysBefore: 1, hour: 18, reason: '明天纪念日'),
      (daysBefore: 0, hour: 9, reason: '今天纪念日'),
    ],
    'holiday': [
      (daysBefore: 7, hour: 9, reason: '假期计划安排'),
      (daysBefore: 1, hour: 18, reason: '明天放假'),
    ],
    'exam': [
      (daysBefore: 30, hour: 9, reason: '考前一个月复习'),
      (daysBefore: 7, hour: 9, reason: '考前一周冲刺'),
      (daysBefore: 1, hour: 20, reason: '考前一晚准备'),
      (daysBefore: 0, hour: 7, reason: '考试当天'),
    ],
    'work': [
      (daysBefore: 1, hour: 9, reason: '提前一天准备'),
      (daysBefore: 0, hour: 8, reason: '当天提醒'),
    ],
    'travel': [
      (daysBefore: 7, hour: 9, reason: '提前一周准备行程'),
      (daysBefore: 3, hour: 9, reason: '出行前检查'),
      (daysBefore: 1, hour: 20, reason: '明天出发'),
    ],
    'custom': [
      (daysBefore: 1, hour: 9, reason: '默认提前一天'),
    ],
  };

  /// 重要性权重
  static const _importanceWeights = {
    'high': 1.5, // 重要事件建议更多提醒
    'medium': 1.0,
    'low': 0.7,
  };

  // ==================== 主方法 ====================

  /// 获取智能提醒建议
  ///
  /// 根据事件特征和用户历史，生成最优提醒建议
  Future<List<SmartReminderSuggestion>> getSuggestions(
    CountdownEvent event, {
    bool includeHistory = true,
  }) async {
    final suggestions = <SmartReminderSuggestion>[];

    // 1. 获取分类默认策略
    final categoryStrategy = _getCategoryStrategy(event.categoryId);
    for (final strategy in categoryStrategy) {
      suggestions.add(SmartReminderSuggestion(
        daysBefore: strategy.daysBefore,
        hour: strategy.hour,
        minute: 0,
        score: 0.7, // 默认策略基础分
        reason: strategy.reason,
      ));
    }

    // 2. 考虑事件距离
    final distanceScore = _calculateDistanceScore(event);
    if (distanceScore != null) {
      suggestions.add(distanceScore);
    }

    // 3. 基于用户历史学习
    if (includeHistory) {
      final learnedSuggestions = await _getLearnedSuggestions(event);
      for (final s in learnedSuggestions) {
        // 如果有相似的建议，更新分数
        final existingIndex = suggestions.indexWhere(
          (e) => e.daysBefore == s.daysBefore && e.hour == s.hour,
        );
        if (existingIndex >= 0) {
          suggestions[existingIndex] = SmartReminderSuggestion(
            daysBefore: s.daysBefore,
            hour: s.hour,
            minute: s.minute,
            score: (suggestions[existingIndex].score + s.score) / 2,
            reason: s.reason.isNotEmpty ? s.reason : suggestions[existingIndex].reason,
          );
        } else {
          suggestions.add(s);
        }
      }
    }

    // 4. 调整分数
    final adjustedSuggestions = _adjustScores(suggestions, event);

    // 5. 排序并返回
    adjustedSuggestions.sort((a, b) => b.score.compareTo(a.score));
    return adjustedSuggestions;
  }

  /// 生成推荐的提醒列表
  ///
  /// 返回实际可用的 Reminder 对象列表
  Future<List<Reminder>> generateReminders(
    CountdownEvent event, {
    int maxReminders = 5,
    double minScore = 0.5,
  }) async {
    final suggestions = await getSuggestions(event);
    
    // 过滤并限制数量
    final topSuggestions = suggestions
        .where((s) => s.score >= minScore)
        .take(maxReminders)
        .toList();

    // 转换为 Reminder 对象
    final reminders = <Reminder>[];
    for (final suggestion in topSuggestions) {
      final reminderDate = event.targetDate.subtract(
        Duration(days: suggestion.daysBefore),
      );
      
      // 如果提醒时间已过，跳过
      if (reminderDate.isBefore(DateTime.now())) {
        continue;
      }

      final reminderDateTime = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        suggestion.hour,
        suggestion.minute,
      );

      reminders.add(Reminder.create(
        eventId: event.id,
        reminderDateTime: reminderDateTime,
        customMessage: _generateReminderMessage(event, suggestion),
      ));
    }

    return reminders;
  }

  /// 记录用户对提醒的反馈
  ///
  /// 用于学习用户偏好
  Future<void> recordUserFeedback({
    required String eventId,
    required String categoryId,
    required int daysBefore,
    required int hour,
    required bool accepted,
  }) async {
    // 这里将用户反馈存储到数据库
    // 用于后续学习和优化建议
    // 实际存储逻辑在 intelligence_service.dart 中实现
  }

  // ==================== 辅助方法 ====================

  /// 获取分类默认策略
  List<({int daysBefore, int hour, String reason})> _getCategoryStrategy(
    String categoryId,
  ) {
    return _categoryDefaultStrategies[categoryId] ??
        _categoryDefaultStrategies['custom']!;
  }

  /// 计算基于距离的建议
  SmartReminderSuggestion? _calculateDistanceScore(CountdownEvent event) {
    final daysRemaining = event.daysRemaining;

    if (daysRemaining < 0) {
      // 已过期事件不需要提醒
      return null;
    }

    // 根据剩余时间动态调整
    if (daysRemaining <= 1) {
      return SmartReminderSuggestion(
        daysBefore: 0,
        hour: 9,
        minute: 0,
        score: 0.9,
        reason: '即将到期',
      );
    } else if (daysRemaining <= 7) {
      return SmartReminderSuggestion(
        daysBefore: 1,
        hour: 9,
        minute: 0,
        score: 0.8,
        reason: '一周内到期',
      );
    } else if (daysRemaining <= 30) {
      return SmartReminderSuggestion(
        daysBefore: 7,
        hour: 9,
        minute: 0,
        score: 0.7,
        reason: '一个月内到期',
      );
    }

    return null;
  }

  /// 基于用户历史获取建议
  Future<List<SmartReminderSuggestion>> _getLearnedSuggestions(
    CountdownEvent event,
  ) async {
    // 从数据库获取用户历史提醒设置
    // 这里简化处理，实际应该从 learned_patterns 表获取
    return [];
  }

  /// 调整分数
  List<SmartReminderSuggestion> _adjustScores(
    List<SmartReminderSuggestion> suggestions,
    CountdownEvent event,
  ) {
    final adjusted = <SmartReminderSuggestion>[];

    for (final suggestion in suggestions) {
      var score = suggestion.score;

      // 如果是重复事件，略微提高分数
      if (event.isRepeating) {
        score *= 1.1;
      }

      // 如果是置顶事件，提高分数
      if (event.isPinned) {
        score *= 1.2;
      }

      // 根据分类重要性调整
      final importance = _getEventImportance(event);
      score *= _importanceWeights[importance] ?? 1.0;

      adjusted.add(SmartReminderSuggestion(
        daysBefore: suggestion.daysBefore,
        hour: suggestion.hour,
        minute: suggestion.minute,
        score: score.clamp(0.0, 1.0),
        reason: suggestion.reason,
      ));
    }

    return adjusted;
  }

  /// 获取事件重要性
  String _getEventImportance(CountdownEvent event) {
    // 根据分类判断重要性
    if (event.categoryId == 'birthday' ||
        event.categoryId == 'anniversary') {
      return 'high';
    } else if (event.categoryId == 'exam' ||
        event.categoryId == 'work') {
      return 'medium';
    }
    return 'low';
  }

  /// 生成提醒消息
  String _generateReminderMessage(
    CountdownEvent event,
    SmartReminderSuggestion suggestion,
  ) {
    final daysRemaining = suggestion.daysBefore;

    if (daysRemaining == 0) {
      return '今天就是 ${event.title}！';
    } else if (daysRemaining == 1) {
      return '明天就是 ${event.title} 了！';
    } else if (daysRemaining <= 7) {
      return '${event.title} 还有 $daysRemaining 天';
    } else {
      return '${event.title} 还有 $daysRemaining 天';
    }
  }

  // ==================== 统计分析方法 ====================

  /// 分析用户提醒时间偏好
  ///
  /// 返回用户最常用的提醒时间设置
  Future<Map<String, dynamic>> analyzeUserReminderPatterns() async {
    final events = await _dbService.getActiveEvents();
    final allReminders = <Map<String, dynamic>>[];
    
    // 收集所有提醒数据
    final groupedReminders = await _dbService.getAllRemindersGrouped();
    for (final entry in groupedReminders.entries) {
      allReminders.addAll(entry.value);
    }

    if (allReminders.isEmpty) {
      return {'hasData': false};
    }

    // 统计分析
    final hourDistribution = <int, int>{};
    final daysBeforeDistribution = <int, int>{};
    
    for (final reminder in allReminders) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(
        reminder['reminderDateTime'] as int,
      );
      hourDistribution[dateTime.hour] = 
          (hourDistribution[dateTime.hour] ?? 0) + 1;
      
      // 计算提前天数（需要关联事件）
      // 这里简化处理
    }

    // 找出最常用的时间
    final preferredHours = hourDistribution.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'hasData': true,
      'totalReminders': allReminders.length,
      'preferredHours': preferredHours.take(3).map((e) => e.key).toList(),
      'hourDistribution': hourDistribution,
      'daysBeforeDistribution': daysBeforeDistribution,
    };
  }

  /// 获取特定分类的提醒建议
  Future<List<SmartReminderSuggestion>> getCategorySuggestions(
    String categoryId,
  ) async {
    // 获取该分类下所有事件的提醒
    final events = await _dbService.getEventsByCategory(categoryId);
    
    if (events.isEmpty) {
      // 返回默认策略
      return _getCategoryStrategy(categoryId).map((s) => SmartReminderSuggestion(
        daysBefore: s.daysBefore,
        hour: s.hour,
        minute: 0,
        score: 0.7,
        reason: s.reason,
      )).toList();
    }

    // 分析现有提醒
    final daysBeforeCount = <int, int>{};
    final hourCount = <int, int>{};
    
    final allReminders = await _dbService.getAllRemindersGrouped();
    
    for (final event in events) {
      final reminders = allReminders[event.id] ?? [];
      for (final reminder in reminders) {
        final reminderTime = DateTime.fromMillisecondsSinceEpoch(
          reminder['reminderDateTime'] as int,
        );
        final eventDate = event.targetDate;
        
        final daysBefore = eventDate.difference(reminderTime).inDays;
        daysBeforeCount[daysBefore] = (daysBeforeCount[daysBefore] ?? 0) + 1;
        hourCount[reminderTime.hour] = 
            (hourCount[reminderTime.hour] ?? 0) + 1;
      }
    }

    // 转换为建议
    final suggestions = <SmartReminderSuggestion>[];
    
    for (final entry in daysBeforeCount.entries) {
      final mostCommonHour = hourCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      final score = entry.value / events.length;
      
      suggestions.add(SmartReminderSuggestion(
        daysBefore: entry.key,
        hour: mostCommonHour,
        minute: 0,
        score: score.clamp(0.5, 0.95),
        reason: '基于您的习惯推荐',
      ));
    }

    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions.take(3).toList();
  }
}
