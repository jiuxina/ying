import 'package:flutter_test/flutter_test.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/models/widget_holiday.dart';
import 'package:ying/services/wallpaper_color_service.dart';
import 'package:ying/services/widget_service.dart';

void main() {
  group('节日皮肤', () {
    test('新年与圣诞按本地日期判定', () {
      expect(holidayFor(DateTime(2027, 1, 1)), WidgetHoliday.newYear);
      expect(holidayFor(DateTime(2026, 12, 24)), WidgetHoliday.christmas);
      expect(holidayFor(DateTime(2026, 12, 26)), WidgetHoliday.christmas);
      expect(holidayFor(DateTime(2026, 8, 8)), WidgetHoliday.none);
    });

    test('中秋按农历八月十五判定', () {
      expect(holidayFor(DateTime(2026, 9, 25)), WidgetHoliday.midAutumn);
      expect(holidayFor(DateTime(2025, 10, 6)), WidgetHoliday.midAutumn);
      expect(holidayFor(DateTime(2026, 9, 26)), isNot(WidgetHoliday.midAutumn));
    });

    test('生日皮肤只在目标日命中', () {
      final event = CountdownEvent(
        id: 'birthday',
        title: '妈妈的生日',
        targetDate: DateTime(2026, 5, 20),
        category: '家庭',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(holidayForEvent(event, DateTime(2027, 5, 20)), WidgetHoliday.birthday);
      expect(holidayForEvent(event, DateTime(2027, 5, 21)), WidgetHoliday.none);
      expect(
        holidayForEvent(event.copyWith(title: '纪念日'), DateTime(2027, 5, 20)),
        WidgetHoliday.none,
      );
    });

    test('日期型节日优先于生日皮肤', () {
      final event = CountdownEvent(
        id: 'birthday',
        title: '生日',
        targetDate: DateTime(2027, 1, 1),
        category: '生活',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(combinedHoliday(event, DateTime(2027, 1, 1)), WidgetHoliday.newYear);
    });
  });

  group('壁纸取色辅助', () {
    test('对比色按亮度选择黑白', () {
      expect(contrastTextColor(0xFF0F766E), 0xFFFFFFFF);
      expect(contrastTextColor(0xFFFFFFFF), 0xFF101418);
      expect(contrastTextColor(0xFF111111), 0xFFFFFFFF);
    });
  });

  group('小部件协议 v9', () {
    test('偏好值携带协议版本与节日字段', () {
      final values = widgetPreferenceValues(
        const AppSettings(),
        now: DateTime(2026, 9, 25),
      );
      expect(values['widget_protocol_version'], 10);
      expect(values['widget_holiday'], 'mid_autumn');
      expect(values['widget_style'], 'card');
    });

    test('未知节日名称回退 none', () {
      expect(WidgetHoliday.fromName('spring-festival'), WidgetHoliday.none);
      expect(WidgetHoliday.fromName('christmas'), WidgetHoliday.christmas);
    });
  });
}
