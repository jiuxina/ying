import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/responsive_utils.dart';

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
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveSpacing.base(context),
          ),
          child: Text(
            '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}:${_second.toString().padLeft(2, '0')}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: ResponsiveUtils.scaledSize(context, 2),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        // 滚轮选择器
        SizedBox(
          height: ResponsiveUtils.scaledSize(context, 180),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 小时
              Flexible(
                child: _buildWheelColumn(
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
              ),
              // 分隔符
              _buildSeparator(context),
              // 分钟
              Flexible(
                child: _buildWheelColumn(
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
              ),
              // 分隔符
              if (widget.showSeconds) _buildSeparator(context),
              // 秒数
              if (widget.showSeconds)
                Flexible(
                  child: _buildWheelColumn(
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
    final wheelWidth = ResponsiveUtils.scaledSize(context, 60);
    final wheelHeight = ResponsiveUtils.scaledSize(context, 150);
    final itemExtent = ResponsiveUtils.scaledSize(context, 40);
    
    return Column(
      children: [
        // 标签
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        SizedBox(height: ResponsiveSpacing.xs(context)),
        // 滚轮
        SizedBox(
          width: wheelWidth,
          height: wheelHeight,
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: itemExtent,
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
                      fontSize: isSelected
                          ? ResponsiveFontSize.title(context)
                          : ResponsiveFontSize.xl(context),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSpacing.sm(context),
      ),
      child: Text(
        ':',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w300,
              color: Theme.of(context).colorScheme.outline,
            ),
        overflow: TextOverflow.visible,
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
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(ResponsiveBorderRadius.lg(context)),
      ),
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
                SizedBox(height: ResponsiveSpacing.base(context)),
                Text(
                  '选择时间',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
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
                SizedBox(height: ResponsiveSpacing.base(context)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSpacing.xl(context),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                      ),
                      SizedBox(width: ResponsiveSpacing.base(context)),
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
                SizedBox(height: ResponsiveSpacing.base(context)),
              ],
            ),
          );
        },
      );
    },
  );

  return selectedTime;
}
