import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../models/countdown_event.dart';
import '../models/undo_operation.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import '../utils/event_query.dart';
import '../utils/event_repeat_utils.dart';

typedef EventsLoader = Future<List<CountdownEvent>> Function();
typedef EventsSaver = Future<void> Function(List<CountdownEvent> events);
typedef SettingsLoader = Future<AppSettings> Function();
typedef SettingsSaver = Future<void> Function(AppSettings settings);
typedef NotificationScheduler = Future<void> Function(CountdownEvent event);
typedef NotificationCanceller = Future<void> Function(String eventId);
typedef WidgetSynchronizer =
    Future<void> Function(List<CountdownEvent> events, AppSettings settings);
typedef UndoTimerFactory =
    Timer Function(Duration duration, void Function() run);

class AppState {
  const AppState({
    this.events = const [],
    this.settings = const AppSettings(),
    this.pendingUndos = const [],
    this.isLoading = true,
  });

  final List<CountdownEvent> events;
  final AppSettings settings;
  final List<UndoOperation> pendingUndos;
  final bool isLoading;

  UndoOperation? get latestUndo =>
      pendingUndos.isEmpty ? null : pendingUndos.last;

  List<CountdownEvent> get sortedEvents =>
      queryEvents(events, sortMode: settings.eventSortMode);

  AppState copyWith({
    List<CountdownEvent>? events,
    AppSettings? settings,
    List<UndoOperation>? pendingUndos,
    bool? isLoading,
  }) {
    return AppState(
      events: events ?? this.events,
      settings: settings ?? this.settings,
      pendingUndos: pendingUndos ?? this.pendingUndos,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AppController extends StateNotifier<AppState> {
  AppController(
    this._storage, {
    EventsLoader? loadEvents,
    EventsSaver? saveEvents,
    SettingsLoader? loadSettings,
    SettingsSaver? saveSettings,
    NotificationScheduler? scheduleNotification,
    NotificationCanceller? cancelNotification,
    WidgetSynchronizer? syncWidget,
    UndoTimerFactory? timerFactory,
    Duration undoDuration = const Duration(seconds: 6),
    bool autoLoad = true,
  }) : _loadEvents = loadEvents ?? _storage.loadEvents,
       _saveEvents = saveEvents ?? _storage.saveEvents,
       _loadSettings = loadSettings ?? _storage.loadSettings,
       _saveSettings = saveSettings ?? _storage.saveSettings,
       _scheduleNotification =
           scheduleNotification ?? NotificationService.instance.schedule,
       _cancelNotification =
           cancelNotification ?? NotificationService.instance.cancel,
       _syncWidget = syncWidget ?? WidgetService.sync,
       _timerFactory =
           timerFactory ?? ((duration, run) => Timer(duration, run)),
       _undoDuration = undoDuration,
       super(const AppState()) {
    if (autoLoad) unawaited(load());
  }

  // ignore: unused_field
  final StorageService _storage;
  final EventsLoader _loadEvents;
  final EventsSaver _saveEvents;
  final SettingsLoader _loadSettings;
  final SettingsSaver _saveSettings;
  final NotificationScheduler _scheduleNotification;
  final NotificationCanceller _cancelNotification;
  final WidgetSynchronizer _syncWidget;
  final UndoTimerFactory _timerFactory;
  final Duration _undoDuration;
  final Map<String, Timer> _undoTimers = {};
  int _operationSequence = 0;
  int? _notificationActionRevision;

  Future<void> load() async {
    _cancelAllUndoTimers();
    final events = await _loadEvents();
    final settings = await _loadSettings();
    state = AppState(events: events, settings: settings, isLoading: false);
    _notificationActionRevision = await _storage
        .loadNotificationActionRevision();
    await _syncWidget(events, settings);
  }

  Future<void> reloadAfterNotificationAction() async {
    final revision = await _storage.loadNotificationActionRevision();
    if (_notificationActionRevision == revision) return;
    _notificationActionRevision = revision;
    await load();
  }

  Future<void> saveEvent(CountdownEvent event) async {
    final events = [...state.events];
    final index = events.indexWhere((value) => value.id == event.id);
    if (index < 0) {
      events.add(event);
    } else {
      events[index] = event;
    }
    await _commitVisibleEvents(events);
    await _scheduleNotification(event);
  }

  Future<void> deleteEvent(CountdownEvent event) => deleteEventWithUndo(event);

  Future<void> deleteEventWithUndo(CountdownEvent event) async {
    if (!state.events.any((value) => value.id == event.id)) return;
    final operation = _newOperation(
      type: UndoOperationType.delete,
      eventsBefore: [event],
      message: '已删除“${event.title}”',
    );
    final visible = state.events
        .where((value) => value.id != event.id)
        .toList();
    _appendUndo(operation, visible);
    await _persistSafeEvents();
    await _syncWidget(state.events, state.settings);
  }

  Future<void> toggleCompleted(CountdownEvent event) =>
      toggleCompletedWithUndo(event);

  Future<void> toggleCompletedWithUndo(CountdownEvent event) async {
    final index = state.events.indexWhere((value) => value.id == event.id);
    if (index < 0) return;
    final current = state.events[index];
    final updated = current.repeatsYearly && !current.isCompleted
        ? completeEvent(current)
        : current.copyWith(isCompleted: !current.isCompleted);
    final events = [...state.events]..[index] = updated;
    final operation = _newOperation(
      type: UndoOperationType.toggleCompleted,
      eventsBefore: [current],
      message: current.repeatsYearly && !current.isCompleted
          ? '“${updated.title}”已进入 ${updated.targetDate.year} 年'
          : updated.isCompleted
          ? '已完成“${updated.title}”'
          : '已恢复“${updated.title}”',
    );
    _appendUndo(operation, events);
    await _persistSafeEvents();
    await _syncWidget(events, state.settings);
    await _scheduleNotification(updated);
  }

  Future<void> togglePinned(CountdownEvent event) async {
    final index = state.events.indexWhere((value) => value.id == event.id);
    if (index < 0) return;
    final events = [...state.events];
    events[index] = events[index].copyWith(isPinned: !events[index].isPinned);
    await _commitVisibleEvents(events);
  }

  Future<void> clearCompletedWithUndo() async {
    final completed = state.events.where((event) => event.isCompleted).toList();
    if (completed.isEmpty) return;
    final operation = _newOperation(
      type: UndoOperationType.clearCompleted,
      eventsBefore: completed,
      message: '已清理 ${completed.length} 个完成事件',
    );
    final visible = state.events.where((event) => !event.isCompleted).toList();
    _appendUndo(operation, visible);
    await _persistSafeEvents();
    await _syncWidget(visible, state.settings);
  }

  Future<void> undoLatest() async {
    final operation = state.latestUndo;
    if (operation == null) return;
    _undoTimers.remove(operation.id)?.cancel();
    final remaining = state.pendingUndos
        .where((value) => value.id != operation.id)
        .toList();
    var events = [...state.events];
    for (final before in operation.eventsBefore) {
      final index = events.indexWhere((event) => event.id == before.id);
      if (index < 0) {
        events.add(before);
      } else {
        events[index] = before;
      }
    }
    state = state.copyWith(events: events, pendingUndos: remaining);
    await _persistSafeEvents();
    await _syncWidget(events, state.settings);
    for (final event in operation.eventsBefore) {
      await _scheduleNotification(event);
    }
  }

  Future<void> finalizeUndo(String operationId) async {
    UndoOperation? operation;
    for (final value in state.pendingUndos) {
      if (value.id == operationId) {
        operation = value;
        break;
      }
    }
    final finalized = operation;
    if (finalized == null) return;
    _undoTimers.remove(finalized.id)?.cancel();
    final remaining = state.pendingUndos
        .where((value) => value.id != finalized.id)
        .toList();
    state = state.copyWith(pendingUndos: remaining);
    await _persistSafeEvents();
    if (finalized.delaysDeletion) {
      for (final event in finalized.eventsBefore) {
        await _cancelNotification(event.id);
      }
      await _syncWidget(state.events, state.settings);
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    state = state.copyWith(settings: settings);
    await _saveSettings(settings);
    await _syncWidget(state.events, settings);
  }

  UndoOperation _newOperation({
    required UndoOperationType type,
    required List<CountdownEvent> eventsBefore,
    required String message,
  }) {
    final now = DateTime.now();
    return UndoOperation(
      id: '${now.microsecondsSinceEpoch}-${_operationSequence++}',
      type: type,
      eventsBefore: List.unmodifiable(eventsBefore),
      message: message,
      expiresAt: now.add(_undoDuration),
    );
  }

  void _appendUndo(UndoOperation operation, List<CountdownEvent> events) {
    state = state.copyWith(
      events: events,
      pendingUndos: [...state.pendingUndos, operation],
    );
    _undoTimers[operation.id] = _timerFactory(
      _undoDuration,
      () => unawaited(finalizeUndo(operation.id)),
    );
  }

  Future<void> _commitVisibleEvents(List<CountdownEvent> events) async {
    state = state.copyWith(events: events);
    await _persistSafeEvents();
    await _syncWidget(events, state.settings);
  }

  Future<void> _persistSafeEvents() => _saveEvents(_safeStoredEvents());

  List<CountdownEvent> _safeStoredEvents() {
    final result = [...state.events];
    for (final operation in state.pendingUndos.where(
      (value) => value.delaysDeletion,
    )) {
      for (final event in operation.eventsBefore) {
        if (!result.any((value) => value.id == event.id)) result.add(event);
      }
    }
    return result;
  }

  void _cancelAllUndoTimers() {
    for (final timer in _undoTimers.values) {
      timer.cancel();
    }
    _undoTimers.clear();
  }

  @override
  void dispose() {
    _cancelAllUndoTimers();
    super.dispose();
  }
}

final storageProvider = Provider((ref) => StorageService());

final appControllerProvider = StateNotifierProvider<AppController, AppState>(
  (ref) => AppController(ref.read(storageProvider)),
);

final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(appControllerProvider).settings.themeMode,
);
