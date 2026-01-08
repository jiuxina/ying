import 'dart:io';
import 'dart:ui' as ui;
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
  }) {
    switch (template.style) {
      case ShareTemplateStyle.minimal:
        return _MinimalTemplate(
          event: event,
          template: template,
          options: options,
          categoryColor: categoryColor,
        );
      case ShareTemplateStyle.gradient:
        return _GradientTemplate(
          event: event,
          template: template,
          options: options,
          categoryColor: categoryColor,
        );
      case ShareTemplateStyle.card:
        return _CardTemplate(
          event: event,
          template: template,
          options: options,
          categoryColor: categoryColor,
        );
      case ShareTemplateStyle.festive:
        return _FestiveTemplate(
          event: event,
          template: template,
          options: options,
          categoryColor: categoryColor,
        );
      case ShareTemplateStyle.poster:
        return _PosterTemplate(
          event: event,
          template: template,
          options: options,
          categoryColor: categoryColor,
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

  const _BaseTemplate({
    required this.event,
    required this.template,
    required this.options,
    this.categoryColor,
  });

  bool get isDark => template.theme == ShareTemplateTheme.dark;
  Color get accentColor => categoryColor ?? const Color(0xFF6B4EFF); // Default primary

  /// 构建天数显示部件
  Widget buildDaysDisplay(Color color, {double fontSize = 72, FontWeight fontWeight = FontWeight.w300}) {
    if (!options.showDays) return const SizedBox.shrink();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          event.isCountUp ? '已经' : (event.daysRemaining >= 0 ? '还有' : '已过'),
          style: TextStyle(fontSize: fontSize * 0.22, color: color.withOpacity(0.6)),
        ),
        SizedBox(width: fontSize * 0.1),
        Text(
          '${event.daysRemaining.abs()}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: accentColor,
            height: 1.0,
          ),
        ),
        SizedBox(width: fontSize * 0.1),
        Text(
          '天',
          style: TextStyle(fontSize: fontSize * 0.22, color: color.withOpacity(0.6)),
        ),
      ],
    );
  }

  /// 构建标题部件
  Widget buildTitle(Color color, {double fontSize = 24}) {
    if (!options.showTitle) return const SizedBox.shrink();
    
    return Text(
      event.title,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 构建备注部件
  Widget buildNote(Color color, {double fontSize = 14}) {
    if (!options.showNote || event.note == null || event.note!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          event.note!,
          style: TextStyle(
            fontSize: fontSize,
            color: color.withOpacity(0.8),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
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
      children: [
        Icon(Icons.event_note, size: 14, color: color.withOpacity(0.5)),
        const SizedBox(width: 6),
        Text(
          AppConstants.appName,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 1. 极简模板 - 响应式重构
class _MinimalTemplate extends _BaseTemplate {
  const _MinimalTemplate({required super.event, required super.template, required super.options, super.categoryColor});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          
          if (isLandscape) {
            // 横版布局：左侧大数字，右侧信息
            return Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Center(child: FittedBox(child: buildDaysDisplay(textColor, fontSize: 100))),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (options.showTitle)
                        FittedBox(fit: BoxFit.scaleDown, child: buildTitle(textColor, fontSize: 28)),
                      if (options.showNote) buildNote(textColor),
                      const Spacer(),
                      if (options.showDate) buildDate(accentColor, accentColor.withOpacity(0.1)),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                FittedBox(fit: BoxFit.scaleDown, child: buildTitle(textColor)),
                if (options.showNote) buildNote(textColor),
                const Spacer(),
                FittedBox(child: buildDaysDisplay(textColor)),
                const Spacer(flex: 2),
                if (options.showDate) buildDate(accentColor, accentColor.withOpacity(0.1)),
                const SizedBox(height: 24),
                if (options.showFooter) buildBrandFooter(textColor),
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
  const _GradientTemplate({required super.event, required super.template, required super.options, super.categoryColor});

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      accentColor,
      HSLColor.fromColor(accentColor).withHue((HSLColor.fromColor(accentColor).hue + 40) % 360).toColor(),
    ];

    return Container(
      decoration: BoxDecoration(
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

          // 大圆圈数字部件
          Widget circleNumber = Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: FittedBox(
              child: Text(
                '${event.daysRemaining.abs()}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          );

          if (isLandscape) {
            return Row(
              children: [
                if (options.showDays) Expanded(flex: 1, child: AspectRatio(aspectRatio: 1, child: circleNumber)),
                if (options.showDays) const SizedBox(width: 32),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (options.showTitle) 
                        Text(event.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2),
                      if (options.showNote)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(event.note ?? '', style: TextStyle(color: Colors.white.withOpacity(0.9)), maxLines: 2),
                        ),
                      const Spacer(),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (options.showDays) 
                  Expanded(flex: 3, child: AspectRatio(aspectRatio: 1, child: circleNumber)),
                const SizedBox(height: 24),
                const Text('天', style: TextStyle(fontSize: 24, color: Colors.white70)),
                const SizedBox(height: 16),
                if (options.showTitle)
                  Text(event.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center, maxLines: 2),
                if (options.showNote) buildNote(Colors.white),
                const Spacer(),
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
  const _CardTemplate({required super.event, required super.template, required super.options, super.categoryColor});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

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
                      BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), blurRadius: 20, offset: const Offset(0, 10)),
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
                                      style: TextStyle(fontSize: 120, fontWeight: FontWeight.bold, color: accentColor, height: 1),
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
                                    Text(event.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor), maxLines: 2),
                                  if (options.showNote) buildNote(textColor),
                                  const Spacer(),
                                  if (options.showDate)
                                    Row(children: [Icon(Icons.calendar_today, size: 16, color: textColor.withOpacity(0.5)), const SizedBox(width: 8), Text(DateFormat('yyyy年MM月dd日').format(event.targetDate), style: TextStyle(color: textColor.withOpacity(0.6))) ]),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (options.showTitle)
                              Text(event.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor), textAlign: TextAlign.center, maxLines: 2),
                           if (options.showNote) buildNote(textColor),
                            const Spacer(),
                            if (options.showDays)
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: FittedBox(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('${event.daysRemaining.abs()}', style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: accentColor, height: 1)),
                                        Text('天', style: TextStyle(fontSize: 20, color: textColor.withOpacity(0.6))),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const Spacer(),
                            if (options.showDate)
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.calendar_today, size: 16, color: textColor.withOpacity(0.5)), const SizedBox(width: 8), Text(DateFormat('yyyy年MM月dd日').format(event.targetDate), style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.6)))]),
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
  const _FestiveTemplate({required super.event, required super.template, required super.options, super.categoryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accentColor.withOpacity(0.8), accentColor],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
           // 装饰元素 (保持不变)
          Positioned(top: -20, left: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)))),
          Positioned(bottom: -30, right: -30, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)))),
          
          LayoutBuilder(builder: (context, constraints) {
             final isLandscape = constraints.maxWidth > constraints.maxHeight;
             return Padding(
               padding: const EdgeInsets.all(32),
               child: isLandscape 
                 ? Row(
                     children: [
                       if (options.showDays)
                         Expanded(
                           child: Center(
                             child: Container(
                               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                               decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                               child: Column(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   Text('${event.daysRemaining.abs()}', style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white)),
                                   const Text('天', style: TextStyle(fontSize: 18, color: Colors.white70)),
                                 ],
                               ),
                             ),
                           ),
                         ),
                       const SizedBox(width: 24),
                       Expanded(
                         child: Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             const Text('🎉', style: TextStyle(fontSize: 36)),
                             const SizedBox(height: 16),
                             if (options.showTitle)
                               Text(event.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2),
                             if (options.showNote)
                               Padding(padding: const EdgeInsets.only(top: 8), child: Text(event.note ?? '', style: TextStyle(color: Colors.white.withOpacity(0.9)), maxLines: 2)),
                             const Spacer(),
                             if (options.showDate)
                               Text(DateFormat('yyyy年MM月dd日').format(event.targetDate), style: TextStyle(color: Colors.white.withOpacity(0.8))),
                             const SizedBox(height: 8),
                             if (options.showFooter)
                               buildBrandFooter(Colors.white),
                           ],
                         ),
                       ),
                     ],
                   )
                 : Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)), child: const Center(child: Text('🎉', style: TextStyle(fontSize: 36)))),
                       const SizedBox(height: 24),
                       if (options.showTitle)
                         Text(event.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center, maxLines: 2),
                       if (options.showNote) buildNote(Colors.white),
                       const SizedBox(height: 32),
                       if (options.showDays)
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                           decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Text('${event.daysRemaining.abs()}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                               const Text(' 天', style: TextStyle(fontSize: 18, color: Colors.white70)),
                             ],
                           ),
                         ),
                       const Spacer(),
                       if (options.showDate)
                         Text(DateFormat('yyyy年MM月dd日').format(event.targetDate), style: TextStyle(color: Colors.white.withOpacity(0.8))),
                       const SizedBox(height: 8),
                       if (options.showFooter) buildBrandFooter(Colors.white),
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
  const _PosterTemplate({required super.event, required super.template, required super.options, super.categoryColor});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF0D0D0D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      color: bgColor,
      child: Column(
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [accentColor, accentColor.withOpacity(0.7)]),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isLandscape = constraints.maxWidth > constraints.maxHeight;
                  return isLandscape
                    ? Row(
                        children: [
                          if (options.showDays)
                            Expanded(
                              flex: 1,
                              child: Container(
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accentColor, width: 4)),
                                child: Center(
                                  child: FittedBox(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(children: [Text('${event.daysRemaining.abs()}', style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: accentColor)), Text('天', style: TextStyle(fontSize: 20, color: textColor.withOpacity(0.6)))]),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (options.showTitle)
                                  Text(event.title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor), maxLines: 2),
                                if (options.showNote)
                                  buildNote(textColor),
                                const Spacer(),
                                if (options.showDate)
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.calendar_today, size: 18, color: accentColor), const SizedBox(width: 8), Text(DateFormat('yyyy年MM月dd日').format(event.targetDate), style: TextStyle(fontSize: 16, color: accentColor, fontWeight: FontWeight.w500))])),
                                if (options.showFooter) ...[const SizedBox(height: 16), buildBrandFooter(textColor)],
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          if (options.showDays)
                            Container(width: 140, height: 140, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accentColor, width: 4)), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${event.daysRemaining.abs()}', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: accentColor, height: 1)), Text('天', style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.6))) ]))),
                          const SizedBox(height: 32),
                          if (options.showTitle)
                            Text(event.title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor), textAlign: TextAlign.center, maxLines: 3),
                          if (options.showNote) buildNote(textColor),
                          const Spacer(),
                          if (options.showDate)
                            Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.calendar_today, size: 18, color: accentColor), const SizedBox(width: 8), Text(DateFormat('yyyy年MM月dd日').format(event.targetDate), style: TextStyle(fontSize: 16, color: accentColor, fontWeight: FontWeight.w500))])),
                          const SizedBox(height: 24),
                          if (options.showFooter) buildBrandFooter(textColor),
                        ],
                      );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
