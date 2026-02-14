import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/countdown_event.dart';
import '../models/event_group.dart';
import '../models/category_model.dart';
import '../models/reminder.dart';
import '../services/database_service.dart';
import '../services/widget_service.dart';
import '../services/notification_service.dart';
import '../services/debug_logger.dart';

/// 事件状态管理 Provider
///
/// 核心业务逻辑层，负责：
/// 1. 管理所有倒数日事件的生命周期 (CRUD)。
/// 2. 处理事件的归档与置顶逻辑。
/// 3. 提供事件筛选（分类、搜索）与排序功能。
/// 4. 同步更新桌面小部件 (WidgetService)。
/// 5. 与数据库层 (DatabaseService) 交互进行持久化。
/// 6. 管理事件通知 (NotificationService)。
class EventsProvider extends ChangeNotifier {
  final DatabaseService _dbService;
  final NotificationService _notificationService;
  final DebugLogger _debugLogger = DebugLogger();
  final Uuid _uuid = const Uuid();

  EventsProvider({
    DatabaseService? dbService,
    NotificationService? notificationService,
  })  : _dbService = dbService ?? DatabaseService(),
        _notificationService = notificationService ?? NotificationService();

  List<CountdownEvent> _events = [];
  List<CountdownEvent> _archivedEvents = [];
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = false;

  // Getters
  List<CountdownEvent> get events => _filteredEvents;
  List<CountdownEvent> get archivedEvents => _archivedEvents;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  /// 获取过滤后的事件列表
  List<CountdownEvent> get _filteredEvents {
    var result = List<CountdownEvent>.from(_events);

    // 按分类过滤
    if (_selectedCategoryId != null) {
      result = result.where((e) => e.categoryId == _selectedCategoryId).toList();
    }

    // 按搜索词过滤
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((e) {
        return e.title.toLowerCase().contains(query) ||
            (e.note?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // 排序：置顶优先，然后按剩余天数排序
    result.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return a.daysRemaining.compareTo(b.daysRemaining);
    });

    return result;
  }

  List<EventGroup> _groups = [];
  
  List<EventGroup> get groups => _groups;

  List<Category> _categories = []; // Added
  List<Category> get categories => _categories; // Added

  /// 初始化 - 加载事件
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadEvents();
      await _loadGroups();
      await _loadCategories(); // Added
    } catch (e) {
      debugPrint('Error initializing provider: $e'); // Updated message
    } finally { // Added finally block
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadEvents() async {
    _events = await _dbService.getActiveEvents();
    
    // 批量加载 Reminders（解决 N+1 查询问题）
    final allReminders = await _dbService.getAllRemindersGrouped();
    for (var i = 0; i < _events.length; i++) {
      final eventReminders = allReminders[_events[i].id] ?? [];
      final reminders = eventReminders.map((m) => Reminder.fromMap(m)).toList();
      _events[i] = _events[i].copyWith(reminders: reminders);
    }

    _archivedEvents = await _dbService.getArchivedEvents();
    
    await _updateWidget();
  }

  Future<void> _loadGroups() async { // Added
    _groups = await _dbService.getAllGroups();
  }

  Future<void> _loadCategories() async { // Added
    final maps = await _dbService.getAllCategories();
    _categories = maps.map((m) => Category.fromJson(m)).toList();
  }

  // --- Category Operations --- // Added

  Future<void> addCategory(Category category) async { // Added
    await _dbService.insertCategory(category.toJson());
    await _loadCategories();
    notifyListeners();
  }

  Future<void> updateCategory(Category category) async { // Added
    await _dbService.updateCategory(category.toJson());
    await _loadCategories();
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async { // Added
    await _dbService.deleteCategory(id);
    await _loadCategories();
    // Refresh events as they might have been reset to 'custom'
    await _loadEvents(); 
    notifyListeners();
  }
  
  Category getCategoryById(String id) { // Added
    return _categories.firstWhere(
      (c) => c.id == id,
      orElse: () => _categories.firstWhere(
        (c) => c.id == 'custom',
        orElse: () => const Category(
          id: 'custom', 
          name: '其他', 
          icon: '📌', 
          color: 0xFF9C27B0,
          isDefault: true
        ),
      ),
    );
  }

  // --- Event Operations ---

  /// 刷新事件列表
  Future<void> refresh() async {
    await init();
  }

  /// 添加事件
  Future<void> addEvent({
    required String title,
    String? note,
    required DateTime targetDate,
    bool isLunar = false,
    String? lunarDateStr,
    String categoryId = 'custom',
    bool isCountUp = false,
    bool isRepeating = false,
    String? backgroundImage,
    bool enableBlur = false,
    bool enableNotification = false,
    int notifyDaysBefore = 1,
    int notifyHour = 9,
    int notifyMinute = 0,
    String? groupId,
    List<Reminder>? reminders, // Added parameter
  }) async {
    final now = DateTime.now();
    final eventId = _uuid.v4(); // Generate ID first
    
    final event = CountdownEvent(
      id: eventId,
      title: title,
      note: note,
      targetDate: targetDate,
      isLunar: isLunar,
      lunarDateStr: lunarDateStr,
      categoryId: categoryId,
      isCountUp: isCountUp,
      isRepeating: isRepeating,
      backgroundImage: backgroundImage,
      enableBlur: enableBlur,
      createdAt: now,
      updatedAt: now,
      enableNotification: enableNotification,
      notifyDaysBefore: notifyDaysBefore,
      notifyHour: notifyHour,
      notifyMinute: notifyMinute,
      groupId: groupId,
      reminders: reminders ?? [],
    );

    await _dbService.insertEvent(event);
    
    // Save reminders
    if (reminders != null) {
      for (var reminder in reminders) {
        // Ensure reminder has correct eventId
        await _dbService.insertReminder(reminder.copyWith(eventId: eventId).toMap());
      }
    }
    
    _events.add(event);
    
    // Schedule notifications
    await _notificationService.scheduleEventReminders(event);
    
    notifyListeners();
  }

  /// 直接添加事件对象
  Future<void> insertEvent(CountdownEvent event) async {
    _debugLogger.event('创建事件: ${event.title}', data: {
      'targetDate': event.targetDate.toIso8601String(),
      'hasReminders': event.reminders.isNotEmpty,
    });
    
    await _dbService.insertEvent(event);
    _events.add(event);
    
    // Schedule notifications
    await _notificationService.scheduleEventReminders(event);
    
    await _updateWidget();
    notifyListeners();
    
    _debugLogger.success('事件创建成功: ${event.title}');
  }

  /// 更新事件
  Future<void> updateEvent(CountdownEvent event) async {
    _debugLogger.event('更新事件: ${event.title}');
    
    final updatedEvent = event.copyWith(updatedAt: DateTime.now());
    await _dbService.updateEvent(updatedEvent);
    
    // Update reminders
    await _dbService.deleteEventReminders(event.id);
    for (var reminder in event.reminders) {
      await _dbService.insertReminder(reminder.toMap());
    }

    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = updatedEvent;
    }

    // Update notifications
    await _notificationService.scheduleEventReminders(updatedEvent);

    await _updateWidget();
    notifyListeners();
    
    _debugLogger.success('事件更新成功: ${event.title}');
  }

  /// 删除事件
  Future<void> deleteEvent(String id) async {
    final event = _events.firstWhere((e) => e.id == id);
    _debugLogger.event('删除事件: ${event.title}');
    
    await _dbService.deleteEvent(id);
    
    // Cancel notifications
    await _notificationService.cancelEventNotifications(id);
    
    _events.removeWhere((e) => e.id == id);
    _archivedEvents.removeWhere((e) => e.id == id);
    await _updateWidget();
    notifyListeners();
    
    _debugLogger.success('事件删除成功');
  }

  /// 切换置顶状态
  Future<void> togglePinned(String id) async {
    final index = _events.indexWhere((e) => e.id == id);
    if (index != -1) {
      final event = _events[index];
      await updateEvent(event.copyWith(isPinned: !event.isPinned));
    }
  }

  /// 切换置顶状态（别名）
  Future<void> togglePin(String id) => togglePinned(id);

  /// 归档事件
  Future<void> archiveEvent(String id) async {
    final index = _events.indexWhere((e) => e.id == id);
    if (index != -1) {
      final event = _events[index].copyWith(isArchived: true);
      await _dbService.updateEvent(event);
      _events.removeAt(index);
      _archivedEvents.add(event);
      notifyListeners();
    }
  }

  /// 取消归档
  Future<void> unarchiveEvent(String id) async {
    final index = _archivedEvents.indexWhere((e) => e.id == id);
    if (index != -1) {
      final event = _archivedEvents[index].copyWith(isArchived: false);
      await _dbService.updateEvent(event);
      _archivedEvents.removeAt(index);
      _events.add(event);
      notifyListeners();
    }
  }

  /// 切换归档状态
  Future<void> toggleArchive(String id) async {
    final index = _events.indexWhere((e) => e.id == id);
    if (index != -1) {
      await archiveEvent(id);
    } else {
      await unarchiveEvent(id);
    }
  }

  /// 设置分类筛选
  void setCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  /// 设置搜索词
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// 清除筛选
  void clearFilters() {
    _selectedCategoryId = null;
    _searchQuery = '';
    notifyListeners();
  }

  // Group Management

  /// 添加分组
  Future<void> addGroup(String name, {String? color}) async {
    final now = DateTime.now();
    final group = EventGroup(
      id: _uuid.v4(),
      name: name,
      color: color,
      createdAt: now,
      updatedAt: now,
      sortOrder: _groups.length,
    );
    
    await _dbService.insertGroup(group);
    _groups.add(group);
    notifyListeners();
  }

  /// 更新分组
  Future<void> updateGroup(EventGroup group) async {
    final updatedGroup = group.copyWith(updatedAt: DateTime.now());
    await _dbService.updateGroup(updatedGroup);
    
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = updatedGroup;
    }
    notifyListeners();
  }

  /// 删除分组
  Future<void> deleteGroup(String id) async {
    await _dbService.deleteGroup(id);
    _groups.removeWhere((g) => g.id == id);
    
    // 更新本地内存中事件的groupId
    for (var event in _events) {
      if (event.groupId == id) {
        final index = _events.indexOf(event);
        _events[index] = event.copyWith(groupId: null); 
        // copyWith with null is tricky in Dart if not explicit nullable logic or using a specific null value.
        // My copyWith implementation: groupId: groupId ?? this.groupId.
        // So passing null will keep existing value!
        // I need to fix copyWith in CountdownEvent or logic here.
        // Wait, I can't easily pass null to keep existing value via copyWith usually unless I use a sentinel.
        // But here I want to CLEAR the groupId.
        // Let's check CountdownEvent copyWith.
      }
    }
    // Re-fetching events is safer and easier.
    _events = await _dbService.getActiveEvents();
    
    notifyListeners();
  }

  // Fix copyWith logic note:
  // In standard copyWith `field: val ?? this.field`, passing null means "don't change".
  // To clear a field, we usually need `field: null` but that won't work with `??`.
  // Or we use a specific approach.
  // Instead of solving copyWith problem, I just reload events as above.

  /// 更新小部件数据
  Future<void> _updateWidget() async {
    try {
      await WidgetService.updateWithTopEvent(_events);
    } catch (e) {
      debugPrint('更新小部件失败: $e');
    }
  }
}
