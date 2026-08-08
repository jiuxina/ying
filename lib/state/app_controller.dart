import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_version.dart';
import '../models/app_settings.dart';
import '../models/countdown_event.dart';
import '../models/undo_operation.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/update_service.dart';
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
typedef UpdateChecker =
    Future<UpdateCheckResult> Function(String currentVersion);
typedef BeforeWidgetSync =
    Future<void> Function(List<CountdownEvent> events);

class AppState {
  const AppState({
    this.events = const [],
    this.settings = const AppSettings(),
    this.pendingUndos = const [],
    this.isLoading = true,
    this.availableRelease,
  });

  final List<CountdownEvent> events;
  final AppSettings settings;
  final List<UndoOperation> pendingUndos;
  final bool isLoading;

  /// 自动/手动检测到的新版本发布，非空时首页显示更新横幅。
  final ReleaseInfo? availableRelease;

  UndoOperation? get latestUndo =>
      pendingUndos.isEmpty ? null : pendingUndos.last;

  List<CountdownEvent> get sortedEvents =>
      queryEvents(events, sortMode: settings.eventSortMode);

  AppState copyWith({
    List<CountdownEvent>? events,
    AppSettings? settings,
    List<UndoOperation>? pendingUndos,
    bool? isLoading,
    ReleaseInfo? availableRelease,
    bool clearAvailableRelease = false,
  }) {
    return AppState(
      events: events ?? this.events,
      settings: settings ?? this.settings,
      pendingUndos: pendingUndos ?? this.pendingUndos,
      isLoading: isLoading ?? this.isLoading,
      availableRelease: clearAvailableRelease
          ? null
          : availableRelease ?? this.availableRelease,
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
    UpdateChecker? checkUpdate,
    Duration undoDuration = const Duration(seconds: 6),
    Duration updateCheckInterval = const Duration(hours: 24),
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
       _checkUpdate = checkUpdate ?? _defaultCheckUpdate,
       _undoDuration = undoDuration,
       _updateCheckInterval = updateCheckInterval,
       super(const AppState()) {
    if (autoLoad) unawaited(load());
  }

  static Future<UpdateCheckResult> _defaultCheckUpdate(
    String currentVersion,
  ) {
    return UpdateService().checkForUpdate(currentVersion: currentVersion);
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
  final UpdateChecker _checkUpdate;
  final Duration _undoDuration;
  final Duration _updateCheckInterval;
  static const _batchUndoDuration = Duration(seconds: 10);
  final Map<String, Timer> _undoTimers = {};
  int _operationSequence = 0;
  int? _notificationActionRevision;

  Future<void> load({bool runAutoCheck = true}) async {
    _cancelAllUndoTimers();
    final events = await _loadEvents();
    final settings = await _loadSettings();
    state = AppState(
      events: events,
      settings: settings,
      isLoading: false,
      // 刷新数据时保留已发现的更新提示，避免横幅因重载消失。
      availableRelease: state.availableRelease,
    );
    _notificationActionRevision = await _storage
        .loadNotificationActionRevision();
    await _syncWidget(events, settings);
    if (runAutoCheck) {
      unawaited(autoCheckForUpdate());
    }
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

  /// 导入备份：按 ID 合并到现有列表，剪贴板数据优先。
  Future<void> importEvents(List<CountdownEvent> incoming) async {
    if (incoming.isEmpty) return;
    final byId = <String, CountdownEvent>{
      for (final value in state.events) value.id: value,
    };
    for (final event in incoming) {
      byId[event.id] = event;
    }
    final events = byId.values.toList();
    await _commitVisibleEvents(events);
    for (final event in incoming) {
      await _scheduleNotification(event);
    }
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

  Future<void> toggleCompletedWithUndo(
    CountdownEvent event, {
    BeforeWidgetSync? beforeWidgetSync,
  }) async {
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
    if (beforeWidgetSync != null) {
      await beforeWidgetSync(events);
    }
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
      duration: _batchUndoDuration,
    );
    final visible = state.events.where((event) => !event.isCompleted).toList();
    _appendUndo(operation, visible, duration: _batchUndoDuration);
    await _persistSafeEvents();
    await _syncWidget(visible, state.settings);
  }

  Future<void> clearAllEventsWithUndo() async {
    if (state.events.isEmpty) return;
    final operation = _newOperation(
      type: UndoOperationType.clearAll,
      eventsBefore: [...state.events],
      message: '已清除 ${state.events.length} 个事件',
      duration: _batchUndoDuration,
    );
    _appendUndo(operation, const [], duration: _batchUndoDuration);
    await _persistSafeEvents();
    await _syncWidget(const [], state.settings);
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
    state = state.copyWith(
      settings: settings,
      // 关闭自动检测时一并收起更新横幅。
      clearAvailableRelease: !settings.autoCheckUpdate &&
          state.availableRelease != null,
    );
    await _saveSettings(settings);
    await _syncWidget(state.events, settings);
  }

  /// 启动后的自动检测：受开关与 [_updateCheckInterval] 间隔限制，
  /// 结果只在新版本未被跳过时以横幅形式提示，失败保持静默。
  Future<void> autoCheckForUpdate() async {
    if (!state.settings.autoCheckUpdate) return;
    final now = DateTime.now();
    final lastCheckAt = await _storage.loadLastUpdateCheckAt();
    if (lastCheckAt != null &&
        now.difference(lastCheckAt) < _updateCheckInterval) {
      return;
    }
    // 先记录时间再请求，弱网下也保持每天最多一次。
    await _storage.saveLastUpdateCheckAt(now);
    final result = await _runUpdateCheck();
    if (!mounted) return;
    final release = result.release;
    if (!result.isNewer || release == null) return;
    final skipped = await _storage.loadSkippedReleaseVersion();
    if (!mounted) return;
    if (skipped == release.version) return;
    state = state.copyWith(availableRelease: release);
  }

  /// 设置页手动检测：不受开关与间隔限制，结果直接返回给界面。
  Future<UpdateCheckResult> checkForUpdateNow() async {
    final result = await _runUpdateCheck();
    if (!mounted) return result;
    await _storage.saveLastUpdateCheckAt(DateTime.now());
    final release = result.release;
    if (result.isNewer && release != null) {
      state = state.copyWith(availableRelease: release);
    }
    return result;
  }

  /// 收起更新横幅；[skipVersion] 为真时记住该版本，自动检测不再提示。
  Future<void> dismissUpdateRelease({bool skipVersion = false}) async {
    final release = state.availableRelease;
    state = state.copyWith(clearAvailableRelease: true);
    if (skipVersion && release != null) {
      await _storage.saveSkippedReleaseVersion(release.version);
    }
  }

  Future<UpdateCheckResult> _runUpdateCheck() async {
    try {
      return await _checkUpdate(appVersion);
    } catch (_) {
      return const UpdateCheckResult(errorMessage: '检查更新失败，请稍后再试');
    }
  }

  UndoOperation _newOperation({
    required UndoOperationType type,
    required List<CountdownEvent> eventsBefore,
    required String message,
    Duration? duration,
  }) {
    final now = DateTime.now();
    return UndoOperation(
      id: '${now.microsecondsSinceEpoch}-${_operationSequence++}',
      type: type,
      eventsBefore: List.unmodifiable(eventsBefore),
      message: message,
      expiresAt: now.add(duration ?? _undoDuration),
    );
  }

  void _appendUndo(
    UndoOperation operation,
    List<CountdownEvent> events, {
    Duration? duration,
  }) {
    state = state.copyWith(
      events: events,
      pendingUndos: [...state.pendingUndos, operation],
    );
    _undoTimers[operation.id] = _timerFactory(
      duration ?? _undoDuration,
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


