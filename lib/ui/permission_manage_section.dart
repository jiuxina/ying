import 'dart:async';

import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/permission_service.dart';
import 'glass_ui.dart';

/// 权限管理页/首次引导共用的权限状态卡片。
/// 负责读取通知权限、电池优化与自启动入口状态，并提供跳转系统设置的操作。
class PermissionManageSection extends StatefulWidget {
  const PermissionManageSection({super.key, this.compact = false});

  final bool compact;

  @override
  State<PermissionManageSection> createState() => _PermissionManageSectionState();
}

class _PermissionManageSectionState extends State<PermissionManageSection>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool? _notificationsEnabled;
  bool _ignoringBattery = false;
  bool _autoStartSupported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading != true) {
      setState(() => _loading = true);
    }
    bool? notifications;
    try {
      notifications = await NotificationService.instance.notificationsEnabled();
    } catch (_) {
      // 测试或受限平台没有通知实现时保持“无法确定”状态。
    }
    var battery = false;
    try {
      battery = await PermissionService.instance.isIgnoringBatteryOptimizations();
    } catch (_) {}
    var autoStart = false;
    try {
      autoStart = await PermissionService.instance.isAutoStartSupported();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _loading = false;
      _notificationsEnabled = notifications;
      _ignoringBattery = battery;
      _autoStartSupported = autoStart;
    });
  }

  Future<void> _enableNotifications() async {
    final granted = await NotificationService.instance
        .ensureNotificationPermission();
    if (!granted) {
      await NotificationService.instance.openAppNotificationSettings();
      _showMessage('通知权限未开启，已为你打开系统通知设置');
    } else {
      _showMessage('通知权限已开启');
    }
    await _refresh();
  }

  Future<void> _openAutoStart() async {
    final result = await PermissionService.instance.openAutoStartSettings();
    if (result.opened && !result.fallback) {
      _showMessage('已打开系统自启动设置，请找到萤并允许自启动');
    } else if (result.opened && result.fallback) {
      _showMessage('未找到自启动入口，已打开应用详情，请手动查找自启动选项');
    } else {
      _showMessage('无法打开系统设置，请在系统设置中搜索“自启动”并允许萤');
    }
    await _refresh();
  }

  Future<void> _openBattery() async {
    final result = await PermissionService.instance
        .requestIgnoreBatteryOptimizations();
    if (result.opened && !result.fallback) {
      _showMessage('已打开系统页面，请允许萤忽略电池优化');
    } else if (result.opened && result.fallback) {
      _showMessage('自动跳转受限，已打开应用详情，请手动允许忽略电池优化');
    } else {
      _showMessage('无法打开系统设置，请在系统设置中关闭萤的电池优化限制');
    }
    await _refresh();
  }

  Future<void> _openDetails() async {
    final opened = await PermissionService.instance.openAppDetailsSettings();
    if (opened) {
      _showMessage('已打开应用详情，请手动检查需要的权限');
    } else {
      _showMessage('无法打开系统设置，请稍后重试');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassSurface(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassSectionTitle(
            title: widget.compact ? '完成基础配置' : '权限管理',
            subtitle: widget.compact ? null : '受系统限制，需在系统设置中允许',
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: CircularProgressIndicator.adaptive()),
            )
          else ...[
            _PermissionRow(
              actionKey: const ValueKey('permission-notification-action'),
              icon: Icons.notifications_active_outlined,
              title: '通知提醒',
              subtitle: '事件到点前准时提醒',
              status: switch (_notificationsEnabled) {
                true => '已开启',
                false => '未开启',
                null => '无法确定',
              },
              color: _notificationsEnabled == true
                  ? GlassPalette.mint
                  : GlassPalette.orange,
              actionLabel: _notificationsEnabled == true ? null : '去开启',
              onAction: _enableNotifications,
            ),
            const _PermissionDivider(),
            _PermissionRow(
              actionKey: const ValueKey('permission-autostart-action'),
              icon: Icons.power_settings_new_rounded,
              title: '开机自启动',
              subtitle: _autoStartSupported
                  ? '允许开机后恢复提醒调度'
                  : '不同厂商入口不同，建议手动开启',
              status: _autoStartSupported ? '建议开启' : '请手动开启',
              color: GlassPalette.orange,
              actionLabel: '去设置',
              onAction: _openAutoStart,
            ),
            const _PermissionDivider(),
            _PermissionRow(
              actionKey: const ValueKey('permission-battery-action'),
              icon: Icons.battery_charging_full_rounded,
              title: '忽略电池优化',
              subtitle: '避免系统清理后台调度',
              status: _ignoringBattery ? '已开启' : '未开启',
              color: _ignoringBattery
                  ? GlassPalette.mint
                  : GlassPalette.orange,
              actionLabel: _ignoringBattery ? null : '去开启',
              onAction: _openBattery,
            ),
          ],
          const SizedBox(height: 12),
          if (!_loading)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _openDetails,
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: const Text('打不开？去应用详情手动设置'),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.actionKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
    required this.onAction,
    this.actionLabel,
  });

  final Key actionKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color color;
  final String? actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: scheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GlassStatusPill(label: status, color: color),
              const SizedBox(height: 4),
              if (actionLabel != null)
                TextButton(
                  key: actionKey,
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text(actionLabel!),
                )
              else
                const Icon(Icons.check_circle_outline_rounded, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionDivider extends StatelessWidget {
  const _PermissionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Theme.of(context).dividerColor);
  }
}
