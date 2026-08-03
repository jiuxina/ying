import 'package:flutter/material.dart';

import '../models/event_reminder.dart';

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
                child: DropdownButtonFormField<int>(
                  initialValue: reminderToAdd,
                  decoration: const InputDecoration(
                    labelText: '添加提醒',
                    isDense: true,
                  ),
                  items: options.entries
                      .map(
                        (entry) => DropdownMenuItem<int>(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onOptionChanged(value);
                  },
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
}
