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
import '../utils/widget_content_utils.dart';
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
  late String icon;
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
    icon = event?.icon ?? '';
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
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.82,
              ),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.4,
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
                      validator: (value) =>
                          value == null || value.trim().isEmpty
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
                    GlassChoiceTile(
                      icon: Icons.today_outlined,
                      title: '全天事件',
                      value: isAllDay ? '已开启' : '已关闭',
                      subtitle: '全天事件只记录日期，提醒以当天 09:00 为基准',
                      selected: isAllDay,
                      trailing: GlassSwitch(
                        value: isAllDay,
                        onChanged: _toggleAllDay,
                      ),
                      onTap: () => _toggleAllDay(!isAllDay),
                    ),
                    const SizedBox(height: 4),
                    _DateTimeTile(
                      targetDate: targetDate,
                      isAllDay: isAllDay,
                      onTap: isAllDay ? _pickDate : _pickDateTime,
                    ),
                    const SizedBox(height: 12),
                    GlassChoiceTile(
                      icon: Icons.sell_outlined,
                      title: '分类标签',
                      value: category,
                      selected: true,
                      onTap: _pickCategory,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '事件图标',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _EmojiPicker(
                      value: icon,
                      onChanged: (value) => setState(() => icon = value),
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
                    _DirectionPicker(
                      value: direction,
                      onChanged: (value) => setState(() => direction = value),
                    ),
                    const SizedBox(height: 12),
                    GlassChoiceTile(
                      icon: Icons.repeat_rounded,
                      title: '重复',
                      value: repeatType == EventRepeatType.yearly
                          ? '每年'
                          : '不重复',
                      selected: repeatType == EventRepeatType.yearly,
                      onTap: _pickRepeat,
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
      ),
    );
  }

  Future<void> _pickCategory() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FormChoiceSheet<String>(
        title: '选择分类',
        value: category,
        options: categories,
      ),
    );
    if (value != null && mounted) setState(() => category = value);
  }

  Future<void> _pickRepeat() async {
    final value = await showModalBottomSheet<EventRepeatType>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FormChoiceSheet<EventRepeatType>(
        title: '重复周期',
        value: repeatType,
        options: const [EventRepeatType.none, EventRepeatType.yearly],
        labels: const {
          EventRepeatType.none: '不重复',
          EventRepeatType.yearly: '每年',
        },
      ),
    );
    if (value != null && mounted) setState(() => repeatType = value);
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
    var notificationsAllowed = true;
    if (selectedReminders.isNotEmpty) {
      notificationsAllowed =
          await NotificationService.instance.requestPermission();
    }
    final existing = widget.event;
    final event = CountdownEvent(
      id: existing?.id ?? const Uuid().v4(),
      title: titleController.text.trim(),
      targetDate: targetDate,
      category: category,
      icon: icon,
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
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    if (selectedReminders.isNotEmpty && !notificationsAllowed) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('通知权限未开启，提醒可能无法送达'),
          action: SnackBarAction(
            label: '去设置',
            onPressed: () {
              NotificationService.instance.openAppNotificationSettings();
            },
          ),
        ),
      );
    }
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

class _EmojiPicker extends StatelessWidget {
  const _EmojiPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final emoji in eventIconOptions)
          Semantics(
            button: true,
            selected: value == emoji,
            label: emoji.isEmpty ? '不使用图标' : '图标：$emoji',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(emoji),
                customBorder: const CircleBorder(),
                child: AnimatedContainer(
                  duration: motionDuration(
                    context,
                    const Duration(milliseconds: 160),
                  ),
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value == emoji
                        ? scheme.primary.withValues(alpha: 0.14)
                        : Colors.transparent,
                    border: Border.all(
                      color: value == emoji
                          ? scheme.primary.withValues(alpha: 0.45)
                          : scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  child: ExcludeSemantics(
                    child: emoji.isEmpty
                        ? Icon(
                            Icons.mood_bad_outlined,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          )
                        : Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
              ),
            ),
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

class _DirectionPicker extends StatelessWidget {
  const _DirectionPicker({required this.value, required this.onChanged});
  final CountDirection value;
  final ValueChanged<CountDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      (CountDirection.auto, '自动', Icons.sync_rounded),
      (CountDirection.countdown, '倒计时', Icons.south_rounded),
      (CountDirection.countup, '正计时', Icons.north_rounded),
    ];
    return Row(
      children: [
        for (var index = 0; index < options.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: _DirectionOption(
              icon: options[index].$3,
              label: options[index].$2,
              selected: value == options[index].$1,
              onTap: () => onChanged(options[index].$1),
            ),
          ),
        ],
      ],
    );
  }
}

class _DirectionOption extends StatelessWidget {
  const _DirectionOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '计时方式：$label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: motionDuration(context, const Duration(milliseconds: 180)),
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.34)
                  : scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormChoiceSheet<T> extends StatelessWidget {
  const _FormChoiceSheet({
    required this.title,
    required this.value,
    required this.options,
    this.labels = const {},
  });
  final String title;
  final T value;
  final List<T> options;
  final Map<T, String> labels;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: GlassSurface(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            for (final option in options)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GlassChoiceTile(
                  icon: Icons.radio_button_checked_rounded,
                  title: labels[option] ?? '$option',
                  value: '',
                  selected: option == value,
                  onTap: () => Navigator.pop(context, option),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

