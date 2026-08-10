import 'dart:async';

import 'package:flutter/material.dart';

import '../app_navigator.dart';
import '../ui/event_detail_page.dart';
import '../ui/event_form_sheet.dart';
import '../ui/glass_ui.dart';
import 'widget_interaction_service.dart';

/// 处理小部件前台启动 URI：`ying://add` 与 `ying://open?id=...`，
/// 并兼容旧版 iOS 小部件写出的 `ying://new` 与 `ying://event?id=...`。
final Map<String, int> _handledLaunchUris = {};

const int widgetLaunchDedupeCapacity = 64;
const int widgetLaunchMaxRetries = 20;
const Duration widgetLaunchRetryDelay = Duration(milliseconds: 50);
const Duration widgetLaunchDedupeWindow = Duration(milliseconds: 1500);

Future<void> handleWidgetLaunchUri(Uri? uri) => _handleWidgetLaunchUri(uri, 0);

Future<void> _handleWidgetLaunchUri(Uri? uri, int attempt) async {
  if (uri == null || uri.scheme != 'ying') return;
  final key = uri.toString();
  final now = DateTime.now().millisecondsSinceEpoch;
  if (now -
          (_handledLaunchUris[key] ??
              -widgetLaunchDedupeWindow.inMilliseconds) <
      widgetLaunchDedupeWindow.inMilliseconds) {
    return;
  }
  _handledLaunchUris[key] = now;
  final pruned = pruneWidgetLaunchUris(_handledLaunchUris);
  _handledLaunchUris
    ..clear()
    ..addAll(pruned);
  final navigator = appNavigatorKey.currentState;
  if (navigator == null || !navigator.mounted) {
    // 冷启动时导航器尚未挂载，等首帧后再执行；超过上限则放弃，避免无界自旋。
    if (attempt >= widgetLaunchMaxRetries) {
      debugPrint(
        'ying widget launch: navigator not ready after '
        '$widgetLaunchMaxRetries attempts: $uri',
      );
      return;
    }
    await Future<void>.delayed(widgetLaunchRetryDelay);
    await _handleWidgetLaunchUri(uri, attempt + 1);
    return;
  }
  switch (_normalizeWidgetLaunchHost(uri.host)) {
    case widgetActionAdd:
      unawaited(_showAddSheet(navigator.context));
    case widgetActionOpen:
      final id = uri.queryParameters['id'];
      if (id != null) {
        unawaited(
          navigator.push<void>(
            GlassPageRoute<void>(
              builder: (context) => EventDetailPage(eventId: id),
            ),
          ),
        );
      }
  }
}

String _normalizeWidgetLaunchHost(String host) => switch (host) {
  'event' => widgetActionOpen,
  'new' => widgetActionAdd,
  _ => host,
};

/// 裁剪去重表，避免长期运行后内存无限增长；按插入顺序保留最新 [capacity] 条。
@visibleForTesting
Map<String, int> pruneWidgetLaunchUris(
  Map<String, int> source, {
  int capacity = widgetLaunchDedupeCapacity,
}) {
  final result = Map<String, int>.from(source);
  while (result.length > capacity) {
    result.remove(result.keys.first);
  }
  return result;
}

Future<void> _showAddSheet(BuildContext context) async {
  await showGlassBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 680),
    builder: (context) => const EventFormSheet(),
  );
}
