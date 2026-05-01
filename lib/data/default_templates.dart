import '../models/event_template.dart';

/// ============================================================================
/// 默认事件模板数据
/// ============================================================================

/// 内置模板列表
/// 
/// 包含常用的事件模板，用户可以快速使用或修改后另存
class DefaultTemplates {
  /// 获取所有内置模板
  static List<EventTemplate> getAll() {
    return [
      // ==================== 生日类 ====================
      EventTemplate(
        id: 'builtin_birthday_self',
        name: '我的生日',
        description: '记录自己的生日，自动计算年龄',
        category: 'birthday',
        icon: '🎂',
        defaultValues: {
          'categoryId': 'birthday',
          'isRepeating': true,
          'enableNotification': true,
        },
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        features: [
          TemplateFeature.autoAgeCalculation,
          TemplateFeature.dynamicTitle,
          TemplateFeature.yearlyRepeat,
        ],
      ),
      
      EventTemplate(
        id: 'builtin_birthday_family',
        name: '家人生日',
        description: '记录家人生日，每年提醒',
        category: 'birthday',
        icon: '👨‍👩‍👧‍👦',
        defaultValues: {
          'categoryId': 'birthday',
          'isRepeating': true,
          'enableNotification': true,
        },
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        features: [
          TemplateFeature.autoAgeCalculation,
          TemplateFeature.yearlyRepeat,
        ],
      ),
      
      EventTemplate(
        id: 'builtin_birthday_friend',
        name: '朋友生日',
        description: '记录朋友生日，不再错过祝福',
        category: 'birthday',
        icon: '🎉',
        defaultValues: {
          'categoryId': 'birthday',
          'isRepeating': true,
          'enableNotification': true,
        },
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        features: [
          TemplateFeature.yearlyRepeat,
        ],
      ),
      
      // ==================== 纪念日类 ====================
      EventTemplate(
        id: 'builtin_anniversary_love',
        name: '恋爱纪念日',
        description: '记录恋爱开始的日子，见证爱情',
        category: 'anniversary',
        icon: '❤️',
        defaultValues: {
          'categoryId': 'anniversary',
          'isRepeating': true,
          'enableNotification': true,
        },
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        features: [
          TemplateFeature.yearlyRepeat,
        ],
      ),
      
      EventTemplate(
        id: 'builtin_anniversary_wedding',
        name: '结婚纪念日',
        description: '记录结婚周年，纪念重要时刻',
        category: 'anniversary',
        icon: '💒',
        defaultValues: {
          'categoryId': 'anniversary',
          'isRepeating': true,
          'enableNotification': true,
        },
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        features: [
          TemplateFeature.yearlyRepeat,
        ],
      ),
      
      EventTemplate(
        id: 'builtin_anniversary_work',
        name: '入职纪念日',
        description: '记录入职日期，见证职业成长',
        category: 'anniversary',
        icon: '💼',
        defaultValues: {
          'categoryId': 'work',
          'isRepeating': true,
          'enableNotification': false,
        },
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        features: [
          TemplateFeature.yearlyRepeat,
        ],
      ),
      
      // ==================== 考试类 ====================
      EventTemplate(
        id: 'builtin_exam_final',
        name: '期末考试',
        description: '倒计时期末考试，合理安排复习',
        category: 'exam',
        icon: '📝',
        defaultValues: {
          'categoryId': 'exam',
          'isRepeating': false,
          'enableNotification': true,
        },
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        features: [],
      ),
      
      EventTemplate(
        id: 'builtin_exam_cet',
        name: '英语四六级',
        description: '英语四六级考试倒计时',
        category: 'exam',
        icon: '📖',
        defaultValues: {
          'categoryId': 'exam',
          'isRepeating': false,
          'enableNotification': true,
        },
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        features: [],
      ),
      
      EventTemplate(
        id: 'builtin_exam_graduate',
        name: '考研',
        description: '考研倒计时，为目标努力',
        category: 'exam',
        icon: '🎓',
        defaultValues: {
          'categoryId': 'exam',
          'isRepeating': false,
          'enableNotification': true,
        },
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        features: [],
      ),
      
      // ==================== 节日类 ====================
      EventTemplate(
        id: 'builtin_holiday_spring',
        name: '春节',
        description: '农历新年倒计时，支持农历日期',
        category: 'holiday',
        icon: '🧧',
        defaultValues: {
          'categoryId': 'holiday',
          'isLunar': true,
          'lunarMonth': 1,
          'lunarDay': 1,
          'isRepeating': true,
          'enableNotification': true,
        },
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        features: [
          TemplateFeature.lunarDateConversion,
          TemplateFeature.yearlyRepeat,
        ],
      ),
      
      EventTemplate(
        id: 'builtin_holiday_mid_autumn',
        name: '中秋节',
        description: '农历八月十五，团圆佳节',
        category: 'holiday',
        icon: '🥮',
        defaultValues: {
          'categoryId': 'holiday',
          'isLunar': true,
          'lunarMonth': 8,
          'lunarDay': 15,
          'isRepeating': true,
          'enableNotification': true,
        },
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        features: [
          TemplateFeature.lunarDateConversion,
          TemplateFeature.yearlyRepeat,
        ],
      ),
      
      EventTemplate(
        id: 'builtin_holiday_national',
        name: '国庆节',
        description: '十一假期倒计时',
        category: 'holiday',
        icon: '🇨🇳',
        defaultValues: {
          'categoryId': 'holiday',
          'targetMonth': 10,
          'targetDay': 1,
          'isRepeating': true,
          'enableNotification': false,
        },
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        features: [
          TemplateFeature.yearlyRepeat,
        ],
      ),
      
      // ==================== 工作类 ====================
      EventTemplate(
        id: 'builtin_work_deadline',
        name: '项目截止日期',
        description: '项目交付倒计时，把控进度',
        category: 'work',
        icon: '📊',
        defaultValues: {
          'categoryId': 'work',
          'isRepeating': false,
          'enableNotification': true,
        },
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        features: [],
      ),
      
      EventTemplate(
        id: 'builtin_work_meeting',
        name: '重要会议',
        description: '重要会议倒计时提醒',
        category: 'work',
        icon: '📅',
        defaultValues: {
          'categoryId': 'work',
          'isRepeating': false,
          'enableNotification': true,
        },
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        features: [],
      ),
      
      // ==================== 旅行类 ====================
      EventTemplate(
        id: 'builtin_travel_trip',
        name: '旅行出发',
        description: '期待已久的旅行，倒计时出发',
        category: 'travel',
        icon: '✈️',
        defaultValues: {
          'categoryId': 'travel',
          'isRepeating': false,
          'enableNotification': true,
        },
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        features: [],
      ),
      
      EventTemplate(
        id: 'builtin_travel_vacation',
        name: '假期开始',
        description: '期待假期的到来',
        category: 'travel',
        icon: '🏖️',
        defaultValues: {
          'categoryId': 'travel',
          'isRepeating': false,
          'enableNotification': true,
        },
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        features: [],
      ),
      
      // ==================== 生活类 ====================
      EventTemplate(
        id: 'builtin_life_newyear',
        name: '新年倒计时',
        description: '跨年倒计时，迎接新的一年',
        category: 'life',
        icon: '🎆',
        defaultValues: {
          'categoryId': 'holiday',
          'targetMonth': 1,
          'targetDay': 1,
          'isRepeating': true,
          'enableNotification': true,
        },
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        features: [
          TemplateFeature.yearlyRepeat,
        ],
      ),
      
      EventTemplate(
        id: 'builtin_life_mortgage',
        name: '房贷还款日',
        description: '每月房贷还款提醒',
        category: 'life',
        icon: '🏠',
        defaultValues: {
          'categoryId': 'life',
          'isRepeating': true,
          'enableNotification': true,
        },
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        features: [
          TemplateFeature.yearlyRepeat,
        ],
      ),
    ];
  }
  
  /// 根据分类获取模板
  static List<EventTemplate> getByCategory(String category) {
    return getAll().where((t) => t.category == category).toList();
  }
  
  /// 根据ID获取模板
  static EventTemplate? getById(String id) {
    try {
      return getAll().firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
  
  /// 搜索模板
  static List<EventTemplate> search(String query) {
    final lowerQuery = query.toLowerCase();
    return getAll().where((t) {
      return t.name.toLowerCase().contains(lowerQuery) ||
          (t.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          t.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
