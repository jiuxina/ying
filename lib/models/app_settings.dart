import 'package:flutter/material.dart';

import 'event_sort_mode.dart';

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
  });

  final ThemeMode themeMode;
  final int widgetColor;
  final double widgetFontScale;
  final bool widgetShowNote;
  final bool widgetShowCategory;
  final EventSortMode eventSortMode;
  final bool reduceTransparency;
  final bool reduceMotion;

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? widgetColor,
    double? widgetFontScale,
    bool? widgetShowNote,
    bool? widgetShowCategory,
    EventSortMode? eventSortMode,
    bool? reduceTransparency,
    bool? reduceMotion,
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
    );
  }
}
