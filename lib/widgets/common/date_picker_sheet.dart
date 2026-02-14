import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/responsive_utils.dart';

/// ============================================================================
/// 统一日期选择器 - 年/月/日 三个滚轮并排显示
/// ============================================================================

class DatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onDateChanged;

  const DatePickerSheet({
    super.key,
    required this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onDateChanged,
  });

  @override
  State<DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<DatePickerSheet> {
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;

  late int _year;
  late int _month;
  late int _day;

  late int _minYear;
  late int _maxYear;

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
    _day = widget.initialDate.day;

    _minYear = widget.firstDate?.year ?? 1900;
    _maxYear = widget.lastDate?.year ?? 2200;

    _yearController = FixedExtentScrollController(initialItem: _year - _minYear);
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    // Validate and adjust day if needed
    final maxDay = _getMaxDayForMonth();
    if (_day > maxDay) {
      _day = maxDay;
      _dayController.jumpToItem(_day - 1);
    }

    widget.onDateChanged?.call(DateTime(_year, _month, _day));
  }

  int _getMaxDayForMonth() {
    return DateTime(_year, _month + 1, 0).day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 当前日期显示
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveSpacing.base(context),
          ),
          child: Text(
            '${_year.toString()}年${_month.toString().padLeft(2, '0')}月${_day.toString().padLeft(2, '0')}日',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: ResponsiveUtils.scaledSize(context, 1),
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
              // 年份
              Flexible(
                flex: 2,
                child: _buildWheelColumn(
                  context: context,
                  label: '年',
                  controller: _yearController,
                  itemCount: _maxYear - _minYear + 1,
                  selectedValue: _year - _minYear,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _year = _minYear + value);
                    _notifyChange();
                  },
                  valueBuilder: (index) => (_minYear + index).toString(),
                ),
              ),
              // 分隔符
              _buildSeparator(context),
              // 月份
              Flexible(
                child: _buildWheelColumn(
                  context: context,
                  label: '月',
                  controller: _monthController,
                  itemCount: 12,
                  selectedValue: _month - 1,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _month = value + 1);
                    _notifyChange();
                  },
                  valueBuilder: (index) => (index + 1).toString().padLeft(2, '0'),
                ),
              ),
              // 分隔符
              _buildSeparator(context),
              // 日期
              Flexible(
                child: _buildWheelColumn(
                  context: context,
                  label: '日',
                  controller: _dayController,
                  itemCount: _getMaxDayForMonth(),
                  selectedValue: _day - 1,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _day = value + 1);
                    _notifyChange();
                  },
                  valueBuilder: (index) => (index + 1).toString().padLeft(2, '0'),
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
    required String Function(int) valueBuilder,
  }) {
    final theme = Theme.of(context);
    final wheelWidth = ResponsiveUtils.scaledSize(context, 80);
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
                    child: Text(valueBuilder(index)),
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
        horizontal: ResponsiveSpacing.xs(context),
      ),
      child: Text(
        '/',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w300,
              color: Theme.of(context).colorScheme.outline,
            ),
        overflow: TextOverflow.visible,
      ),
    );
  }
}

/// 显示日期选择器
Future<DateTime?> showDatePickerSheet({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  DateTime? selectedDate;

  await showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(ResponsiveBorderRadius.lg(context)),
      ),
    ),
    builder: (context) {
      DateTime tempDate = initialDate;
      
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: ResponsiveSpacing.base(context)),
                Text(
                  '选择日期',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                DatePickerSheet(
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  onDateChanged: (date) {
                    tempDate = date;
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
                            selectedDate = tempDate;
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

  return selectedDate;
}
