import 'package:flutter/material.dart';

/// ============================================================================
/// Widget Theme Model - Enhanced customization for desktop widgets
/// ============================================================================

/// Widget style options
enum WidgetStyleType {
  /// Minimal style - clean and simple
  minimal,
  
  /// Card style - with subtle shadows
  card,
  
  /// Photo style - with background image
  photo,
  
  /// Gradient style - with gradient background
  gradient,
}

extension WidgetStyleTypeExtension on WidgetStyleType {
  String get displayName {
    switch (this) {
      case WidgetStyleType.minimal:
        return '极简';
      case WidgetStyleType.card:
        return '卡片';
      case WidgetStyleType.photo:
        return '图片';
      case WidgetStyleType.gradient:
        return '渐变';
    }
  }

  String get description {
    switch (this) {
      case WidgetStyleType.minimal:
        return '简洁干净，仅显示核心信息';
      case WidgetStyleType.card:
        return '带阴影的卡片风格';
      case WidgetStyleType.photo:
        return '使用自定义背景图片';
      case WidgetStyleType.gradient:
        return '双色渐变效果';
    }
  }

  IconData get icon {
    switch (this) {
      case WidgetStyleType.minimal:
        return Icons.crop_square;
      case WidgetStyleType.card:
        return Icons.style_outlined;
      case WidgetStyleType.photo:
        return Icons.image_outlined;
      case WidgetStyleType.gradient:
        return Icons.gradient;
    }
  }
}

/// Font size options for widget text
enum WidgetFontSize {
  small,
  medium,
  large,
}

extension WidgetFontSizeExtension on WidgetFontSize {
  String get displayName {
    switch (this) {
      case WidgetFontSize.small:
        return '小';
      case WidgetFontSize.medium:
        return '中';
      case WidgetFontSize.large:
        return '大';
    }
  }

  double get titleScale {
    switch (this) {
      case WidgetFontSize.small:
        return 0.85;
      case WidgetFontSize.medium:
        return 1.0;
      case WidgetFontSize.large:
        return 1.15;
    }
  }

  double get daysScale {
    switch (this) {
      case WidgetFontSize.small:
        return 0.85;
      case WidgetFontSize.medium:
        return 1.0;
      case WidgetFontSize.large:
        return 1.2;
    }
  }
}

/// Widget theme configuration
class WidgetTheme {
  /// Unique identifier
  final String id;
  
  /// Theme name
  final String name;
  
  /// Style type
  final WidgetStyleType styleType;
  
  /// Primary background color (ARGB)
  final int primaryColor;
  
  /// Secondary/gradient end color (ARGB)
  final int? secondaryColor;
  
  /// Text color (ARGB)
  final int textColor;
  
  /// Font size preference
  final WidgetFontSize fontSize;
  
  /// Background image path (for photo style)
  final String? backgroundImage;
  
  /// Background opacity (0.0 - 1.0)
  final double opacity;
  
  /// Corner radius (dp)
  final double cornerRadius;
  
  /// Show icon element
  final bool showIcon;
  
  /// Show days count
  final bool showDays;
  
  /// Show date text
  final bool showDate;
  
  /// Show title
  final bool showTitle;
  
  /// Dark mode variant colors
  final int? darkPrimaryColor;
  final int? darkSecondaryColor;
  final int? darkTextColor;
  
  const WidgetTheme({
    required this.id,
    required this.name,
    this.styleType = WidgetStyleType.minimal,
    this.primaryColor = 0xFF6366F1,
    this.secondaryColor,
    this.textColor = 0xFFFFFFFF,
    this.fontSize = WidgetFontSize.medium,
    this.backgroundImage,
    this.opacity = 1.0,
    this.cornerRadius = 16.0,
    this.showIcon = false,
    this.showDays = true,
    this.showDate = true,
    this.showTitle = true,
    this.darkPrimaryColor,
    this.darkSecondaryColor,
    this.darkTextColor,
  });

  /// Default themes
  static WidgetTheme defaultTheme() => const WidgetTheme(
    id: 'default',
    name: '默认主题',
    styleType: WidgetStyleType.minimal,
    primaryColor: 0xFF6366F1,
    textColor: 0xFFFFFFFF,
  );

  /// Preset themes
  static const List<WidgetTheme> presetThemes = [
    WidgetTheme(
      id: 'minimal_indigo',
      name: '靛蓝极简',
      styleType: WidgetStyleType.minimal,
      primaryColor: 0xFF6366F1,
      textColor: 0xFFFFFFFF,
    ),
    WidgetTheme(
      id: 'gradient_purple',
      name: '紫罗兰渐变',
      styleType: WidgetStyleType.gradient,
      primaryColor: 0xFF6366F1,
      secondaryColor: 0xFF8B5CF6,
      textColor: 0xFFFFFFFF,
    ),
    WidgetTheme(
      id: 'gradient_sunset',
      name: '日落渐变',
      styleType: WidgetStyleType.gradient,
      primaryColor: 0xFFFF6B6B,
      secondaryColor: 0xFFFFB347,
      textColor: 0xFFFFFFFF,
    ),
    WidgetTheme(
      id: 'gradient_ocean',
      name: '海洋渐变',
      styleType: WidgetStyleType.gradient,
      primaryColor: 0xFF06B6D4,
      secondaryColor: 0xFF3B82F6,
      textColor: 0xFFFFFFFF,
    ),
    WidgetTheme(
      id: 'card_green',
      name: '翠绿卡片',
      styleType: WidgetStyleType.card,
      primaryColor: 0xFF10B981,
      textColor: 0xFFFFFFFF,
    ),
    WidgetTheme(
      id: 'card_blue',
      name: '天蓝卡片',
      styleType: WidgetStyleType.card,
      primaryColor: 0xFF3B82F6,
      textColor: 0xFFFFFFFF,
    ),
    WidgetTheme(
      id: 'minimal_dark',
      name: '暗夜极简',
      styleType: WidgetStyleType.minimal,
      primaryColor: 0xFF1E293B,
      textColor: 0xFFF1F5F9,
    ),
    WidgetTheme(
      id: 'gradient_aurora',
      name: '极光渐变',
      styleType: WidgetStyleType.gradient,
      primaryColor: 0xFF14B8A6,
      secondaryColor: 0xFF8B5CF6,
      textColor: 0xFFFFFFFF,
    ),
  ];

  /// Get color for current mode
  int getPrimaryColor(bool isDark) => isDark && darkPrimaryColor != null 
      ? darkPrimaryColor! 
      : primaryColor;
  
  int getSecondaryColor(bool isDark) => isDark && darkSecondaryColor != null
      ? darkSecondaryColor!
      : secondaryColor ?? primaryColor;
  
  int getTextColor(bool isDark) => isDark && darkTextColor != null
      ? darkTextColor!
      : textColor;

  /// Get Color objects
  Color get primaryColorValue => Color(primaryColor);
  Color? get secondaryColorValue => secondaryColor != null ? Color(secondaryColor!) : null;
  Color get textColorValue => Color(textColor);

  /// Copy with modifications
  WidgetTheme copyWith({
    String? id,
    String? name,
    WidgetStyleType? styleType,
    int? primaryColor,
    int? secondaryColor,
    int? textColor,
    WidgetFontSize? fontSize,
    String? backgroundImage,
    double? opacity,
    double? cornerRadius,
    bool? showIcon,
    bool? showDays,
    bool? showDate,
    bool? showTitle,
    int? darkPrimaryColor,
    int? darkSecondaryColor,
    int? darkTextColor,
    bool clearBackgroundImage = false,
    bool clearSecondaryColor = false,
  }) {
    return WidgetTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      styleType: styleType ?? this.styleType,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: clearSecondaryColor ? null : (secondaryColor ?? this.secondaryColor),
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      backgroundImage: clearBackgroundImage ? null : (backgroundImage ?? this.backgroundImage),
      opacity: opacity ?? this.opacity,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      showIcon: showIcon ?? this.showIcon,
      showDays: showDays ?? this.showDays,
      showDate: showDate ?? this.showDate,
      showTitle: showTitle ?? this.showTitle,
      darkPrimaryColor: darkPrimaryColor ?? this.darkPrimaryColor,
      darkSecondaryColor: darkSecondaryColor ?? this.darkSecondaryColor,
      darkTextColor: darkTextColor ?? this.darkTextColor,
    );
  }

  /// Convert to map for persistence
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'styleType': styleType.name,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'textColor': textColor,
      'fontSize': fontSize.name,
      'backgroundImage': backgroundImage,
      'opacity': opacity,
      'cornerRadius': cornerRadius,
      'showIcon': showIcon,
      'showDays': showDays,
      'showDate': showDate,
      'showTitle': showTitle,
      'darkPrimaryColor': darkPrimaryColor,
      'darkSecondaryColor': darkSecondaryColor,
      'darkTextColor': darkTextColor,
    };
  }

  /// Create from map
  factory WidgetTheme.fromMap(Map<String, dynamic> map) {
    return WidgetTheme(
      id: map['id'] as String? ?? 'default',
      name: map['name'] as String? ?? '自定义主题',
      styleType: WidgetStyleType.values.firstWhere(
        (e) => e.name == map['styleType'],
        orElse: () => WidgetStyleType.minimal,
      ),
      primaryColor: map['primaryColor'] as int? ?? 0xFF6366F1,
      secondaryColor: map['secondaryColor'] as int?,
      textColor: map['textColor'] as int? ?? 0xFFFFFFFF,
      fontSize: WidgetFontSize.values.firstWhere(
        (e) => e.name == map['fontSize'],
        orElse: () => WidgetFontSize.medium,
      ),
      backgroundImage: map['backgroundImage'] as String?,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
      cornerRadius: (map['cornerRadius'] as num?)?.toDouble() ?? 16.0,
      showIcon: map['showIcon'] as bool? ?? false,
      showDays: map['showDays'] as bool? ?? true,
      showDate: map['showDate'] as bool? ?? true,
      showTitle: map['showTitle'] as bool? ?? true,
      darkPrimaryColor: map['darkPrimaryColor'] as int?,
      darkSecondaryColor: map['darkSecondaryColor'] as int?,
      darkTextColor: map['darkTextColor'] as int?,
    );
  }

  /// Convert to widget config (for backward compatibility)
  Map<String, dynamic> toWidgetConfigMap(String widgetTypeName) {
    return {
      'type': widgetTypeName,
      'style': _mapStyleType(),
      'backgroundColor': primaryColor,
      'gradientEndColor': secondaryColor,
      'opacity': opacity,
      'backgroundImage': backgroundImage,
      'showDate': showDate,
      'showTitle': showTitle,
      'showDays': showDays,
      'fontSize': fontSize.name,
      'cornerRadius': cornerRadius,
      'textColor': textColor,
    };
  }

  String _mapStyleType() {
    switch (styleType) {
      case WidgetStyleType.minimal:
        return 'standard';
      case WidgetStyleType.card:
        return 'standard';
      case WidgetStyleType.photo:
        return 'standard';
      case WidgetStyleType.gradient:
        return 'gradient';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WidgetTheme &&
        other.id == id &&
        other.styleType == styleType &&
        other.primaryColor == primaryColor &&
        other.secondaryColor == secondaryColor &&
        other.textColor == textColor &&
        other.fontSize == fontSize &&
        other.backgroundImage == backgroundImage &&
        other.opacity == opacity &&
        other.cornerRadius == cornerRadius &&
        other.showIcon == showIcon &&
        other.showDays == showDays &&
        other.showDate == showDate &&
        other.showTitle == showTitle;
  }

  @override
  int get hashCode => Object.hash(
    id,
    styleType,
    primaryColor,
    secondaryColor,
    textColor,
    fontSize,
    backgroundImage,
    opacity,
    cornerRadius,
    showIcon,
    showDays,
    showDate,
    showTitle,
  );
}

/// WidgetType is defined in widget_config.dart
