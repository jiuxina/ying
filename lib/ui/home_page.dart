import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../models/countdown_event.dart';
import '../state/app_controller.dart';
import '../utils/event_query.dart';
import 'event_card.dart';
import 'event_detail_page.dart';
import 'event_filter_bar.dart';
import 'event_form_sheet.dart';
import 'glass_ui.dart';
import 'settings_page.dart';

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
    final pages = [
      _EventsPage(
        events: state.events,
        settings: state.settings,
        loading: state.isLoading,
        onAdd: _openForm,
        onEdit: _openForm,
      ),
      const SettingsPage(),
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
                    child: IndexedStack(index: selectedIndex, children: pages),
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
  final searchController = TextEditingController();
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
    final completedEvents = events.where((event) => event.isCompleted).toList();
    final active = activeEvents.length;
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
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
                28,
                20,
                14,
              ),
              child: Column(
                children: [
                  _HeroHeader(active: active, onAdd: widget.onAdd),
                  const SizedBox(height: 18),
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
              sliver: SliverList.list(
                children: [
                  for (final event in activeEvents) ...[
                    _buildEventCard(context, event),
                    const SizedBox(height: 14),
                  ],
                  if (!incompleteOnly && completedEvents.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _CompletedHeader(
                      count: completedEvents.length,
                      expanded: completedExpanded,
                      onToggle: () => setState(
                        () => completedExpanded = !completedExpanded,
                      ),
                      onClear: () => ref
                          .read(appControllerProvider.notifier)
                          .clearCompletedWithUndo(),
                    ),
                    if (completedExpanded) ...[
                      const SizedBox(height: 14),
                      for (final event in completedEvents) ...[
                        _buildEventCard(context, event),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ],
                ],
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

  Widget _buildEventCard(BuildContext context, CountdownEvent event) {
    final child = EventCard(
      key: ValueKey(event.id),
      event: event,
      onOpen: () => Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (context) => EventDetailPage(eventId: event.id),
        ),
      ),
      onEdit: () => widget.onEdit(event),
      onToggle: () => ref
          .read(appControllerProvider.notifier)
          .toggleCompletedWithUndo(event),
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

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.active, required this.onAdd});

  final int active;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '萤',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1,
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 8, bottom: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.55),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                active == 0 ? '收藏下一个值得期待的时刻' : '$active 个日子，正在靠近',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (wide)
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('新建日子'),
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
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                '考试、旅行、纪念日，\n把重要时刻收藏在这里。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
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
                child: GlassIconButton(
                  icon: Icons.add_rounded,
                  selected: true,
                  tooltip: '新建倒数日',
                  onPressed: onAdd,
                ),
              ),
              Expanded(
                child: _TabButton(
                  label: '设置',
                  icon: Icons.tune_rounded,
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
        ? Theme.of(context).colorScheme.primary
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
            GlassIconButton(
              icon: Icons.add_rounded,
              selected: true,
              onPressed: onAdd,
              tooltip: '新建倒数日',
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
              icon: Icons.tune_rounded,
              label: '设置',
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
          color: selected ? GlassPalette.blue.withValues(alpha: 0.14) : null,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected
                  ? GlassPalette.blue
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected
                    ? GlassPalette.blue
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
