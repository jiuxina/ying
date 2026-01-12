import 'package:flutter/material.dart';

/// ============================================================================
/// 自定义页面转场动画
/// ============================================================================

/// 从底部滑入转场
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SlideUpRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 350),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.15);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

/// 淡入缩放转场
class FadeScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  FadeScaleRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeOutCubic;

            var scaleTween = Tween<double>(begin: 0.92, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            return ScaleTransition(
              scale: animation.drive(scaleTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

/// 共享轴转场（水平）
class SharedAxisRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final bool forward;

  SharedAxisRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.forward = true,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeOutCubic;

            // 进入页面从右侧滑入，退出页面向左滑出
            var slideIn = Tween<Offset>(
              begin: Offset(forward ? 0.2 : -0.2, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: curve));

            var fadeIn = Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(slideIn),
              child: FadeTransition(
                opacity: animation.drive(fadeIn),
                child: child,
              ),
            );
          },
        );
}

/// 展开转场 - 从指定点展开
class ExpandRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Offset? origin;
  final Duration duration;

  ExpandRoute({
    required this.page,
    this.origin,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeOutCubic;

            var scaleTween = Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: Curves.easeOut),
            );

            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: ScaleTransition(
                scale: animation.drive(scaleTween),
                alignment: Alignment.center,
                child: child,
              ),
            );
          },
        );
}

/// Hero 增强包装器 - 添加材质渐变效果
class HeroCard extends StatelessWidget {
  final String tag;
  final Widget child;
  final ShapeBorder? shape;

  const HeroCard({
    super.key,
    required this.tag,
    required this.child,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return Material(
          color: Colors.transparent,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}
