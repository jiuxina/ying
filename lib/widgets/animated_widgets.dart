import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ============================================================================
/// 可点击动画组件
/// 提供统一的触觉反馈和视觉动画
/// ============================================================================

class AnimatedTapWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final Duration duration;
  final bool enableHaptic;

  const AnimatedTapWidget({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.enableHaptic = true,
  });

  @override
  State<AnimatedTapWidget> createState() => _AnimatedTapWidgetState();
}

class _AnimatedTapWidgetState extends State<AnimatedTapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
    if (widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  void _handleTap() {
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  void _handleLongPress() {
    if (widget.enableHaptic) {
      HapticFeedback.mediumImpact();
    }
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap != null ? _handleTap : null,
      onLongPress: widget.onLongPress != null ? _handleLongPress : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// ============================================================================
/// 可滑动反馈组件
/// ============================================================================

class AnimatedSlideWidget extends StatefulWidget {
  final Widget child;
  final Function(DragUpdateDetails)? onHorizontalDragUpdate;
  final Function(DragEndDetails)? onHorizontalDragEnd;
  final bool enableHaptic;

  const AnimatedSlideWidget({
    super.key,
    required this.child,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.enableHaptic = true,
  });

  @override
  State<AnimatedSlideWidget> createState() => _AnimatedSlideWidgetState();
}

class _AnimatedSlideWidgetState extends State<AnimatedSlideWidget> {
  double _offset = 0.0;
  bool _hasTriggeredHaptic = false;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta.dx;
      // 达到一定偏移量时触发反馈
      if (!_hasTriggeredHaptic && _offset.abs() > 50) {
        if (widget.enableHaptic) {
          HapticFeedback.selectionClick();
        }
        _hasTriggeredHaptic = true;
      }
    });
    widget.onHorizontalDragUpdate?.call(details);
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _offset = 0.0;
      _hasTriggeredHaptic = false;
    });
    widget.onHorizontalDragEnd?.call(details);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(_offset * 0.3, 0, 0),
        child: widget.child,
      ),
    );
  }
}

/// ============================================================================
/// 涟漪按钮
/// ============================================================================

class RippleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final Color? splashColor;

  const RippleButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.splashColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        splashColor: splashColor ?? Theme.of(context).colorScheme.primary.withAlpha(30),
        highlightColor: splashColor?.withAlpha(20) ?? Theme.of(context).colorScheme.primary.withAlpha(15),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        onLongPress: onLongPress != null ? () {
          HapticFeedback.mediumImpact();
          onLongPress?.call();
        } : null,
        child: child,
      ),
    );
  }
}
