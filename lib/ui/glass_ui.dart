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

/// A deliberately small palette. Blue is the only product accent; the
/// remaining colors are reserved for content that carries real semantics.
class GlassPalette {
  const GlassPalette._();

  static const blue = Color(0xFF2563EB);
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
        color: dark ? const Color(0xFF101114) : const Color(0xFFF7F7F8),
        gradient: reduceTransparency
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? const [Color(0xFF111318), Color(0xFF0D0F12)]
                    : const [Color(0xFFFAFBFD), Color(0xFFF3F5F8)],
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
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;
  final double? opacity;
  final double? borderOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final reduceTransparency = reduceTransparencyOf(context);
    final borderRadius = BorderRadius.circular(radius);
    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: reduceTransparency
            ? (dark ? const Color(0xFF1B1D22) : Colors.white)
            : (dark
                  ? const Color(0xFF1A1C21).withValues(alpha: opacity ?? 0.82)
                  : Colors.white.withValues(alpha: opacity ?? 0.76)),
        borderRadius: borderRadius,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(
            alpha: borderOpacity ?? (dark ? 0.34 : 0.55),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.18 : 0.045),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    final surface = ClipRRect(
      borderRadius: borderRadius,
      child: reduceTransparency
          ? container
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
