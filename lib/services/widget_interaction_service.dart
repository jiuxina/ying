import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../models/app_settings.dart';
import '../models/countdown_event.dart';
import '../state/app_controller.dart';
import 'storage_service.dart';
import 'widget_service.dart';

/// 小部件点击动作的 URI host 常量。
const widgetActionAdd = 'add';
const widgetActionOpen = 'open';
const widgetActionComplete = 'complete';
const widgetActionUndo = 'undo';
const widgetActionCopy = 'copy';

/// 快速完成后小部件内可撤销的窗口时长。
const widgetUndoWindow = Duration(seconds: 6);

const widgetPendingUndoKey = 'widget_pending_undo';
const widgetToastKey = 'widget_toast';

typedef WidgetFlipSynchronizer =
    Future<void> Function(
      List<CountdownEvent> events,
      AppSettings settings, {
      int? flipDay,
    });

class PendingUndoPayload {
  const PendingUndoPayload({
    required this.event,
    required this.expiresAt,
  });

  final CountdownEvent event;
  final DateTime expiresAt;

  String encode() => jsonEncode({
    'event': event.toJson(),
    'expiresAt': expiresAt.millisecondsSinceEpoch,
  });

  static PendingUndoPayload? decode(String? source) {
    if (source == null || source.isEmpty) return null;
    try {
      final values = jsonDecode(source) as Map<String, dynamic>;
      return PendingUndoPayload(
        event: CountdownEvent.fromJson(
          values['event'] as Map<String, dynamic>,
        ),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
          (values['expiresAt'] as num).toInt(),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

/// 生成「距离 XXX 还有 N 天」样式的分享卡片文案。
String widgetShareCardText(CountdownEvent event, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final delta = event.dayDelta(today);
  if (delta == 0) return '${event.title}：就是今天';
  final verb = event.isCountingUp ? '已经' : '还有';
  return '${event.title}：$verb ${delta.abs()} 天';
}

/// 桌面小部件后台回调：完成、撤销与复制动作统一入口。
@pragma('vm:entry-point')
FutureOr<void> widgetBackgroundCallback(Uri? uri) async {
  if (uri == null) return;
  switch (uri.host) {
    case widgetActionComplete:
      await _handleComplete(uri);
    case widgetActionUndo:
      await _handleUndo(uri);
    case widgetActionCopy:
      await _handleCopy(uri);
  }
}

Future<void> _handleComplete(Uri uri) async {
  final id = uri.queryParameters['id'];
  if (id == null) return;
  final storage = StorageService();
  final controller = AppController(storage, autoLoad: false);
  await controller.load(runAutoCheck: false);
  final events = await storage.loadEvents();
  final settings = await storage.loadSettings();
  final event = events.where((value) => value.id == id).firstOrNull;
  if (event == null || event.isCompleted) return;

  await completeEventFromWidget(
    storage: storage,
    controller: controller,
    event: event,
    settings: settings,
  );
}

/// 小部件完成回调的公共逻辑：完成事件后，用完成后的最新列表再次同步小部件，
/// 避免把已勾选事件重新写回列表。
@visibleForTesting
Future<void> completeEventFromWidget({
  required StorageService storage,
  required AppController controller,
  required CountdownEvent event,
  required AppSettings settings,
  WidgetFlipSynchronizer? syncWidget,
}) async {
  final expiresAt = DateTime.now().add(widgetUndoWindow);
  await controller.toggleCompletedWithUndo(
    event,
    beforeWidgetSync: (_) async {
      await _savePendingUndo(event, expiresAt);
    },
  );
  final updatedEvents = await storage.loadEvents();
  await (syncWidget ?? WidgetService.syncWithFlip)(
    updatedEvents,
    settings,
    flipDay: event.dayDelta(),
  );
  await storage.markNotificationAction();
}

Future<void> _handleUndo(Uri uri) async {
  final id = uri.queryParameters['id'];
  if (id == null) return;
  final storage = StorageService();
  final controller = AppController(storage, autoLoad: false);
  await controller.load(runAutoCheck: false);
  final events = await storage.loadEvents();
  final event = events.where((value) => value.id == id).firstOrNull;
  if (event == null || !event.isCompleted) return;

  await controller.toggleCompletedWithUndo(
    event,
    beforeWidgetSync: (_) async {
      await _savePendingUndo(null, null);
    },
  );
  await storage.markNotificationAction();
}

Future<void> _handleCopy(Uri uri) async {
  final id = uri.queryParameters['id'];
  if (id == null) return;
  final storage = StorageService();
  final events = await storage.loadEvents();
  final event = events.where((value) => value.id == id).firstOrNull;
  if (event == null) return;
  await Clipboard.setData(ClipboardData(text: widgetShareCardText(event)));
  await _showCopyFeedback();
}

Future<void> _savePendingUndo(
  CountdownEvent? event,
  DateTime? expiresAt,
) async {
  if (event == null || expiresAt == null) {
    await HomeWidget.saveWidgetData<String>(widgetPendingUndoKey, null);
    return;
  }
  final payload = PendingUndoPayload(event: event, expiresAt: expiresAt);
  await HomeWidget.saveWidgetData<String>(widgetPendingUndoKey, payload.encode());
}

/// 应用在前台时用 SnackBar 提示，否则写入偏好由小部件刷新时弹 Toast。
Future<void> _showCopyFeedback() async {
  await HomeWidget.saveWidgetData<String>(
    widgetToastKey,
    '已复制到剪贴板',
  );
  await WidgetService.syncWidgetDataOnly();
}
