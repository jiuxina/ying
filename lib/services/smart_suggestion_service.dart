import '../models/intelligence_models.dart';
import '../services/database_service.dart';
import '../services/natural_language_parser.dart';
import '../services/holiday_detector.dart';

/// 智能建议服务
///
/// 提供多种智能建议功能：
/// - 分类建议
/// - 标签建议
/// - 重复事件检测
/// - 季节性建议
/// - 基于标题的智能推断
class SmartSuggestionService {
  final DatabaseService _dbService;
  final NaturalLanguageParser _parser;
  late final SmartCategoryEngine _categoryEngine;

  SmartSuggestionService({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService(),
        _parser = NaturalLanguageParser() {
    _categoryEngine = SmartCategoryEngine(_dbService);
  }

  // ==================== 分类建议 ====================

  /// 获取分类建议
  ///
  /// 基于标题、日期、用户历史等多维度分析
  Future<List<SmartSuggestion>> getCategorySuggestions(String title) async {
    final suggestions = <SmartSuggestion>[];
    
    // 1. 基于关键词匹配
    final keywordSuggestions = _getKeywordBasedSuggestions(title);
    suggestions.addAll(keywordSuggestions);
    
    // 2. 基于用户历史
    final historySuggestions = await _categoryEngine.suggestFromHistory(title);
    // historySuggestions returns a single SmartSuggestion, so add it directly
    if (historySuggestions.data.isNotEmpty) {
      final s = historySuggestions;
      // 如果已存在相同分类，合并分数
      final existingIndex = suggestions.indexWhere(
        (e) => e.data['categoryId'] == s.data['categoryId'],
      );
      if (existingIndex >= 0) {
        suggestions[existingIndex] = SmartSuggestion(
          suggestionId: suggestions[existingIndex].suggestionId,
          type: SuggestionType.category,
          title: suggestions[existingIndex].title,
          description: suggestions[existingIndex].description,
          confidence: (suggestions[existingIndex].confidence + s.confidence) / 2,
          data: suggestions[existingIndex].data,
          reason: '${suggestions[existingIndex].reason}；${s.reason}',
        );
      } else {
        suggestions.add(s);
      }
    }
    // 3. 检测节日
    final holidayName = HolidayDetector.suggestHolidayName(title);
    if (holidayName != null) {
      suggestions.add(SmartSuggestion(
        suggestionId: 'holiday_${DateTime.now().millisecondsSinceEpoch}',
        type: SuggestionType.category,
        title: '节假日',
        description: '检测到可能与 $holidayName 相关',
        confidence: 0.85,
        data: {'categoryId': 'holiday', 'detectedHoliday': holidayName},
        reason: '标题包含节日关键词',
      ));
    }
    
    // 排序并返回
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return suggestions;
  }

  /// 基于关键词的分类建议
  List<SmartSuggestion> _getKeywordBasedSuggestions(String title) {
    final suggestions = <SmartSuggestion>[];
    final lowerTitle = title.toLowerCase();
    
    // 生日关键词
    final birthdayKeywords = ['生日', '生辰', '寿', '诞辰', 'birthday'];
    if (birthdayKeywords.any((k) => lowerTitle.contains(k))) {
      suggestions.add(SmartSuggestion(
        suggestionId: 'keyword_birthday',
        type: SuggestionType.category,
        title: '生日',
        description: '检测到生日相关内容',
        confidence: 0.9,
        data: {'categoryId': 'birthday'},
        reason: '标题包含生日关键词',
      ));
    }
    
    // 纪念日关键词
    final anniversaryKeywords = ['纪念', '周年', '结婚', '恋爱', '订婚', '领证', '婚礼'];
    if (anniversaryKeywords.any((k) => lowerTitle.contains(k))) {
      suggestions.add(SmartSuggestion(
        suggestionId: 'keyword_anniversary',
        type: SuggestionType.category,
        title: '纪念日',
        description: '检测到纪念日相关内容',
        confidence: 0.85,
        data: {'categoryId': 'anniversary'},
        reason: '标题包含纪念日关键词',
      ));
    }
    
    // 考试关键词
    final examKeywords = ['考试', '高考', '中考', '考研', '考公', '雅思', '托福', '四级', '六级', '面试', '答辩'];
    if (examKeywords.any((k) => lowerTitle.contains(k))) {
      suggestions.add(SmartSuggestion(
        suggestionId: 'keyword_exam',
        type: SuggestionType.category,
        title: '考试',
        description: '检测到考试相关内容',
        confidence: 0.85,
        data: {'categoryId': 'exam'},
        reason: '标题包含考试关键词',
      ));
    }
    
    // 工作关键词
    final workKeywords = ['会议', '截止', 'deadline', '提交', '汇报', '出差', '入职', '培训', '项目'];
    if (workKeywords.any((k) => lowerTitle.contains(k))) {
      suggestions.add(SmartSuggestion(
        suggestionId: 'keyword_work',
        type: SuggestionType.category,
        title: '工作',
        description: '检测到工作相关内容',
        confidence: 0.8,
        data: {'categoryId': 'work'},
        reason: '标题包含工作关键词',
      ));
    }
    
    // 旅行关键词
    final travelKeywords = ['旅行', '旅游', '出游', '度假', '机票', '酒店', '出行', '行程'];
    if (travelKeywords.any((k) => lowerTitle.contains(k))) {
      suggestions.add(SmartSuggestion(
        suggestionId: 'keyword_travel',
        type: SuggestionType.category,
        title: '旅行',
        description: '检测到旅行相关内容',
        confidence: 0.8,
        data: {'categoryId': 'travel'},
        reason: '标题包含旅行关键词',
      ));
    }
    
    return suggestions;
  }

  // ==================== 标签建议 ====================

  /// 获取标签建议
  ///
  /// 基于标题和分类推断可能的标签
  Future<List<String>> getTagSuggestions(String title, String? categoryId) async {
    final tags = <String>{};
    final lowerTitle = title.toLowerCase();
    
    // 关系标签
    if (lowerTitle.contains('妈妈') || lowerTitle.contains('母亲')) {
      tags.add('家人');
      tags.add('重要');
    }
    if (lowerTitle.contains('爸爸') || lowerTitle.contains('父亲')) {
      tags.add('家人');
      tags.add('重要');
    }
    if (lowerTitle.contains('男友') || lowerTitle.contains('女朋友') || 
        lowerTitle.contains('老公') || lowerTitle.contains('老婆')) {
      tags.add('伴侣');
      tags.add('重要');
    }
    
    // 重要性标签
    if (lowerTitle.contains('重要') || lowerTitle.contains('紧急') ||
        lowerTitle.contains('必须') || lowerTitle.contains('关键')) {
      tags.add('重要');
    }
    
    // 时间标签
    if (lowerTitle.contains('每年') || lowerTitle.contains('年度')) {
      tags.add('年度');
    }
    if (lowerTitle.contains('每月') || lowerTitle.contains('月度')) {
      tags.add('月度');
    }
    
    // 基于分类的标签
    switch (categoryId) {
      case 'birthday':
        tags.add('生日');
        tags.add('年度');
        break;
      case 'anniversary':
        tags.add('纪念');
        tags.add('年度');
        break;
      case 'exam':
        tags.add('学习');
        break;
      case 'work':
        tags.add('工作');
        break;
      case 'travel':
        tags.add('出行');
        break;
    }
    
    // 获取用户常用标签（从历史事件）
    final frequentTags = await _getFrequentTags();
    for (final tag in frequentTags) {
      // 如果标签关键词出现在标题中，添加该标签
      if (lowerTitle.contains(tag.toLowerCase())) {
        tags.add(tag);
      }
    }
    
    return tags.toList()..sort();
  }

  /// 获取用户常用标签
  Future<List<String>> _getFrequentTags() async {
    // 从历史事件的备注中提取标签
    // 简化实现：返回预定义的常见标签
    return ['重要', '家人', '工作', '学习', '生活', '年度'];
  }

  // ==================== 重复事件检测 ====================

  /// 检测可能的重复事件
  ///
  /// 返回相似事件的列表
  Future<DuplicateCheckResult> checkDuplicate(String title, DateTime? targetDate) async {
    final events = await _dbService.getActiveEvents();
    final matches = <DuplicateMatch>[];
    
    for (final event in events) {
      final similarity = _calculateSimilarity(title, event.title);
      
      // 完全相同
      if (similarity > 0.95) {
        matches.add(DuplicateMatch(
          eventId: event.id,
          eventTitle: event.title,
          similarity: similarity,
          duplicateType: DuplicateType.exact,
        ));
        continue;
      }
      
      // 相似标题
      if (similarity > 0.7) {
        matches.add(DuplicateMatch(
          eventId: event.id,
          eventTitle: event.title,
          similarity: similarity,
          duplicateType: DuplicateType.similarTitle,
        ));
        continue;
      }
      
      // 同一日期
      if (targetDate != null &&
          event.targetDate.year == targetDate.year &&
          event.targetDate.month == targetDate.month &&
          event.targetDate.day == targetDate.day) {
        matches.add(DuplicateMatch(
          eventId: event.id,
          eventTitle: event.title,
          similarity: similarity,
          duplicateType: DuplicateType.sameDate,
        ));
      }
    }
    
    // 计算最高相似度
    final highestSimilarity = matches.isNotEmpty
        ? matches.map((m) => m.similarity).reduce((a, b) => a > b ? a : b)
        : 0.0;
    
    return DuplicateCheckResult(
      isDuplicate: matches.any((m) => m.similarity > 0.9),
      matches: matches,
      highestSimilarity: highestSimilarity,
    );
  }

  /// 计算字符串相似度（Jaccard相似度）
  double _calculateSimilarity(String s1, String s2) {
    // 标准化
    final normalized1 = s1.toLowerCase().trim();
    final normalized2 = s2.toLowerCase().trim();
    
    // 完全相同
    if (normalized1 == normalized2) return 1.0;
    
    // 计算字符集合
    final set1 = normalized1.split('').toSet();
    final set2 = normalized2.split('').toSet();
    
    // Jaccard 相似度
    final intersection = set1.intersection(set2).length;
    final union = set2.union(set2).length;
    
    if (union == 0) return 0.0;
    return intersection / union;
  }

  // ==================== 季节性建议 ====================

  /// 获取季节性事件建议
  ///
  /// 根据当前时间推荐相关的季节性事件
  Future<List<SmartSuggestion>> getSeasonalSuggestions() async {
    final suggestions = <SmartSuggestion>[];
    final now = DateTime.now();
    final month = now.month;
    
    // 春季（3-5月）
    if (month >= 3 && month <= 5) {
      suggestions.add(SmartSuggestion(
        suggestionId: 'seasonal_spring',
        type: SuggestionType.holiday,
        title: '清明节',
        description: '春季重要节日，踏青扫墓',
        confidence: 0.6,
        data: {'categoryId': 'holiday', 'month': 4},
        reason: '春季时节',
      ));
    }
    
    // 夏季（6-8月）
    if (month >= 6 && month <= 8) {
      suggestions.add(SmartSuggestion(
        suggestionId: 'seasonal_summer',
        type: SuggestionType.holiday,
        title: '端午节',
        description: '夏季传统节日',
        confidence: 0.6,
        data: {'categoryId': 'holiday'},
        reason: '夏季时节',
      ));
    }
    
    // 秋季（9-11月）
    if (month >= 9 && month <= 11) {
      suggestions.add(SmartSuggestion(
        suggestionId: 'seasonal_autumn',
        type: SuggestionType.holiday,
        title: '中秋节',
        description: '秋季传统节日，团圆赏月',
        confidence: 0.7,
        data: {'categoryId': 'holiday'},
        reason: '秋季时节',
      ));
      suggestions.add(SmartSuggestion(
        suggestionId: 'seasonal_autumn_national',
        type: SuggestionType.holiday,
        title: '国庆节',
        description: '10月1日国庆节',
        confidence: 0.8,
        data: {'categoryId': 'holiday', 'month': 10, 'day': 1},
        reason: '秋季时节',
      ));
    }
    
    // 冬季（12-2月）
    if (month == 12 || month <= 2) {
      suggestions.add(SmartSuggestion(
        suggestionId: 'seasonal_winter_ny',
        type: SuggestionType.holiday,
        title: '春节',
        description: '农历新年，最重要的传统节日',
        confidence: 0.8,
        data: {'categoryId': 'holiday', 'isLunar': true},
        reason: '冬季时节',
      ));
      suggestions.add(SmartSuggestion(
        suggestionId: 'seasonal_winter_christmas',
        type: SuggestionType.holiday,
        title: '圣诞节',
        description: '12月25日圣诞节',
        confidence: 0.6,
        data: {'categoryId': 'holiday', 'month': 12, 'day': 25},
        reason: '冬季时节',
      ));
    }
    
    // 添加即将到来的节假日
    final upcomingHolidays = HolidayDetector.getUpcomingHolidays(count: 3);
    for (final holiday in upcomingHolidays) {
      if (holiday.daysFromNow > 0 && holiday.daysFromNow <= 60) {
        suggestions.add(SmartSuggestion(
          suggestionId: 'upcoming_${holiday.name}_${holiday.date.millisecondsSinceEpoch}',
          type: SuggestionType.holiday,
          title: holiday.name,
          description: '${holiday.date.month}月${holiday.date.day}日，还有${holiday.daysFromNow}天',
          confidence: holiday.isOfficial ? 0.9 : 0.7,
          data: {
            'categoryId': 'holiday',
            'month': holiday.date.month,
            'day': holiday.date.day,
            'isLunar': holiday.type == HolidayType.lunar,
          },
          reason: '即将到来',
        ));
      }
    }
    
    return suggestions;
  }

  // ==================== 自然语言解析建议 ====================

  /// 解析自然语言输入并返回建议
  ///
  /// 综合使用自然语言解析和智能建议
  Future<SmartInputResult> parseAndSuggest(String input) async {
    // 1. 解析自然语言
    final parsed = _parser.parse(input);
    
    // 2. 获取分类建议
    List<SmartSuggestion>? categorySuggestions;
    if (parsed.title != null) {
      categorySuggestions = await getCategorySuggestions(parsed.title!);
    }
    
    // 3. 获取标签建议
    List<String>? tagSuggestions;
    if (parsed.title != null) {
      final topCategoryId = categorySuggestions?.isNotEmpty == true
          ? categorySuggestions!.first.data['categoryId'] as String?
          : parsed.categoryId;
      tagSuggestions = await getTagSuggestions(parsed.title!, topCategoryId);
    }
    
    // 4. 检测重复
    DuplicateCheckResult? duplicateCheck;
    if (parsed.title != null) {
      duplicateCheck = await checkDuplicate(parsed.title!, parsed.targetDate);
    }
    
    return SmartInputResult(
      parsed: parsed,
      categorySuggestions: categorySuggestions,
      tagSuggestions: tagSuggestions,
      duplicateCheck: duplicateCheck,
    );
  }
}

/// 智能分类引擎
///
/// 基于用户历史学习分类偏好
class SmartCategoryEngine {
  final DatabaseService _dbService;
  
  // 分类词频缓存
  Map<String, Map<String, int>> _categoryWordFrequency = {};
  bool _initialized = false;

  SmartCategoryEngine(this._dbService);

  /// 初始化引擎（加载历史数据）
  Future<void> initialize() async {
    if (_initialized) return;
    
    final events = await _dbService.getActiveEvents();
    _categoryWordFrequency = {};
    
    for (final event in events) {
      final category = event.categoryId;
      _categoryWordFrequency.putIfAbsent(category, () => {});
      
      // 分词（简单实现：按字分）
      final chars = event.title.split('');
      for (final char in chars) {
        if (char.trim().isEmpty) continue;
        _categoryWordFrequency[category]![char] = 
            (_categoryWordFrequency[category]![char] ?? 0) + 1;
      }
    }
    
    _initialized = true;
  }

  /// 从历史数据推断分类
  Future<SmartSuggestion> suggestFromHistory(String title) async {
    await initialize();
    
    if (_categoryWordFrequency.isEmpty) {
      return SmartSuggestion(
        suggestionId: 'history_default',
        type: SuggestionType.category,
        title: '其他',
        confidence: 0.3,
        data: {'categoryId': 'custom'},
        reason: '无历史数据',
      );
    }
    
    // 计算每个分类的得分
    final scores = <String, double>{};
    final chars = title.split('');
    
    for (final entry in _categoryWordFrequency.entries) {
      final category = entry.key;
      final frequencies = entry.value;
      
      double score = 0;
      int matched = 0;
      
      for (final char in chars) {
        if (frequencies.containsKey(char)) {
          score += frequencies[char]!;
          matched++;
        }
      }
      
      // 归一化
      if (matched > 0) {
        scores[category] = score / matched;
      }
    }
    
    // 找出最高分的分类
    if (scores.isEmpty) {
      return SmartSuggestion(
        suggestionId: 'history_no_match',
        type: SuggestionType.category,
        title: '其他',
        confidence: 0.3,
        data: {'categoryId': 'custom'},
        reason: '历史数据无匹配',
      );
    }
    
    final sortedScores = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final bestMatch = sortedScores.first;
    
    // 获取分类名称
    final categories = await _dbService.getAllCategories();
    final categoryName = categories.firstWhere(
      (c) => c['id'] == bestMatch.key,
      orElse: () => {'name': '其他'},
    )['name'] as String;
    
    return SmartSuggestion(
      suggestionId: 'history_${bestMatch.key}',
      type: SuggestionType.category,
      title: categoryName,
      confidence: (bestMatch.value / 10).clamp(0.3, 0.9),
      data: {'categoryId': bestMatch.key},
      reason: '基于您的习惯推断',
    );
  }
}

/// 智能输入结果
class SmartInputResult {
  final ParsedEventInput parsed;
  final List<SmartSuggestion>? categorySuggestions;
  final List<String>? tagSuggestions;
  final DuplicateCheckResult? duplicateCheck;

  const SmartInputResult({
    required this.parsed,
    this.categorySuggestions,
    this.tagSuggestions,
    this.duplicateCheck,
  });

  bool get hasSuggestions =>
      (categorySuggestions?.isNotEmpty ?? false) ||
      (tagSuggestions?.isNotEmpty ?? false);

  bool get hasDuplicates => duplicateCheck?.isDuplicate ?? false;

  /// 获取最佳分类建议
  SmartSuggestion? get bestCategorySuggestion =>
      categorySuggestions?.isNotEmpty == true ? categorySuggestions!.first : null;

  /// 获取摘要
  String get summary {
    final parts = <String>[];
    
    if (parsed.title != null) {
      parts.add('标题: ${parsed.title}');
    }
    if (parsed.targetDate != null) {
      parts.add('日期: ${_formatDate(parsed.targetDate!)}');
    }
    if (bestCategorySuggestion != null) {
      parts.add('分类: ${bestCategorySuggestion!.title}');
    }
    
    return parts.join(' | ');
  }

  static String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
