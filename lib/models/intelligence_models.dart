import 'package:uuid/uuid.dart';

/// 用户行为模式类型
enum PatternType {
  reminderTime, // 提醒时间偏好
  categoryPreference, // 分类偏好
  eventTiming, // 事件时间模式
  notificationBehavior, // 通知行为
  seasonalEvent, // 季节性事件
}

/// 用户学习到的模式
class LearnedPattern {
  final String id;
  final PatternType type;
  final String key; // 模式标识（如 "birthday_reminder_days"）
  final Map<String, dynamic> data; // 模式数据
  final int confidence; // 置信度 0-100
  final int sampleCount; // 样本数量
  final DateTime firstObserved;
  final DateTime lastObserved;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LearnedPattern({
    required this.id,
    required this.type,
    required this.key,
    required this.data,
    this.confidence = 0,
    this.sampleCount = 0,
    required this.firstObserved,
    required this.lastObserved,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LearnedPattern.create({
    required PatternType type,
    required String key,
    required Map<String, dynamic> data,
  }) {
    final now = DateTime.now();
    return LearnedPattern(
      id: const Uuid().v4(),
      type: type,
      key: key,
      data: data,
      confidence: 10, // 初始低置信度
      sampleCount: 1,
      firstObserved: now,
      lastObserved: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'key': key,
      'data': _encodeData(data),
      'confidence': confidence,
      'sampleCount': sampleCount,
      'firstObserved': firstObserved.millisecondsSinceEpoch,
      'lastObserved': lastObserved.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory LearnedPattern.fromMap(Map<String, dynamic> map) {
    return LearnedPattern(
      id: map['id'] as String,
      type: PatternType.values[map['type'] as int],
      key: map['key'] as String,
      data: _decodeData(map['data'] as String),
      confidence: map['confidence'] as int,
      sampleCount: map['sampleCount'] as int,
      firstObserved: DateTime.fromMillisecondsSinceEpoch(
        map['firstObserved'] as int,
      ),
      lastObserved: DateTime.fromMillisecondsSinceEpoch(
        map['lastObserved'] as int,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  LearnedPattern copyWith({
    String? id,
    PatternType? type,
    String? key,
    Map<String, dynamic>? data,
    int? confidence,
    int? sampleCount,
    DateTime? firstObserved,
    DateTime? lastObserved,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LearnedPattern(
      id: id ?? this.id,
      type: type ?? this.type,
      key: key ?? this.key,
      data: data ?? this.data,
      confidence: confidence ?? this.confidence,
      sampleCount: sampleCount ?? this.sampleCount,
      firstObserved: firstObserved ?? this.firstObserved,
      lastObserved: lastObserved ?? this.lastObserved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 更新模式数据（增加样本）
  LearnedPattern updateWithNewSample(Map<String, dynamic> newData) {
    final newSampleCount = sampleCount + 1;
    
    // 使用指数移动平均更新置信度
    // 每次新样本增加置信度，但增幅递减
    final confidenceIncrement = (100 - confidence) * 0.1;
    final newConfidence = (confidence + confidenceIncrement).round().clamp(0, 100);
    
    return copyWith(
      data: _mergeData(data, newData),
      confidence: newConfidence,
      sampleCount: newSampleCount,
      lastObserved: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static String _encodeData(Map<String, dynamic> data) {
    // Simple JSON encoding
    return data.entries
        .map((e) => '${e.key}:${e.value}')
        .join(';');
  }

  static Map<String, dynamic> _decodeData(String encoded) {
    if (encoded.isEmpty) return {};
    final map = <String, dynamic>{};
    for (final pair in encoded.split(';')) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final value = parts[1];
        // Try to parse as int, double, or bool
        if (value == 'true') {
          map[parts[0]] = true;
        } else if (value == 'false') {
          map[parts[0]] = false;
        } else {
          final intValue = int.tryParse(value);
          if (intValue != null) {
            map[parts[0]] = intValue;
          } else {
            final doubleValue = double.tryParse(value);
            if (doubleValue != null) {
              map[parts[0]] = doubleValue;
            } else {
              map[parts[0]] = value;
            }
          }
        }
      }
    }
    return map;
  }

  static Map<String, dynamic> _mergeData(
    Map<String, dynamic> existing,
    Map<String, dynamic> newData,
  ) {
    // Simple merge strategy: average numeric values, keep latest for others
    final merged = Map<String, dynamic>.from(existing);
    for (final entry in newData.entries) {
      if (merged.containsKey(entry.key)) {
        final existingValue = merged[entry.key];
        final newValue = entry.value;
        
        if (existingValue is num && newValue is num) {
          // Average numeric values
          merged[entry.key] = (existingValue + newValue) / 2;
        } else {
          merged[entry.key] = newValue;
        }
      } else {
        merged[entry.key] = entry.value;
      }
    }
    return merged;
  }
}

/// 智能建议结果
class SmartSuggestion {
  final String suggestionId;
  final SuggestionType type;
  final String title;
  final String? description;
  final double confidence; // 0.0 - 1.0
  final Map<String, dynamic> data;
  final String? reason; // 解释为什么提出此建议

  const SmartSuggestion({
    required this.suggestionId,
    required this.type,
    required this.title,
    this.description,
    this.confidence = 0.5,
    this.data = const {},
    this.reason,
  });
}

/// 建议类型
enum SuggestionType {
  category, // 分类建议
  reminder, // 提醒建议
  date, // 日期建议
  tag, // 标签建议
  duplicate, // 重复事件检测
  holiday, // 节假日建议
}

/// 自然语言解析结果
class ParsedEventInput {
  final String? title;
  final DateTime? targetDate;
  final bool isLunar;
  final String? lunarDateStr;
  final String? categoryId;
  final bool? isRepeating;
  final double confidence;
  final List<String> warnings; // 解析警告
  final Map<String, dynamic> rawExtracted; // 原始提取的数据

  const ParsedEventInput({
    this.title,
    this.targetDate,
    this.isLunar = false,
    this.lunarDateStr,
    this.categoryId,
    this.isRepeating,
    this.confidence = 0.0,
    this.warnings = const [],
    this.rawExtracted = const {},
  });

  bool get hasResult =>
      title != null ||
      targetDate != null ||
      categoryId != null;

  String get summary {
    final parts = <String>[];
    if (title != null) parts.add('标题: $title');
    if (targetDate != null) {
      parts.add('日期: ${_formatDate(targetDate!)}');
    }
    if (categoryId != null) parts.add('分类: $categoryId');
    if (isRepeating == true) parts.add('每年重复');
    return parts.join(', ');
  }

  static String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}

/// 智能提醒建议
class SmartReminderSuggestion {
  final int daysBefore; // 提前几天
  final int hour; // 提醒时间（小时）
  final int minute; // 提醒时间（分钟）
  final double score; // 推荐分数 0.0 - 1.0
  final String reason; // 推荐理由

  const SmartReminderSuggestion({
    required this.daysBefore,
    required this.hour,
    required this.minute,
    required this.score,
    required this.reason,
  });
}

/// 事件统计信息
class EventStatistics {
  final int totalEvents;
  final int activeEvents;
  final int archivedEvents;
  final Map<String, int> categoryDistribution;
  final Map<int, int> hourlyDistribution; // 按小时分布（创建时间）
  final Map<int, int> weeklyDistribution; // 按星期分布
  final Map<int, int> monthlyDistribution; // 按月份分布
  final double avgRemindersPerEvent;
  final double repeatingEventRatio;

  const EventStatistics({
    this.totalEvents = 0,
    this.activeEvents = 0,
    this.archivedEvents = 0,
    this.categoryDistribution = const {},
    this.hourlyDistribution = const {},
    this.weeklyDistribution = const {},
    this.monthlyDistribution = const {},
    this.avgRemindersPerEvent = 0.0,
    this.repeatingEventRatio = 0.0,
  });
}

/// 重复事件检测结果
class DuplicateCheckResult {
  final bool isDuplicate;
  final List<DuplicateMatch> matches;
  final double highestSimilarity;

  const DuplicateCheckResult({
    this.isDuplicate = false,
    this.matches = const [],
    this.highestSimilarity = 0.0,
  });
}

/// 重复匹配详情
class DuplicateMatch {
  final String eventId;
  final String eventTitle;
  final double similarity;
  final DuplicateType duplicateType;

  const DuplicateMatch({
    required this.eventId,
    required this.eventTitle,
    required this.similarity,
    required this.duplicateType,
  });
}

/// 重复类型
enum DuplicateType {
  exact, // 完全相同
  similar, // 相似
  sameDate, // 同一日期
  similarTitle, // 相似标题
}

/// 智能功能设置
class IntelligenceSettings {
  final bool enabled;
  final bool smartReminders;
  final bool smartCategorization;
  final bool naturalLanguageInput;
  final bool duplicateDetection;
  final bool holidayDetection;
  final bool seasonalSuggestions;
  final bool learnFromBehavior;
  final int minConfidenceThreshold; // 最小置信度阈值 0-100

  const IntelligenceSettings({
    this.enabled = true,
    this.smartReminders = true,
    this.smartCategorization = true,
    this.naturalLanguageInput = true,
    this.duplicateDetection = true,
    this.holidayDetection = true,
    this.seasonalSuggestions = true,
    this.learnFromBehavior = true,
    this.minConfidenceThreshold = 50,
  });

  IntelligenceSettings copyWith({
    bool? enabled,
    bool? smartReminders,
    bool? smartCategorization,
    bool? naturalLanguageInput,
    bool? duplicateDetection,
    bool? holidayDetection,
    bool? seasonalSuggestions,
    bool? learnFromBehavior,
    int? minConfidenceThreshold,
  }) {
    return IntelligenceSettings(
      enabled: enabled ?? this.enabled,
      smartReminders: smartReminders ?? this.smartReminders,
      smartCategorization: smartCategorization ?? this.smartCategorization,
      naturalLanguageInput: naturalLanguageInput ?? this.naturalLanguageInput,
      duplicateDetection: duplicateDetection ?? this.duplicateDetection,
      holidayDetection: holidayDetection ?? this.holidayDetection,
      seasonalSuggestions: seasonalSuggestions ?? this.seasonalSuggestions,
      learnFromBehavior: learnFromBehavior ?? this.learnFromBehavior,
      minConfidenceThreshold:
          minConfidenceThreshold ?? this.minConfidenceThreshold,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'smartReminders': smartReminders,
      'smartCategorization': smartCategorization,
      'naturalLanguageInput': naturalLanguageInput,
      'duplicateDetection': duplicateDetection,
      'holidayDetection': holidayDetection,
      'seasonalSuggestions': seasonalSuggestions,
      'learnFromBehavior': learnFromBehavior,
      'minConfidenceThreshold': minConfidenceThreshold,
    };
  }

  factory IntelligenceSettings.fromMap(Map<String, dynamic> map) {
    return IntelligenceSettings(
      enabled: map['enabled'] as bool? ?? true,
      smartReminders: map['smartReminders'] as bool? ?? true,
      smartCategorization: map['smartCategorization'] as bool? ?? true,
      naturalLanguageInput: map['naturalLanguageInput'] as bool? ?? true,
      duplicateDetection: map['duplicateDetection'] as bool? ?? true,
      holidayDetection: map['holidayDetection'] as bool? ?? true,
      seasonalSuggestions: map['seasonalSuggestions'] as bool? ?? true,
      learnFromBehavior: map['learnFromBehavior'] as bool? ?? true,
      minConfidenceThreshold:
          map['minConfidenceThreshold'] as int? ?? 50,
    );
  }
}
