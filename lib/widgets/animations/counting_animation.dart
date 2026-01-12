import 'package:flutter/material.dart';

/// ============================================================================
/// 数字滚动动画组件
/// ============================================================================

/// 动画数字显示 - 数字变化时带有滚动效果
class AnimatedNumber extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const AnimatedNumber({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, child) {
        return Text(
          animatedValue.toInt().toString(),
          style: style,
        );
      },
    );
  }
}

/// 带前缀和后缀的动画数字
class AnimatedNumberWithLabel extends StatelessWidget {
  final int value;
  final String? prefix;
  final String? suffix;
  final TextStyle? numberStyle;
  final TextStyle? labelStyle;
  final Duration duration;
  final Curve curve;

  const AnimatedNumberWithLabel({
    super.key,
    required this.value,
    this.prefix,
    this.suffix,
    this.numberStyle,
    this.labelStyle,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (prefix != null)
          Text(prefix!, style: labelStyle),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration: duration,
          curve: curve,
          builder: (context, animatedValue, child) {
            return Text(
              animatedValue.toInt().toString(),
              style: numberStyle,
            );
          },
        ),
        if (suffix != null)
          Text(suffix!, style: labelStyle),
      ],
    );
  }
}

/// 滚动数字（每位数字独立滚动）
class RollingNumber extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final int digitCount;

  const RollingNumber({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.digitCount = 0, // 0 表示自动
  });

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber> {
  late int _previousValue;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
  }

  @override
  void didUpdateWidget(RollingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final valueStr = widget.value.toString();
    final prevStr = _previousValue.toString();
    final maxLen = widget.digitCount > 0 
        ? widget.digitCount 
        : (valueStr.length > prevStr.length ? valueStr.length : prevStr.length);

    final paddedValue = valueStr.padLeft(maxLen, '0');
    final paddedPrev = prevStr.padLeft(maxLen, '0');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxLen, (index) {
        final currentDigit = int.parse(paddedValue[index]);
        final previousDigit = int.parse(paddedPrev[index]);

        return _RollingDigit(
          value: currentDigit,
          previousValue: previousDigit,
          style: widget.style,
          duration: widget.duration,
        );
      }),
    );
  }
}

class _RollingDigit extends StatelessWidget {
  final int value;
  final int previousValue;
  final TextStyle? style;
  final Duration duration;

  const _RollingDigit({
    required this.value,
    required this.previousValue,
    this.style,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: previousValue.toDouble(), end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        final displayValue = animatedValue.round() % 10;
        return Text(
          displayValue.toString(),
          style: style,
        );
      },
    );
  }
}

/// 倒计时样式的动画数字（带冒号分隔）
class AnimatedCountdown extends StatelessWidget {
  final int days;
  final int hours;
  final int minutes;
  final int seconds;
  final TextStyle? numberStyle;
  final TextStyle? separatorStyle;
  final Duration duration;

  const AnimatedCountdown({
    super.key,
    required this.days,
    this.hours = 0,
    this.minutes = 0,
    this.seconds = 0,
    this.numberStyle,
    this.separatorStyle,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedNumber(
          value: days,
          style: numberStyle,
          duration: duration,
        ),
        Text('天', style: separatorStyle),
        if (hours > 0 || minutes > 0 || seconds > 0) ...[
          const SizedBox(width: 4),
          AnimatedNumber(
            value: hours,
            style: numberStyle?.copyWith(fontSize: (numberStyle?.fontSize ?? 14) * 0.7),
            duration: duration,
          ),
          Text(':', style: separatorStyle),
          Text(
            minutes.toString().padLeft(2, '0'),
            style: numberStyle?.copyWith(fontSize: (numberStyle?.fontSize ?? 14) * 0.7),
          ),
          Text(':', style: separatorStyle),
          Text(
            seconds.toString().padLeft(2, '0'),
            style: numberStyle?.copyWith(fontSize: (numberStyle?.fontSize ?? 14) * 0.7),
          ),
        ],
      ],
    );
  }
}
