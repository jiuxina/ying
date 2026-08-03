import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/countdown_event.dart';
import '../models/event_reminder.dart';
import '../models/event_repeat.dart';
import '../services/notification_service.dart';
import '../state/app_controller.dart';
import '../utils/event_date_utils.dart';
import 'glass_ui.dart';
import 'reminder_editor.dart';

class EventFormSheet extends ConsumerStatefulWidget {
  const EventFormSheet({super.key, this.event});

  final CountdownEvent? event;

  @override
  ConsumerState<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends ConsumerState<EventFormSheet> {
  static const categories = ['生活', '工作', '学习', '纪念日', '旅行', '其他'];
  static const reminderOptions = <int, String>{
    0: '事件发生时',
    30: '提前 30 分钟',
    60: '提前 1 小时',
    1440: '提前 1 天',
    4320: '提前 3 天',
    10080: '提前 7 天',
  };
  static const maxReminderCount = 5;

  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController noteController;
  late DateTime targetDate;
  late String category;
  late CountDirection direction;
  late bool isAllDay;
  late EventRepeatType repeatType;
  late TimeOfDay rememberedTime;
  late List<EventReminder> selectedReminders;
  int reminderToAdd = 1440;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    titleController = TextEditingController(text: event?.title ?? '');
    noteController = TextEditingController(text: event?.note ?? '');
    isAllDay = event?.isAllDay ?? true;
    repeatType = event?.repeatType ?? EventRepeatType.none;
    final initialDate =
        event?.targetDate ??
        dateOnly(DateTime.now().add(const Duration(days: 30)));
    targetDate = isAllDay ? dateOnly(initialDate) : initialDate;
    rememberedTime = event == null || event.isAllDay
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay.fromDateTime(event.targetDate);
    category = event?.category ?? categories.first;
    direction = event?.direction ?? CountDirection.auto;
    selectedReminders = [...?event?.reminders];
  }

  @override
  void dispose() {
    titleController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, bottomInset + 12),
        child: GlassSurface(
          radius: 24,
          opacity: Theme.of(context).brightness == Brightness.dark
              ? 0.15
              : 0.78,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.event == null ? '新建日子' : '编辑日子',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.event == null
                                  ? '收藏一个值得期待的时刻'
                                  : '调整日期、提醒和显示方式',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GlassIconButton(
                        icon: Icons.close_rounded,
                        tooltip: '关闭',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleController,
                    autofocus: widget.event == null,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '事件名称',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? '请输入事件名称'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _QuickDatePicker(
                    targetDate: targetDate,
                    onSelected: _applyShortcut,
                    onCustom: _pickDate,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: isAllDay,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('全天事件'),
                    subtitle: const Text('全天事件只记录日期，提醒以当天 09:00 为基准'),
                    secondary: const Icon(Icons.today_outlined),
                    onChanged: _toggleAllDay,
                  ),
                  const SizedBox(height: 4),
                  _DateTimeTile(
                    targetDate: targetDate,
                    isAllDay: isAllDay,
                    onTap: isAllDay ? _pickDate : _pickDateTime,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(
                      labelText: '分类标签',
                      prefixIcon: Icon(Icons.sell_outlined),
                    ),
                    items: categories
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => category = value!),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '计时方式',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<CountDirection>(
                    segments: const [
                      ButtonSegment(
                        value: CountDirection.auto,
                        label: Text('自动'),
                        icon: Icon(Icons.sync_rounded),
                      ),
                      ButtonSegment(
                        value: CountDirection.countdown,
                        label: Text('倒计时'),
                      ),
                      ButtonSegment(
                        value: CountDirection.countup,
                        label: Text('正计时'),
                      ),
                    ],
                    selected: {direction},
                    onSelectionChanged: (value) {
                      setState(() => direction = value.first);
                    },
                    showSelectedIcon: false,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<EventRepeatType>(
                    initialValue: repeatType,
                    decoration: const InputDecoration(
                      labelText: '重复',
                      prefixIcon: Icon(Icons.repeat_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: EventRepeatType.none,
                        child: Text('不重复'),
                      ),
                      DropdownMenuItem(
                        value: EventRepeatType.yearly,
                        child: Text('每年'),
                      ),
                    ],
                    onChanged: (value) => setState(
                      () => repeatType = value ?? EventRepeatType.none,
                    ),
                  ),
                  if (repeatType == EventRepeatType.yearly) ...[
                    const SizedBox(height: 6),
                    Text(
                      targetDate.month == 2 && targetDate.day == 29
                          ? '非闰年会自动跳过，下一次仍为 2 月 29 日。'
                          : '完成后自动进入下一年的同一天。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ReminderEditor(
                    reminders: selectedReminders,
                    options: reminderOptions,
                    reminderToAdd: reminderToAdd,
                    maxCount: maxReminderCount,
                    onOptionChanged: (value) {
                      setState(() => reminderToAdd = value);
                    },
                    onAdd: _addReminder,
                    onRemove: _removeReminder,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '备注（可选）',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isSaving ? null : _save,
                      icon: isSaving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(widget.event == null ? '创建日子' : '保存修改'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _applyShortcut(EventDateShortcut shortcut) {
    final date = applyEventDateShortcut(shortcut);
    setState(() {
      targetDate = isAllDay
          ? date
          : DateTime(
              date.year,
              date.month,
              date.day,
              rememberedTime.hour,
              rememberedTime.minute,
            );
    });
  }

  void _toggleAllDay(bool value) {
    setState(() {
      if (value) {
        if (!isAllDay) {
          rememberedTime = TimeOfDay.fromDateTime(targetDate);
        }
        targetDate = dateOnly(targetDate);
      } else {
        targetDate = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          rememberedTime.hour,
          rememberedTime.minute,
        );
      }
      isAllDay = value;
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: targetDate,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    setState(() {
      targetDate = isAllDay
          ? dateOnly(date)
          : DateTime(
              date.year,
              date.month,
              date.day,
              rememberedTime.hour,
              rememberedTime.minute,
            );
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: targetDate,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: rememberedTime,
    );
    if (time == null || !mounted) return;
    setState(() {
      rememberedTime = time;
      targetDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _addReminder() {
    if (selectedReminders.length >= maxReminderCount ||
        selectedReminders.any(
          (reminder) => reminder.minutesBefore == reminderToAdd,
        )) {
      return;
    }
    setState(() {
      selectedReminders = EventReminder.normalize([
        ...selectedReminders,
        EventReminder(id: const Uuid().v4(), minutesBefore: reminderToAdd),
      ]);
    });
  }

  void _removeReminder(EventReminder reminder) {
    setState(() {
      selectedReminders = selectedReminders
          .where((value) => value.id != reminder.id)
          .toList();
    });
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isSaving = true);
    if (selectedReminders.isNotEmpty) {
      await NotificationService.instance.requestPermission();
    }
    final existing = widget.event;
    final event = CountdownEvent(
      id: existing?.id ?? const Uuid().v4(),
      title: titleController.text.trim(),
      targetDate: targetDate,
      category: category,
      note: noteController.text.trim(),
      direction: direction,
      reminders: EventReminder.normalize(selectedReminders),
      isAllDay: isAllDay,
      isCompleted: repeatType == EventRepeatType.yearly
          ? false
          : existing?.isCompleted ?? false,
      isPinned: existing?.isPinned ?? false,
      repeatType: repeatType,
      repeatMonth: repeatType == EventRepeatType.yearly
          ? targetDate.month
          : null,
      repeatDay: repeatType == EventRepeatType.yearly ? targetDate.day : null,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    await ref.read(appControllerProvider.notifier).saveEvent(event);
    if (mounted) Navigator.pop(context);
  }
}

class _QuickDatePicker extends StatelessWidget {
  const _QuickDatePicker({
    required this.targetDate,
    required this.onSelected,
    required this.onCustom,
  });

  final DateTime targetDate;
  final ValueChanged<EventDateShortcut> onSelected;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    const values = <EventDateShortcut, String>{
      EventDateShortcut.today: '今天',
      EventDateShortcut.tomorrow: '明天',
      EventDateShortcut.nextWeek: '一周后',
      EventDateShortcut.nextMonth: '一个月后',
      EventDateShortcut.yearEnd: '今年年底',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快捷日期',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in values.entries)
              ActionChip(
                label: Text(entry.value),
                onPressed: () => onSelected(entry.key),
              ),
            ActionChip(
              avatar: const Icon(Icons.edit_calendar_outlined, size: 18),
              label: const Text('自定义'),
              onPressed: onCustom,
            ),
          ],
        ),
      ],
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.targetDate,
    required this.isAllDay,
    required this.onTap,
  });

  final DateTime targetDate;
  final bool isAllDay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '目标日期',
          prefixIcon: Icon(Icons.event_outlined),
        ),
        child: Text(
          isAllDay
              ? '${DateFormat('yyyy年M月d日', 'zh_CN').format(targetDate)} · 全天'
              : DateFormat('yyyy年M月d日  HH:mm', 'zh_CN').format(targetDate),
        ),
      ),
    );
  }
}
