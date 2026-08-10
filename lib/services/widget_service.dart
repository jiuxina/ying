import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/countdown_event.dart';
import '../models/unlock_features.dart';
import '../models/widget_element_style.dart';
import '../models/widget_holiday.dart';
import '../models/widget_render_spec.dart';
import '../utils/widget_content_utils.dart';
import 'storage_service.dart';
import 'widget_interaction_service.dart' show widgetBackgroundCallback;

class WidgetStatus {
  const WidgetStatus({
    required this.installedCount,
    required this.syncedEventCount,
    required this.lastSyncedAt,
    required this.pinSupported,
    this.error,
  });

  final int installedCount;
  final int syncedEventCount;
  final DateTime? lastSyncedAt;
  final bool pinSupported;
  final String? error;
}

class WidgetService {
  static const appGroupId = 'group.com.jiuxina.ying';
  static const androidWidgetName = 'DaymarkWidgetProvider';
  static const iOSWidgetName = 'DaymarkWidget';
  static const qualifiedAndroidWidgetName =
      'com.jiuxina.ying.DaymarkWidgetProvider';
  static const qualifiedDetailWidgetName =
      'com.jiuxina.ying.DaymarkDetailWidgetProvider';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);
    await HomeWidget.registerInteractivityCallback(widgetBackgroundCallback);
  }

  static Future<void> sync(
    List<CountdownEvent> events,
    AppSettings settings,
  ) =>
      syncWithFlip(events, settings, flipDay: null);

  /// 同步小部件数据；天数变化时把旧天数写入翻牌字段，
  /// Android 侧先显示旧值，再在短窗口后切到新天数。
  static Future<void> syncWithFlip(
    List<CountdownEvent> events,
    AppSettings settings, {
    int? flipDay,
  }) async {
    await HomeWidget.setAppGroupId(appGroupId);
    final visible = events.where((event) => !event.isCompleted).toList()
      ..sort(compareWidgetEvents);
    final previousFlipDay = await HomeWidget.getWidgetData<int>(
      'widget_flip_day',
    );
    final activeDay = visible.isEmpty ? null : visible.first.dayDelta();
    final resolvedFlipDay = flipDay ??
        (previousFlipDay != null &&
                activeDay != null &&
                previousFlipDay != activeDay
            ? previousFlipDay
            : null);
    final preferences = await SharedPreferences.getInstance();
    final sponsorUnlocked =
        preferences.getBool(StorageService.sponsorUnlockedKey) ?? false;
    final encoded = encodeWidgetEvents(visible);
    final renderSpec = resolveWidgetRenderSpec(
      visible,
      settings,
      sponsorUnlocked: sponsorUnlocked,
    );
    await Future.wait([
      HomeWidget.saveWidgetData<String>('widget_events', encoded),
      HomeWidget.saveWidgetData<int>('widget_event_count', visible.length),
      HomeWidget.saveWidgetData<int>(
        'widget_synced_at',
        DateTime.now().millisecondsSinceEpoch,
      ),
      HomeWidget.saveWidgetData<int>('widget_flip_day', resolvedFlipDay),
      for (final entry in widgetPreferenceValues(
        settings,
        events: visible,
        sponsorUnlocked: sponsorUnlocked,
      ).entries)
        HomeWidget.saveWidgetData(entry.key, entry.value),
      HomeWidget.saveWidgetData<String>(
        'widget_render_spec',
        jsonEncode(renderSpec.toJson()),
      ),
    ]);
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Future.wait([
        HomeWidget.updateWidget(
          qualifiedAndroidName: qualifiedAndroidWidgetName,
        ),
        HomeWidget.updateWidget(
          qualifiedAndroidName: qualifiedDetailWidgetName,
        ),
      ]);
    } else {
      await HomeWidget.updateWidget(iOSName: iOSWidgetName);
    }
  }

  static Future<WidgetStatus> status() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      final widgets = await HomeWidget.getInstalledWidgets();
      final syncedAt = await HomeWidget.getWidgetData<int>('widget_synced_at');
      final count = await HomeWidget.getWidgetData<int>(
        'widget_event_count',
        defaultValue: 0,
      );
      final pinSupported = defaultTargetPlatform == TargetPlatform.android
          ? await HomeWidget.isRequestPinWidgetSupported() ?? false
          : false;
      return WidgetStatus(
        installedCount: widgets.length,
        syncedEventCount: count ?? 0,
        lastSyncedAt: syncedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(syncedAt),
        pinSupported: pinSupported,
      );
    } catch (error) {
      return WidgetStatus(
        installedCount: 0,
        syncedEventCount: 0,
        lastSyncedAt: null,
        pinSupported: false,
        error: error.toString(),
      );
    }
  }

  static Future<void> requestPin() => HomeWidget.requestPinWidget(
    qualifiedAndroidName: qualifiedAndroidWidgetName,
  );

  static Future<void> requestDetailPin() => HomeWidget.requestPinWidget(
    qualifiedAndroidName: qualifiedDetailWidgetName,
  );

  /// 只刷新已保存的小部件数据（不重写事件与偏好），用于 Toast 等轻量更新。
  static Future<void> syncWidgetDataOnly() async {
    await HomeWidget.setAppGroupId(appGroupId);
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Future.wait([
        HomeWidget.updateWidget(
          qualifiedAndroidName: qualifiedAndroidWidgetName,
        ),
        HomeWidget.updateWidget(
          qualifiedAndroidName: qualifiedDetailWidgetName,
        ),
      ]);
    } else {
      await HomeWidget.updateWidget(iOSName: iOSWidgetName);
    }
  }
}

/// 把可见事件编码为小部件 JSON：每个事件含 [CountdownEvent.icon] 与
/// [CountdownEvent.createdAt]（毫秒时间戳），并保持置顶优先、距离近优先的排序。
String encodeWidgetEvents(List<CountdownEvent> events) {
  final visible = events.where((event) => !event.isCompleted).toList()
    ..sort(compareWidgetEvents);
  return jsonEncode(
    visible
        .map(
          (event) => {
            'id': event.id,
            'title': event.title,
            'targetDate': event.dateOnly.millisecondsSinceEpoch,
            'targetTime': event.targetDate.millisecondsSinceEpoch,
            'category': event.category,
            'note': event.note,
            'icon': event.icon,
            'isAllDay': event.isAllDay,
            'isCountUp': event.isCountingUp,
            'isPinned': event.isPinned,
            'repeatsYearly': event.repeatsYearly,
            'createdAt': event.createdAt.millisecondsSinceEpoch,
          },
        )
        .toList(),
  );
}

/// 小部件偏好键值对；协议版本与全部新字段缺失时由 Android 侧回退默认值。
Map<String, Object?> widgetPreferenceValues(
  AppSettings settings, {
  List<CountdownEvent> events = const [],
  DateTime? now,
  bool sponsorUnlocked = true,
}) {
  final today = now ?? DateTime.now();
  final resolved = sponsorUnlocked ? settings : sanitizeSponsorSettings(settings);
  final renderSpec = resolveWidgetRenderSpec(
    events,
    resolved,
    sponsorUnlocked: sponsorUnlocked,
    now: today,
  );
  return {
    'widget_protocol_version': widgetRenderProtocolVersion,
    'widget_sponsor_unlocked': sponsorUnlocked,
    'widget_color': resolved.widgetColor.toRadixString(16).padLeft(8, '0'),
    'widget_font_scale': resolved.widgetFontScale,
    'widget_show_note': resolved.widgetShowNote,
    'widget_show_category': resolved.widgetShowCategory,
    'widget_style': resolved.widgetStyle.name,
    'widget_background_path': resolved.widgetBackgroundPath,
    'widget_unit_text': resolved.widgetUnitText,
    'widget_show_icon': resolved.widgetShowIcon,
    'widget_show_progress': resolved.widgetShowProgress,
    'widget_show_precise_time': resolved.widgetShowPreciseTime,
    'widget_show_lunar_week': resolved.widgetShowLunarWeek,
    'widget_mystery_mode': resolved.widgetMysteryMode,
    'widget_quote_mode': resolved.widgetQuoteMode,
    'widget_urgent_highlight': resolved.widgetUrgentHighlight,
    'widget_list_mode': resolved.widgetListMode,
    'widget_font_family': resolved.widgetFontFamily,
    'widget_text_font_family': resolved.widgetTextFontFamily,
    'widget_digit_font_path': resolved.widgetDigitFontPath,
    'widget_text_font_path': resolved.widgetTextFontPath,
    'widget_text_outline': resolved.widgetTextOutline,
    'widget_wallpaper_color': resolved.widgetWallpaperColor,
    'widget_wallpaper_dark_color': resolved.widgetWallpaperDarkColor,
    'widget_wallpaper_text_color': resolved.widgetWallpaperTextColor,
    'widget_element_styles': encodeWidgetElementStyles(
      resolved.widgetElementStyles,
    ),
    'widget_vertical_align': resolved.widgetVerticalAlign.name,
    'widget_holiday': holidayFor(today).wireName,
    'widget_date_info': widgetDateInfo(today),
    'widget_render_spec': jsonEncode(renderSpec.toJson()),
  };
}
