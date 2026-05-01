import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/event_template.dart';
import '../models/countdown_event.dart';
import '../services/database_service.dart';
import '../data/default_templates.dart';
import '../utils/lunar_utils.dart';
import 'package:uuid/uuid.dart';

/// ============================================================================
/// 模板服务
/// ============================================================================

/// 模板服务 - 管理事件模板的加载、创建和使用
class TemplateService {
  static final TemplateService _instance = TemplateService._internal();
  factory TemplateService() => _instance;
  TemplateService._internal();

  final DatabaseService _dbService = DatabaseService();
  final Uuid _uuid = const Uuid();
  
  List<EventTemplate>? _cachedTemplates;

  /// 获取所有模板（内置 + 自定义）
  Future<List<EventTemplate>> getAllTemplates({bool forceReload = false}) async {
    if (_cachedTemplates != null && !forceReload) {
      return _cachedTemplates!;
    }

    // 获取内置模板
    final builtInTemplates = DefaultTemplates.getAll();
    
    // 获取自定义模板
    final customTemplates = await _getCustomTemplates();
    
    // 合并并按分类排序
    _cachedTemplates = [...builtInTemplates, ...customTemplates];
    _cachedTemplates!.sort((a, b) {
      final categorySort = TemplateCategory.builtInCategories
          .indexWhere((c) => c.id == a.category)
          .compareTo(
            TemplateCategory.builtInCategories
                .indexWhere((c) => c.id == b.category),
          );
      if (categorySort != 0) return categorySort;
      return a.name.compareTo(b.name);
    });

    return _cachedTemplates!;
  }

  /// 获取自定义模板
  Future<List<EventTemplate>> _getCustomTemplates() async {
    try {
      final maps = await _dbService.getAllTemplates();
      return maps.map((m) => EventTemplate.fromMap(m)).toList();
    } catch (e) {
      debugPrint('获取自定义模板失败: $e');
      return [];
    }
  }

  /// 根据分类获取模板
  Future<List<EventTemplate>> getTemplatesByCategory(String category) async {
    final all = await getAllTemplates();
    return all.where((t) => t.category == category).toList();
  }

  /// 根据ID获取模板
  Future<EventTemplate?> getTemplateById(String id) async {
    // 先检查内置模板
    final builtIn = DefaultTemplates.getById(id);
    if (builtIn != null) return builtIn;
    
    // 再检查自定义模板
    final all = await getAllTemplates();
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 搜索模板
  Future<List<EventTemplate>> searchTemplates(String query) async {
    final all = await getAllTemplates();
    if (query.isEmpty) return all;
    
    final lowerQuery = query.toLowerCase();
    return all.where((t) {
      return t.name.toLowerCase().contains(lowerQuery) ||
          (t.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// 添加自定义模板
  Future<EventTemplate> addCustomTemplate({
    required String name,
    String? description,
    required String category,
    required String icon,
    required Map<String, dynamic> defaultValues,
    List<TemplateFeature> features = const [],
  }) async {
    final now = DateTime.now();
    final template = EventTemplate(
      id: 'custom_${_uuid.v4()}',
      name: name,
      description: description,
      category: category,
      icon: icon,
      defaultValues: defaultValues,
      isBuiltIn: false,
      createdAt: now,
      updatedAt: now,
      features: features,
    );

    if (!template.validate()) {
      throw ArgumentError('模板数据验证失败');
    }

    await _dbService.insertTemplate(template.toMap());
    _cachedTemplates = null; // 清除缓存

    return template;
  }

  /// 更新自定义模板
  Future<void> updateTemplate(EventTemplate template) async {
    if (template.isBuiltIn) {
      throw StateError('不能修改内置模板');
    }

    final updated = template.copyWith(updatedAt: DateTime.now());
    await _dbService.updateTemplate(updated.toMap());
    _cachedTemplates = null;
  }

  /// 删除自定义模板
  Future<void> deleteTemplate(String id) async {
    final template = await getTemplateById(id);
    if (template == null) return;
    
    if (template.isBuiltIn) {
      throw StateError('不能删除内置模板');
    }

    await _dbService.deleteTemplate(id);
    _cachedTemplates = null;
  }

  /// 从事件创建模板
  Future<EventTemplate> createTemplateFromEvent(
    CountdownEvent event, {
    String? name,
    String? description,
    String? icon,
  }) async {
    return addCustomTemplate(
      name: name ?? event.title,
      description: description ?? '从事件创建的模板',
      category: event.categoryId,
      icon: icon ?? _getCategoryIcon(event.categoryId),
      defaultValues: {
        'categoryId': event.categoryId,
        'isRepeating': event.isRepeating,
        'enableNotification': event.enableNotification,
        if (event.isLunar) 'isLunar': true,
        if (event.groupId != null) 'groupId': event.groupId,
      },
      features: event.isRepeating ? [TemplateFeature.yearlyRepeat] : [],
    );
  }

  /// 从模板创建事件
  Future<CountdownEvent> createEventFromTemplate(
    EventTemplate template, {
    required DateTime targetDate,
    String? title,
    String? note,
    String? groupId,
  }) async {
    final now = DateTime.now();
    final defaults = template.defaultValues;
    
    // 处理农历日期
    DateTime eventDate = targetDate;
    bool isLunar = defaults['isLunar'] == true;
    String? lunarDateStr;
    
    if (isLunar) {
      // 从默认值获取农历月日
      final lunarMonth = defaults['lunarMonth'] as int?;
      final lunarDay = defaults['lunarDay'] as int?;
      
      if (lunarMonth != null && lunarDay != null) {
        // 转换农历到公历
        eventDate = LunarUtils.lunarToSolar(
          targetDate.year,
          lunarMonth,
          lunarDay,
        );
        lunarDateStr = LunarUtils.getLunarDateString(eventDate);
      } else {
        lunarDateStr = LunarUtils.getLunarDateString(targetDate);
      }
    }

    // 处理动态标题（年龄计算）
    String eventTitle = title ?? template.name;
    if (template.features.contains(TemplateFeature.dynamicTitle) &&
        template.features.contains(TemplateFeature.autoAgeCalculation)) {
      final age = _calculateAge(eventDate);
      if (age >= 0) {
        eventTitle = '$age岁生日';
      }
    }

    // 构建事件
    final event = CountdownEvent(
      id: const Uuid().v4(),
      title: eventTitle,
      note: note,
      targetDate: eventDate,
      isLunar: isLunar,
      lunarDateStr: lunarDateStr,
      categoryId: defaults['categoryId'] as String? ?? 'custom',
      isRepeating: defaults['isRepeating'] == true,
      enableNotification: defaults['enableNotification'] == true,
      groupId: groupId ?? defaults['groupId'] as String?,
      createdAt: now,
      updatedAt: now,
    );

    // 更新使用统计
    await _incrementUsageCount(template.id);

    return event;
  }

  /// 计算年龄
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  /// 增加使用次数
  Future<void> _incrementUsageCount(String templateId) async {
    if (templateId.startsWith('builtin_')) return; // 内置模板不统计
    
    try {
      final template = await getTemplateById(templateId);
      if (template != null && !template.isBuiltIn) {
        final updated = template.copyWith(
          usageCount: template.usageCount + 1,
        );
        await _dbService.updateTemplate(updated.toMap());
      }
    } catch (e) {
      debugPrint('更新模板使用次数失败: $e');
    }
  }

  /// 获取分类图标
  String _getCategoryIcon(String categoryId) {
    const icons = {
      'birthday': '🎂',
      'anniversary': '💑',
      'exam': '📚',
      'holiday': '🎉',
      'work': '💼',
      'travel': '✈️',
      'custom': '📌',
    };
    return icons[categoryId] ?? '📌';
  }

  /// 导出模板为 JSON
  Future<String> exportTemplate(String templateId) async {
    final template = await getTemplateById(templateId);
    if (template == null) {
      throw StateError('模板不存在');
    }

    return const JsonEncoder.withIndent('  ').convert(template.toJson());
  }

  /// 导出所有自定义模板
  Future<String> exportAllCustomTemplates() async {
    final templates = await _getCustomTemplates();
    final json = templates.map((t) => t.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'templates': json,
    });
  }

  /// 从 JSON 导入模板
  Future<EventTemplate> importTemplate(String jsonString) async {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final template = EventTemplate.fromJson(json);
      
      // 生成新ID，避免冲突
      final imported = template.copyWith(
        id: 'imported_${_uuid.v4()}',
        isBuiltIn: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (!imported.validate()) {
        throw ArgumentError('导入的模板数据无效');
      }

      await _dbService.insertTemplate(imported.toMap());
      _cachedTemplates = null;

      return imported;
    } catch (e) {
      throw FormatException('导入模板失败: $e');
    }
  }

  /// 批量导入模板
  Future<int> importTemplatesFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final templates = data['templates'] as List;
      
      int count = 0;
      for (final item in templates) {
        try {
          await importTemplate(jsonEncode(item));
          count++;
        } catch (e) {
          debugPrint('导入模板失败: $e');
        }
      }
      
      return count;
    } catch (e) {
      throw FormatException('批量导入失败: $e');
    }
  }

  /// 清除缓存
  void clearCache() {
    _cachedTemplates = null;
  }
}
