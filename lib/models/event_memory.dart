import 'package:uuid/uuid.dart';

/// 记忆类型枚举
/// 
/// 定义事件记忆的不同类型
enum MemoryType {
  /// 照片类型
  photo,
  
  /// 故事/日记类型
  story,
  
  /// 简单备注类型
  note,
}

/// 记忆类型扩展方法
extension MemoryTypeExtension on MemoryType {
  /// 获取显示名称
  String get displayName => switch (this) {
    MemoryType.photo => '照片',
    MemoryType.story => '故事',
    MemoryType.note => '备注',
  };
  
  /// 获取图标名称
  String get iconName => switch (this) {
    MemoryType.photo => 'photo_library',
    MemoryType.story => 'auto_stories',
    MemoryType.note => 'note',
  };
}

/// 事件记忆模型
/// 
/// 用于存储与倒数日事件相关的照片、日记、备注等记忆内容。
/// 每个记忆都属于特定的事件，并按时间线组织展示。
/// 
/// 示例:
/// ```dart
/// final memory = EventMemory.create(
///   eventId: 'event-123',
///   type: MemoryType.photo,
///   content: '美好的一天',
///   imagePaths: ['/path/to/image1.jpg', '/path/to/image2.jpg'],
/// );
/// ```
class EventMemory {
  /// 记忆唯一标识符
  final String id;
  
  /// 关联的事件ID
  final String eventId;
  
  /// 记忆类型
  final MemoryType type;
  
  /// 文字内容（故事、备注或照片描述）
  final String? content;
  
  /// 图片路径列表（本地存储路径）
  /// 
  /// 支持多张照片，最多50张
  final List<String> imagePaths;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 最后更新时间
  final DateTime updatedAt;

  /// 构造函数
  const EventMemory({
    required this.id,
    required this.eventId,
    required this.type,
    this.content,
    this.imagePaths = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// 创建新记忆的工厂方法
  /// 
  /// 自动生成UUID和时间戳
  factory EventMemory.create({
    required String eventId,
    required MemoryType type,
    String? content,
    List<String>? imagePaths,
  }) {
    final now = DateTime.now();
    return EventMemory(
      id: const Uuid().v4(),
      eventId: eventId,
      type: type,
      content: content,
      imagePaths: imagePaths ?? [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 是否有图片
  bool get hasImages => imagePaths.isNotEmpty;
  
  /// 图片数量
  int get imageCount => imagePaths.length;
  
  /// 是否有文字内容
  bool get hasContent => content != null && content!.trim().isNotEmpty;

  /// 转换为Map用于数据库存储
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'type': type.index,
      'content': content,
      'imagePaths': imagePaths.join('|'), // 使用 | 分隔多个路径
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// 从Map创建实例
  factory EventMemory.fromMap(Map<String, dynamic> map) {
    return EventMemory(
      id: map['id'] as String,
      eventId: map['eventId'] as String,
      type: MemoryType.values[map['type'] as int],
      content: map['content'] as String?,
      imagePaths: (map['imagePaths'] as String?)
          ?.split('|')
          .where((path) => path.isNotEmpty)
          .toList() ?? [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  /// 复制并修改
  EventMemory copyWith({
    String? id,
    String? eventId,
    MemoryType? type,
    String? content,
    List<String>? imagePaths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventMemory(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      type: type ?? this.type,
      content: content ?? this.content,
      imagePaths: imagePaths ?? this.imagePaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 添加图片路径
  EventMemory addImage(String imagePath) {
    if (imagePaths.length >= 50) {
      throw StateError('单个记忆最多只能添加50张照片');
    }
    return copyWith(
      imagePaths: [...imagePaths, imagePath],
      updatedAt: DateTime.now(),
    );
  }

  /// 移除图片路径
  EventMemory removeImage(String imagePath) {
    return copyWith(
      imagePaths: imagePaths.where((path) => path != imagePath).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// 更新内容
  EventMemory updateContent(String? newContent) {
    return copyWith(
      content: newContent,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventMemory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EventMemory(id: $id, eventId: $eventId, type: $type, '
        'imageCount: $imageCount, createdAt: $createdAt)';
  }
}

/// 记忆验证结果
class MemoryValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? field;

  const MemoryValidationResult({
    required this.isValid,
    this.errorMessage,
    this.field,
  });

  const MemoryValidationResult.valid()
      : isValid = true,
        errorMessage = null,
        field = null;

  const MemoryValidationResult.invalid(String message, {String? fieldValue})
      : isValid = false,
        errorMessage = message,
        field = fieldValue;
}

/// 事件记忆扩展方法 - 验证
extension EventMemoryValidation on EventMemory {
  /// 验证记忆数据的有效性
  MemoryValidationResult validate() {
    // 验证事件ID
    if (eventId.isEmpty) {
      return const MemoryValidationResult.invalid(
        '事件ID不能为空',
        fieldValue: 'eventId',
      );
    }

    // 验证图片数量
    if (imagePaths.length > 50) {
      return const MemoryValidationResult.invalid(
        '单个记忆最多只能有50张照片',
        fieldValue: 'imagePaths',
      );
    }

    // 验证内容长度
    if (content != null && content!.length > 5000) {
      return const MemoryValidationResult.invalid(
        '内容长度不能超过5000个字符',
        fieldValue: 'content',
      );
    }

    // 照片类型必须有图片
    if (type == MemoryType.photo && !hasImages) {
      return const MemoryValidationResult.invalid(
        '照片类型必须包含至少一张图片',
        fieldValue: 'imagePaths',
      );
    }

    // 故事或备注类型应该有内容
    if ((type == MemoryType.story || type == MemoryType.note) && !hasContent) {
      return MemoryValidationResult.invalid(
        '${type.displayName}类型应该包含文字内容',
        fieldValue: 'content',
      );
    }

    return const MemoryValidationResult.valid();
  }

  /// 快速验证（仅检查必填字段）
  bool get isValidQuick => eventId.isNotEmpty;
}
