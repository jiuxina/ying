import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../../providers/settings_provider.dart';
import '../../services/debug_service.dart';
import '../../utils/constants.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/ui_helpers.dart';

/// ============================================================================
/// 调试设置页面
/// ============================================================================

class DebugSettingsScreen extends StatefulWidget {
  const DebugSettingsScreen({super.key});

  @override
  State<DebugSettingsScreen> createState() => _DebugSettingsScreenState();
}

class _DebugSettingsScreenState extends State<DebugSettingsScreen> with WidgetsBindingObserver {
  final DebugService _debugService = DebugService();
  bool _isOverlayActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkOverlayStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Check overlay status when app resumes
    if (state == AppLifecycleState.resumed) {
      _checkOverlayStatus();
    }
  }

  Future<void> _checkOverlayStatus() async {
    try {
      _debugService.info('Checking overlay status...', source: 'DebugSettings');
      final status = await FlutterOverlayWindow.isActive();
      _debugService.info('Overlay status result: $status', source: 'DebugSettings');
      if (mounted) {
        setState(() {
          _isOverlayActive = status ?? false;
        });
      }
    } catch (e) {
      _debugService.error('Failed to check overlay status: $e', source: 'DebugSettings');
    }
  }

  Future<void> _requestOverlayPermission() async {
    try {
      _debugService.info('Checking overlay permission...', source: 'DebugSettings');
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      _debugService.info('Has permission: $hasPermission', source: 'DebugSettings');
      
      if (hasPermission != true) {
        _debugService.info('Requesting overlay permission', source: 'DebugSettings');
        final granted = await FlutterOverlayWindow.requestPermission();
        _debugService.info('Permission granted: $granted', source: 'DebugSettings');
        
        if (granted != true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('需要悬浮窗权限才能使用调试功能'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      // 显示悬浮窗
      _debugService.info('Attempting to show overlay...', source: 'DebugSettings');
      await _showOverlay();
    } catch (e) {
      _debugService.error('Failed to request overlay permission: $e', source: 'DebugSettings');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('请求悬浮窗权限失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showOverlay() async {
    try {
      _debugService.info('Attempting to show overlay...', source: 'DebugSettings');
      
      // Show the overlay
      await FlutterOverlayWindow.showOverlay(
        height: 600,
        width: 350,
        alignment: OverlayAlignment.centerRight,
        visibility: NotificationVisibility.visibilityPublic,
        flag: OverlayFlag.defaultFlag,
        enableDrag: true,
      );

      _debugService.info('Overlay show command executed', source: 'DebugSettings');
      
      // Wait a bit for the overlay to actually start
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check if overlay is actually active
      await _checkOverlayStatus();
      
      if (mounted) {
        if (_isOverlayActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('调试悬浮窗已启动'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('悬浮窗启动失败，请检查权限设置'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      _debugService.error('Failed to show overlay: $e', source: 'DebugSettings');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('显示悬浮窗失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _closeOverlay() async {
    try {
      _debugService.info('Attempting to close overlay...', source: 'DebugSettings');
      
      await FlutterOverlayWindow.closeOverlay();
      
      _debugService.info('Overlay close command executed', source: 'DebugSettings');
      
      // Wait a bit for the overlay to actually close
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Check if overlay is actually closed
      await _checkOverlayStatus();
      
      if (mounted && !_isOverlayActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('调试悬浮窗已关闭'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      _debugService.error('Failed to close overlay: $e', source: 'DebugSettings');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('关闭悬浮窗失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                          _buildOverlayStatusTile(),
                          const Divider(height: 1),
                          _buildOverlayControlTile(),
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
              if (_isOverlayActive) {
                await _closeOverlay();
              }
            }
          },
        );
      },
    );
  }

  Widget _buildOverlayStatusTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (_isOverlayActive ? Colors.green : Colors.grey).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          _isOverlayActive ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 22,
          color: _isOverlayActive ? Colors.green : Colors.grey,
        ),
      ),
      title: const Text(
        '悬浮窗状态',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        _isOverlayActive ? '悬浮窗已启动' : '悬浮窗未启动',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: _checkOverlayStatus,
        tooltip: '刷新状态',
      ),
    );
  }

  Widget _buildOverlayControlTile() {
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
              _isOverlayActive ? Icons.close : Icons.open_in_new,
              size: 22,
              color: enabled ? Colors.blue : Colors.grey,
            ),
          ),
          title: Text(
            _isOverlayActive ? '关闭悬浮窗' : '打开悬浮窗',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: enabled ? null : Colors.grey,
            ),
          ),
          subtitle: Text(
            _isOverlayActive ? '点击关闭调试悬浮窗' : '点击打开调试悬浮窗',
            style: TextStyle(
              fontSize: 12,
              color: enabled ? null : Colors.grey,
            ),
          ),
          onTap: enabled
              ? (_isOverlayActive ? _closeOverlay : _requestOverlayPermission)
              : null,
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
