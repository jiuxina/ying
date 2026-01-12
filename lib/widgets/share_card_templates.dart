import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/countdown_event.dart';
import '../models/share_template_model.dart';
import '../utils/constants.dart';

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
  Widget buildDaysDisplay(Color color, {double fontSize = 72, FontWeight fontWeight = FontWeight.w300}) {
    if (!options.showDays) return const SizedBox.shrink();
    
    final daysStr = '${event.daysRemaining.abs()}';
    // 大数字时缩小字体
    final adaptedFontSize = daysStr.length > 3 ? fontSize * 0.7 : (daysStr.length > 2 ? fontSize * 0.85 : fontSize);
    
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
          ),
          SizedBox(width: adaptedFontSize * 0.08),
          Text(
            '天',
            style: TextStyle(fontSize: adaptedFontSize * 0.22, color: color.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  /// 构建标题部件 - 自适应版本
  Widget buildTitle(Color color, {double fontSize = 24, double? maxWidth}) {
    if (!options.showTitle) return const SizedBox.shrink();
    
    final title = event.title;
    final adaptedFontSize = _adaptiveFontSize(title, fontSize, threshold: 8);
    
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
        ),
      ),
    );
  }

  /// 构建备注部件 - 自适应版本
  Widget buildNote(Color color, {double fontSize = 14, double? maxHeight}) {
    if (!options.showNote || event.note == null || event.note!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final note = event.note!;
    // 根据备注长度调整显示行数
    final maxLines = note.length > 100 ? 2 : (note.length > 50 ? 3 : 4);
    final adaptedFontSize = note.length > 80 ? fontSize * 0.9 : fontSize;
    
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight ?? 80),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
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
        ),
      ),
    );
  }

  /// 构建日期部件
  Widget buildDate(Color textColor, Color bgColor) {
    if (!options.showDate) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        DateFormat('yyyy.MM.dd').format(event.targetDate),
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建品牌页脚
  Widget buildBrandFooter(Color color) {
    if (!options.showFooter) return const SizedBox.shrink();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_note, size: 14, color: color.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Text(
          AppConstants.appName,
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
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
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          final maxContentWidth = constraints.maxWidth - 48; // 减去 padding
          
          if (isLandscape) {
            // 横版布局：左侧大数字，右侧信息
            return Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Center(child: buildDaysDisplay(textColor, fontSize: 80)),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (options.showTitle)
                        Flexible(child: buildTitle(textColor, fontSize: 28, maxWidth: maxContentWidth * 0.5)),
                      if (options.showNote) 
                        Flexible(child: buildNote(textColor, maxHeight: 60)),
                      const SizedBox(height: 16),
                      if (options.showDate) buildDate(accentColor, accentColor.withValues(alpha: 0.1)),
                      const SizedBox(height: 8),
                      if (options.showFooter) buildBrandFooter(textColor),
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
                  child: Center(child: buildTitle(textColor, maxWidth: maxContentWidth)),
                ),
                // 备注
                if (options.showNote) 
                  Flexible(child: buildNote(textColor, maxHeight: 60)),
                // 天数区域
                Flexible(
                  flex: 3,
                  child: Center(child: buildDaysDisplay(textColor)),
                ),
                // 底部区域
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (options.showDate) buildDate(accentColor, accentColor.withValues(alpha: 0.1)),
                    const SizedBox(height: 16),
                    if (options.showFooter) buildBrandFooter(textColor),
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
      padding: const EdgeInsets.all(32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          final maxContentWidth = constraints.maxWidth - 64;

          // 大圆圈数字部件
          Widget circleNumber = Container(
            constraints: BoxConstraints(maxWidth: isLandscape ? 120 : 160, maxHeight: isLandscape ? 120 : 160),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: FittedBox(
              child: Text(
                '${event.daysRemaining.abs()}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          );

          // 自适应标题
          final titleFontSize = _adaptiveFontSize(event.title, isLandscape ? 26 : 28, threshold: 10);

          if (isLandscape) {
            return Row(
              children: [
                if (options.showDays) 
                  Flexible(flex: 1, child: Center(child: circleNumber)),
                if (options.showDays) const SizedBox(width: 32),
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
                          ),
                        ),
                      if (options.showNote && event.note != null)
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              event.note!, 
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13), 
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (options.showDate) 
                            Text(DateFormat('yyyy.MM.dd').format(event.targetDate), style: const TextStyle(color: Colors.white70)),
                          const Spacer(),
                          if (options.showFooter) 
                            Text(AppConstants.appName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
                const Text('天', style: TextStyle(fontSize: 20, color: Colors.white70)),
                const SizedBox(height: 8),
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
                      ),
                    ),
                  ),
                if (options.showNote) 
                  Flexible(child: buildNote(Colors.white, maxHeight: 50)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (options.showDate)
                      Text(DateFormat('yyyy.MM.dd').format(event.targetDate), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    if (options.showFooter)
                      Row(children: [const Icon(Icons.event_note, size: 14, color: Colors.white70), const SizedBox(width: 4), const Text(AppConstants.appName, style: TextStyle(fontSize: 12, color: Colors.white70))]),
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
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          final titleFontSize = _adaptiveFontSize(event.title, isLandscape ? 24 : 22, threshold: 10);

          return Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1), blurRadius: 20, offset: const Offset(0, 10)),
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
                                      style: TextStyle(fontSize: 100, fontWeight: FontWeight.bold, color: accentColor, height: 1),
                                    ),
                                  ),
                                ),
                              ),
                            if (options.showDays) const SizedBox(width: 24),
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
                                      ),
                                    ),
                                  if (options.showNote) 
                                    Flexible(child: buildNote(textColor, maxHeight: 50)),
                                  const SizedBox(height: 16),
                                  if (options.showDate)
                                    Row(children: [Icon(Icons.calendar_today, size: 16, color: textColor.withValues(alpha: 0.5)), const SizedBox(width: 8), Text(DateFormat('yyyy年MM月dd日').format(event.targetDate), style: TextStyle(color: textColor.withValues(alpha: 0.6))) ]),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    event.title, 
                                    style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: textColor), 
                                    textAlign: TextAlign.center, 
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            if (options.showNote) 
                              Flexible(child: buildNote(textColor, maxHeight: 50)),
                            if (options.showDays)
                              Flexible(
                                flex: 2,
                                child: Center(
                                  child: FittedBox(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('${event.daysRemaining.abs()}', style: TextStyle(fontSize: 70, fontWeight: FontWeight.bold, color: accentColor, height: 1)),
                                        Text('天', style: TextStyle(fontSize: 18, color: textColor.withValues(alpha: 0.6))),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (options.showDate)
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.calendar_today, size: 16, color: textColor.withValues(alpha: 0.5)), const SizedBox(width: 8), Text(DateFormat('yyyy年MM月dd日').format(event.targetDate), style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.6)))]),
                          ],
                        ),
                ),
              ),
              if (options.showFooter) ...[const SizedBox(height: 16), buildBrandFooter(textColor)],
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
          Positioned(top: -20, left: -20, child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)))),
          Positioned(bottom: -30, right: -30, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)))),
          
          LayoutBuilder(builder: (context, constraints) {
             final isLandscape = constraints.maxWidth > constraints.maxHeight;
             final isVeryTight = constraints.maxHeight < 200; // 16:9 比例
             final titleFontSize = _adaptiveFontSize(event.title, isLandscape ? 24 : 26, threshold: 10);
             final daysFontSize = isVeryTight ? 36 : (isLandscape ? 50 : 42);
             final padding = isVeryTight ? 16.0 : 24.0;
             
             return Padding(
               padding: EdgeInsets.all(padding),
               child: isLandscape 
                 ? Row(
                     children: [
                       if (options.showDays)
                         Flexible(
                           child: Center(
                             child: Container(
                               padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.6),
                               decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                               child: FittedBox(
                                 fit: BoxFit.scaleDown,
                                 child: Column(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     Text('${event.daysRemaining.abs()}', style: TextStyle(fontSize: daysFontSize.toDouble(), fontWeight: FontWeight.bold, color: Colors.white)),
                                     Text('天', style: TextStyle(fontSize: isVeryTight ? 14 : 18, color: Colors.white70)),
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
                             if (!isVeryTight) const Text('🎉', style: TextStyle(fontSize: 28)),
                             if (!isVeryTight) const SizedBox(height: 8),
                             if (options.showTitle)
                               Flexible(
                                 child: Text(
                                   event.title, 
                                   style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: Colors.white), 
                                   maxLines: isVeryTight ? 1 : 2,
                                   overflow: TextOverflow.ellipsis,
                                 ),
                               ),
                             if (options.showNote && event.note != null && !isVeryTight)
                               Flexible(
                                 child: Padding(
                                   padding: const EdgeInsets.only(top: 4), 
                                   child: Text(
                                     event.note!, 
                                     style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12), 
                                     maxLines: 1,
                                     overflow: TextOverflow.ellipsis,
                                   ),
                                 ),
                               ),
                             const SizedBox(height: 8),
                             if (options.showDate)
                               Text(DateFormat('yyyy.MM.dd').format(event.targetDate), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: isVeryTight ? 11 : 13)),
                             if (options.showFooter && !isVeryTight) ...[
                               const SizedBox(height: 4),
                               buildBrandFooter(Colors.white),
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
                         width: 60, height: 60, 
                         decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)), 
                         child: const Center(child: Text('🎉', style: TextStyle(fontSize: 28))),
                       ),
                       if (options.showTitle)
                         Flexible(
                           child: Padding(
                             padding: const EdgeInsets.symmetric(horizontal: 8),
                             child: Text(
                               event.title, 
                               style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: Colors.white), 
                               textAlign: TextAlign.center, 
                               maxLines: 2,
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                         ),
                       if (options.showNote) 
                         Flexible(child: buildNote(Colors.white, maxHeight: 50)),
                       if (options.showDays)
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                           decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                           child: FittedBox(
                             fit: BoxFit.scaleDown,
                             child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Text('${event.daysRemaining.abs()}', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
                                 const Text(' 天', style: TextStyle(fontSize: 16, color: Colors.white70)),
                               ],
                             ),
                           ),
                         ),
                       Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           if (options.showDate)
                             Text(DateFormat('yyyy.MM.dd').format(event.targetDate), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                           if (options.showFooter) ...[
                             const SizedBox(height: 4),
                             buildBrandFooter(Colors.white),
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
          final isVeryTight = constraints.maxHeight < 220;
          final headerHeight = isVeryTight ? 40.0 : 80.0;
          final padding = isVeryTight ? 16.0 : 24.0;
          
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
                      final titleFontSize = _adaptiveFontSize(event.title, isLandscape ? 24 : 22, threshold: 10);
                      final circleSize = isVeryTight ? 60.0 : (isLandscape ? 80.0 : 100.0);
                      final daysFontSize = isVeryTight ? 28.0 : (isLandscape ? 40.0 : 36.0);
                      
                      return isLandscape
                        ? Row(
                            children: [
                              if (options.showDays)
                                Flexible(
                                  child: Container(
                                    width: circleSize,
                                    height: circleSize,
                                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accentColor, width: 3)),
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('${event.daysRemaining.abs()}', style: TextStyle(fontSize: daysFontSize, fontWeight: FontWeight.bold, color: accentColor, height: 1)),
                                              Text('天', style: TextStyle(fontSize: isVeryTight ? 12 : 14, color: textColor.withValues(alpha: 0.6))),
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
                                        ),
                                      ),
                                    if (options.showNote && !isVeryTight)
                                      Flexible(child: buildNote(textColor, maxHeight: 40)),
                                    const SizedBox(height: 8),
                                    if (options.showDate)
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: padding * 0.6, vertical: padding * 0.4), 
                                        decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), 
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min, 
                                          children: [
                                            Icon(Icons.calendar_today, size: isVeryTight ? 12 : 14, color: accentColor), 
                                            const SizedBox(width: 4), 
                                            Text(DateFormat('yyyy.MM.dd').format(event.targetDate), style: TextStyle(fontSize: isVeryTight ? 11 : 13, color: accentColor, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                    if (options.showFooter && !isVeryTight) ...[const SizedBox(height: 8), buildBrandFooter(textColor)],
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
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accentColor, width: 3)), 
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center, 
                                        children: [
                                          Text('${event.daysRemaining.abs()}', style: TextStyle(fontSize: daysFontSize, fontWeight: FontWeight.bold, color: accentColor, height: 1)), 
                                          Text('天', style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.6))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (options.showTitle)
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      event.title, 
                                      style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: textColor), 
                                      textAlign: TextAlign.center, 
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              if (options.showNote) 
                                Flexible(child: buildNote(textColor, maxHeight: 40)),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (options.showDate)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.5), 
                                      decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), 
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min, 
                                        children: [
                                          Icon(Icons.calendar_today, size: 14, color: accentColor), 
                                          const SizedBox(width: 6), 
                                          Text(DateFormat('yyyy.MM.dd').format(event.targetDate), style: TextStyle(fontSize: 13, color: accentColor, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                  if (options.showFooter) ...[const SizedBox(height: 8), buildBrandFooter(textColor)],
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
