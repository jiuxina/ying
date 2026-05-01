/// ============================================================================
/// 事件模板模型
/// ============================================================================

/// 模板字段定义
/// 
/// 定义模板中可预填充的字段及其属性
class TemplateField {
  /// 字段名称（对应 CountdownEvent 字段）
  final String name;
  
  /// 显示名称
  final String displayName;
  
  /// 默认值
  final dynamic defaultValue;
  
  /// 是否必填
  final bool isRequired;
  
  /// 字段描述
  final String? description;

  const TemplateField({
    required this.name,
    required this.displayName,
    this.defaultValue,
    this.isRequired = false,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'displayName': displayName,
      'defaultValue': defaultValue,
      'isRequired': isRequired,
      'description': description,
    };
  }

  factory TemplateField.fromMap(Map<String, dynamic> map) {
    return TemplateField(
      name: map['name'] as String,
      displayName: map['displayName'] as String,
      defaultValue: map['defaultValue'],
      isRequired: map['isRequired'] as bool? ?? false,
      description: map['description'] as String?,
    );
  }
}

/// 模板特殊功能
enum TemplateFeature {
  /// 自动计算年龄（生日模板）
  autoAgeCalculation,
  
  /// 农历日期自动转换
  lunarDateConversion,
  
  /// 动态标题更新（如"30岁生日"）
  dynamicTitle,
  
  /// 每年重复
  yearlyRepeat,
}

/// 事件模板
/// 
/// 用于快速创建常用类型的倒数日事件
class EventTemplate {
  /// 模板ID
  final String id;
  
  /// 模板名称
  final String name;
  
  /// 模板描述
  final String? description;
  
  /// 模板分类（生日、纪念日、考试等）
  final String category;
  
  /// 模板图标（emoji）
  final String icon;
  
  /// 预填充的默认值
  final Map<String, dynamic> defaultValues;
  
  /// 是否为内置模板
  final bool isBuiltIn;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间
  final DateTime updatedAt;
  
  /// 使用次数
  final int usageCount;
  
  /// 特殊功能标识
  final List<TemplateFeature> features;

  const EventTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.icon,
    required this.defaultValues,
    this.isBuiltIn = false,
    required this.createdAt,
    required this.updatedAt,
    this.usageCount = 0,
    this.features = const [],
  });

  /// 复制并修改
  EventTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? icon,
    Map<String, dynamic>? defaultValues,
    bool? isBuiltIn,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? usageCount,
    List<TemplateFeature>? features,
  }) {
    return EventTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      defaultValues: defaultValues ?? this.defaultValues,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      usageCount: usageCount ?? this.usageCount,
      features: features ?? this.features,
    );
  }

  /// 转换为 Map（用于数据库存储）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'icon': icon,
      'defaultValues': _encodeDefaultValues(defaultValues),
      'isBuiltIn': isBuiltIn ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'usageCount': usageCount,
      'features': features.map((f) => f.index).toList(),
    };
  }

  /// 从 Map 创建实例
  factory EventTemplate.fromMap(Map<String, dynamic> map) {
    return EventTemplate(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String,
      icon: map['icon'] as String,
      defaultValues: _decodeDefaultValues(map['defaultValues'] as String?),
      isBuiltIn: (map['isBuiltIn'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      usageCount: map['usageCount'] as int? ?? 0,
      features: _decodeFeatures(map['features']),
    );
  }

  /// 转换为 JSON（用于导入导出）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'icon': icon,
      'defaultValues': defaultValues,
      'isBuiltIn': isBuiltIn,
      'features': features.map((f) => f.name).toList(),
    };
  }

  /// 从 JSON 创建实例
  factory EventTemplate.fromJson(Map<String, dynamic> json) {
    return EventTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      icon: json['icon'] as String,
      defaultValues: Map<String, dynamic>.from(json['defaultValues'] as Map),
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      usageCount: json['usageCount'] as int? ?? 0,
      features: _decodeFeaturesFromNames(json['features'] as List?),
    );
  }

  /// 编码默认值为 JSON 字符串
  static String _encodeDefaultValues(Map<String, dynamic> values) {
    // 简单实现：将 Map 转为 JSON 字符串
    return values.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');
  }

  /// 解码默认值
  static Map<String, dynamic> _decodeDefaultValues(String? encoded) {
    if (encoded == null || encoded.isEmpty) return {};
    
    final result = <String, dynamic>{};
    for (final part in encoded.split('|')) {
      final idx = part.indexOf(':');
      if (idx > 0) {
        final key = part.substring(0, idx);
        final strValue = part.substring(idx + 1);
        dynamic value = strValue;
        
        // 类型转换
        if (strValue == 'true') {
          value = true;
        } else if (strValue == 'false') {
          value = false;
        } else if (int.tryParse(strValue) != null) {
          value = int.parse(strValue);
        }
        
        result[key] = value;
      }
    }
    return result;
  }

  /// 解码功能列表
  static List<TemplateFeature> _decodeFeatures(dynamic value) {
    if (value == null) return [];
    
    final indices = value is String 
        ? value.split(',').map(int.tryParse).whereType<int>().toList()
        : (value as List).cast<int>();
    
    return indices
        .where((i) => i < TemplateFeature.values.length)
        .map((i) => TemplateFeature.values[i])
        .toList();
  }

  /// 从名称列表解码功能
  static List<TemplateFeature> _decodeFeaturesFromNames(List? names) {
    if (names == null) return [];
    
    return names
        .map((name) {
          try {
            return TemplateFeature.values.firstWhere(
              (f) => f.name == name,
              orElse: () => TemplateFeature.autoAgeCalculation,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<TemplateFeature>()
        .toList();
  }

  /// 验证模板数据
  bool validate() {
    if (name.isEmpty || name.length > 50) return false;
    if (category.isEmpty) return false;
    if (icon.isEmpty) return false;
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 模板分类
class TemplateCategory {
  final String id;
  final String name;
  final String icon;
  final int sortOrder;

  const TemplateCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.sortOrder = 0,
  });

  /// 内置分类列表
  static const List<TemplateCategory> builtInCategories = [
    TemplateCategory(id: 'birthday', name: '生日', icon: '🎂', sortOrder: 0),
    TemplateCategory(id: 'anniversary', name: '纪念日', icon: '💑', sortOrder: 1),
    TemplateCategory(id: 'exam', name: '考试', icon: '📚', sortOrder: 2),
    TemplateCategory(id: 'holiday', name: '节日', icon: '🎉', sortOrder: 3),
    TemplateCategory(id: 'work', name: '工作', icon: '💼', sortOrder: 4),
    TemplateCategory(id: 'travel', name: '旅行', icon: '✈️', sortOrder: 5),
    TemplateCategory(id: 'life', name: '生活', icon: '🏠', sortOrder: 6),
    TemplateCategory(id: 'custom', name: '自定义', icon: '⭐', sortOrder: 99),
  ];
}
