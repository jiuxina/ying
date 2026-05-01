import 'package:flutter/material.dart';

/// 年度进度网格
///
/// 显示365天点阵图，已过天数高亮，事件日期标记。
/// 点击某天可查看事件，支持手势交互。
///
/// 布局: 7列 x 53行 (每周7天，每年53周)
///
/// 示例:
/// ```dart
/// YearProgressGrid(
///   year: 2026,
///   eventDates: {DateTime(2026, 1, 1), DateTime(2026, 5, 1)},
///   onDayTap: (date) => print(date),
/// )
/// ```
class YearProgressGrid extends StatefulWidget {
  /// 要显示的年份
  final int year;

  /// 事件日期集合
  final Set<DateTime> eventDates;

  /// 点击某天的回调
  final void Function(DateTime date)? onDayTap;

  /// 长按某天的回调
  final void Function(DateTime date)? onDayLongPress;

  /// 网格单元大小
  final double cellSize;

  /// 单元间距
  final double cellSpacing;

  /// 是否显示月份标签
  final bool showMonthLabels;

  /// 是否显示星期标签
  final bool showWeekdayLabels;

  /// 已过日期的颜色
  final Color? passedDayColor;

  /// 未来日期的颜色
  final Color? futureDayColor;

  /// 事件日期的颜色
  final Color? eventDayColor;

  /// 动画时长
  final Duration animationDuration;

  /// 自定义颜色映射函数 (根据事件数量返回颜色强度)
  final Color Function(int eventCount)? eventColorIntensity;

  const YearProgressGrid({
    super.key,
    required this.year,
    this.eventDates = const {},
    this.onDayTap,
    this.onDayLongPress,
    this.cellSize = 12,
    this.cellSpacing = 3,
    this.showMonthLabels = true,
    this.showWeekdayLabels = true,
    this.passedDayColor,
    this.futureDayColor,
    this.eventDayColor,
    this.animationDuration = const Duration(milliseconds: 500),
    this.eventColorIntensity,
  });

  @override
  State<YearProgressGrid> createState() => _YearProgressGridState();
}

class _YearProgressGridState extends State<YearProgressGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final DateTime _now = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 获取年份的天数
  int _getDaysInYear(int year) {
    return DateTime(year + 1, 1, 1).difference(DateTime(year, 1, 1)).inDays;
  }

  /// 获取年份的第一天是星期几 (1 = 周一, 7 = 周日)
  int _getFirstDayOfWeek(int year) {
    return DateTime(year, 1, 1).weekday;
  }

  /// 判断日期是否是今天
  bool _isToday(DateTime date) {
    return date.year == _now.year &&
        date.month == _now.month &&
        date.day == _now.day;
  }

  /// 判断日期是否已过
  bool _isPassed(DateTime date) {
    final today = DateTime(_now.year, _now.month, _now.day);
    final compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isBefore(today);
  }

  /// 判断日期是否有事件
  bool _hasEvent(DateTime date) {
    return widget.eventDates.any((eventDate) =>
        eventDate.year == date.year &&
        eventDate.month == date.month &&
        eventDate.day == date.day);
  }

  /// 获取日期的事件数量
  int _getEventCount(DateTime date) {
    return widget.eventDates
        .where((eventDate) =>
            eventDate.year == date.year &&
            eventDate.month == date.month &&
            eventDate.day == date.day)
        .length;
  }

  /// 处理日期点击
  void _handleDayTap(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    widget.onDayTap?.call(date);
  }

  /// 处理日期长按
  void _handleDayLongPress(DateTime date) {
    widget.onDayLongPress?.call(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 默认颜色
    final passedColor = widget.passedDayColor ??
        (isDark ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.7));
    final futureColor = widget.futureDayColor ??
        (isDark ? Colors.grey.shade800 : Colors.grey.shade200);
    final eventColor = widget.eventDayColor ?? theme.colorScheme.secondary;
    final selectedColor = theme.colorScheme.primary.withOpacity(0.3);

    final daysInYear = _getDaysInYear(widget.year);
    final firstDayOfWeek = _getFirstDayOfWeek(widget.year);
    final totalWeeks = ((firstDayOfWeek - 1 + daysInYear) / 7).ceil();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Semantics(
            label: '${widget.year}年进度网格',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 月份标签行
                if (widget.showMonthLabels)
                  Padding(
                    padding: EdgeInsets.only(
                      left: widget.showWeekdayLabels
                          ? widget.cellSize + widget.cellSpacing
                          : 0,
                    ),
                    child: _buildMonthLabels(totalWeeks),
                  ),

                // 网格主体
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 星期标签列
                    if (widget.showWeekdayLabels)
                      _buildWeekdayLabels(),

                    // 网格
                    _buildGrid(
                      daysInYear,
                      firstDayOfWeek,
                      totalWeeks,
                      passedColor,
                      futureColor,
                      eventColor,
                      selectedColor,
                      isDark,
                    ),
                  ],
                ),

                // 图例
                const SizedBox(height: 12),
                _buildLegend(theme, passedColor, futureColor, eventColor),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthLabels(int totalWeeks) {
    const months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
    final cellWidth = widget.cellSize + widget.cellSpacing;
    final monthLabels = <Widget>[];

    for (int month = 1; month <= 12; month++) {
      final firstDayOfMonth = DateTime(widget.year, month, 1);
      final weekIndex = ((firstDayOfMonth.weekday - 1 +
              firstDayOfMonth.day - 1) /
          7)
          .floor();

      if (month == 1) {
        monthLabels.add(
          SizedBox(
            width: cellWidth * (weekIndex + 1),
            child: Text(
              months[month - 1],
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        );
      } else if (weekIndex > ((month - 1 == 2
              ? DateTime(widget.year, month - 1, 1)
              : DateTime(widget.year, month - 1, 1))
          .day /
          7)) {
        monthLabels.add(
          SizedBox(
            width: cellWidth,
            child: Text(
              months[month - 1],
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        );
      } else {
        monthLabels.add(
          SizedBox(
            width: cellWidth,
          ),
        );
      }
    }

    return Row(children: monthLabels.take(totalWeeks).toList());
  }

  Widget _buildWeekdayLabels() {
    const weekdays = ['', '一', '二', '三', '四', '五', ''];
    return Column(
      children: List.generate(7, (index) {
        // 只显示周一、周三、周五、周日
        if (index == 0 || index == 2 || index == 4 || index == 6) {
          return SizedBox(
            height: widget.cellSize + widget.cellSpacing,
            child: Text(
              weekdays[index],
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          );
        }
        return SizedBox(height: widget.cellSize + widget.cellSpacing);
      }),
    );
  }

  Widget _buildGrid(
    int daysInYear,
    int firstDayOfWeek,
    int totalWeeks,
    Color passedColor,
    Color futureColor,
    Color eventColor,
    Color selectedColor,
    bool isDark,
  ) {
    return Row(
      children: List.generate(totalWeeks, (weekIndex) {
        return Column(
          children: List.generate(7, (dayIndex) {
            // 计算这一周这一天的索引
            final dayNumber = weekIndex * 7 + dayIndex - (firstDayOfWeek - 1);

            // 如果超出范围，返回空单元格
            if (dayNumber < 0 || dayNumber >= daysInYear) {
              return SizedBox(
                width: widget.cellSize,
                height: widget.cellSize,
              );
            }

            final date = DateTime(widget.year, 1, 1 + dayNumber);
            final isPassed = _isPassed(date);
            final hasEvent = _hasEvent(date);
            final isSelected = _selectedDate == date;
            final isToday = _isToday(date);
            final eventCount = _getEventCount(date);

            // 计算动画进度（从左到右、从上到下）
            final totalDays = weekIndex * 7 + dayIndex;
            final animationProgress = (_animation.value * totalWeeks * 7) > totalDays
                ? 1.0
                : 0.0;

            return Padding(
              padding: EdgeInsets.all(widget.cellSpacing / 2),
              child: GestureDetector(
                onTap: () => _handleDayTap(date),
                onLongPress: () => _handleDayLongPress(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: widget.cellSize,
                  height: widget.cellSize,
                  decoration: BoxDecoration(
                    color: _getDayColor(
                      isPassed,
                      hasEvent,
                      isSelected,
                      passedColor,
                      futureColor,
                      eventColor,
                      selectedColor,
                      eventCount,
                    ),
                    borderRadius: BorderRadius.circular(2),
                    border: isToday
                        ? Border.all(
                            color: isDark ? Colors.white : Colors.black,
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: animationProgress > 0
                      ? null
                      : const SizedBox.shrink(),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Color _getDayColor(
    bool isPassed,
    bool hasEvent,
    bool isSelected,
    Color passedColor,
    Color futureColor,
    Color eventColor,
    Color selectedColor,
    int eventCount,
  ) {
    if (isSelected) return selectedColor;
    if (hasEvent) {
      if (widget.eventColorIntensity != null) {
        return widget.eventColorIntensity!(eventCount);
      }
      return eventColor;
    }
    if (isPassed) return passedColor;
    return futureColor;
  }

  Widget _buildLegend(
    ThemeData theme,
    Color passedColor,
    Color futureColor,
    Color eventColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '已过',
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        _buildLegendDot(passedColor),
        const SizedBox(width: 12),
        Text(
          '有事件',
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        _buildLegendDot(eventColor),
        const SizedBox(width: 12),
        Text(
          '未来',
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        _buildLegendDot(futureColor),
      ],
    );
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// 带统计信息的年度进度网格
class YearProgressGridWithStats extends StatelessWidget {
  final int year;
  final Set<DateTime> eventDates;
  final void Function(DateTime date)? onDayTap;
  final void Function(DateTime date)? onDayLongPress;
  final double cellSize;
  final bool showMonthLabels;
  final bool showWeekdayLabels;

  const YearProgressGridWithStats({
    super.key,
    required this.year,
    this.eventDates = const {},
    this.onDayTap,
    this.onDayLongPress,
    this.cellSize = 12,
    this.showMonthLabels = true,
    this.showWeekdayLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final startOfYear = DateTime(year, 1, 1);
    // ignore: unused_local_variable
    final endOfYear = DateTime(year, 12, 31);
    final today = DateTime(now.year, now.month, now.day);

    // 计算统计数据
    final passedDays = year < now.year
        ? DateTime(year + 1, 1, 1).difference(startOfYear).inDays
        : today.difference(startOfYear).inDays + 1;
    final totalDays = year < now.year
        ? DateTime(year + 1, 1, 1).difference(startOfYear).inDays
        : (now.year == year
            ? today.difference(DateTime(year, 1, 1)).inDays + 1
            : DateTime(year + 1, 1, 1).difference(startOfYear).inDays);
    final daysWithEvents = eventDates
        .where((d) => d.year == year)
        .map((d) => '${d.month}-${d.day}')
        .toSet()
        .length;
    final progress = totalDays > 0 ? passedDays / 365 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 统计信息
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                '已过天数',
                '$passedDays',
                '天',
              ),
              _buildStatItem(
                context,
                '总天数',
                '$totalDays',
                '天',
              ),
              _buildStatItem(
                context,
                '有事件',
                '$daysWithEvents',
                '天',
              ),
              _buildStatItem(
                context,
                '年度进度',
                '${(progress * 100).toInt()}',
                '%',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 年度进度网格
        YearProgressGrid(
          year: year,
          eventDates: eventDates,
          onDayTap: onDayTap,
          onDayLongPress: onDayLongPress,
          cellSize: cellSize,
          showMonthLabels: showMonthLabels,
          showWeekdayLabels: showWeekdayLabels,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    String unit,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextSpan(
                text: unit,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
