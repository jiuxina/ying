import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ying/providers/settings_provider.dart';
import 'package:ying/services/debug_service.dart';

void main() {
  group('SettingsProvider Debug Logging', () {
    late SettingsProvider settingsProvider;
    late DebugService debugService;

    setUp(() async {
      // Initialize SharedPreferences with mock
      SharedPreferences.setMockInitialValues({});
      
      settingsProvider = SettingsProvider();
      debugService = DebugService();
      
      // Clear debug logs
      debugService.clearLogs();
      
      // Initialize the settings provider
      await settingsProvider.init();
      
      // Clear the initialization log
      debugService.clearLogs();
    });

    test('should log theme mode changes', () async {
      await settingsProvider.setThemeMode(ThemeMode.dark);
      
      // Check that a log entry was created
      expect(debugService.logs.length, greaterThan(0));
      final log = debugService.logs.last;
      expect(log.level, 'info');
      expect(log.source, 'Settings');
      expect(log.message, contains('Theme mode changed'));
      expect(log.message, contains('dark'));
    });

    test('should log font size changes', () async {
      debugService.clearLogs();
      
      await settingsProvider.setFontSizePx(18.0);
      
      expect(debugService.logs.length, greaterThan(0));
      final log = debugService.logs.last;
      expect(log.level, 'info');
      expect(log.source, 'Settings');
      expect(log.message, contains('Font size (px) changed'));
      expect(log.message, contains('18'));
    });

    test('should log background effect changes', () async {
      debugService.clearLogs();
      
      await settingsProvider.setBackgroundEffect('gradient');
      
      expect(debugService.logs.length, greaterThan(0));
      final log = debugService.logs.last;
      expect(log.level, 'info');
      expect(log.source, 'Settings');
      expect(log.message, contains('Background effect changed'));
      expect(log.message, contains('gradient'));
    });

    test('should log particle type changes', () async {
      debugService.clearLogs();
      
      await settingsProvider.setParticleType('sakura');
      
      expect(debugService.logs.length, greaterThan(0));
      final log = debugService.logs.last;
      expect(log.level, 'info');
      expect(log.source, 'Settings');
      expect(log.message, contains('Particle type changed'));
      expect(log.message, contains('sakura'));
    });

    test('should log progress bar style changes', () async {
      debugService.clearLogs();
      
      await settingsProvider.setProgressStyle('background');
      
      expect(debugService.logs.length, greaterThan(0));
      final log = debugService.logs.last;
      expect(log.level, 'info');
      expect(log.source, 'Settings');
      expect(log.message, contains('Progress bar style changed'));
      expect(log.message, contains('background'));
    });

    test('should log sort order changes', () async {
      debugService.clearLogs();
      
      await settingsProvider.setSortOrder('daysDesc');
      
      expect(debugService.logs.length, greaterThan(0));
      final log = debugService.logs.last;
      expect(log.level, 'info');
      expect(log.source, 'Settings');
      expect(log.message, contains('Sort order changed'));
      expect(log.message, contains('daysDesc'));
    });

    test('should log cloud sync settings', () async {
      debugService.clearLogs();
      
      await settingsProvider.setAutoSyncEnabled(true);
      
      expect(debugService.logs.length, greaterThan(0));
      final log = debugService.logs.last;
      expect(log.level, 'info');
      expect(log.source, 'Settings');
      expect(log.message, contains('Auto sync'));
      expect(log.message, contains('enabled'));
    });

    test('should log debug mode toggle', () async {
      debugService.clearLogs();
      
      await settingsProvider.setDebugModeEnabled(true);
      
      expect(debugService.logs.length, greaterThan(0));
      final log = debugService.logs.last;
      expect(log.level, 'info');
      expect(log.source, 'Settings');
      expect(log.message, contains('Debug mode'));
      expect(log.message, contains('enabled'));
    });

    test('should log all settings changes with proper format', () async {
      debugService.clearLogs();
      
      // Make multiple changes
      await settingsProvider.setThemeMode(ThemeMode.dark);
      await settingsProvider.setFontSizePx(16.0);
      await settingsProvider.setParticleType('snow');
      
      // Verify all logs have the correct structure
      expect(debugService.logs.length, 3);
      
      for (final log in debugService.logs) {
        expect(log.level, 'info');
        expect(log.source, 'Settings');
        expect(log.message.isNotEmpty, true);
        expect(log.timestamp, isNotNull);
      }
    });

    test('should not expose sensitive data in logs', () async {
      debugService.clearLogs();
      
      await settingsProvider.setWebdavPassword('super-secret-password');
      
      expect(debugService.logs.length, greaterThan(0));
      final log = debugService.logs.last;
      expect(log.message, contains('WebDAV password updated'));
      // Ensure password is NOT in the log message
      expect(log.message, isNot(contains('super-secret-password')));
    });
  });
}
