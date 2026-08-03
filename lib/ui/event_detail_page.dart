import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/countdown_event.dart';
import '../models/event_reminder.dart';
import '../state/app_controller.dart';
import 'event_form_sheet.dart';
import 'glass_ui.dart';

class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    CountdownEvent? event;
    for (final value in state.events) {
      if (value.id == eventId) {
        event = value;
        break;
      }
    }
    if (event == null) {
      if (state.isLoading) {
        return const Scaffold(
          backgroundColor: Colors.transparent,
          body: LiquidBackground(
            child: Center(child: CircularProgressIndicator.adaptive()),
          ),
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    final current = event;
    final dateText = current.isAllDay
        ? '${DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(current.targetDate)} · 全天'
        : DateFormat(
            'yyyy年M月d日 EEEE HH:mm',
            'zh_CN',
          ).format(current.targetDate);
    final reminderText = current.reminders.isEmpty
        ? '不提醒'
        : current.reminders
              .where((reminder) => reminder.enabled)
              .map(
                (reminder) =>
                    EventReminder.labelForMinutes(reminder.minutesBefore),
              )
              .join('、');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  child: Row(
                    children: [
                      GlassIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: '返回',
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      GlassIconButton(
                        icon: Icons.edit_outlined,
                        tooltip: '编辑',
                        onPressed: () => _openEdit(context, current),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList.list(
                  children: [
                    GlassSurface(
                      radius: 24,
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            current.statusLabel,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: current.isCompleted
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant
                                      : Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            current.title,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.6,
                                ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                current.dayDelta() == 0
                                    ? '今'
                                    : '${current.displayDays}',
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: current.isCompleted
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      height: 0.9,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  current.dayDelta() == 0 ? '就是今天' : '天',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassSurface(
                      radius: 20,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.event_outlined,
                            label: '目标日期',
                            value: dateText,
                          ),
                          _DetailRow(
                            icon: Icons.sell_outlined,
                            label: '分类',
                            value: current.category,
                          ),
                          _DetailRow(
                            icon: Icons.notifications_outlined,
                            label: '提醒',
                            value: reminderText,
                          ),
                          _DetailRow(
                            icon: Icons.repeat_rounded,
                            label: '重复',
                            value: current.repeatsYearly ? '每年' : '不重复',
                          ),
                          _DetailRow(
                            icon: Icons.schedule_outlined,
                            label: '创建时间',
                            value: DateFormat(
                              'yyyy年M月d日 HH:mm',
                              'zh_CN',
                            ).format(current.createdAt),
                          ),
                        ],
                      ),
                    ),
                    if (current.note.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      GlassSurface(
                        radius: 20,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '备注',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              current.note,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(height: 1.55),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        GlassIconButton(
                          tooltip: current.isPinned ? '取消置顶' : '置顶事件',
                          onPressed: () => ref
                              .read(appControllerProvider.notifier)
                              .togglePinned(current),
                          icon: current.isPinned
                              ? Icons.push_pin_rounded
                              : Icons.push_pin_outlined,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => ref
                                .read(appControllerProvider.notifier)
                                .toggleCompletedWithUndo(current),
                            icon: Icon(
                              current.isCompleted
                                  ? Icons.restore_rounded
                                  : Icons.check_rounded,
                            ),
                            label: Text(
                              current.repeatsYearly && !current.isCompleted
                                  ? '进入下一年'
                                  : current.isCompleted
                                  ? '恢复事件'
                                  : '标记完成',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GlassIconButton(
                          tooltip: '删除事件',
                          onPressed: () async {
                            await ref
                                .read(appControllerProvider.notifier)
                                .deleteEventWithUndo(current);
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: Icons.delete_outline_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, CountdownEvent event) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: const BoxConstraints(maxWidth: 680),
        builder: (context) => EventFormSheet(event: event),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
