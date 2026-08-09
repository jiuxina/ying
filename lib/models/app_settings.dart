import 'package:flutter/material.dart';

import 'event_sort_mode.dart';

/// 桌面小部件样式预设；旧配置或未知值统一回退 [WidgetStyle.card]。
enum WidgetStyle {
  card,
  sticker,
  photo,
  glass,
  polaroid,
  neon,
  pixel,
  minimal,
}

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.widgetColor = 0xFF0F766E,
    this.widgetFontScale = 1.0,
    this.widgetShowNote = true,
    this.widgetShowCategory = true,
    this.eventSortMode = EventSortMode.distance,
    this.reduceTransparency = false,
    this.reduceMotion = false,
    this.autoCheckUpdate = true,
    this.widgetStyle = WidgetStyle.card,
    this.widgetBackgroundPath = '',
    this.widgetUnitText = '',
    this.widgetShowIcon = false,
    this.widgetShowProgress = false,
    this.widgetShowPreciseTime = false,
    this.widgetShowLunarWeek = false,
    this.widgetMysteryMode = false,
    this.widgetQuoteMode = false,
    this.widgetUrgentHighlight = false,
    this.widgetListMode = false,
    this.widgetFontFamily = 'system',
    this.widgetTextOutline = false,
    this.widgetWallpaperColor = -1,
    this.widgetWallpaperDarkColor = -1,
    this.widgetWallpaperTextColor = -1,
  });

  final ThemeMode themeMode;
  final int widgetColor;
  final double widgetFontScale;
  final bool widgetShowNote;
  final bool widgetShowCategory;
  final EventSortMode eventSortMode;
  final bool reduceTransparency;
  final bool reduceMotion;
  final bool autoCheckUpdate;
  final WidgetStyle widgetStyle;
  final String widgetBackgroundPath;
  final String widgetUnitText;
  final bool widgetShowIcon;
  final bool widgetShowProgress;
  final bool widgetShowPreciseTime;
  final bool widgetShowLunarWeek;
  final bool widgetMysteryMode;
  final bool widgetQuoteMode;
  final bool widgetUrgentHighlight;
  final bool widgetListMode;
  final String widgetFontFamily;
  final bool widgetTextOutline;
  final int widgetWallpaperColor;
  final int widgetWallpaperDarkColor;
  final int widgetWallpaperTextColor;

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? widgetColor,
    double? widgetFontScale,
    bool? widgetShowNote,
    bool? widgetShowCategory,
    EventSortMode? eventSortMode,
    bool? reduceTransparency,
    bool? reduceMotion,
    bool? autoCheckUpdate,
    WidgetStyle? widgetStyle,
    String? widgetBackgroundPath,
    String? widgetUnitText,
    bool? widgetShowIcon,
    bool? widgetShowProgress,
    bool? widgetShowPreciseTime,
    bool? widgetShowLunarWeek,
    bool? widgetMysteryMode,
    bool? widgetQuoteMode,
    bool? widgetUrgentHighlight,
    bool? widgetListMode,
    String? widgetFontFamily,
    bool? widgetTextOutline,
    int? widgetWallpaperColor,
    int? widgetWallpaperDarkColor,
    int? widgetWallpaperTextColor,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      widgetColor: widgetColor ?? this.widgetColor,
      widgetFontScale: widgetFontScale ?? this.widgetFontScale,
      widgetShowNote: widgetShowNote ?? this.widgetShowNote,
      widgetShowCategory: widgetShowCategory ?? this.widgetShowCategory,
      eventSortMode: eventSortMode ?? this.eventSortMode,
      reduceTransparency: reduceTransparency ?? this.reduceTransparency,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      autoCheckUpdate: autoCheckUpdate ?? this.autoCheckUpdate,
      widgetStyle: widgetStyle ?? this.widgetStyle,
      widgetBackgroundPath: widgetBackgroundPath ?? this.widgetBackgroundPath,
      widgetUnitText: widgetUnitText ?? this.widgetUnitText,
      widgetShowIcon: widgetShowIcon ?? this.widgetShowIcon,
      widgetShowProgress: widgetShowProgress ?? this.widgetShowProgress,
      widgetShowPreciseTime:
          widgetShowPreciseTime ?? this.widgetShowPreciseTime,
      widgetShowLunarWeek: widgetShowLunarWeek ?? this.widgetShowLunarWeek,
      widgetMysteryMode: widgetMysteryMode ?? this.widgetMysteryMode,
      widgetQuoteMode: widgetQuoteMode ?? this.widgetQuoteMode,
      widgetUrgentHighlight:
          widgetUrgentHighlight ?? this.widgetUrgentHighlight,
      widgetListMode: widgetListMode ?? this.widgetListMode,
      widgetFontFamily: widgetFontFamily ?? this.widgetFontFamily,
      widgetTextOutline: widgetTextOutline ?? this.widgetTextOutline,
      widgetWallpaperColor: widgetWallpaperColor ?? this.widgetWallpaperColor,
      widgetWallpaperDarkColor:
          widgetWallpaperDarkColor ?? this.widgetWallpaperDarkColor,
      widgetWallpaperTextColor:
          widgetWallpaperTextColor ?? this.widgetWallpaperTextColor,
    );
  }

  Map<String, Object> toMap() => {
    'themeMode': themeMode.name,
    'widgetColor': widgetColor,
    'widgetFontScale': widgetFontScale,
    'widgetShowNote': widgetShowNote,
    'widgetShowCategory': widgetShowCategory,
    'eventSortMode': eventSortMode.name,
    'reduceTransparency': reduceTransparency,
    'reduceMotion': reduceMotion,
    'autoCheckUpdate': autoCheckUpdate,
    'widgetStyle': widgetStyle.name,
    'widgetBackgroundPath': widgetBackgroundPath,
    'widgetUnitText': widgetUnitText,
    'widgetShowIcon': widgetShowIcon,
    'widgetShowProgress': widgetShowProgress,
    'widgetShowPreciseTime': widgetShowPreciseTime,
    'widgetShowLunarWeek': widgetShowLunarWeek,
    'widgetMysteryMode': widgetMysteryMode,
    'widgetQuoteMode': widgetQuoteMode,
    'widgetUrgentHighlight': widgetUrgentHighlight,
    'widgetListMode': widgetListMode,
    'widgetFontFamily': widgetFontFamily,
    'widgetTextOutline': widgetTextOutline,
    'widgetWallpaperColor': widgetWallpaperColor,
    'widgetWallpaperDarkColor': widgetWallpaperDarkColor,
    'widgetWallpaperTextColor': widgetWallpaperTextColor,
  };

  factory AppSettings.fromMap(Map<String, Object?> map) {
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == map['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      widgetColor: (map['widgetColor'] as int?) ?? 0xFF0F766E,
      widgetFontScale: (map['widgetFontScale'] as double?) ?? 1.0,
      widgetShowNote: (map['widgetShowNote'] as bool?) ?? true,
      widgetShowCategory: (map['widgetShowCategory'] as bool?) ?? true,
      eventSortMode: EventSortMode.values.firstWhere(
        (mode) => mode.name == map['eventSortMode'],
        orElse: () => EventSortMode.distance,
      ),
      reduceTransparency: (map['reduceTransparency'] as bool?) ?? false,
      reduceMotion: (map['reduceMotion'] as bool?) ?? false,
      autoCheckUpdate: (map['autoCheckUpdate'] as bool?) ?? true,
      widgetStyle: WidgetStyle.values.firstWhere(
        (style) => style.name == map['widgetStyle'],
        orElse: () => WidgetStyle.card,
      ),
      widgetBackgroundPath: (map['widgetBackgroundPath'] as String?) ?? '',
      widgetUnitText: (map['widgetUnitText'] as String?) ?? '',
      widgetShowIcon: (map['widgetShowIcon'] as bool?) ?? false,
      widgetShowProgress: (map['widgetShowProgress'] as bool?) ?? false,
      widgetShowPreciseTime: (map['widgetShowPreciseTime'] as bool?) ?? false,
      widgetShowLunarWeek: (map['widgetShowLunarWeek'] as bool?) ?? false,
      widgetMysteryMode: (map['widgetMysteryMode'] as bool?) ?? false,
      widgetQuoteMode: (map['widgetQuoteMode'] as bool?) ?? false,
      widgetUrgentHighlight: (map['widgetUrgentHighlight'] as bool?) ?? false,
      widgetListMode: (map['widgetListMode'] as bool?) ?? false,
      widgetFontFamily: (map['widgetFontFamily'] as String?) ?? 'system',
      widgetTextOutline: (map['widgetTextOutline'] as bool?) ?? false,
      widgetWallpaperColor: (map['widgetWallpaperColor'] as int?) ?? -1,
      widgetWallpaperDarkColor:
          (map['widgetWallpaperDarkColor'] as int?) ?? -1,
      widgetWallpaperTextColor:
          (map['widgetWallpaperTextColor'] as int?) ?? -1,
    );
  }
}
