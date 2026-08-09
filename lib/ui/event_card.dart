import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/countdown_event.dart';
import 'glass_ui.dart';

class EventCard extends StatefulWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onOpen,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.onTogglePinned,
  });

  final CountdownEvent event;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTogglePinned;

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  static const _actionWidth = 132.0;
  static const _completeThreshold = 86.0;
  double dragOffset = 0;
  bool hapticTriggered = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final reduceMotion = reduceMotionOf(context);
    return Semantics(
      container: true,
      button: true,
      label:
          '${event.title}，${event.statusLabel}${event.displayDays}天，${event.category}${event.isPinned ? '，已置顶' : ''}${event.repeatsYearly ? '，每年重复' : ''}',
      hint:
          '点击查看详情；长按卡片可置顶、编辑或删除；右侧按钮可${event.repeatsYearly && !event.isCompleted
              ? '进入下一年'
              : event.isCompleted
              ? '恢复'
              : '完成'}',
      onTap: widget.onOpen,
      onIncrease: widget.onToggle,
      onLongPress: _showCardMenu,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              ignoring: dragOffset == 0,
              child: AnimatedOpacity(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 190),
                curve: Curves.easeOutCubic,
                opacity: dragOffset == 0 ? 0 : 1,
                child: _SwipeActions(
                  event: event,
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                ),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            onLongPress: _showCardMenu,
            child: AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 190),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(dragOffset, 0, 0),
              child: AnimatedOpacity(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                opacity: event.isCompleted ? 0.52 : 1,
                child: GlassSurface(
                  radius: 24,
                  onTap: dragOffset == 0 ? widget.onOpen : _closeActions,
                  padding: const EdgeInsets.fromLTRB(20, 18, 10, 18),
                  child: _CardContent(event: event, onToggle: widget.onToggle),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      dragOffset = (dragOffset + details.delta.dx).clamp(-_actionWidth, 120);
      if (dragOffset >= _completeThreshold && !hapticTriggered) {
        HapticFeedback.mediumImpact();
        hapticTriggered = true;
      } else if (dragOffset < _completeThreshold) {
        hapticTriggered = false;
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (dragOffset >= _completeThreshold) {
      HapticFeedback.selectionClick();
      widget.onToggle();
      setState(() => dragOffset = 0);
      return;
    }
    setState(() {
      dragOffset = dragOffset <= -56 ? -_actionWidth : 0;
      hapticTriggered = false;
    });
  }

  void _closeActions() => setState(() => dragOffset = 0);

  Future<void> _showCardMenu() async {
    if (dragOffset != 0) {
      _closeActions();
      return;
    }
    HapticFeedback.mediumImpact();
    final action = await showModalBottomSheet<_CardAction>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CardActionSheet(event: widget.event),
    );
    if (!mounted || action == null) return;
    HapticFeedback.lightImpact();
    if (action == _CardAction.pin) {
      widget.onTogglePinned();
    } else if (action == _CardAction.edit) {
      widget.onEdit();
    } else {
      widget.onDelete();
    }
  }
}

enum _CardAction { pin, edit, delete }

class _CardActionSheet extends StatelessWidget {
  const _CardActionSheet({required this.event});

  final CountdownEvent event;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: GlassSurface(
          radius: 24,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('事件操作', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              _CardActionRow(
                icon: event.isPinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                label: event.isPinned ? '取消置顶' : '置顶',
                onTap: () => Navigator.pop(context, _CardAction.pin),
              ),
              _CardActionRow(
                icon: Icons.edit_outlined,
                label: '编辑',
                onTap: () => Navigator.pop(context, _CardAction.edit),
              ),
              _CardActionRow(
                icon: Icons.delete_outline_rounded,
                label: '删除',
                color: scheme.error,
                onTap: () => Navigator.pop(context, _CardAction.delete),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardActionRow extends StatelessWidget {
  const _CardActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: accent),
                  const SizedBox(width: 11),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: color ?? scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeActions extends StatelessWidget {
  const _SwipeActions({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  final CountdownEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    event.isCompleted
                        ? Icons.restore_rounded
                        : Icons.check_rounded,
                    color: muted,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    event.isCompleted ? '恢复' : '完成',
                    style: TextStyle(color: muted),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: 132,
          child: Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.edit_outlined,
                  label: '编辑',
                  onTap: onEdit,
                ),
              ),
              Expanded(
                child: _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: '删除',
                  onTap: onDelete,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: muted, size: 19),
            const SizedBox(height: 3),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({required this.event, required this.onToggle});

  final CountdownEvent event;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isTerminal = event.isCompleted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                event.statusLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: motionDuration(
                  context,
                  const Duration(milliseconds: 220),
                ),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: FittedBox(
                  key: ValueKey(
                    '${event.displayDays}-${event.dayDelta() == 0}',
                  ),
                  fit: BoxFit.scaleDown,
                  child: Text(
                    event.dayDelta() == 0 ? '今' : '${event.displayDays}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: isTerminal
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                event.dayDelta() == 0 ? '今天' : '天',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (event.icon.isNotEmpty) ...[
                    Text(event.icon, style: const TextStyle(fontSize: 17)),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        decoration: isTerminal
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              AnimatedSwitcher(
                duration: motionDuration(
                  context,
                  const Duration(milliseconds: 180),
                ),
                child: Text(
                  '${DateFormat('M月d日 E', 'zh_CN').format(event.targetDate)}${event.isAllDay ? ' · 全天' : ''}',
                  key: ValueKey('${event.statusLabel}-${event.targetDate}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  if (event.isPinned)
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Icon(
                        Icons.push_pin_outlined,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  Flexible(
                    child: Text(
                      [
                        event.category,
                        if (event.repeatsYearly) '每年',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        GlassIconButton(
          icon: event.isCompleted
              ? Icons.check_circle_rounded
              : Icons.circle_outlined,
          selected: event.isCompleted,
          onPressed: () {
            HapticFeedback.lightImpact();
            onToggle();
          },
          tooltip: event.repeatsYearly && !event.isCompleted
              ? '进入下一年'
              : event.isCompleted
              ? '恢复事件'
              : '标记完成',
        ),
      ],
    );
  }
}
