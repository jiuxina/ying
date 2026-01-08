import 'dart:ui';

/// ============================================================================
/// 小部件类型枚举（简化版 - 仅支持2种尺寸）
/// ============================================================================

enum WidgetType {
  /// 标准小部件 (2x2) - 单事件显示
  standard,
  
  /// 大型小部件 (4x2) - 主事件 + 事件列表
  large,
}

/// 小部件类型扩展方法
extension WidgetTypeExtension on WidgetType {
  String get displayName {
    switch (this) {
      case WidgetType.standard:
        return '标准 (2×2)';
      case WidgetType.large:
        return '大型 (4×2)';
    }
  }

  String get description {
    switch (this) {
      case WidgetType.standard:
        return '显示单个倒计时事件';
      case WidgetType.large:
        return '主事件 + 更多事件列表';
    }
  }

  String get providerName {
    switch (this) {
      case WidgetType.standard:
        return 'CountdownWidgetReceiver';
      case WidgetType.large:
        return 'CountdownLargeWidgetReceiver';
    }
  }

  /// 获取对应的存储key前缀
  String get configPrefix => 'widget_$name';
}

/// ============================================================================
/// 小部件样式枚举
/// ============================================================================

enum WidgetStyle {
  /// 标准纯色
  standard,
  
  /// 渐变效果
  gradient,
  
  /// 毛玻璃效果
  glassmorphism,
}

extension WidgetStyleExtension on WidgetStyle {
  String get displayName {
    switch (this) {
      case WidgetStyle.standard:
        return '纯色';
      case WidgetStyle.gradient:
        return '渐变';
      case WidgetStyle.glassmorphism:
        return '毛玻璃';
    }
  }
}

/// ============================================================================
/// 小部件配置模型
/// ============================================================================

class WidgetConfig {
  /// 小部件类型
  final WidgetType type;
  
  /// 样式
  final WidgetStyle style;
  
  /// 背景色（ARGB整数）
  final int backgroundColor;
  
  /// 渐变结束色（用于gradient样式）
  final int? gradientEndColor;
  
  /// 透明度 (0.0 - 1.0)
  final double opacity;
  
  /// 背景图片路径
  final String? backgroundImage;
  
  /// 是否显示目标日期
  final bool showDate;

  const WidgetConfig({
    required this.type,
    this.style = WidgetStyle.standard,
    this.backgroundColor = 0xFF6366F1,
    this.gradientEndColor,
    this.opacity = 1.0,
    this.backgroundImage,
    this.showDate = true,
  });

  /// 默认配置
  static WidgetConfig defaultFor(WidgetType type) {
    return WidgetConfig(
      type: type,
      showDate: true,
    );
  }

  /// 复制并修改
  WidgetConfig copyWith({
    WidgetType? type,
    WidgetStyle? style,
    int? backgroundColor,
    int? gradientEndColor,
    double? opacity,
    String? backgroundImage,
    bool? showDate,
  }) {
    return WidgetConfig(
      type: type ?? this.type,
      style: style ?? this.style,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gradientEndColor: gradientEndColor ?? this.gradientEndColor,
      opacity: opacity ?? this.opacity,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      showDate: showDate ?? this.showDate,
    );
  }

  /// 转换为Map（用于持久化）
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'style': style.name,
      'backgroundColor': backgroundColor,
      'gradientEndColor': gradientEndColor,
      'opacity': opacity,
      'backgroundImage': backgroundImage,
      'showDate': showDate,
    };
  }

  /// 从Map创建实例
  factory WidgetConfig.fromMap(Map<String, dynamic> map) {
    return WidgetConfig(
      type: WidgetType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => WidgetType.standard,
      ),
      style: WidgetStyle.values.firstWhere(
        (e) => e.name == map['style'],
        orElse: () => WidgetStyle.standard,
      ),
      backgroundColor: map['backgroundColor'] as int? ?? 0xFF6366F1,
      gradientEndColor: map['gradientEndColor'] as int?,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
      backgroundImage: map['backgroundImage'] as String?,
      showDate: map['showDate'] as bool? ?? true,
    );
  }

  /// 获取颜色对象
  Color get color => Color(backgroundColor);
  
  /// 获取渐变结束颜色对象
  Color? get gradientEnd => gradientEndColor != null ? Color(gradientEndColor!) : null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WidgetConfig &&
        other.type == type &&
        other.style == style &&
        other.backgroundColor == backgroundColor &&
        other.gradientEndColor == gradientEndColor &&
        other.opacity == opacity &&
        other.backgroundImage == backgroundImage &&
        other.showDate == showDate;
  }

  @override
  int get hashCode => Object.hash(
    type,
    style,
    backgroundColor,
    gradientEndColor,
    opacity,
    backgroundImage,
    showDate,
  );
}
