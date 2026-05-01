import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/notification_service.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/ui_helpers.dart';
import '../../utils/constants.dart';

/// 通知设置页面
/// 
/// 帮助用户诊断和配置通知权限，确保定时通知正常工作
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  Map<String, dynamic>? _status;
  bool _isLoading = true;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final status = await _notificationService.checkNotificationStatus();
      final pending = await _notificationService.getPendingNotifications();
      
      if (mounted) {
        setState(() {
          _status = status;
          _pendingCount = pending.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载通知状态失败: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _requestPermissions() async {
    HapticFeedback.mediumImpact();
    
    try {
      final granted = await _notificationService.requestPermissions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(granted ? '✓ 权限已授予' : '❌ 权限被拒绝'),
            backgroundColor: granted ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // 重新加载状态
        await _loadStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('请求权限失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _requestBatteryOptimization() async {
    HapticFeedback.mediumImpact();
    
    try {
      final requested = await _notificationService.requestBatteryOptimization();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              requested 
                ? '✓ 已打开设置页面，请手动授予电池优化豁免' 
                : '❌ 请求失败，请手动在系统设置中配置'
            ),
            backgroundColor: requested ? Colors.blue : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // 等待用户返回后重新加载状态
        await Future.delayed(const Duration(seconds: 2));
        await _loadStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('请求电池优化豁免失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            '通知设置',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatus,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_status == null) {
      return const Center(
        child: Text('无法加载通知状态'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      children: [
        // 状态概览
        const SectionHeader(title: '通知状态', icon: Icons.notifications),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            children: [
              _buildStatusItem(
                '通知服务',
                _status!['initialized'] == true,
                '已初始化',
                '未初始化',
              ),
              const Divider(height: 1),
              _buildStatusItem(
                '通知权限',
                _status!['hasNotificationPermission'] == true,
                '已授予',
                '未授予',
              ),
              const Divider(height: 1),
              _buildStatusItem(
                '精确闹钟权限',
                _status!['hasExactAlarmPermission'] == true,
                '已授予',
                '未授予',
              ),
              const Divider(height: 1),
              _buildStatusItem(
                '电池优化豁免',
                _status!['hasBatteryOptimization'] == true,
                '已豁免',
                '受限制',
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.schedule, color: Colors.blue),
                title: const Text('待处理通知'),
                trailing: Text(
                  '$_pendingCount 个',
                  style: TextStyle(
                    color: _pendingCount > 0 ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 权限请求按钮
        if (_status!['hasNotificationPermission'] != true ||
            _status!['hasExactAlarmPermission'] != true)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton.icon(
              onPressed: _requestPermissions,
              icon: const Icon(Icons.security),
              label: const Text('请求通知权限'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ),

        // 电池优化豁免按钮
        if (_status!['hasBatteryOptimization'] != true)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton.icon(
              onPressed: _requestBatteryOptimization,
              icon: const Icon(Icons.battery_saver),
              label: const Text('请求电池优化豁免'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),

        // 警告信息
        if ((_status!['warnings'] as List).isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionHeader(title: '⚠️ 需要注意', icon: Icons.warning),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < (_status!['warnings'] as List).length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _status!['warnings'][i],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        // 配置建议
        if ((_status!['recommendations'] as List).isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionHeader(title: '💡 配置指南', icon: Icons.lightbulb),
          const SizedBox(height: 8),
          for (int i = 0; i < (_status!['recommendations'] as List).length; i++) ...[
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '配置步骤',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _status!['recommendations'][i],
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],

        // 说明信息
        const SizedBox(height: 16),
        const SectionHeader(title: 'ℹ️ 重要说明', icon: Icons.info),
        const SizedBox(height: 8),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '为什么需要配置？',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Android 为省电会限制后台活动\n'
                  '• 定时通知需要特殊权限\n'
                  '• 完成配置后通知才能正常工作\n'
                  '• 国产手机需额外设置\n'
                  '• 重启后自动恢复通知调度',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(
    String label,
    bool status,
    String enabledText,
    String disabledText,
  ) {
    return ListTile(
      leading: Icon(
        status ? Icons.check_circle : Icons.cancel,
        color: status ? Colors.green : Colors.red,
      ),
      title: Text(label),
      trailing: Text(
        status ? enabledText : disabledText,
        style: TextStyle(
          color: status ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
