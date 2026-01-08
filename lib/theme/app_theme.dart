import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

/// ============================================================================
/// 应用主题配置
/// ============================================================================

class AppTheme {
  static ThemeData lightTheme(Color primaryColor, {
    String? fontFamily,
    double fontSizePx = 16.0,
  }) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: AppConstants.accentColor,
        surface: AppConstants.lightSurface,
        error: AppConstants.errorColor,
      ),
      scaffoldBackgroundColor: AppConstants.lightBackground,
      fontFamily: _isGoogleFont(fontFamily) ? null : fontFamily,
    );

    // 获取基础 TextTheme (处理 Google Fonts)
    TextTheme textTheme = baseTheme.textTheme;
    if (_isGoogleFont(fontFamily)) {
      try {
        textTheme = _applyGoogleFont(fontFamily!, textTheme);
      } catch (_) {
        // Fallback
      }
    }

    // 应用字体大小缩放
    final scaledTextTheme = textTheme.apply(
      fontSizeFactor: fontSizePx / 16.0,
      fontFamily: _isGoogleFont(fontFamily) ? null : fontFamily,
    );

    return baseTheme.copyWith(
      textTheme: scaledTextTheme,
      // AppBar 主题
      
      // AppBar 主题
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppConstants.lightText,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      
      // 卡片主题
      cardTheme: CardThemeData(
        color: AppConstants.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      
      // 浮动按钮主题
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        filled: true,
        fillColor: AppConstants.lightBackground,
      ),
      
      // 分割线主题
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),
    );
  }

  /// 构建深色主题
  static ThemeData darkTheme(Color primaryColor, {
    String? fontFamily,
    double fontSizePx = 16.0,
  }) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: AppConstants.accentColor,
        surface: AppConstants.darkSurface,
        error: AppConstants.errorColor,
      ),
      scaffoldBackgroundColor: AppConstants.darkBackground,
      fontFamily: _isGoogleFont(fontFamily) ? null : fontFamily,
    );

    // 获取基础 TextTheme (处理 Google Fonts)
    TextTheme textTheme = baseTheme.textTheme;
    if (_isGoogleFont(fontFamily)) {
      try {
        textTheme = _applyGoogleFont(fontFamily!, textTheme);
      } catch (_) {
        // Fallback
      }
    }

    // 应用字体大小缩放
    final scaledTextTheme = textTheme.apply(
      fontSizeFactor: fontSizePx / 16.0,
      fontFamily: _isGoogleFont(fontFamily) ? null : fontFamily,
      bodyColor: AppConstants.darkText,
      displayColor: AppConstants.darkText,
    );

    return baseTheme.copyWith(
      textTheme: scaledTextTheme,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppConstants.darkText,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: AppConstants.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: BorderSide(color: Colors.grey.shade800),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        filled: true,
        fillColor: AppConstants.darkBackground,
      ),
      
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade800,
        thickness: 1,
      ),
    );
  }

  static bool _isGoogleFont(String? fontFamily) {
    if (fontFamily == null) return false;
    // 内置支持的 Google Fonts 列表
    const googleFonts = [
      'Roboto', 
      'NotoSansSC', 
      'NotoSerifSC', 
      'LXGWWenKai', 
      'MadimiOne', 
      'MaShanZheng', 
      'ZhiMangXing', 
      'LongCang'
    ];
    return googleFonts.contains(fontFamily);
  }

  static TextTheme _applyGoogleFont(String fontFamily, TextTheme baseTheme) {
    TextStyle getStyle(TextStyle? original) {
      return GoogleFonts.getFont(fontFamily, textStyle: original);
    }

    return baseTheme.copyWith(
      displayLarge: getStyle(baseTheme.displayLarge),
      displayMedium: getStyle(baseTheme.displayMedium),
      displaySmall: getStyle(baseTheme.displaySmall),
      headlineLarge: getStyle(baseTheme.headlineLarge),
      headlineMedium: getStyle(baseTheme.headlineMedium),
      headlineSmall: getStyle(baseTheme.headlineSmall),
      titleLarge: getStyle(baseTheme.titleLarge),
      titleMedium: getStyle(baseTheme.titleMedium),
      titleSmall: getStyle(baseTheme.titleSmall),
      bodyLarge: getStyle(baseTheme.bodyLarge),
      bodyMedium: getStyle(baseTheme.bodyMedium),
      bodySmall: getStyle(baseTheme.bodySmall),
      labelLarge: getStyle(baseTheme.labelLarge),
      labelMedium: getStyle(baseTheme.labelMedium),
      labelSmall: getStyle(baseTheme.labelSmall),
    );
  }
}

/// ============================================================================
/// 颜色工具类
/// ============================================================================

class AppColors {
  /// 获取渐变背景色
  static List<Color> getGradientColors(bool isDark) {
    if (isDark) {
      return const [
        AppConstants.darkGradientStart,
        AppConstants.darkGradientMiddle,
        AppConstants.darkGradientEnd,
      ];
    }
    return const [
      AppConstants.lightGradientStart,
      AppConstants.lightGradientMiddle,
      AppConstants.lightGradientEnd,
    ];
  }

  /// 获取分类颜色
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'birthday':
        return const Color(0xFFEC4899); // 粉色
      case 'anniversary':
        return const Color(0xFFEF4444); // 红色
      case 'holiday':
        return const Color(0xFFF59E0B); // 琥珀
      case 'exam':
        return const Color(0xFF3B82F6); // 蓝色
      case 'work':
        return const Color(0xFF6366F1); // 靛蓝
      case 'travel':
        return const Color(0xFF10B981); // 翠绿
      default:
        return const Color(0xFF8B5CF6); // 紫罗兰
    }
  }
}
