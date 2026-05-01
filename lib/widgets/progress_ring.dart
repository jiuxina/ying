import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 圆形进度环组件
///
/// 支持自定义颜色、粗细、动画，显示百分比文字，支持渐变色。
/// 使用 CustomPaint 和 Canvas 进行绘制，实现流畅的动画效果。
///
/// 示例:
/// ```dart
/// ProgressRing(
///   progress: 0.75,
///   size: 120,
///   strokeWidth: 12,
///   gradientColors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
///   backgroundColor: Colors.grey.shade300,
/// )
/// ```
class ProgressRing extends StatefulWidget {
  /// 进度值 (0.0 - 1.0)
  final double progress;

  /// 环的尺寸（宽度和高度）
  final double size;

  /// 环的粗细
  final double strokeWidth;

  /// 渐变颜色列表（如果为空则使用单一颜色）
  final List<Color>? gradientColors;

  /// 单一颜色（当没有渐变时使用）
  final Color? color;

  /// 背景环颜色
  final Color? backgroundColor;

  /// 是否显示百分比文字
  final bool showPercentage;

  /// 百分比文字样式
  final TextStyle? percentageStyle;

  /// 动画时长
  final Duration animationDuration;

  /// 是否显示动画
  final bool animate;

  /// 起始角度（弧度），默认从顶部开始 (-π/2)
  final double startAngle;

  /// 顺时针方向，默认为 true
  final bool clockwise;

  /// 最小尺寸
  static const double minSize = 100.0;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 150,
    this.strokeWidth = 12,
    this.gradientColors,
    this.color,
    this.backgroundColor,
    this.showPercentage = true,
    this.percentageStyle,
    this.animationDuration = const Duration(milliseconds: 400),
    this.animate = true,
    this.startAngle = -math.pi / 2,
    this.clockwise = true,
  }) : assert(progress >= 0.0 && progress <= 1.0, 'progress must be between 0.0 and 1.0'),
       assert(size >= minSize, 'size must be at least $minSize');

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _setupAnimation();
  }

  void _setupAnimation() {
    final targetProgress = widget.progress.clamp(0.0, 1.0);
    _progressAnimation = Tween<double>(
      begin: _previousProgress,
      end: targetProgress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animate) {
      _controller.forward(from: 0.0);
    } else {
      _controller.value = 1.0;
    }

    _previousProgress = targetProgress;
  }

  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _setupAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 确定颜色
    final progressColor = widget.color ??
        widget.gradientColors?.first ??
        theme.colorScheme.primary;
    final bgColor = widget.backgroundColor ??
        (isDark ? Colors.grey.shade800 : Colors.grey.shade200);

    // 默认百分比文字样式
    final defaultPercentageStyle = widget.percentageStyle ??
        TextStyle(
          fontSize: widget.size * 0.2,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        );

    return Semantics(
      label: '进度环: ${(widget.progress * 100).toInt()}%',
      value: '${(widget.progress * 100).toInt()}%',
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: _ProgressRingPainter(
                progress: _progressAnimation.value,
                strokeWidth: widget.strokeWidth,
                gradientColors: widget.gradientColors,
                progressColor: progressColor,
                backgroundColor: bgColor,
                startAngle: widget.startAngle,
                clockwise: widget.clockwise,
              ),
              child: widget.showPercentage
                  ? Center(
                      child: Text(
                        '${(_progressAnimation.value * 100).toInt()}%',
                        style: defaultPercentageStyle,
                      ),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}

/// 进度环绘制器
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color>? gradientColors;
  final Color progressColor;
  final Color backgroundColor;
  final double startAngle;
  final bool clockwise;

  // 缓存 paints 对象以优化性能
  Paint? _backgroundPaint;
  Paint? _progressPaint;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    this.gradientColors,
    required this.progressColor,
    required this.backgroundColor,
    required this.startAngle,
    required this.clockwise,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 绘制背景环
    _drawBackgroundRing(canvas, center, radius);

    // 绘制进度环
    _drawProgressRing(canvas, center, radius);
  }

  void _drawBackgroundRing(Canvas canvas, Offset center, double radius) {
    _backgroundPaint ??= Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, _backgroundPaint!);
  }

  void _drawProgressRing(Canvas canvas, Offset center, double radius) {
    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress * (clockwise ? 1 : -1);

    if (gradientColors != null && gradientColors!.length >= 2) {
      // 使用渐变色
      _progressPaint ??= Paint()
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(center: center, radius: radius);
      _progressPaint!.shader = SweepGradient(
        startAngle: startAngle,
        colors: _getGradientColorsWithAlpha(),
        stops: _getGradientStops(),
        transform: GradientRotation(startAngle),
      ).createShader(rect);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        _progressPaint!,
      );
    } else {
      // 使用单一颜色
      _progressPaint ??= Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        _progressPaint!,
      );
    }
  }

  List<Color> _getGradientColorsWithAlpha() {
    // 为渐变添加透明度变化，使进度环更有层次感
    return gradientColors!
        .map((color) => color.withOpacity(0.7))
        .toList();
  }

  List<double> _getGradientStops() {
    final colors = gradientColors!;
    if (colors.length == 2) {
      return const [0.0, 1.0];
    } else if (colors.length == 3) {
      return const [0.0, 0.5, 1.0];
    }
    // 均匀分布
    return List.generate(colors.length, (i) => i / (colors.length - 1));
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        strokeWidth != oldDelegate.strokeWidth ||
        progressColor != oldDelegate.progressColor ||
        backgroundColor != oldDelegate.backgroundColor ||
        startAngle != oldDelegate.startAngle ||
        clockwise != oldDelegate.clockwise;
  }
}

/// 进度环包装器 - 带标题和描述
class ProgressRingWithLabel extends StatelessWidget {
  /// 进度值 (0.0 - 1.0)
  final double progress;

  /// 标题文字
  final String title;

  /// 描述文字
  final String? description;

  /// 环的尺寸
  final double size;

  /// 环的粗细
  final double strokeWidth;

  /// 渐变颜色
  final List<Color>? gradientColors;

  /// 颜色
  final Color? color;

  /// 自定义底部组件
  final Widget? trailing;

  const ProgressRingWithLabel({
    super.key,
    required this.progress,
    required this.title,
    this.description,
    this.size = 150,
    this.strokeWidth = 12,
    this.gradientColors,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressRing(
          progress: progress,
          size: size,
          strokeWidth: strokeWidth,
          gradientColors: gradientColors,
          color: color,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (trailing != null) ...[
          const SizedBox(height: 8),
          trailing!,
        ],
      ],
    );
  }
}
