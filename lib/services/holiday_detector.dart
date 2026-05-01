import 'package:lunar/lunar.dart';

/// 节假日检测器
///
/// 检测中国法定节假日和传统节日：
/// - 公历节日（元旦、劳动节、国庆节等）
/// - 农历节日（春节、中秋、端午等）
/// - 国际节日（圣诞节、情人节等）
/// - 二十四节气
class HolidayDetector {
  // ==================== 公历节日 ====================

  /// 公历节日数据 (月, 日, 名称, 是否法定假日)
  static const _solarHolidays = [
    // 中国法定假日
    (1, 1, '元旦', true),
    (5, 1, '劳动节', true),
    (10, 1, '国庆节', true),
    
    // 其他重要节日
    (2, 14, '情人节', false),
    (3, 8, '妇女节', false),
    (3, 12, '植树节', false),
    (4, 1, '愚人节', false),
    (5, 4, '青年节', false),
    (6, 1, '儿童节', true),
    (7, 1, '建党节', false),
    (8, 1, '建军节', false),
    (9, 10, '教师节', false),
    (10, 31, '万圣节前夜', false),
    (11, 11, '双十一', false),
    (12, 24, '平安夜', false),
    (12, 25, '圣诞节', false),
  ];

  // ==================== 农历节日 ====================

  /// 农历节日数据 (农历月, 农历日, 名称, 是否法定假日)
  static const _lunarHolidays = [
    // 中国传统节日（农历）
    (1, 1, '春节', true),
    (1, 15, '元宵节', false),
    (2, 2, '龙抬头', false),
    (5, 5, '端午节', true),
    (7, 7, '七夕节', false),
    (7, 15, '中元节', false),
    (8, 15, '中秋节', true),
    (9, 9, '重阳节', false),
    (12, 8, '腊八节', false),
    (12, 23, '小年', false),
    (12, 30, '除夕', true), // 注意：腊月只有29天时除夕是29
  ];

  // ==================== 母亲节/父亲节 ====================

  /// 特殊节日：母亲节（5月第二个星期日）
  static DateTime? getMotherDay(int year) {
    final mayFirst = DateTime(year, 5, 1);
    final weekday = mayFirst.weekday;
    // 第一个周日 + 7天 = 第二个周日
    final firstSunday = mayFirst.add(Duration(days: (7 - weekday) % 7));
    return firstSunday.add(const Duration(days: 7));
  }

  /// 特殊节日：父亲节（6月第三个星期日）
  static DateTime? getFatherDay(int year) {
    final juneFirst = DateTime(year, 6, 1);
    final weekday = juneFirst.weekday;
    // 第一个周日 + 14天 = 第三个周日
    final firstSunday = juneFirst.add(Duration(days: (7 - weekday) % 7));
    return firstSunday.add(const Duration(days: 14));
  }

  /// 感恩节（11月第四个星期四）
  static DateTime? getThanksgiving(int year) {
    final novemberFirst = DateTime(year, 11, 1);
    final weekday = novemberFirst.weekday;
    // 第一个周四 + 21天 = 第四个周四
    int daysToThursday = (4 - weekday) % 7;
    if (daysToThursday < 0) daysToThursday += 7;
    final firstThursday = novemberFirst.add(Duration(days: daysToThursday));
    return firstThursday.add(const Duration(days: 21));
  }

  // ==================== 二十四节气 ====================

  /// 获取指定年份的所有节气
  static List<(DateTime date, String name)> getSolarTerms(int year) {
    final result = <(DateTime, String)>[];
    
    // 二十四节气的近似公历日期（简化实现）
    // 实际节气日期每年会有1-2天的浮动
    final jieQiData = {
      '小寒': DateTime(year, 1, 6),
      '大寒': DateTime(year, 1, 20),
      '立春': DateTime(year, 2, 4),
      '雨水': DateTime(year, 2, 19),
      '惊蛰': DateTime(year, 3, 6),
      '春分': DateTime(year, 3, 21),
      '清明': DateTime(year, 4, 5),
      '谷雨': DateTime(year, 4, 20),
      '立夏': DateTime(year, 5, 6),
      '小满': DateTime(year, 5, 21),
      '芒种': DateTime(year, 6, 6),
      '夏至': DateTime(year, 6, 21),
      '小暑': DateTime(year, 7, 7),
      '大暑': DateTime(year, 7, 23),
      '立秋': DateTime(year, 8, 8),
      '处暑': DateTime(year, 8, 23),
      '白露': DateTime(year, 9, 8),
      '秋分': DateTime(year, 9, 23),
      '寒露': DateTime(year, 10, 8),
      '霜降': DateTime(year, 10, 24),
      '立冬': DateTime(year, 11, 8),
      '小雪': DateTime(year, 11, 22),
      '大雪': DateTime(year, 12, 7),
      '冬至': DateTime(year, 12, 22),
    };
    
    for (final entry in jieQiData.entries) {
      result.add((entry.value, entry.key));
    }
    
    return result;
  }

  /// 获取当前/下一个节气
  static (DateTime date, String name)? getNextSolarTerm() {
    final now = DateTime.now();
    final yearTerms = getSolarTerms(now.year);
    
    for (final term in yearTerms) {
      if (term.$1.isAfter(now)) {
        return term;
      }
    }
    
    // 如果当年没有下一个节气，返回明年的第一个
    if (now.month >= 12) {
      final nextYearTerms = getSolarTerms(now.year + 1);
      if (nextYearTerms.isNotEmpty) {
        return nextYearTerms.first;
      }
    }
    
    return null;
  }

  // ==================== 节假日检测 ====================

  /// 检测指定日期的节假日
  static List<HolidayInfo> detectHolidays(DateTime date) {
    final holidays = <HolidayInfo>[];
    
    // 检测公历节日
    for (final holiday in _solarHolidays) {
      if (date.month == holiday.$1 && date.day == holiday.$2) {
        holidays.add(HolidayInfo(
          name: holiday.$3,
          date: date,
          isOfficial: holiday.$4,
          type: HolidayType.solar,
        ));
      }
    }
    
    // 检测母亲节
    final motherDay = getMotherDay(date.year);
    if (motherDay != null &&
        date.year == motherDay.year &&
        date.month == motherDay.month &&
        date.day == motherDay.day) {
      holidays.add(HolidayInfo(
        name: '母亲节',
        date: date,
        isOfficial: false,
        type: HolidayType.special,
      ));
    }
    
    // 检测父亲节
    final fatherDay = getFatherDay(date.year);
    if (fatherDay != null &&
        date.year == fatherDay.year &&
        date.month == fatherDay.month &&
        date.day == fatherDay.day) {
      holidays.add(HolidayInfo(
        name: '父亲节',
        date: date,
        isOfficial: false,
        type: HolidayType.special,
      ));
    }
    
    // 检测感恩节
    final thanksgiving = getThanksgiving(date.year);
    if (thanksgiving != null &&
        date.year == thanksgiving.year &&
        date.month == thanksgiving.month &&
        date.day == thanksgiving.day) {
      holidays.add(HolidayInfo(
        name: '感恩节',
        date: date,
        isOfficial: false,
        type: HolidayType.special,
      ));
    }
    
    // 检测农历节日
    final lunar = Lunar.fromDate(date);
    final lunarMonth = lunar.getMonth();
    final lunarDay = lunar.getDay();
    
    for (final holiday in _lunarHolidays) {
      if (lunarMonth == holiday.$1 && lunarDay == holiday.$2) {
        holidays.add(HolidayInfo(
          name: holiday.$3,
          date: date,
          isOfficial: holiday.$4,
          type: HolidayType.lunar,
          lunarMonth: lunarMonth,
          lunarDay: lunarDay,
        ));
      }
    }
    
    // 除夕特殊处理：腊月最后一天
    if (lunarMonth == 12) {
      final nextDay = date.add(const Duration(days: 1));
      final nextLunar = Lunar.fromDate(nextDay);
      // 如果明天是正月初一，今天是除夕
      if (nextLunar.getMonth() == 1 && nextLunar.getDay() == 1) {
        holidays.add(HolidayInfo(
          name: '除夕',
          date: date,
          isOfficial: true,
          type: HolidayType.lunar,
          lunarMonth: 12,
          lunarDay: lunarDay,
        ));
      }
    }
    
    // 检测节气
    final solarTerms = getSolarTerms(date.year);
    for (final term in solarTerms) {
      if (term.$1.year == date.year &&
          term.$1.month == date.month &&
          term.$1.day == date.day) {
        holidays.add(HolidayInfo(
          name: term.$2,
          date: date,
          isOfficial: false,
          type: HolidayType.solarTerm,
        ));
      }
    }
    
    return holidays;
  }

  /// 检查是否为法定假日
  static bool isOfficialHoliday(DateTime date) {
    final holidays = detectHolidays(date);
    return holidays.any((h) => h.isOfficial);
  }

  /// 获取近期即将到来的节假日
  static List<HolidayInfo> getUpcomingHolidays({
    int count = 5,
    int daysAhead = 365,
  }) {
    final holidays = <HolidayInfo>[];
    final now = DateTime.now();
    final endDate = now.add(Duration(days: daysAhead));
    
    // 遍历未来一年内的所有日期
    for (var date = now;
        date.isBefore(endDate) && holidays.length < count * 2;
        date = date.add(const Duration(days: 1))) {
      final dayHolidays = detectHolidays(date);
      holidays.addAll(dayHolidays);
    }
    
    // 去重并排序
    final uniqueHolidays = <String, HolidayInfo>{};
    for (final h in holidays) {
      final key = '${h.name}_${h.date.year}';
      if (!uniqueHolidays.containsKey(key)) {
        uniqueHolidays[key] = h;
      }
    }
    
    return uniqueHolidays.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date))
      ..length = count.clamp(0, uniqueHolidays.length);
  }

  /// 根据日期字符串检测可能的节日
  static String? suggestHolidayName(String title) {
    final lowerTitle = title.toLowerCase();
    
    // 关键词匹配
    final holidayKeywords = {
      '春节': ['春节', '过年', '新年', '大年初一'],
      '元宵节': ['元宵', '上元'],
      '清明': ['清明', '踏青'],
      '劳动节': ['五一', '劳动节', '劳工节'],
      '端午': ['端午', '粽子', '龙舟'],
      '中秋': ['中秋', '月饼'],
      '国庆': ['国庆', '十一'],
      '元旦': ['元旦', '新年'],
      '情人节': ['情人节', '2月14', '214'],
      '妇女节': ['三八', '妇女节', '女王节', '女神节'],
      '儿童节': ['六一', '儿童节'],
      '教师节': ['教师节', '老师节'],
      '圣诞节': ['圣诞', 'christmas'],
      '母亲节': ['母亲节', '妈妈节'],
      '父亲节': ['父亲节', '爸爸节'],
      '七夕': ['七夕', '乞巧', '情人节'],
      '重阳': ['重阳', '登高'],
      '腊八': ['腊八', '腊八粥'],
      '除夕': ['除夕', '大年三十'],
    };
    
    for (final entry in holidayKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerTitle.contains(keyword.toLowerCase())) {
          return entry.key;
        }
      }
    }
    
    return null;
  }

  /// 获取指定月份的主要节日
  static List<HolidayInfo> getMonthHolidays(int year, int month) {
    final holidays = <HolidayInfo>[];
    
    // 公历节日
    for (final holiday in _solarHolidays) {
      if (holiday.$1 == month) {
        holidays.add(HolidayInfo(
          name: holiday.$3,
          date: DateTime(year, month, holiday.$2),
          isOfficial: holiday.$4,
          type: HolidayType.solar,
        ));
      }
    }
    
    // 母亲节
    if (month == 5) {
      final motherDay = getMotherDay(year);
      if (motherDay != null) {
        holidays.add(HolidayInfo(
          name: '母亲节',
          date: motherDay,
          isOfficial: false,
          type: HolidayType.special,
        ));
      }
    }
    
    // 父亲节
    if (month == 6) {
      final fatherDay = getFatherDay(year);
      if (fatherDay != null) {
        holidays.add(HolidayInfo(
          name: '父亲节',
          date: fatherDay,
          isOfficial: false,
          type: HolidayType.special,
        ));
      }
    }
    
    // 感恩节
    if (month == 11) {
      final thanksgiving = getThanksgiving(year);
      if (thanksgiving != null) {
        holidays.add(HolidayInfo(
          name: '感恩节',
          date: thanksgiving,
          isOfficial: false,
          type: HolidayType.special,
        ));
      }
    }
    
    // 农历节日（需要计算该月对应的农历日期）
    // 遍历该月的每一天检测农历节日
    final startDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final lunar = Lunar.fromDate(date);
      final lunarMonth = lunar.getMonth();
      final lunarDay = lunar.getDay();
      
      for (final holiday in _lunarHolidays) {
        if (lunarMonth == holiday.$1 && lunarDay == holiday.$2) {
          holidays.add(HolidayInfo(
            name: holiday.$3,
            date: date,
            isOfficial: holiday.$4,
            type: HolidayType.lunar,
            lunarMonth: lunarMonth,
            lunarDay: lunarDay,
          ));
        }
      }
    }
    
    // 排序
    holidays.sort((a, b) => a.date.compareTo(b.date));
    
    return holidays;
  }
}

/// 节假日信息
class HolidayInfo {
  final String name;
  final DateTime date;
  final bool isOfficial;
  final HolidayType type;
  final int? lunarMonth;
  final int? lunarDay;

  const HolidayInfo({
    required this.name,
    required this.date,
    required this.isOfficial,
    required this.type,
    this.lunarMonth,
    this.lunarDay,
  });

  /// 计算距离今天的天数
  int get daysFromNow {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  /// 是否即将到来（7天内）
  bool get isUpcoming => daysFromNow > 0 && daysFromNow <= 7;

  /// 获取农历日期字符串
  String get lunarDateString {
    if (lunarMonth == null || lunarDay == null) return '';
    return '农历${lunarMonth}月${lunarDay}日';
  }

  @override
  String toString() {
    return 'HolidayInfo(name: $name, date: $date, isOfficial: $isOfficial, type: $type)';
  }
}

/// 节假日类型
enum HolidayType {
  solar, // 公历节日
  lunar, // 农历节日
  solarTerm, // 节气
  special, // 特殊计算日期的节日（如母亲节）
}
