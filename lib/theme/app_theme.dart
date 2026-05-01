import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../utils/app_style.dart';

/// ============================================================================
/// 应用主题配置
/// ============================================================================

class AppTheme {
  /// 构建亮色主题
  static ThemeData lightTheme(
    Color primaryColor, {
    String? fontFamily,
    double fontSizePx = 16.0,
    AppButtonStyleMode buttonStyleMode = AppButtonStyleMode.softShadow,
    double cardOpacity = 1.0,
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

    // 解析 AppStyleTheme
    final appStyle = AppStyleTheme.resolve(
      brightness: Brightness.light,
      colorScheme: baseTheme.colorScheme,
      textSecondary: AppConstants.lightTextSecondary,
      buttonStyleMode: buttonStyleMode,
      cardOpacity: cardOpacity,
    );

    return baseTheme.copyWith(
      textTheme: scaledTextTheme,
      extensions: [appStyle],
      
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
        color: appStyle.cardSurface,
        elevation: buttonStyleMode == AppButtonStyleMode.softShadow ? 4 : 0,
        shadowColor: Colors.black.withValues(alpha: 0.14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: appStyle.useBorderlessButtons 
              ? BorderSide.none 
              : BorderSide(color: appStyle.outlineColor),
        ),
      ),
      
      // 填充按钮主题
      filledButtonTheme: FilledButtonThemeData(
        style: _filledButtonStyle(
          primaryColor: primaryColor,
          strongSurface: appStyle.strongSurface,
          textColor: AppConstants.lightText,
          outlineColor: appStyle.outlineColor,
          useBorderless: appStyle.useBorderlessButtons,
          cardOpacity: cardOpacity,
        ),
      ),
      
      // 描边按钮主题
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(
          strongSurface: appStyle.strongSurface,
          textColor: AppConstants.lightText,
          outlineColor: appStyle.outlineColor,
          useBorderless: appStyle.useBorderlessButtons,
        ),
      ),
      
      // 文字按钮主题
      textButtonTheme: TextButtonThemeData(
        style: _textButtonStyle(
          strongSurface: appStyle.strongSurface,
          textColor: AppConstants.lightText,
          primaryColor: primaryColor,
          useBorderless: appStyle.useBorderlessButtons,
        ),
      ),
      
      // 图标按钮主题
      iconButtonTheme: IconButtonThemeData(
        style: _iconButtonStyle(
          strongSurface: appStyle.strongSurface,
          textColor: AppConstants.lightText,
          useBorderless: appStyle.useBorderlessButtons,
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
        fillColor: appStyle.mutedSurface,
      ),
      
      // 分割线主题
      dividerTheme: DividerThemeData(
        color: appStyle.outlineColor,
        thickness: 1,
      ),
      
      // 对话框主题
      dialogTheme: DialogThemeData(
        backgroundColor: AppConstants.lightSurface.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusDialog),
        ),
      ),
      
      // 底部表单主题
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppConstants.lightSurface.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.borderRadiusDialog),
          ),
        ),
        elevation: buttonStyleMode == AppButtonStyleMode.softShadow ? 4 : 0,
      ),
      
      // SnackBar 主题
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        backgroundColor: AppConstants.lightSurface.withValues(alpha: 0.95),
      ),
    );
  }

  /// 构建深色主题
  static ThemeData darkTheme(
    Color primaryColor, {
    String? fontFamily,
    double fontSizePx = 16.0,
    AppButtonStyleMode buttonStyleMode = AppButtonStyleMode.softShadow,
    double cardOpacity = 1.0,
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

    // 解析 AppStyleTheme
    final appStyle = AppStyleTheme.resolve(
      brightness: Brightness.dark,
      colorScheme: baseTheme.colorScheme,
      textSecondary: AppConstants.darkTextSecondary,
      buttonStyleMode: buttonStyleMode,
      cardOpacity: cardOpacity,
    );

    return baseTheme.copyWith(
      textTheme: scaledTextTheme,
      extensions: [appStyle],
      
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
        color: appStyle.cardSurface,
        elevation: buttonStyleMode == AppButtonStyleMode.softShadow ? 4 : 0,
        shadowColor: Colors.black.withValues(alpha: 0.24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: appStyle.useBorderlessButtons 
              ? BorderSide.none 
              : BorderSide(color: appStyle.outlineColor),
        ),
      ),
      
      // 填充按钮主题
      filledButtonTheme: FilledButtonThemeData(
        style: _filledButtonStyle(
          primaryColor: primaryColor,
          strongSurface: appStyle.strongSurface,
          textColor: AppConstants.darkText,
          outlineColor: appStyle.outlineColor,
          useBorderless: appStyle.useBorderlessButtons,
          cardOpacity: cardOpacity,
        ),
      ),
      
      // 描边按钮主题
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(
          strongSurface: appStyle.strongSurface,
          textColor: AppConstants.darkText,
          outlineColor: appStyle.outlineColor,
          useBorderless: appStyle.useBorderlessButtons,
        ),
      ),
      
      // 文字按钮主题
      textButtonTheme: TextButtonThemeData(
        style: _textButtonStyle(
          strongSurface: appStyle.strongSurface,
          textColor: AppConstants.darkText,
          primaryColor: primaryColor,
          useBorderless: appStyle.useBorderlessButtons,
        ),
      ),
      
      // 图标按钮主题
      iconButtonTheme: IconButtonThemeData(
        style: _iconButtonStyle(
          strongSurface: appStyle.strongSurface,
          textColor: AppConstants.darkText,
          useBorderless: appStyle.useBorderlessButtons,
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
        fillColor: appStyle.mutedSurface,
      ),
      
      dividerTheme: DividerThemeData(
        color: appStyle.outlineColor,
        thickness: 1,
      ),
      
      // 对话框主题
      dialogTheme: DialogThemeData(
        backgroundColor: AppConstants.darkSurface.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusDialog),
        ),
      ),
      
      // 底部表单主题
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppConstants.darkSurface.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.borderRadiusDialog),
          ),
        ),
        elevation: buttonStyleMode == AppButtonStyleMode.softShadow ? 4 : 0,
      ),
      
      // SnackBar 主题
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        backgroundColor: AppConstants.darkSurface.withValues(alpha: 0.95),
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
  
  // ==================== 按钮样式辅助方法 ====================
  
  /// 填充按钮样式
  static ButtonStyle _filledButtonStyle({
    required Color primaryColor,
    required Color strongSurface,
    required Color textColor,
    required Color outlineColor,
    required bool useBorderless,
    required double cardOpacity,
  }) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return strongSurface.withValues(alpha: 0.45);
        }
        return strongSurface;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return textColor.withValues(alpha: 0.55);
        }
        return textColor;
      }),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (useBorderless) {
          return states.contains(WidgetState.pressed) ? 2 : 4;
        }
        return 0;
      }),
      shadowColor: WidgetStateProperty.all(
        useBorderless ? Colors.black.withValues(alpha: 0.18) : Colors.transparent,
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: useBorderless 
              ? BorderSide.none 
              : BorderSide(color: primaryColor),
        ),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    );
  }
  
  /// 描边按钮样式
  static ButtonStyle _outlinedButtonStyle({
    required Color strongSurface,
    required Color textColor,
    required Color outlineColor,
    required bool useBorderless,
  }) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (useBorderless) {
          if (states.contains(WidgetState.disabled)) {
            return strongSurface.withValues(alpha: 0.45);
          }
          return strongSurface;
        }
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return textColor.withValues(alpha: 0.55);
        }
        return textColor;
      }),
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: useBorderless 
              ? BorderSide.none 
              : BorderSide(color: outlineColor),
        ),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    );
  }
  
  /// 文字按钮样式
  static ButtonStyle _textButtonStyle({
    required Color strongSurface,
    required Color textColor,
    required Color primaryColor,
    required bool useBorderless,
  }) {
    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return (useBorderless ? textColor : primaryColor).withValues(alpha: 0.55);
        }
        return useBorderless ? textColor : primaryColor;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (!useBorderless) return Colors.transparent;
        if (states.contains(WidgetState.disabled)) {
          return strongSurface.withValues(alpha: 0.45);
        }
        if (states.contains(WidgetState.pressed)) {
          return strongSurface.withValues(alpha: 0.95);
        }
        return strongSurface;
      }),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusTextButton),
        ),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
  
  /// 图标按钮样式
  static ButtonStyle _iconButtonStyle({
    required Color strongSurface,
    required Color textColor,
    required bool useBorderless,
  }) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (!useBorderless) return Colors.transparent;
        if (states.contains(WidgetState.disabled)) {
          return strongSurface.withValues(alpha: 0.45);
        }
        return strongSurface;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return textColor.withValues(alpha: 0.55);
        }
        return textColor;
      }),
      elevation: WidgetStateProperty.all(useBorderless ? 2 : 0),
      shadowColor: WidgetStateProperty.all(
        useBorderless ? Colors.black.withValues(alpha: 0.10) : Colors.transparent,
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusIconButton),
        ),
      ),
    );
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
