import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/event_reminder.dart';
import 'glass_ui.dart';

const _wheelRowExtent = 44.0;
const _wheelVisibleRows = 5;
const _weekdayNames = [
  '星期一',
  '星期二',
  '星期三',
  '星期四',
  '星期五',
  '星期六',
  '星期日',
];

/// 自定义提醒在选项弹层中的哨兵值，分钟数不可能为负。
const reminderPickerCustomToken = -1;

/// 滚轮未构建（positions 为空）时回退到 initialItem，
/// 保证 build/initState 阶段读取当前值不会断言。
int _wheelIndexOf(FixedExtentScrollController controller) =>
    controller.positions.isNotEmpty
    ? controller.selectedItem
    : controller.initialItem;

String chineseWeekday(DateTime date) => _weekdayNames[date.weekday - 1];

String formatCnDate(DateTime date) => '${date.year}年${date.month}月${date.day}日';

String formatCnTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

int daysInCnMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// 与 CountdownEvent.calendarDayDelta 相同的 UTC 口径，避免夏令时影响。
int _calendarDelta(DateTime from, DateTime to) {
  final start = DateTime.utc(from.year, from.month, from.day);
  final end = DateTime.utc(to.year, to.month, to.day);
  return end.difference(start).inDays;
}

String _relativeDayLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final delta = _calendarDelta(today, date);
  if (delta == 0) return '就是今天';
  if (delta == 1) return '明天';
  if (delta == -1) return '昨天';
  return delta > 0 ? '还有 $delta 天' : '已过去 ${-delta} 天';
}

/// 打开自定义的中文轮盘式日期选择弹层（不含时间）。
Future<DateTime?> showGlassWheelDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showGlassBottomSheet<DateTime>(
    isScrollControlled: true,
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => _WheelDateTimeSheet(
      initial: initialDate,
      includeTime: false,
      firstDate: firstDate ?? DateTime(1970),
      lastDate: lastDate ?? DateTime(2100),
    ),
  );
}

/// 打开日期 + 时间一体的轮盘选择弹层，替代原生两次弹窗。
Future<DateTime?> showGlassWheelDateTimePicker({
  required BuildContext context,
  required DateTime initialDateTime,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showGlassBottomSheet<DateTime>(
    isScrollControlled: true,
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => _WheelDateTimeSheet(
      initial: initialDateTime,
      includeTime: true,
      firstDate: firstDate ?? DateTime(1970),
      lastDate: lastDate ?? DateTime(2100),
    ),
  );
}

/// 纯时间的轮盘选择弹层。
Future<TimeOfDay?> showGlassWheelTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showGlassBottomSheet<TimeOfDay>(
    isScrollControlled: true,
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => _WheelTimeSheet(initial: initialTime),
  );
}

/// 自定义提醒提前量：返回相对事件开始的分钟数。
Future<int?> showGlassReminderOffsetPicker({
  required BuildContext context,
  required int initialMinutes,
}) {
  return showGlassBottomSheet<int>(
    isScrollControlled: true,
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => _ReminderOffsetSheet(initialMinutes: initialMinutes),
  );
}

/// 单列轮盘：玻璃风格的高亮带与滚轮动效由外层负责。
class GlassWheelColumn extends StatelessWidget {
  const GlassWheelColumn({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.labelBuilder,
    required this.onSelectedItemChanged,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final String Function(int index) labelBuilder;
  final ValueChanged<int> onSelectedItemChanged;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      // 每列可能渲染上百个子项，语义由外层 Semantics 汇总播报。
      child: ExcludeSemantics(
        child: ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: _wheelRowExtent,
          diameterRatio: 1.9,
          perspective: 0.0022,
          squeeze: 1.25,
          physics: const FixedExtentScrollPhysics(),
          useMagnifier: true,
          magnification: 1.08,
          overAndUnderCenterOpacity: 0.45,
          onSelectedItemChanged: onSelectedItemChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: itemCount,
            builder: (context, index) {
              if (index < 0 || index >= itemCount) return null;
              return Center(
                child: Text(labelBuilder(index), maxLines: 1, style: style),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PickerFrame extends StatelessWidget {
  const _PickerFrame({
    required this.title,
    required this.preview,
    required this.body,
    required this.onConfirm,
  });

  final String title;
  final Widget preview;
  final Widget body;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
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
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
                  GlassIconButton(
                    icon: Icons.close_rounded,
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              preview,
              const SizedBox(height: 6),
              body,
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onConfirm,
                      child: const Text('确定'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WheelDateTimeSheet extends StatefulWidget {
  const _WheelDateTimeSheet({
    required this.initial,
    required this.includeTime,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initial;
  final bool includeTime;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_WheelDateTimeSheet> createState() => _WheelDateTimeSheetState();
}

class _WheelDateTimeSheetState extends State<_WheelDateTimeSheet> {
  late final List<int> _years;
  late final FixedExtentScrollController _yearCtrl;
  late final FixedExtentScrollController _monthCtrl;
  late final FixedExtentScrollController _dayCtrl;
  // 时间列控制器始终创建（成本极低），仅在 includeTime 时渲染，
  // 避免空安全下到处使用断言。
  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;
  bool _clamping = false;

  @override
  void initState() {
    super.initState();
    final firstYear = widget.firstDate.year;
    final lastYear = widget.lastDate.year;
    _years = [for (var y = firstYear; y <= lastYear; y++) y];
    var initial = widget.initial;
    if (initial.isBefore(widget.firstDate)) initial = widget.firstDate;
    if (initial.isAfter(widget.lastDate)) initial = widget.lastDate;
    _yearCtrl = FixedExtentScrollController(
      initialItem: initial.year - firstYear,
    );
    _monthCtrl = FixedExtentScrollController(initialItem: initial.month - 1);
    _dayCtrl = FixedExtentScrollController(initialItem: initial.day - 1);
    _hourCtrl = FixedExtentScrollController(initialItem: initial.hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: initial.minute);
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  int get _year => _years[_wheelIndexOf(_yearCtrl)];

  int get _month => _wheelIndexOf(_monthCtrl) + 1;

  int get _dayCount => daysInCnMonth(_year, _month);

  int get _day => math.min(_wheelIndexOf(_dayCtrl) + 1, _dayCount);

  DateTime get _selected => DateTime(
    _year,
    _month,
    _day,
    widget.includeTime ? _wheelIndexOf(_hourCtrl) : 0,
    widget.includeTime ? _wheelIndexOf(_minuteCtrl) : 0,
  );

  void _syncDayClamp() {
    final maxIndex = _dayCount - 1;
    if (_wheelIndexOf(_dayCtrl) <= maxIndex) return;
    _clamping = true;
    try {
      _dayCtrl.jumpToItem(maxIndex);
    } finally {
      _clamping = false;
    }
  }

  void _handleDateChanged(int _) {
    if (_clamping) return;
    HapticFeedback.selectionClick();
    _syncDayClamp();
    setState(() {});
  }

  void _handleTimeChanged(int _) {
    if (_clamping) return;
    HapticFeedback.selectionClick();
    setState(() {});
  }

  void _confirm() {
    HapticFeedback.lightImpact();
    Navigator.pop(context, _selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = _selected;
    final dateLabel = widget.includeTime
        ? '${formatCnDate(selected)} ${chineseWeekday(selected)} ${formatCnTime(TimeOfDay.fromDateTime(selected))}'
        : '${formatCnDate(selected)} ${chineseWeekday(selected)}';
    final preview = Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.includeTime
                ? '${_relativeDayLabel(selected)} · 提醒按所选时间'
                : _relativeDayLabel(selected),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    Widget wheel({
      required int flex,
      required String semanticLabel,
      required String semanticValue,
      required FixedExtentScrollController controller,
      required int count,
      required String Function(int) labelFor,
      bool isDateColumn = true,
    }) {
      return Expanded(
        flex: flex,
        child: Semantics(
          label: '选择$semanticLabel',
          value: semanticValue,
          child: GlassWheelColumn(
            controller: controller,
            itemCount: count,
            labelBuilder: labelFor,
            onSelectedItemChanged: isDateColumn
                ? _handleDateChanged
                : _handleTimeChanged,
          ),
        ),
      );
    }

    final body = SizedBox(
      height: _wheelRowExtent * _wheelVisibleRows,
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Container(
                height: _wheelRowExtent,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              wheel(
                flex: 3,
                semanticLabel: '年份',
                semanticValue: '$_year年',
                controller: _yearCtrl,
                count: _years.length,
                labelFor: (index) => '${_years[index]}年',
              ),
              wheel(
                flex: 2,
                semanticLabel: '月份',
                semanticValue: '$_month月',
                controller: _monthCtrl,
                count: 12,
                labelFor: (index) => '${index + 1}月',
              ),
              wheel(
                flex: 2,
                semanticLabel: '日期',
                semanticValue: '$_day日',
                controller: _dayCtrl,
                count: _dayCount,
                labelFor: (index) => '${index + 1}日',
              ),
              if (widget.includeTime) ...[
                wheel(
                  flex: 2,
                  semanticLabel: '小时',
                  semanticValue: '${_wheelIndexOf(_hourCtrl)}时',
                  controller: _hourCtrl,
                  count: 24,
                  labelFor: (index) => '$index时',
                  isDateColumn: false,
                ),
                wheel(
                  flex: 2,
                  semanticLabel: '分钟',
                  semanticValue: '${_wheelIndexOf(_minuteCtrl)}分',
                  controller: _minuteCtrl,
                  count: 60,
                  labelFor: (index) =>
                      '${index.toString().padLeft(2, '0')}分',
                  isDateColumn: false,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return _PickerFrame(
      title: widget.includeTime ? '选择日期时间' : '选择日期',
      preview: preview,
      body: body,
      onConfirm: _confirm,
    );
  }
}

class _WheelTimeSheet extends StatefulWidget {
  const _WheelTimeSheet({required this.initial});

  final TimeOfDay initial;

  @override
  State<_WheelTimeSheet> createState() => _WheelTimeSheetState();
}

class _WheelTimeSheetState extends State<_WheelTimeSheet> {
  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;

  @override
  void initState() {
    super.initState();
    _hourCtrl = FixedExtentScrollController(initialItem: widget.initial.hour);
    _minuteCtrl = FixedExtentScrollController(
      initialItem: widget.initial.minute,
    );
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  TimeOfDay get _selected =>
      TimeOfDay(hour: _wheelIndexOf(_hourCtrl), minute: _wheelIndexOf(_minuteCtrl));

  String _periodLabel(int hour) => hour < 12 ? '上午' : '下午';

  void _confirm() {
    HapticFeedback.lightImpact();
    Navigator.pop(context, _selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = _selected;
    final preview = Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Text(
        '${_periodLabel(selected.hour)} ${formatCnTime(selected)}',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final body = SizedBox(
      height: _wheelRowExtent * _wheelVisibleRows,
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Container(
                height: _wheelRowExtent,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Semantics(
                  label: '选择小时',
                  value: '${selected.hour}时',
                  child: GlassWheelColumn(
                    controller: _hourCtrl,
                    itemCount: 24,
                    labelBuilder: (index) => '$index时',
                    onSelectedItemChanged: (index) {
                      HapticFeedback.selectionClick();
                      setState(() {});
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Semantics(
                  label: '选择分钟',
                  value: '${selected.minute}分',
                  child: GlassWheelColumn(
                    controller: _minuteCtrl,
                    itemCount: 60,
                    labelBuilder: (index) =>
                        '${index.toString().padLeft(2, '0')}分',
                    onSelectedItemChanged: (index) {
                      HapticFeedback.selectionClick();
                      setState(() {});
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return _PickerFrame(title: '选择时间', preview: preview, body: body, onConfirm: _confirm);
  }
}

class _ReminderOffsetSheet extends StatefulWidget {
  const _ReminderOffsetSheet({required this.initialMinutes});

  final int initialMinutes;

  @override
  State<_ReminderOffsetSheet> createState() => _ReminderOffsetSheetState();
}

class _ReminderOffsetSheetState extends State<_ReminderOffsetSheet> {
  static const _units = [('分钟', 1), ('小时', 60), ('天', 1440)];

  late final FixedExtentScrollController _countCtrl;
  late final FixedExtentScrollController _unitCtrl;
  bool _clamping = false;

  int get _unitFactor => _units[_wheelIndexOf(_unitCtrl)].$2;

  int get _maxCount => _unitFactor >= 1440 ? 90 : 59;

  int get _count => math.min(_wheelIndexOf(_countCtrl) + 1, _maxCount);

  int get _minutes => _count * _unitFactor;

  @override
  void initState() {
    super.initState();
    var unitIndex = 0;
    var count = widget.initialMinutes;
    if (count > 0 && count % 1440 == 0) {
      unitIndex = 2;
      count ~/= 1440;
    } else if (count > 0 && count % 60 == 0) {
      unitIndex = 1;
      count ~/= 60;
    }
    _unitCtrl = FixedExtentScrollController(initialItem: unitIndex);
    _countCtrl = FixedExtentScrollController(
      initialItem: count.clamp(1, _maxCount) - 1,
    );
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  void _handleCountChanged(int _) {
    if (_clamping) return;
    HapticFeedback.selectionClick();
    setState(() {});
  }

  void _handleUnitChanged(int _) {
    if (_clamping) return;
    HapticFeedback.selectionClick();
    final maxIndex = _maxCount - 1;
    if (_wheelIndexOf(_countCtrl) > maxIndex) {
      _clamping = true;
      try {
        _countCtrl.jumpToItem(maxIndex);
      } finally {
        _clamping = false;
      }
    }
    setState(() {});
  }

  void _confirm() {
    HapticFeedback.lightImpact();
    Navigator.pop(context, _minutes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unitName = _units[_wheelIndexOf(_unitCtrl)].$1;
    final preview = Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '提醒时间：${EventReminder.labelForMinutes(_minutes)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '基于事件开始时间计算，全天事件以当天 09:00 为基准。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    final body = SizedBox(
      height: _wheelRowExtent * _wheelVisibleRows,
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Container(
                height: _wheelRowExtent,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Semantics(
                  label: '选择提醒提前数量',
                  value: '$_count',
                  child: GlassWheelColumn(
                    controller: _countCtrl,
                    itemCount: _maxCount,
                    labelBuilder: (index) => '${index + 1}',
                    onSelectedItemChanged: _handleCountChanged,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Semantics(
                  label: '选择提醒提前单位',
                  value: unitName,
                  child: GlassWheelColumn(
                    controller: _unitCtrl,
                    itemCount: _units.length,
                    labelBuilder: (index) => _units[index].$1,
                    onSelectedItemChanged: _handleUnitChanged,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return _PickerFrame(title: '自定义提醒时间', preview: preview, body: body, onConfirm: _confirm);
  }
}
