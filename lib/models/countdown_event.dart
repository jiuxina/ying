import 'reminder.dart';

/// 事件验证结果
class EventValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? field;

  // ignore: unused_element
  const EventValidationResult._({
    required this.isValid,
    // ignore: unused_element_parameter
    this.errorMessage,
    // ignore: unused_element_parameter
    this.field,
  });

  const EventValidationResult.valid() : isValid = true, errorMessage = null, field = null;

  const EventValidationResult.invalid(this.errorMessage, {this.field}) : isValid = false;
}

/// 倒数日事件模型
class CountdownEvent {
  final String id;
  final String title;
  final String? note; // 备注
  final DateTime targetDate;
  final bool isLunar; // 是否为农历日期
  final String? lunarDateStr; // 农历日期字符串
  final String categoryId; // Changed from EventCategory to String ID
  final bool isCountUp; // true: 正数日, false: 倒数日
  final bool isRepeating; // 每年重复
  final bool isPinned; // 置顶
  final bool isArchived; // 归档
  final String? backgroundImage; // 背景图片路径
  final bool enableBlur; // 启用模糊效果
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // 通知设置
  final bool enableNotification;
  final int notifyDaysBefore; // 提前几天提醒
  final int notifyHour; // 提醒时间（小时）
  final int notifyMinute; // 提醒时间（分钟）
  final String? groupId; // 所属分组ID
  final bool isPrivate; // 是否为私密事件

  CountdownEvent({
    required this.id,
    required this.title,
    this.note,
    required this.targetDate,
    this.isLunar = false,
    this.lunarDateStr,
    this.categoryId = 'custom', // Default
    this.isCountUp = false,
    this.isRepeating = false,
    this.isPinned = false,
    this.isArchived = false,
    this.backgroundImage,
    this.enableBlur = false,
    required this.createdAt,
    required this.updatedAt,
    this.enableNotification = false,
    this.notifyDaysBefore = 1,
    this.notifyHour = 9,
    this.notifyMinute = 0,
    this.groupId,
    this.reminders = const [],
    this.isPrivate = false,
  });
  
  // existing fields...
  final List<Reminder> reminders;

  /// 计算剩余/已过天数
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return target.difference(today).inDays;
  }

  /// 计算进度百分比（用于进度条）
  /// 对于倒数日：返回剩余时间百分比 (100% → 0%)
  /// 对于正数日：固定返回0%（已完成）
  double get progressPercentage {
    if (isCountUp) return 0.0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final created = DateTime(createdAt.year, createdAt.month, createdAt.day);
    
    final totalDays = target.difference(created).inDays;
    if (totalDays <= 0) return 0.0;
    
    final passedDays = today.difference(created).inDays;
    final progress = 1.0 - (passedDays / totalDays); // 剩余百分比 = 1 - 已过百分比
    return progress.clamp(0.0, 1.0);
  }

  /// 是否已过期
  bool get isExpired => daysRemaining < 0 && !isCountUp;

  // 用于 copyWith 的哨兵值，表示"保持原值"
  static const Object _sentinel = Object();

  /// 复制并修改
  /// 
  /// 注意：对于 nullable 字段 (note, groupId, backgroundImage 等)：
  /// - 不传参数或传 _sentinel: 保持原值
  /// - 显式传 null: 设置为 null
  /// - 传其他值: 使用新值
  CountdownEvent copyWith({
    String? id,
    String? title,
    Object? note = _sentinel,
    DateTime? targetDate,
    bool? isLunar,
    Object? lunarDateStr = _sentinel,
    String? categoryId,
    bool? isCountUp,
    bool? isRepeating,
    bool? isPinned,
    bool? isArchived,
    Object? backgroundImage = _sentinel,
    bool? enableBlur,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? enableNotification,
    int? notifyDaysBefore,
    int? notifyHour,
    int? notifyMinute,
    Object? groupId = _sentinel,
    List<Reminder>? reminders,
    bool? isPrivate,
  }) {
    return CountdownEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note == _sentinel ? this.note : note as String?,
      targetDate: targetDate ?? this.targetDate,
      isLunar: isLunar ?? this.isLunar,
      lunarDateStr: lunarDateStr == _sentinel ? this.lunarDateStr : lunarDateStr as String?,
      categoryId: categoryId ?? this.categoryId,
      isCountUp: isCountUp ?? this.isCountUp,
      isRepeating: isRepeating ?? this.isRepeating,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      backgroundImage: backgroundImage == _sentinel ? this.backgroundImage : backgroundImage as String?,
      enableBlur: enableBlur ?? this.enableBlur,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      enableNotification: enableNotification ?? this.enableNotification,
      notifyDaysBefore: notifyDaysBefore ?? this.notifyDaysBefore,
      notifyHour: notifyHour ?? this.notifyHour,
      notifyMinute: notifyMinute ?? this.notifyMinute,
      groupId: groupId == _sentinel ? this.groupId : groupId as String?,
      reminders: reminders ?? this.reminders,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }

  /// 转换为 Map（用于数据库存储）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'targetDate': targetDate.millisecondsSinceEpoch,
      'isLunar': isLunar ? 1 : 0,
      'lunarDateStr': lunarDateStr,
      'category': categoryId, // Storing ID
      'isCountUp': isCountUp ? 1 : 0,
      'isRepeating': isRepeating ? 1 : 0,
      'isPinned': isPinned ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
      'backgroundImage': backgroundImage,
      'enableBlur': enableBlur ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'enableNotification': enableNotification ? 1 : 0,
      'notifyDaysBefore': notifyDaysBefore,
      'notifyHour': notifyHour,
      'notifyMinute': notifyMinute,
      'groupId': groupId,
      'isPrivate': isPrivate ? 1 : 0,
    };
  }

  /// 从 Map 创建实例
  factory CountdownEvent.fromMap(Map<String, dynamic> map) {
    return CountdownEvent(
      id: map['id'] as String,
      title: map['title'] as String,
      note: map['note'] as String?,
      targetDate: DateTime.fromMillisecondsSinceEpoch(map['targetDate'] as int),
      isLunar: (map['isLunar'] as int) == 1,
      lunarDateStr: map['lunarDateStr'] as String?,
      categoryId: map['category'] as String? ?? 'custom', // Load ID
      isCountUp: (map['isCountUp'] as int) == 1,
      isRepeating: (map['isRepeating'] as int) == 1,
      isPinned: (map['isPinned'] as int) == 1,
      isArchived: (map['isArchived'] as int) == 1,
      backgroundImage: map['backgroundImage'] as String?,
      enableBlur: (map['enableBlur'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      enableNotification: (map['enableNotification'] as int) == 1,
      notifyDaysBefore: map['notifyDaysBefore'] as int? ?? 1,
      notifyHour: map['notifyHour'] as int? ?? 9,
      notifyMinute: map['notifyMinute'] as int? ?? 0,
      groupId: map['groupId'] as String?,
      isPrivate: (map['isPrivate'] as int?) == 1,
      reminders: [], // Reminders are loaded separately
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountdownEvent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  // ==================== 验证方法 ====================

  /// 验证事件数据的有效性
  /// 
  /// 返回验证结果，包含是否有效和错误信息
  EventValidationResult validate() {
    // 验证标题
    if (title.trim().isEmpty) {
      return const EventValidationResult.invalid('标题不能为空', field: 'title');
    }
    if (title.length > 100) {
      return const EventValidationResult.invalid('标题长度不能超过100个字符', field: 'title');
    }

    // 验证备注长度
    if (note != null && note!.length > 1000) {
      return const EventValidationResult.invalid('备注长度不能超过1000个字符', field: 'note');
    }

    // 验证目标日期
    if (isLunar) {
      // 农历日期需要 lunarDateStr
      if (lunarDateStr == null || lunarDateStr!.isEmpty) {
        return const EventValidationResult.invalid('农历日期不能为空', field: 'lunarDateStr');
      }
    } else {
      // 公历日期验证
      // 对于倒数日，允许过去日期（显示为已过期）
      // 对于正数日，过去日期是正常的
    }

    // 验证分类ID
    if (categoryId.isEmpty) {
      return const EventValidationResult.invalid('请选择一个分类', field: 'categoryId');
    }

    // 验证通知设置
    if (enableNotification) {
      if (notifyDaysBefore < 0 || notifyDaysBefore > 365) {
        return const EventValidationResult.invalid('提前天数必须在0-365之间', field: 'notifyDaysBefore');
      }
      if (notifyHour < 0 || notifyHour > 23) {
        return const EventValidationResult.invalid('小时必须在0-23之间', field: 'notifyHour');
      }
      if (notifyMinute < 0 || notifyMinute > 59) {
        return const EventValidationResult.invalid('分钟必须在0-59之间', field: 'notifyMinute');
      }
    }

    // 验证提醒列表
    if (reminders.length > 10) {
      return const EventValidationResult.invalid('最多只能设置10个提醒', field: 'reminders');
    }

    // 验证提醒时间
    for (final reminder in reminders) {
      if (reminder.reminderDateTime.isAfter(targetDate) && !isCountUp) {
        return EventValidationResult.invalid(
          '提醒时间不能晚于目标日期',
          field: 'reminders',
        );
      }
    }

    return const EventValidationResult.valid();
  }

  /// 快速验证（仅检查必填字段）
  bool get isValidQuick {
    return title.trim().isNotEmpty && categoryId.isNotEmpty;
  }

  /// 验证并抛出异常
  void validateOrThrow() {
    final result = validate();
    if (!result.isValid) {
      throw ArgumentError('${result.field ?? "字段"}: ${result.errorMessage}');
    }
  }
}

