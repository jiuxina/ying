import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../models/countdown_event.dart';
import '../services/avatar_image_provider.dart';
import '../services/update_service.dart';
import '../state/app_controller.dart';
import '../utils/event_query.dart';
import 'calendar_page.dart';
import 'event_card.dart';
import 'event_detail_page.dart';
import 'event_filter_bar.dart';
import 'event_form_sheet.dart';
import 'glass_ui.dart';
import 'settings_page.dart';
import 'update_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final active = state.events.where((event) => !event.isCompleted).length;
    final pages = [
      _EventsPage(
        events: state.events,
        settings: state.settings,
        loading: state.isLoading,
        onAdd: _openForm,
        onEdit: _openForm,
      ),
      const CalendarPage(),
    ];

    return Scaffold(
      extendBody: true,
      body: LiquidBackground(
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Row(
                children: [
                  if (wide)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 0, 18),
                      child: _GlassRail(
                        selectedIndex: selectedIndex,
                        onChanged: (value) =>
                            setState(() => selectedIndex = value),
                        onAdd: _openForm,
                      ),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            wide ? 34 : 20,
                            8,
                            20,
                            0,
                          ),
                          child: _HomeTopBar(
                            active: active,
                            avatarPath: state.settings.avatarPath,
                            onAdd: _openForm,
                            onSettings: _openSettings,
                          ),
                        ),
                        Expanded(
                          child: IndexedStack(
                            index: selectedIndex,
                            children: pages,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (state.latestUndo != null)
              Positioned(
                left: wide ? 122 : 18,
                right: 18,
                bottom: wide ? 18 : 94,
                child: _UndoBanner(
                  message: state.latestUndo!.message,
                  pendingCount: state.pendingUndos.length,
                  onUndo: () =>
                      ref.read(appControllerProvider.notifier).undoLatest(),
                ),
              )
            // 撤销横幅优先展示；无撤销项时若检测到新版本，显示更新横幅。
            else if (state.availableRelease != null)
              Positioned(
                left: wide ? 122 : 18,
                right: 18,
                bottom: wide ? 18 : 94,
                child: _UpdateBanner(
                  release: state.availableRelease!,
                  onOpen: () => showReleaseDialog(
                    context,
                    state.availableRelease!,
                    onSkip: () => ref
                        .read(appControllerProvider.notifier)
                        .dismissUpdateRelease(skipVersion: true),
                  ),
                  onDismiss: () => ref
                      .read(appControllerProvider.notifier)
                      .dismissUpdateRelease(),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : _GlassTabBar(
              selectedIndex: selectedIndex,
              onChanged: (value) => setState(() => selectedIndex = value),
              onAdd: _openForm,
            ),
    );
  }

  Future<void> _openForm([CountdownEvent? event]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 680),
      builder: (context) => EventFormSheet(event: event),
    );
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push<void>(GlassPageRoute(builder: (context) => const SettingsPage()));
  }
}

class _EventsPage extends ConsumerStatefulWidget {
  const _EventsPage({
    required this.events,
    required this.settings,
    required this.loading,
    required this.onAdd,
    required this.onEdit,
  });

  final List<CountdownEvent> events;
  final AppSettings settings;
  final bool loading;
  final VoidCallback onAdd;
  final ValueChanged<CountdownEvent> onEdit;

  @override
  ConsumerState<_EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<_EventsPage> {
  static const String _completedHeaderItem = '__completed_header__';
  static const double _cardSpacing = 14;

  final searchController = TextEditingController();
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();

  /// 当前列表实际渲染的条目（事件 id 或 [_completedHeaderItem]），
  /// 与 [SliverAnimatedList] 的内部计数保持同步。
  final List<Object> _items = [];

  /// 事件快照：事件被删除/移动后，退出动画期间仍能渲染出卡片内容。
  final Map<String, CountdownEvent> _eventSnapshots = {};

  /// 上一次同步时的完成状态，用于识别"勾选完成/恢复"这类需要
  /// 在两个分组之间搬移卡片的变更。
  final Map<String, bool> _completionById = {};

  int _completedCount = 0;
  bool _syncScheduled = false;
  bool completedExpanded = false;
  bool searchExpanded = false;
  bool incompleteOnly = false;
  String? selectedCategory;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allEvents = widget.events;
    final events = queryEvents(
      allEvents,
      searchText: searchController.text,
      category: selectedCategory,
      incompleteOnly: incompleteOnly,
      sortMode: widget.settings.eventSortMode,
    );
    final categories = allEvents.map((event) => event.category).toSet().toList()
      ..sort();
    final activeEvents = events.where((event) => !event.isCompleted).toList();
    final active = activeEvents.length;
    _completedCount = events.length - active;
    for (final event in allEvents) {
      _eventSnapshots[event.id] = event;
    }
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (_listKey.currentState == null) {
      // 列表尚未挂载（首帧或整页切换后）：直接同步，不做过渡动画。
      _items
        ..clear()
        ..addAll(_computeTargetItems(activeEvents, events));
      _updateCompletionSnapshot(allEvents);
    } else {
      _scheduleSync();
    }
    return RefreshIndicator.adaptive(
      onRefresh: ref.read(appControllerProvider.notifier).load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.sizeOf(context).width >= 760 ? 34 : 20,
                14,
                20,
                14,
              ),
              child: Column(
                children: [
                  EventFilterBar(
                    controller: searchController,
                    searchExpanded: searchExpanded,
                    incompleteOnly: incompleteOnly,
                    selectedCategory: selectedCategory,
                    categories: categories,
                    sortMode: widget.settings.eventSortMode,
                    onToggleSearch: () =>
                        setState(() => searchExpanded = !searchExpanded),
                    onSearchChanged: (_) => setState(() {}),
                    onIncompleteChanged: (value) =>
                        setState(() => incompleteOnly = value),
                    onCategoryChanged: (value) =>
                        setState(() => selectedCategory = value),
                    onSortChanged: (value) => ref
                        .read(appControllerProvider.notifier)
                        .updateSettings(
                          widget.settings.copyWith(eventSortMode: value),
                        ),
                    onClear: _clearFilters,
                  ),
                ],
              ),
            ),
          ),
          if (allEvents.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(onAdd: widget.onAdd),
            )
          else if (events.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _NoFilterResults(onClear: _clearFilters),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.sizeOf(context).width >= 760 ? 34 : 20,
                8,
                20,
                132,
              ),
              sliver: SliverAnimatedList(
                key: _listKey,
                initialItemCount: _items.length,
                findChildIndexCallback: _findItemIndex,
                itemBuilder: (context, index, animation) =>
                    _buildListItem(index, animation),
              ),
            ),
        ],
      ),
    );
  }

  void _clearFilters() {
    searchController.clear();
    setState(() {
      selectedCategory = null;
      incompleteOnly = false;
    });
  }

  /// 按当前筛选/展开状态计算列表应有的条目顺序：
  /// 进行中事件 → “已完成”分组头 → 已完成事件。
  List<Object> _computeTargetItems(
    List<CountdownEvent> activeEvents,
    List<CountdownEvent> filteredEvents,
  ) {
    final completedEvents = filteredEvents
        .where((event) => event.isCompleted)
        .toList();
    return [
      for (final event in activeEvents) event.id,
      if (!incompleteOnly && completedEvents.isNotEmpty) ...[
        _completedHeaderItem,
        if (completedExpanded)
          for (final event in completedEvents) event.id,
      ],
    ];
  }

  void _updateCompletionSnapshot(List<CountdownEvent> events) {
    _completionById.clear();
    for (final event in events) {
      _completionById[event.id] = event.isCompleted;
    }
  }

  void _scheduleSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (mounted) _syncItems();
    });
  }

  /// 对比 [_items] 与目标条目，通过 [SliverAnimatedListState] 的
  /// insert/remove 驱动过渡动画。勾选完成/恢复的事件会被强制
  /// “移除再插入”，让卡片从一个分组搬到另一个分组，而不是原地突变。
  void _syncItems() {
    final allEvents = widget.events;
    final events = queryEvents(
      allEvents,
      searchText: searchController.text,
      category: selectedCategory,
      incompleteOnly: incompleteOnly,
      sortMode: widget.settings.eventSortMode,
    );
    final activeEvents = events.where((event) => !event.isCompleted).toList();
    final target = _computeTargetItems(activeEvents, events);

    final listState = _listKey.currentState;
    if (listState == null) {
      _items
        ..clear()
        ..addAll(target);
      _updateCompletionSnapshot(allEvents);
      return;
    }

    final toggledIds = <String>{
      for (final event in allEvents)
        if (_completionById.containsKey(event.id) &&
            _completionById[event.id] != event.isCompleted)
          event.id,
    };
    _updateCompletionSnapshot(allEvents);

    final duration = motionDuration(context, const Duration(milliseconds: 260));

    // 移除不再出现（或完成状态翻转）的条目，倒序处理避免索引错位。
    for (var index = _items.length - 1; index >= 0; index--) {
      final item = _items[index];
      final kept = switch (item) {
        final String id => target.contains(id) && !toggledIds.contains(id),
        _ => target.contains(item),
      };
      if (!kept) {
        _items.removeAt(index);
        listState.removeItem(
          index,
          (context, animation) => _buildItemFrame(item, animation),
          duration: duration,
        );
      }
    }

    // 插入新条目；位置变化的既有条目按“移除+插入”实现搬移动画。
    for (var index = 0; index < target.length; index++) {
      final item = target[index];
      if (index < _items.length && _items[index] == item) continue;
      final oldIndex = _items.indexOf(item, index + 1);
      if (oldIndex != -1) {
        _items.removeAt(oldIndex);
        listState.removeItem(
          oldIndex,
          (context, animation) => _buildItemFrame(item, animation),
          duration: duration,
        );
      }
      _items.insert(index, item);
      listState.insertItem(index, duration: duration);
    }
  }

  int? _findItemIndex(Key key) {
    if (key is! ValueKey<Object>) return null;
    final index = _items.indexOf(key.value);
    return index == -1 ? null : index;
  }

  Widget _buildListItem(int index, Animation<double> animation) {
    return _buildItemFrame(_items[index], animation, keyed: true);
  }

  Widget _buildItemFrame(
    Object item,
    Animation<double> animation, {
    bool keyed = false,
  }) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SizeTransition(
        sizeFactor: curved,
        child: _buildItemContent(item, keyed: keyed),
      ),
    );
  }

  Widget _buildItemContent(Object item, {required bool keyed}) {
    if (item == _completedHeaderItem) {
      return Padding(
        key: keyed ? const ValueKey<String>(_completedHeaderItem) : null,
        padding: const EdgeInsets.only(top: 4, bottom: _cardSpacing),
        child: _CompletedHeader(
          count: _completedCount,
          expanded: completedExpanded,
          onToggle: () =>
              setState(() => completedExpanded = !completedExpanded),
          onClear: () =>
              ref.read(appControllerProvider.notifier).clearCompletedWithUndo(),
        ),
      );
    }
    final event = _eventSnapshots[item as String];
    if (event == null) return const SizedBox.shrink();
    return Padding(
      key: keyed ? ValueKey<String>(event.id) : null,
      padding: const EdgeInsets.only(bottom: _cardSpacing),
      child: _buildEventCard(context, event),
    );
  }

  Widget _buildEventCard(BuildContext context, CountdownEvent event) {
    final child = EventCard(
      event: event,
      onOpen: () => Navigator.push<void>(
        context,
        GlassPageRoute(
          builder: (context) => EventDetailPage(eventId: event.id),
        ),
      ),
      onEdit: () => widget.onEdit(event),
      onToggle: () {
        // 每年重复事件勾选时是“进入下一年”，仍留在进行中分组；
        // 其余情况才真正完成，需要展开分组让卡片搬入可见。
        if (!event.isCompleted && !event.repeatsYearly) {
          setState(() => completedExpanded = true);
        }
        ref.read(appControllerProvider.notifier).toggleCompletedWithUndo(event);
      },
      onDelete: () =>
          ref.read(appControllerProvider.notifier).deleteEventWithUndo(event),
      onTogglePinned: () =>
          ref.read(appControllerProvider.notifier).togglePinned(event),
    );
    if (reduceMotionOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, value, animatedChild) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: animatedChild,
        ),
      ),
      child: child,
    );
  }
}

class _CompletedHeader extends StatelessWidget {
  const _CompletedHeader({
    required this.count,
    required this.expanded,
    required this.onToggle,
    required this.onClear,
  });

  final int count;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '已完成 $count',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.cleaning_services_outlined, size: 18),
              label: const Text('清理'),
            ),
        ],
      ),
    );
  }
}

class _UndoBanner extends StatelessWidget {
  const _UndoBanner({
    required this.message,
    required this.pendingCount,
    required this.onUndo,
  });

  final String message;
  final int pendingCount;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 24,
      opacity: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.82,
      glass: true,
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
      child: Row(
        children: [
          Icon(
            Icons.history_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 19,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              pendingCount > 1
                  ? '$message · 另有 ${pendingCount - 1} 项'
                  : message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(onPressed: onUndo, child: const Text('撤销')),
        ],
      ),
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({
    required this.release,
    required this.onOpen,
    required this.onDismiss,
  });

  final ReleaseInfo release;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 24,
      opacity: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.82,
      glass: true,
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
      child: Row(
        children: [
          Icon(
            Icons.system_update_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 19,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '发现新版本 v${release.version}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(onPressed: onOpen, child: const Text('查看')),
          IconButton(
            onPressed: onDismiss,
            tooltip: '关闭',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.active,
    required this.avatarPath,
    required this.onAdd,
    required this.onSettings,
  });

  final int active;
  final String avatarPath;
  final VoidCallback onAdd;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Semantics(
            image: true,
            label: '应用头像',
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage:
                  avatarImage(avatarPath) ?? const AssetImage('app.png'),
            ),
          ),
        ),
        const Spacer(),
        if (wide) ...[
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('新建日子'),
          ),
          const SizedBox(width: 12),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GlassIconButton(
              key: const ValueKey('home-settings'),
              icon: Icons.settings_outlined,
              tooltip: '设置',
              onPressed: onSettings,
            ),
            const SizedBox(height: 2),
            Text(
              active == 0 ? '还没有日子' : '$active 个待完成',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 130),
        child: GlassSurface(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_available_outlined,
                size: 36,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 18),
              Text(
                '让期待有迹可循',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                '考试、旅行、纪念日，都收藏在这里。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('创建第一个日子'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoFilterResults extends StatelessWidget {
  const _NoFilterResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 130),
        child: GlassSurface(
          radius: 20,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 42),
              const SizedBox(height: 14),
              Text('没有符合条件的事件', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '换一个关键词或清除筛选后再看看。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton(onPressed: onClear, child: const Text('清除筛选')),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassTabBar extends StatelessWidget {
  const _GlassTabBar({
    required this.selectedIndex,
    required this.onChanged,
    required this.onAdd,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: GlassSurface(
        radius: 30,
        glass: true,
        opacity: 0.88,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: '日子',
                  icon: Icons.calendar_today_rounded,
                  selected: selectedIndex == 0,
                  onTap: () => onChanged(0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Tooltip(
                  message: '新建倒数日',
                  child: SizedBox.square(
                    dimension: 46,
                    child: FilledButton(
                      onPressed: onAdd,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      child: const Icon(Icons.add_rounded, size: 24),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _TabButton(
                  label: '日历',
                  icon: Icons.calendar_month_rounded,
                  selected: selectedIndex == 1,
                  onTap: () => onChanged(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassRail extends StatelessWidget {
  const _GlassRail({
    required this.selectedIndex,
    required this.onChanged,
    required this.onAdd,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 32,
      glass: true,
      opacity: 0.88,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 16),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Tooltip(
              message: '新建倒数日',
              child: SizedBox.square(
                dimension: 46,
                child: FilledButton(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.add_rounded, size: 24),
                ),
              ),
            ),
            const Spacer(),
            _RailButton(
              icon: Icons.calendar_today_rounded,
              label: '日子',
              selected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
            const SizedBox(height: 14),
            _RailButton(
              icon: Icons.calendar_month_rounded,
              label: '日历',
              selected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 62,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
