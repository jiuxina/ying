import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import '../models/countdown_event.dart';
import '../models/category_model.dart';
import '../providers/events_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/batch_operations_provider.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/expandable_fab.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/search_header.dart';
import '../widgets/home/event_list_view.dart';
import '../widgets/home/batch_operations_bar.dart';
import '../utils/responsive_utils.dart';
import 'add_edit_event_screen.dart';
import 'event_detail_screen.dart';
import 'settings_screen.dart';
import 'archive_screen.dart';
import 'calendar_screen.dart';
import 'template_gallery_screen.dart';
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
      // 首先从 install channel 消费 pending widget ID（与 Android 端实现保持一致）
      const installChannel = MethodChannel('com.jiuxina.ying/install');
      int? widgetId = await installChannel.invokeMethod<int>('consumePendingWidgetId');
      
      // 如果没有 pending ID，尝试从 intent 获取
      if (widgetId == null) {
        widgetId = await installChannel.invokeMethod<int>('getAppWidgetId');
      }

      const widgetChannel = MethodChannel('com.jiuxina.ying/widget');
      
      if (widgetId != null) {
        // Widget 配置模式
        debugPrint('Widget config mode, ID: $widgetId');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/widget_config');
        }
        return;
      }
      
      // 首先尝试消费 pending event ID（从 onNewIntent 获取）
      String? eventId = await widgetChannel.invokeMethod<String>('consumePendingEventId');
      
      // 如果没有 pending ID，尝试从 intent 获取
      if (eventId == null) {
        eventId = await widgetChannel.invokeMethod<String>('getLaunchEventId');
      }
      
      if (eventId != null && mounted) {
        debugPrint('Widget click mode, event ID: $eventId');
        // 查找事件并跳转到详情页
        final eventsProvider = context.read<EventsProvider>();
        try {
          final event = eventsProvider.events.firstWhere(
            (e) => e.id == eventId,
            orElse: () => eventsProvider.archivedEvents.firstWhere(
              (e) => e.id == eventId,
              orElse: () => throw Exception('Event not found'),
            ),
          );
          
          // 延迟导航，确保页面已构建完成
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EventDetailScreen(event: event),
                ),
              );
            }
          });
        } catch (e) {
          debugPrint('Widget 点击事件未找到: $eventId');
        }
      }
    } catch (e) {
      debugPrint("Error checking widget launch: $e");
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
    final batchOps = context.watch<BatchOperationsProvider>();
    
    return PopScope(
      canPop: !_isSearching && !batchOps.isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (batchOps.isSelectionMode) {
            batchOps.exitSelectionMode();
          } else if (_isSearching) {
            _exitSearch();
          }
        }
      },
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(batchOps),
                Expanded(
                  child: Consumer<EventsProvider>(
                    builder: (context, provider, child) {
                      return RefreshIndicator(
                        onRefresh: () => provider.init(),
                        child: _buildBody(provider, batchOps),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: batchOps.isSelectionMode 
            ? null 
            : _buildExpandableFAB(),
        bottomNavigationBar: batchOps.isSelectionMode
            ? BatchOperationsBar(
                onDelete: () => _showBatchDeleteConfirm(context, batchOps),
                onArchive: () => _showBatchArchiveConfirm(context, batchOps),
                onChangeCategory: () => _showBatchCategoryDialog(context, batchOps),
                onExport: () => _handleBatchExport(context, batchOps),
              )
            : null,
      ),
    );
  }

  Widget _buildAppBar(BatchOperationsProvider batchOps) {
    // 选择模式下的 AppBar
    if (batchOps.isSelectionMode) {
      return _buildSelectionModeAppBar(batchOps);
    }
    
    // 搜索模式下的 AppBar
    if (_isSearching) {
      return SearchHeader(
        controller: _searchController,
        onBack: _exitSearch,
        onChanged: (value) => setState(() {}),
      );
    }
    
    // 默认 AppBar
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

  /// 选择模式 AppBar
  Widget _buildSelectionModeAppBar(BatchOperationsProvider batchOps) {
    final theme = Theme.of(context);
    final selectedCount = batchOps.selectedCount;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSpacing.base(context),
        vertical: ResponsiveSpacing.sm(context),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              HapticFeedback.selectionClick();
              batchOps.exitSelectionMode();
            },
          ),
          Expanded(
              child: Text(
                '已选 $selectedCount 个',
                style: TextStyle(
                fontSize: ResponsiveFontSize.lg(context),
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (selectedCount > 0)
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                batchOps.invertSelection();
              },
              child: const Text('反选'),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(EventsProvider provider, BatchOperationsProvider batchOps) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final events = _getFilteredEvents(provider);
    final settings = context.watch<SettingsProvider>();
    final isCustomSort = settings.sortOrder == 'custom' && 
                         _searchController.text.isEmpty && 
                         _selectedCategoryId == null &&
                         !batchOps.isSelectionMode;

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
    return ExpandableFab(
      items: [
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
            icon: Icons.dashboard_customize,
            label: '模板创建',
            color: Colors.indigo,
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TemplateGalleryScreen()),
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
      ],
    );
  }

  // ========== 批量操作方法 ==========

  /// 显示批量删除确认对话框
  Future<void> _showBatchDeleteConfirm(
    BuildContext context,
    BatchOperationsProvider batchOps,
  ) async {
    final selectedCount = batchOps.selectedCount;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('删除选中的 $selectedCount 个事件？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await batchOps.batchDelete();
      
      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已删除 ${result.successCount} 个'),
              action: SnackBarAction(
                label: '撤销',
                onPressed: () async {
                  final undoSuccess = await batchOps.undoBatchDelete();
                  if (undoSuccess && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已撤销删除')),
                    );
                  }
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除：成功 ${result.successCount}，失败 ${result.failureCount}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  /// 显示批量归档确认对话框
  Future<void> _showBatchArchiveConfirm(
    BuildContext context,
    BatchOperationsProvider batchOps,
  ) async {
    final selectedCount = batchOps.selectedCount;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量归档'),
        content: Text('归档选中的 $selectedCount 个事件？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('归档'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await batchOps.batchArchive();
      
      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已归档 ${result.successCount} 个'),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('归档：成功 ${result.successCount}，失败 ${result.failureCount}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  /// 显示批量更改分类对话框
  Future<void> _showBatchCategoryDialog(
    BuildContext context,
    BatchOperationsProvider batchOps,
  ) async {
    final eventsProvider = context.read<EventsProvider>();
    final categories = eventsProvider.categories;
    
    String? selectedCategoryId;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('更改分类'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '移至：',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                  ),
                ),
                const SizedBox(height: 16),
                // 分类列表
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = selectedCategoryId == category.id;
                      
                      return RadioListTile<String>(
                        value: category.id,
                        groupValue: selectedCategoryId,
                        title: Row(
                          children: [
                            Text(category.icon),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                        secondary: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(category.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => selectedCategoryId = value);
                        },
                        selected: isSelected,
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: selectedCategoryId != null
                    ? () => Navigator.pop(context, true)
                    : null,
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && selectedCategoryId != null && mounted) {
      final result = await batchOps.batchChangeCategory(selectedCategoryId!);
      
      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已更改 ${result.successCount} 个分类'),
              action: SnackBarAction(
                label: '撤销',
                onPressed: () async {
                  final undoSuccess = await batchOps.undoBatchChangeCategory();
                  if (undoSuccess && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已撤销更改分类')),
                    );
                  }
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('更改：成功 ${result.successCount}，失败 ${result.failureCount}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  /// 处理批量导出
  void _handleBatchExport(
    BuildContext context,
    BatchOperationsProvider batchOps,
  ) {
    final exportedData = batchOps.exportSelected();
    
    if (exportedData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未选中任何事件')),
      );
      return;
    }
    
    // 显示导出成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已选 ${exportedData.length} 个，导出功能开发中...'),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // TODO: 实现实际的导出功能
    // 可以导出为 JSON 或 iCalendar 格式
  }
}

