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
  static const _autoCheckUpdateKey = 'auto_check_update';
  static const _lastUpdateCheckAtKey = 'last_update_check_at';
  static const _skippedReleaseVersionKey = 'skipped_release_version';
  static const _notificationActionRevisionKey = 'notification_action_revision';
  static const _widgetStyleKey = 'widget_style';
  static const _widgetBackgroundPathKey = 'widget_background_path';
  static const _widgetUnitTextKey = 'widget_unit_text';
  static const _widgetShowIconKey = 'widget_show_icon';
  static const _widgetShowProgressKey = 'widget_show_progress';
  static const _widgetShowPreciseTimeKey = 'widget_show_precise_time';
  static const _widgetShowLunarWeekKey = 'widget_show_lunar_week';
  static const _widgetMysteryModeKey = 'widget_mystery_mode';
  static const _widgetQuoteModeKey = 'widget_quote_mode';
  static const _widgetListModeKey = 'widget_list_mode';
  static const _widgetFontFamilyKey = 'widget_font_family';
  static const _widgetTextOutlineKey = 'widget_text_outline';
  static const _widgetWallpaperColorKey = 'widget_wallpaper_color';
  static const _widgetWallpaperDarkColorKey = 'widget_wallpaper_dark_color';
  static const _widgetWallpaperTextColorKey = 'widget_wallpaper_text_color';

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
      'autoCheckUpdate': preferences.getBool(_autoCheckUpdateKey),
      'widgetStyle': preferences.getString(_widgetStyleKey),
      'widgetBackgroundPath': preferences.getString(_widgetBackgroundPathKey),
      'widgetUnitText': preferences.getString(_widgetUnitTextKey),
      'widgetShowIcon': preferences.getBool(_widgetShowIconKey),
      'widgetShowProgress': preferences.getBool(_widgetShowProgressKey),
      'widgetShowPreciseTime': preferences.getBool(
        _widgetShowPreciseTimeKey,
      ),
      'widgetShowLunarWeek': preferences.getBool(
        _widgetShowLunarWeekKey,
      ),
      'widgetMysteryMode': preferences.getBool(_widgetMysteryModeKey),
      'widgetQuoteMode': preferences.getBool(_widgetQuoteModeKey),
      'widgetListMode': preferences.getBool(_widgetListModeKey),
      'widgetFontFamily': preferences.getString(_widgetFontFamilyKey),
      'widgetTextOutline': preferences.getBool(_widgetTextOutlineKey),
      'widgetWallpaperColor': preferences.getInt(_widgetWallpaperColorKey),
      'widgetWallpaperDarkColor': preferences.getInt(
        _widgetWallpaperDarkColorKey,
      ),
      'widgetWallpaperTextColor': preferences.getInt(
        _widgetWallpaperTextColorKey,
      ),
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
      preferences.setBool(_autoCheckUpdateKey, settings.autoCheckUpdate),
      preferences.setString(_widgetStyleKey, settings.widgetStyle.name),
      preferences.setString(
        _widgetBackgroundPathKey,
        settings.widgetBackgroundPath,
      ),
      preferences.setString(_widgetUnitTextKey, settings.widgetUnitText),
      preferences.setBool(_widgetShowIconKey, settings.widgetShowIcon),
      preferences.setBool(_widgetShowProgressKey, settings.widgetShowProgress),
      preferences.setBool(
        _widgetShowPreciseTimeKey,
        settings.widgetShowPreciseTime,
      ),
      preferences.setBool(
        _widgetShowLunarWeekKey,
        settings.widgetShowLunarWeek,
      ),
      preferences.setBool(_widgetMysteryModeKey, settings.widgetMysteryMode),
      preferences.setBool(_widgetQuoteModeKey, settings.widgetQuoteMode),
      preferences.setBool(_widgetListModeKey, settings.widgetListMode),
      preferences.setString(_widgetFontFamilyKey, settings.widgetFontFamily),
      preferences.setBool(_widgetTextOutlineKey, settings.widgetTextOutline),
      preferences.setInt(_widgetWallpaperColorKey, settings.widgetWallpaperColor),
      preferences.setInt(
        _widgetWallpaperDarkColorKey,
        settings.widgetWallpaperDarkColor,
      ),
      preferences.setInt(
        _widgetWallpaperTextColorKey,
        settings.widgetWallpaperTextColor,
      ),
    ]);
  }

  Future<DateTime?> loadLastUpdateCheckAt() async {
    final preferences = await SharedPreferences.getInstance();
    final millis = preferences.getInt(_lastUpdateCheckAtKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> saveLastUpdateCheckAt(DateTime time) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      _lastUpdateCheckAtKey,
      time.millisecondsSinceEpoch,
    );
  }

  Future<String?> loadSkippedReleaseVersion() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_skippedReleaseVersionKey);
  }

  Future<void> saveSkippedReleaseVersion(String version) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_skippedReleaseVersionKey, version);
  }
}
