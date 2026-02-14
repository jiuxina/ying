import 'package:flutter/material.dart';
import 'dart:async';
import '../services/debug_service.dart';

/// ============================================================================
/// 调试悬浮窗 UI
/// ============================================================================

class DebugOverlayWidget extends StatefulWidget {
  const DebugOverlayWidget({super.key});

  @override
  State<DebugOverlayWidget> createState() => _DebugOverlayWidgetState();
}

class _DebugOverlayWidgetState extends State<DebugOverlayWidget>
    with SingleTickerProviderStateMixin {
  final DebugService _debugService = DebugService();
  late TabController _tabController;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // 监听调试服务更新
    _debugService.addListener(_onDebugUpdate);
    
    // 定时刷新UI
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _onDebugUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _updateTimer?.cancel();
    _debugService.removeListener(_onDebugUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.85),
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.9),
          title: const Text(
            '调试信息',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.blue,
            labelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(text: '日志'),
              Tab(text: '路由'),
              Tab(text: '系统'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildLogsTab(),
            _buildRoutesTab(),
            _buildSystemTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsTab() {
    final logs = _debugService.logs.reversed.toList();

    return Column(
      children: [
        // 工具栏
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.black45,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '共 ${logs.length} 条日志',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              TextButton(
                onPressed: _debugService.clearLogs,
                child: const Text(
                  '清空',
                  style: TextStyle(color: Colors.red, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        // 日志列表
        Expanded(
          child: logs.isEmpty
              ? const Center(
                  child: Text(
                    '暂无日志',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    Color levelColor;
                    switch (log.level) {
                      case 'error':
                        levelColor = Colors.red;
                        break;
                      case 'warning':
                        levelColor = Colors.orange;
                        break;
                      case 'debug':
                        levelColor = Colors.cyan;
                        break;
                      default:
                        levelColor = Colors.green;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                        border: Border(
                          left: BorderSide(color: levelColor, width: 3),
                        ),
                      ),
                      child: Text(
                        log.toString(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRoutesTab() {
    final routes = _debugService.routeHistory.reversed.toList();

    return Column(
      children: [
        // 工具栏
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.black45,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '共 ${routes.length} 条导航记录',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              TextButton(
                onPressed: _debugService.clearRouteHistory,
                child: const Text(
                  '清空',
                  style: TextStyle(color: Colors.red, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        // 路由历史列表
        Expanded(
          child: routes.isEmpty
              ? const Center(
                  child: Text(
                    '暂无导航记录',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        routes[index],
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
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
      padding: const EdgeInsets.all(12),
      children: [
        _buildInfoCard('应用状态', appState, Icons.apps),
        const SizedBox(height: 12),
        _buildInfoCard('系统信息', null, Icons.info_outline),
        ...systemInfo.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    '${entry.key}:',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        _buildInfoCard('内存信息', '点击刷新获取最新信息', Icons.memory),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            _debugService.collectSystemInfo();
          },
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('刷新系统信息', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String? subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
