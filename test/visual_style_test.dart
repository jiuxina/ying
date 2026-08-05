import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/services/storage_service.dart';
import 'package:ying/state/app_controller.dart';
import 'package:ying/ui/app_theme.dart';
import 'package:ying/ui/home_page.dart';

void main() {
  test('theme follows the reference HTML palette', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();

    expect(light.colorScheme.primary, const Color(0xFF0F766E));
    expect(light.scaffoldBackgroundColor, const Color(0xFFFCFBF9));
    expect(dark.colorScheme.primary, const Color(0xFFBEF264));
    expect(dark.scaffoldBackgroundColor, const Color(0xFF0F1115));
  });

  testWidgets('mobile navigation keeps days, add and settings entries', (
    tester,
  ) async {
    final controller = AppController(
      StorageService(),
      autoLoad: false,
      loadEvents: () async => const [],
      saveEvents: (_) async {},
      loadSettings: () async => const AppSettings(),
      saveSettings: (_) async {},
      scheduleNotification: (_) async {},
      cancelNotification: (_) async {},
      syncWidget: (_, _) async {},
      timerFactory: (_, _) => _IdleTimer(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appControllerProvider.overrideWith((ref) => controller)],
        child: MaterialApp(theme: AppTheme.light(), home: const HomePage()),
      ),
    );
    await tester.pump();

    expect(find.text('日子'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.byTooltip('新建倒数日'), findsOneWidget);
  });
}

class _IdleTimer implements Timer {
  bool _active = true;

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}
