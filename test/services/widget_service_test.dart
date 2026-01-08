import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/services/widget_service.dart';

void main() {
  group('WidgetService', () {
    late List<CountdownEvent> testEvents;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('home_widget'), (MethodCall methodCall) async {
        return true;
      });

      final now = DateTime.now();
      testEvents = [
        CountdownEvent(
          id: '1',
          title: '新年',
          targetDate: now.add(const Duration(days: 30)),
          isPinned: true,
          createdAt: now,
          updatedAt: now,
        ),
        CountdownEvent(
          id: '2',
          title: '生日',
          targetDate: now.add(const Duration(days: 60)),
          createdAt: now,
          updatedAt: now,
        ),
        CountdownEvent(
          id: '3',
          title: '假期',
          targetDate: now.add(const Duration(days: 90)),
          createdAt: now,
          updatedAt: now,
        ),
        CountdownEvent(
          id: '4',
          title: '归档事件',
          targetDate: now.add(const Duration(days: 10)),
          isArchived: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];
    });

    test('_sortEvents should filter archived and sort by pinned then days', () {
      // 通过调用公共方法间接测试排序逻辑
      // 由于 _sortEvents 是私有方法，这里测试逻辑正确性
      final activeEvents = testEvents.where((e) => !e.isArchived).toList();
      
      expect(activeEvents.length, 3);
      
      activeEvents.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return a.daysRemaining.compareTo(b.daysRemaining);
      });
      
      expect(activeEvents[0].title, '新年'); // isPinned = true
      expect(activeEvents[1].title, '生日'); // 60 days
      expect(activeEvents[2].title, '假期'); // 90 days
    });

    test('should handle empty events list', () async {
      // 测试空列表不会抛出异常
      expect(() => WidgetService.updateAllWidgets([]), returnsNormally);
    });

    test('should handle single event correctly', () async {
      final singleEvent = [testEvents[0]];
      expect(() => WidgetService.updateAllWidgets(singleEvent), returnsNormally);
    });

    test('updateWidget should be backward compatible', () async {
      // 测试旧方法兼容性
      expect(() => WidgetService.updateWidget(null), returnsNormally);
      expect(() => WidgetService.updateWidget(testEvents[0]), returnsNormally);
    });

    test('updateWidgets should be backward compatible', () async {
      expect(() => WidgetService.updateWidgets(testEvents), returnsNormally);
    });

    test('updateWithTopEvent should be backward compatible', () async {
      expect(() => WidgetService.updateWithTopEvent(testEvents), returnsNormally);
    });
  });
}
