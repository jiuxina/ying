import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ying/screens/settings/debug_console_screen.dart';
import 'package:ying/services/debug_service.dart';

void main() {
  group('DebugConsoleScreen', () {
    late DebugService debugService;

    setUp(() {
      debugService = DebugService();
      debugService.clearLogs();
      debugService.clearRouteHistory();
    });

    testWidgets('should display console screen with tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DebugConsoleScreen(),
        ),
      );

      // Verify the title is displayed
      expect(find.text('调试控制台'), findsOneWidget);

      // Verify tabs are present
      expect(find.text('日志'), findsOneWidget);
      expect(find.text('路由'), findsOneWidget);
      expect(find.text('系统'), findsOneWidget);

      // Verify back button is present
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('should display empty state when no logs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DebugConsoleScreen(),
        ),
      );

      // Should show empty state
      expect(find.text('暂无日志'), findsOneWidget);
    });

    testWidgets('should display logs when available', (WidgetTester tester) async {
      // Add some test logs
      debugService.info('Test info message', source: 'Test');
      debugService.warning('Test warning', source: 'Test');
      debugService.error('Test error', source: 'Test');

      await tester.pumpWidget(
        const MaterialApp(
          home: DebugConsoleScreen(),
        ),
      );

      // Wait for the UI to update
      await tester.pumpAndSettle();

      // Should show log count
      expect(find.textContaining('3'), findsWidgets);

      // Should show log messages (in the ExpansionTile)
      expect(find.textContaining('Test info message'), findsOneWidget);
      expect(find.textContaining('Test warning'), findsOneWidget);
      expect(find.textContaining('Test error'), findsOneWidget);
    });

    testWidgets('should have filter chips for log levels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DebugConsoleScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify filter chips exist
      expect(find.textContaining('全部'), findsOneWidget);
      expect(find.textContaining('信息'), findsOneWidget);
      expect(find.textContaining('警告'), findsOneWidget);
      expect(find.textContaining('错误'), findsOneWidget);
      expect(find.textContaining('调试'), findsOneWidget);
    });

    testWidgets('should filter logs by level when chip is tapped', (WidgetTester tester) async {
      // Add different types of logs
      debugService.info('Info message', source: 'Test');
      debugService.warning('Warning message', source: 'Test');
      debugService.error('Error message', source: 'Test');

      await tester.pumpWidget(
        const MaterialApp(
          home: DebugConsoleScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the error filter chip
      await tester.tap(find.textContaining('错误'));
      await tester.pumpAndSettle();

      // Should show only error logs
      expect(find.textContaining('显示 1 / 3'), findsOneWidget);
    });

    testWidgets('should have search field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DebugConsoleScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify search field exists
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('搜索日志内容或来源...'), findsOneWidget);
    });

    testWidgets('should filter logs by search query', (WidgetTester tester) async {
      // Add test logs
      debugService.info('Database connected', source: 'Database');
      debugService.info('Network request', source: 'Network');
      debugService.info('Database query executed', source: 'Database');

      await tester.pumpWidget(
        const MaterialApp(
          home: DebugConsoleScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Type in search field
      await tester.enterText(find.byType(TextField), 'Database');
      await tester.pumpAndSettle();

      // Should show filtered count
      expect(find.textContaining('显示 2 / 3'), findsOneWidget);
    });

    testWidgets('should display clear log button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DebugConsoleScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify clear button exists
      expect(find.text('清空日志'), findsOneWidget);
    });

    testWidgets('should switch to routes tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DebugConsoleScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on routes tab
      await tester.tap(find.text('路由'));
      await tester.pumpAndSettle();

      // Should show routes empty state
      expect(find.text('暂无导航记录'), findsOneWidget);
    });

    testWidgets('should display routes when available', (WidgetTester tester) async {
      // Add test routes
      debugService.recordRoute('/home');
      debugService.recordRoute('/settings');
      debugService.recordRoute('/debug');

      await tester.pumpWidget(
        const MaterialApp(
          home: DebugConsoleScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on routes tab
      await tester.tap(find.text('路由'));
      await tester.pumpAndSettle();

      // Should show route count
      expect(find.textContaining('共 3 条导航记录'), findsOneWidget);
    });

    testWidgets('should switch to system tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DebugConsoleScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on system tab
      await tester.tap(find.text('系统'));
      await tester.pumpAndSettle();

      // Should show system info section
      expect(find.text('调试控制台说明'), findsOneWidget);
      expect(find.text('应用状态'), findsOneWidget);
    });

    testWidgets('should have refresh button on system tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DebugConsoleScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on system tab
      await tester.tap(find.text('系统'));
      await tester.pumpAndSettle();

      // Verify refresh button exists
      expect(find.text('刷新系统信息'), findsOneWidget);
    });

    testWidgets('should expand log details when tapped', (WidgetTester tester) async {
      debugService.info('Test message', source: 'TestSource');

      await tester.pumpWidget(
        const MaterialApp(
          home: DebugConsoleScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the expansion tile
      final expansionTile = find.byType(ExpansionTile).first;
      await tester.tap(expansionTile);
      await tester.pumpAndSettle();

      // Should show detailed information
      expect(find.text('时间:'), findsOneWidget);
      expect(find.text('级别:'), findsOneWidget);
      expect(find.text('来源:'), findsOneWidget);
      expect(find.text('消息:'), findsOneWidget);
    });
  });
}
