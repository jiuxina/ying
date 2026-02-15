import 'package:flutter_test/flutter_test.dart';
import 'package:ying/services/debug_service.dart';

void main() {
  group('DebugService', () {
    late DebugService debugService;

    setUp(() {
      debugService = DebugService();
      // Clear any existing logs from previous tests
      debugService.clearLogs();
      debugService.clearRouteHistory();
    });

    test('should be a singleton', () {
      final instance1 = DebugService();
      final instance2 = DebugService();
      expect(instance1, same(instance2));
    });

    test('should log messages with correct level', () {
      debugService.info('Test info message', source: 'Test');
      debugService.warning('Test warning message', source: 'Test');
      debugService.error('Test error message', source: 'Test');
      debugService.debug('Test debug message', source: 'Test');

      expect(debugService.logs.length, 4);
      expect(debugService.logs[0].level, 'info');
      expect(debugService.logs[1].level, 'warning');
      expect(debugService.logs[2].level, 'error');
      expect(debugService.logs[3].level, 'debug');
    });

    test('should limit log entries to maximum', () {
      // Add more than max logs (500)
      for (int i = 0; i < 600; i++) {
        debugService.info('Log $i');
      }

      expect(debugService.logs.length, 500);
      // First log should be removed, so the oldest should be log 100
      expect(debugService.logs.first.message, 'Log 100');
    });

    test('should record route history', () {
      debugService.recordRoute('/home');
      debugService.recordRoute('/settings');
      debugService.recordRoute('/debug');

      expect(debugService.routeHistory.length, 3);
      expect(debugService.routeHistory[0], contains('/home'));
      expect(debugService.routeHistory[1], contains('/settings'));
      expect(debugService.routeHistory[2], contains('/debug'));
    });

    test('should limit route history to maximum', () {
      // Add more than max routes (50)
      for (int i = 0; i < 60; i++) {
        debugService.recordRoute('/route$i');
      }

      expect(debugService.routeHistory.length, 50);
      expect(debugService.routeHistory.first, contains('/route10'));
    });

    test('should update app state', () {
      expect(debugService.appState, 'Initializing');
      
      debugService.updateAppState('Resumed');
      expect(debugService.appState, 'Resumed');
      
      debugService.updateAppState('Paused');
      expect(debugService.appState, 'Paused');
    });

    test('should collect system info', () async {
      await debugService.collectSystemInfo();
      
      expect(debugService.systemInfo.isNotEmpty, true);
      expect(debugService.systemInfo.containsKey('Platform'), true);
      expect(debugService.systemInfo.containsKey('Processors'), true);
    });

    test('should clear logs', () {
      debugService.info('Test message 1');
      debugService.info('Test message 2');
      expect(debugService.logs.length, 2);

      debugService.clearLogs();
      // clearLogs() adds one log entry about clearing
      expect(debugService.logs.length, 1);
      expect(debugService.logs.first.message, 'Logs cleared');
    });

    test('should clear route history', () {
      debugService.recordRoute('/home');
      debugService.recordRoute('/settings');
      expect(debugService.routeHistory.length, 2);

      debugService.clearRouteHistory();
      // clearRouteHistory() doesn't add to route history, only logs
      expect(debugService.routeHistory.length, 0);
    });

    test('should notify listeners on log addition', () {
      var listenerCalled = false;
      debugService.addListener(() {
        listenerCalled = true;
      });

      debugService.info('Test message');
      expect(listenerCalled, true);
    });

    test('should format time correctly', () {
      debugService.recordRoute('/test');
      
      // Check that route history contains time in HH:mm:ss format
      final routeEntry = debugService.routeHistory.first;
      // Should match format like "14:30:25 -> /test"
      expect(routeEntry, matches(r'\d{2}:\d{2}:\d{2} -> /test'));
    });

    test('should include source in log entry', () {
      debugService.info('Test message', source: 'TestSource');
      
      final logEntry = debugService.logs.first;
      expect(logEntry.source, 'TestSource');
      expect(logEntry.toString(), contains('TestSource'));
    });

    test('should handle log without source', () {
      debugService.info('Test message without source');
      
      final logEntry = debugService.logs.first;
      expect(logEntry.source, isNull);
    });
  });
}
