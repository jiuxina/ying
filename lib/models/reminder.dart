import 'package:uuid/uuid.dart';

/// 提醒模型
/// 
/// 用于设置倒数日事件的提醒时间
class Reminder {
  final String id;
  final String eventId;
  final DateTime reminderDateTime; // 完整的提醒日期时间
  final String? customMessage; // 自定义提醒内容

  const Reminder({
    required this.id,
    required this.eventId,
    required this.reminderDateTime,
    this.customMessage,
  });

  factory Reminder.create({
    required String eventId,
    required DateTime reminderDateTime,
    String? customMessage,
  }) {
    return Reminder(
      id: const Uuid().v4(),
      eventId: eventId,
      reminderDateTime: reminderDateTime,
      customMessage: customMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'reminderDateTime': reminderDateTime.millisecondsSinceEpoch,
      'customMessage': customMessage,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as String,
      eventId: map['eventId'] as String,
      reminderDateTime: DateTime.fromMillisecondsSinceEpoch(
        map['reminderDateTime'] as int,
      ),
      customMessage: map['customMessage'] as String?,
    );
  }

  Reminder copyWith({
    String? id,
    String? eventId,
    DateTime? reminderDateTime,
    String? customMessage,
  }) {
    return Reminder(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      customMessage: customMessage ?? this.customMessage,
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
