import 'package:flutter/material.dart';

/// ============================================================================
/// 响应式布局工具类
/// ============================================================================

class ResponsiveUtils {
  /// 获取屏幕宽度
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// 获取屏幕高度
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// 判断是否为小屏设备 (宽度 < 360dp)
  static bool isSmallScreen(BuildContext context) {
    return screenWidth(context) < 360;
  }

  /// 判断是否为中等屏幕 (360dp <= 宽度 < 600dp)
  static bool isMediumScreen(BuildContext context) {
    final width = screenWidth(context);
    return width >= 360 && width < 600;
  }

  /// 判断是否为大屏设备 (宽度 >= 600dp)
  static bool isLargeScreen(BuildContext context) {
    return screenWidth(context) >= 600;
  }

  /// 判断是否为平板 (宽度 >= 768dp)
  static bool isTablet(BuildContext context) {
    return screenWidth(context) >= 768;
  }

  /// 获取响应式宽度值 (百分比)
  /// [percentage] 占屏幕宽度的百分比 (0.0 - 1.0)
  static double width(BuildContext context, double percentage) {
    return screenWidth(context) * percentage;
  }

  /// 获取响应式高度值 (百分比)
  /// [percentage] 占屏幕高度的百分比 (0.0 - 1.0)
  static double height(BuildContext context, double percentage) {
    return screenHeight(context) * percentage;
  }

  /// 根据屏幕宽度缩放字体大小
  /// [baseFontSize] 基准字体大小 (设计稿尺寸, 通常以 375dp 为基准)
  static double scaledFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 以 375 为基准宽度进行缩放
    final scale = screenWidth / 375.0;
    // 限制缩放范围在 0.85 - 1.3 之间，避免过大或过小
    final clampedScale = scale.clamp(0.85, 1.3);
    return baseFontSize * clampedScale;
  }

  /// 根据屏幕尺寸缩放间距
  /// [baseSpacing] 基准间距值
  static double scaledSpacing(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 375.0;
    final clampedScale = scale.clamp(0.9, 1.2);
    return baseSpacing * clampedScale;
  }

  /// 根据屏幕尺寸缩放尺寸
  /// [baseSize] 基准尺寸值
  static double scaledSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 375.0;
    final clampedScale = scale.clamp(0.85, 1.3);
    return baseSize * clampedScale;
  }

  /// 根据文本缩放因子调整字体大小
  /// [fontSize] 原始字体大小
  static double textScaleFontSize(BuildContext context, double fontSize) {
    final textScaleFactor = MediaQuery.of(context).textScaler.scale(1.0);
    // 限制文本缩放因子在合理范围内
    final clampedFactor = textScaleFactor.clamp(0.8, 1.5);
    return fontSize * clampedFactor;
  }
}

/// ============================================================================
/// 响应式间距常量
/// ============================================================================

class ResponsiveSpacing {
  /// 超小间距 (4dp)
  static double xs(BuildContext context) => ResponsiveUtils.scaledSpacing(context, 4.0);

  /// 小间距 (8dp)
  static double sm(BuildContext context) => ResponsiveUtils.scaledSpacing(context, 8.0);

  /// 中等间距 (12dp)
  static double md(BuildContext context) => ResponsiveUtils.scaledSpacing(context, 12.0);

  /// 标准间距 (16dp)
  static double base(BuildContext context) => ResponsiveUtils.scaledSpacing(context, 16.0);

  /// 大间距 (20dp)
  static double lg(BuildContext context) => ResponsiveUtils.scaledSpacing(context, 20.0);

  /// 超大间距 (24dp)
  static double xl(BuildContext context) => ResponsiveUtils.scaledSpacing(context, 24.0);

  /// 巨大间距 (32dp)
  static double xxl(BuildContext context) => ResponsiveUtils.scaledSpacing(context, 32.0);

  /// 超巨大间距 (40dp)
  static double xxxl(BuildContext context) => ResponsiveUtils.scaledSpacing(context, 40.0);
}

/// ============================================================================
/// 响应式字体大小常量
/// ============================================================================

class ResponsiveFontSize {
  /// 超小字体 (10px)
  static double xs(BuildContext context) => ResponsiveUtils.scaledFontSize(context, 10.0);

  /// 小字体 (12px)
  static double sm(BuildContext context) => ResponsiveUtils.scaledFontSize(context, 12.0);

  /// 中小字体 (13px)
  static double md(BuildContext context) => ResponsiveUtils.scaledFontSize(context, 13.0);

  /// 标准字体 (14px)
  static double base(BuildContext context) => ResponsiveUtils.scaledFontSize(context, 14.0);

  /// 中大字体 (16px)
  static double lg(BuildContext context) => ResponsiveUtils.scaledFontSize(context, 16.0);

  /// 大字体 (18px)
  static double xl(BuildContext context) => ResponsiveUtils.scaledFontSize(context, 18.0);

  /// 超大字体 (20px)
  static double xxl(BuildContext context) => ResponsiveUtils.scaledFontSize(context, 20.0);

  /// 标题字体 (24px)
  static double title(BuildContext context) => ResponsiveUtils.scaledFontSize(context, 24.0);

  /// 大标题字体 (28px)
  static double heading(BuildContext context) => ResponsiveUtils.scaledFontSize(context, 28.0);

  /// 超大标题字体 (32px)
  static double display(BuildContext context) => ResponsiveUtils.scaledFontSize(context, 32.0);

  /// 巨大标题字体 (36px)
  static double hero(BuildContext context) => ResponsiveUtils.scaledFontSize(context, 36.0);
}

/// ============================================================================
/// 响应式圆角大小常量
/// ============================================================================

class ResponsiveBorderRadius {
  /// 超小圆角 (4dp)
  static double xs(BuildContext context) => ResponsiveUtils.scaledSize(context, 4.0);

  /// 小圆角 (8dp)
  static double sm(BuildContext context) => ResponsiveUtils.scaledSize(context, 8.0);

  /// 中等圆角 (12dp)
  static double md(BuildContext context) => ResponsiveUtils.scaledSize(context, 12.0);

  /// 标准圆角 (16dp)
  static double base(BuildContext context) => ResponsiveUtils.scaledSize(context, 16.0);

  /// 大圆角 (20dp)
  static double lg(BuildContext context) => ResponsiveUtils.scaledSize(context, 20.0);

  /// 超大圆角 (24dp)
  static double xl(BuildContext context) => ResponsiveUtils.scaledSize(context, 24.0);

  /// 圆形
  static double circular(BuildContext context) => 9999.0;
}

/// ============================================================================
/// 响应式图标大小常量
/// ============================================================================

class ResponsiveIconSize {
  /// 超小图标 (12px)
  static double xs(BuildContext context) => ResponsiveUtils.scaledSize(context, 12.0);

  /// 小图标 (16px)
  static double sm(BuildContext context) => ResponsiveUtils.scaledSize(context, 16.0);

  /// 中等图标 (20px)
  static double md(BuildContext context) => ResponsiveUtils.scaledSize(context, 20.0);

  /// 标准图标 (24px)
  static double base(BuildContext context) => ResponsiveUtils.scaledSize(context, 24.0);

  /// 大图标 (28px)
  static double lg(BuildContext context) => ResponsiveUtils.scaledSize(context, 28.0);

  /// 超大图标 (32px)
  static double xl(BuildContext context) => ResponsiveUtils.scaledSize(context, 32.0);

  /// 巨大图标 (40px)
  static double xxl(BuildContext context) => ResponsiveUtils.scaledSize(context, 40.0);
}

/// ============================================================================
/// 响应式辅助组件
/// ============================================================================

/// 响应式垂直间距
class ResponsiveVerticalSpacing extends StatelessWidget {
  final double baseHeight;

  const ResponsiveVerticalSpacing(this.baseHeight, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: ResponsiveUtils.scaledSpacing(context, baseHeight));
  }
}

/// 响应式水平间距
class ResponsiveHorizontalSpacing extends StatelessWidget {
  final double baseWidth;

  const ResponsiveHorizontalSpacing(this.baseWidth, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: ResponsiveUtils.scaledSpacing(context, baseWidth));
  }
}

/// 响应式文本组件（带自动缩放和溢出保护）
class ResponsiveText extends StatelessWidget {
  final String text;
  final double baseFontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;

  const ResponsiveText(
    this.text, {
    super.key,
    this.baseFontSize = 14.0,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.softWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: ResponsiveUtils.scaledFontSize(context, baseFontSize),
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
