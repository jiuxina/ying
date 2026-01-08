import 'category_model.dart';
import 'reminder.dart';
import 'event_category.dart'; // Deprecated but maybe used elsewhere?

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
  /// 对于倒数日：从创建日期到目标日期的进度
  /// 对于正数日：固定返回100%
  double get progressPercentage {
    if (isCountUp) return 1.0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final created = DateTime(createdAt.year, createdAt.month, createdAt.day);
    
    final totalDays = target.difference(created).inDays;
    if (totalDays <= 0) return 1.0;
    
    final passedDays = today.difference(created).inDays;
    final progress = passedDays / totalDays;
    return progress.clamp(0.0, 1.0);
  }

  /// 是否已过期
  bool get isExpired => daysRemaining < 0 && !isCountUp;

  /// 复制并修改
  CountdownEvent copyWith({
    String? id,
    String? title,
    String? note,
    DateTime? targetDate,
    bool? isLunar,
    String? lunarDateStr,
    String? categoryId,
    bool? isCountUp,
    bool? isRepeating,
    bool? isPinned,
    bool? isArchived,
    String? backgroundImage,
    bool? enableBlur,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? enableNotification,
    int? notifyDaysBefore,
    int? notifyHour,
    int? notifyMinute,
    String? groupId,
    List<Reminder>? reminders,
  }) {
    return CountdownEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      targetDate: targetDate ?? this.targetDate,
      isLunar: isLunar ?? this.isLunar,
      lunarDateStr: lunarDateStr ?? this.lunarDateStr,
      categoryId: categoryId ?? this.categoryId,
      isCountUp: isCountUp ?? this.isCountUp,
      isRepeating: isRepeating ?? this.isRepeating,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      enableBlur: enableBlur ?? this.enableBlur,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      enableNotification: enableNotification ?? this.enableNotification,
      notifyDaysBefore: notifyDaysBefore ?? this.notifyDaysBefore,
      notifyHour: notifyHour ?? this.notifyHour,
      notifyMinute: notifyMinute ?? this.notifyMinute,
      groupId: groupId ?? this.groupId,
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

