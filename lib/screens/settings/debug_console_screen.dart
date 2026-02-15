import 'package:flutter/material.dart';
import '../../services/debug_service.dart';
import '../../utils/constants.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/ui_helpers.dart';

/// ============================================================================
/// 调试控制台页面 - 显示详细的调试日志信息
/// ============================================================================

class DebugConsoleScreen extends StatefulWidget {
  const DebugConsoleScreen({super.key});

  @override
  State<DebugConsoleScreen> createState() => _DebugConsoleScreenState();
}

class _DebugConsoleScreenState extends State<DebugConsoleScreen>
    with SingleTickerProviderStateMixin {
  final DebugService _debugService = DebugService();
  late TabController _tabController;
  String _logFilter = 'all'; // all, info, warning, error, debug
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _debugService.addListener(_onDebugServiceUpdate);
  }

  void _onDebugServiceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debugService.removeListener(_onDebugServiceUpdate);
    super.dispose();
  }

  List<DebugLogEntry> get _filteredLogs {
    var logs = _debugService.logs;
    
    // 按级别过滤
    if (_logFilter != 'all') {
      logs = logs.where((log) => log.level == _logFilter).toList();
    }
    
    // 按搜索关键词过滤
    if (_searchQuery.isNotEmpty) {
      logs = logs.where((log) {
        final searchLower = _searchQuery.toLowerCase();
        return log.message.toLowerCase().contains(searchLower) ||
            (log.source?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }
    
    return logs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLogsTab(),
                    _buildRoutesTab(),
                    _buildSystemTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.terminal, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '调试控制台',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '查看详细的应用日志和系统信息',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        tabs: const [
          Tab(
            icon: Icon(Icons.article, size: 20),
            text: '日志',
          ),
          Tab(
            icon: Icon(Icons.route, size: 20),
            text: '路由',
          ),
          Tab(
            icon: Icon(Icons.info_outline, size: 20),
            text: '系统',
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTab() {
    final logs = _filteredLogs.reversed.toList();

    return Column(
      children: [
        // 搜索和过滤工具栏
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            children: [
              // 搜索框
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索日志内容或来源...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.5),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              // 级别过滤器
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('全部', 'all', logs.length),
                    _buildFilterChip(
                      '信息',
                      'info',
                      _debugService.logs
                          .where((log) => log.level == 'info')
                          .length,
                      color: Colors.green,
                    ),
                    _buildFilterChip(
                      '警告',
                      'warning',
                      _debugService.logs
                          .where((log) => log.level == 'warning')
                          .length,
                      color: Colors.orange,
                    ),
                    _buildFilterChip(
                      '错误',
                      'error',
                      _debugService.logs
                          .where((log) => log.level == 'error')
                          .length,
                      color: Colors.red,
                    ),
                    _buildFilterChip(
                      '调试',
                      'debug',
                      _debugService.logs
                          .where((log) => log.level == 'debug')
                          .length,
                      color: Colors.cyan,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // 统计信息
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '显示 ${logs.length} / ${_debugService.logs.length} 条日志',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              TextButton.icon(
                onPressed: _debugService.clearLogs,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('清空日志'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 日志列表
        Expanded(
          child: logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无日志',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _buildLogCard(log);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, int count, {Color? color}) {
    final isSelected = _logFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _logFilter = value;
          });
        },
        selectedColor: (color ?? Theme.of(context).colorScheme.primary)
            .withValues(alpha: 0.2),
        checkmarkColor: color ?? Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected
              ? (color ?? Theme.of(context).colorScheme.primary)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildLogCard(DebugLogEntry log) {
    Color levelColor;
    IconData levelIcon;
    
    switch (log.level) {
      case 'error':
        levelColor = Colors.red;
        levelIcon = Icons.error;
        break;
      case 'warning':
        levelColor = Colors.orange;
        levelIcon = Icons.warning;
        break;
      case 'debug':
        levelColor = Colors.cyan;
        levelIcon = Icons.bug_report;
        break;
      default:
        levelColor = Colors.green;
        levelIcon = Icons.info;
    }

    final time = '${log.timestamp.hour.toString().padLeft(2, '0')}:'
        '${log.timestamp.minute.toString().padLeft(2, '0')}:'
        '${log.timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: levelColor, width: 4),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.all(12),
        leading: Icon(levelIcon, color: levelColor, size: 20),
        title: Row(
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 8),
            if (log.source != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.source!,
                  style: TextStyle(
                    fontSize: 10,
                    color: levelColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                log.message,
                style: const TextStyle(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('时间', _formatDateTime(log.timestamp)),
                const Divider(height: 16),
                _buildDetailRow('级别', log.level.toUpperCase()),
                const Divider(height: 16),
                if (log.source != null) ...[
                  _buildDetailRow('来源', log.source!),
                  const Divider(height: 16),
                ],
                _buildDetailRow('消息', log.message, isMultiline: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMultiline = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontFamily: isMultiline ? 'monospace' : null,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  Widget _buildRoutesTab() {
    final routes = _debugService.routeHistory.reversed.toList();

    return Column(
      children: [
        // 工具栏
        Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '共 ${routes.length} 条导航记录',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              TextButton.icon(
                onPressed: _debugService.clearRouteHistory,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('清空'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ),
        // 路由历史列表
        Expanded(
          child: routes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.route_outlined,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无导航记录',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '应用的路由导航历史将在此显示',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium),
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    final parts = route.split(' -> ');
                    final time = parts.length > 0 ? parts[0] : '';
                    final path = parts.length > 1 ? parts[1] : route;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.withValues(alpha: 0.2),
                          child: Text(
                            '${routes.length - index}',
                            style: const TextStyle(
                              color: Colors.purple,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          path,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSystemTab() {
    final systemInfo = _debugService.systemInfo;
    final appState = _debugService.appState;

    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      children: [
        // 说明卡片
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '调试控制台说明',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '调试控制台提供以下功能：',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildBulletPoint('日志记录：实时查看应用的所有日志信息，包括信息、警告、错误和调试日志'),
                _buildBulletPoint('日志过滤：支持按级别过滤和关键词搜索，快速定位问题'),
                _buildBulletPoint('路由历史：追踪应用的导航路径，了解用户操作流程'),
                _buildBulletPoint('系统信息：查看设备和应用的详细系统信息'),
                const SizedBox(height: 12),
                const Text(
                  '日志级别说明：',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildLevelDescription('信息', '一般性的操作记录', Colors.green),
                _buildLevelDescription('警告', '需要注意但不影响运行的问题', Colors.orange),
                _buildLevelDescription('错误', '影响功能的错误信息', Colors.red),
                _buildLevelDescription('调试', '详细的调试信息', Colors.cyan),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 应用状态
        GlassCard(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.apps, color: Colors.green),
            ),
            title: const Text(
              '应用状态',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(appState),
          ),
        ),
        const SizedBox(height: 16),
        // 系统信息
        const SectionHeader(
          title: '系统信息',
          icon: Icons.settings_system_daydream,
        ),
        const SizedBox(height: 8),
        if (systemInfo.isEmpty)
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '点击下方按钮获取系统信息',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ),
            ),
          )
        else
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: systemInfo.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            '${entry.key}:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        const SizedBox(height: 16),
        // 操作按钮
        ElevatedButton.icon(
          onPressed: () {
            _debugService.collectSystemInfo();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('刷新系统信息'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelDescription(String level, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              level,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
