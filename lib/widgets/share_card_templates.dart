import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/countdown_event.dart';
import '../models/share_template_model.dart';
import '../utils/constants.dart';
import '../utils/responsive_utils.dart';

/// 分享内容选项配置
class ShareContentOptions {
  final bool showTitle;
  final bool showDays; // 核心元素
  final bool showDate;
  final bool showNote;
  final bool showFooter;

  const ShareContentOptions({
    this.showTitle = true,
    this.showDays = true,
    this.showDate = true,
    this.showNote = false,
    this.showFooter = true,
  });
}

/// 分享卡片模板组件集合
class ShareCardTemplates {
  /// 构建分享卡片
  static Widget buildCard({
    required CountdownEvent event,
    required ShareTemplate template,
    required ShareContentOptions options,
    Color? categoryColor,
    bool hasCustomBackground = false,
  }) {
    switch (template.style) {
      case ShareTemplateStyle.minimal:
        return _MinimalTemplate(
          event: event,
          template: template,
          options: options,
          categoryColor: categoryColor,
          hasCustomBackground: hasCustomBackground,
        );
      case ShareTemplateStyle.gradient:
        return _GradientTemplate(
          event: event,
          template: template,
          options: options,
          categoryColor: categoryColor,
          hasCustomBackground: hasCustomBackground,
        );
      case ShareTemplateStyle.card:
        return _CardTemplate(
          event: event,
          template: template,
          options: options,
          categoryColor: categoryColor,
          hasCustomBackground: hasCustomBackground,
        );
      case ShareTemplateStyle.festive:
        return _FestiveTemplate(
          event: event,
          template: template,
          options: options,
          categoryColor: categoryColor,
          hasCustomBackground: hasCustomBackground,
        );
      case ShareTemplateStyle.poster:
        return _PosterTemplate(
          event: event,
          template: template,
          options: options,
          categoryColor: categoryColor,
          hasCustomBackground: hasCustomBackground,
        );
    }
  }

  /// 获取模板尺寸
  static Size getTemplateSize(ShareTemplate template) {
    const baseWidth = 360.0;
    switch (template.aspectRatio) {
      case ShareTemplateAspectRatio.square:
        return const Size(baseWidth, baseWidth);
      case ShareTemplateAspectRatio.portrait:
        return const Size(baseWidth, baseWidth / (3 / 4));
      case ShareTemplateAspectRatio.landscape:
        return const Size(baseWidth, baseWidth / (16 / 9));
    }
  }
}

/// 基础模板类，提供通用布局能力
abstract class _BaseTemplate extends StatelessWidget {
  final CountdownEvent event;
  final ShareTemplate template;
  final ShareContentOptions options;
  final Color? categoryColor;
  final bool hasCustomBackground;

  const _BaseTemplate({
    required this.event,
    required this.template,
    required this.options,
    this.categoryColor,
    this.hasCustomBackground = false,
  });

  bool get isDark => template.theme == ShareTemplateTheme.dark || hasCustomBackground;
  Color get accentColor => categoryColor ?? const Color(0xFF6B4EFF);

  /// 根据文本长度计算自适应字体大小
  double _adaptiveFontSize(String text, double baseSize, {int threshold = 10}) {
    if (text.length <= threshold) return baseSize;
    if (text.length <= threshold * 2) return baseSize * 0.85;
    if (text.length <= threshold * 3) return baseSize * 0.7;
    return baseSize * 0.6;
  }

  /// 构建天数显示部件 - 自适应版本
  Widget buildDaysDisplay(BuildContext context, Color color, {double fontSize = 72, FontWeight fontWeight = FontWeight.w300}) {
    if (!options.showDays) return const SizedBox.shrink();
    
    final daysStr = '${event.daysRemaining.abs()}';
    // 大数字时缩小字体
    final baseFontSize = ResponsiveUtils.scaledFontSize(context, fontSize);
    final adaptedFontSize = daysStr.length > 3 ? baseFontSize * 0.7 : (daysStr.length > 2 ? baseFontSize * 0.85 : baseFontSize);
    
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            event.isCountUp ? '已经' : (event.daysRemaining >= 0 ? '还有' : '已过'),
            style: TextStyle(fontSize: adaptedFontSize * 0.22, color: color.withValues(alpha: 0.6)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
          SizedBox(width: adaptedFontSize * 0.08),
          Text(
            daysStr,
            style: TextStyle(
              fontSize: adaptedFontSize,
              fontWeight: fontWeight,
              color: accentColor,
              height: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.clip,
            softWrap: false,
          ),
          SizedBox(width: adaptedFontSize * 0.08),
          Text(
            '天',
            style: TextStyle(fontSize: adaptedFontSize * 0.22, color: color.withValues(alpha: 0.6)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ],
      ),
    );
  }

  /// 构建标题部件 - 自适应版本
  Widget buildTitle(BuildContext context, Color color, {double fontSize = 24, double? maxWidth}) {
    if (!options.showTitle) return const SizedBox.shrink();
    
    final title = event.title;
    final baseFontSize = ResponsiveUtils.scaledFontSize(context, fontSize);
    final adaptedFontSize = _adaptiveFontSize(title, baseFontSize, threshold: 8);
    
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          title,
          style: TextStyle(
            fontSize: adaptedFontSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
        ),
      ),
    );
  }

  /// 构建备注部件 - 自适应版本
  Widget buildNote(BuildContext context, Color color, {double fontSize = 14, double? maxHeight}) {
    if (!options.showNote || event.note == null || event.note!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final note = event.note!;
    // 根据备注长度调整显示行数
    final maxLines = note.length > 100 ? 2 : (note.length > 50 ? 3 : 4);
    final baseFontSize = ResponsiveUtils.scaledFontSize(context, fontSize);
    final adaptedFontSize = note.length > 80 ? baseFontSize * 0.9 : baseFontSize;
    
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight ?? ResponsiveUtils.scaledSize(context, 80)),
      child: Container(
        margin: EdgeInsets.only(top: ResponsiveSpacing.sm(context)),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveSpacing.md(context), 
          vertical: ResponsiveSpacing.sm(context)
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(ResponsiveBorderRadius.sm(context)),
        ),
        child: Text(
          note,
          style: TextStyle(
            fontSize: adaptedFontSize,
            color: color.withValues(alpha: 0.8),
            fontStyle: FontStyle.italic,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
        ),
      ),
    );
  }

  /// 构建日期部件
  Widget buildDate(BuildContext context, Color textColor, Color bgColor) {
    if (!options.showDate) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSpacing.md(context), 
        vertical: ResponsiveSpacing.xs(context) + 2
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
      ),
      child: Text(
        DateFormat('yyyy.MM.dd').format(event.targetDate),
        style: TextStyle(
          fontSize: ResponsiveFontSize.sm(context),
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }

  /// 构建品牌页脚
  Widget buildBrandFooter(BuildContext context, Color color) {
    if (!options.showFooter) return const SizedBox.shrink();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_note, size: ResponsiveIconSize.sm(context), color: color.withValues(alpha: 0.5)),
        SizedBox(width: ResponsiveSpacing.xs(context) + 2),
        Text(
          AppConstants.appName,
          style: TextStyle(
            fontSize: ResponsiveFontSize.sm(context),
            color: color.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ],
    );
  }
}

/// 1. 极简模板 - 响应式重构
class _MinimalTemplate extends _BaseTemplate {
  const _MinimalTemplate({required super.event, required super.template, required super.options, super.categoryColor, super.hasCustomBackground});

  @override
  Widget build(BuildContext context) {
    final bgColor = hasCustomBackground ? Colors.transparent : (isDark ? const Color(0xFF1A1A2E) : Colors.white);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      color: bgColor,
      padding: EdgeInsets.all(ResponsiveSpacing.xl(context)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          final maxContentWidth = constraints.maxWidth - ResponsiveSpacing.xl(context) * 2; // 减去 padding
          
          if (isLandscape) {
            // 横版布局：左侧大数字，右侧信息
            return Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Center(child: buildDaysDisplay(context, textColor, fontSize: 80)),
                ),
                SizedBox(width: ResponsiveSpacing.xl(context)),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (options.showTitle)
                        Flexible(child: buildTitle(context, textColor, fontSize: 28, maxWidth: maxContentWidth * 0.5)),
                      if (options.showNote) 
                        Flexible(child: buildNote(context, textColor, maxHeight: ResponsiveUtils.scaledSize(context, 60))),
                      SizedBox(height: ResponsiveSpacing.base(context)),
                      if (options.showDate) buildDate(context, accentColor, accentColor.withValues(alpha: 0.1)),
                      SizedBox(height: ResponsiveSpacing.sm(context)),
                      if (options.showFooter) buildBrandFooter(context, textColor),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // 竖版布局
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 标题区域
                Flexible(
                  flex: 2,
                  child: Center(child: buildTitle(context, textColor, maxWidth: maxContentWidth)),
                ),
                // 备注
                if (options.showNote) 
                  Flexible(child: buildNote(context, textColor, maxHeight: ResponsiveUtils.scaledSize(context, 60))),
                // 天数区域
                Flexible(
                  flex: 3,
                  child: Center(child: buildDaysDisplay(context, textColor)),
                ),
                // 底部区域
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (options.showDate) buildDate(context, accentColor, accentColor.withValues(alpha: 0.1)),
                    SizedBox(height: ResponsiveSpacing.base(context)),
                    if (options.showFooter) buildBrandFooter(context, textColor),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

/// 2. 渐变模板 - 响应式重构
class _GradientTemplate extends _BaseTemplate {
  const _GradientTemplate({required super.event, required super.template, required super.options, super.categoryColor, super.hasCustomBackground});

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      accentColor,
      HSLColor.fromColor(accentColor).withHue((HSLColor.fromColor(accentColor).hue + 40) % 360).toColor(),
    ];

    return Container(
      decoration: hasCustomBackground ? null : BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      padding: EdgeInsets.all(ResponsiveSpacing.xxl(context)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          final maxContentWidth = constraints.maxWidth - ResponsiveSpacing.xxl(context) * 2;

          // 大圆圈数字部件
          Widget circleNumber = Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.scaledSize(context, isLandscape ? 120 : 160), 
              maxHeight: ResponsiveUtils.scaledSize(context, isLandscape ? 120 : 160)
            ),
            padding: EdgeInsets.all(ResponsiveSpacing.xl(context)),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: FittedBox(
              child: Text(
                '${event.daysRemaining.abs()}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.clip,
                softWrap: false,
              ),
            ),
          );

          // 自适应标题
          final titleFontSize = _adaptiveFontSize(
            event.title, 
            ResponsiveUtils.scaledFontSize(context, isLandscape ? 26 : 28), 
            threshold: 10
          );

          if (isLandscape) {
            return Row(
              children: [
                if (options.showDays) 
                  Flexible(flex: 1, child: Center(child: circleNumber)),
                if (options.showDays) SizedBox(width: ResponsiveSpacing.xxl(context)),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (options.showTitle) 
                        Flexible(
                          child: Text(
                            event.title, 
                            style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: Colors.white), 
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ),
                      if (options.showNote && event.note != null)
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(top: ResponsiveSpacing.sm(context)),
                            child: Text(
                              event.note!, 
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9), 
                                fontSize: ResponsiveFontSize.md(context)
                              ), 
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          ),
                        ),
                      SizedBox(height: ResponsiveSpacing.base(context)),
                      Row(
                        children: [
                          if (options.showDate) 
                            Text(
                              DateFormat('yyyy.MM.dd').format(event.targetDate), 
                              style: const TextStyle(color: Colors.white70),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          const Spacer(),
                          if (options.showFooter) 
                            Text(
                              AppConstants.appName, 
                              style: TextStyle(color: Colors.white70, fontSize: ResponsiveFontSize.sm(context)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (options.showDays) 
                  Flexible(flex: 3, child: Center(child: circleNumber)),
                Text(
                  '天', 
                  style: TextStyle(fontSize: ResponsiveFontSize.xxl(context), color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                SizedBox(height: ResponsiveSpacing.sm(context)),
                if (options.showTitle)
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: maxContentWidth * 0.05),
                      child: Text(
                        event.title, 
                        style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: Colors.white), 
                        textAlign: TextAlign.center, 
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ),
                  ),
                if (options.showNote) 
                  Flexible(child: buildNote(context, Colors.white, maxHeight: ResponsiveUtils.scaledSize(context, 50))),
                SizedBox(height: ResponsiveSpacing.sm(context)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (options.showDate)
                      Text(
                        DateFormat('yyyy.MM.dd').format(event.targetDate), 
                        style: TextStyle(fontSize: ResponsiveFontSize.sm(context), color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    if (options.showFooter)
                      Row(
                        children: [
                          Icon(Icons.event_note, size: ResponsiveIconSize.sm(context), color: Colors.white70), 
                          SizedBox(width: ResponsiveSpacing.xs(context)), 
                          Text(
                            AppConstants.appName, 
                            style: TextStyle(fontSize: ResponsiveFontSize.sm(context), color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

/// 3. 卡片模板 - 响应式重构
class _CardTemplate extends _BaseTemplate {
  const _CardTemplate({required super.event, required super.template, required super.options, super.categoryColor, super.hasCustomBackground});

  @override
  Widget build(BuildContext context) {
    final bgColor = hasCustomBackground ? Colors.transparent : (isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5));
    final cardColor = isDark ? const Color(0xFF1E1E1E).withValues(alpha: hasCustomBackground ? 0.8 : 1.0) : Colors.white.withValues(alpha: hasCustomBackground ? 0.9 : 1.0);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      color: bgColor,
      padding: EdgeInsets.all(ResponsiveSpacing.xl(context)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          final titleFontSize = _adaptiveFontSize(
            event.title, 
            ResponsiveUtils.scaledFontSize(context, isLandscape ? 24 : 22), 
            threshold: 10
          );

          return Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(ResponsiveSpacing.xl(context)),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(ResponsiveBorderRadius.xl(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1), 
                        blurRadius: ResponsiveUtils.scaledSize(context, 20), 
                        offset: Offset(0, ResponsiveUtils.scaledSize(context, 10))
                      ),
                    ],
                  ),
                  child: isLandscape
                      ? Row(
                          children: [
                            if (options.showDays)
                              Expanded(
                                flex: 4,
                                child: Center(
                                  child: FittedBox(
                                    child: Text(
                                      '${event.daysRemaining.abs()}',
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.scaledFontSize(context, 100), 
                                        fontWeight: FontWeight.bold, 
                                        color: accentColor, 
                                        height: 1
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                      softWrap: false,
                                    ),
                                  ),
                                ),
                              ),
                            if (options.showDays) SizedBox(width: ResponsiveSpacing.xl(context)),
                            Expanded(
                              flex: 5,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (options.showTitle)
                                    Flexible(
                                      child: Text(
                                        event.title, 
                                        style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: textColor), 
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true,
                                      ),
                                    ),
                                  if (options.showNote) 
                                    Flexible(child: buildNote(context, textColor, maxHeight: ResponsiveUtils.scaledSize(context, 50))),
                                  SizedBox(height: ResponsiveSpacing.base(context)),
                                  if (options.showDate)
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: ResponsiveIconSize.sm(context), color: textColor.withValues(alpha: 0.5)), 
                                        SizedBox(width: ResponsiveSpacing.sm(context)), 
                                        Flexible(
                                          child: Text(
                                            DateFormat('yyyy年MM月dd日').format(event.targetDate), 
                                            style: TextStyle(color: textColor.withValues(alpha: 0.6)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (options.showTitle)
                              Flexible(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: ResponsiveSpacing.sm(context)),
                                  child: Text(
                                    event.title, 
                                    style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: textColor), 
                                    textAlign: TextAlign.center, 
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                  ),
                                ),
                              ),
                            if (options.showNote) 
                              Flexible(child: buildNote(context, textColor, maxHeight: ResponsiveUtils.scaledSize(context, 50))),
                            if (options.showDays)
                              Flexible(
                                flex: 2,
                                child: Center(
                                  child: FittedBox(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${event.daysRemaining.abs()}', 
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.scaledFontSize(context, 70), 
                                            fontWeight: FontWeight.bold, 
                                            color: accentColor, 
                                            height: 1
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.clip,
                                          softWrap: false,
                                        ),
                                        Text(
                                          '天', 
                                          style: TextStyle(
                                            fontSize: ResponsiveFontSize.xl(context), 
                                            color: textColor.withValues(alpha: 0.6)
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (options.showDate)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center, 
                                children: [
                                  Icon(Icons.calendar_today, size: ResponsiveIconSize.sm(context), color: textColor.withValues(alpha: 0.5)), 
                                  SizedBox(width: ResponsiveSpacing.sm(context)), 
                                  Flexible(
                                    child: Text(
                                      DateFormat('yyyy年MM月dd日').format(event.targetDate), 
                                      style: TextStyle(fontSize: ResponsiveFontSize.base(context), color: textColor.withValues(alpha: 0.6)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                ),
              ),
              if (options.showFooter) ...[
                SizedBox(height: ResponsiveSpacing.base(context)), 
                buildBrandFooter(context, textColor)
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 4. 节日模板 - 响应式重构
class _FestiveTemplate extends _BaseTemplate {
  const _FestiveTemplate({required super.event, required super.template, required super.options, super.categoryColor, super.hasCustomBackground});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: hasCustomBackground ? null : BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accentColor.withValues(alpha: 0.8), accentColor],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
           // 装饰元素
          Positioned(
            top: ResponsiveUtils.scaledSize(context, -20), 
            left: ResponsiveUtils.scaledSize(context, -20), 
            child: Container(
              width: ResponsiveUtils.scaledSize(context, 80), 
              height: ResponsiveUtils.scaledSize(context, 80), 
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: Colors.white.withValues(alpha: 0.1)
              )
            )
          ),
          Positioned(
            bottom: ResponsiveUtils.scaledSize(context, -30), 
            right: ResponsiveUtils.scaledSize(context, -30), 
            child: Container(
              width: ResponsiveUtils.scaledSize(context, 120), 
              height: ResponsiveUtils.scaledSize(context, 120), 
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: Colors.white.withValues(alpha: 0.1)
              )
            )
          ),
          
          LayoutBuilder(builder: (context, constraints) {
             final isLandscape = constraints.maxWidth > constraints.maxHeight;
             final isVeryTight = constraints.maxHeight < ResponsiveUtils.scaledSize(context, 200); // 16:9 比例
             final titleFontSize = _adaptiveFontSize(
               event.title, 
               ResponsiveUtils.scaledFontSize(context, isLandscape ? 24 : 26), 
               threshold: 10
             );
             final daysFontSize = ResponsiveUtils.scaledFontSize(
               context, 
               isVeryTight ? 36 : (isLandscape ? 50 : 42)
             );
             final padding = ResponsiveSpacing.xl(context) * (isVeryTight ? 0.67 : 1.0);
             
             return Padding(
               padding: EdgeInsets.all(padding),
               child: isLandscape 
                 ? Row(
                     children: [
                       if (options.showDays)
                         Flexible(
                           child: Center(
                             child: Container(
                               padding: EdgeInsets.symmetric(
                                 horizontal: padding, 
                                 vertical: padding * 0.6
                               ),
                               decoration: BoxDecoration(
                                 color: Colors.white.withValues(alpha: 0.2), 
                                 borderRadius: BorderRadius.circular(ResponsiveBorderRadius.base(context))
                               ),
                               child: FittedBox(
                                 fit: BoxFit.scaleDown,
                                 child: Column(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     Text(
                                       '${event.daysRemaining.abs()}', 
                                       style: TextStyle(
                                         fontSize: daysFontSize, 
                                         fontWeight: FontWeight.bold, 
                                         color: Colors.white
                                       ),
                                       maxLines: 1,
                                       overflow: TextOverflow.clip,
                                       softWrap: false,
                                     ),
                                     Text(
                                       '天', 
                                       style: TextStyle(
                                         fontSize: isVeryTight ? ResponsiveFontSize.base(context) : ResponsiveFontSize.xl(context), 
                                         color: Colors.white70
                                       ),
                                       maxLines: 1,
                                       overflow: TextOverflow.ellipsis,
                                       softWrap: false,
                                     ),
                                   ],
                                 ),
                               ),
                             ),
                           ),
                         ),
                       SizedBox(width: padding),
                       Expanded(
                         flex: 2,
                         child: Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             if (!isVeryTight) 
                               Text(
                                 '🎉', 
                                 style: TextStyle(fontSize: ResponsiveFontSize.heading(context)),
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                                 softWrap: false,
                               ),
                             if (!isVeryTight) SizedBox(height: ResponsiveSpacing.sm(context)),
                             if (options.showTitle)
                               Flexible(
                                 child: Text(
                                   event.title, 
                                   style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: Colors.white), 
                                   maxLines: isVeryTight ? 1 : 2,
                                   overflow: TextOverflow.ellipsis,
                                   softWrap: true,
                                 ),
                               ),
                             if (options.showNote && event.note != null && !isVeryTight)
                               Flexible(
                                 child: Padding(
                                   padding: EdgeInsets.only(top: ResponsiveSpacing.xs(context)), 
                                   child: Text(
                                     event.note!, 
                                     style: TextStyle(
                                       color: Colors.white.withValues(alpha: 0.9), 
                                       fontSize: ResponsiveFontSize.sm(context)
                                     ), 
                                     maxLines: 1,
                                     overflow: TextOverflow.ellipsis,
                                     softWrap: true,
                                   ),
                                 ),
                               ),
                             SizedBox(height: ResponsiveSpacing.sm(context)),
                             if (options.showDate)
                               Text(
                                 DateFormat('yyyy.MM.dd').format(event.targetDate), 
                                 style: TextStyle(
                                   color: Colors.white.withValues(alpha: 0.8), 
                                   fontSize: isVeryTight ? ResponsiveFontSize.xs(context) + 1 : ResponsiveFontSize.md(context)
                                 ),
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                                 softWrap: false,
                               ),
                             if (options.showFooter && !isVeryTight) ...[
                               SizedBox(height: ResponsiveSpacing.xs(context)),
                               buildBrandFooter(context, Colors.white),
                             ],
                           ],
                         ),
                       ),
                     ],
                   )
                 : Column(
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: [
                       Container(
                         width: ResponsiveUtils.scaledSize(context, 60), 
                         height: ResponsiveUtils.scaledSize(context, 60), 
                         decoration: BoxDecoration(
                           shape: BoxShape.circle, 
                           color: Colors.white.withValues(alpha: 0.2)
                         ), 
                         child: Center(
                           child: Text(
                             '🎉', 
                             style: TextStyle(fontSize: ResponsiveFontSize.heading(context)),
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                             softWrap: false,
                           ),
                         ),
                       ),
                       if (options.showTitle)
                         Flexible(
                           child: Padding(
                             padding: EdgeInsets.symmetric(horizontal: ResponsiveSpacing.sm(context)),
                             child: Text(
                               event.title, 
                               style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: Colors.white), 
                               textAlign: TextAlign.center, 
                               maxLines: 2,
                               overflow: TextOverflow.ellipsis,
                               softWrap: true,
                             ),
                           ),
                         ),
                       if (options.showNote) 
                         Flexible(child: buildNote(context, Colors.white, maxHeight: ResponsiveUtils.scaledSize(context, 50))),
                       if (options.showDays)
                         Container(
                           padding: EdgeInsets.symmetric(
                             horizontal: ResponsiveSpacing.lg(context), 
                             vertical: ResponsiveSpacing.md(context)
                           ),
                           decoration: BoxDecoration(
                             color: Colors.white.withValues(alpha: 0.2), 
                             borderRadius: BorderRadius.circular(ResponsiveBorderRadius.base(context))
                           ),
                           child: FittedBox(
                             fit: BoxFit.scaleDown,
                             child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Text(
                                   '${event.daysRemaining.abs()}', 
                                   style: TextStyle(
                                     fontSize: ResponsiveUtils.scaledFontSize(context, 42), 
                                     fontWeight: FontWeight.bold, 
                                     color: Colors.white
                                   ),
                                   maxLines: 1,
                                   overflow: TextOverflow.clip,
                                   softWrap: false,
                                 ),
                                 Text(
                                   ' 天', 
                                   style: TextStyle(
                                     fontSize: ResponsiveFontSize.base(context), 
                                     color: Colors.white70
                                   ),
                                   maxLines: 1,
                                   overflow: TextOverflow.ellipsis,
                                   softWrap: false,
                                 ),
                               ],
                             ),
                           ),
                         ),
                       Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           if (options.showDate)
                             Text(
                               DateFormat('yyyy.MM.dd').format(event.targetDate), 
                               style: TextStyle(
                                 color: Colors.white.withValues(alpha: 0.8), 
                                 fontSize: ResponsiveFontSize.sm(context)
                               ),
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                               softWrap: false,
                             ),
                           if (options.showFooter) ...[
                             SizedBox(height: ResponsiveSpacing.xs(context)),
                             buildBrandFooter(context, Colors.white),
                           ],
                         ],
                       ),
                     ],
                   ),
             );
          }),
        ],
      ),
    );
  }
}

/// 5. 海报模板 - 响应式重构
class _PosterTemplate extends _BaseTemplate {
  const _PosterTemplate({required super.event, required super.template, required super.options, super.categoryColor, super.hasCustomBackground});

  @override
  Widget build(BuildContext context) {
    final bgColor = hasCustomBackground ? Colors.transparent : (isDark ? const Color(0xFF0D0D0D) : Colors.white);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      color: bgColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isVeryTight = constraints.maxHeight < ResponsiveUtils.scaledSize(context, 220);
          final headerHeight = ResponsiveUtils.scaledSize(context, isVeryTight ? 40.0 : 80.0);
          final padding = ResponsiveSpacing.xl(context) * (isVeryTight ? 0.67 : 1.0);
          
          return Column(
            children: [
              // 顶部渐变条
              Container(
                height: headerHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accentColor, accentColor.withValues(alpha: 0.7)]),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: LayoutBuilder(
                    builder: (context, innerConstraints) {
                      final isLandscape = innerConstraints.maxWidth > innerConstraints.maxHeight;
                      final titleFontSize = _adaptiveFontSize(
                        event.title, 
                        ResponsiveUtils.scaledFontSize(context, isLandscape ? 24 : 22), 
                        threshold: 10
                      );
                      final circleSize = ResponsiveUtils.scaledSize(
                        context, 
                        isVeryTight ? 60.0 : (isLandscape ? 80.0 : 100.0)
                      );
                      final daysFontSize = ResponsiveUtils.scaledFontSize(
                        context, 
                        isVeryTight ? 28.0 : (isLandscape ? 40.0 : 36.0)
                      );
                      
                      return isLandscape
                        ? Row(
                            children: [
                              if (options.showDays)
                                Flexible(
                                  child: Container(
                                    width: circleSize,
                                    height: circleSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle, 
                                      border: Border.all(
                                        color: accentColor, 
                                        width: ResponsiveUtils.scaledSize(context, 3)
                                      )
                                    ),
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Padding(
                                          padding: EdgeInsets.all(ResponsiveSpacing.sm(context)),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${event.daysRemaining.abs()}', 
                                                style: TextStyle(
                                                  fontSize: daysFontSize, 
                                                  fontWeight: FontWeight.bold, 
                                                  color: accentColor, 
                                                  height: 1
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.clip,
                                                softWrap: false,
                                              ),
                                              Text(
                                                '天', 
                                                style: TextStyle(
                                                  fontSize: isVeryTight ? ResponsiveFontSize.sm(context) : ResponsiveFontSize.base(context), 
                                                  color: textColor.withValues(alpha: 0.6)
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                softWrap: false,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              SizedBox(width: padding),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (options.showTitle)
                                      Flexible(
                                        child: Text(
                                          event.title, 
                                          style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: textColor), 
                                          maxLines: isVeryTight ? 1 : 2,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                        ),
                                      ),
                                    if (options.showNote && !isVeryTight)
                                      Flexible(child: buildNote(context, textColor, maxHeight: ResponsiveUtils.scaledSize(context, 40))),
                                    SizedBox(height: ResponsiveSpacing.sm(context)),
                                    if (options.showDate)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: padding * 0.6, 
                                          vertical: padding * 0.4
                                        ), 
                                        decoration: BoxDecoration(
                                          color: accentColor.withValues(alpha: 0.1), 
                                          borderRadius: BorderRadius.circular(ResponsiveBorderRadius.sm(context))
                                        ), 
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min, 
                                          children: [
                                            Icon(
                                              Icons.calendar_today, 
                                              size: isVeryTight ? ResponsiveIconSize.xs(context) : ResponsiveIconSize.sm(context), 
                                              color: accentColor
                                            ), 
                                            SizedBox(width: ResponsiveSpacing.xs(context)), 
                                            Text(
                                              DateFormat('yyyy.MM.dd').format(event.targetDate), 
                                              style: TextStyle(
                                                fontSize: isVeryTight ? ResponsiveFontSize.xs(context) + 1 : ResponsiveFontSize.md(context), 
                                                color: accentColor, 
                                                fontWeight: FontWeight.w500
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              softWrap: false,
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (options.showFooter && !isVeryTight) ...[
                                      SizedBox(height: ResponsiveSpacing.sm(context)), 
                                      buildBrandFooter(context, textColor)
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (options.showDays)
                                Container(
                                  width: circleSize, 
                                  height: circleSize, 
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle, 
                                    border: Border.all(
                                      color: accentColor, 
                                      width: ResponsiveUtils.scaledSize(context, 3)
                                    )
                                  ), 
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center, 
                                        children: [
                                          Text(
                                            '${event.daysRemaining.abs()}', 
                                            style: TextStyle(
                                              fontSize: daysFontSize, 
                                              fontWeight: FontWeight.bold, 
                                              color: accentColor, 
                                              height: 1
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.clip,
                                            softWrap: false,
                                          ), 
                                          Text(
                                            '天', 
                                            style: TextStyle(
                                              fontSize: ResponsiveFontSize.base(context), 
                                              color: textColor.withValues(alpha: 0.6)
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (options.showTitle)
                                Flexible(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: ResponsiveSpacing.sm(context)),
                                    child: Text(
                                      event.title, 
                                      style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: textColor), 
                                      textAlign: TextAlign.center, 
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                    ),
                                  ),
                                ),
                              if (options.showNote) 
                                Flexible(child: buildNote(context, textColor, maxHeight: ResponsiveUtils.scaledSize(context, 40))),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (options.showDate)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: padding, 
                                        vertical: padding * 0.5
                                      ), 
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.1), 
                                        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.xs(context) + 2)
                                      ), 
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min, 
                                        children: [
                                          Icon(Icons.calendar_today, size: ResponsiveIconSize.sm(context), color: accentColor), 
                                          SizedBox(width: ResponsiveSpacing.xs(context) + 2), 
                                          Text(
                                            DateFormat('yyyy.MM.dd').format(event.targetDate), 
                                            style: TextStyle(
                                              fontSize: ResponsiveFontSize.md(context), 
                                              color: accentColor, 
                                              fontWeight: FontWeight.w500
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (options.showFooter) ...[
                                    SizedBox(height: ResponsiveSpacing.sm(context)), 
                                    buildBrandFooter(context, textColor)
                                  ],
                                ],
                              ),
                            ],
                          );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
