import 'dart:ui';
import 'widget_theme.dart';

/// ============================================================================
/// 小部件类型枚举（简化版 - 仅支持2种尺寸）
/// ============================================================================

enum WidgetType {
  /// 迷你小部件 (1x1) - 仅显示天数
  mini,
  
  /// 标准小部件 (2x2) - 单事件显示
  standard,
  
  /// 大型小部件 (4x2) - 主事件 + 事件列表
  large,
}

/// 小部件类型扩展方法
extension WidgetTypeExtension on WidgetType {
  String get displayName {
    switch (this) {
      case WidgetType.mini:
        return '迷你 (1×1)';
      case WidgetType.standard:
        return '标准 (2×2)';
      case WidgetType.large:
        return '大型 (4×2)';
    }
  }

  String get description {
    switch (this) {
      case WidgetType.mini:
        return '仅显示天数，极致简洁';
      case WidgetType.standard:
        return '显示单个倒计时事件';
      case WidgetType.large:
        return '主事件 + 更多事件列表';
    }
  }

  String get providerName {
    switch (this) {
      case WidgetType.mini:
        return 'CountdownMiniWidgetReceiver';
      case WidgetType.standard:
        return 'CountdownWidgetReceiver';
      case WidgetType.large:
        return 'CountdownLargeWidgetReceiver';
    }
  }

  /// 获取对应的存储key前缀
  String get configPrefix => 'widget_$name';
  
  /// Get widget size in dp
  (int width, int height) get defaultSize {
    switch (this) {
      case WidgetType.mini:
        return (40, 40);
      case WidgetType.standard:
        return (110, 110);
      case WidgetType.large:
        return (250, 110);
    }
  }
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
  
  /// 是否显示标题
  final bool showTitle;
  
  /// 是否显示天数
  final bool showDays;
  
  /// 是否显示图标
  final bool showIcon;
  
  /// 字体大小
  final WidgetFontSize fontSize;
  
  /// 圆角半径
  final double cornerRadius;
  
  /// 文字颜色
  final int textColor;
  
  /// 主题ID（用于关联WidgetTheme）
  final String? themeId;

  const WidgetConfig({
    required this.type,
    this.style = WidgetStyle.standard,
    this.backgroundColor = 0xFF6366F1,
    this.gradientEndColor,
    this.opacity = 1.0,
    this.backgroundImage,
    this.showDate = true,
    this.showTitle = true,
    this.showDays = true,
    this.showIcon = false,
    this.fontSize = WidgetFontSize.medium,
    this.cornerRadius = 16.0,
    this.textColor = 0xFFFFFFFF,
    this.themeId,
  });

  /// 默认配置
  static WidgetConfig defaultFor(WidgetType type) {
    return WidgetConfig(
      type: type,
      showDate: true,
      showTitle: true,
      showDays: true,
    );
  }

  /// 从 WidgetTheme 创建配置
  factory WidgetConfig.fromTheme(WidgetType type, WidgetTheme theme) {
    return WidgetConfig(
      type: type,
      style: _mapStyleType(theme.styleType),
      backgroundColor: theme.primaryColor,
      gradientEndColor: theme.secondaryColor,
      opacity: theme.opacity,
      backgroundImage: theme.backgroundImage,
      showDate: theme.showDate,
      showTitle: theme.showTitle,
      showDays: theme.showDays,
      showIcon: theme.showIcon,
      fontSize: theme.fontSize,
      cornerRadius: theme.cornerRadius,
      textColor: theme.textColor,
      themeId: theme.id,
    );
  }

  static WidgetStyle _mapStyleType(WidgetStyleType styleType) {
    switch (styleType) {
      case WidgetStyleType.minimal:
      case WidgetStyleType.card:
      case WidgetStyleType.photo:
        return WidgetStyle.standard;
      case WidgetStyleType.gradient:
        return WidgetStyle.gradient;
    }
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
    bool? showTitle,
    bool? showDays,
    bool? showIcon,
    WidgetFontSize? fontSize,
    double? cornerRadius,
    int? textColor,
    String? themeId,
    bool clearBackgroundImage = false,
    bool clearGradientEndColor = false,
  }) {
    return WidgetConfig(
      type: type ?? this.type,
      style: style ?? this.style,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gradientEndColor: clearGradientEndColor ? null : (gradientEndColor ?? this.gradientEndColor),
      opacity: opacity ?? this.opacity,
      backgroundImage: clearBackgroundImage ? null : (backgroundImage ?? this.backgroundImage),
      showDate: showDate ?? this.showDate,
      showTitle: showTitle ?? this.showTitle,
      showDays: showDays ?? this.showDays,
      showIcon: showIcon ?? this.showIcon,
      fontSize: fontSize ?? this.fontSize,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      textColor: textColor ?? this.textColor,
      themeId: themeId ?? this.themeId,
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
      'showTitle': showTitle,
      'showDays': showDays,
      'showIcon': showIcon,
      'fontSize': fontSize.name,
      'cornerRadius': cornerRadius,
      'textColor': textColor,
      'themeId': themeId,
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
      showTitle: map['showTitle'] as bool? ?? true,
      showDays: map['showDays'] as bool? ?? true,
      showIcon: map['showIcon'] as bool? ?? false,
      fontSize: WidgetFontSize.values.firstWhere(
        (e) => e.name == map['fontSize'],
        orElse: () => WidgetFontSize.medium,
      ),
      cornerRadius: (map['cornerRadius'] as num?)?.toDouble() ?? 16.0,
      textColor: map['textColor'] as int? ?? 0xFFFFFFFF,
      themeId: map['themeId'] as String?,
    );
  }

  /// 获取颜色对象
  Color get color => Color(backgroundColor);
  
  /// 获取渐变结束颜色对象
  Color? get gradientEnd => gradientEndColor != null ? Color(gradientEndColor!) : null;
  
  /// 获取文字颜色对象
  Color get textColorValue => Color(textColor);

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
        other.showDate == showDate &&
        other.showTitle == showTitle &&
        other.showDays == showDays &&
        other.showIcon == showIcon &&
        other.fontSize == fontSize &&
        other.cornerRadius == cornerRadius &&
        other.textColor == textColor &&
        other.themeId == themeId;
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
    showTitle,
    showDays,
    showIcon,
    fontSize,
    cornerRadius,
    textColor,
    themeId,
  );
}
