import 'package:flutter/material.dart';
import '../models/countdown_event.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'events_provider.dart';

/// 批量操作结果
class BatchOperationResult {
  final bool success;
  final int successCount;
  final int failureCount;
  final String? errorMessage;
  final List<String> affectedIds;

  const BatchOperationResult({
    required this.success,
    this.successCount = 0,
    this.failureCount = 0,
    this.errorMessage,
    this.affectedIds = const [],
  });

  bool get partialSuccess => successCount > 0 && failureCount > 0;
}

/// 批量操作状态管理 Provider
///
/// 负责：
/// 1. 管理选择模式状态
/// 2. 跟踪选中的事件 ID
/// 3. 执行批量操作（删除、归档、分类变更、导出）
/// 4. 支持撤销操作
class BatchOperationsProvider extends ChangeNotifier {
  final EventsProvider _eventsProvider;
  final DatabaseService _dbService;
  final NotificationService _notificationService;

  BatchOperationsProvider({
    required EventsProvider eventsProvider,
    DatabaseService? dbService,
    NotificationService? notificationService,
  })  : _eventsProvider = eventsProvider,
        _dbService = dbService ?? DatabaseService(),
        _notificationService = notificationService ?? NotificationService();

  // 选择状态
  bool _isSelectionMode = false;
  final Set<String> _selectedEventIds = {};

  // 撤销支持
  List<CountdownEvent>? _lastDeletedEvents;
  List<CountdownEvent>? _lastArchivedEvents;
  List<CountdownEvent>? _lastUnarchivedEvents;
  Map<String, String>? _lastCategoryChanges; // eventId -> oldCategoryId

  // Getters
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedEventIds => Set.unmodifiable(_selectedEventIds);
  int get selectedCount => _selectedEventIds.length;
  bool get hasSelection => _selectedEventIds.isNotEmpty;
  bool get allSelected => _eventsProvider.events.isNotEmpty &&
      _selectedEventIds.length == _eventsProvider.events.length;

  /// 进入选择模式
  void enterSelectionMode() {
    if (_isSelectionMode) return;
    _isSelectionMode = true;
    notifyListeners();
  }

  /// 退出选择模式
  void exitSelectionMode() {
    if (!_isSelectionMode) return;
    _isSelectionMode = false;
    _selectedEventIds.clear();
    notifyListeners();
  }

  /// 切换选择模式
  void toggleSelectionMode() {
    if (_isSelectionMode) {
      exitSelectionMode();
    } else {
      enterSelectionMode();
    }
  }

  /// 切换事件选择状态
  void toggleEventSelection(String eventId) {
    if (!_isSelectionMode) {
      enterSelectionMode();
    }
    
    if (_selectedEventIds.contains(eventId)) {
      _selectedEventIds.remove(eventId);
    } else {
      _selectedEventIds.add(eventId);
    }
    notifyListeners();
  }

  /// 选择事件
  void selectEvent(String eventId) {
    if (!_isSelectionMode) {
      enterSelectionMode();
    }
    _selectedEventIds.add(eventId);
    notifyListeners();
  }

  /// 取消选择事件
  void deselectEvent(String eventId) {
    _selectedEventIds.remove(eventId);
    notifyListeners();
  }

  /// 全选当前显示的事件
  void selectAll() {
    if (!_isSelectionMode) {
      enterSelectionMode();
    }
    _selectedEventIds.clear();
    _selectedEventIds.addAll(_eventsProvider.events.map((e) => e.id));
    notifyListeners();
  }

  /// 取消全选
  void deselectAll() {
    _selectedEventIds.clear();
    notifyListeners();
  }

  /// 反选
  void invertSelection() {
    if (!_isSelectionMode) {
      enterSelectionMode();
    }
    
    final allEventIds = _eventsProvider.events.map((e) => e.id).toSet();
    final newSelection = allEventIds.difference(_selectedEventIds);
    _selectedEventIds.clear();
    _selectedEventIds.addAll(newSelection);
    notifyListeners();
  }

  /// 检查事件是否被选中
  bool isEventSelected(String eventId) => _selectedEventIds.contains(eventId);

  /// 批量删除事件
  Future<BatchOperationResult> batchDelete() async {
    if (_selectedEventIds.isEmpty) {
      return const BatchOperationResult(success: false, errorMessage: '没有选中任何事件');
    }

    // 备份用于撤销
    _lastDeletedEvents = _eventsProvider.events
        .where((e) => _selectedEventIds.contains(e.id))
        .toList();

    int successCount = 0;
    int failureCount = 0;
    final affectedIds = <String>[];

    for (final eventId in _selectedEventIds.toList()) {
      try {
        await _eventsProvider.deleteEvent(eventId);
        successCount++;
        affectedIds.add(eventId);
      } catch (e) {
        failureCount++;
        debugPrint('批量删除失败: $eventId - $e');
      }
    }

    // 退出选择模式
    exitSelectionMode();

    return BatchOperationResult(
      success: failureCount == 0,
      successCount: successCount,
      failureCount: failureCount,
      affectedIds: affectedIds,
    );
  }

  /// 撤销批量删除
  Future<bool> undoBatchDelete() async {
    if (_lastDeletedEvents == null || _lastDeletedEvents!.isEmpty) {
      return false;
    }

    try {
      for (final event in _lastDeletedEvents!) {
        await _eventsProvider.insertEvent(event);
      }
      _lastDeletedEvents = null;
      return true;
    } catch (e) {
      debugPrint('撤销批量删除失败: $e');
      return false;
    }
  }

  /// 批量归档
  Future<BatchOperationResult> batchArchive() async {
    if (_selectedEventIds.isEmpty) {
      return const BatchOperationResult(success: false, errorMessage: '没有选中任何事件');
    }

    // 备份用于撤销
    _lastArchivedEvents = _eventsProvider.events
        .where((e) => _selectedEventIds.contains(e.id) && !e.isArchived)
        .toList();

    int successCount = 0;
    int failureCount = 0;
    final affectedIds = <String>[];

    for (final eventId in _selectedEventIds.toList()) {
      try {
        await _eventsProvider.archiveEvent(eventId);
        successCount++;
        affectedIds.add(eventId);
      } catch (e) {
        failureCount++;
        debugPrint('批量归档失败: $eventId - $e');
      }
    }

    exitSelectionMode();

    return BatchOperationResult(
      success: failureCount == 0,
      successCount: successCount,
      failureCount: failureCount,
      affectedIds: affectedIds,
    );
  }

  /// 批量取消归档
  Future<BatchOperationResult> batchUnarchive() async {
    if (_selectedEventIds.isEmpty) {
      return const BatchOperationResult(success: false, errorMessage: '没有选中任何事件');
    }

    // 备份用于撤销
    _lastUnarchivedEvents = _eventsProvider.archivedEvents
        .where((e) => _selectedEventIds.contains(e.id))
        .toList();

    int successCount = 0;
    int failureCount = 0;
    final affectedIds = <String>[];

    for (final eventId in _selectedEventIds.toList()) {
      try {
        await _eventsProvider.unarchiveEvent(eventId);
        successCount++;
        affectedIds.add(eventId);
      } catch (e) {
        failureCount++;
        debugPrint('批量取消归档失败: $eventId - $e');
      }
    }

    exitSelectionMode();

    return BatchOperationResult(
      success: failureCount == 0,
      successCount: successCount,
      failureCount: failureCount,
      affectedIds: affectedIds,
    );
  }

  /// 批量更改分类
  Future<BatchOperationResult> batchChangeCategory(String newCategoryId) async {
    if (_selectedEventIds.isEmpty) {
      return const BatchOperationResult(success: false, errorMessage: '没有选中任何事件');
    }

    // 备份用于撤销
    _lastCategoryChanges = {};
    for (final event in _eventsProvider.events) {
      if (_selectedEventIds.contains(event.id)) {
        _lastCategoryChanges![event.id] = event.categoryId;
      }
    }

    int successCount = 0;
    int failureCount = 0;
    final affectedIds = <String>[];

    for (final event in _eventsProvider.events.toList()) {
      if (!_selectedEventIds.contains(event.id)) continue;
      
      try {
        final updatedEvent = event.copyWith(
          categoryId: newCategoryId,
          updatedAt: DateTime.now(),
        );
        await _eventsProvider.updateEvent(updatedEvent);
        successCount++;
        affectedIds.add(event.id);
      } catch (e) {
        failureCount++;
        debugPrint('批量更改分类失败: ${event.id} - $e');
      }
    }

    exitSelectionMode();

    return BatchOperationResult(
      success: failureCount == 0,
      successCount: successCount,
      failureCount: failureCount,
      affectedIds: affectedIds,
    );
  }

  /// 撤销批量更改分类
  Future<bool> undoBatchChangeCategory() async {
    if (_lastCategoryChanges == null || _lastCategoryChanges!.isEmpty) {
      return false;
    }

    try {
      for (final entry in _lastCategoryChanges!.entries) {
        final event = _eventsProvider.events
            .cast<CountdownEvent?>()
            .firstWhere((e) => e?.id == entry.key, orElse: () => null);
        
        if (event != null) {
          final updatedEvent = event.copyWith(
            categoryId: entry.value,
            updatedAt: DateTime.now(),
          );
          await _eventsProvider.updateEvent(updatedEvent);
        }
      }
      _lastCategoryChanges = null;
      return true;
    } catch (e) {
      debugPrint('撤销批量更改分类失败: $e');
      return false;
    }
  }

  /// 批量切换置顶状态
  Future<BatchOperationResult> batchTogglePin({required bool pin}) async {
    if (_selectedEventIds.isEmpty) {
      return const BatchOperationResult(success: false, errorMessage: '没有选中任何事件');
    }

    int successCount = 0;
    int failureCount = 0;
    final affectedIds = <String>[];

    for (final event in _eventsProvider.events.toList()) {
      if (!_selectedEventIds.contains(event.id)) continue;
      
      // 只处理需要改变的事件
      if (event.isPinned == pin) {
        continue;
      }

      try {
        final updatedEvent = event.copyWith(
          isPinned: pin,
          updatedAt: DateTime.now(),
        );
        await _eventsProvider.updateEvent(updatedEvent);
        successCount++;
        affectedIds.add(event.id);
      } catch (e) {
        failureCount++;
        debugPrint('批量切换置顶失败: ${event.id} - $e');
      }
    }

    exitSelectionMode();

    return BatchOperationResult(
      success: failureCount == 0,
      successCount: successCount,
      failureCount: failureCount,
      affectedIds: affectedIds,
    );
  }

  /// 导出选中的事件
  List<Map<String, dynamic>> exportSelected() {
    return _eventsProvider.events
        .where((e) => _selectedEventIds.contains(e.id))
        .map((e) => e.toMap())
        .toList();
  }

  /// 获取选中的事件列表
  List<CountdownEvent> getSelectedEvents() {
    return _eventsProvider.events
        .where((e) => _selectedEventIds.contains(e.id))
        .toList();
  }
}
