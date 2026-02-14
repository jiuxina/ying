import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/countdown_event.dart';
import '../models/event_group.dart';

/// 数据库服务 - 管理事件的本地存储
/// 
/// 使用单例模式确保整个应用只有一个数据库连接实例
class DatabaseService {
  // 单例实例
  static final DatabaseService _instance = DatabaseService._internal();
  
  /// 工厂构造函数，始终返回同一实例
  factory DatabaseService() => _instance;
  
  /// 私有构造函数
  DatabaseService._internal();

  static Database? _database;
  static const String _tableName = 'countdown_events';
  static const String _categoriesTable = 'event_categories';
  static const String _groupsTable = 'event_groups';
  static const String _remindersTable = 'event_reminders';

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ying_countdown.db');

    return await openDatabase(
      path,
      version: 6, // Increment version for reminder schema migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        note TEXT,
        targetDate INTEGER NOT NULL,
        isLunar INTEGER NOT NULL DEFAULT 0,
        lunarDateStr TEXT,
        category TEXT NOT NULL,
        isCountUp INTEGER NOT NULL DEFAULT 0,
        isRepeating INTEGER NOT NULL DEFAULT 0,
        isPinned INTEGER NOT NULL DEFAULT 0,
        isArchived INTEGER NOT NULL DEFAULT 0,
        backgroundImage TEXT,
        enableBlur INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        enableNotification INTEGER NOT NULL DEFAULT 0,
        notifyDaysBefore INTEGER NOT NULL DEFAULT 1,
        notifyHour INTEGER NOT NULL DEFAULT 9,
        notifyMinute INTEGER NOT NULL DEFAULT 0,
        groupId TEXT
      )
    ''');

    // Create indexes for frequently queried columns
    await db.execute('CREATE INDEX idx_events_category ON $_tableName(category)');
    await db.execute('CREATE INDEX idx_events_archived ON $_tableName(isArchived)');
    await db.execute('CREATE INDEX idx_events_pinned ON $_tableName(isPinned)');
    await db.execute('CREATE INDEX idx_events_target_date ON $_tableName(targetDate)');
    await db.execute('CREATE INDEX idx_events_group_id ON $_tableName(groupId)');

    await db.execute('''
      CREATE TABLE $_groupsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    await _createCategoriesTable(db);
    await _seedDefaultCategories(db);
    await _createRemindersTable(db); // Create reminders table
  }

  /// 升级数据库
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE $_groupsTable (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          color TEXT,
          sortOrder INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL
        )
      ''');
      await db.execute('ALTER TABLE $_tableName ADD COLUMN groupId TEXT');
    }

    if (oldVersion < 3) {
      await _createCategoriesTable(db);
      await _seedDefaultCategories(db);
    }

    if (oldVersion < 4) {
      await _createRemindersTable(db);
      // Optional: Migrate existing single reminders to new table?
      // For simplicity, we might keep old fields for "legacy" or "primary" reminder
      // and use table for extras. Or migrate.
      // Let's migrate if possible, or just start fresh with multiple reminders support.
      // For now, let's just create the table.
    }

    // Add indexes for better query performance (version 5+)
    if (oldVersion < 5) {
      // Check if indexes don't exist before creating them
      await db.execute('CREATE INDEX IF NOT EXISTS idx_events_category ON $_tableName(category)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_events_archived ON $_tableName(isArchived)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_events_pinned ON $_tableName(isPinned)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_events_target_date ON $_tableName(targetDate)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_events_group_id ON $_tableName(groupId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_event_id ON $_remindersTable(eventId)');
    }
    
    // Migrate reminders table schema (version 6+)
    if (oldVersion < 6) {
      // Drop and recreate reminders table with new schema
      await db.execute('DROP TABLE IF EXISTS $_remindersTable');
      await _createRemindersTable(db);
    }
  }
  
  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_categoriesTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        isDefault INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createRemindersTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_remindersTable (
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        reminderDateTime INTEGER NOT NULL,
        customMessage TEXT,
        FOREIGN KEY (eventId) REFERENCES $_tableName (id) ON DELETE CASCADE
      )
    ''');
    // Create index for faster lookups by eventId
    await db.execute('CREATE INDEX idx_reminders_event_id ON $_remindersTable(eventId)');
  }

  Future<void> _seedDefaultCategories(Database db) async {
    // 默认分类 (对应 EventCategory 枚举)
    final defaults = [
      {'id': 'birthday', 'name': '生日', 'icon': '🎂', 'color': 0xFFFF4081, 'isDefault': 1},
      {'id': 'anniversary', 'name': '纪念日', 'icon': '💑', 'color': 0xFFE91E63, 'isDefault': 1},
      {'id': 'holiday', 'name': '节假日', 'icon': '🎉', 'color': 0xFF2196F3, 'isDefault': 1},
      {'id': 'exam', 'name': '考试', 'icon': '📚', 'color': 0xFFFF9800, 'isDefault': 1},
      {'id': 'work', 'name': '工作', 'icon': '💼', 'color': 0xFF607D8B, 'isDefault': 1},
      {'id': 'travel', 'name': '旅行', 'icon': '✈️', 'color': 0xFF4CAF50, 'isDefault': 1},
      {'id': 'custom', 'name': '其他', 'icon': '📌', 'color': 0xFF9C27B0, 'isDefault': 1},
    ];

    final batch = db.batch();
    for (var cat in defaults) {
      batch.insert(_categoriesTable, cat, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit();
  }

  /// 插入事件
  Future<void> insertEvent(CountdownEvent event) async {
    final db = await database;
    await db.insert(
      _tableName,
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 更新事件
  Future<void> updateEvent(CountdownEvent event) async {
    final db = await database;
    await db.update(
      _tableName,
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  /// 删除事件
  Future<void> deleteEvent(String id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取所有事件
  Future<List<CountdownEvent>> getAllEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return List.generate(maps.length, (i) => CountdownEvent.fromMap(maps[i]));
  }

  /// 获取未归档的事件
  Future<List<CountdownEvent>> getActiveEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'isArchived = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => CountdownEvent.fromMap(maps[i]));
  }

  /// 获取归档的事件
  Future<List<CountdownEvent>> getArchivedEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'isArchived = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => CountdownEvent.fromMap(maps[i]));
  }

  /// 根据分类获取事件
  Future<List<CountdownEvent>> getEventsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'category = ? AND isArchived = ?',
      whereArgs: [category, 0],
    );
    return List.generate(maps.length, (i) => CountdownEvent.fromMap(maps[i]));
  }

  /// 搜索事件
  Future<List<CountdownEvent>> searchEvents(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'title LIKE ? OR note LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => CountdownEvent.fromMap(maps[i]));
  }

  // Group CRUD

  /// 获取所有分组
  Future<List<EventGroup>> getAllGroups() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _groupsTable,
      orderBy: 'sortOrder ASC',
    );
    return List.generate(maps.length, (i) => EventGroup.fromMap(maps[i]));
  }

  /// 插入分组
  Future<void> insertGroup(EventGroup group) async {
    final db = await database;
    await db.insert(
      _groupsTable,
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 更新分组
  Future<void> updateGroup(EventGroup group) async {
    final db = await database;
    await db.update(
      _groupsTable,
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  /// 删除分组
  Future<void> deleteGroup(String id) async {
    final db = await database;
    await db.delete(
      _groupsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // 将该分组下的事件移出分组
    await db.update(
      _tableName,
      {'groupId': null},
      where: 'groupId = ?',
      whereArgs: [id],
    );
  }

  // Category CRUD
  
  /// 获取所有分类
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return await db.query(_categoriesTable);
  }

  /// 插入分类
  Future<void> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    await db.insert(
      _categoriesTable,
      category,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// 更新分类
  Future<void> updateCategory(Map<String, dynamic> category) async {
    final db = await database;
    await db.update(
      _categoriesTable,
      category,
      where: 'id = ?',
      whereArgs: [category['id']],
    );
  }

  /// 删除分类
  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete(
      _categoriesTable,
      where: 'id = ? AND isDefault = 0',
      whereArgs: [id],
    );
    
    // 将该分类下的事件重置为'custom'
    await db.update(
      _tableName,
      {'category': 'custom'},
      where: 'category = ?',
      whereArgs: [id],
    );
  }

  // Reminder CRUD
  
  /// 获取事件的所有提醒
  Future<List<Map<String, dynamic>>> getReminders(String eventId) async {
    final db = await database;
    return await db.query(
      _remindersTable,
      where: 'eventId = ?',
      whereArgs: [eventId],
      orderBy: 'daysBefore DESC, hour ASC',
    );
  }

  /// 插入提醒
  Future<void> insertReminder(Map<String, dynamic> reminder) async {
    final db = await database;
    await db.insert(
      _remindersTable,
      reminder,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 删除指定提醒
  Future<void> deleteReminder(String id) async {
    final db = await database;
    await db.delete(
      _remindersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除事件的所有提醒
  Future<void> deleteEventReminders(String eventId) async {
    final db = await database;
    await db.delete(
      _remindersTable,
      where: 'eventId = ?',
      whereArgs: [eventId],
    );
  }

  /// 批量获取所有提醒（按事件ID分组）
  /// 解决 N+1 查询问题
  Future<Map<String, List<Map<String, dynamic>>>> getAllRemindersGrouped() async {
    final db = await database;
    final results = await db.query(_remindersTable, orderBy: 'daysBefore DESC, hour ASC');
    
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in results) {
      final eventId = row['eventId'] as String;
      grouped.putIfAbsent(eventId, () => []).add(row);
    }
    return grouped;
  }

  // Backup & Restore

  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    
    final events = await db.query(_tableName);
    final categories = await db.query(_categoriesTable);
    final groups = await db.query(_groupsTable);
    final reminders = await db.query(_remindersTable);

    return {
      'version': 1,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'events': events,
      'categories': categories,
      'groups': groups,
      'reminders': reminders,
    };
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Clear all tables
      await txn.delete(_remindersTable);
      await txn.delete(_tableName);
      await txn.delete(_categoriesTable);
      await txn.delete(_groupsTable);

      // Restore Categories
      final categories = (data['categories'] as List).cast<Map<String, dynamic>>();
      for (var item in categories) {
        await txn.insert(_categoriesTable, item);
      }

      // Restore Groups
      if (data['groups'] != null) {
        final groups = (data['groups'] as List).cast<Map<String, dynamic>>();
        for (var item in groups) {
          await txn.insert(_groupsTable, item);
        }
      }

      // Restore Events
      final events = (data['events'] as List).cast<Map<String, dynamic>>();
      for (var item in events) {
        await txn.insert(_tableName, item);
      }

      // Restore Reminders
      if (data['reminders'] != null) {
        final reminders = (data['reminders'] as List).cast<Map<String, dynamic>>();
        for (var item in reminders) {
          await txn.insert(_remindersTable, item);
        }
      }
    });
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
