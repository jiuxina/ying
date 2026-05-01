import 'package:flutter/material.dart';

/// ============================================================================
/// 应用常量配置
/// ============================================================================

/// 按钮样式模式
enum AppButtonStyleMode {
  /// 经典描边风格
  classic,
  /// 简洁立体风格（无描边，带阴影）
  softShadow,
}

/// 夜间主题配色方案
class DarkThemeScheme {
  final String name;
  final Color background;
  final Color surface;
  final Color text;
  final Color textSecondary;
  
  const DarkThemeScheme({
    required this.name,
    required this.background,
    required this.surface,
    required this.text,
    required this.textSecondary,
  });
}

/// 浅色主题配色方案
class LightThemeScheme {
  final String name;
  final Color background;
  final Color surface;
  final Color text;
  final Color textSecondary;
  
  const LightThemeScheme({
    required this.name,
    required this.background,
    required this.surface,
    required this.text,
    required this.textSecondary,
  });
}

/// 字体选项
class FontOption {
  final String name;       // 显示名称
  final String fontFamily; // 字体族名称
  
  const FontOption({
    required this.name,
    required this.fontFamily,
  });
}

class AppConstants {
  // ==================== 应用信息 ====================

  /// 应用名称
  static const String appName = '萤';

  /// 应用包名/App Group ID
  static const String appGroupId = 'com.jiuxina.ying';

  /// 版本号
  static const String appVersion = '1.1.0';

  /// 应用描述
  static const String appDescription = '用心记录每一个重要时刻';

  /// 作者
  static const String author = 'jiuxina';

  /// GitHub 仓库地址
  static const String githubUrl = 'https://github.com/jiuxina/ying';

  /// 反馈邮箱
  static const String feedbackEmail = 'jiuxina@outlook.com';

  // ==================== 主题色 ====================
  
  /// 主色调（靛蓝）
  static const Color primaryColor = Color(0xFF6366F1);
  
  /// 强调色（青色）
  static const Color accentColor = Color(0xFF22D3EE);
  
  /// 错误色（红色）
  static const Color errorColor = Color(0xFFEF4444);
  
  /// 成功色（绿色）
  static const Color successColor = Color(0xFF22C55E);
  
  /// 警告色（琥珀色）
  static const Color warningColor = Color(0xFFF59E0B);

  // ==================== 12种预设主题色 ====================
  
  static const List<Color> themeColors = [
    Color(0xFF6366F1),  // 靛蓝（默认）
    Color(0xFF3B82F6),  // 蓝色
    Color(0xFF10B981),  // 翠绿
    Color(0xFFF59E0B),  // 琥珀
    Color(0xFFEF4444),  // 红色
    Color(0xFF8B5CF6),  // 紫罗兰
    Color(0xFFEC4899),  // 粉色
    Color(0xFF14B8A6),  // 青色
    Color(0xFFF97316),  // 橙色
    Color(0xFF84CC16),  // 青柠
    Color(0xFF06B6D4),  // 天蓝
    Color(0xFFD946EF),  // 洋红
  ];

  // ==================== 预设界面字体颜色 ====================

  /// 8种精选界面字体颜色（适合阅读的颜色）
  static const List<Color> uiFontColors = [
    Color(0xFF1F2937), // 深灰（默认）- 近黑色，适合阅读
    Color(0xFF374151), // 灰色 - 中等深度
    Color(0xFF1E3A5F), // 深蓝 - 沉稳
    Color(0xFF1B4332), // 深绿 - 自然
    Color(0xFF4A1D1D), // 深红 - 温暖
    Color(0xFF3B2D5F), // 深紫 - 优雅
    Color(0xFF3D3D3D), // 中灰 - 中性
    Color(0xFF2D3748), // 蓝灰 - 柔和
  ];

  // ==================== 浅色主题色 ====================
  
  /// 浅色背景渐变起点
  static const Color lightGradientStart = Color(0xFFf8f9ff);
  /// 浅色背景渐变中点
  static const Color lightGradientMiddle = Color(0xFFf0f4ff);
  /// 浅色背景渐变终点
  static const Color lightGradientEnd = Color(0xFFe8eeff);
  
  /// 浅色背景
  static const Color lightBackground = Color(0xFFF8FAFC);
  /// 浅色表面
  static const Color lightSurface = Color(0xFFFFFFFF);
  /// 浅色主文字
  static const Color lightText = Color(0xFF1E293B);
  /// 浅色次要文字
  static const Color lightTextSecondary = Color(0xFF64748B);

  // ==================== 深色主题色 ====================
  
  /// 深色背景渐变起点
  static const Color darkGradientStart = Color(0xFF1a1a2e);
  /// 深色背景渐变中点
  static const Color darkGradientMiddle = Color(0xFF16213e);
  /// 深色背景渐变终点
  static const Color darkGradientEnd = Color(0xFF0f0f23);
  
  /// 深色背景
  static const Color darkBackground = Color(0xFF0F172A);
  /// 深色表面
  static const Color darkSurface = Color(0xFF1E293B);
  /// 深色主文字
  static const Color darkText = Color(0xFFF1F5F9);
  /// 深色次要文字
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // ==================== 夜间主题方案 ====================
  
  static const List<DarkThemeScheme> darkThemeSchemes = [
    // 1. 柔和暗灰 - GitHub Dimmed 风格
    DarkThemeScheme(
      name: '柔和暗灰',
      background: Color(0xFF22272E),
      surface: Color(0xFF2D333B),
      text: Color(0xFFADBAC7),
      textSecondary: Color(0xFF768390),
    ),
    // 2. 舒适暖灰 - 温和护眼
    DarkThemeScheme(
      name: '舒适暖灰',
      background: Color(0xFF1A1A1A),
      surface: Color(0xFF2D2D2D),
      text: Color(0xFFE8E6E3),
      textSecondary: Color(0xFFA8A8A8),
    ),
    // 3. 午夜深蓝 - Slate 风格 (默认)
    DarkThemeScheme(
      name: '午夜深蓝',
      background: Color(0xFF0F172A),
      surface: Color(0xFF1E293B),
      text: Color(0xFFF1F5F9),
      textSecondary: Color(0xFF94A3B8),
    ),
    // 4. 深邃极夜 - GitHub Dark 风格
    DarkThemeScheme(
      name: '深邃极夜',
      background: Color(0xFF0D1117),
      surface: Color(0xFF161B22),
      text: Color(0xFFC9D1D9),
      textSecondary: Color(0xFF8B949E),
    ),
    // 5. 经典黑 - AMOLED 省电
    DarkThemeScheme(
      name: '经典黑',
      background: Color(0xFF000000),
      surface: Color(0xFF121212),
      text: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFB3B3B3),
    ),
    // 6. 极致纯黑 - 全黑模式
    DarkThemeScheme(
      name: '极致纯黑',
      background: Color(0xFF000000),
      surface: Color(0xFF000000),
      text: Color(0xFFFFFFFF),
      textSecondary: Color(0xFF888888),
    ),
  ];

  // ==================== 浅色主题方案 ====================
  
  static const List<LightThemeScheme> lightThemeSchemes = [
    // 1. 经典白 - 默认浅色
    LightThemeScheme(
      name: '经典白',
      background: Color(0xFFF8FAFC),
      surface: Color(0xFFFFFFFF),
      text: Color(0xFF1E293B),
      textSecondary: Color(0xFF64748B),
    ),
    // 2. 暖纸色 - 护眼米白
    LightThemeScheme(
      name: '暖纸色',
      background: Color(0xFFFAF8F5),
      surface: Color(0xFFFFFDF9),
      text: Color(0xFF3D3929),
      textSecondary: Color(0xFF7A7567),
    ),
    // 3. 冷灰色 - 专业简洁
    LightThemeScheme(
      name: '冷灰色',
      background: Color(0xFFF1F3F5),
      surface: Color(0xFFFFFFFF),
      text: Color(0xFF212529),
      textSecondary: Color(0xFF6C757D),
    ),
    // 4. 天空蓝 - 清新明亮
    LightThemeScheme(
      name: '天空蓝',
      background: Color(0xFFF0F9FF),
      surface: Color(0xFFFFFFFF),
      text: Color(0xFF0C4A6E),
      textSecondary: Color(0xFF0369A1),
    ),
    // 5. 薄荷绿 - 自然清新
    LightThemeScheme(
      name: '薄荷绿',
      background: Color(0xFFF0FDF4),
      surface: Color(0xFFFFFFFF),
      text: Color(0xFF14532D),
      textSecondary: Color(0xFF166534),
    ),
  ];

  // ==================== 可用字体 ====================
  
  static const List<FontOption> availableFonts = [
    FontOption(name: '系统默认', fontFamily: 'System'),
    FontOption(name: 'Roboto', fontFamily: 'Roboto'),
    FontOption(name: '思源黑体', fontFamily: 'NotoSansSC'),
    FontOption(name: '思源宋体', fontFamily: 'NotoSerifSC'),
    FontOption(name: '霞鹜文楷', fontFamily: 'LXGWWenKai'),
  ];

  // ==================== 尺寸规范 ====================
  
  /// 小内边距
  static const double paddingSmall = 8.0;
  /// 中等内边距
  static const double paddingMedium = 16.0;
  /// 大内边距
  static const double paddingLarge = 24.0;

  // ==================== 圆角系统 ====================
  
  /// 标准圆角 - 卡片、按钮、FAB
  static const double borderRadius = 16.0;
  /// 小圆角 - 图标容器、输入框
  static const double borderRadiusSmall = 12.0;
  /// 大圆角 - 快捷操作容器
  static const double borderRadiusLarge = 20.0;
  /// 对话框圆角
  static const double borderRadiusDialog = 24.0;
  /// 文字按钮圆角
  static const double borderRadiusTextButton = 14.0;
  /// 图标按钮圆角
  static const double borderRadiusIconButton = 14.0;
  /// 小元素圆角
  static const double borderRadiusXs = 8.0;
  /// 迷你圆角
  static const double borderRadiusMini = 10.0;

  // ==================== 阴影系统 (softShadow 模式) ====================
  
  /// 卡片阴影 - 亮色模式
  static List<BoxShadow> cardShadowLight(bool softShadow) {
    if (!softShadow) return [];
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.10),
        blurRadius: 24,
        offset: const Offset(0, 10),
        spreadRadius: -14,
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.7),
        blurRadius: 12,
        offset: const Offset(0, -1),
        spreadRadius: -10,
      ),
    ];
  }
  
  /// 卡片阴影 - 暗色模式
  static List<BoxShadow> cardShadowDark(bool softShadow) {
    if (!softShadow) return [];
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.24),
        blurRadius: 20,
        offset: const Offset(0, 10),
        spreadRadius: -12,
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.02),
        blurRadius: 12,
        offset: const Offset(0, -1),
        spreadRadius: -10,
      ),
    ];
  }
  
  /// 强调阴影 - 用于重要卡片
  static List<BoxShadow> prominentShadow(Color primaryColor, bool isDark) {
    return [
      BoxShadow(
        color: primaryColor.withValues(alpha: isDark ? 0.24 : 0.18),
        blurRadius: 20,
        offset: const Offset(0, 8),
        spreadRadius: -10,
      ),
    ];
  }
  
  /// 按钮阴影
  static List<BoxShadow> buttonShadow(bool isDark) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.10),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // ==================== 边框透明度 ====================
  
  /// classic 模式边框透明度 - 亮色
  static const double borderOpacityLight = 0.16;
  /// classic 模式边框透明度 - 暗色
  static const double borderOpacityDark = 0.28;

  // ==================== 表面颜色透明度 ====================
  
  /// 卡片表面透明度 - 亮色模式 (muted)
  static double cardSurfaceOpacityLight(bool strong) {
    return strong ? 0.90 : 0.76;
  }
  
  /// 卡片表面透明度 - 暗色模式 (muted)
  static double cardSurfaceOpacityDark(bool strong) {
    return strong ? 0.94 : 0.82;
  }

  // ==================== 动画配置 ====================
  
  /// 标准动画时长
  static const Duration animationDuration = Duration(milliseconds: 300);
  /// 快速动画时长
  static const Duration animationFast = Duration(milliseconds: 150);

  // ==================== 日期格式 ====================
  
  static const List<String> dateFormats = [
    'yyyy年MM月dd日',
    'yyyy-MM-dd',
    'yyyy/MM/dd',
    'MM月dd日',
  ];
  // ==================== 更新服务 ====================

  /// GitHub Releases API
  static const String githubApiUrl = 'https://api.github.com/repos/jiuxina/ying/releases/latest';

  /// GitHub 代理地址
  static const String proxyUrl = 'https://gh-proxy.org';

  // ==================== 数据库表名 ====================

  /// 事件表名
  static const String eventsTable = 'events';

  /// 分类表名
  static const String categoriesTable = 'categories';

  /// 提醒表名
  static const String remindersTable = 'reminders';

  /// 事件分组表名
  static const String eventGroupsTable = 'event_groups';

  /// 小部件配置表名
  static const String widgetConfigsTable = 'widget_configs';

  // ==================== 时间常量 ====================

  /// 事件预览天数（30天）
  static const int eventPreviewDays = 30;

  /// 字体大小范围
  static const double minFontSize = 12.0;
  static const double maxFontSize = 24.0;
}

