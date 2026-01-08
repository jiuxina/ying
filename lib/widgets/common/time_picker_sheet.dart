import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ============================================================================
/// 统一时间选择器 - 时/分/秒 三个滚轮并排显示
/// ============================================================================

class TimePickerSheet extends StatefulWidget {
  final int initialHour;
  final int initialMinute;
  final int initialSecond;
  final bool showSeconds;
  final ValueChanged<TimeOfDayWithSeconds>? onTimeChanged;

  const TimePickerSheet({
    super.key,
    this.initialHour = 0,
    this.initialMinute = 0,
    this.initialSecond = 0,
    this.showSeconds = true,
    this.onTimeChanged,
  });

  @override
  State<TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<TimePickerSheet> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _secondController;

  late int _hour;
  late int _minute;
  late int _second;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialHour;
    _minute = widget.initialMinute;
    _second = widget.initialSecond;

    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
    _secondController = FixedExtentScrollController(initialItem: _second);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onTimeChanged?.call(TimeOfDayWithSeconds(
      hour: _hour,
      minute: _minute,
      second: _second,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 当前时间显示
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}:${_second.toString().padLeft(2, '0')}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        // 滚轮选择器
        SizedBox(
          height: 180,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 小时
              _buildWheelColumn(
                context: context,
                label: '时',
                controller: _hourController,
                itemCount: 24,
                selectedValue: _hour,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() => _hour = value);
                  _notifyChange();
                },
              ),
              // 分隔符
              _buildSeparator(context),
              // 分钟
              _buildWheelColumn(
                context: context,
                label: '分',
                controller: _minuteController,
                itemCount: 60,
                selectedValue: _minute,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() => _minute = value);
                  _notifyChange();
                },
              ),
              // 分隔符
              if (widget.showSeconds) _buildSeparator(context),
              // 秒数
              if (widget.showSeconds)
                _buildWheelColumn(
                  context: context,
                  label: '秒',
                  controller: _secondController,
                  itemCount: 60,
                  selectedValue: _second,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _second = value);
                    _notifyChange();
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWheelColumn({
    required BuildContext context,
    required String label,
    required FixedExtentScrollController controller,
    required int itemCount,
    required int selectedValue,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // 标签
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        // 滚轮
        SizedBox(
          width: 60,
          height: 150,
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 40,
            perspective: 0.005,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: itemCount,
              builder: (context, index) {
                final isSelected = index == selectedValue;
                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 150),
                    style: TextStyle(
                      fontSize: isSelected ? 24 : 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    child: Text(index.toString().padLeft(2, '0')),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        ':',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w300,
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
    );
  }
}

/// 带秒数的时间数据类
class TimeOfDayWithSeconds {
  final int hour;
  final int minute;
  final int second;

  const TimeOfDayWithSeconds({
    required this.hour,
    required this.minute,
    required this.second,
  });

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
}

/// 显示时间选择器
Future<TimeOfDayWithSeconds?> showTimePickerSheet({
  required BuildContext context,
  int initialHour = 0,
  int initialMinute = 0,
  int initialSecond = 0,
  bool showSeconds = true,
}) async {
  TimeOfDayWithSeconds? selectedTime;

  await showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      TimeOfDayWithSeconds tempTime = TimeOfDayWithSeconds(
        hour: initialHour,
        minute: initialMinute,
        second: initialSecond,
      );
      
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  '选择时间',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TimePickerSheet(
                  initialHour: initialHour,
                  initialMinute: initialMinute,
                  initialSecond: initialSecond,
                  showSeconds: showSeconds,
                  onTimeChanged: (time) {
                    tempTime = time;
                  },
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            selectedTime = tempTime;
                            Navigator.pop(context);
                          },
                          child: const Text('确定'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    },
  );

  return selectedTime;
}
