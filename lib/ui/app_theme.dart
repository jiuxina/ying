import 'package:flutter/material.dart';

import 'glass_ui.dart';

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: GlassPalette.blue,
      brightness: brightness,
      primary: GlassPalette.blue,
      surface: dark ? const Color(0xFF101114) : const Color(0xFFF7F7F8),
      error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFB42318),
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: 'SF Pro Display',
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
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          height: 1.18,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
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
        fillColor: scheme.surfaceContainerHighest.withValues(
          alpha: dark ? 0.30 : 0.52,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.60),
          ),
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
        backgroundColor: Colors.transparent,
        selectedColor: scheme.primary.withValues(alpha: 0.10),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        secondaryLabelStyle: TextStyle(
          color: scheme.primary,
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
        color: dark ? const Color(0xFF202227) : Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? const Color(0xFF1B1D22) : Colors.white,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
