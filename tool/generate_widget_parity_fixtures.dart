import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/models/widget_render_spec.dart';

void main() {
  test('regenerate shared widget parity fixtures', () async {
    final root = Directory(
      'android/app/src/test/resources/widget_parity',
    );
    root.createSync(recursive: true);
    final now = DateTime(2026, 8, 8, 12);
    final cases = <String, ({AppSettings settings, List<CountdownEvent> events})>{
      'empty_single': (
        settings: const AppSettings(),
        events: const [],
      ),
      'single_event': (
        settings: const AppSettings(
          widgetShowIcon: true,
          widgetShowNote: true,
          widgetShowCategory: true,
        ),
        events: [
          CountdownEvent(
            id: 'evt-1',
            title: '毕业典礼',
            targetDate: DateTime(2026, 8, 20),
            category: '家庭',
            note: '记得合影',
            icon: '🎂',
            createdAt: DateTime(2026, 7, 1, 9, 30),
          ),
        ],
      ),
      'list_mode': (
        settings: const AppSettings(
          widgetListMode: true,
          widgetShowPreciseTime: true,
          widgetShowCategory: true,
        ),
        events: [
          CountdownEvent(
            id: 'pinned',
            title: '置顶旅行',
            targetDate: DateTime(2026, 9, 1),
            category: '旅行',
            note: '护照',
            icon: '✈️',
            isPinned: true,
            createdAt: DateTime(2026, 7, 1),
          ),
          CountdownEvent(
            id: 'near',
            title: '面试',
            targetDate: DateTime(2026, 8, 9),
            category: '工作',
            createdAt: DateTime(2026, 7, 1),
          ),
          CountdownEvent(
            id: 'done',
            title: '已完成',
            targetDate: DateTime(2026, 8, 8),
            category: '生活',
            isCompleted: true,
            createdAt: DateTime(2026, 7, 1),
          ),
          CountdownEvent(
            id: 'far',
            title: '新年',
            targetDate: DateTime(2027, 1, 1),
            category: '节日',
            createdAt: DateTime(2026, 7, 1),
          ),
        ],
      ),
    };

    final encoder = const JsonEncoder.withIndent('  ');
    for (final entry in cases.entries) {
      final name = entry.key;
      final settings = entry.value.settings;
      final events = entry.value.events;
      final input = <String, Object?>{
        'settings': settings.toMap(),
        'events': events.map((event) => event.toJson()).toList(),
        'sponsorUnlocked': true,
        'now': now.toIso8601String(),
      };
      final spec = resolveWidgetRenderSpec(
        events,
        settings,
        sponsorUnlocked: true,
        now: now,
      );
      File('${root.path}/$name.input.json').writeAsStringSync(
        encoder.convert(input),
      );
      File('${root.path}/$name.spec.json').writeAsStringSync(
        encoder.convert(spec.toJson()),
      );
    }
  });
}
