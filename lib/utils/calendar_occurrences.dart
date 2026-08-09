import '../models/countdown_event.dart';
import 'event_repeat_utils.dart';

/// 日历页中“事件 × 日期”的一次展示。
class CalendarOccurrence {
  const CalendarOccurrence({required this.event, required this.date});

  final CountdownEvent event;
  final DateTime date;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// 某个月网格里应展示的事件：每年重复事件在该月对应日期出现，
/// 普通事件只出现在目标日期所在月份。
List<CalendarOccurrence> calendarOccurrencesForMonth(
  List<CountdownEvent> events,
  DateTime month,
) {
  final result = <CalendarOccurrence>[];
  final year = month.year;
  final monthNumber = month.month;
  for (final event in events) {
    if (event.repeatsYearly) {
      final repeatMonth = event.repeatMonth ?? event.targetDate.month;
      final repeatDay = event.repeatDay ?? event.targetDate.day;
      if (repeatMonth == monthNumber &&
          isValidCalendarDate(year, repeatMonth, repeatDay)) {
        result.add(
          CalendarOccurrence(
            event: event,
            date: DateTime(year, repeatMonth, repeatDay),
          ),
        );
      }
    } else if (event.targetDate.year == year &&
        event.targetDate.month == monthNumber) {
      result.add(
        CalendarOccurrence(event: event, date: _dateOnly(event.targetDate)),
      );
    }
  }
  result.sort((a, b) => a.date.compareTo(b.date));
  return result;
}

/// 某一年 12 个月的“月份 → 事件”映射，供年视图使用。
Map<int, List<CalendarOccurrence>> calendarOccurrencesByMonth(
  List<CountdownEvent> events,
  int year,
) {
  final result = <int, List<CalendarOccurrence>>{
    for (var month = 1; month <= 12; month++) month: <CalendarOccurrence>[],
  };
  for (final event in events) {
    if (event.repeatsYearly) {
      final repeatMonth = event.repeatMonth ?? event.targetDate.month;
      final repeatDay = event.repeatDay ?? event.targetDate.day;
      if (isValidCalendarDate(year, repeatMonth, repeatDay)) {
        result[repeatMonth]!.add(
          CalendarOccurrence(
            event: event,
            date: DateTime(year, repeatMonth, repeatDay),
          ),
        );
      }
    } else if (event.targetDate.year == year) {
      final date = _dateOnly(event.targetDate);
      result[date.month]!.add(CalendarOccurrence(event: event, date: date));
    }
  }
  for (final occurrences in result.values) {
    occurrences.sort((a, b) => a.date.compareTo(b.date));
  }
  return result;
}

/// 日程列表视图使用：每个事件按当前目标日期出现一次。
List<CalendarOccurrence> calendarOccurrencesForAgenda(
  List<CountdownEvent> events,
) {
  final result = <CalendarOccurrence>[
    for (final event in events)
      CalendarOccurrence(event: event, date: _dateOnly(event.targetDate)),
  ];
  result.sort((a, b) => a.date.compareTo(b.date));
  return result;
}
