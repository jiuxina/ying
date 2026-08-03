class EventReminder {
  const EventReminder({
    required this.id,
    required this.minutesBefore,
    this.enabled = true,
  });

  final String id;
  final int minutesBefore;
  final bool enabled;

  EventReminder copyWith({int? minutesBefore, bool? enabled}) {
    return EventReminder(
      id: id,
      minutesBefore: minutesBefore ?? this.minutesBefore,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'minutesBefore': minutesBefore,
    'enabled': enabled,
  };

  factory EventReminder.fromJson(Map<String, dynamic> json) {
    return EventReminder(
      id: json['id'] as String,
      minutesBefore: json['minutesBefore'] as int,
      enabled: (json['enabled'] as bool?) ?? true,
    );
  }

  static List<EventReminder> normalize(
    Iterable<EventReminder> values, {
    int maxCount = 5,
  }) {
    final byMinutes = <int, EventReminder>{};
    for (final value in values) {
      if (value.minutesBefore < 0) continue;
      byMinutes.putIfAbsent(value.minutesBefore, () => value);
    }
    final result = byMinutes.values.toList()
      ..sort((a, b) => b.minutesBefore.compareTo(a.minutesBefore));
    return List.unmodifiable(result.take(maxCount));
  }

  static String labelForMinutes(int minutes) {
    if (minutes == 0) return '事件发生时';
    if (minutes >= 1440 && minutes % 1440 == 0) {
      return '提前 ${minutes ~/ 1440} 天';
    }
    if (minutes >= 60 && minutes % 60 == 0) {
      return '提前 ${minutes ~/ 60} 小时';
    }
    return '提前 $minutes 分钟';
  }
}
