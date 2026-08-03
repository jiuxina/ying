import '../models/countdown_event.dart';
import '../models/event_repeat.dart';

bool isLeapYear(int year) =>
    year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);

bool isValidCalendarDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1) return false;
  final value = DateTime(year, month, day);
  return value.year == year && value.month == month && value.day == day;
}

DateTime nextYearlyOccurrence(CountdownEvent event, {DateTime? after}) {
  if (event.repeatType != EventRepeatType.yearly) return event.targetDate;
  final boundary = after ?? event.targetDate;
  final month = event.repeatMonth ?? event.targetDate.month;
  final day = event.repeatDay ?? event.targetDate.day;
  var year = boundary.year;
  while (true) {
    if (isValidCalendarDate(year, month, day)) {
      final candidate = event.isAllDay
          ? DateTime(year, month, day)
          : DateTime(
              year,
              month,
              day,
              event.targetDate.hour,
              event.targetDate.minute,
              event.targetDate.second,
              event.targetDate.millisecond,
              event.targetDate.microsecond,
            );
      if (candidate.isAfter(boundary)) return candidate;
    }
    year += 1;
  }
}

CountdownEvent completeEvent(CountdownEvent event, {DateTime? now}) {
  if (event.repeatType != EventRepeatType.yearly) {
    return event.copyWith(isCompleted: true);
  }
  final boundary = event.targetDate.isAfter(now ?? DateTime.now())
      ? event.targetDate
      : (now ?? DateTime.now());
  return event.copyWith(
    targetDate: nextYearlyOccurrence(event, after: boundary),
    isCompleted: false,
  );
}
