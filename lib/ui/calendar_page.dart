import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/countdown_event.dart';
import '../state/app_controller.dart';
import '../utils/calendar_occurrences.dart';
import 'event_detail_page.dart';
import 'glass_ui.dart';

enum CalendarMode { month, year, list }

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  CalendarMode _mode = CalendarMode.month;
  int _modeNavigationDirection = 1;
  int _monthNavigationDirection = 1;
  late DateTime _focusedMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(appControllerProvider).events;
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final now = DateTime.now();
    final subtitleText = DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(now);
    final subtitleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
    final subtitleHeight = (TextPainter(
      text: TextSpan(text: subtitleText, style: subtitleStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout()).height;
    return ListView(
      padding: EdgeInsets.fromLTRB(wide ? 34 : 20, 28, 20, wide ? 24 : 132),
      children: [
        Text(
          '日历',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: subtitleHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: motionDuration(context, AppMotion.state),
                curve: AppMotion.crossFade,
                left: 0,
                top: 0,
                bottom: 0,
                right: _showTodayButton ? 72 : 0,
                child: Text(
                  subtitleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: subtitleStyle,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: AnimatedSwitcher(
                  duration: motionDuration(context, AppMotion.state),
                  switchInCurve: AppMotion.enter,
                  switchOutCurve: AppMotion.exit,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.85, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: AppMotion.enter,
                        ),
                      ),
                      child: child,
                    ),
                  ),
                  child: _showTodayButton
                      ? Padding(
                          key: const ValueKey('today-button'),
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          child: TextButton(
                            key: const ValueKey('calendar-today'),
                            onPressed: _jumpToToday,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 24),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('今天'),
                          ),
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('today-button-hidden'),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _ModeSelector(value: _mode, onChanged: _changeMode),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: motionDuration(context, AppMotion.switchDuration),
          switchInCurve: AppMotion.enter,
          switchOutCurve: AppMotion.exit,
          transitionBuilder: (child, animation) {
            final slide =
                Tween<Offset>(
                  begin: Offset(-0.03 * _modeNavigationDirection, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: AppMotion.crossFade,
                  ),
                );
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slide, child: child),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_mode),
            child: switch (_mode) {
              CalendarMode.month => _buildMonthView(context, events, now),
              CalendarMode.year => _buildYearView(context, events, now),
              CalendarMode.list => _buildListView(context, events, now),
            },
          ),
        ),
      ],
    );
  }

  bool get _showTodayButton {
    final now = DateTime.now();
    return switch (_mode) {
      CalendarMode.month =>
        _selectedDate != null && !_sameDay(_selectedDate!, now),
      CalendarMode.year => _focusedMonth.year != now.year,
      CalendarMode.list => false,
    };
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  void _changeMode(CalendarMode mode) {
    setState(() {
      _modeNavigationDirection = mode.index - _mode.index;
      _mode = mode;
      if (mode == CalendarMode.year) _selectedDate = null;
    });
    HapticFeedback.selectionClick();
  }

  DateTime _shiftMonth(int delta) {
    final total = _focusedMonth.year * 12 + (_focusedMonth.month - 1) + delta;
    return DateTime(total ~/ 12, total % 12 + 1);
  }

  void _goToMonth(int delta) {
    setState(() {
      _monthNavigationDirection = delta;
      _focusedMonth = _shiftMonth(delta);
    });
  }

  void _goToYear(int delta) {
    setState(() {
      _monthNavigationDirection = delta;
      _focusedMonth = DateTime(_focusedMonth.year + delta, _focusedMonth.month);
    });
  }

  Widget _buildMonthView(
    BuildContext context,
    List<CountdownEvent> events,
    DateTime now,
  ) {
    final occurrences = calendarOccurrencesForMonth(events, _focusedMonth);
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final leading = firstDay.weekday - 1;
    final cellCount = ((leading + daysInMonth + 6) ~/ 7) * 7;
    final grid = GlassSurface(
      key: const ValueKey('calendar-month-grid'),
      radius: 20,
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
      child: Column(
        children: [
          const _WeekdayHeader(),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - leading + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              final date = DateTime(
                _focusedMonth.year,
                _focusedMonth.month,
                dayNumber,
              );
              final dayEvents = occurrences
                  .where((occurrence) => _sameDay(occurrence.date, date))
                  .toList();
              return _DayCell(
                date: date,
                occurrences: dayEvents,
                selected:
                    _selectedDate != null && _sameDay(_selectedDate!, date),
                isToday: _sameDay(date, now),
                onTap: () => setState(() => _selectedDate = date),
              );
            },
          ),
        ],
      ),
    );
    final dayCard = _DayEventsCard(
      occurrences: occurrences,
      selectedDate: _selectedDate,
      onOpen: _openEvent,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GlassIconButton(
              icon: Icons.chevron_left_rounded,
              tooltip: '上个月',
              onPressed: () => _goToMonth(-1),
            ),
            Expanded(
              child: Center(
                child: Text(
                  DateFormat('yyyy年M月', 'zh_CN').format(_focusedMonth),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            GlassIconButton(
              icon: Icons.chevron_right_rounded,
              tooltip: '下个月',
              onPressed: () => _goToMonth(1),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (reduceMotionOf(context))
          grid
        else
          _calendarSwitcher(
            key: ValueKey(
              'calendar-month-grid-${_focusedMonth.year}-${_focusedMonth.month}',
            ),
            duration: AppMotion.switchDuration,
            begin: Offset(-0.03 * _monthNavigationDirection, 0),
            child: grid,
          ),
        const SizedBox(height: 16),
        if (reduceMotionOf(context))
          dayCard
        else
          _calendarSwitcher(
            key: ValueKey(_selectedDate),
            duration: AppMotion.state,
            begin: const Offset(0, 0.03),
            child: dayCard,
          ),
      ],
    );
  }

  Widget _calendarSwitcher({
    required Key key,
    required Duration duration,
    required Offset begin,
    required Widget child,
  }) {
    return AnimatedSwitcher(
      duration: motionDuration(context, duration),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(begin: begin, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: AppMotion.crossFade),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(key: key, child: child),
    );
  }

  Widget _buildYearView(
    BuildContext context,
    List<CountdownEvent> events,
    DateTime now,
  ) {
    final year = _focusedMonth.year;
    final byMonth = calendarOccurrencesByMonth(events, year);
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GlassIconButton(
              icon: Icons.chevron_left_rounded,
              tooltip: '上一年',
              onPressed: () => _goToYear(-1),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$year 年',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            GlassIconButton(
              icon: Icons.chevron_right_rounded,
              tooltip: '下一年',
              onPressed: () => _goToYear(1),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: motionDuration(context, AppMotion.switchDuration),
          switchInCurve: AppMotion.enter,
          switchOutCurve: AppMotion.exit,
          transitionBuilder: (child, animation) {
            final slide =
                Tween<Offset>(
                  begin: Offset(-0.03 * _monthNavigationDirection, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: AppMotion.crossFade,
                  ),
                );
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slide, child: child),
            );
          },
          child: GridView.builder(
            key: ValueKey('calendar-year-grid-$year'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: wide ? 3 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: wide ? 1.15 : 0.82,
            ),
            itemBuilder: (context, index) {
              final month = index + 1;
              return _MiniMonthCard(
                year: year,
                month: month,
                occurrences: byMonth[month]!,
                onTap: () => setState(() {
                  _focusedMonth = DateTime(year, month);
                  _mode = CalendarMode.month;
                  _selectedDate = null;
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListView(
    BuildContext context,
    List<CountdownEvent> events,
    DateTime now,
  ) {
    final occurrences = calendarOccurrencesForAgenda(events);
    if (occurrences.isEmpty) {
      return GlassSurface(
        radius: 20,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            '还没有安排的事件',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final groups = <String, List<CalendarOccurrence>>{};
    for (final occurrence in occurrences) {
      final key = DateFormat('yyyy年M月', 'zh_CN').format(occurrence.date);
      groups.putIfAbsent(key, () => []).add(occurrence);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              entry.key,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          GlassSurface(
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                for (var index = 0; index < entry.value.length; index++) ...[
                  if (index > 0)
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                  _EventRow(
                    occurrence: entry.value[index],
                    onTap: () => _openEvent(entry.value[index].event),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  void _openEvent(CountdownEvent event) {
    Navigator.push<void>(
      context,
      GlassPageRoute(builder: (context) => EventDetailPage(eventId: event.id)),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.value, required this.onChanged});

  final CalendarMode value;
  final ValueChanged<CalendarMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 18,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ModeButton(
            key: const ValueKey('calendar-mode-month'),
            label: '月',
            icon: Icons.calendar_view_month_rounded,
            selected: value == CalendarMode.month,
            onTap: () => onChanged(CalendarMode.month),
          ),
          _ModeButton(
            key: const ValueKey('calendar-mode-year'),
            label: '年',
            icon: Icons.grid_view_rounded,
            selected: value == CalendarMode.year,
            onTap: () => onChanged(CalendarMode.year),
          ),
          _ModeButton(
            key: const ValueKey('calendar-mode-list'),
            label: '列表',
            icon: Icons.view_agenda_outlined,
            selected: value == CalendarMode.list,
            onTap: () => onChanged(CalendarMode.list),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '日历模式：$label',
        child: Material(
          color: Colors.transparent,
          child: GlassPressable(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: motionDuration(
                  context,
                  const Duration(milliseconds: 180),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.surfaceContainerHighest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 17,
                        color: selected
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: selected
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  static const _labels = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    return Row(
      children: [
        for (final label in _labels)
          Expanded(
            child: Center(child: Text(label, style: style)),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.occurrences,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final List<CalendarOccurrence> occurrences;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${DateFormat('M月d日', 'zh_CN').format(date)}'
          '${occurrences.isEmpty ? '' : '，${occurrences.length} 个事件'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedScale(
            scale: selected ? 1.06 : 1,
            duration: motionDuration(context, AppMotion.state),
            curve: AppMotion.enter,
            child: AnimatedContainer(
              key: ValueKey(
                'calendar-day-${date.year}-${date.month}-${date.day}',
              ),
              duration: motionDuration(context, AppMotion.state),
              curve: AppMotion.crossFade,
              decoration: BoxDecoration(
                color: selected ? scheme.surfaceContainerHighest : null,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? scheme.outlineVariant : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: selected || isToday
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (occurrences.isEmpty && !isToday)
                    const SizedBox(height: 8)
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isToday && occurrences.isEmpty)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          for (final occurrence in occurrences.take(3))
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: occurrence.event.isCompleted
                                    ? scheme.outlineVariant
                                    : scheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        if (occurrences.length > 3)
                          Text(
                            '+${occurrences.length - 3}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 9,
                                ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayEventsCard extends StatelessWidget {
  const _DayEventsCard({
    required this.occurrences,
    required this.selectedDate,
    required this.onOpen,
  });

  final List<CalendarOccurrence> occurrences;
  final DateTime? selectedDate;
  final ValueChanged<CountdownEvent> onOpen;

  @override
  Widget build(BuildContext context) {
    final date = selectedDate;
    if (date == null) return const SizedBox.shrink();
    final dayEvents = occurrences
        .where((occurrence) => _sameDay(occurrence.date, date))
        .toList();
    return GlassSurface(
      key: const ValueKey('calendar-day-events'),
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('M月d日 EEEE', 'zh_CN').format(date),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (dayEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '这一天没有事件',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final occurrence in dayEvents)
              _EventRow(
                occurrence: occurrence,
                onTap: () => onOpen(occurrence.event),
              ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.occurrence, required this.onTap});

  final CalendarOccurrence occurrence;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final event = occurrence.event;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: event.title,
      hint: '点击查看详情',
      child: Opacity(
        key: ValueKey('calendar-event-${event.id}'),
        opacity: event.isCompleted ? 0.5 : 1,
        child: GlassPressable(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    if (event.icon.isNotEmpty) ...[
                      Text(event.icon, style: const TextStyle(fontSize: 17)),
                      const SizedBox(width: 9),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.isCompleted
                                ? '已完成'
                                : '${event.statusLabel} ${event.displayDays} 天',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant,
                      size: 20,
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
}

class _MiniMonthCard extends StatelessWidget {
  const _MiniMonthCard({
    required this.year,
    required this.month,
    required this.occurrences,
    required this.onTap,
  });

  final int year;
  final int month;
  final List<CalendarOccurrence> occurrences;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leading = firstDay.weekday - 1;
    final rows = (leading + daysInMonth + 6) ~/ 7;
    return Semantics(
      button: true,
      label:
          '$month 月${occurrences.isEmpty ? '' : '，${occurrences.length} 个事件'}',
      child: GlassSurface(
        radius: 16,
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        onTap: onTap,
        haptic: GlassHaptic.selectionClick,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$month 月',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var row = 0; row < rows; row++)
                    Row(
                      children: [
                        for (var column = 0; column < 7; column++)
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final day = row * 7 + column - leading + 1;
                                final visible = day >= 1 && day <= daysInMonth;
                                return _MiniDayCell(
                                  day: day,
                                  visible: visible,
                                  hasEvent:
                                      visible &&
                                      occurrences.any(
                                        (occurrence) =>
                                            occurrence.date.day == day,
                                      ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniDayCell extends StatelessWidget {
  const _MiniDayCell({
    required this.day,
    required this.visible,
    required this.hasEvent,
  });

  final int day;
  final bool visible;
  final bool hasEvent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          visible ? '$day' : '',
          style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
        ),
        if (hasEvent)
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}
