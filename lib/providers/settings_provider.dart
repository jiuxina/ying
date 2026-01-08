import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';
import '../models/widget_config.dart';
import '../services/widget_service.dart';

/// ============================================================================
/// 设置状态管理器
/// 
/// 负责管理应用程序的所有全局设置，包括：
/// - 主题与外观 (Theme & Appearance)
/// - 显示选项 (Display Options: Font, Date Format)
/// - 背景与特效 (Background & Particles)
/// - 进度条样式 (Progress Bar Styles)
/// - 列表排序与布局 (Sorting & Layout)
/// - 桌面小部件配置 (Desktop Widget Configuration)
/// 
/// 所有设置均持久化存储于 SharedPreferences。
/// ============================================================================

class SettingsProvider extends ChangeNotifier {
  // ==================== 主题设置 ====================
  
  /// 安全存储（用于敏感信息如密码）
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// 主题模式
  ThemeMode _themeMode = ThemeMode.system;
  
  /// 主题色索引（对应 themeColors 列表）
  int _themeColorIndex = 0;
  
  /// 夜间主题索引
  int _darkThemeIndex = 2; // 默认使用午夜深蓝
  
  /// 浅色主题索引
  int _lightThemeIndex = 0; // 默认使用经典白
  
  /// 语言设置
  Locale _locale = const Locale('zh', 'CN');

  // ==================== 显示设置 ====================
  
  /// 字体缩放比例（保留兼容）
  double _fontSize = 1.0;
  
  /// 字体大小（12-24px）
  double _fontSizePx = 16.0;
  
  /// 字体（null = 系统默认）
  String? _fontFamily;
  
  /// 自定义字体路径
  String? _customFontPath;
  
  /// 日期格式 (app wide date format setting)
  String _dateFormat = 'yyyy年MM月dd日';
  
  /// 卡片显示格式: 'days' (剩余天数) or 'detailed' (年月日)
  String _cardDisplayFormat = 'days';

  // ==================== 背景设置 ====================
  
  /// 背景图片路径
  String? _backgroundImagePath;
  
  /// 背景效果类型
  String _backgroundEffect = 'none';
  
  /// 模糊效果强度
  double _backgroundBlur = 10.0;

  // ==================== 粒子效果设置 ====================
  
  /// 粒子类型: 'none', 'sakura', 'rain', 'firefly', 'snow'
  String _particleType = 'none';
  
  /// 粒子速率 (0.1-1.0)
  double _particleSpeed = 0.5;
  
  /// 全局显示（包含编辑器区域）
  bool _particleGlobal = false;

  // ==================== 卡片设置 ====================
  
  /// 事件卡片是否展开
  bool _cardsExpanded = true;

  // ==================== 进度条设置 ====================
  
  /// 进度条样式: 'standard'(标准), 'background'(背景进度条)
  String _progressStyle = 'standard';
  
  /// 进度条颜色（背景进度条模式）
  int _progressColorValue = 0xFF808080; // 灰色
  
  /// 进度计算方式: 'created'(从创建时算), 'fixed'(固定天数)
  String _progressCalculation = 'fixed';
  
  /// 固定天数选项: 10, 15, 30, 90, 365
  int _progressFixedDays = 30;

  // ==================== 排序设置 ====================
  
  /// 排序方式
  String _sortOrder = 'daysAsc';
  
  /// 自定义排序顺序（事件ID列表）
  List<String> _customSortOrder = [];

  // ==================== 小部件设置 ====================
  
  /// 当前选中编辑的小部件类型
  WidgetType _currentWidgetType = WidgetType.standard;
  
  /// 各类型小部件配置
  final Map<WidgetType, WidgetConfig> _widgetConfigs = {
    WidgetType.standard: WidgetConfig.defaultFor(WidgetType.standard),
    WidgetType.large: WidgetConfig.defaultFor(WidgetType.large),
  };

  // ==================== 云同步设置 ====================
  
  /// WebDAV 服务器地址
  String _webdavUrl = '';
  
  /// WebDAV 用户名
  String _webdavUsername = '';
  
  /// WebDAV 密码
  String _webdavPassword = '';
  
  /// 是否启用自动同步
  bool _autoSyncEnabled = false;
  
  /// 上次同步时间
  DateTime? _lastSyncTime;

  // ==================== Getters ====================
  
  ThemeMode get themeMode => _themeMode;
  int get themeColorIndex => _themeColorIndex;
  Color get themeColor => AppConstants.themeColors[_themeColorIndex];
  double get fontSize => _fontSize;
  double get fontSizePx => _fontSizePx;
  String? get fontFamily => _fontFamily;
  String get dateFormat => _dateFormat;
  String get cardDisplayFormat => _cardDisplayFormat;
  String? get backgroundImagePath => _backgroundImagePath;
  String get backgroundEffect => _backgroundEffect;
  double get backgroundBlur => _backgroundBlur;
  String get particleType => _particleType;
  bool get particleEnabled => _particleType != 'none';
  double get particleSpeed => _particleSpeed;
  bool get particleGlobal => _particleGlobal;
  bool get cardsExpanded => _cardsExpanded;
  String get progressStyle => _progressStyle;
  Color get progressColor => Color(_progressColorValue);
  String get progressCalculation => _progressCalculation;
  int get progressFixedDays => _progressFixedDays;
  String get sortOrder => _sortOrder;
  List<String> get customSortOrder => _customSortOrder;
  
  // 主题方案 getters
  int get darkThemeIndex => _darkThemeIndex;
  int get lightThemeIndex => _lightThemeIndex;
  Locale get locale => _locale;
  
  // 云同步 getters
  String get webdavUrl => _webdavUrl;
  String get webdavUsername => _webdavUsername;
  String get webdavPassword => _webdavPassword;
  bool get autoSyncEnabled => _autoSyncEnabled;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isWebdavConfigured => _webdavUrl.isNotEmpty && _webdavUsername.isNotEmpty && _webdavPassword.isNotEmpty;
  
  // 小部件设置 getters
  WidgetType get currentWidgetType => _currentWidgetType;
  
  WidgetConfig get currentWidgetConfig => 
      _widgetConfigs[_currentWidgetType] ?? WidgetConfig.defaultFor(_currentWidgetType);
  
  WidgetConfig getWidgetConfig(WidgetType type) =>
      _widgetConfigs[type] ?? WidgetConfig.defaultFor(type);

  // 兼容旧代码的getters
  String get widgetSize => _currentWidgetType == WidgetType.large ? 'large' : 'small';
  String get widgetDisplayMode => 'single'; // 简化版不再支持多事件模式
  
  Color get widgetBackgroundColor => currentWidgetConfig.color;
  double get widgetOpacity => currentWidgetConfig.opacity;
  String? get widgetBackgroundImage => currentWidgetConfig.backgroundImage;
  bool get widgetBlur => currentWidgetConfig.style == WidgetStyle.glassmorphism;

  // ==================== 初始化 ====================

  /// 从本地存储加载设置
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // 主题设置
    final themeModeIndex = prefs.getInt('theme_mode') ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];
    _themeColorIndex = prefs.getInt('theme_color_index') ?? 0;
    
    // 主题方案设置
    _darkThemeIndex = prefs.getInt('dark_theme_index') ?? 2;
    _lightThemeIndex = prefs.getInt('light_theme_index') ?? 0;
    
    // 语言设置
    final localeCode = prefs.getString('locale') ?? 'zh';
    _locale = localeCode == 'en' ? const Locale('en', 'US') : const Locale('zh', 'CN');
    
    // 云同步设置
    _webdavUrl = prefs.getString('webdav_url') ?? '';
    _webdavUsername = prefs.getString('webdav_username') ?? '';
    _autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? false;
    final lastSyncMs = prefs.getInt('last_sync_time');
    _lastSyncTime = lastSyncMs != null ? DateTime.fromMillisecondsSinceEpoch(lastSyncMs) : null;
    
    // 从安全存储读取密码
    _webdavPassword = await _secureStorage.read(key: 'webdav_password') ?? '';
    
    // 显示设置
    _fontSize = prefs.getDouble('font_size') ?? 1.0;
    _fontSizePx = prefs.getDouble('font_size_px') ?? 16.0;
    _fontFamily = prefs.getString('font_family');
    _customFontPath = prefs.getString('custom_font_path');
    _dateFormat = prefs.getString('date_format') ?? 'yyyy年MM月dd日';
    _cardDisplayFormat = prefs.getString('card_display_format') ?? 'days';
    
    // 加载自定义字体
    if (_customFontPath != null && _fontFamily != null) {
      try {
        final file = File(_customFontPath!);
        if (await file.exists()) {
          final loader = FontLoader(_fontFamily!);
          final bytes = await file.readAsBytes();
          loader.addFont(Future.value(ByteData.view(bytes.buffer)));
          await loader.load();
        }
      } catch (e) {
        debugPrint('Error loading custom font: $e');
      }
    }
    
    // 背景设置
    _backgroundImagePath = prefs.getString('background_image_path');
    _backgroundEffect = prefs.getString('background_effect') ?? 'none';
    _backgroundBlur = prefs.getDouble('background_blur') ?? 10.0;
    
    // 粒子效果设置
    _particleType = prefs.getString('particle_type') ?? 'none';
    _particleSpeed = prefs.getDouble('particle_speed') ?? 0.5;
    _particleGlobal = prefs.getBool('particle_global') ?? false;
    
    // 卡片设置
    _cardsExpanded = prefs.getBool('cards_expanded') ?? true;
    
    // 进度条设置
    _progressStyle = prefs.getString('progress_style') ?? 'standard';
    _progressColorValue = prefs.getInt('progress_color') ?? 0xFF808080;
    _progressCalculation = prefs.getString('progress_calculation') ?? 'fixed';
    _progressFixedDays = prefs.getInt('progress_fixed_days') ?? 30;
    
    // 排序设置
    _sortOrder = prefs.getString('sort_order') ?? 'daysAsc';
    final customOrderJson = prefs.getString('custom_sort_order');
    if (customOrderJson != null) {
      try {
        _customSortOrder = List<String>.from(jsonDecode(customOrderJson));
      } catch (_) {
        _customSortOrder = [];
      }
    }
    
    // 小部件设置
    final currentTypeStr = prefs.getString('widget_current_type');
    if (currentTypeStr != null) {
      _currentWidgetType = WidgetType.values.firstWhere(
        (t) => t.name == currentTypeStr,
        orElse: () => WidgetType.standard,
      );
    }
    
    // 加载各类型配置
    for (final type in WidgetType.values) {
      final configJson = prefs.getString('widget_config_${type.name}');
      if (configJson != null) {
        try {
          final map = jsonDecode(configJson) as Map<String, dynamic>;
          _widgetConfigs[type] = WidgetConfig.fromMap(map);
        } catch (_) {
          _widgetConfigs[type] = WidgetConfig.defaultFor(type);
        }
      }
    }

    notifyListeners();
  }

  // ==================== 主题设置方法 ====================

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    notifyListeners();
  }

  Future<void> setThemeColor(int index) async {
    if (index >= 0 && index < AppConstants.themeColors.length) {
      _themeColorIndex = index;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_color_index', index);
      notifyListeners();
    }
  }

  // ==================== 显示设置方法 ====================

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', size);
    notifyListeners();
  }

  Future<void> setDateFormat(String format) async {
    _dateFormat = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('date_format', format);
    notifyListeners();
  }

  Future<void> setCardDisplayFormat(String format) async {
    _cardDisplayFormat = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('card_display_format', format);
    notifyListeners();
  }

  Future<void> setFontSizePx(double size) async {
    _fontSizePx = size.clamp(12.0, 24.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size_px', _fontSizePx);
    notifyListeners();
  }

  Future<void> setFontFamily(String? family) async {
    _fontFamily = family;
    final prefs = await SharedPreferences.getInstance();
    if (family != null) {
      await prefs.setString('font_family', family);
    } else {
      await prefs.remove('font_family');
    }
    notifyListeners();
  }

  Future<void> setCustomFont(String name, String path) async {
    _fontFamily = name;
    _customFontPath = path;
    
    // 立即加载字体
    try {
      final file = File(path);
      if (await file.exists()) {
        final loader = FontLoader(name);
        final bytes = await file.readAsBytes();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
        await loader.load();
      }
    } catch (e) {
      debugPrint('Error loading custom font: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('font_family', name);
    await prefs.setString('custom_font_path', path);
    notifyListeners();
  }

  // ==================== 背景设置方法 ====================

  Future<void> setBackgroundImage(String? path) async {
    _backgroundImagePath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString('background_image_path', path);
    } else {
      await prefs.remove('background_image_path');
    }
    notifyListeners();
  }

  Future<void> setBackgroundEffect(String effect) async {
    _backgroundEffect = effect;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background_effect', effect);
    notifyListeners();
  }

  Future<void> setBackgroundBlur(double blur) async {
    _backgroundBlur = blur;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('background_blur', blur);
    notifyListeners();
  }

  // ==================== 粒子效果设置方法 ====================

  Future<void> setParticleType(String type) async {
    _particleType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('particle_type', type);
    notifyListeners();
  }

  Future<void> setParticleSpeed(double speed) async {
    _particleSpeed = speed.clamp(0.1, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('particle_speed', _particleSpeed);
    notifyListeners();
  }

  Future<void> setParticleGlobal(bool global) async {
    _particleGlobal = global;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('particle_global', global);
    notifyListeners();
  }

  // ==================== 卡片设置方法 ====================

  Future<void> setCardsExpanded(bool expanded) async {
    _cardsExpanded = expanded;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cards_expanded', expanded);
    notifyListeners();
  }

  void toggleCardsExpanded() {
    setCardsExpanded(!_cardsExpanded);
  }

  // ==================== 进度条设置方法 ====================

  Future<void> setProgressStyle(String style) async {
    _progressStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('progress_style', style);
    notifyListeners();
  }

  Future<void> setProgressColor(Color color) async {
    _progressColorValue = color.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('progress_color', color.value);
    notifyListeners();
  }

  Future<void> setProgressCalculation(String calculation) async {
    _progressCalculation = calculation;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('progress_calculation', calculation);
    notifyListeners();
  }

  Future<void> setProgressFixedDays(int days) async {
    _progressFixedDays = days;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('progress_fixed_days', days);
    notifyListeners();
  }

  // ==================== 排序设置方法 ====================

  Future<void> setSortOrder(String order) async {
    _sortOrder = order;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sort_order', order);
    notifyListeners();
  }

  Future<void> setCustomSortOrder(List<String> order) async {
    _customSortOrder = order;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_sort_order', jsonEncode(order));
    notifyListeners();
  }

  // ==================== 小部件设置方法 ====================
  
  /// 切换当前编辑的小部件类型
  Future<void> setCurrentWidgetType(WidgetType type) async {
    _currentWidgetType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('widget_current_type', type.name);
    notifyListeners();
  }

  /// 更新指定类型的小部件配置
  Future<void> updateWidgetConfig(WidgetType type, WidgetConfig config) async {
    _widgetConfigs[type] = config;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('widget_config_${type.name}', jsonEncode(config.toMap()));
    
    // 更新原生小部件
    await WidgetService.updateWidgetConfig(config);
    
    notifyListeners();
  }

  /// 更新当前类型的配置
  Future<void> updateCurrentWidgetConfig(WidgetConfig config) async {
    await updateWidgetConfig(_currentWidgetType, config);
  }

  // 兼容旧方法
  Future<void> setWidgetSize(String size) async {
    final type = size == 'large' ? WidgetType.large : WidgetType.standard;
    await setCurrentWidgetType(type);
  }

  // setWidgetDisplayMode 已废弃 - 简化版不再支持多事件模式

  Future<void> setWidgetBackgroundColor(Color color) async {
    final config = currentWidgetConfig.copyWith(backgroundColor: color.value);
    await updateCurrentWidgetConfig(config);
  }

  Future<void> setWidgetOpacity(double opacity) async {
    final config = currentWidgetConfig.copyWith(opacity: opacity);
    await updateCurrentWidgetConfig(config);
  }

  Future<void> setWidgetBackgroundImage(String? path) async {
    final config = currentWidgetConfig.copyWith(backgroundImage: path);
    await updateCurrentWidgetConfig(config);
  }

  Future<void> setWidgetBlur(bool blur) async {
    final style = blur ? WidgetStyle.glassmorphism : WidgetStyle.standard;
    final config = currentWidgetConfig.copyWith(style: style);
    await updateCurrentWidgetConfig(config);
  }

  // ==================== 主题方案设置方法 ====================

  /// 设置夜间主题索引
  Future<void> setDarkThemeIndex(int index) async {
    _darkThemeIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dark_theme_index', index);
    notifyListeners();
  }

  /// 设置浅色主题索引
  Future<void> setLightThemeIndex(int index) async {
    _lightThemeIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('light_theme_index', index);
    notifyListeners();
  }

  // ==================== 语言设置方法 ====================

  /// 设置应用语言
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    notifyListeners();
  }

  // ==================== 背景设置增强 ====================

  /// 设置背景图片（增强版：复制到私有目录）
  Future<void> setBackgroundImageWithCopy(String? path) async {
    if (path == null) {
      // 清除背景图片
      if (_backgroundImagePath != null) {
        try {
          final oldFile = File(_backgroundImagePath!);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (_) {}
      }
      _backgroundImagePath = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('background_image_path');
      notifyListeners();
      return;
    }
    
    try {
      // 将图片复制到应用私有目录
      final appDir = await getApplicationSupportDirectory();
      final bgDir = Directory('${appDir.path}/backgrounds');
      if (!await bgDir.exists()) {
        await bgDir.create(recursive: true);
      }
      
      final sourceFile = File(path);
      final fileName = 'background_${DateTime.now().millisecondsSinceEpoch}.${path.split('.').last}';
      final destPath = '${bgDir.path}/$fileName';
      
      // 复制文件
      await sourceFile.copy(destPath);
      
      // 删除旧的背景图片文件
      if (_backgroundImagePath != null && _backgroundImagePath != destPath) {
        try {
          final oldFile = File(_backgroundImagePath!);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (_) {}
      }
      
      _backgroundImagePath = destPath;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('background_image_path', destPath);
      notifyListeners();
    } catch (e) {
      // 如果复制失败，直接使用原路径
      _backgroundImagePath = path;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('background_image_path', path);
      notifyListeners();
    }
  }

  // ==================== 云同步设置方法 ====================

  /// 设置 WebDAV 服务器地址
  Future<void> setWebdavUrl(String url) async {
    _webdavUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('webdav_url', url);
    notifyListeners();
  }

  /// 设置 WebDAV 用户名
  Future<void> setWebdavUsername(String username) async {
    _webdavUsername = username;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('webdav_username', username);
    notifyListeners();
  }

  /// 设置 WebDAV 密码（安全存储）
  Future<void> setWebdavPassword(String password) async {
    _webdavPassword = password;
    await _secureStorage.write(key: 'webdav_password', value: password);
    notifyListeners();
  }

  /// 设置自动同步开关
  Future<void> setAutoSyncEnabled(bool enabled) async {
    _autoSyncEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync_enabled', enabled);
    notifyListeners();
  }

  /// 更新上次同步时间
  Future<void> updateLastSyncTime() async {
    _lastSyncTime = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_sync_time', _lastSyncTime!.millisecondsSinceEpoch);
    notifyListeners();
  }

  /// 保存所有 WebDAV 凭据
  Future<void> saveWebdavCredentials({
    required String url,
    required String username,
    required String password,
  }) async {
    _webdavUrl = url;
    _webdavUsername = username;
    _webdavPassword = password;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('webdav_url', url);
    await prefs.setString('webdav_username', username);
    await _secureStorage.write(key: 'webdav_password', value: password);
    notifyListeners();
  }
}

