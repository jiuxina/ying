import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ============================================================================
/// 分段日期输入组件 - YYYY/MM/DD 格式
/// 自动跳转：输入完年份后跳转到月份，月份完成后跳转到日
/// ============================================================================

class SegmentedDateInput extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime>? onDateChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const SegmentedDateInput({
    super.key,
    required this.initialDate,
    this.onDateChanged,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<SegmentedDateInput> createState() => _SegmentedDateInputState();
}

class _SegmentedDateInputState extends State<SegmentedDateInput> {
  late TextEditingController _yearController;
  late TextEditingController _monthController;
  late TextEditingController _dayController;

  late FocusNode _yearFocus;
  late FocusNode _monthFocus;
  late FocusNode _dayFocus;

  @override
  void initState() {
    super.initState();
    _yearController = TextEditingController(
      text: widget.initialDate.year.toString(),
    );
    _monthController = TextEditingController(
      text: widget.initialDate.month.toString().padLeft(2, '0'),
    );
    _dayController = TextEditingController(
      text: widget.initialDate.day.toString().padLeft(2, '0'),
    );

    _yearFocus = FocusNode();
    _monthFocus = FocusNode();
    _dayFocus = FocusNode();
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    _yearFocus.dispose();
    _monthFocus.dispose();
    _dayFocus.dispose();
    super.dispose();
  }

  void _onYearChanged(String value) {
    // 自动跳转到月份
    if (value.length == 4) {
      _monthFocus.requestFocus();
      _monthController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _monthController.text.length,
      );
    }
    _notifyDateChanged();
  }

  void _onMonthChanged(String value) {
    // 验证月份范围
    if (value.isNotEmpty) {
      final month = int.tryParse(value) ?? 0;
      if (month > 12) {
        _monthController.text = '12';
      } else if (month < 1 && value.length == 2) {
        _monthController.text = '01';
      }
    }
    // 自动跳转到日
    if (value.length == 2) {
      _dayFocus.requestFocus();
      _dayController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _dayController.text.length,
      );
    }
    _notifyDateChanged();
  }

  void _onDayChanged(String value) {
    // 验证日期范围
    if (value.isNotEmpty) {
      final day = int.tryParse(value) ?? 0;
      final maxDay = _getMaxDayForMonth();
      if (day > maxDay) {
        _dayController.text = maxDay.toString().padLeft(2, '0');
      } else if (day < 1 && value.length == 2) {
        _dayController.text = '01';
      }
    }
    _notifyDateChanged();
  }

  int _getMaxDayForMonth() {
    final year = int.tryParse(_yearController.text) ?? DateTime.now().year;
    final month = int.tryParse(_monthController.text) ?? 1;
    return DateTime(year, month + 1, 0).day;
  }

  void _notifyDateChanged() {
    final year = int.tryParse(_yearController.text);
    final month = int.tryParse(_monthController.text);
    final day = int.tryParse(_dayController.text);

    if (year != null && month != null && day != null) {
      try {
        final date = DateTime(year, month, day);
        widget.onDateChanged?.call(date);
      } catch (_) {
        // 无效日期，忽略
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
    );
    final separatorStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w300,
      color: theme.colorScheme.outline,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 年份
        SizedBox(
          width: 80,
          child: TextField(
            controller: _yearController,
            focusNode: _yearFocus,
            textAlign: TextAlign.center,
            style: textStyle,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: const InputDecoration(
              hintText: 'YYYY',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: _onYearChanged,
          ),
        ),
        // 分隔符
        Text(' / ', style: separatorStyle),
        // 月份
        SizedBox(
          width: 50,
          child: TextField(
            controller: _monthController,
            focusNode: _monthFocus,
            textAlign: TextAlign.center,
            style: textStyle,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: const InputDecoration(
              hintText: 'MM',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: _onMonthChanged,
          ),
        ),
        // 分隔符
        Text(' / ', style: separatorStyle),
        // 日期
        SizedBox(
          width: 50,
          child: TextField(
            controller: _dayController,
            focusNode: _dayFocus,
            textAlign: TextAlign.center,
            style: textStyle,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: const InputDecoration(
              hintText: 'DD',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: _onDayChanged,
          ),
        ),
      ],
    );
  }
}

/// 显示日期选择对话框
Future<DateTime?> showSegmentedDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  DateTime? selectedDate;

  await showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (context) {
      DateTime tempDate = initialDate;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                '选择日期',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              SegmentedDateInput(
                initialDate: initialDate,
                firstDate: firstDate,
                lastDate: lastDate,
                onDateChanged: (date) {
                  tempDate = date;
                },
              ),
              const SizedBox(height: 24),
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
                          selectedDate = tempDate;
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
        ),
      );
    },
  );

  return selectedDate;
}
