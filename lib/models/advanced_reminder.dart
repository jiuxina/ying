import 'package:uuid/uuid.dart';

/// 提醒类型枚举
/// 
/// 定义不同的提醒模式，满足不同场景需求
enum ReminderType {
  /// 多阶段提醒
  /// 
  /// 根据预设的时间节点发送多次提醒（如：提前1天、3天、7天、30天、90天）
  multiStage,
  
  /// 智能提醒
  /// 
  /// 根据事件重要性和距离天数自动调整提醒策略
  smart,
  
  /// 自定义提醒
  /// 
  /// 用户完全自定义提醒时间和规则
  custom,
  
  /// 循环提醒
  /// 
  /// 按固定周期重复提醒（如每天、每周、每月）
  recurring,
}

/// 提醒规则类
/// 
/// 定义具体的提醒规则，包括提醒时间、条件等
class ReminderRule {
  /// 规则ID
  final String id;
  
  /// 提前天数（负数表示提前，0表示当天，正数表示之后）
  final int daysOffset;
  
  /// 提醒时间（小时，0-23）
  final int hour;
  
  /// 提醒时间（分钟，0-59）
  final int minute;
  
  /// 是否启用
  final bool isEnabled;
  
  /// 自定义消息模板
  /// 
  /// 支持变量：{title}、{days}、{date}
  final String? customMessageTemplate;
  
  /// 优先级（1-10，10最高）
  final int priority;

  const ReminderRule({
    required this.id,
    required this.daysOffset,
    this.hour = 9,
    this.minute = 0,
    this.isEnabled = true,
    this.customMessageTemplate,
    this.priority = 5,
  });

  /// 创建新的提醒规则
  factory ReminderRule.create({
    required int daysOffset,
    int hour = 9,
    int minute = 0,
    bool isEnabled = true,
    String? customMessageTemplate,
    int priority = 5,
  }) {
    return ReminderRule(
      id: const Uuid().v4(),
      daysOffset: daysOffset,
      hour: hour,
      minute: minute,
      isEnabled: isEnabled,
      customMessageTemplate: customMessageTemplate,
      priority: priority,
    );
  }

  /// 从Map创建实例
  factory ReminderRule.fromMap(Map<String, dynamic> map) {
    return ReminderRule(
      id: map['id'] as String,
      daysOffset: map['daysOffset'] as int,
      hour: map['hour'] as int? ?? 9,
      minute: map['minute'] as int? ?? 0,
      isEnabled: (map['isEnabled'] as int?) == 1,
      customMessageTemplate: map['customMessageTemplate'] as String?,
      priority: map['priority'] as int? ?? 5,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'daysOffset': daysOffset,
      'hour': hour,
      'minute': minute,
      'isEnabled': isEnabled ? 1 : 0,
      'customMessageTemplate': customMessageTemplate,
      'priority': priority,
    };
  }

  /// 复制并修改
  ReminderRule copyWith({
    String? id,
    int? daysOffset,
    int? hour,
    int? minute,
    bool? isEnabled,
    String? customMessageTemplate,
    int? priority,
  }) {
    return ReminderRule(
      id: id ?? this.id,
      daysOffset: daysOffset ?? this.daysOffset,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isEnabled: isEnabled ?? this.isEnabled,
      customMessageTemplate: customMessageTemplate ?? this.customMessageTemplate,
      priority: priority ?? this.priority,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderRule &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// 验证规则数据的有效性
  bool validate() {
    if (hour < 0 || hour > 23) return false;
    if (minute < 0 || minute > 59) return false;
    if (priority < 1 || priority > 10) return false;
    return true;
  }

  /// 获取预设的多阶段提醒规则
  /// 
  /// 返回常用的提醒时间节点：提前1天、3天、7天、30天、90天
  static List<ReminderRule> getDefaultMultiStageRules() {
    return [
      ReminderRule.create(daysOffset: -1, hour: 9, minute: 0, priority: 8),
      ReminderRule.create(daysOffset: -3, hour: 9, minute: 0, priority: 6),
      ReminderRule.create(daysOffset: -7, hour: 9, minute: 0, priority: 5),
      ReminderRule.create(daysOffset: -30, hour: 9, minute: 0, priority: 4),
      ReminderRule.create(daysOffset: -90, hour: 9, minute: 0, priority: 3),
    ];
  }
}

/// 高级提醒类
/// 
/// 扩展基础提醒模型，支持多阶段、智能、自定义和循环提醒
class AdvancedReminder {
  /// 提醒ID
  final String id;
  
  /// 关联的事件ID
  final String eventId;
  
  /// 提醒类型
  final ReminderType type;
  
  /// 提醒规则列表
  final List<ReminderRule> rules;
  
  /// 是否启用智能模式
  /// 
  /// 启用后会根据事件重要性自动调整提醒策略
  final bool smartModeEnabled;
  
  /// 事件重要性评分（1-10）
  /// 
  /// 用于智能提醒算法
  final int importanceScore;
  
  /// 是否启用
  final bool isEnabled;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间
  final DateTime updatedAt;

  const AdvancedReminder({
    required this.id,
    required this.eventId,
    required this.type,
    this.rules = const [],
    this.smartModeEnabled = false,
    this.importanceScore = 5,
    this.isEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 创建新的高级提醒
  factory AdvancedReminder.create({
    required String eventId,
    required ReminderType type,
    List<ReminderRule>? rules,
    bool smartModeEnabled = false,
    int importanceScore = 5,
    bool isEnabled = true,
  }) {
    final now = DateTime.now();
    return AdvancedReminder(
      id: const Uuid().v4(),
      eventId: eventId,
      type: type,
      rules: rules ?? (type == ReminderType.multiStage 
          ? ReminderRule.getDefaultMultiStageRules() 
          : []),
      smartModeEnabled: smartModeEnabled,
      importanceScore: importanceScore,
      isEnabled: isEnabled,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 从Map创建实例
  factory AdvancedReminder.fromMap(Map<String, dynamic> map, {List<ReminderRule>? rules}) {
    return AdvancedReminder(
      id: map['id'] as String,
      eventId: map['eventId'] as String,
      type: ReminderType.values[map['type'] as int],
      rules: rules ?? [],
      smartModeEnabled: (map['smartModeEnabled'] as int?) == 1,
      importanceScore: map['importanceScore'] as int? ?? 5,
      isEnabled: (map['isEnabled'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'type': type.index,
      'smartModeEnabled': smartModeEnabled ? 1 : 0,
      'importanceScore': importanceScore,
      'isEnabled': isEnabled ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// 复制并修改
  AdvancedReminder copyWith({
    String? id,
    String? eventId,
    ReminderType? type,
    List<ReminderRule>? rules,
    bool? smartModeEnabled,
    int? importanceScore,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdvancedReminder(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      type: type ?? this.type,
      rules: rules ?? this.rules,
      smartModeEnabled: smartModeEnabled ?? this.smartModeEnabled,
      importanceScore: importanceScore ?? this.importanceScore,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdvancedReminder &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// 验证提醒数据的有效性
  bool validate() {
    if (eventId.isEmpty) return false;
    if (importanceScore < 1 || importanceScore > 10) return false;
    for (final rule in rules) {
      if (!rule.validate()) return false;
    }
    return true;
  }

  /// 根据目标日期计算所有提醒时间
  /// 
  /// 返回按时间排序的提醒时间列表
  List<DateTime> calculateReminderTimes(DateTime targetDate) {
    final times = <DateTime>[];
    final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);

    for (final rule in rules) {
      if (!rule.isEnabled) continue;

      final reminderDay = targetDay.add(Duration(days: rule.daysOffset));
      final reminderTime = DateTime(
        reminderDay.year,
        reminderDay.month,
        reminderDay.day,
        rule.hour,
        rule.minute,
      );

      // 只添加未来的提醒时间
      if (reminderTime.isAfter(DateTime.now())) {
        times.add(reminderTime);
      }
    }

    times.sort();
    return times;
  }
}

/// 提醒历史记录类
/// 
/// 记录每次提醒的发送情况，用于分析和优化提醒策略
class ReminderHistory {
  /// 记录ID
  final String id;
  
  /// 关联的高级提醒ID
  final String advancedReminderId;
  
  /// 关联的事件ID
  final String eventId;
  
  /// 提醒发送时间
  final DateTime sentAt;
  
  /// 计划的提醒时间
  final DateTime scheduledTime;
  
  /// 是否成功发送
  final bool isSuccessful;
  
  /// 失败原因（如果有）
  final String? failureReason;
  
  /// 提醒消息内容
  final String message;
  
  /// 规则ID（对应ReminderRule）
  final String? ruleId;

  const ReminderHistory({
    required this.id,
    required this.advancedReminderId,
    required this.eventId,
    required this.sentAt,
    required this.scheduledTime,
    required this.isSuccessful,
    this.failureReason,
    required this.message,
    this.ruleId,
  });

  /// 创建新的历史记录
  factory ReminderHistory.create({
    required String advancedReminderId,
    required String eventId,
    required DateTime scheduledTime,
    required bool isSuccessful,
    String? failureReason,
    required String message,
    String? ruleId,
  }) {
    return ReminderHistory(
      id: const Uuid().v4(),
      advancedReminderId: advancedReminderId,
      eventId: eventId,
      sentAt: DateTime.now(),
      scheduledTime: scheduledTime,
      isSuccessful: isSuccessful,
      failureReason: failureReason,
      message: message,
      ruleId: ruleId,
    );
  }

  /// 从Map创建实例
  factory ReminderHistory.fromMap(Map<String, dynamic> map) {
    return ReminderHistory(
      id: map['id'] as String,
      advancedReminderId: map['advancedReminderId'] as String,
      eventId: map['eventId'] as String,
      sentAt: DateTime.fromMillisecondsSinceEpoch(map['sentAt'] as int),
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(map['scheduledTime'] as int),
      isSuccessful: (map['isSuccessful'] as int) == 1,
      failureReason: map['failureReason'] as String?,
      message: map['message'] as String,
      ruleId: map['ruleId'] as String?,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'advancedReminderId': advancedReminderId,
      'eventId': eventId,
      'sentAt': sentAt.millisecondsSinceEpoch,
      'scheduledTime': scheduledTime.millisecondsSinceEpoch,
      'isSuccessful': isSuccessful ? 1 : 0,
      'failureReason': failureReason,
      'message': message,
      'ruleId': ruleId,
    };
  }

  /// 复制并修改
  ReminderHistory copyWith({
    String? id,
    String? advancedReminderId,
    String? eventId,
    DateTime? sentAt,
    DateTime? scheduledTime,
    bool? isSuccessful,
    String? failureReason,
    String? message,
    String? ruleId,
  }) {
    return ReminderHistory(
      id: id ?? this.id,
      advancedReminderId: advancedReminderId ?? this.advancedReminderId,
      eventId: eventId ?? this.eventId,
      sentAt: sentAt ?? this.sentAt,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      failureReason: failureReason ?? this.failureReason,
      message: message ?? this.message,
      ruleId: ruleId ?? this.ruleId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderHistory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// 计算延迟时间（毫秒）
  /// 
  /// 实际发送时间与计划时间的差值
  int get delayMs => sentAt.difference(scheduledTime).inMilliseconds;

  /// 是否为延迟发送（超过5分钟）
  bool get isDelayed => delayMs > 5 * 60 * 1000;
}

/// 智能提醒配置类
/// 
/// 定义智能提醒模式的算法参数
class SmartReminderConfig {
  /// 最小提醒天数间隔
  final int minDaysBetweenReminders;
  
  /// 重要事件的提醒密度系数（0.0-1.0）
  final double importanceDensityFactor;
  
  /// 默认提醒时间（小时）
  final int defaultHour;
  
  /// 默认提醒时间（分钟）
  final int defaultMinute;
  
  /// 是否在事件当天发送提醒
  final bool remindOnEventDay;
  
  /// 提前提醒的天数列表（按重要性递减）
  final List<int> reminderDaysByImportance;

  const SmartReminderConfig({
    this.minDaysBetweenReminders = 2,
    this.importanceDensityFactor = 0.5,
    this.defaultHour = 9,
    this.defaultMinute = 0,
    this.remindOnEventDay = true,
    this.reminderDaysByImportance = const [
      1,   // 提前1天
      3,   // 提前3天
      7,   // 提前7天
      14,  // 提前14天
      30,  // 提前30天
      60,  // 提前60天
      90,  // 提前90天
    ],
  });

  /// 默认配置
  static const SmartReminderConfig defaultConfig = SmartReminderConfig();

  /// 复制并修改
  SmartReminderConfig copyWith({
    int? minDaysBetweenReminders,
    double? importanceDensityFactor,
    int? defaultHour,
    int? defaultMinute,
    bool? remindOnEventDay,
    List<int>? reminderDaysByImportance,
  }) {
    return SmartReminderConfig(
      minDaysBetweenReminders: minDaysBetweenReminders ?? this.minDaysBetweenReminders,
      importanceDensityFactor: importanceDensityFactor ?? this.importanceDensityFactor,
      defaultHour: defaultHour ?? this.defaultHour,
      defaultMinute: defaultMinute ?? this.defaultMinute,
      remindOnEventDay: remindOnEventDay ?? this.remindOnEventDay,
      reminderDaysByImportance: reminderDaysByImportance ?? this.reminderDaysByImportance,
    );
  }
}

/// 提醒状态扩展
/// 
/// 用于表示提醒的计算结果和状态
sealed class ReminderStatus {}

/// 待发送的提醒
final class PendingReminder extends ReminderStatus {
  final DateTime scheduledTime;
  final ReminderRule rule;
  final String message;

  PendingReminder({
    required this.scheduledTime,
    required this.rule,
    required this.message,
  });
}

/// 已发送的提醒
final class SentReminder extends ReminderStatus {
  final DateTime sentTime;
  final ReminderRule rule;
  final bool wasSuccessful;

  SentReminder({
    required this.sentTime,
    required this.rule,
    required this.wasSuccessful,
  });
}

/// 已跳过的提醒
final class SkippedReminder extends ReminderStatus {
  final DateTime scheduledTime;
  final String reason;

  SkippedReminder({
    required this.scheduledTime,
    required this.reason,
  });
}
