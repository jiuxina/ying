import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 月度进度条
///
/// 显示当月已过天数进度，事件分布标记，简洁优雅的设计。
/// 支持点击某天查看事件详情。
///
/// 示例:
/// ```dart
/// MonthProgressBar(
///   year: 2026,
///   month: 4,
///   eventDates: {DateTime(2026, 4, 15), DateTime(2026, 4, 30)},
///   onDayTap: (date) => print(date),
/// )
/// ```
class MonthProgressBar extends StatefulWidget {
  /// 年份
  final int year;

  /// 月份 (1-12)
  final int month;

  /// 事件日期集合
  final Set<DateTime> eventDates;

  /// 点击某天的回调
  final void Function(DateTime date)? onDayTap;

  /// 高度
  final double height;

  /// 是否显示标签
  final bool showLabels;

  /// 是否显示事件标记
  final bool showEventMarkers;

  /// 已过日期的颜色
  final Color? passedColor;

  /// 未来日期的颜色
  final Color? futureColor;

  /// 事件标记颜色
  final Color? eventMarkerColor;

  /// 动画时长
  final Duration animationDuration;

  /// 进度条圆角
  final double borderRadius;

  /// 是否启用点击交互
  final bool enableTap;

  const MonthProgressBar({
    super.key,
    required this.year,
    required this.month,
    this.eventDates = const {},
    this.onDayTap,
    this.height = 80,
    this.showLabels = true,
    this.showEventMarkers = true,
    this.passedColor,
    this.futureColor,
    this.eventMarkerColor,
    this.animationDuration = const Duration(milliseconds: 400),
    this.borderRadius = 12,
    this.enableTap = true,
  }) : assert(month >= 1 && month <= 12, 'month must be between 1 and 12');

  @override
  State<MonthProgressBar> createState() => _MonthProgressBarState();
}

class _MonthProgressBarState extends State<MonthProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _setupAnimation();
  }

  void _setupAnimation() {
    final progress = _calculateProgress();
    _progressAnimation = Tween<double>(
      begin: 0,
      end: progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(MonthProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year ||
        oldWidget.month != widget.month ||
        oldWidget.eventDates != widget.eventDates) {
      _setupAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 计算当月进度
  double _calculateProgress() {
    final now = DateTime.now();
    final daysInMonth = DateTime(widget.year, widget.month + 1, 0).day;

    if (widget.year < now.year ||
        (widget.year == now.year && widget.month < now.month)) {
      // 已过去的月份
      return 1.0;
    } else if (widget.year > now.year ||
        (widget.year == now.year && widget.month > now.month)) {
      // 未来的月份
      return 0.0;
    } else {
      // 当前月份
      final currentDay = now.day;
      return (currentDay / daysInMonth).clamp(0.0, 1.0);
    }
  }

  /// 获取当月天数
  int _getDaysInMonth() {
    return DateTime(widget.year, widget.month + 1, 0).day;
  }

  /// 获取月份名称
  String _getMonthName() {
    final date = DateTime(widget.year, widget.month);
    return DateFormat('M月').format(date);
  }

  /// 判断日期是否有事件（预留功能）
  // ignore: unused_element
  bool _hasEvent(DateTime date) {
    return widget.eventDates.any((eventDate) =>
        eventDate.year == date.year &&
        eventDate.month == date.month &&
        eventDate.day == date.day);
  }

  /// 处理日期点击
  void _handleDayTap(DateTime date) {
    if (!widget.enableTap) return;
    setState(() {
      _selectedDate = date;
    });
    widget.onDayTap?.call(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 颜色定义
    final passedColor = widget.passedColor ?? theme.colorScheme.primary;
    final futureColor = widget.futureColor ??
        (isDark ? Colors.grey.shade800 : Colors.grey.shade200);
    final eventMarkerColor = widget.eventMarkerColor ?? theme.colorScheme.secondary;
    final selectedColor = theme.colorScheme.primary.withOpacity(0.3);

    final daysInMonth = _getDaysInMonth();
    final progress = _progressAnimation.value;
    final passedDays = (progress * daysInMonth).round();

    return Semantics(
      label: '${widget.year}年${_getMonthName()}进度',
      value: '$passedDays/$daysInMonth 天已过',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标签行
          if (widget.showLabels) _buildLabels(theme, passedDays, daysInMonth),
          const SizedBox(height: 8),

          // 进度条主体
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapUp: widget.enableTap
                        ? (details) {
                            final dayIndex = (details.localPosition.dx /
                                    constraints.maxWidth *
                                    daysInMonth)
                                .floor()
                                .clamp(1, daysInMonth);
                            final date = DateTime(
                              widget.year,
                              widget.month,
                              dayIndex,
                            );
                            _handleDayTap(date);
                          }
                        : null,
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, widget.height),
                      painter: _MonthProgressPainter(
                        progress: _progressAnimation.value,
                        daysInMonth: daysInMonth,
                        eventDates: widget.eventDates,
                        year: widget.year,
                        month: widget.month,
                        passedColor: passedColor,
                        futureColor: futureColor,
                        eventMarkerColor: eventMarkerColor,
                        selectedDate: _selectedDate,
                        selectedColor: selectedColor,
                        borderRadius: widget.borderRadius,
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // 日期标签
          if (widget.showLabels)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1日',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${daysInMonth}日',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabels(ThemeData theme, int passedDays, int daysInMonth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _getMonthName(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$passedDays / $daysInMonth 天',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// 月度进度条绘制器
class _MonthProgressPainter extends CustomPainter {
  final double progress;
  final int daysInMonth;
  final Set<DateTime> eventDates;
  final int year;
  final int month;
  final Color passedColor;
  final Color futureColor;
  final Color eventMarkerColor;
  final DateTime? selectedDate;
  final Color selectedColor;
  final double borderRadius;

  // 缓存 paints 对象以优化性能
  Paint? _passedPaint;
  Paint? _futurePaint;
  Paint? _eventPaint;

  _MonthProgressPainter({
    required this.progress,
    required this.daysInMonth,
    required this.eventDates,
    required this.year,
    required this.month,
    required this.passedColor,
    required this.futureColor,
    required this.eventMarkerColor,
    this.selectedDate,
    required this.selectedColor,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dayWidth = size.width / daysInMonth;
    final barHeight = size.height * 0.7;
    final markerHeight = size.height * 0.2;
    final barTop = (size.height - barHeight) / 2;
    final markerTop = barTop + barHeight + 4;

    // 绘制背景（未来日期）
    _drawFutureDays(canvas, size, dayWidth, barHeight, barTop);

    // 绘制进度（已过日期）
    _drawPassedDays(canvas, size, dayWidth, barHeight, barTop);

    // 绘制事件标记
    _drawEventMarkers(canvas, size, dayWidth, markerHeight, markerTop);

    // 绘制选中状态
    if (selectedDate != null) {
      _drawSelectedDay(canvas, size, dayWidth, barHeight, barTop);
    }
  }

  void _drawFutureDays(
      Canvas canvas, Size size, double dayWidth, double barHeight, double barTop) {
    _futurePaint ??= Paint()..color = futureColor;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, barTop, size.width, barHeight),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(rrect, _futurePaint!);
  }

  void _drawPassedDays(
      Canvas canvas, Size size, double dayWidth, double barHeight, double barTop) {
    if (progress <= 0) return;

    _passedPaint ??= Paint()..color = passedColor;

    final progressWidth = size.width * progress;
    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, barTop, progressWidth, barHeight),
      topLeft: Radius.circular(borderRadius),
      bottomLeft: Radius.circular(borderRadius),
      topRight: progress >= 1 ? Radius.circular(borderRadius) : Radius.zero,
      bottomRight: progress >= 1 ? Radius.circular(borderRadius) : Radius.zero,
    );
    canvas.drawRRect(rrect, _passedPaint!);
  }

  void _drawEventMarkers(
      Canvas canvas, Size size, double dayWidth, double markerHeight, double markerTop) {
    _eventPaint ??= Paint()..color = eventMarkerColor;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      if (_hasEventOnDate(date)) {
        final x = (day - 0.5) * dayWidth - markerHeight / 2;
        canvas.drawCircle(
          Offset(x + markerHeight / 2, markerTop + markerHeight / 2),
          markerHeight / 2,
          _eventPaint!,
        );
      }
    }
  }

  void _drawSelectedDay(
      Canvas canvas, Size size, double dayWidth, double barHeight, double barTop) {
    final selectedPaint = Paint()..color = selectedColor;
    final day = selectedDate!.day;
    final x = (day - 1) * dayWidth;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, barTop, dayWidth, barHeight),
        Radius.circular(4),
      ),
      selectedPaint,
    );
  }

  bool _hasEventOnDate(DateTime date) {
    return eventDates.any((eventDate) =>
        eventDate.year == date.year &&
        eventDate.month == date.month &&
        eventDate.day == date.day);
  }

  @override
  bool shouldRepaint(_MonthProgressPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        daysInMonth != oldDelegate.daysInMonth ||
        eventDates != oldDelegate.eventDates ||
        selectedDate != oldDelegate.selectedDate ||
        passedColor != oldDelegate.passedColor ||
        futureColor != oldDelegate.futureColor ||
        eventMarkerColor != oldDelegate.eventMarkerColor;
  }
}

/// 月度进度条包装器 - 带月份切换
class MonthProgressBarWithNavigation extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final Set<DateTime> eventDates;
  final void Function(DateTime date)? onDayTap;
  final double height;
  final bool showLabels;

  const MonthProgressBarWithNavigation({
    super.key,
    required this.initialYear,
    required this.initialMonth,
    this.eventDates = const {},
    this.onDayTap,
    this.height = 80,
    this.showLabels = true,
  });

  @override
  State<MonthProgressBarWithNavigation> createState() =>
      _MonthProgressBarWithNavigationState();
}

class _MonthProgressBarWithNavigationState
    extends State<MonthProgressBarWithNavigation> {
  late int _currentYear;
  late int _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentYear = widget.initialYear;
    _currentMonth = widget.initialMonth;
  }

  void _previousMonth() {
    setState(() {
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear--;
      } else {
        _currentMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear++;
      } else {
        _currentMonth++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 月份选择器
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left),
                tooltip: '上个月',
              ),
              Text(
                '$_currentYear年 $_currentMonth月',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
                tooltip: '下个月',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 月度进度条
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MonthProgressBar(
            year: _currentYear,
            month: _currentMonth,
            eventDates: widget.eventDates,
            onDayTap: widget.onDayTap,
            height: widget.height,
            showLabels: widget.showLabels,
          ),
        ),
      ],
    );
  }
}
