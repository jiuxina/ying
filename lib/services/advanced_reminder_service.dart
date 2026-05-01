import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../models/advanced_reminder.dart';
import '../models/countdown_event.dart';
import '../models/reminder.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'debug_service.dart';

/// 高级提醒服务
/// 
/// 提供多阶段提醒、智能提醒和自定义提醒规则的管理功能。
/// 扩展基础通知服务，支持更复杂的提醒场景。
class AdvancedReminderService {
  static final AdvancedReminderService _instance = AdvancedReminderService._internal();
  factory AdvancedReminderService() => _instance;
  AdvancedReminderService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final DebugService _debugService = DebugService();
  
  /// 智能提醒配置
  SmartReminderConfig _smartConfig = const SmartReminderConfig();
  
  /// 获取当前智能提醒配置
  SmartReminderConfig get smartConfig => _smartConfig;
  
  /// 设置智能提醒配置
  void setSmartConfig(SmartReminderConfig config) {
    _smartConfig = config;
    _debugService.info('Smart reminder config updated', source: 'AdvancedReminder');
  }

  // ==================== 高级提醒 CRUD ====================

  /// 创建高级提醒
  /// 
  /// 根据事件和提醒类型创建相应的高级提醒配置
  Future<AdvancedReminder> createAdvancedReminder({
    required String eventId,
    required ReminderType type,
    List<ReminderRule>? customRules,
    bool smartModeEnabled = false,
    int importanceScore = 5,
  }) async {
    final reminder = AdvancedReminder.create(
      eventId: eventId,
      type: type,
      rules: customRules,
      smartModeEnabled: smartModeEnabled,
      importanceScore: importanceScore,
    );

    if (!reminder.validate()) {
      throw ArgumentError('Invalid reminder data');
    }

    final db = await _databaseService.database;
    
    // 插入高级提醒主记录
    await db.insert(
      'advanced_reminders',
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 插入关联的提醒规则
    for (final rule in reminder.rules) {
      await db.insert(
        'reminder_rules',
        {
          ...rule.toMap(),
          'advancedReminderId': reminder.id,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    _debugService.info(
      'Created advanced reminder: ${reminder.id} for event: $eventId',
      source: 'AdvancedReminder',
    );

    return reminder;
  }

  /// 获取事件的高级提醒配置
  Future<AdvancedReminder?> getAdvancedReminder(String eventId) async {
    final db = await _databaseService.database;
    
    final results = await db.query(
      'advanced_reminders',
      where: 'eventId = ?',
      whereArgs: [eventId],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final reminderMap = results.first;
    final reminderId = reminderMap['id'] as String;

    // 获取关联的规则
    final rulesResults = await db.query(
      'reminder_rules',
      where: 'advancedReminderId = ?',
      whereArgs: [reminderId],
      orderBy: 'daysOffset DESC',
    );

    final rules = rulesResults
        .map((map) => ReminderRule.fromMap(map))
        .toList();

    return AdvancedReminder.fromMap(reminderMap, rules: rules);
  }

  /// 更新高级提醒
  Future<void> updateAdvancedReminder(AdvancedReminder reminder) async {
    if (!reminder.validate()) {
      throw ArgumentError('Invalid reminder data');
    }

    final db = await _databaseService.database;
    final now = DateTime.now();
    
    final updatedReminder = reminder.copyWith(updatedAt: now);

    // 更新主记录
    await db.update(
      'advanced_reminders',
      updatedReminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );

    // 删除旧规则
    await db.delete(
      'reminder_rules',
      where: 'advancedReminderId = ?',
      whereArgs: [reminder.id],
    );

    // 插入新规则
    for (final rule in updatedReminder.rules) {
      await db.insert(
        'reminder_rules',
        {
          ...rule.toMap(),
          'advancedReminderId': updatedReminder.id,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    _debugService.info(
      'Updated advanced reminder: ${reminder.id}',
      source: 'AdvancedReminder',
    );
  }

  /// 删除高级提醒
  Future<void> deleteAdvancedReminder(String reminderId) async {
    final db = await _databaseService.database;
    
    await db.delete(
      'advanced_reminders',
      where: 'id = ?',
      whereArgs: [reminderId],
    );

    // 关联的规则会通过外键级联删除（如果设置了CASCADE）
    // 否则手动删除
    await db.delete(
      'reminder_rules',
      where: 'advancedReminderId = ?',
      whereArgs: [reminderId],
    );

    _debugService.info(
      'Deleted advanced reminder: $reminderId',
      source: 'AdvancedReminder',
    );
  }

  /// 删除事件的所有高级提醒
  Future<void> deleteEventAdvancedReminders(String eventId) async {
    final db = await _databaseService.database;
    
    // 获取该事件的所有高级提醒ID
    final reminders = await db.query(
      'advanced_reminders',
      columns: ['id'],
      where: 'eventId = ?',
      whereArgs: [eventId],
    );

    for (final reminder in reminders) {
      await deleteAdvancedReminder(reminder['id'] as String);
    }
  }

  // ==================== 智能提醒逻辑 ====================

  /// 计算智能提醒规则
  /// 
  /// 根据事件重要性和距离天数自动生成提醒规则
  List<ReminderRule> calculateSmartReminderRules({
    required int importanceScore,
    required int daysUntilEvent,
    SmartReminderConfig? config,
  }) {
    final effectiveConfig = config ?? _smartConfig;
    final rules = <ReminderRule>[];

    // 根据重要性计算应该激活的提醒天数
    // 重要性越高，提醒密度越大
    final activeDays = _selectActiveReminderDays(
      importanceScore: importanceScore,
      daysUntilEvent: daysUntilEvent,
      config: effectiveConfig,
    );

    // 为每个激活的天数创建规则
    for (final days in activeDays) {
      // 只为未来的日期创建规则
      if (days <= daysUntilEvent) {
        rules.add(ReminderRule.create(
          daysOffset: -days,
          hour: effectiveConfig.defaultHour,
          minute: effectiveConfig.defaultMinute,
          priority: _calculatePriorityForDay(days, importanceScore),
        ));
      }
    }

    // 如果配置为在事件当天提醒
    if (effectiveConfig.remindOnEventDay && daysUntilEvent >= 0) {
      rules.add(ReminderRule.create(
        daysOffset: 0,
        hour: effectiveConfig.defaultHour,
        minute: effectiveConfig.defaultMinute,
        priority: 10, // 最高优先级
      ));
    }

    rules.sort((a, b) => b.daysOffset.compareTo(a.daysOffset));
    return rules;
  }

  /// 选择激活的提醒天数
  /// 
  /// 根据重要性和最小间隔筛选合适的提醒时间点
  List<int> _selectActiveReminderDays({
    required int importanceScore,
    required int daysUntilEvent,
    required SmartReminderConfig config,
  }) {
    final activeDays = <int>[];
    
    // 计算激活比例：重要性越高，激活的提醒越多
    final activationRatio = config.importanceDensityFactor * (importanceScore / 10.0);
    
    for (final day in config.reminderDaysByImportance) {
      // 根据激活比例和随机因素决定是否激活
      // 使用确定性算法：基于天数和重要性的哈希
      final hash = '$day-$importanceScore'.hashCode;
      final threshold = (hash % 100) / 100.0;
      
      if (threshold < activationRatio && day <= daysUntilEvent) {
        // 检查最小间隔
        if (activeDays.isEmpty || 
            (activeDays.last - day) >= config.minDaysBetweenReminders) {
          activeDays.add(day);
        }
      }
    }

    return activeDays;
  }

  /// 计算特定天数的规则优先级
  int _calculatePriorityForDay(int days, int importanceScore) {
    // 距离越近，优先级越高
    // 重要性越高，优先级也越高
    final distanceFactor = days <= 1 ? 10 : (days <= 7 ? 8 : (days <= 30 ? 6 : 4));
    final importanceFactor = importanceScore ~/ 2;
    
    return ((distanceFactor + importanceFactor) / 2).round().clamp(1, 10);
  }

  // ==================== 提醒调度 ====================

  /// 为事件调度高级提醒
  /// 
  /// 将高级提醒规则转换为实际的通知调度
  Future<void> scheduleAdvancedReminders(
    CountdownEvent event,
    AdvancedReminder advancedReminder,
  ) async {
    if (!advancedReminder.isEnabled) {
      _debugService.info(
        'Advanced reminder is disabled for event: ${event.id}',
        source: 'AdvancedReminder',
      );
      return;
    }

    // 取消该事件的旧通知
    await _notificationService.cancelEventNotifications(event.id);

    // 计算提醒时间
    final reminderTimes = advancedReminder.calculateReminderTimes(event.targetDate);

    // 创建基础提醒对象并调度
    for (int i = 0; i < reminderTimes.length && i < advancedReminder.rules.length; i++) {
      final time = reminderTimes[i];
      final rule = advancedReminder.rules[i];

      // 创建基础提醒对象用于兼容现有通知系统
      final basicReminder = Reminder.create(
        eventId: event.id,
        reminderDateTime: time,
        customMessage: _generateReminderMessage(event, rule, time),
      );

      // 保存到基础提醒表（兼容现有系统）
      await _databaseService.insertReminder(basicReminder.toMap());
    }

    // 获取事件的所有提醒并调度通知
    final remindersData = await _databaseService.getReminders(event.id);
    final reminders = remindersData
        .map((map) => Reminder.fromMap(map))
        .toList();

    // 使用事件副本调度通知
    final eventWithReminders = event.copyWith(reminders: reminders);
    await _notificationService.scheduleEventReminders(eventWithReminders);

    _debugService.info(
      'Scheduled ${reminderTimes.length} advanced reminders for event: ${event.title}',
      source: 'AdvancedReminder',
    );
  }

  /// 生成提醒消息
  /// 
  /// 根据规则和事件信息生成个性化的提醒消息
  String _generateReminderMessage(
    CountdownEvent event,
    ReminderRule rule,
    DateTime reminderTime,
  ) {
    // 如果规则有自定义模板，使用模板
    if (rule.customMessageTemplate != null && rule.customMessageTemplate!.isNotEmpty) {
      return _applyMessageTemplate(
        rule.customMessageTemplate!,
        event,
        reminderTime,
      );
    }

    // 否则生成默认消息
    final daysRemaining = event.targetDate.difference(reminderTime).inDays;
    
    if (daysRemaining == 0) {
      return '🎉 今天就是 ${event.title} 的日子！';
    } else if (daysRemaining == 1) {
      return '⏰ 明天就是 ${event.title} 了！还有1天';
    } else if (daysRemaining <= 7) {
      return '📅 ${event.title} 还有 $daysRemaining 天';
    } else if (daysRemaining <= 30) {
      return '📆 ${event.title} 还有 $daysRemaining 天';
    } else {
      return '🗓️ ${event.title} 还有 $daysRemaining 天';
    }
  }

  /// 应用消息模板
  String _applyMessageTemplate(
    String template,
    CountdownEvent event,
    DateTime reminderTime,
  ) {
    final daysRemaining = event.targetDate.difference(reminderTime).inDays;
    
    return template
        .replaceAll('{title}', event.title)
        .replaceAll('{days}', daysRemaining.toString())
        .replaceAll('{date}', event.targetDate.toString().split(' ')[0]);
  }

  // ==================== 提醒历史管理 ====================

  /// 记录提醒发送历史
  Future<void> recordReminderHistory(ReminderHistory history) async {
    final db = await _databaseService.database;
    
    await db.insert(
      'reminder_history',
      history.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _debugService.info(
      'Recorded reminder history: ${history.id}',
      source: 'AdvancedReminder',
    );
  }

  /// 批量记录提醒历史
  Future<void> recordReminderHistories(List<ReminderHistory> histories) async {
    final db = await _databaseService.database;
    
    final batch = db.batch();
    for (final history in histories) {
      batch.insert(
        'reminder_history',
        history.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();

    _debugService.info(
      'Recorded ${histories.length} reminder histories',
      source: 'AdvancedReminder',
    );
  }

  /// 获取事件的提醒历史
  Future<List<ReminderHistory>> getEventReminderHistory(String eventId) async {
    final db = await _databaseService.database;
    
    final results = await db.query(
      'reminder_history',
      where: 'eventId = ?',
      whereArgs: [eventId],
      orderBy: 'scheduledTime DESC',
    );

    return results.map((map) => ReminderHistory.fromMap(map)).toList();
  }

  /// 获取高级提醒的历史记录
  Future<List<ReminderHistory>> getAdvancedReminderHistory(String advancedReminderId) async {
    final db = await _databaseService.database;
    
    final results = await db.query(
      'reminder_history',
      where: 'advancedReminderId = ?',
      whereArgs: [advancedReminderId],
      orderBy: 'scheduledTime DESC',
    );

    return results.map((map) => ReminderHistory.fromMap(map)).toList();
  }

  /// 获取最近的提醒历史
  Future<List<ReminderHistory>> getRecentReminderHistory({
    int limit = 50,
    bool successfulOnly = false,
  }) async {
    final db = await _databaseService.database;
    
    String whereClause = successfulOnly ? 'isSuccessful = 1' : '1=1';
    
    final results = await db.query(
      'reminder_history',
      where: whereClause,
      orderBy: 'sentAt DESC',
      limit: limit,
    );

    return results.map((map) => ReminderHistory.fromMap(map)).toList();
  }

  /// 清理过期的提醒历史
  /// 
  /// 删除指定天数之前的记录
  Future<int> cleanupOldReminderHistory({int daysToKeep = 90}) async {
    final db = await _databaseService.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    final count = await db.delete(
      'reminder_history',
      where: 'sentAt < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );

    _debugService.info(
      'Cleaned up $count old reminder history records',
      source: 'AdvancedReminder',
    );

    return count;
  }

  /// 获取提醒统计信息
  Future<Map<String, dynamic>> getReminderStatistics(String eventId) async {
    final history = await getEventReminderHistory(eventId);
    
    if (history.isEmpty) {
      return {
        'totalCount': 0,
        'successfulCount': 0,
        'failedCount': 0,
        'successRate': 0.0,
        'averageDelay': 0.0,
      };
    }

    final successfulCount = history.where((h) => h.isSuccessful).length;
    final failedCount = history.length - successfulCount;
    final averageDelay = history
        .where((h) => h.isSuccessful)
        .map((h) => h.delayMs)
        .fold<int>(0, (sum, delay) => sum + delay) / successfulCount;

    return {
      'totalCount': history.length,
      'successfulCount': successfulCount,
      'failedCount': failedCount,
      'successRate': successfulCount / history.length,
      'averageDelay': averageDelay,
    };
  }

  // ==================== 批量操作 ====================

  /// 为事件自动创建智能提醒
  /// 
  /// 根据事件属性自动生成合适的提醒规则
  Future<AdvancedReminder> createSmartReminderForEvent(CountdownEvent event) async {
    // 计算事件重要性
    final importance = _calculateEventImportance(event);
    
    // 计算距离天数
    final daysUntilEvent = event.daysRemaining;
    
    // 生成智能规则
    final smartRules = calculateSmartReminderRules(
      importanceScore: importance,
      daysUntilEvent: daysUntilEvent,
    );

    // 创建高级提醒
    return await createAdvancedReminder(
      eventId: event.id,
      type: ReminderType.smart,
      customRules: smartRules,
      smartModeEnabled: true,
      importanceScore: importance,
    );
  }

  /// 计算事件重要性评分
  /// 
  /// 基于多个因素评估事件的重要性
  int _calculateEventImportance(CountdownEvent event) {
    int score = 5; // 基础分

    // 分类权重
    final categoryWeights = {
      'birthday': 3,      // 生日最重要
      'anniversary': 3,   // 纪念日也很重要
      'exam': 2,          // 考试较重要
      'work': 2,          // 工作较重要
      'holiday': 1,       // 节假日一般
      'travel': 1,        // 旅行一般
      'custom': 0,        // 自定义无额外权重
    };
    score += categoryWeights[event.categoryId] ?? 0;

    // 是否置顶
    if (event.isPinned) score += 2;

    // 是否重复事件（年度重要事件）
    if (event.isRepeating) score += 1;

    // 距离时间（越近越重要）
    final days = event.daysRemaining;
    if (days <= 7) score += 2;
    else if (days <= 30) score += 1;

    // 有备注说明通常更重要
    if (event.note != null && event.note!.isNotEmpty) score += 1;

    return score.clamp(1, 10);
  }

  /// 重新调度所有高级提醒
  /// 
  /// 用于应用启动或时区变更后恢复提醒
  Future<void> rescheduleAllAdvancedReminders(List<CountdownEvent> events) async {
    _debugService.info(
      'Rescheduling all advanced reminders for ${events.length} events',
      source: 'AdvancedReminder',
    );

    for (final event in events) {
      try {
        final advancedReminder = await getAdvancedReminder(event.id);
        if (advancedReminder != null && advancedReminder.isEnabled) {
          await scheduleAdvancedReminders(event, advancedReminder);
        }
      } catch (e) {
        _debugService.error(
          'Failed to reschedule advanced reminder for event ${event.id}: $e',
          source: 'AdvancedReminder',
        );
      }
    }
  }

  // ==================== 提醒规则管理 ====================

  /// 添加提醒规则到现有高级提醒
  Future<void> addReminderRule(
    String advancedReminderId,
    ReminderRule rule,
  ) async {
    final reminder = await _getAdvancedReminderById(advancedReminderId);
    if (reminder == null) {
      throw ArgumentError('Advanced reminder not found: $advancedReminderId');
    }

    final updatedRules = [...reminder.rules, rule];
    await updateAdvancedReminder(reminder.copyWith(rules: updatedRules));
  }

  /// 从高级提醒中移除规则
  Future<void> removeReminderRule(
    String advancedReminderId,
    String ruleId,
  ) async {
    final reminder = await _getAdvancedReminderById(advancedReminderId);
    if (reminder == null) {
      throw ArgumentError('Advanced reminder not found: $advancedReminderId');
    }

    final updatedRules = reminder.rules.where((r) => r.id != ruleId).toList();
    await updateAdvancedReminder(reminder.copyWith(rules: updatedRules));
  }

  /// 更新提醒规则
  Future<void> updateReminderRule(
    String advancedReminderId,
    ReminderRule updatedRule,
  ) async {
    final reminder = await _getAdvancedReminderById(advancedReminderId);
    if (reminder == null) {
      throw ArgumentError('Advanced reminder not found: $advancedReminderId');
    }

    final updatedRules = reminder.rules.map((r) {
      return r.id == updatedRule.id ? updatedRule : r;
    }).toList();
    
    await updateAdvancedReminder(reminder.copyWith(rules: updatedRules));
  }

  /// 通过ID获取高级提醒
  Future<AdvancedReminder?> _getAdvancedReminderById(String id) async {
    final db = await _databaseService.database;
    
    final results = await db.query(
      'advanced_reminders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final reminderMap = results.first;
    
    final rulesResults = await db.query(
      'reminder_rules',
      where: 'advancedReminderId = ?',
      whereArgs: [id],
      orderBy: 'daysOffset DESC',
    );

    final rules = rulesResults
        .map((map) => ReminderRule.fromMap(map))
        .toList();

    return AdvancedReminder.fromMap(reminderMap, rules: rules);
  }

  // ==================== 工具方法 ====================

  /// 检查提醒是否即将到期
  /// 
  /// 返回即将在指定小时内触发的提醒列表
  Future<List<Map<String, dynamic>>> getUpcomingReminders({int hoursAhead = 24}) async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    final futureTime = now.add(Duration(hours: hoursAhead));

    // 从基础提醒表查询即将到期的提醒
    final results = await db.query(
      'event_reminders',
      where: 'reminderDateTime >= ? AND reminderDateTime <= ?',
      whereArgs: [
        now.millisecondsSinceEpoch,
        futureTime.millisecondsSinceEpoch,
      ],
      orderBy: 'reminderDateTime ASC',
    );

    return results;
  }

  /// 获取所有启用高级提醒的事件ID列表
  Future<List<String>> getEventsWithAdvancedReminders() async {
    final db = await _databaseService.database;
    
    final results = await db.query(
      'advanced_reminders',
      columns: ['eventId'],
      where: 'isEnabled = 1',
    );

    return results.map((map) => map['eventId'] as String).toList();
  }
}
