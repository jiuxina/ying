import 'reminder.dart';

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
      reminders: [], // Reminders are loaded separately
    );
  }
}

