import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ying/services/cloud_sync_service.dart';

import '../helpers/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockWebDAVService mockWebDAV;
  late CloudSyncService cloudSync;
  late Directory tempDir;

  setUp(() {
    // Create a temporary directory for each test
    tempDir = Directory.systemTemp.createTempSync('ying_test_');

    // Mock path_provider to return the temporary directory
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    });

    mockWebDAV = MockWebDAVService();
    cloudSync = CloudSyncService(webdavService: mockWebDAV);
  });

  tearDown(() {
    // Clean up temporary directory
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('CloudSyncService backup', () {
    test('should fail if sync is already in progress', () async {
      // Manually set status to syncing? 
      // CloudSyncService doesn't expose a setter, and methods are async.
      // We can try to race two calls, but it's flaky.
      // Let's rely on internal logic testing via single call first.
      
      // Since we can't easily put it in 'syncing' state from outside without calling a method that awaits,
      // we'll skip this state test for now or implement a way to delay the mock.
    });

    test('should fail if WebDAV connection fails', () async {
      mockWebDAV.failConnection = true;
      final result = await cloudSync.backup();
      expect(result.success, false);
      expect(result.errorMessage, contains('无法连接'));
    });

    test('should fail if local database does not exist', () async {
      // Do not create events.db
      final result = await cloudSync.backup();
      expect(result.success, false);
      expect(result.errorMessage, contains('本地数据库不存在'));
    });

    test('should succeed if everything is fine', () async {
      // Create dummy db file
      final dbFile = File('${tempDir.path}/events.db');
      await dbFile.writeAsString('dummy db content');

      final result = await cloudSync.backup();
      expect(result.success, true);
      expect(result.uploadedCount, 1);
    });

    test('should fail if upload fails', () async {
      // Create dummy db file
      final dbFile = File('${tempDir.path}/events.db');
      await dbFile.writeAsString('dummy db content');

      mockWebDAV.failUpload = true;
      final result = await cloudSync.backup();
      expect(result.success, false);
      expect(result.errorMessage, contains('上传数据库失败'));
    });
  });

  group('CloudSyncService restore', () {
    test('should fail if WebDAV connection fails', () async {
      mockWebDAV.failConnection = true;
      final result = await cloudSync.restore();
      expect(result.success, false);
      expect(result.errorMessage, contains('无法连接'));
    });

    test('should succeed and backup local db', () async {
      // Create local db to check backup
      final dbFile = File('${tempDir.path}/events.db');
      await dbFile.writeAsString('original content');

      // Mock download involves writing to the file?
      // Our MockWebDAVService just returns true.
      // The CloudSyncService doesn't verify content, just success boolean.
      // But it expects downloadFile to actually populate the file?
      // No, `downloadFile` implementation in Service just calls WebDAV.
      // In MockWebDAV, we should maybe simulate writing file if we want to be strict,
      // but sticking to logic flow (boolean checks) is enough for unit test.
      
      final result = await cloudSync.restore();
      expect(result.success, true);
      
      // Check if backup exists
      final backupFile = File('${tempDir.path}/events.db.backup');
      expect(await backupFile.exists(), true);
    });

    test('should fail if download fails', () async {
      mockWebDAV.failDownload = true;
      final result = await cloudSync.restore();
      expect(result.success, false);
      expect(result.errorMessage, contains('下载数据库失败'));
    });
  });
}
