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
          '点击查看详情；更多操作菜单提供置顶、编辑和删除；右侧按钮可${event.repeatsYearly && !event.isCompleted
              ? '进入下一年'
              : event.isCompleted
              ? '恢复'
              : '完成'}',
      onTap: widget.onOpen,
      onIncrease: widget.onToggle,
      onLongPress: widget.onEdit,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: _SwipeActions(
              event: event,
              onEdit: widget.onEdit,
              onDelete: widget.onDelete,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
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
                  radius: 20,
                  onTap: dragOffset == 0 ? widget.onOpen : _closeActions,
                  padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
                  child: _CardContent(
                    event: event,
                    onEdit: widget.onEdit,
                    onDelete: widget.onDelete,
                    onToggle: widget.onToggle,
                    onTogglePinned: widget.onTogglePinned,
                  ),
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
  const _CardContent({
    required this.event,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    required this.onTogglePinned,
  });

  final CountdownEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final VoidCallback onTogglePinned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isTerminal = event.isCompleted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 58,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  event.dayDelta() == 0 ? '今' : '${event.displayDays}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: isTerminal
                        ? scheme.onSurfaceVariant
                        : scheme.primary,
                    fontWeight: FontWeight.w700,
                    height: 0.95,
                    letterSpacing: -1,
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
                  Expanded(
                    child: Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        decoration: isTerminal
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: '更多操作',
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: scheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onSelected: (value) {
                      HapticFeedback.lightImpact();
                      if (value == 'pin') onTogglePinned();
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Text(event.isPinned ? '取消置顶' : '置顶'),
                      ),
                      const PopupMenuItem(value: 'edit', child: Text('编辑')),
                      const PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${event.statusLabel} · ${DateFormat('M月d日 E', 'zh_CN').format(event.targetDate)}${event.isAllDay ? ' · 全天' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
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
