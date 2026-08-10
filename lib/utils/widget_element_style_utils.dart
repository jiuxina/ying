import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/widget_element_style.dart';

WidgetElementStyle? widgetElementStyleOf(
  AppSettings settings,
  String id,
) {
  return settings.widgetElementStyles[id];
}

bool widgetElementVisible(
  AppSettings settings,
  String id, {
  required bool followDefault,
}) {
  final style = widgetElementStyleOf(settings, id);
  return switch (style?.visible) {
    WidgetElementVisible.show => true,
    WidgetElementVisible.hide => false,
    _ => followDefault,
  };
}

double widgetElementSizeScale(AppSettings settings, String id) =>
    widgetElementStyleOf(settings, id)?.sizeScale ?? 1.0;

int widgetElementWeight(AppSettings settings, String id) =>
    widgetElementStyleOf(settings, id)?.weight ?? 0;

/// 颜色优先级：自定义色 > 特殊色（临近高亮/胶囊/节日）> 角色默认色。
Color widgetElementColor(
  AppSettings settings,
  String id, {
  required Color primary,
  required Color secondary,
  required bool defaultPrimary,
  Color? override,
}) {
  final style = widgetElementStyleOf(settings, id);
  final fallback = defaultPrimary ? primary : secondary;
  if (style == null) return override ?? fallback;
  return switch (style.colorMode) {
    WidgetColorMode.custom =>
      style.color == -1 ? (override ?? fallback) : Color(style.color),
    WidgetColorMode.secondary => override ?? secondary,
    WidgetColorMode.primary => override ?? primary,
  };
}

TextAlign widgetElementAlign(AppSettings settings, String id) {
  return switch (widgetElementStyleOf(settings, id)?.align) {
    WidgetAlign.center => TextAlign.center,
    WidgetAlign.end => TextAlign.end,
    _ => TextAlign.start,
  };
}
