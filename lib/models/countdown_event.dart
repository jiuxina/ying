import 'dart:convert';

import 'event_reminder.dart';
import 'event_repeat.dart';

enum CountDirection { auto, countdown, countup }

class CountdownEvent {
  const CountdownEvent({
    required this.id,
    required this.title,
    required this.targetDate,
    required this.category,
    this.note = '',
    this.direction = CountDirection.auto,
    this.reminders = const [],
    this.isAllDay = false,
    this.isCompleted = false,
    this.isPinned = false,
    this.repeatType = EventRepeatType.none,
    this.repeatMonth,
    this.repeatDay,
    required this.createdAt,
  });

  final String id;
  final String title;
  final DateTime targetDate;
  final String category;
  final String note;
  final CountDirection direction;
  final List<EventReminder> reminders;
  final bool isAllDay;
  final bool isCompleted;
  final bool isPinned;
  final EventRepeatType repeatType;
  final int? repeatMonth;
  final int? repeatDay;
  final DateTime createdAt;

  DateTime get dateOnly =>
      DateTime(targetDate.year, targetDate.month, targetDate.day);

  DateTime get reminderAnchor => isAllDay
      ? DateTime(targetDate.year, targetDate.month, targetDate.day, 9)
      : targetDate;

  bool get repeatsYearly => repeatType == EventRepeatType.yearly;

  int dayDelta([DateTime? now]) {
    final today = now ?? DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return dateOnly.difference(start).inDays;
  }

  bool get isCountingUp =>
      direction == CountDirection.countup ||
      (direction == CountDirection.auto && dayDelta() < 0);

  int get displayDays => dayDelta().abs();

  String get statusLabel {
    if (isCompleted) return '已完成';
    final delta = dayDelta();
    if (delta == 0) return '就是今天';
    if (isCountingUp) return '已经';
    return '还有';
  }

  CountdownEvent copyWith({
    String? title,
    DateTime? targetDate,
    String? category,
    String? note,
    CountDirection? direction,
    List<EventReminder>? reminders,
    bool? isAllDay,
    bool? isCompleted,
    bool? isPinned,
    EventRepeatType? repeatType,
    int? repeatMonth,
    int? repeatDay,
    bool clearRepeatDate = false,
  }) {
    return CountdownEvent(
      id: id,
      title: title ?? this.title,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      note: note ?? this.note,
      direction: direction ?? this.direction,
      reminders: reminders ?? this.reminders,
      isAllDay: isAllDay ?? this.isAllDay,
      isCompleted: isCompleted ?? this.isCompleted,
      isPinned: isPinned ?? this.isPinned,
      repeatType: repeatType ?? this.repeatType,
      repeatMonth: clearRepeatDate ? null : repeatMonth ?? this.repeatMonth,
      repeatDay: clearRepeatDate ? null : repeatDay ?? this.repeatDay,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'targetDate': targetDate.toIso8601String(),
    'category': category,
    'note': note,
    'direction': direction.name,
    'reminders': reminders.map((reminder) => reminder.toJson()).toList(),
    'isAllDay': isAllDay,
    'isCompleted': isCompleted,
    'isPinned': isPinned,
    'repeatType': repeatType.name,
    if (repeatType == EventRepeatType.yearly) ...{
      'repeatMonth': repeatMonth ?? targetDate.month,
      'repeatDay': repeatDay ?? targetDate.day,
    },
    'createdAt': createdAt.toIso8601String(),
  };

  factory CountdownEvent.fromJson(Map<String, dynamic> json) {
    final rawReminders = json['reminders'] as List<dynamic>?;
    final reminders = rawReminders != null
        ? EventReminder.normalize(
            rawReminders.map(
              (value) => EventReminder.fromJson(value as Map<String, dynamic>),
            ),
          )
        : _legacyReminders(json['reminderMinutes'] as int?);
    final targetDate = DateTime.parse(json['targetDate'] as String);
    final repeatType = EventRepeatType.values.firstWhere(
      (value) => value.name == json['repeatType'],
      orElse: () => EventRepeatType.none,
    );
    return CountdownEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      targetDate: targetDate,
      category: (json['category'] as String?) ?? '生活',
      note: (json['note'] as String?) ?? '',
      direction: CountDirection.values.firstWhere(
        (value) => value.name == json['direction'],
        orElse: () => CountDirection.auto,
      ),
      reminders: reminders,
      isAllDay: (json['isAllDay'] as bool?) ?? false,
      isCompleted: (json['isCompleted'] as bool?) ?? false,
      isPinned: (json['isPinned'] as bool?) ?? false,
      repeatType: repeatType,
      repeatMonth: repeatType == EventRepeatType.yearly
          ? (json['repeatMonth'] as int?) ?? targetDate.month
          : null,
      repeatDay: repeatType == EventRepeatType.yearly
          ? (json['repeatDay'] as int?) ?? targetDate.day
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static List<EventReminder> _legacyReminders(int? minutes) {
    if (minutes == null || minutes < 0) return const [];
    return [EventReminder(id: 'legacy-$minutes', minutesBefore: minutes)];
  }

  static String encodeList(List<CountdownEvent> events) =>
      jsonEncode(events.map((event) => event.toJson()).toList());

  static List<CountdownEvent> decodeList(String source) {
    final values = jsonDecode(source) as List<dynamic>;
    return values
        .map((value) => CountdownEvent.fromJson(value as Map<String, dynamic>))
        .toList();
  }
}
