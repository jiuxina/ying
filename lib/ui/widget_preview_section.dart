import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_settings.dart';
import '../models/countdown_event.dart';
import '../models/widget_holiday.dart';
import '../services/background_image_provider.dart';
import '../services/widget_service.dart';
import 'glass_ui.dart';

class WidgetPreviewSection extends StatefulWidget {
  const WidgetPreviewSection({
    super.key,
    required this.events,
    required this.settings,
  });

  final List<CountdownEvent> events;
  final AppSettings settings;

  @override
  State<WidgetPreviewSection> createState() => _WidgetPreviewSectionState();
}

class _WidgetPreviewSectionState extends State<WidgetPreviewSection> {
  late Future<WidgetStatus> statusFuture;
  bool refreshing = false;

  @override
  void initState() {
    super.initState();
    statusFuture = WidgetService.status();
  }

  void _reloadStatus() {
    setState(() {
      statusFuture = WidgetService.status();
    });
  }

  Future<void> _refresh() async {
    setState(() => refreshing = true);
    try {
      await WidgetService.sync(widget.events, widget.settings);
      _reloadStatus();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('桌面小部件已刷新')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('刷新失败：$error')));
      }
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.events.where((event) => !event.isCompleted).toList()
      ..sort((a, b) => a.dayDelta().abs().compareTo(b.dayDelta().abs()));
    final event = visible.firstOrNull;
    final color = Color(widget.settings.widgetColor);
    return GlassSurface(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlassSectionTitle(title: '桌面小部件', subtitle: '预览、状态与添加引导'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final vertical = constraints.maxWidth < 500;
              final compactPreview = _WidgetPreview(
                event: event,
                settings: widget.settings,
                color: color,
                compact: true,
              );
              final mediumPreview = _WidgetPreview(
                event: event,
                settings: widget.settings,
                color: color,
                compact: false,
              );
              return vertical
                  ? Column(
                      children: [
                        compactPreview,
                        const SizedBox(height: 12),
                        mediumPreview,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: compactPreview),
                        const SizedBox(width: 12),
                        Expanded(child: mediumPreview),
                      ],
                    );
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<WidgetStatus>(
            future: statusFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }
              final status = snapshot.data!;
              return Column(
                children: [
                  _StatusRow(
                    icon: Icons.widgets_outlined,
                    color: status.installedCount == 0
                        ? GlassPalette.orange
                        : GlassPalette.indigo,
                    title: '桌面实例',
                    value: status.installedCount == 0
                        ? '未检测到'
                        : '${status.installedCount} 个',
                  ),
                  const _StatusDivider(),
                  _StatusRow(
                    icon: Icons.sync_rounded,
                    color: GlassPalette.blue,
                    title: '已同步事件',
                    value: '${status.syncedEventCount} 个',
                  ),
                  const _StatusDivider(),
                  _StatusRow(
                    icon: Icons.schedule_outlined,
                    color: status.lastSyncedAt == null
                        ? GlassPalette.orange
                        : GlassPalette.mint,
                    title: '最近刷新',
                    value: status.lastSyncedAt == null
                        ? '尚未同步'
                        : DateFormat(
                            'M月d日 HH:mm',
                            'zh_CN',
                          ).format(status.lastSyncedAt!),
                  ),
                  if (status.error != null) ...[
                    const _StatusDivider(),
                    _StatusRow(
                      icon: Icons.error_outline_rounded,
                      color: GlassPalette.orange,
                      title: '状态异常',
                      value: status.error!,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: refreshing ? null : _refresh,
                          icon: refreshing
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                          label: const Text('一键刷新'),
                        ),
                      ),
                      if (defaultTargetPlatform == TargetPlatform.android &&
                          status.pinSupported) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await WidgetService.requestPin();
                              if (mounted) _reloadStatus();
                            },
                            icon: const Icon(Icons.add_to_home_screen_rounded),
                            label: const Text('添加到桌面'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            defaultTargetPlatform == TargetPlatform.iOS
                ? '添加方法：长按桌面空白处，点击“+”，搜索“萤”，选择小号或中号。'
                : '若一键添加不可用：长按桌面空白处，打开“小部件”，找到“萤”并拖到桌面。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview({
    required this.event,
    required this.settings,
    required this.color,
    required this.compact,
  });

  final CountdownEvent? event;
  final AppSettings settings;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scale = settings.widgetFontScale;
    final style = settings.widgetStyle;
    final holiday = combinedHoliday(event, DateTime.now());
    final darkSurface = style == WidgetStyle.glass ||
        style == WidgetStyle.polaroid ||
        style == WidgetStyle.minimal;
    final wallpaperText = settings.widgetWallpaperTextColor == -1
        ? null
        : Color(settings.widgetWallpaperTextColor);
    final primaryText = wallpaperText ??
        (darkSurface ? const Color(0xFF1C1C1E) : Colors.white);
    final secondaryText = primaryText.withValues(alpha: 0.74);
    final accent = _holidayAccent(holiday) ?? Color(settings.widgetColor);
    final borderColor = style == WidgetStyle.minimal
        ? primaryText.withValues(alpha: 0.4)
        : style == WidgetStyle.glass
        ? Colors.white.withValues(alpha: 0.75)
        : style == WidgetStyle.neon
        ? accent
        : style == WidgetStyle.pixel
        ? accent.withValues(alpha: 0.9)
        : null;
    final withShadow = style == WidgetStyle.sticker ||
        style == WidgetStyle.photo ||
        style == WidgetStyle.neon ||
        style == WidgetStyle.pixel;
    final shadow = withShadow
        ? const [
            Shadow(
              color: Colors.black54,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ]
        : null;
    return Semantics(
      label: compact ? '小号小部件预览' : '中号小部件预览',
      child: Container(
        height: compact ? 150 : 170,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            switch (style) {
              WidgetStyle.pixel => 0,
              WidgetStyle.polaroid => 4,
              WidgetStyle.neon ||
              WidgetStyle.minimal => 8,
              _ => 10,
            },
          ),
          border: borderColor == null ? null : Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _PreviewBackdrop(
              style: style,
              color: color,
              accent: accent,
              imageProvider: widgetBackgroundImage(
                settings.widgetBackgroundPath,
              ),
            ),
            if (style == WidgetStyle.sticker || style == WidgetStyle.photo)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x66000000)],
                    stops: [0.35, 1],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: event == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '萤',
                          style: TextStyle(color: secondaryText),
                        ),
                        const Spacer(),
                        Text(
                          '添加一个倒数日',
                          style: TextStyle(
                            color: primaryText,
                            fontWeight: FontWeight.w700,
                            shadows: shadow,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!compact)
                          Row(
                            children: [
                              if (settings.widgetShowCategory)
                                Expanded(
                                  child: Text(
                                    event!.category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: secondaryText,
                                      shadows: shadow,
                                    ),
                                  ),
                                ),
                              if (holiday != WidgetHoliday.none) ...[
                                const SizedBox(width: 8),
                                _HolidayBadge(
                                  holiday: holiday,
                                  accent: accent,
                                ),
                              ],
                            ],
                          ),
                        const SizedBox(height: 2),
                        Text(
                          event!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 18 * scale,
                            fontWeight: FontWeight.w700,
                            shadows: shadow,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${event!.displayDays}',
                              style: TextStyle(
                                color: primaryText,
                                fontSize: (compact ? 38 : 44) * scale,
                                fontWeight: FontWeight.w800,
                                height: 0.95,
                                shadows: shadow,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '天',
                                style: TextStyle(
                                  color: secondaryText,
                                  shadows: shadow,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!compact &&
                            settings.widgetShowNote &&
                            event!.note.isNotEmpty)
                          Text(
                            event!.note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: secondaryText,
                              shadows: shadow,
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewBackdrop extends StatelessWidget {
  const _PreviewBackdrop({
    required this.style,
    required this.color,
    required this.accent,
    required this.imageProvider,
  });

  final WidgetStyle style;
  final Color color;
  final Color accent;
  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case WidgetStyle.card:
        return ColoredBox(color: color);
      case WidgetStyle.sticker:
      case WidgetStyle.minimal:
        return const SizedBox.shrink();
      case WidgetStyle.photo:
        final image = imageProvider;
        if (image != null) {
          return Image(
            image: image,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _photoPlaceholder(accent),
          );
        }
        return _photoPlaceholder(accent);
      case WidgetStyle.glass:
        return ColoredBox(color: Colors.white.withValues(alpha: 0.72));
      case WidgetStyle.polaroid:
        return Column(
          children: [
            const Expanded(child: ColoredBox(color: Colors.white)),
            ColoredBox(
              color: const Color(0xFFF0EDE6),
              child: const SizedBox(height: 30),
            ),
          ],
        );
      case WidgetStyle.neon:
        return ColoredBox(color: const Color(0xFF0A0F1E));
      case WidgetStyle.pixel:
        return ColoredBox(color: const Color(0xFF141414));
    }
  }

  Widget _photoPlaceholder(Color accent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.55), accent.withValues(alpha: 0.3)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.photo_outlined,
          color: Colors.white.withValues(alpha: 0.85),
          size: 30,
        ),
      ),
    );
  }
}

class _HolidayBadge extends StatelessWidget {
  const _HolidayBadge({required this.holiday, required this.accent});

  final WidgetHoliday holiday;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          holiday.label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            shadows: const [
              Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }
}

Color? _holidayAccent(WidgetHoliday holiday) {
  switch (holiday) {
    case WidgetHoliday.newYear:
      return const Color(0xFFE11D48);
    case WidgetHoliday.christmas:
      return const Color(0xFF16A34A);
    case WidgetHoliday.midAutumn:
      return const Color(0xFFD97706);
    case WidgetHoliday.birthday:
      return const Color(0xFFEC4899);
    case WidgetHoliday.none:
      return null;
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: GlassStatusPill(label: value, color: color, maxLines: 3),
          ),
        ],
      ),
    );
  }
}

class _StatusDivider extends StatelessWidget {
  const _StatusDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Theme.of(context).dividerColor);
  }
}
