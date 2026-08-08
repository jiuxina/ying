import 'dart:async';

import 'package:flutter/material.dart';

import '../app_navigator.dart';
import '../ui/event_detail_page.dart';
import '../ui/event_form_sheet.dart';
import '../ui/glass_ui.dart';
import 'widget_interaction_service.dart';

/// 处理小部件前台启动 URI：`ying://add` 与 `ying://open?id=...`。
Future<void> handleWidgetLaunchUri(Uri? uri) async {
  if (uri == null || uri.scheme != 'ying') return;
  final navigator = appNavigatorKey.currentState;
  if (navigator == null || !navigator.mounted) {
    // 冷启动时导航器尚未挂载，等首帧后再执行。
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await handleWidgetLaunchUri(uri);
    return;
  }
  switch (uri.host) {
    case widgetActionAdd:
      await _showAddSheet(navigator.context);
    case widgetActionOpen:
      final id = uri.queryParameters['id'];
      if (id != null) {
        await navigator.push<void>(
          GlassPageRoute<void>(
            builder: (context) => EventDetailPage(eventId: id),
          ),
        );
      }
  }
}

Future<void> _showAddSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 680),
    builder: (context) => const EventFormSheet(),
  );
}
