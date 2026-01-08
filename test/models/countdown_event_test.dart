import 'package:flutter_test/flutter_test.dart';
import 'package:ying/models/countdown_event.dart';

void main() {
  group('CountdownEvent Tests', () {
    test('Should correctly calculate days remaining', () {
      final now = DateTime.now();
      final target = now.add(const Duration(days: 10));
      
      final event = CountdownEvent(
        id: '1',
        title: 'Test Event',
        targetDate: target,
        categoryId: 'custom',
        createdAt: now,
        updatedAt: now,
      );

      // Note: calculations might depend on time of day, but logic usually strips time
      // Check if calculateDaysRemaining strips time correctly
      expect(event.daysRemaining, 10);
    });

    test('Should support JSON serialization', () {
      final now = DateTime.now();
      final event = CountdownEvent(
        id: '123',
        title: 'JSON Test',
        targetDate: now,
        categoryId: 'birthday',
        createdAt: now,
        updatedAt: now,
        isPinned: true,
        note: 'Some note',
        backgroundImage: 'path/to/img',
      );

      final json = event.toMap();
      final fromJson = CountdownEvent.fromMap(json);

      expect(fromJson.id, event.id);
      expect(fromJson.title, event.title);
      expect(fromJson.isPinned, event.isPinned);
      expect(fromJson.note, event.note);
      expect(fromJson.backgroundImage, event.backgroundImage);
    });

    test('Should correctly identify count up events', () {
      final past = DateTime.now().subtract(const Duration(days: 5));
      final event = CountdownEvent(
        id: '1',
        title: 'Past Event',
        targetDate: past,
        categoryId: 'anniversary',
        createdAt: past,
        updatedAt: past,
      );

      expect(event.daysRemaining, lessThanOrEqualTo(0));
      // By default isCountUp is false. If daysRemaining < 0 and !isCountUp, it is expired.
      // If we want it to be count up, we must set isCountUp: true.
      // But let's check negative days first.
      expect(event.daysRemaining, -5); 
    });
  });
}
