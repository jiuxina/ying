import 'countdown_event.dart';

enum UndoOperationType { delete, toggleCompleted, clearCompleted }

class UndoOperation {
  const UndoOperation({
    required this.id,
    required this.type,
    required this.eventsBefore,
    required this.message,
    required this.expiresAt,
  });

  final String id;
  final UndoOperationType type;
  final List<CountdownEvent> eventsBefore;
  final String message;
  final DateTime expiresAt;

  bool get delaysDeletion =>
      type == UndoOperationType.delete ||
      type == UndoOperationType.clearCompleted;
}
