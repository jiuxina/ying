import 'package:lunar/lunar.dart';

/// 农历工具类
class LunarUtils {
  /// 获取农历日期字符串
  static String getLunarDateString(DateTime date) {
    final lunar = Lunar.fromDate(date);
    return '${lunar.getYearInChinese()}年${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
  }

  /// 获取简短农历日期字符串（月日）
  static String getShortLunarDateString(DateTime date) {
    final lunar = Lunar.fromDate(date);
    return '${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
  }

  /// 农历转公历
  static DateTime lunarToSolar(int year, int month, int day, {bool isLeapMonth = false}) {
    final lunar = Lunar.fromYmd(year, month, day);
    final solar = lunar.getSolar();
    return DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
  }

  /// 公历转农历
  static Lunar solarToLunar(DateTime date) {
    return Lunar.fromDate(date);
  }

  /// 获取农历年份列表（用于选择器）
  static List<int> getLunarYears() {
    final currentYear = DateTime.now().year;
    return List.generate(100, (i) => currentYear - 50 + i);
  }

  /// 获取农历月份列表
  static List<String> getLunarMonths() {
    return ['正月', '二月', '三月', '四月', '五月', '六月', 
            '七月', '八月', '九月', '十月', '冬月', '腊月'];
  }

  /// 获取农历日期列表
  static List<String> getLunarDays() {
    return [
      '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
      '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
      '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十',
    ];
  }

  /// 获取下一个农历日期对应的公历日期（用于重复事件）
  static DateTime getNextLunarDate(int lunarMonth, int lunarDay) {
    final now = DateTime.now();
    final currentLunar = Lunar.fromDate(now);
    
    int targetYear = currentLunar.getYear();
    
    // 如果今年的这个农历日期已经过了，就取明年的
    final thisYearLunar = Lunar.fromYmd(targetYear, lunarMonth, lunarDay);
    final thisYearSolar = thisYearLunar.getSolar();
    final thisYearDate = DateTime(thisYearSolar.getYear(), thisYearSolar.getMonth(), thisYearSolar.getDay());
    
    if (thisYearDate.isBefore(now)) {
      targetYear++;
    }
    
    final targetLunar = Lunar.fromYmd(targetYear, lunarMonth, lunarDay);
    final targetSolar = targetLunar.getSolar();
    return DateTime(targetSolar.getYear(), targetSolar.getMonth(), targetSolar.getDay());
  }
}
