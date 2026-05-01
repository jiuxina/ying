import 'package:lunar/lunar.dart';
import '../models/intelligence_models.dart';

/// 自然语言解析服务
///
/// 解析中文自然语言输入，提取事件信息：
/// - 标题识别
/// - 日期解析（支持多种格式）
/// - 农历日期识别
/// - 重复模式识别
/// - 分类推断
class NaturalLanguageParser {
  // ==================== 日期相关正则 ====================

  /// 相对日期模式
  static final _relativeDatePatterns = {
    // 今天相关
    RegExp(r'今[天日]'): 0,
    RegExp(r'今天'): 0,
    // 明天相关
    RegExp(r'明[天日]'): 1,
    RegExp(r'明天'): 1,
    // 后天
    RegExp(r'后[天日]'): 2,
    RegExp(r'后天'): 2,
    // 大后天
    RegExp(r'大后天'): 3,
    // 昨天（用于正计时事件）
    RegExp(r'昨[天日]'): -1,
    RegExp(r'昨天'): -1,
    // 前天
    RegExp(r'前[天日]'): -2,
  };

  /// 星期相关模式
  static final _weekdayPatterns = [
    (pattern: RegExp(r'下?周[一1]'), weekday: 1, name: '周一'),
    (pattern: RegExp(r'下?周[二2]'), weekday: 2, name: '周二'),
    (pattern: RegExp(r'下?周[三3]'), weekday: 3, name: '周三'),
    (pattern: RegExp(r'下?周[四4]'), weekday: 4, name: '周四'),
    (pattern: RegExp(r'下?周[五5]'), weekday: 5, name: '周五'),
    (pattern: RegExp(r'下?周[六6]'), weekday: 6, name: '周六'),
    (pattern: RegExp(r'下?周[日天7]'), weekday: 7, name: '周日'),
  ];

  /// 数字月份中文
  static const _chineseMonths = {
    '一': 1, '正': 1,
    '二': 2,
    '三': 3,
    '四': 4,
    '五': 5,
    '六': 6,
    '七': 7,
    '八': 8,
    '九': 9,
    '十': 10,
    '十一': 11, '冬': 11,
    '十二': 12, '腊': 12,
  };

  /// 数字日期中文
  static const _chineseDays = {
    '一': 1, '初一': 1,
    '二': 2, '初二': 2,
    '三': 3, '初三': 3,
    '四': 4, '初四': 4,
    '五': 5, '初五': 5,
    '六': 6, '初六': 6,
    '七': 7, '初七': 7,
    '八': 8, '初八': 8,
    '九': 9, '初九': 9,
    '十': 10, '初十': 10,
    '十一': 11,
    '十二': 12,
    '十三': 13,
    '十四': 14,
    '十五': 15,
    '十六': 16,
    '十七': 17,
    '十八': 18,
    '十九': 19,
    '二十': 20,
    '廿一': 21, '二十一': 21,
    '廿二': 22, '二十二': 22,
    '廿三': 23, '二十三': 23,
    '廿四': 24, '二十四': 24,
    '廿五': 25, '二十五': 25,
    '廿六': 26, '二十六': 26,
    '廿七': 27, '二十七': 27,
    '廿八': 28, '二十八': 28,
    '廿九': 29, '二十九': 29,
    '三十': 30,
  };

  /// 数字转换
  static const _numberWords = {
    '零': 0, '〇': 0,
    '一': 1, '壹': 1,
    '二': 2, '贰': 2, '两': 2,
    '三': 3, '叁': 3,
    '四': 4, '肆': 4,
    '五': 5, '伍': 5,
    '六': 6, '陆': 6,
    '七': 7, '柒': 7,
    '八': 8, '捌': 8,
    '九': 9, '玖': 9,
    '十': 10, '拾': 10,
    '百': 100, '佰': 100,
    '千': 1000, '仟': 1000,
    '万': 10000, '萬': 10000,
  };

  // ==================== 分类关键词 ====================

  /// 分类关键词映射
  static final _categoryKeywords = {
    'birthday': [
      '生日', '生辰', '诞辰', '出生', '寿辰', '做寿', '祝寿',
      '生日快乐', 'happy birthday', 'birthday',
    ],
    'anniversary': [
      '纪念日', '结婚', '恋爱', '周年', '在一起', '订婚', '领证',
      '婚礼', '婚庆', '结婚纪念日', '恋爱纪念日',
    ],
    'holiday': [
      '春节', '元旦', '元宵', '清明', '端午', '中秋', '国庆',
      '劳动节', '儿童节', '教师节', '情人节', '圣诞节', '万圣节',
      '母亲节', '父亲节', '妇女节', '青年节', '建军节', '过年',
      '除夕', '新年', '节日', '假期', '放假',
    ],
    'exam': [
      '考试', '高考', '中考', '考研', '考公', '雅思', '托福',
      '四级', '六级', '期末', '期中', '测验', '测试', '面试',
      '笔试', '口试', '答辩', '毕业', '开学', '放假',
    ],
    'work': [
      '会议', '截止', 'deadline', '提交', '汇报', '出差',
      '入职', '离职', '面试', '培训', '项目', '任务', '工作',
      '加班', '值班', '报告', '开题', '答辩', '入职',
    ],
    'travel': [
      '旅行', '旅游', '出游', '度假', '出发', '返程', '机票',
      '火车票', '酒店', '景点', '游玩', '出行', '行程',
    ],
  };

  /// 重复事件关键词
  static final _repeatingKeywords = [
    '每年', '每年一次', '一年一次', '年年',
    '生日', '纪念日', '周年',
  ];

  /// 农历关键词
  static final _lunarKeywords = [
    '农历', '阴历', '初', '腊月', '正月',
    '大年初', '新年', '春节',
  ];

  // ==================== 主解析方法 ====================

  /// 解析自然语言输入
  ///
  /// 支持的格式示例：
  /// - "妈妈生日 下周五"
  /// - "考试 2024年6月15日"
  /// - "春节 农历正月初一"
  /// - "明天 开会"
  /// - "后天下午3点 面试"
  ParsedEventInput parse(String input) {
    if (input.trim().isEmpty) {
      return const ParsedEventInput();
    }

    final warnings = <String>[];
    final rawExtracted = <String, dynamic>{};
    
    // 规范化输入
    final normalizedInput = _normalizeInput(input);
    
    // 检测农历
    final isLunar = _detectLunar(normalizedInput);
    
    // 提取日期
    DateTime? targetDate;
    String? lunarDateStr;
    String remainingText = normalizedInput;
    
    if (isLunar) {
      final lunarResult = _extractLunarDate(normalizedInput);
      if (lunarResult.date != null) {
        targetDate = lunarResult.date;
        lunarDateStr = lunarResult.dateStr;
        remainingText = lunarResult.remainingText;
        rawExtracted['lunarMonth'] = lunarResult.month;
        rawExtracted['lunarDay'] = lunarResult.day;
      }
    } else {
      final dateResult = _extractSolarDate(normalizedInput);
      if (dateResult.date != null) {
        targetDate = dateResult.date;
        remainingText = dateResult.remainingText;
        rawExtracted['extractedDate'] = dateResult.matchedText;
      }
    }
    
    // 如果没有提取到日期，尝试提取星期
    if (targetDate == null) {
      final weekdayResult = _extractWeekday(remainingText);
      if (weekdayResult.date != null) {
        targetDate = weekdayResult.date;
        remainingText = weekdayResult.remainingText;
        rawExtracted['extractedWeekday'] = weekdayResult.matchedText;
      }
    }
    
    // 如果还是没有日期，尝试提取相对日期
    if (targetDate == null) {
      final relativeResult = _extractRelativeDate(remainingText);
      if (relativeResult.date != null) {
        targetDate = relativeResult.date;
        remainingText = relativeResult.remainingText;
        rawExtracted['relativeDays'] = relativeResult.daysOffset;
      }
    }
    
    // 提取标题
    String? title = _extractTitle(remainingText);
    if (title != null) {
      rawExtracted['title'] = title;
    }
    
    // 推断分类
    final categoryId = _inferCategory(title ?? normalizedInput);
    if (categoryId != null) {
      rawExtracted['inferredCategory'] = categoryId;
    }
    
    // 检测是否为重复事件
    final isRepeating = _detectRepeating(normalizedInput, categoryId);
    if (isRepeating) {
      rawExtracted['isRepeating'] = true;
    }
    
    // 计算置信度
    double confidence = 0.0;
    if (title != null) confidence += 0.3;
    if (targetDate != null) confidence += 0.4;
    if (categoryId != null) confidence += 0.2;
    if (isLunar && lunarDateStr != null) confidence += 0.1;
    
    return ParsedEventInput(
      title: title,
      targetDate: targetDate,
      isLunar: isLunar,
      lunarDateStr: lunarDateStr,
      categoryId: categoryId,
      isRepeating: isRepeating,
      confidence: confidence.clamp(0.0, 1.0),
      warnings: warnings,
      rawExtracted: rawExtracted,
    );
  }

  // ==================== 辅助方法 ====================

  /// 规范化输入
  String _normalizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // 多个空格合并为一个
        .replaceAll('　', ' ') // 全角空格
        .toLowerCase();
  }

  /// 检测农历
  bool _detectLunar(String input) {
    for (final keyword in _lunarKeywords) {
      if (input.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  /// 提取公历日期
  _DateExtractionResult _extractSolarDate(String input) {
    DateTime? date;
    String matchedText = '';
    String remainingText = input;
    
    final now = DateTime.now();
    
    // 格式: YYYY年MM月DD日
    final fullDatePattern = RegExp(
      r'(\d{4})[年\-\/\.](\d{1,2})[月\-\/\.](\d{1,2})[日号]?',
    );
    final fullMatch = fullDatePattern.firstMatch(input);
    if (fullMatch != null) {
      final year = int.parse(fullMatch.group(1)!);
      final month = int.parse(fullMatch.group(2)!);
      final day = int.parse(fullMatch.group(3)!);
      date = DateTime(year, month, day);
      matchedText = fullMatch.group(0)!;
      remainingText = input.replaceAll(matchedText, '').trim();
      return _DateExtractionResult(
        date: date,
        matchedText: matchedText,
        remainingText: remainingText,
      );
    }
    
    // 格式: MM月DD日（当年）
    final monthDayPattern = RegExp(r'(\d{1,2})[月](\d{1,2})[日号]');
    final monthDayMatch = monthDayPattern.firstMatch(input);
    if (monthDayMatch != null) {
      final month = int.parse(monthDayMatch.group(1)!);
      final day = int.parse(monthDayMatch.group(2)!);
      var year = now.year;
      
      // 如果日期已过，使用明年
      final tempDate = DateTime(year, month, day);
      if (tempDate.isBefore(now)) {
        year++;
      }
      
      date = DateTime(year, month, day);
      matchedText = monthDayMatch.group(0)!;
      remainingText = input.replaceAll(matchedText, '').trim();
      return _DateExtractionResult(
        date: date,
        matchedText: matchedText,
        remainingText: remainingText,
      );
    }
    
    // 格式: 数字日期 YYYY-MM-DD 或 YYYY/MM/DD
    final numericPattern = RegExp(r'(\d{4})[\-\/](\d{1,2})[\-\/](\d{1,2})');
    final numericMatch = numericPattern.firstMatch(input);
    if (numericMatch != null) {
      final year = int.parse(numericMatch.group(1)!);
      final month = int.parse(numericMatch.group(2)!);
      final day = int.parse(numericMatch.group(3)!);
      date = DateTime(year, month, day);
      matchedText = numericMatch.group(0)!;
      remainingText = input.replaceAll(matchedText, '').trim();
      return _DateExtractionResult(
        date: date,
        matchedText: matchedText,
        remainingText: remainingText,
      );
    }
    
    return _DateExtractionResult(remainingText: remainingText);
  }

  /// 提取农历日期
  _LunarDateExtractionResult _extractLunarDate(String input) {
    DateTime? date;
    String? dateStr;
    String remainingText = input;
    int? lunarMonth;
    int? lunarDay;
    
    final now = DateTime.now();
    
    // 格式: 农历X月X 或 正月十五 等
    final lunarPattern = RegExp(
      r'(?:农历|阴历)?([正一二三四五六七八九十腊冬]+)月([初一二三四五六七八九十廿]+[一二三四五六七八九十]?)',
    );
    final match = lunarPattern.firstMatch(input);
    
    if (match != null) {
      final monthStr = match.group(1)!;
      final dayStr = match.group(2)!;
      
      lunarMonth = _chineseMonths[monthStr];
      lunarDay = _chineseDays[dayStr];
      
      if (lunarMonth != null && lunarDay != null) {
        try {
          // 转换为公历
          final currentYear = now.year;
          final lunar = Lunar.fromYmd(currentYear, lunarMonth, lunarDay);
          var solar = lunar.getSolar();
          var solarDate = DateTime(
            solar.getYear(),
            solar.getMonth(),
            solar.getDay(),
          );
          
          // 如果日期已过，使用明年
          if (solarDate.isBefore(now)) {
            final nextLunar = Lunar.fromYmd(currentYear + 1, lunarMonth, lunarDay);
            solar = nextLunar.getSolar();
            solarDate = DateTime(
              solar.getYear(),
              solar.getMonth(),
              solar.getDay(),
            );
          }
          
          date = solarDate;
          dateStr = '农历${monthStr}月${dayStr}';
          remainingText = input.replaceAll(match.group(0)!, '').trim();
        } catch (e) {
          // 农历日期无效
        }
      }
    }
    
    return _LunarDateExtractionResult(
      date: date,
      dateStr: dateStr,
      month: lunarMonth,
      day: lunarDay,
      remainingText: remainingText,
    );
  }

  /// 提取星期
  _DateExtractionResult _extractWeekday(String input) {
    DateTime? date;
    String matchedText = '';
    String remainingText = input;
    
    final now = DateTime.now();
    final currentWeekday = now.weekday;
    
    for (final entry in _weekdayPatterns) {
      if (entry.pattern.hasMatch(input)) {
        final match = entry.pattern.firstMatch(input)!;
        matchedText = match.group(0)!;
        
        // 判断是否为"下周X"
        final isNext = matchedText.contains('下');
        var targetWeekday = entry.weekday;
        
        // DateTime 的 weekday: 1=周一, 7=周日
        // 我们的模式中 weekday: 1=周一, 7=周日
        
        int daysUntil;
        if (isNext) {
          // 下周X
          daysUntil = 7 - currentWeekday + targetWeekday;
        } else {
          // 本周X
          daysUntil = targetWeekday - currentWeekday;
          if (daysUntil <= 0) {
            // 如果已过，则认为是下周
            daysUntil += 7;
          }
        }
        
        date = now.add(Duration(days: daysUntil));
        date = DateTime(date.year, date.month, date.day);
        
        remainingText = input.replaceAll(matchedText, '').trim();
        break;
      }
    }
    
    return _DateExtractionResult(
      date: date,
      matchedText: matchedText,
      remainingText: remainingText,
    );
  }

  /// 提取相对日期
  _RelativeDateExtractionResult _extractRelativeDate(String input) {
    DateTime? date;
    int? daysOffset;
    String remainingText = input;
    
    for (final entry in _relativeDatePatterns.entries) {
      if (entry.key.hasMatch(input)) {
        final match = entry.key.firstMatch(input)!;
        daysOffset = entry.value;
        
        final now = DateTime.now();
        date = now.add(Duration(days: daysOffset));
        date = DateTime(date.year, date.month, date.day);
        
        remainingText = input.replaceAll(match.group(0)!, '').trim();
        break;
      }
    }
    
    return _RelativeDateExtractionResult(
      date: date,
      daysOffset: daysOffset,
      remainingText: remainingText,
    );
  }

  /// 提取标题
  String? _extractTitle(String input) {
    final title = input.trim();
    
    // 移除常见的日期相关词汇
    var cleaned = title
        .replaceAll(RegExp(r'^(在|于|到|至)\s*'), '')
        .replaceAll(RegExp(r'\s*(的|是)\s*$'), '')
        .trim();
    
    if (cleaned.isEmpty) return null;
    if (cleaned.length > 50) return cleaned.substring(0, 50);
    
    return cleaned;
  }

  /// 推断分类
  String? _inferCategory(String input) {
    final lowerInput = input.toLowerCase();
    
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerInput.contains(keyword.toLowerCase())) {
          return entry.key;
        }
      }
    }
    
    return null;
  }

  /// 检测是否为重复事件
  bool _detectRepeating(String input, String? categoryId) {
    // 生日和纪念日默认重复
    if (categoryId == 'birthday' || categoryId == 'anniversary') {
      return true;
    }
    
    // 检查关键词
    final lowerInput = input.toLowerCase();
    for (final keyword in _repeatingKeywords) {
      if (lowerInput.contains(keyword)) {
        return true;
      }
    }
    
    return false;
  }

  /// 将中文数字转换为阿拉伯数字
  int? _chineseToNumber(String chinese) {
    // 简单情况：直接匹配
    if (_numberWords.containsKey(chinese)) {
      return _numberWords[chinese];
    }
    
    // 复杂情况：需要计算（如"二十一"）
    int result = 0;
    int temp = 0;
    
    for (int i = 0; i < chinese.length; i++) {
      final char = chinese[i];
      final value = _numberWords[char];
      
      if (value == null) continue;
      
      if (value >= 10) {
        // 十、百、千、万
        if (temp == 0) temp = 1;
        result += temp * value;
        temp = 0;
      } else {
        // 个位数
        temp = value;
      }
    }
    
    result += temp;
    
    return result > 0 ? result : null;
  }
}

// ==================== 辅助类 ====================

class _DateExtractionResult {
  final DateTime? date;
  final String matchedText;
  final String remainingText;

  _DateExtractionResult({
    this.date,
    this.matchedText = '',
    required this.remainingText,
  });
}

class _LunarDateExtractionResult {
  final DateTime? date;
  final String? dateStr;
  final int? month;
  final int? day;
  final String remainingText;

  _LunarDateExtractionResult({
    this.date,
    this.dateStr,
    this.month,
    this.day,
    required this.remainingText,
  });
}

class _RelativeDateExtractionResult {
  final DateTime? date;
  final int? daysOffset;
  final String remainingText;

  _RelativeDateExtractionResult({
    this.date,
    this.daysOffset,
    required this.remainingText,
  });
}
