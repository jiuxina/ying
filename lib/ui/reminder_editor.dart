import 'package:flutter/material.dart';

import '../models/event_reminder.dart';
import 'glass_ui.dart';

class ReminderEditor extends StatelessWidget {
  const ReminderEditor({
    super.key,
    required this.reminders,
    required this.options,
    required this.reminderToAdd,
    required this.maxCount,
    required this.onOptionChanged,
    required this.onAdd,
    required this.onRemove,
  });

  final List<EventReminder> reminders;
  final Map<int, String> options;
  final int reminderToAdd;
  final int maxCount;
  final ValueChanged<int> onOptionChanged;
  final VoidCallback onAdd;
  final ValueChanged<EventReminder> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duplicate = reminders.any(
      (reminder) => reminder.minutesBefore == reminderToAdd,
    );
    final canAdd = reminders.length < maxCount && !duplicate;
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '提醒',
        prefixIcon: Icon(Icons.notifications_outlined),
        alignLabelWithHint: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reminders.isEmpty)
            Text(
              '暂未设置提醒',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final reminder in reminders)
                  InputChip(
                    label: Text(
                      EventReminder.labelForMinutes(reminder.minutesBefore),
                    ),
                    onDeleted: () => onRemove(reminder),
                  ),
              ],
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: '添加提醒，当前${options[reminderToAdd] ?? '未选择'}',
                  hint: '点击选择提醒时间',
                  child: InkWell(
                    onTap: () => _openPicker(context),
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '添加提醒',
                        isDense: true,
                      ),
                      child: Text(options[reminderToAdd] ?? '选择提醒'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: duplicate
                    ? '该提醒已存在'
                    : reminders.length >= maxCount
                    ? '最多 $maxCount 条提醒'
                    : '添加提醒',
                onPressed: canAdd ? onAdd : null,
                icon: const Icon(Icons.add_alert_rounded),
              ),
            ],
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

  Future<void> _openPicker(BuildContext context) async {
    final value = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: GlassSurface(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '选择提醒时间',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 10),
                for (final entry in options.entries)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GlassChoiceTile(
                      icon: Icons.notifications_none_rounded,
                      title: entry.value,
                      value: '',
                      selected: entry.key == reminderToAdd,
                      onTap: () => Navigator.pop(context, entry.key),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (value != null) onOptionChanged(value);
  }
}
