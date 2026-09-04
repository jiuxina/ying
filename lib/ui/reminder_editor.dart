import 'package:flutter/material.dart';

import '../models/event_reminder.dart';
import 'glass_ui.dart';
import 'wheel_datetime_picker.dart';

class ReminderEditor extends StatelessWidget {
  const ReminderEditor({
    super.key,
    required this.reminders,
    required this.options,
    required this.maxCount,
    required this.onAdd,
    required this.onRemove,
  });

  final List<EventReminder> reminders;
  final Map<int, String> options;
  final int maxCount;
  final ValueChanged<int> onAdd;
  final ValueChanged<EventReminder> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '提醒',
        prefixIcon: Icon(Icons.notifications_outlined),
        alignLabelWithHint: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: motionDuration(context, AppMotion.state),
            switchInCurve: AppMotion.enter,
            switchOutCurve: AppMotion.exit,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1).animate(
                  CurvedAnimation(parent: animation, curve: AppMotion.enter),
                ),
                child: child,
              ),
            ),
            child: reminders.isEmpty
                ? Text(
                    '暂未设置提醒',
                    key: const ValueKey('no-reminders'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : Wrap(
                    key: const ValueKey('reminder-chips'),
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final reminder in reminders)
                        InputChip(
                          key: ValueKey('reminder-${reminder.id}'),
                          label: Text(
                            EventReminder.labelForMinutes(
                              reminder.minutesBefore,
                            ),
                          ),
                          onDeleted: () => onRemove(reminder),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Semantics(
              button: true,
              label: '添加提醒时间',
              child: OutlinedButton.icon(
                onPressed: () => _openPicker(context),
                icon: const Icon(Icons.add_alert_rounded, size: 19),
                label: const Text('添加提醒时间'),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '每个事件最多 $maxCount 条；全天事件均以当天 09:00 为基准。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionTile(BuildContext sheetContext, MapEntry<int, String> entry) {
    final added = reminders.any(
      (reminder) => reminder.minutesBefore == entry.key,
    );
    return GlassChoiceTile(
      icon: Icons.notifications_none_rounded,
      title: entry.value,
      value: added ? '已添加' : '',
      selected: added,
      onTap: () => Navigator.pop(sheetContext, entry.key),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showGlassBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: GlassSurface(
              radius: 24,
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '添加提醒',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      GlassIconButton(
                        icon: Icons.close_rounded,
                        tooltip: '关闭',
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final entry in options.entries)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _optionTile(sheetContext, entry),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GlassChoiceTile(
                      icon: Icons.tune_rounded,
                      title: '自定义提醒时间',
                      subtitle: '按分钟 / 小时 / 天自由设置',
                      value: '',
                      onTap: () => Navigator.pop(
                        sheetContext,
                        reminderPickerCustomToken,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (selected == null || !context.mounted) return;
    if (selected == reminderPickerCustomToken) {
      final minutes = await showGlassReminderOffsetPicker(
        context: context,
        initialMinutes: 1440,
      );
      if (minutes == null) return;
      onAdd(minutes);
      return;
    }
    onAdd(selected);
  }
}
