import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_settings.dart';
import '../models/countdown_event.dart';
import '../models/widget_element_style.dart';
import '../models/widget_holiday.dart';
import '../models/widget_render_spec.dart';
import '../services/background_image_provider.dart';
import '../services/widget_service.dart';
import '../utils/widget_content_utils.dart';
import 'glass_ui.dart';

part 'widget_preview_painters.dart';

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
      ..sort(compareWidgetEvents);
    final event = visible.firstOrNull;
    final color = Color(widget.settings.widgetColor);
    final renderSpec = resolveWidgetRenderSpec(
      widget.events,
      widget.settings,
      sponsorUnlocked: true,
    );
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
              final compactPreview = widget.settings.widgetListMode
                  ? _WidgetListPreview(
                      events: visible,
                      settings: widget.settings,
                      color: color,
                      compact: true,
                      texts: renderSpec.texts,
                      render: renderSpec.compact,
                    )
                  : _WidgetPreview(
                      event: event,
                      settings: widget.settings,
                      color: color,
                      compact: true,
                      texts: renderSpec.texts,
                      render: renderSpec.compact,
                    );
              final mediumPreview = widget.settings.widgetListMode
                  ? _WidgetListPreview(
                      events: visible,
                      settings: widget.settings,
                      color: color,
                      compact: false,
                      texts: renderSpec.texts,
                      render: renderSpec.full,
                    )
                  : _WidgetPreview(
                      event: event,
                      settings: widget.settings,
                      color: color,
                      compact: false,
                      texts: renderSpec.texts,
                      render: renderSpec.full,
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
                  if (defaultTargetPlatform == TargetPlatform.android &&
                      status.pinSupported) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await WidgetService.requestDetailPin();
                        if (mounted) _reloadStatus();
                      },
                      icon: const Icon(Icons.filter_center_focus_rounded),
                      label: const Text('添加单事件小部件'),
                    ),
                  ],
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
    required this.texts,
    required this.render,
  });

  final CountdownEvent? event;
  final AppSettings settings;
  final Color color;
  final bool compact;
  final WidgetRenderTexts texts;
  final WidgetRenderBranch render;

  @override
  Widget build(BuildContext context) {
    final scale = settings.widgetFontScale;
    final style = settings.widgetStyle;
    final holiday = combinedHoliday(event, DateTime.now());
    final accent = _holidayAccent(holiday) ?? Color(settings.widgetColor);
    final primaryText = Color(render.element('title').color);
    final borderColor = style == WidgetStyle.minimal
        ? primaryText.withValues(alpha: 0.4)
        : style == WidgetStyle.glass
        ? Colors.white.withValues(alpha: 0.75)
        : style == WidgetStyle.neon
        ? accent
        : style == WidgetStyle.pixel
        ? accent.withValues(alpha: 0.9)
        : style == WidgetStyle.crt
        ? const Color(0xFF4ADE80).withValues(alpha: 0.75)
        : style == WidgetStyle.neonSign ||
              style == WidgetStyle.envelope ||
              style == WidgetStyle.pixelHealth ||
              style == WidgetStyle.mirror
        ? accent.withValues(alpha: 0.85)
        : null;
    final withShadow = style == WidgetStyle.sticker ||
        style == WidgetStyle.photo ||
        style == WidgetStyle.neon ||
        style == WidgetStyle.pixel ||
        style == WidgetStyle.neonSign ||
        style == WidgetStyle.envelope ||
        style == WidgetStyle.mirror;
    final shadow = withShadow
        ? const [
            Shadow(
              color: Colors.black54,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ]
        : null;
    final body = _PreviewBody(
      event: event,
      settings: settings,
      texts: texts,
      render: render,
      compact: compact,
      accent: accent,
      holiday: holiday,
      shadow: shadow,
      scale: scale,
    );
    final verticalAlignment = switch (settings.widgetVerticalAlign) {
      WidgetVerticalAlign.top => Alignment.topLeft,
      WidgetVerticalAlign.bottom => Alignment.bottomLeft,
      _ => Alignment.centerLeft,
    };
    return Semantics(
      label: compact ? '小号小部件预览' : '中号小部件预览',
      child: Container(
        height: compact
            ? 150
            : (settings.widgetShowPreciseTime ||
                      settings.widgetShowLunarWeek ||
                      settings.widgetShowProgress ||
                      settings.widgetQuoteMode ||
                      style == WidgetStyle.pixelHealth)
                  ? 216
                  : 170,
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
              child: style == WidgetStyle.mirror
                  ? Transform.rotate(
                      angle: -0.045,
                      child: Align(
                        alignment: verticalAlignment,
                        child: body,
                      ),
                    )
                  : Align(
                      alignment: verticalAlignment,
                      child: body,
                    ),
            ),
            if (style == WidgetStyle.envelope)
              const Positioned.fill(child: _EnvelopeCover()),
          ],
        ),
      ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    required this.event,
    required this.settings,
    required this.texts,
    required this.render,
    required this.compact,
    required this.accent,
    required this.holiday,
    required this.shadow,
    required this.scale,
  });

  final CountdownEvent? event;
  final AppSettings settings;
  final WidgetRenderTexts texts;
  final WidgetRenderBranch render;
  final bool compact;
  final Color accent;
  final WidgetHoliday holiday;
  final List<Shadow>? shadow;
  final double scale;

  WidgetElementRender _element(String id) => render.element(id);

  TextAlign _align(WidgetAlign value) => switch (value) {
    WidgetAlign.center => TextAlign.center,
    WidgetAlign.end => TextAlign.end,
    _ => TextAlign.start,
  };

  Color _color(String id, {Color? override}) {
    final style = settings.widgetElementStyles[id];
    final base = Color(_element(id).color);
    if (style?.colorMode == WidgetColorMode.custom) return base;
    return override ?? base;
  }

  Widget _iconButton(IconData icon, bool visible, Color color) {
    if (!visible) return const SizedBox.shrink();
    return Icon(icon, size: 22, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final current = event;
    final categoryElement = _element('category');
    final holidayElement = _element('holidayBadge');
    final titleElement = _element('title');
    final daysElement = _element('days');
    final unitElement = _element('unit');
    final iconElement = _element('icon');
    final noteElement = _element('note');
    final preciseElement = _element('precise');
    final dateInfoElement = _element('dateInfo');
    final progressElement = _element('progress');
    final prevElement = _element('prevButton');
    final nextElement = _element('nextButton');
    final completeElement = _element('completeButton');
    final daysAlign = daysElement.align;

    if (current == null) {
      final headerRow = Row(
        children: [
          if (categoryElement.visible)
            Expanded(
              child: Text(
                texts.category,
                style: TextStyle(
                  color: Color(categoryElement.color),
                  shadows: shadow,
                ),
              ),
            )
          else
            const Spacer(),
          _iconButton(
            Icons.chevron_left_rounded,
            prevElement.visible,
            Color(prevElement.color),
          ),
          _iconButton(
            Icons.chevron_right_rounded,
            nextElement.visible,
            Color(nextElement.color),
          ),
        ],
      );
      final emptyDaysAlign = switch (daysAlign) {
        WidgetAlign.center => MainAxisAlignment.center,
        WidgetAlign.end => MainAxisAlignment.end,
        _ => MainAxisAlignment.start,
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerRow,
          const Spacer(),
          if (titleElement.visible)
            Text(
              texts.title,
              textAlign: _align(titleElement.align),
              style: TextStyle(
                color: Color(titleElement.color),
                fontSize: (compact ? 15 : 18) * scale * titleElement.size,
                fontWeight: FontWeight.w700,
                shadows: shadow,
              ),
            ),
          if (daysElement.visible || unitElement.visible) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: emptyDaysAlign,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (daysElement.visible)
                  Text(
                    texts.days,
                    style: TextStyle(
                      color: Color(daysElement.color),
                      fontSize:
                          (compact ? 32 : 44) * scale * daysElement.size,
                      fontWeight: FontWeight.w800,
                      height: 0.95,
                      shadows: shadow,
                    ),
                  ),
                if (unitElement.visible) ...[
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      texts.unit,
                      style: TextStyle(
                        color: Color(unitElement.color),
                        fontSize: 14 * scale * unitElement.size,
                        shadows: shadow,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      );
    }
    final now = DateTime.now();
    final countDisplay = widgetCountDisplay(current, settings.widgetUnitText);
    final mystery = settings.widgetMysteryMode;
    final capsuleToday =
        settings.widgetStyle == WidgetStyle.capsule && current.dayDelta() == 0;
    final displayTitle = capsuleToday ? '恭喜！${current.title}' : current.title;
    final displayCategory = capsuleToday ? '时间胶囊' : current.category;
    final mainText = capsuleToday
        ? '🎉'
        : mystery
        ? '🕯️'
        : countDisplay.mainText;
    final unitText = capsuleToday
        ? '就是今天'
        : mystery
        ? '快到了'
        : countDisplay.unitText;
    final urgentLevel = settings.widgetUrgentHighlight
        ? widgetUrgentLevel(current)
        : 0;
    final urgentActive = !capsuleToday && urgentLevel > 0 && !mystery;
    final displayUnitText = urgentActive
        ? widgetUrgentLabel(urgentLevel, current.displayDays)
        : unitText;
    final Color? displayMainColor = capsuleToday
        ? accent
        : urgentActive
        ? Color(widgetUrgentArgb(urgentLevel))
        : null;
    final fontFamily = settings.widgetStyle == WidgetStyle.pixelHealth
        ? 'monospace'
        : widgetFontName(settings.widgetFontFamily);
    final italic = settings.widgetFontFamily == 'hand' &&
        settings.widgetStyle != WidgetStyle.pixelHealth;
    final dateInfoText = settings.widgetShowLunarWeek
        ? widgetDateInfo(now)
        : '';
    final quote = settings.widgetQuoteMode
        ? widgetQuoteText(current, now)
        : '';
    final noteText = quote.isNotEmpty ? quote : current.note;
    final progressValue = widgetProgress(current, now);
    final glowShadows = settings.widgetStyle == WidgetStyle.neonSign
        ? [
            Shadow(color: accent.withValues(alpha: 0.9), blurRadius: 10),
            Shadow(color: accent.withValues(alpha: 0.45), blurRadius: 22),
          ]
        : shadow;
    final iconVisible = iconElement.visible && current.icon.isNotEmpty;
    final titleVisible = titleElement.visible;
    final daysVisible = daysElement.visible;
    final unitVisible = unitElement.visible && displayUnitText.isNotEmpty;
    final categoryVisible = categoryElement.visible;
    final holidayVisible =
        holidayElement.visible && holiday != WidgetHoliday.none;
    final preciseVisible = preciseElement.visible;
    final dateInfoVisible = dateInfoElement.visible && dateInfoText.isNotEmpty;
    final progressVisible =
        progressElement.visible && settings.widgetShowProgress;
    final healthVisible = progressElement.visible &&
        settings.widgetStyle == WidgetStyle.pixelHealth;
    final noteVisible = noteElement.visible &&
        (quote.isNotEmpty ||
            (settings.widgetShowNote && current.note.isNotEmpty));
    final prevVisible = prevElement.visible;
    final nextVisible = nextElement.visible;
    final completeVisible = completeElement.visible;
    final mainFontSize = mainText.length > 3
        ? (compact ? 22 : 26) * scale * daysElement.size
        : (compact ? 32 : 44) * scale * daysElement.size;
    final daysMainAxisAlignment = switch (daysAlign) {
      WidgetAlign.center => MainAxisAlignment.center,
      WidgetAlign.end => MainAxisAlignment.end,
      _ => MainAxisAlignment.start,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categoryVisible ||
            holidayVisible ||
            prevVisible ||
            nextVisible)
          Row(
            children: [
              if (categoryVisible)
                Expanded(
                  child: Text(
                    displayCategory,
                    maxLines: 1,
                    textAlign: _align(categoryElement.align),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(categoryElement.color),
                      shadows: shadow,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (holidayVisible) ...[
                const SizedBox(width: 8),
                _HolidayBadge(holiday: holiday, accent: accent),
              ],
              _iconButton(
                Icons.chevron_left_rounded,
                prevVisible,
                Color(prevElement.color),
              ),
              _iconButton(
                Icons.chevron_right_rounded,
                nextVisible,
                Color(nextElement.color),
              ),
            ],
          ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (iconVisible) ...[
              Text(
                current.icon,
                style: TextStyle(
                  color: Color(iconElement.color),
                  fontSize: 18 * scale * iconElement.size,
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (titleVisible)
              Expanded(
                child: Text(
                  displayTitle,
                  maxLines: 1,
                  textAlign: _align(titleElement.align),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(titleElement.color),
                    fontSize: (compact ? 15 : 18) * scale * titleElement.size,
                    fontWeight: FontWeight.w700,
                    shadows: shadow,
                  ),
                ),
              ),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: daysMainAxisAlignment,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (healthVisible) ...[
              _PixelHealthBar(
                progress: progressValue,
                accent: accent,
                track: Color(daysElement.color).withValues(alpha: 0.16),
              ),
              const SizedBox(width: 9),
            ],
            if (progressVisible) ...[
              _ProgressRing(
                progress: progressValue,
                size: 42,
                color: accent,
                track: Color(daysElement.color).withValues(alpha: 0.22),
              ),
              const SizedBox(width: 9),
            ],
            if (daysVisible)
              Text(
                mainText,
                style: TextStyle(
                  color: _color('days', override: displayMainColor),
                  fontSize: mainFontSize,
                  fontWeight: FontWeight.w800,
                  height: 0.95,
                  shadows: glowShadows,
                  fontFamily: fontFamily,
                  fontStyle: italic ? FontStyle.italic : null,
                ),
              ),
            if (unitVisible) ...[
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  displayUnitText,
                  style: TextStyle(
                    color: _color(
                      'unit',
                      override: urgentActive
                          ? (displayMainColor ?? const Color(0xFFFFFFFF))
                              .withValues(alpha: 0.92)
                          : null,
                    ),
                    fontSize: 14 * scale * unitElement.size,
                    shadows: glowShadows,
                  ),
                ),
              ),
            ],
            if (completeVisible) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check_circle_outline_rounded,
                size: 22,
                color: Color(completeElement.color),
              ),
            ],
          ],
        ),
        if (preciseVisible)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widgetPreciseTimeText(current, now),
              textAlign: _align(preciseElement.align),
              style: TextStyle(
                color: Color(preciseElement.color),
                fontSize: 14 * scale * preciseElement.size,
                fontFamily: fontFamily,
                shadows: shadow,
              ),
            ),
          ),
        if (dateInfoVisible)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              dateInfoText,
              maxLines: 1,
              textAlign: _align(dateInfoElement.align),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(dateInfoElement.color),
                fontSize: 12 * scale * dateInfoElement.size,
                shadows: shadow,
              ),
            ),
          ),
        if (noteVisible)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              noteText,
              maxLines: 1,
              textAlign: _align(noteElement.align),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(noteElement.color),
                fontSize: 14 * scale * noteElement.size,
                fontStyle: quote.isNotEmpty ? FontStyle.italic : null,
                shadows: shadow,
              ),
            ),
          ),
      ],
    );
  }
}

TextAlign _renderTextAlign(WidgetAlign value) => switch (value) {
  WidgetAlign.center => TextAlign.center,
  WidgetAlign.end => TextAlign.end,
  _ => TextAlign.start,
};

class _WidgetListPreview extends StatelessWidget {
  const _WidgetListPreview({
    required this.events,
    required this.settings,
    required this.color,
    required this.compact,
    required this.texts,
    required this.render,
  });

  final List<CountdownEvent> events;
  final AppSettings settings;
  final Color color;
  final bool compact;
  final WidgetRenderTexts texts;
  final WidgetRenderBranch render;

  @override
  Widget build(BuildContext context) {
    final style = settings.widgetStyle;
    final accent = Color(settings.widgetColor);
    final scale = settings.widgetFontScale;
    final listHeader = render.element('listHeader');
    final empty = render.element('empty');
    final rowTitle = render.element('rowTitle');
    final primaryText = Color(rowTitle.color);
    final rows = events.isEmpty
        ? <CountdownEvent>[]
        : events.take(compact ? 2 : 4).toList();
    final listHeaderVisible = listHeader.visible;
    final emptyVisible = empty.visible && rows.isEmpty;
    return Semantics(
      label: compact ? '小号事件列表预览' : '中号事件列表预览',
      child: Container(
        height: compact ? 168 : 200,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            switch (style) {
              WidgetStyle.pixel => 0,
              WidgetStyle.polaroid => 4,
              _ => 10,
            },
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  if (listHeaderVisible) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '事件列表',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: _renderTextAlign(listHeader.align),
                            style: TextStyle(
                              color: Color(listHeader.color),
                              fontSize: 13 * scale * listHeader.size,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Expanded(
                    child: rows.isEmpty
                        ? Center(
                            child: emptyVisible
                                ? Text(
                                    texts.title,
                                    textAlign: _renderTextAlign(empty.align),
                                    style: TextStyle(
                                      color: Color(empty.color),
                                      fontSize: 15 * scale * empty.size,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          )
                        : Column(
                            children: [
                              for (
                                var index = 0;
                                index < rows.length;
                                index++
                              ) ...[
                                if (index > 0)
                                  Divider(
                                    height: 1,
                                    color: primaryText.withValues(alpha: 0.14),
                                  ),
                                Expanded(
                                  child: _ListRow(
                                    event: rows[index],
                                    settings: settings,
                                    render: render,
                                  ),
                                ),
                              ],
                            ],
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

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.event,
    required this.settings,
    required this.render,
  });

  final CountdownEvent event;
  final AppSettings settings;
  final WidgetRenderBranch render;

  @override
  Widget build(BuildContext context) {
    final countDisplay = widgetCountDisplay(event, settings.widgetUnitText);
    final mystery = settings.widgetMysteryMode;
    final mainText = mystery ? '🕯️' : countDisplay.mainText;
    final unitText = mystery ? '快到了' : countDisplay.unitText;
    final urgentLevel = settings.widgetUrgentHighlight
        ? widgetUrgentLevel(event)
        : 0;
    final urgentActive = urgentLevel > 0 && !mystery;
    final displayUnitText = urgentActive
        ? widgetUrgentLabel(urgentLevel, event.displayDays)
        : unitText;
    final Color? displayMainColor = urgentActive
        ? Color(widgetUrgentArgb(urgentLevel))
        : null;
    final fontFamily = widgetFontName(settings.widgetFontFamily);
    final scale = settings.widgetFontScale;
    final icon = render.element('icon');
    final rowTitle = render.element('rowTitle');
    final rowDays = render.element('rowDays');
    final rowUnit = render.element('rowUnit');
    final rowSubtitle = render.element('rowSubtitle');
    final complete = render.element('completeButton');
    final iconVisible = icon.visible && event.icon.isNotEmpty;
    final rowTitleVisible = rowTitle.visible;
    final rowDaysVisible = rowDays.visible;
    final rowUnitVisible = rowUnit.visible && displayUnitText.isNotEmpty;
    final completeVisible = complete.visible;
    final subtitle = [
      if (settings.widgetShowCategory) event.category,
      if (settings.widgetShowPreciseTime)
        widgetPreciseTimeText(event, DateTime.now()),
    ].join(' · ');
    final rowSubtitleVisible = rowSubtitle.visible && subtitle.isNotEmpty;

    Color color(String id, {Color? override}) {
      final style = settings.widgetElementStyles[id];
      final base = Color(render.element(id).color);
      if (style?.colorMode == WidgetColorMode.custom) return base;
      return override ?? base;
    }

    return Row(
      children: [
        if (iconVisible) ...[
          Text(
            event.icon,
            style: TextStyle(
              color: Color(icon.color),
              fontSize: 16 * scale * icon.size,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (rowTitleVisible)
                Text(
                  event.title,
                  maxLines: 1,
                  textAlign: _renderTextAlign(rowTitle.align),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(rowTitle.color),
                    fontSize: 14 * scale * rowTitle.size,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (rowSubtitleVisible) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  textAlign: _renderTextAlign(rowSubtitle.align),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(rowSubtitle.color),
                    fontSize: 11 * scale * rowSubtitle.size,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (rowDaysVisible)
          Text(
            mainText,
            style: TextStyle(
              color: color('rowDays', override: displayMainColor),
              fontSize: 18 * scale * rowDays.size,
              fontWeight: FontWeight.w800,
              fontFamily: fontFamily,
            ),
          ),
        if (rowUnitVisible && displayUnitText.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            displayUnitText,
            style: TextStyle(
              color: color(
                'rowUnit',
                override: urgentActive
                    ? (displayMainColor ?? const Color(0xFFFFFFFF))
                        .withValues(alpha: 0.92)
                    : null,
              ),
              fontSize: 11 * scale * rowUnit.size,
            ),
          ),
        ],
        if (completeVisible) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: Color(complete.color),
          ),
        ],
      ],
    );
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
