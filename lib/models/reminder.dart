import 'package:uuid/uuid.dart';

/// 提醒模型
/// 
/// 用于设置倒数日事件的提醒时间
class Reminder {
  final String id;
  final String eventId;
  final int daysBefore; // 0 = on the day, 1 = 1 day before, etc.
  final int hour; // 24h format
  final int minute;

  const Reminder({
    required this.id,
    required this.eventId,
    required this.daysBefore,
    required this.hour,
    required this.minute,
  });

  factory Reminder.create({
    required String eventId,
    required int daysBefore,
    required int hour,
    required int minute,
  }) {
    return Reminder(
      id: const Uuid().v4(),
      eventId: eventId,
      daysBefore: daysBefore,
      hour: hour,
      minute: minute,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'daysBefore': daysBefore,
      'hour': hour,
      'minute': minute,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as String,
      eventId: map['eventId'] as String,
      daysBefore: map['daysBefore'] as int,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
    );
  }

  Reminder copyWith({
    String? id,
    String? eventId,
    int? daysBefore,
    int? hour,
    int? minute,
  }) {
    return Reminder(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      daysBefore: daysBefore ?? this.daysBefore,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reminder &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
