import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/services/widget_service.dart';
import 'package:ying/services/widget_interaction_service.dart';

void main() {
  CountdownEvent event({
    String id = 'evt',
    int days = 5,
    bool countingUp = false,
  }) {
    final base = DateTime(2026, 8, 8);
    return CountdownEvent(
      id: id,
      title: '考试',
      targetDate: base.add(Duration(days: days)),
      category: '学习',
      direction: countingUp ? CountDirection.countup : CountDirection.auto,
      createdAt: base.subtract(const Duration(days: 30)),
    );
  }

  group('widgetShareCardText', () {
    test('future event uses 还有', () {
      expect(
        widgetShareCardText(event(days: 5), now: DateTime(2026, 8, 8)),
        '考试：还有 5 天',
      );
    });

    test('past count-up event uses 已经', () {
      expect(
        widgetShareCardText(
          event(days: -3, countingUp: true),
          now: DateTime(2026, 8, 8),
        ),
        '考试：已经 3 天',
      );
    });

    test('today event returns 就是今天', () {
      expect(
        widgetShareCardText(event(days: 0), now: DateTime(2026, 8, 8)),
        '考试：就是今天',
      );
    });
  });

  group('PendingUndoPayload', () {
    test('round-trips event and expiry', () {
      final source = event(id: 'undo-me', days: 2);
      final expiresAt = DateTime(2026, 8, 8, 12, 0, 6);
      final restored = PendingUndoPayload.decode(
        PendingUndoPayload(event: source, expiresAt: expiresAt).encode(),
      )!;
      expect(restored.event.id, 'undo-me');
      expect(restored.event.title, '考试');
      expect(restored.expiresAt, expiresAt);
    });

    test('rejects malformed payload', () {
      expect(PendingUndoPayload.decode(null), isNull);
      expect(PendingUndoPayload.decode(''), isNull);
      expect(PendingUndoPayload.decode('not-json'), isNull);
      expect(PendingUndoPayload.decode('{"event":{}}'), isNull);
    });
  });

  test('undo window is six seconds', () {
    expect(widgetUndoWindow, const Duration(seconds: 6));
  });

  group('WidgetService.syncWithFlip', () {
    test('writes previous day when day changes', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final calls = <MethodCall>[];
      final messenger = TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('home_widget'),
        (call) async {
          calls.add(call);
          if (call.method == 'getWidgetData') {
            return 5;
          }
          if (call.method == 'saveWidgetData') {
            return true;
          }
          if (call.method == 'updateWidget') {
            return true;
          }
          if (call.method == 'setAppGroupId') {
            return true;
          }
          return null;
        },
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          const MethodChannel('home_widget'),
          null,
        ),
      );

      final base = DateTime(2026, 8, 8);
      final events = [
        CountdownEvent(
          id: 'flip',
          title: '考试',
          targetDate: base.add(const Duration(days: 4)),
          category: '学习',
          createdAt: base.subtract(const Duration(days: 30)),
        ),
      ];
      await WidgetService.syncWithFlip(events, const AppSettings());

      final flipWrites = calls
          .where(
            (call) =>
                call.method == 'saveWidgetData' &&
                (call.arguments as Map<Object?, Object?>)['id'] ==
                    'widget_flip_day',
          )
          .toList();
      expect(flipWrites, hasLength(1));
      expect(
        (flipWrites.single.arguments as Map<Object?, Object?>)['data'],
        5,
      );
    });
  });
}
