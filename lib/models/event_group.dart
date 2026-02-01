/// 事件分组模型
/// 
/// 用于将倒数日事件分组管理
class EventGroup {
  final String id;
  final String name;
  final String? color; // Hex color string
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventGroup({
    required this.id,
    required this.name,
    this.color,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 复制并修改
  EventGroup copyWith({
    String? id,
    String? name,
    String? color,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'sortOrder': sortOrder,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// 从 Map 创建
  factory EventGroup.fromMap(Map<String, dynamic> map) {
    return EventGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      color: map['color'] as String?,
      sortOrder: map['sortOrder'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventGroup &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
