import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/debug_service.dart';
import '../../utils/constants.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/ui_helpers.dart';
import 'debug_console_screen.dart';

/// ============================================================================
/// 调试设置页面
/// ============================================================================

class DebugSettingsScreen extends StatefulWidget {
  const DebugSettingsScreen({super.key});

  @override
  State<DebugSettingsScreen> createState() => _DebugSettingsScreenState();
}

class _DebugSettingsScreenState extends State<DebugSettingsScreen> {
  final DebugService _debugService = DebugService();

  @override
  void initState() {
    super.initState();
    _debugService.addListener(_onDebugServiceUpdate);
  }

  void _onDebugServiceUpdate() {
    // Rebuild the entire widget when DebugService notifies listeners of data changes
    // (e.g., logs cleared, route history cleared, system info refreshed)
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _debugService.removeListener(_onDebugServiceUpdate);
    super.dispose();
  }

  void _openDebugConsole() {
    _debugService.info('Opening debug console', source: 'DebugSettings');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DebugConsoleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  children: [
                    const SectionHeader(
                      title: '调试功能',
                      icon: Icons.bug_report,
                    ),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Column(
                        children: [
                          _buildDebugModeTile(context),
                          const Divider(height: 1),
                          _buildConsoleControlTile(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SectionHeader(
                      title: '调试信息',
                      icon: Icons.info_outline,
                    ),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Column(
                        children: [
                          _buildInfoTile(
                            '日志数量',
                            '${_debugService.logs.length} 条',
                            Icons.description,
                            Colors.blue,
                          ),
                          const Divider(height: 1),
                          _buildInfoTile(
                            '路由历史',
                            '${_debugService.routeHistory.length} 条',
                            Icons.route,
                            Colors.purple,
                          ),
                          const Divider(height: 1),
                          _buildInfoTile(
                            '应用状态',
                            _debugService.appState,
                            Icons.apps,
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SectionHeader(
                      title: '操作',
                      icon: Icons.settings,
                    ),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Column(
                        children: [
                          _buildActionTile(
                            '清空日志',
                            '清除所有调试日志',
                            Icons.delete_outline,
                            Colors.orange,
                            _debugService.clearLogs,
                          ),
                          const Divider(height: 1),
                          _buildActionTile(
                            '清空路由历史',
                            '清除所有导航记录',
                            Icons.delete_sweep,
                            Colors.orange,
                            _debugService.clearRouteHistory,
                          ),
                          const Divider(height: 1),
                          _buildActionTile(
                            '刷新系统信息',
                            '重新收集系统信息',
                            Icons.refresh,
                            Colors.blue,
                            _debugService.collectSystemInfo,
                          ),
                        ],
                      ),
                    ),
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
          Text(
            '调试设置',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugModeTile(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          secondary: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.bug_report,
              size: 22,
              color: Colors.red,
            ),
          ),
          title: const Text(
            '启用调试模式',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            '开启后可以查看应用行为和系统信息',
            style: TextStyle(fontSize: 12),
          ),
          value: settings.debugModeEnabled,
          onChanged: (value) async {
            await settings.setDebugModeEnabled(value);
            if (value) {
              _debugService.info('Debug mode enabled', source: 'Settings');
              await _debugService.initialize();
            } else {
              _debugService.info('Debug mode disabled', source: 'Settings');
            }
          },
        );
      },
    );
  }

  Widget _buildConsoleControlTile() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final enabled = settings.debugModeEnabled;
        
        return ListTile(
          enabled: enabled,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (enabled ? Colors.blue : Colors.grey).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.terminal,
              size: 22,
              color: enabled ? Colors.blue : Colors.grey,
            ),
          ),
          title: Text(
            '调试控制台',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: enabled ? null : Colors.grey,
            ),
          ),
          subtitle: Text(
            '查看详细的日志信息和系统状态',
            style: TextStyle(
              fontSize: 12,
              color: enabled ? null : Colors.grey,
            ),
          ),
          onTap: enabled ? _openDebugConsole : null,
          trailing: Icon(
            Icons.chevron_right,
            size: 20,
            color: enabled
                ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)
                : Colors.grey,
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 22,
          color: color,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 22,
          color: color,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      onTap: () {
        onTap();
      },
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
      ),
    );
  }
}
