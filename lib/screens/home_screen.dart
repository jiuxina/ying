import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import '../models/countdown_event.dart';
import '../providers/events_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/expandable_fab.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/search_header.dart';
import '../widgets/home/event_list_view.dart';
import '../widgets/debug/debug_floating_window.dart';
import 'add_edit_event_screen.dart';
import 'settings_screen.dart';
import 'archive_screen.dart';
import 'calendar_screen.dart';
import '../services/share_link_service.dart';

/// ============================================================================
/// 首页
/// ============================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String? _selectedCategoryId;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLink();
    _checkWidgetLaunch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _checkWidgetLaunch() async {
    try {
      // 检查是否是 Widget 配置启动
      const channel = MethodChannel('com.jiuxina.ying/install');
      final int? widgetId = await channel.invokeMethod<int>('getAppWidgetId');
      
      if (widgetId != null) {
        if (mounted) {
           Navigator.of(context).pushReplacementNamed('/widget_config');
        }
      }
    } catch (e) {
      debugPrint("Error checking widget ID: $e");
    }
  }

  Future<void> _initDeepLink() async {
    final appLinks = AppLinks();

    // Get the initial link (if any)
    try {
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        _handleLink(initialUri.toString());
      }
    } catch (e) {
      debugPrint('Initial link error: $e');
    }

    // Subscribe to link changes
    _sub = appLinks.uriLinkStream.listen((Uri? uri) { // Changed to uriLinkStream
      if (uri != null) {
        _handleLink(uri.toString());
      }
    }, onError: (err) {
      debugPrint('Link stream error: $err');
    });
  }

  void _handleLink(String link) {
    try {
      final uri = Uri.parse(link);
      if (uri.scheme != 'ying') return;

      if (uri.host == 'add_event') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddEditEventScreen(),
          ),
        );
      } else if (uri.host == 'event' || uri.path == '/event') {
        // 处理分享链接
        _handleShareLink(link);
      }
    } catch (e) {
      debugPrint('Handle link error: $e');
    }
  }

  void _handleShareLink(String link) async {
    final sharedEvent = ShareLinkService.parseShareLink(link);
    if (sharedEvent == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法解析分享链接')),
        );
      }
      return;
    }

    // 显示导入确认对话框
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入事件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('标题: ${sharedEvent.title}'),
            const SizedBox(height: 8),
            Text('日期: ${sharedEvent.targetDate.toString().split(' ')[0]}'),
            if (sharedEvent.note != null && sharedEvent.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('备注: ${sharedEvent.note}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('导入'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<EventsProvider>();
      // Create a new event with a proper ID
      final eventToImport = CountdownEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: sharedEvent.title,
        targetDate: sharedEvent.targetDate,
        isLunar: sharedEvent.isLunar,
        lunarDateStr: sharedEvent.lunarDateStr,
        categoryId: sharedEvent.categoryId,
        isCountUp: sharedEvent.isCountUp,
        isRepeating: sharedEvent.isRepeating,
        note: sharedEvent.note,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await provider.insertEvent(eventToImport);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导入: ${sharedEvent.title}')),
        );
      }
    }
  }

  void _exitSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSearching) {
          _exitSearch();
        }
      },
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: Consumer<EventsProvider>(
                    builder: (context, provider, child) {
                      return RefreshIndicator(
                        onRefresh: () => provider.init(),
                        child: _buildBody(provider),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _buildExpandableFAB(),
      ),
    );
  }

  Widget _buildAppBar() {
    if (_isSearching) {
      return SearchHeader(
        controller: _searchController,
        onBack: _exitSearch,
        onChanged: (value) => setState(() {}),
      );
    }
    return HomeHeader(
      onSearchTap: () => setState(() => _isSearching = true),
      onSettingsTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      ),
      onArchiveTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ArchiveScreen()),
      ),
      onCalendarTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CalendarScreen()),
      ),
    );
  }

  Widget _buildBody(EventsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final events = _getFilteredEvents(provider);
    final settings = context.watch<SettingsProvider>();
    final isCustomSort = settings.sortOrder == 'custom' && 
                         _searchController.text.isEmpty && 
                         _selectedCategoryId == null;

    if (events.isEmpty && !_isSearching && _selectedCategoryId == null) {
      // Only show default empty state when there are truly no events at all
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: const EmptyState(key: Key('default_empty')),
      );
    }

    // 分离置顶和普通事件
    final pinnedEvents = events.where((e) => e.isPinned).toList();
    final unpinnedEvents = events.where((e) => !e.isPinned).toList();

    return EventListView(
      pinnedEvents: pinnedEvents,
      unpinnedEvents: unpinnedEvents,
      selectedCategoryId: _selectedCategoryId,
      onCategoryChanged: (categoryId) {
        HapticFeedback.selectionClick();
        setState(() => _selectedCategoryId = categoryId);
      },
      isCustomSort: isCustomSort,
    );
  }

  /// 检查事件是否匹配搜索查询
  bool _matchesSearch(CountdownEvent event, String query) {
    if (query.isEmpty) return true;
    final matchesTitle = event.title.toLowerCase().contains(query);
    final matchesNote = event.note?.toLowerCase().contains(query) ?? false;
    return matchesTitle || matchesNote;
  }

  List<CountdownEvent> _getFilteredEvents(EventsProvider provider) {
    final settings = context.read<SettingsProvider>();
    final query = _searchController.text.toLowerCase();

    // First, separate pinned and unpinned events
    final allNonArchivedEvents = provider.events.where((e) => !e.isArchived).toList();
    final pinnedEvents = allNonArchivedEvents.where((e) => e.isPinned).toList();
    final unpinnedEvents = allNonArchivedEvents.where((e) => !e.isPinned).toList();

    // Filter unpinned events (pinned events bypass category filter)
    final filteredUnpinnedEvents = unpinnedEvents.where((e) {
      // Category filter (only for unpinned events)
      if (_selectedCategoryId != null && e.categoryId != _selectedCategoryId) {
        return false;
      }
      // Search filter
      return _matchesSearch(e, query);
    }).toList();

    // Apply search filter to pinned events (bypass category filter)
    final filteredPinnedEvents = pinnedEvents.where((e) => _matchesSearch(e, query)).toList();

    // Sort pinned events by creation time (FIFO - first pinned appears first)
    filteredPinnedEvents.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Sort unpinned events by user's sort preference
    filteredUnpinnedEvents.sort((a, b) {
      switch (settings.sortOrder) {
        case 'custom':
          final customOrder = settings.customSortOrder;
          if (customOrder.isEmpty) return a.daysRemaining.compareTo(b.daysRemaining);
          final indexA = customOrder.indexOf(a.id);
          final indexB = customOrder.indexOf(b.id);
          if (indexA == -1 && indexB == -1) return a.daysRemaining.compareTo(b.daysRemaining);
          if (indexA == -1) return 1; // 未排序的放后面
          if (indexB == -1) return -1;
          return indexA.compareTo(indexB);
        case 'daysAsc': return a.daysRemaining.compareTo(b.daysRemaining);
        case 'daysDesc': return b.daysRemaining.compareTo(a.daysRemaining);
        case 'dateAsc': return a.targetDate.compareTo(b.targetDate);
        case 'dateDesc': return b.targetDate.compareTo(a.targetDate);
        case 'titleAsc': return a.title.compareTo(b.title);
        case 'titleDesc': return b.title.compareTo(a.title);
        case 'createdAsc': return a.createdAt.compareTo(b.createdAt);
        case 'createdDesc': return b.createdAt.compareTo(a.createdAt);
        default: return a.daysRemaining.compareTo(b.daysRemaining);
      }
    });

    // Combine: pinned first, then unpinned
    return [...filteredPinnedEvents, ...filteredUnpinnedEvents];
  }

  Widget _buildExpandableFAB() {
    // 构建基本的FAB项目
    final items = <ExpandableFabItem>[
      ExpandableFabItem(
        icon: Icons.archive_outlined,
        label: '归档',
        color: Colors.orange,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ArchiveScreen()),
          );
        },
      ),
      ExpandableFabItem(
        icon: Icons.calendar_month,
        label: '日历',
        color: Colors.teal,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CalendarScreen()),
          );
        },
      ),
      ExpandableFabItem(
        icon: Icons.add,
        label: '添加事件',
        color: Theme.of(context).colorScheme.primary,
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: 'editor'),
              builder: (context) => const AddEditEventScreen(),
            ),
          );
        },
      ),
    ];

    // 仅在调试模式下添加调试按钮
    if (kDebugMode) {
      items.insert(0, ExpandableFabItem(
        icon: Icons.bug_report,
        label: '调试',
        color: Colors.purple,
        onPressed: () {
          DebugFloatingWindow.show(context);
        },
      ));
    }

    return ExpandableFab(items: items);
  }
}

