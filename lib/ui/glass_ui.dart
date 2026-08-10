import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 全局统一动效时长与曲线，避免各页面各自定义参数。
abstract final class AppMotion {
  static const press = Duration(milliseconds: 120);
  static const state = Duration(milliseconds: 180);
  static const switchDuration = Duration(milliseconds: 220);
  static const page = Duration(milliseconds: 260);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const crossFade = Curves.easeInOutCubic;
}

/// 轻触觉反馈类型，仅用于关键操作。
enum GlassHaptic {
  selectionClick,
  lightImpact,
  mediumImpact,
  heavyImpact,
  vibrate,
}

class GlassPageTransitionsBuilder extends PageTransitionsBuilder {
  const GlassPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => glassPageTransition(context, animation, secondaryAnimation, child);
}

Widget glassPageTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final duration = motionDuration(context, const Duration(milliseconds: 260));
  if (duration == Duration.zero) return child;
  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  return FadeTransition(
    opacity: Tween<double>(begin: 0.02, end: 1).animate(curved),
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.035),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}

/// 详情等整页跳转使用非不透明路由，推入/退出时首页仍留在下层绘制，
/// 避免不透明路由配合淡入动画时露出平台黑底。
class GlassPageRoute<T> extends PageRouteBuilder<T> {
  GlassPageRoute({required WidgetBuilder builder, super.settings})
    : super(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: glassPageTransition,
      );
}

class AccessibleAppearance extends InheritedWidget {
  const AccessibleAppearance({
    super.key,
    required this.reduceTransparency,
    required this.reduceMotion,
    required super.child,
  });

  final bool reduceTransparency;
  final bool reduceMotion;

  static AccessibleAppearance? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AccessibleAppearance>();

  @override
  bool updateShouldNotify(AccessibleAppearance oldWidget) =>
      reduceTransparency != oldWidget.reduceTransparency ||
      reduceMotion != oldWidget.reduceMotion;
}

bool reduceTransparencyOf(BuildContext context) =>
    AccessibleAppearance.maybeOf(context)?.reduceTransparency ?? false;

bool reduceMotionOf(BuildContext context) {
  final appSetting =
      AccessibleAppearance.maybeOf(context)?.reduceMotion ?? false;
  final systemSetting = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return appSetting || systemSetting;
}

Duration motionDuration(BuildContext context, Duration duration) =>
    reduceMotionOf(context) ? Duration.zero : duration;

/// 按压反馈包装器：仅做视觉缩放，不参与手势竞争，点击仍由子组件处理。
class GlassPressable extends StatefulWidget {
  const GlassPressable({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.97,
    this.haptic,
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;
  final GlassHaptic? haptic;

  @override
  State<GlassPressable> createState() => _GlassPressableState();
}

class _GlassPressableState extends State<GlassPressable> {
  bool _pressed = false;
  Offset? _downPosition;

  @override
  Widget build(BuildContext context) {
    final duration = widget.enabled
        ? motionDuration(context, AppMotion.press)
        : Duration.zero;
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: widget.enabled ? _handleDown : null,
      onPointerUp: widget.enabled ? _handleUp : null,
      onPointerCancel: widget.enabled ? (_) => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: duration,
        curve: AppMotion.enter,
        child: widget.child,
      ),
    );
  }

  void _handleDown(PointerDownEvent event) {
    _downPosition = event.position;
    _setPressed(true);
  }

  void _handleUp(PointerUpEvent event) {
    final down = _downPosition;
    _setPressed(false);
    final haptic = widget.haptic;
    if (haptic == null || down == null) return;
    if ((event.position - down).distance > 18) return;
    switch (haptic) {
      case GlassHaptic.selectionClick:
        HapticFeedback.selectionClick();
      case GlassHaptic.lightImpact:
        HapticFeedback.lightImpact();
      case GlassHaptic.mediumImpact:
        HapticFeedback.mediumImpact();
      case GlassHaptic.heavyImpact:
        HapticFeedback.heavyImpact();
      case GlassHaptic.vibrate:
        HapticFeedback.vibrate();
    }
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }
}

/// 条件出现/消失的通用动效：进入时上滑+淡入+展开，退出时反向收缩。
class GlassAnimatedPresence extends StatelessWidget {
  const GlassAnimatedPresence({
    super.key,
    required this.visible,
    required this.child,
    this.duration = AppMotion.switchDuration,
  });

  final bool visible;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final effective = motionDuration(context, duration);
    if (effective == Duration.zero) {
      return visible ? child : const SizedBox.shrink();
    }
    return AnimatedSwitcher(
      duration: effective,
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.crossFade,
        );
        return FadeTransition(
          opacity: curved,
          child: SizeTransition(
            sizeFactor: curved,
            axisAlignment: -1,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          ),
        );
      },
      child: visible
          ? child
          : const SizedBox.shrink(key: ValueKey('__glass_presence_hidden__')),
    );
  }
}

/// 保留所有子页面状态（同 [IndexedStack]）的交叉淡入切换；
/// 切换结束后隐藏页以 [Offstage] 收起，避免仍被查找/命中。
class CrossfadeIndexedStack extends StatefulWidget {
  const CrossfadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = AppMotion.switchDuration,
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  State<CrossfadeIndexedStack> createState() => _CrossfadeIndexedStackState();
}

class _CrossfadeIndexedStackState extends State<CrossfadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _current;
  int? _previous;
  bool _animating = false;
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _current = widget.index.clamp(0, widget.children.length - 1);
    _controller =
        AnimationController(vsync: this, duration: AppMotion.switchDuration)
          ..addStatusListener((status) {
            if (status != AnimationStatus.completed) return;
            if (!mounted) return;
            setState(() {
              _previous = null;
              _animating = false;
            });
          });
  }

  @override
  void didUpdateWidget(covariant CrossfadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.isEmpty) return;
    final next = widget.index.clamp(0, widget.children.length - 1);
    if (next == _current) return;
    final direction = next > _current ? 1 : -1;
    if (motionDuration(context, widget.duration) == Duration.zero) {
      setState(() {
        _current = next;
        _previous = null;
        _animating = false;
        _direction = direction;
      });
      return;
    }
    setState(() {
      _previous = _current;
      _current = next;
      _direction = direction;
      _animating = true;
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_controller.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < widget.children.length; i++)
              Offstage(
                offstage: !_animating && i != _current,
                child: IgnorePointer(
                  ignoring: i != widget.index,
                  child: Opacity(
                    opacity: _opacityFor(i, t),
                    child: Transform.translate(
                      offset: _offsetFor(i, t),
                      child: widget.children[i],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  double _opacityFor(int index, double t) {
    if (index == _current) return _animating ? t : 1;
    if (index == _previous) return _animating ? 1 - t : 0;
    return 0;
  }

  Offset _offsetFor(int index, double t) {
    if (index == _current) {
      return Offset(0.015 * _direction * (1 - t), 0);
    }
    if (index == _previous) {
      return Offset(-0.015 * _direction * t, 0);
    }
    return Offset.zero;
  }
}

/// 交错入场：延迟 [delay] 后透明度与 1.2% 高度位移渐入。
class GlassReveal extends StatefulWidget {
  const GlassReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.state,
    this.slide = true,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final bool slide;

  @override
  State<GlassReveal> createState() => _GlassRevealState();
}

class _GlassRevealState extends State<GlassReveal>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final reduce = reduceMotionOf(context);
    final total = reduce ? Duration.zero : widget.delay + widget.duration;
    final controller = AnimationController(vsync: this, duration: total);
    _controller = controller;
    final delayFraction = total == Duration.zero
        ? 0.0
        : widget.delay.inMicroseconds / total.inMicroseconds;
    _animation = CurvedAnimation(
      parent: controller,
      curve: Interval(delayFraction, 1, curve: AppMotion.enter),
    );
    if (reduce) {
      controller.value = 1;
    } else {
      controller.forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = _animation;
    if (animation == null) return widget.child;
    final faded = FadeTransition(
      // 从 0.001 开始而非 0，避免透明度为 0 时语义树被裁剪。
      opacity: Tween<double>(begin: 0.001, end: 1).animate(animation),
      child: widget.child,
    );
    if (!widget.slide) return faded;
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.012),
        end: Offset.zero,
      ).animate(animation),
      child: faded,
    );
  }
}

/// 统一的玻璃底部弹层入口：滑入淡入 + 轻微缩放，遵守减少动画。
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  BoxConstraints? constraints,
  bool showDragHandle = false,
}) {
  final duration = motionDuration(context, AppMotion.page);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    constraints: constraints,
    sheetAnimationStyle: duration == Duration.zero
        ? AnimationStyle.noAnimation
        : AnimationStyle(
            duration: duration,
            reverseDuration: duration,
            curve: AppMotion.enter,
            reverseCurve: AppMotion.exit,
          ),
    builder: (sheetContext) {
      final child = builder(sheetContext);
      if (!showDragHandle) return child;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Theme.of(sheetContext).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          child,
        ],
      );
    },
  );
}

/// A deliberately small palette derived from the reference prototype.
/// Teal leads the light theme while firefly green leads the dark theme.
class GlassPalette {
  const GlassPalette._();

  static const blue = Color(0xFF0F766E);
  static const firefly = Color(0xFFBEF264);
  static const indigo = Color(0xFF4F46E5);
  static const purple = Color(0xFF7C3AED);
  static const mint = Color(0xFF16A085);
  static const pink = Color(0xFFDB2777);
  static const orange = Color(0xFFD97706);
  static const upcoming = Color(0xFFB45309);
  static const upcomingDark = Color(0xFFFBBF24);
  static const overdue = Color(0xFFDC2626);
  static const overdueDark = Color(0xFFF87171);
  static const yearlyDark = Color(0xFF818CF8);
}

class LiquidBackground extends StatelessWidget {
  const LiquidBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduceTransparency = reduceTransparencyOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0F1115) : const Color(0xFFFCFBF9),
        gradient: reduceTransparency
            ? null
            : RadialGradient(
                center: const Alignment(0.86, -0.92),
                radius: 1.15,
                colors: dark
                    ? const [Color(0x122B3A26), Color(0x00101115)]
                    : const [Color(0x120F766E), Color(0x00F5F4F0)],
              ),
      ),
      child: child,
    );
  }
}

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.radius = 22,
    this.onTap,
    this.haptic,
    this.opacity,
    this.borderOpacity = 0.55,
    this.glass = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;
  final GlassHaptic? haptic;
  final double? opacity;
  final double? borderOpacity;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final reduceTransparency = reduceTransparencyOf(context);
    final borderRadius = BorderRadius.circular(radius);
    final baseColor = dark ? const Color(0xFF181A20) : Colors.white;
    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: glass && !reduceTransparency
            ? baseColor.withValues(alpha: opacity ?? 0.88)
            : baseColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(
            alpha: borderOpacity ?? 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.14 : 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
    final surface = ClipRRect(
      borderRadius: borderRadius,
      child: reduceTransparency || !glass
          ? container
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: container,
            ),
    );
    if (onTap == null) return surface;
    return GlassPressable(
      haptic: haptic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: surface,
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.selected = false,
    this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool selected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: selected
            ? scheme.onSurface
            : color ?? scheme.onSurfaceVariant,
        backgroundColor: Colors.transparent,
        minimumSize: const Size.square(44),
      ),
      icon: Icon(icon, size: 21),
    );
  }
}

/// 自定义玻璃开关，替代原生 Switch，保证与玻璃控件一致的观感与动效。
/// 语义由调用方通过外层 Semantics/MergeSemantics 提供，避免重复播报。
class GlassSwitch extends StatelessWidget {
  const GlassSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = motionDuration(context, const Duration(milliseconds: 160));
    return ExcludeSemantics(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          // 扩大触控热区到 44px 高。
          padding: const EdgeInsets.symmetric(vertical: 8.5, horizontal: 2),
          child: AnimatedContainer(
            duration: duration,
            width: 46,
            height: 27,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: value
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.55),
            ),
            child: AnimatedAlign(
              duration: duration,
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassChoiceTile extends StatelessWidget {
  const GlassChoiceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '$title，$value',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: motionDuration(
              context,
              const Duration(milliseconds: 180),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
                  : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? scheme.outlineVariant
                    : scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (trailing != null)
                  trailing!
                else
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                if (selected && trailing == null) ...[
                  const SizedBox(width: 7),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 19,
                    color: scheme.onSurface,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlassStatusPill extends StatelessWidget {
  const GlassStatusPill({
    super.key,
    required this.label,
    this.color,
    this.maxLines = 2,
  });

  final String label;
  final Color? color;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      label,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class GlassSectionTitle extends StatelessWidget {
  const GlassSectionTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
