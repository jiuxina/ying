enum EventDateShortcut { today, tomorrow, nextWeek, nextMonth, yearEnd }

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime applyEventDateShortcut(EventDateShortcut shortcut, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  return switch (shortcut) {
    EventDateShortcut.today => today,
    EventDateShortcut.tomorrow => today.add(const Duration(days: 1)),
    EventDateShortcut.nextWeek => today.add(const Duration(days: 7)),
    EventDateShortcut.nextMonth => addCalendarMonth(today),
    EventDateShortcut.yearEnd => DateTime(today.year, 12, 31),
  };
}

DateTime addCalendarMonth(DateTime value) {
  final nextYear = value.month == 12 ? value.year + 1 : value.year;
  final nextMonth = value.month == 12 ? 1 : value.month + 1;
  final lastDay = DateTime(nextYear, nextMonth + 1, 0).day;
  return DateTime(
    nextYear,
    nextMonth,
    value.day > lastDay ? lastDay : value.day,
  );
}
