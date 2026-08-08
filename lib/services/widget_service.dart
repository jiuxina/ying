import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/app_settings.dart';
import '../models/countdown_event.dart';
import '../utils/event_repeat_utils.dart';
import 'notification_service.dart';
import 'storage_service.dart';

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

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);
    await HomeWidget.registerInteractivityCallback(widgetBackgroundCallback);
  }

  static Future<void> sync(
    List<CountdownEvent> events,
    AppSettings settings,
  ) async {
    await HomeWidget.setAppGroupId(appGroupId);
    final visible = events.where((event) => !event.isCompleted).toList()
      ..sort(_compareEvents);
    final encoded = encodeWidgetEvents(visible);
    await Future.wait([
      HomeWidget.saveWidgetData<String>('widget_events', encoded),
      HomeWidget.saveWidgetData<int>('widget_event_count', visible.length),
      HomeWidget.saveWidgetData<int>(
        'widget_synced_at',
        DateTime.now().millisecondsSinceEpoch,
      ),
      for (final entry in widgetPreferenceValues(settings).entries)
        HomeWidget.saveWidgetData(entry.key, entry.value),
    ]);
    await HomeWidget.updateWidget(
      qualifiedAndroidName: qualifiedAndroidWidgetName,
      iOSName: iOSWidgetName,
    );
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
}

/// 把可见事件编码为小部件 v2 JSON：每个事件含 [CountdownEvent.icon] 与
/// [CountdownEvent.createdAt]（毫秒时间戳），并保持置顶优先、距离近优先的排序。
String encodeWidgetEvents(List<CountdownEvent> events) {
  final visible = events.where((event) => !event.isCompleted).toList()
    ..sort(_compareEvents);
  return jsonEncode(
    visible
        .map(
          (event) => {
            'id': event.id,
            'title': event.title,
            'targetDate': event.dateOnly.millisecondsSinceEpoch,
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

/// 小部件 v2 偏好键值对；协议版本与全部新字段缺失时由 Android 侧回退默认值。
Map<String, Object?> widgetPreferenceValues(AppSettings settings) {
  return {
    'widget_protocol_version': 2,
    'widget_color': settings.widgetColor.toRadixString(16).padLeft(8, '0'),
    'widget_font_scale': settings.widgetFontScale,
    'widget_show_note': settings.widgetShowNote,
    'widget_show_category': settings.widgetShowCategory,
    'widget_style': settings.widgetStyle.name,
    'widget_background_path': settings.widgetBackgroundPath,
    'widget_unit_text': settings.widgetUnitText,
    'widget_show_icon': settings.widgetShowIcon,
    'widget_show_progress': settings.widgetShowProgress,
    'widget_show_precise_time': settings.widgetShowPreciseTime,
    'widget_mystery_mode': settings.widgetMysteryMode,
    'widget_quote_mode': settings.widgetQuoteMode,
    'widget_font_family': settings.widgetFontFamily,
    'widget_text_outline': settings.widgetTextOutline,
    'widget_wallpaper_color': settings.widgetWallpaperColor,
    'widget_wallpaper_dark_color': settings.widgetWallpaperDarkColor,
    'widget_wallpaper_text_color': settings.widgetWallpaperTextColor,
  };
}

int _compareEvents(CountdownEvent a, CountdownEvent b) {
  if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
  final aDays = a.dayDelta().abs();
  final bDays = b.dayDelta().abs();
  final distance = aDays.compareTo(bDays);
  if (distance != 0) return distance;
  return a.targetDate.compareTo(b.targetDate);
}

@pragma('vm:entry-point')
FutureOr<void> widgetBackgroundCallback(Uri? uri) async {
  if (uri == null || uri.host != 'complete') return;
  final id = uri.queryParameters['id'];
  if (id == null) return;

  final storage = StorageService();
  final events = await storage.loadEvents();
  final index = events.indexWhere((event) => event.id == id);
  if (index < 0) return;
  final updated = completeEvent(events[index]);
  events[index] = updated;
  await storage.saveEvents(events);
  if (updated.repeatsYearly) {
    await NotificationService.instance.schedule(updated);
  } else {
    await NotificationService.instance.cancel(updated.id);
  }
  final settings = await storage.loadSettings();
  await WidgetService.sync(events, settings);
  await storage.markNotificationAction();
}
