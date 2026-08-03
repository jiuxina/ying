import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/countdown_event.dart';

class StorageService {
  static const _eventsKey = 'countdown_events_v1';
  static const _themeKey = 'theme_mode';
  static const _widgetColorKey = 'widget_color';
  static const _widgetFontKey = 'widget_font_scale';
  static const _widgetNoteKey = 'widget_show_note';
  static const _widgetCategoryKey = 'widget_show_category';
  static const _eventSortModeKey = 'event_sort_mode';
  static const _reduceTransparencyKey = 'reduce_transparency';
  static const _reduceMotionKey = 'reduce_motion';
  static const _notificationActionRevisionKey = 'notification_action_revision';

  Future<List<CountdownEvent>> loadEvents() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final raw = preferences.getString(_eventsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return CountdownEvent.decodeList(raw);
    } on FormatException {
      return const [];
    }
  }

  Future<void> saveEvents(List<CountdownEvent> events) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_eventsKey, CountdownEvent.encodeList(events));
  }

  Future<AppSettings> loadSettings() async {
    final preferences = await SharedPreferences.getInstance();
    return AppSettings.fromMap({
      'themeMode': preferences.getString(_themeKey),
      'widgetColor': preferences.getInt(_widgetColorKey),
      'widgetFontScale': preferences.getDouble(_widgetFontKey),
      'widgetShowNote': preferences.getBool(_widgetNoteKey),
      'widgetShowCategory': preferences.getBool(_widgetCategoryKey),
      'eventSortMode': preferences.getString(_eventSortModeKey),
      'reduceTransparency': preferences.getBool(_reduceTransparencyKey),
      'reduceMotion': preferences.getBool(_reduceMotionKey),
    });
  }

  Future<int> loadNotificationActionRevision() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    return preferences.getInt(_notificationActionRevisionKey) ?? 0;
  }

  Future<void> markNotificationAction() async {
    final preferences = await SharedPreferences.getInstance();
    final revision = preferences.getInt(_notificationActionRevisionKey) ?? 0;
    await preferences.setInt(_notificationActionRevisionKey, revision + 1);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(_themeKey, settings.themeMode.name),
      preferences.setInt(_widgetColorKey, settings.widgetColor),
      preferences.setDouble(_widgetFontKey, settings.widgetFontScale),
      preferences.setBool(_widgetNoteKey, settings.widgetShowNote),
      preferences.setBool(_widgetCategoryKey, settings.widgetShowCategory),
      preferences.setString(_eventSortModeKey, settings.eventSortMode.name),
      preferences.setBool(_reduceTransparencyKey, settings.reduceTransparency),
      preferences.setBool(_reduceMotionKey, settings.reduceMotion),
    ]);
  }
}
