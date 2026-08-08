import 'package:lunar/lunar.dart';

import 'countdown_event.dart';

/// 小部件节日皮肤。日期型节日按本地日期自动计算，生日皮肤绑定具体事件。
enum WidgetHoliday {
  none(''),
  newYear('新年'),
  christmas('圣诞'),
  midAutumn('中秋'),
  birthday('生日');

  const WidgetHoliday(this.label);

  final String label;

  /// 写入小部件协议的 snake_case 值，与 Android 侧保持一致。
  String get wireName {
    switch (this) {
      case WidgetHoliday.none:
        return '';
      case WidgetHoliday.newYear:
        return 'new_year';
      case WidgetHoliday.christmas:
        return 'christmas';
      case WidgetHoliday.midAutumn:
        return 'mid_autumn';
      case WidgetHoliday.birthday:
        return 'birthday';
    }
  }

  static WidgetHoliday fromName(String? name) {
    return WidgetHoliday.values.firstWhere(
      (value) => value.wireName == name,
      orElse: () => WidgetHoliday.none,
    );
  }
}

/// 按本地日期计算日期型节日；农历换算复用成熟 lunar 库。
WidgetHoliday holidayFor(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  if (day.month == 1 && day.day == 1) return WidgetHoliday.newYear;
  if (day.month == 12 && day.day >= 24 && day.day <= 26) {
    return WidgetHoliday.christmas;
  }
  final lunar = Solar.fromDate(day).getLunar();
  if (lunar.getMonth() == 8 && lunar.getDay() == 15) {
    return WidgetHoliday.midAutumn;
  }
  return WidgetHoliday.none;
}

/// 事件级生日皮肤：标题或分类标记生日，且今天正是目标日期。
WidgetHoliday holidayForEvent(CountdownEvent event, DateTime date) {
  if (!event.title.contains('生日') && !event.category.contains('生日')) {
    return WidgetHoliday.none;
  }
  final target = event.dateOnly;
  if (target.month == date.month && target.day == date.day) {
    return WidgetHoliday.birthday;
  }
  return WidgetHoliday.none;
}

/// 日期型节日优先，其次才是事件生日皮肤，避免两者叠加。
WidgetHoliday combinedHoliday(CountdownEvent? event, DateTime date) {
  final base = holidayFor(date);
  if (base != WidgetHoliday.none) return base;
  return event == null ? WidgetHoliday.none : holidayForEvent(event, date);
}
