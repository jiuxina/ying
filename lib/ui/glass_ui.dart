import 'dart:ui';

import 'package:flutter/material.dart';

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
                    ? const [Color(0x182B3A26), Color(0x00101115)]
                    : const [Color(0x140F766E), Color(0x00FCFBF9)],
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
    this.opacity,
    this.borderOpacity,
    this.glass = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;
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
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: borderRadius, child: surface),
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
            ? scheme.primary
            : color ?? scheme.onSurfaceVariant,
        backgroundColor: selected
            ? scheme.primary.withValues(alpha: 0.10)
            : Colors.transparent,
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
        onTap: () => onChanged(!value),
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
              color: selected ? scheme.primary.withValues(alpha: 0.10) : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.32)
                    : scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
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
                    color: scheme.primary,
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
    final accent = color ?? scheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
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
            letterSpacing: -0.2,
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
