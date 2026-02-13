import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/countdown_event.dart';
import '../utils/responsive_utils.dart';

/// 庆祝动效覆盖层
/// 在事件到期日显示庆祝效果
class CelebrationOverlay extends StatefulWidget {
  final CountdownEvent event;
  final VoidCallback? onShare;
  final VoidCallback? onDismiss;

  const CelebrationOverlay({
    super.key,
    required this.event,
    this.onShare,
    this.onDismiss,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // 启动动画
    _animationController.forward();
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          // 彩纸效果 - 左边
          Align(
            alignment: Alignment.topLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -math.pi / 4,
              maxBlastForce: 30,
              minBlastForce: 10,
              emissionFrequency: 0.03,
              numberOfParticles: 20,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.orange,
                Colors.yellow,
                Colors.green,
                Colors.blue,
                Colors.purple,
                Colors.pink,
              ],
            ),
          ),
          // 彩纸效果 - 右边
          Align(
            alignment: Alignment.topRight,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -3 * math.pi / 4,
              maxBlastForce: 30,
              minBlastForce: 10,
              emissionFrequency: 0.03,
              numberOfParticles: 20,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.orange,
                Colors.yellow,
                Colors.green,
                Colors.blue,
                Colors.purple,
                Colors.pink,
              ],
            ),
          ),

          // 主要内容
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.all(ResponsiveSpacing.xxl(context)),
                padding: EdgeInsets.all(ResponsiveSpacing.xxl(context)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(ResponsiveBorderRadius.xl(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: ResponsiveUtils.scaledSize(context, 30),
                      spreadRadius: ResponsiveUtils.scaledSize(context, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 庆祝图标
                    Container(
                      width: ResponsiveUtils.scaledSize(context, 80),
                      height: ResponsiveUtils.scaledSize(context, 80),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '🎉',
                          style: TextStyle(fontSize: ResponsiveIconSize.xxl(context)),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveSpacing.xl(context)),

                    // 标题
                    Text(
                      _getCelebrationTitle(),
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.heading(context),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: ResponsiveSpacing.md(context)),

                    // 事件名称
                    Text(
                      widget.event.title,
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.xxl(context),
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: ResponsiveSpacing.sm(context)),

                    // 副标题
                    Text(
                      _getSubtitle(),
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.base(context),
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: ResponsiveSpacing.xxl(context)),

                    // 行动按钮
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              widget.onDismiss?.call();
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              '稍后',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveSpacing.md(context)),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: () {
                              widget.onShare?.call();
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.share),
                            label: Text(
                              '分享喜悦',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 关闭按钮
          Positioned(
            top: ResponsiveUtils.scaledSize(context, 48),
            right: ResponsiveSpacing.base(context),
            child: IconButton(
              onPressed: () {
                widget.onDismiss?.call();
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.close,
                color: Colors.white,
                size: ResponsiveIconSize.lg(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCelebrationTitle() {
    if (widget.event.isCountUp) {
      final days = widget.event.daysRemaining.abs();
      if (days == 0) {
        return '今天是纪念日！';
      }
      return '已经 $days 天啦！';
    } else {
      final days = widget.event.daysRemaining;
      if (days == 0) {
        return '今天就是这一天！';
      } else if (days < 0) {
        return '已经过去了！';
      }
      return '即将到来！';
    }
  }

  String _getSubtitle() {
    if (widget.event.isCountUp) {
      return '时光飞逝，感谢一路相伴';
    }
    final days = widget.event.daysRemaining;
    if (days == 0) {
      return '期待已久的日子终于到来';
    } else if (days < 0) {
      return '虽然已经过去，但值得纪念';
    }
    return '让我们一起期待这个特别的日子';
  }
}

/// 显示庆祝覆盖层
Future<void> showCelebrationOverlay(
  BuildContext context, {
  required CountdownEvent event,
  VoidCallback? onShare,
  VoidCallback? onDismiss,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (context) => CelebrationOverlay(
      event: event,
      onShare: onShare,
      onDismiss: onDismiss,
    ),
  );
}
