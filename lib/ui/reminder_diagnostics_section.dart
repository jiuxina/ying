import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/countdown_event.dart';
import '../services/notification_service.dart';
import 'glass_ui.dart';

class ReminderDiagnosticsSection extends StatefulWidget {
  const ReminderDiagnosticsSection({super.key, required this.events});

  final List<CountdownEvent> events;

  @override
  State<ReminderDiagnosticsSection> createState() =>
      _ReminderDiagnosticsSectionState();
}

class _ReminderDiagnosticsSectionState
    extends State<ReminderDiagnosticsSection> {
  late Future<NotificationDiagnostics> diagnosticsFuture;
  bool schedulingTest = false;

  @override
  void initState() {
    super.initState();
    diagnosticsFuture = _loadDiagnostics();
  }

  @override
  void didUpdateWidget(ReminderDiagnosticsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.events, widget.events)) _refresh();
  }

  Future<NotificationDiagnostics> _loadDiagnostics() =>
      NotificationService.instance.diagnostics(widget.events);

  void _refresh() {
    if (!mounted) return;
    setState(() => diagnosticsFuture = _loadDiagnostics());
  }

  Future<void> _sendTest() async {
    setState(() => schedulingTest = true);
    try {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('通知权限未开启，请在系统设置中允许通知。')));
        }
        return;
      }
      await NotificationService.instance.scheduleTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('测试提醒已安排，预计约 5 秒后出现。')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('测试提醒安排失败：$error')));
      }
    } finally {
      if (mounted) {
        setState(() => schedulingTest = false);
        _refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassSectionTitle(title: '提醒诊断', subtitle: '检查权限、调度状态与下一条提醒'),
          const SizedBox(height: 14),
          FutureBuilder<NotificationDiagnostics>(
            future: diagnosticsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator.adaptive(),
                  ),
                );
              }
              final diagnostics = snapshot.data!;
              final next = diagnostics.nextReminder;
              return Column(
                children: [
                  _DiagnosticRow(
                    icon: diagnostics.notificationsEnabled == true
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    color: diagnostics.notificationsEnabled == true
                        ? GlassPalette.mint
                        : GlassPalette.orange,
                    title: '通知权限',
                    value: switch (diagnostics.notificationsEnabled) {
                      true => '已开启',
                      false => '未开启',
                      null => '无法确定',
                    },
                  ),
                  const _DiagnosticDivider(),
                  _DiagnosticRow(
                    icon: Icons.pending_actions_outlined,
                    color: GlassPalette.indigo,
                    title: '系统待调度',
                    value: '${diagnostics.pendingCount} 条',
                  ),
                  const _DiagnosticDivider(),
                  _DiagnosticRow(
                    icon: Icons.schedule_outlined,
                    color: GlassPalette.blue,
                    title: '下一条提醒',
                    value: next == null
                        ? '暂无未来提醒'
                        : '${next.event.title}\n${DateFormat('M月d日 HH:mm', 'zh_CN').format(next.scheduledAt)}',
                  ),
                  if (diagnostics.error != null) ...[
                    const _DiagnosticDivider(),
                    _DiagnosticRow(
                      icon: Icons.error_outline_rounded,
                      color: GlassPalette.orange,
                      title: '诊断异常',
                      value: diagnostics.error!,
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('刷新状态'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: schedulingTest ? null : _sendTest,
                  icon: schedulingTest
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.notification_add_outlined),
                  label: const Text('测试提醒'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _platformHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  String get _platformHint {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Android 提醒使用允许待机的非精确调度。若提醒延迟，请检查系统电池优化、自启动和后台运行限制；不同厂商的限制可能不同。';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'iOS 对待触发本地通知总量有限制。萤会为系统槽位预留空间，并优先安排时间最近的提醒。';
    }
    return '提醒能否准时出现仍受系统通知权限和后台调度策略影响。';
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: GlassStatusPill(label: value, color: color, maxLines: 3),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticDivider extends StatelessWidget {
  const _DiagnosticDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Theme.of(context).dividerColor);
  }
}
