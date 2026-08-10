import 'dart:convert';

/// 小部件元素的显隐策略；`follow` 表示沿用现有开关与紧凑尺寸规则。
enum WidgetElementVisible {
  follow,
  show,
  hide;
}

/// 小部件元素字号档位，叠加在全局字号缩放之上。
enum WidgetElementSize {
  small,
  normal,
  large,
  xlarge;

  double get multiplier => switch (this) {
    WidgetElementSize.small => 0.8,
    WidgetElementSize.normal => 1.0,
    WidgetElementSize.large => 1.25,
    WidgetElementSize.xlarge => 1.5,
  };
}

/// 小部件文字颜色来源。
enum WidgetColorMode {
  primary,
  secondary,
  custom;
}

/// 小部件文字水平对齐；内联元素不提供对齐选项。
enum WidgetAlign {
  start,
  center,
  end;
}

/// 单事件小部件整体垂直布局。
enum WidgetVerticalAlign {
  top,
  center,
  bottom;
}

/// 单个小部件元素的样式；元素 ID 见设置页与原生渲染的角色清单。
class WidgetElementStyle {
  const WidgetElementStyle({
    this.visible = WidgetElementVisible.follow,
    this.size = WidgetElementSize.normal,
    this.sizeScale = 1.0,
    this.weight = 0,
    this.colorMode = WidgetColorMode.primary,
    this.color = -1,
    this.align = WidgetAlign.start,
  });

  final WidgetElementVisible visible;
  final WidgetElementSize size;
  final double sizeScale;
  final int weight;
  final WidgetColorMode colorMode;
  final int color;
  final WidgetAlign align;

  WidgetElementStyle copyWith({
    WidgetElementVisible? visible,
    WidgetElementSize? size,
    double? sizeScale,
    int? weight,
    WidgetColorMode? colorMode,
    int? color,
    WidgetAlign? align,
  }) {
    return WidgetElementStyle(
      visible: visible ?? this.visible,
      size: size ?? this.size,
      sizeScale: sizeScale ?? this.sizeScale,
      weight: weight ?? this.weight,
      colorMode: colorMode ?? this.colorMode,
      color: color ?? this.color,
      align: align ?? this.align,
    );
  }

  Map<String, Object> toJson() => {
    'visible': visible.name,
    'size': size.name,
    'sizeScale': sizeScale,
    'weight': weight,
    'colorMode': colorMode.name,
    'color': color,
    'align': align.name,
  };

  factory WidgetElementStyle.fromJson(Map<String, Object?> json) {
    return WidgetElementStyle(
      visible: _enumByName(
        WidgetElementVisible.values,
        json['visible'],
        WidgetElementVisible.follow,
      ),
      size: _enumByName(
        WidgetElementSize.values,
        json['size'],
        WidgetElementSize.normal,
      ),
      sizeScale: (json['sizeScale'] as num?)?.toDouble() ??
          _legacySizeScale(json['size']),
      weight: ((json['weight'] as num?)?.clamp(0, 900) ?? 0).toInt(),
      colorMode: _enumByName(
        WidgetColorMode.values,
        json['colorMode'],
        WidgetColorMode.primary,
      ),
      color: (json['color'] as int?) ?? -1,
      align: _enumByName(
        WidgetAlign.values,
        json['align'],
        WidgetAlign.start,
      ),
    );
  }
}

double _legacySizeScale(Object? name) {
  for (final value in WidgetElementSize.values) {
    if (value.name == name) return value.multiplier;
  }
  return 1.0;
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  if (name is String) {
    for (final value in values) {
      if (value.name == name) return value;
    }
  }
  return fallback;
}

/// 把元素样式表编码为协议 JSON；旧数据缺省时由解析方回退默认样式。
String encodeWidgetElementStyles(Map<String, WidgetElementStyle> styles) {
  return jsonEncode({
    for (final entry in styles.entries) entry.key: entry.value.toJson(),
  });
}

/// 解析协议 JSON；空值或损坏数据统一回退空配置。
Map<String, WidgetElementStyle> decodeWidgetElementStyles(Object? raw) {
  if (raw is! String || raw.isEmpty) return const {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return const {};
    final result = <String, WidgetElementStyle>{};
    decoded.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result[key] = WidgetElementStyle.fromJson(value);
      }
    });
    return result;
  } catch (_) {
    return const {};
  }
}
