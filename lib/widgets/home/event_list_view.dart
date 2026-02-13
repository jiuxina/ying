import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/countdown_event.dart';
import '../../providers/events_provider.dart';
import '../../providers/settings_provider.dart';
import '../../screens/add_edit_event_screen.dart';
import '../../screens/event_detail_screen.dart';

import '../../utils/responsive_utils.dart';
import '../animations/staggered_animation.dart';
import '../category_selector.dart';
import '../common/ui_helpers.dart';
import '../event_card.dart';

class EventListView extends StatelessWidget {
  final List<CountdownEvent> pinnedEvents;
  final List<CountdownEvent> unpinnedEvents;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;
  final bool isCustomSort;

  const EventListView({
    super.key,
    required this.pinnedEvents,
    required this.unpinnedEvents,
    this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.isCustomSort,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    
    return ListView(
      padding: EdgeInsets.all(ResponsiveSpacing.base(context)),
      children: [
        // 事件 - 带排序和展开/收起按钮
        _buildMainHeader(context, settings),
        SizedBox(height: ResponsiveSpacing.md(context)),
        CategorySelector(
          selectedCategoryId: selectedCategoryId,
          onCategoryChanged: onCategoryChanged,
        ),
        SizedBox(height: ResponsiveSpacing.xl(context)),

        // 事件列表（置顶事件+普通事件合并）
        if (pinnedEvents.isEmpty && unpinnedEvents.isEmpty) ...[
          // 空状态仍然显示，但保持按钮可见
          _buildEmptyPlaceholder(context),
        ] else ...[
          if (isCustomSort)
            _buildCustomSortList(context)
          else
            _buildStandardList(context),
        ],

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildMainHeader(BuildContext context, SettingsProvider settings) {
    return Row(
      children: [
        Icon(
          Icons.event,
          size: ResponsiveIconSize.sm(context),
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(width: ResponsiveSpacing.sm(context)),
        Flexible(
          child: Text(
            '事件',
            style: TextStyle(
              fontSize: ResponsiveFontSize.lg(context),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _showSortDialog(context, settings);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sort,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  _getSortLabel(settings.sortOrder),
                  style: TextStyle(
                    fontSize: ResponsiveFontSize.sm(context),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            settings.toggleCardsExpanded();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  settings.cardsExpanded
                      ? Icons.unfold_less
                      : Icons.unfold_more,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  settings.cardsExpanded ? '收起' : '展开',
                  style: TextStyle(
                    fontSize: ResponsiveFontSize.sm(context),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ResponsiveSpacing.xxl(context)),
      child: Center(
        child: Text(
          '暂无事件',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            fontSize: ResponsiveFontSize.base(context),
          ),
        ),
      ),
    );
  }

  String _getSortLabel(String sortOrder) {
    switch (sortOrder) {
      case 'custom':
        return '自定义';
      case 'daysAsc':
        return '天数↑';
      case 'daysDesc':
        return '天数↓';
      case 'dateAsc':
        return '日期↑';
      case 'dateDesc':
        return '日期↓';
      case 'titleAsc':
        return '名称↑';
      case 'titleDesc':
        return '名称↓';
      case 'createdDesc':
        return '创建↓';
      default:
        return '排序';
    }
  }

  void _showSortDialog(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                '排序方式',
                style: TextStyle(
                  fontSize: ResponsiveFontSize.xl(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildSortOption(
                context,
                settings,
                'custom',
                '自定义排序 (拖拽)',
                Icons.drag_indicator,
              ),
              _buildSortOption(
                context,
                settings,
                'daysAsc',
                '按剩余天数（升序）',
                Icons.arrow_upward,
              ),
              _buildSortOption(
                context,
                settings,
                'daysDesc',
                '按剩余天数（降序）',
                Icons.arrow_downward,
              ),
              _buildSortOption(
                context,
                settings,
                'dateAsc',
                '按目标日期（升序）',
                Icons.calendar_today,
              ),
              _buildSortOption(
                context,
                settings,
                'dateDesc',
                '按目标日期（降序）',
                Icons.calendar_today,
              ),
              _buildSortOption(
                context,
                settings,
                'titleAsc',
                '按名称（A-Z）',
                Icons.sort_by_alpha,
              ),
              _buildSortOption(
                context,
                settings,
                'createdDesc',
                '按创建时间（最新）',
                Icons.access_time,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    SettingsProvider settings,
    String order,
    String label,
    IconData icon,
  ) {
    final isSelected = settings.sortOrder == order;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        settings.setSortOrder(order);
        Navigator.pop(context);
      },
    );
  }

  /// Merge pinned events at the top, followed by unpinned events
  List<CountdownEvent> get _allEvents => [...pinnedEvents, ...unpinnedEvents];

  Widget _buildStandardList(BuildContext context) {
    return Column(
      children: [
        ..._allEvents.asMap().entries.map(
          (entry) => StaggeredListItem(
            index: entry.key,
            child: _buildEventCard(context, entry.value),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomSortList(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allEvents.length,
      onReorder: (oldIndex, newIndex) {
        // Don't allow reordering pinned events with unpinned events
        final pinnedCount = pinnedEvents.length;
        
        // If trying to move a pinned event or move into pinned section, ignore
        if (oldIndex < pinnedCount || newIndex < pinnedCount) {
          return;
        }
        
        // Adjust indices to work with unpinnedEvents only
        final adjustedOldIndex = oldIndex - pinnedCount;
        var adjustedNewIndex = newIndex - pinnedCount;
        
        if (adjustedOldIndex < adjustedNewIndex) {
          adjustedNewIndex -= 1;
        }
        
        final item = unpinnedEvents[adjustedOldIndex];
        final newOrderList = List<CountdownEvent>.from(unpinnedEvents);
        newOrderList.removeAt(adjustedOldIndex);
        newOrderList.insert(adjustedNewIndex, item);

        HapticFeedback.selectionClick();
        final settings = context.read<SettingsProvider>();
        final newOrderIds = newOrderList.map((e) => e.id).toList();
        settings.setCustomSortOrder(newOrderIds);
      },
      itemBuilder: (context, index) {
        final event = _allEvents[index];
        final isPinned = index < pinnedEvents.length;
        
        return Padding(
          key: ValueKey(event.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildEventCard(
            context, 
            event, 
            isReorderable: !isPinned, // Only unpinned events are reorderable
          ),
        );
      },
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    CountdownEvent event, {
    bool isReorderable = false,
  }) {
    final settings = context.watch<SettingsProvider>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: EventCard(
        event: event,
        compact: !settings.cardsExpanded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        ),
        onLongPress: isReorderable
            ? null
            : () => _showEventOptions(context, event),
        onTogglePin: () {
          HapticFeedback.mediumImpact();
          context.read<EventsProvider>().togglePin(event.id);
        },
      ),
    );
  }

  void _showEventOptions(BuildContext context, CountdownEvent event) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                event.title,
                style: TextStyle(
                  fontSize: ResponsiveFontSize.xl(context),
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ListTile(
              leading: Icon(
                event.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(event.isPinned ? '取消置顶' : '置顶事件'),
              onTap: () {
                context.read<EventsProvider>().togglePin(event.id);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('编辑事件'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: const RouteSettings(name: 'editor'),
                    builder: (context) => AddEditEventScreen(event: event),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                event.isArchived ? Icons.unarchive : Icons.archive,
                color: Colors.orange,
              ),
              title: Text(event.isArchived ? '取消归档' : '归档事件'),
              onTap: () {
                Navigator.pop(context);
                context.read<EventsProvider>().toggleArchive(event.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(event.isArchived ? '已取消归档' : '已归档'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除事件'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirm(context, event);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, CountdownEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${event.title}"吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              context.read<EventsProvider>().deleteEvent(event.id);
              Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('事件已删除'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

