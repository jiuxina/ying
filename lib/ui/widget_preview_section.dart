import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_settings.dart';
import '../models/countdown_event.dart';
import '../services/widget_service.dart';
import 'glass_ui.dart';

class WidgetPreviewSection extends StatefulWidget {
  const WidgetPreviewSection({
    super.key,
    required this.events,
    required this.settings,
  });

  final List<CountdownEvent> events;
  final AppSettings settings;

  @override
  State<WidgetPreviewSection> createState() => _WidgetPreviewSectionState();
}

class _WidgetPreviewSectionState extends State<WidgetPreviewSection> {
  late Future<WidgetStatus> statusFuture;
  bool refreshing = false;

  @override
  void initState() {
    super.initState();
    statusFuture = WidgetService.status();
  }

  void _reloadStatus() {
    setState(() => statusFuture = WidgetService.status());
  }

  Future<void> _refresh() async {
    setState(() => refreshing = true);
    try {
      await WidgetService.sync(widget.events, widget.settings);
      _reloadStatus();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('桌面小部件已刷新')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('刷新失败：$error')));
      }
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.events.where((event) => !event.isCompleted).toList()
      ..sort((a, b) => a.dayDelta().abs().compareTo(b.dayDelta().abs()));
    final event = visible.firstOrNull;
    final color = Color(widget.settings.widgetColor);
    return GlassSurface(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlassSectionTitle(title: '桌面小部件', subtitle: '预览、状态与添加引导'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final vertical = constraints.maxWidth < 500;
              final compactPreview = _WidgetPreview(
                event: event,
                settings: widget.settings,
                color: color,
                compact: true,
              );
              final mediumPreview = _WidgetPreview(
                event: event,
                settings: widget.settings,
                color: color,
                compact: false,
              );
              return vertical
                  ? Column(
                      children: [
                        compactPreview,
                        const SizedBox(height: 12),
                        mediumPreview,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: compactPreview),
                        const SizedBox(width: 12),
                        Expanded(child: mediumPreview),
                      ],
                    );
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<WidgetStatus>(
            future: statusFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }
              final status = snapshot.data!;
              return Column(
                children: [
                  _StatusLine(
                    label: '桌面实例',
                    value: status.installedCount == 0
                        ? '未检测到'
                        : '${status.installedCount} 个',
                  ),
                  _StatusLine(
                    label: '已同步事件',
                    value: '${status.syncedEventCount} 个',
                  ),
                  _StatusLine(
                    label: '最近刷新',
                    value: status.lastSyncedAt == null
                        ? '尚未同步'
                        : DateFormat(
                            'M月d日 HH:mm',
                            'zh_CN',
                          ).format(status.lastSyncedAt!),
                  ),
                  if (status.error != null)
                    _StatusLine(label: '状态异常', value: status.error!),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: refreshing ? null : _refresh,
                          icon: refreshing
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                          label: const Text('一键刷新'),
                        ),
                      ),
                      if (defaultTargetPlatform == TargetPlatform.android &&
                          status.pinSupported) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await WidgetService.requestPin();
                              if (mounted) _reloadStatus();
                            },
                            icon: const Icon(Icons.add_to_home_screen_rounded),
                            label: const Text('添加到桌面'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            defaultTargetPlatform == TargetPlatform.iOS
                ? '添加方法：长按桌面空白处，点击“+”，搜索“萤”，选择小号或中号。'
                : '若一键添加不可用：长按桌面空白处，打开“小部件”，找到“萤”并拖到桌面。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview({
    required this.event,
    required this.settings,
    required this.color,
    required this.compact,
  });

  final CountdownEvent? event;
  final AppSettings settings;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scale = settings.widgetFontScale;
    return Semantics(
      label: compact ? '小号小部件预览' : '中号小部件预览',
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 150 : 170),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: event == null
            ? const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('萤', style: TextStyle(color: Colors.white70)),
                  Spacer(),
                  Text(
                    '添加一个倒数日',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (settings.widgetShowCategory && !compact)
                    Text(
                      event!.category,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  Text(
                    event!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${event!.displayDays}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (compact ? 38 : 44) * scale,
                          fontWeight: FontWeight.w800,
                          height: 0.95,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          '天',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  if (!compact &&
                      settings.widgetShowNote &&
                      event!.note.isNotEmpty)
                    Text(
                      event!.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                ],
              ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
