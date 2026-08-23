import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'countdown_event.dart';
import 'widget_element_style.dart';
import 'widget_holiday.dart';
import '../utils/widget_element_style_utils.dart';

/// 渲染协议版本；每次变更元素解析规则或 JSON 结构时递增。
const widgetRenderProtocolVersion = 10;

/// 小部件元素清单，顺序即协议输出顺序。
const widgetRenderElementIds = <String>[
  'category',
  'holidayBadge',
  'title',
  'days',
  'unit',
  'note',
  'precise',
  'dateInfo',
  'progress',
  'icon',
  'listHeader',
  'rowTitle',
  'rowSubtitle',
  'rowDays',
  'rowUnit',
  'empty',
  'prevButton',
  'nextButton',
];

/// 默认使用主色的元素；其余元素默认使用次要色。
const widgetPrimaryRenderElementIds = <String>{
  'title',
  'days',
  'icon',
  'rowTitle',
  'rowDays',
};

enum WidgetRenderMode { single, list }

/// 单个元素的最终渲染配置。
class WidgetElementRender {
  const WidgetElementRender({
    required this.visible,
    required this.color,
    required this.size,
    required this.align,
    this.weight = 0,
  });

  final bool visible;
  final int color;
  final double size;
  final WidgetAlign align;
  final int weight;

  Map<String, Object?> toJson() => {
    'visible': visible,
    'color': color,
    'size': size,
    'align': align.name,
    if (weight != 0) 'weight': weight,
  };

  factory WidgetElementRender.fromJson(Map<String, dynamic> json) {
    return WidgetElementRender(
      visible: json['visible'] as bool? ?? false,
      color: json['color'] as int? ?? 0xFFFFFFFF,
      size: (json['size'] as num?)?.toDouble() ?? 1.0,
      align: WidgetAlign.values.firstWhere(
        (value) => value.name == json['align'],
        orElse: () => WidgetAlign.start,
      ),
      weight: ((json['weight'] as num?)?.clamp(0, 900) ?? 0).toInt(),
    );
  }
}

/// 一个尺寸分支（紧凑/完整）的渲染配置。
class WidgetRenderBranch {
  const WidgetRenderBranch({required this.mode, required this.elements});

  final WidgetRenderMode mode;
  final Map<String, WidgetElementRender> elements;

  WidgetElementRender element(String id) =>
      elements[id] ?? const WidgetElementRender(
        visible: false,
        color: 0xFFFFFFFF,
        size: 1.0,
        align: WidgetAlign.start,
        weight: 0,
      );

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    'elements': {
      for (final id in widgetRenderElementIds)
        if (elements[id] != null) id: elements[id]!.toJson(),
    },
  };

  factory WidgetRenderBranch.fromJson(Map<String, dynamic> json) {
    final rawElements = json['elements'] as Map<String, dynamic>? ?? const {};
    return WidgetRenderBranch(
      mode: WidgetRenderMode.values.firstWhere(
        (value) => value.name == json['mode'],
        orElse: () => WidgetRenderMode.single,
      ),
      elements: {
        for (final entry in rawElements.entries)
          if (entry.value is Map<String, dynamic>)
            entry.key: WidgetElementRender.fromJson(
              entry.value as Map<String, dynamic>,
            ),
      },
    );
  }
}

class WidgetRenderTexts {
  const WidgetRenderTexts({
    required this.title,
    required this.category,
    required this.days,
    required this.unit,
  });

  final String title;
  final String category;
  final String days;
  final String unit;

  Map<String, Object?> toJson() => {
    'title': title,
    'category': category,
    'days': days,
    'unit': unit,
  };

  factory WidgetRenderTexts.fromJson(Map<String, dynamic> json) {
    return WidgetRenderTexts(
      title: json['title'] as String? ?? '添加一个倒数日',
      category: json['category'] as String? ?? '萤',
      days: json['days'] as String? ?? '--',
      unit: json['unit'] as String? ?? '天',
    );
  }
}

/// 桌面小部件渲染配置；compact/full 两个分支分别对应小号/中号。
class WidgetRenderSpec {
  const WidgetRenderSpec({
    required this.version,
    required this.style,
    required this.verticalAlign,
    required this.eventOrder,
    required this.texts,
    required this.compact,
    required this.full,
    this.contentMargin = 16.0,
  });

  final int version;
  final String style;
  final WidgetVerticalAlign verticalAlign;
  final List<String> eventOrder;
  final WidgetRenderTexts texts;
  final WidgetRenderBranch compact;
  final WidgetRenderBranch full;
  final double contentMargin;

  WidgetRenderBranch branch(bool compact) => compact ? this.compact : full;

  Map<String, Object?> toJson() => {
    'version': version,
    'style': style,
    'verticalAlign': verticalAlign.name,
    'eventOrder': eventOrder,
    'texts': texts.toJson(),
    'compact': compact.toJson(),
    'full': full.toJson(),
    if (contentMargin != 16.0) 'contentMargin': contentMargin,
  };

  factory WidgetRenderSpec.fromJson(Map<String, dynamic> json) {
    return WidgetRenderSpec(
      version: json['version'] as int? ?? widgetRenderProtocolVersion,
      style: json['style'] as String? ?? WidgetStyle.card.name,
      verticalAlign: WidgetVerticalAlign.values.firstWhere(
        (value) => value.name == json['verticalAlign'],
        orElse: () => WidgetVerticalAlign.center,
      ),
      eventOrder: (json['eventOrder'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      texts: WidgetRenderTexts.fromJson(
        json['texts'] as Map<String, dynamic>? ?? const {},
      ),
      compact: WidgetRenderBranch.fromJson(
        json['compact'] as Map<String, dynamic>? ?? const {},
      ),
      full: WidgetRenderBranch.fromJson(
        json['full'] as Map<String, dynamic>? ?? const {},
      ),
      contentMargin: (json['contentMargin'] as num?)?.toDouble() ?? 16.0,
    );
  }
}

/// 桌面小部件事件排序：置顶优先，其次按距离近优先，再按目标日期。
int compareWidgetEvents(CountdownEvent a, CountdownEvent b) {
  if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
  final distance = a.dayDelta().abs().compareTo(b.dayDelta().abs());
  if (distance != 0) return distance;
  return a.targetDate.compareTo(b.targetDate);
}

/// 由设置与事件解析出完整渲染配置。
WidgetRenderSpec resolveWidgetRenderSpec(
  List<CountdownEvent> rawEvents,
  AppSettings settings, {
  DateTime? now,
}) {
  final visible = rawEvents.where((event) => !event.isCompleted).toList()
    ..sort(compareWidgetEvents);
  final date = now ?? DateTime.now();
  return WidgetRenderSpec(
    version: widgetRenderProtocolVersion,
    style: settings.widgetStyle.name,
    verticalAlign: settings.widgetVerticalAlign,
    eventOrder: visible.map((event) => event.id).toList(),
    texts: const WidgetRenderTexts(
      title: '添加一个倒数日',
      category: '萤',
      days: '--',
      unit: '天',
    ),
    contentMargin: settings.widgetContentMargin,
    compact: _resolveBranch(
      settings,
      visible,
      compact: true,
      date: date,
    ),
    full: _resolveBranch(
      settings,
      visible,
      compact: false,
      date: date,
    ),
  );
}

WidgetRenderBranch _resolveBranch(
  AppSettings settings,
  List<CountdownEvent> visible, {
  required bool compact,
  required DateTime date,
}) {
  final mode = settings.widgetListMode
      ? WidgetRenderMode.list
      : WidgetRenderMode.single;
  final colors = _resolveTextColors(settings, date, visible.firstOrNull);
  final elements = <String, WidgetElementRender>{};
  for (final id in widgetRenderElementIds) {
    elements[id] = _resolveElement(
      settings,
      visible,
      id,
      compact: compact,
      mode: mode,
      colors: colors,
      date: date,
    );
  }
  return WidgetRenderBranch(mode: mode, elements: elements);
}

class _RenderColors {
  const _RenderColors({required this.primary, required this.secondary});

  final int primary;
  final int secondary;
}

_RenderColors _resolveTextColors(
  AppSettings settings,
  DateTime date,
  CountdownEvent? first,
) {
  final style = settings.widgetStyle;
  final holiday = combinedHoliday(first, date);
  final accent = _holidayAccent(holiday) ?? settings.widgetColor;
  final wallpaperText = settings.widgetWallpaperTextColor == -1
      ? null
      : settings.widgetWallpaperTextColor;
  final darkSurface = style == WidgetStyle.glass ||
      style == WidgetStyle.polaroid ||
      style == WidgetStyle.minimal ||
      style == WidgetStyle.capsule;
  final primary = switch (style) {
    WidgetStyle.neonSign => accent,
    WidgetStyle.crt => 0xFFC9F7D0,
    WidgetStyle.pixelHealth => 0xFFB7FF9E,
    _ => wallpaperText ??
        (darkSurface ? 0xFF1C1C1E : 0xFFFFFFFF),
  };
  return _RenderColors(
    primary: primary,
    secondary: _withAlpha(primary, 0.74),
  );
}

WidgetElementRender _resolveElement(
  AppSettings settings,
  List<CountdownEvent> visible,
  String id, {
  required bool compact,
  required WidgetRenderMode mode,
  required _RenderColors colors,
  required DateTime date,
}) {
  final policyVisible = _policyVisible(
    settings,
    visible,
    id,
    compact: compact,
    mode: mode,
    date: date,
  );
  final visibleValue = widgetElementVisible(
    settings,
    id,
    followDefault: policyVisible,
  );
  final color = widgetElementColor(
    settings,
    id,
    primary: Color(colors.primary),
    secondary: Color(colors.secondary),
    defaultPrimary: widgetPrimaryRenderElementIds.contains(id),
  ).toARGB32();
  return WidgetElementRender(
    visible: visibleValue,
    color: color,
    size: widgetElementSizeScale(settings, id),
    align: widgetElementStyleOf(settings, id)?.align ?? WidgetAlign.start,
    weight: widgetElementWeight(settings, id),
  );
}

bool _policyVisible(
  AppSettings settings,
  List<CountdownEvent> visible,
  String id, {
  required bool compact,
  required WidgetRenderMode mode,
  required DateTime date,
}) {
  final style = settings.widgetStyle;
  switch (id) {
    case 'category':
      return !compact && settings.widgetShowCategory;
    case 'holidayBadge':
      return !compact;
    case 'title':
    case 'days':
    case 'unit':
    case 'listHeader':
    case 'rowTitle':
    case 'rowSubtitle':
    case 'rowDays':
    case 'rowUnit':
    case 'empty':
      return true;
    case 'note':
      return !compact;
    case 'precise':
      return settings.widgetShowPreciseTime;
    case 'dateInfo':
      return !compact && settings.widgetShowLunarWeek;
    case 'progress':
      return !compact &&
          (settings.widgetShowProgress || style == WidgetStyle.pixelHealth);
    case 'icon':
      return mode == WidgetRenderMode.list
          ? settings.widgetShowIcon
          : !compact && settings.widgetShowIcon;
    case 'prevButton':
    case 'nextButton':
      return !compact;
    default:
      return true;
  }
}

int _withAlpha(int argb, double alpha) {
  final value = (alpha.clamp(0.0, 1.0) * 255).round();
  return (argb & 0x00FFFFFF) | (value << 24);
}

int? _holidayAccent(WidgetHoliday holiday) {
  switch (holiday) {
    case WidgetHoliday.newYear:
      return 0xFFE11D48;
    case WidgetHoliday.christmas:
      return 0xFF16A34A;
    case WidgetHoliday.midAutumn:
      return 0xFFD97706;
    case WidgetHoliday.birthday:
      return 0xFFEC4899;
    case WidgetHoliday.none:
      return null;
  }
}
