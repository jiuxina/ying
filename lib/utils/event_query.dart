import '../models/countdown_event.dart';
import '../models/event_sort_mode.dart';

List<CountdownEvent> queryEvents(
  Iterable<CountdownEvent> source, {
  String searchText = '',
  String? category,
  bool incompleteOnly = false,
  EventSortMode sortMode = EventSortMode.distance,
}) {
  final query = searchText.trim().toLowerCase();
  final result = source.where((event) {
    if (incompleteOnly && event.isCompleted) return false;
    if (category != null && event.category != category) return false;
    if (query.isEmpty) return true;
    return event.title.toLowerCase().contains(query) ||
        event.note.toLowerCase().contains(query);
  }).toList();
  result.sort((a, b) => compareEvents(a, b, sortMode));
  return result;
}

int compareEvents(CountdownEvent a, CountdownEvent b, EventSortMode sortMode) {
  if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
  if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
  final primary = switch (sortMode) {
    EventSortMode.distance => a.dayDelta().abs().compareTo(b.dayDelta().abs()),
    EventSortMode.targetDate => a.targetDate.compareTo(b.targetDate),
    EventSortMode.createdAt => b.createdAt.compareTo(a.createdAt),
  };
  if (primary != 0) return primary;
  final targetDate = a.targetDate.compareTo(b.targetDate);
  if (targetDate != 0) return targetDate;
  final createdAt = a.createdAt.compareTo(b.createdAt);
  if (createdAt != 0) return createdAt;
  return a.id.compareTo(b.id);
}
