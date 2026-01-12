import 'package:sqflite/sqflite.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/models/event_group.dart';
import 'package:ying/services/database_service.dart';
import 'package:ying/services/webdav_service.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart'; // For TestDefaultBinaryMessengerBinding

// Manual Mock for DatabaseService
class MockDatabaseService implements DatabaseService {
  final List<CountdownEvent> _mockEvents = [];
  final List<CountdownEvent> _mockArchived = [];
  final List<EventGroup> _mockGroups = [];
  final List<Map<String, dynamic>> _mockCategories = [];
  final List<Map<String, dynamic>> _mockReminders = [];

  // Helper to clear state
  void reset() {
    _mockEvents.clear();
    _mockArchived.clear();
    _mockGroups.clear();
    _mockCategories.clear();
    _mockReminders.clear();
  }

  @override
  Future<Database> get database => throw UnimplementedError();

  @override
  Future<List<CountdownEvent>> getActiveEvents() async => [..._mockEvents];

  @override
  Future<List<CountdownEvent>> getArchivedEvents() async => [..._mockArchived];

  @override
  Future<void> insertEvent(CountdownEvent event) async {
    _mockEvents.add(event);
  }

  @override
  Future<void> updateEvent(CountdownEvent event) async {
    final index = _mockEvents.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _mockEvents[index] = event;
    } else {
      final archIndex = _mockArchived.indexWhere((e) => e.id == event.id);
      if (archIndex != -1) _mockArchived[archIndex] = event;
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    _mockEvents.removeWhere((e) => e.id == id);
    _mockArchived.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<CountdownEvent>> getAllEvents() async => [..._mockEvents, ..._mockArchived];

  @override
  Future<List<CountdownEvent>> getEventsByCategory(String categoryId) async {
    return _mockEvents.where((e) => e.categoryId == categoryId).toList();
  }

  @override
  Future<List<CountdownEvent>> searchEvents(String query) async {
     return _mockEvents.where((e) => e.title.contains(query)).toList();
  }

  @override
  Future<List<EventGroup>> getAllGroups() async => [..._mockGroups];

  @override
  Future<void> insertGroup(EventGroup group) async {
    _mockGroups.add(group);
  }

  @override
  Future<void> updateGroup(EventGroup group) async {
    final index = _mockGroups.indexWhere((g) => g.id == group.id);
    if (index != -1) _mockGroups[index] = group;
  }

  @override
  Future<void> deleteGroup(String id) async {
    _mockGroups.removeWhere((g) => g.id == id);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllCategories() async => [..._mockCategories];

  @override
  Future<void> insertCategory(Map<String, dynamic> category) async {
    _mockCategories.add(category);
  }

  @override
  Future<void> updateCategory(Map<String, dynamic> category) async {
    final index = _mockCategories.indexWhere((c) => c['id'] == category['id']);
    if (index != -1) _mockCategories[index] = category;
  }

  @override
  Future<void> deleteCategory(String id) async {
    _mockCategories.removeWhere((c) => c['id'] == id);
  }

  @override
  Future<List<Map<String, dynamic>>> getReminders(String eventId) async {
    return _mockReminders.where((r) => r['eventId'] == eventId).toList();
  }

  @override
  Future<void> insertReminder(Map<String, dynamic> reminder) async {
    _mockReminders.add(reminder);
  }

  @override
  Future<void> deleteReminder(String id) async {
    _mockReminders.removeWhere((r) => r['id'] == id);
  }

  @override
  Future<void> deleteEventReminders(String eventId) async {
    _mockReminders.removeWhere((r) => r['eventId'] == eventId);
  }

  @override
  Future<Map<String, List<Map<String, dynamic>>>> getAllRemindersGrouped() async {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final reminder in _mockReminders) {
      final eventId = reminder['eventId'] as String;
      grouped.putIfAbsent(eventId, () => []).add(reminder);
    }
    return grouped;
  }

  @override
  Future<Map<String, dynamic>> exportAllData() async {
    return {
      'events': _mockEvents.map((e) => e.toMap()).toList(),
      'categories': _mockCategories,
      'groups': _mockGroups.map((g) => g.toMap()).toList(),
      'reminders': _mockReminders,
    };
  }

  @override
  Future<void> importAllData(Map<String, dynamic> data) async {}

  @override
  Future<void> close() async {}
}


// Manual Mock for WebDAVService
class MockWebDAVService implements WebDAVService {
  bool failConnection = false;
  bool failUpload = false;
  bool failDownload = false;
  
  @override
  void initialize(WebDAVConfig config) {}

  @override
  Future<bool> testConnection() async => !failConnection;

  @override
  Future<void> ensureRemoteWorkspace() async {}

  @override
  Future<bool> uploadFile(String localPath, String remotePath) async => !failUpload;

  @override
  Future<bool> downloadFile(String remotePath, String localPath) async => !failDownload;

  @override
  Future<bool> deleteRemote(String remotePath) async => true;

  @override
  Future<List<webdav.File>?> listRemoteFiles({String remotePath = ''}) async => [];
}

/// Setup all required MethodChannel mocks
void setupChannelMocks() {
  const channels = [
    'plugins.flutter.io/path_provider',
    'plugins.it_nomads.com/flutter_secure_storage',
    'com.llfbandit.app_links/messages',
    'com.llfbandit.app_links/events',
    'com.jiuxina.ying/install',
    'home_widget',
    'plugins.flutter.io/image_picker',
    'plugins.flutter.io/shared_preferences', // Just in case
  ];

  for (final name in channels) {
    final channel = MethodChannel(name);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      // Return appropriate defaults
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return '.'; // Or temp path if needed, but handled in specific tests usually
      }
      if (methodCall.method == 'getInitialLink') return null;
      if (methodCall.method == 'saveWidgetData') return true;
      if (methodCall.method == 'updateWidget') return true;
      if (methodCall.method == 'pickImage') return null;
      
      return null;
    });
  }
}

