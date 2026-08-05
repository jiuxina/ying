import 'package:flutter/material.dart';

import 'glass_ui.dart';

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final primary = dark ? const Color(0xFFBEF264) : const Color(0xFF0F766E);
    final background = dark ? const Color(0xFF0F1115) : const Color(0xFFFCFBF9);
    final surface = dark ? const Color(0xFF181A20) : Colors.white;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      onPrimary: dark ? const Color(0xFF0F1115) : Colors.white,
      surface: surface,
      onSurface: dark ? const Color(0xFFF4F4F5) : const Color(0xFF27272A),
      outline: dark ? const Color(0xFF3F424C) : const Color(0xFFD4D4D8),
      outlineVariant: dark ? const Color(0xFF272A33) : const Color(0xFFE4E4E7),
      error: dark ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'PingFang SC',
      fontFamilyFallback: const [
        'PingFang SC',
        'Microsoft YaHei',
        'Noto Sans CJK SC',
        'sans-serif',
      ],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: GlassPageTransitionsBuilder(),
          TargetPlatform.iOS: GlassPageTransitionsBuilder(),
          TargetPlatform.macOS: GlassPageTransitionsBuilder(),
          TargetPlatform.windows: GlassPageTransitionsBuilder(),
          TargetPlatform.linux: GlassPageTransitionsBuilder(),
          TargetPlatform.fuchsia: GlassPageTransitionsBuilder(),
        },
      ),
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.8,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          height: 1.18,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          height: 1.28,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.48),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.42),
        bodySmall: base.textTheme.bodySmall?.copyWith(height: 1.38),
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 20),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.transparent,
      ),
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.55),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.28),
          disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.62),
          elevation: 0,
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: controlShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(44, 46),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          side: BorderSide(color: scheme.outlineVariant),
          shape: controlShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          shape: controlShape,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: background,
        selectedColor: scheme.primary,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        secondaryLabelStyle: TextStyle(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.10),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark
            ? const Color(0xFF292C32)
            : const Color(0xFF292C32),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
      ),
    );
  }
}
