import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../utils/constants.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/ui_helpers.dart';
import 'settings/appearance_settings_screen.dart';
import 'settings/widget_settings_screen.dart';
import 'settings/cloud_sync_screen.dart';
import 'settings/import_screen.dart';
import 'settings/group_management_screen.dart';
import 'settings/category_management_screen.dart';
import 'settings/data_backup_screen.dart';
import 'settings/about_screen.dart';

/// ============================================================================
/// 设置页面 - 导航式布局
/// ============================================================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = AppConstants.appVersion;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = 'V${info.version}');
      }
    } catch (_) {}
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
                    // 外观与显示
                    const SectionHeader(title: '外观与显示', icon: Icons.palette),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: _buildSettingsTile(
                        context,
                        icon: Icons.palette,
                        iconColor: Colors.purple,
                        title: '外观设置',
                        subtitle: '主题、进度条、字体、背景等',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 桌面小部件
                    const SectionHeader(title: '桌面小部件', icon: Icons.widgets),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: _buildSettingsTile(
                        context,
                        icon: Icons.widgets,
                        iconColor: Colors.teal,
                        title: '小部件设置',
                        subtitle: '自定义桌面小部件样式',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WidgetSettingsScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 数据与同步
                    const SectionHeader(title: '数据与同步', icon: Icons.cloud),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Column(
                        children: [
                          _buildSettingsTile(
                            context,
                            icon: Icons.cloud_sync,
                            iconColor: Colors.blue,
                            title: '云同步',
                            subtitle: '备份和恢复事件数据',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CloudSyncScreen()),
                            ),
                          ),
                          const Divider(height: 1),
                          _buildSettingsTile(
                            context,
                            icon: Icons.import_export,
                            iconColor: Colors.green,
                            title: '导入日历事件',
                            subtitle: '支持导入 .ics 格式的日程文件',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ImportScreen()),
                            ),
                          ),
                          const Divider(height: 1),
                          _buildSettingsTile(
                            context,
                            icon: Icons.backup,
                            iconColor: Colors.indigo,
                            title: '数据备份与恢复',
                            subtitle: '备份应用数据或从文件恢复',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DataBackupScreen()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 分类与分组
                    const SectionHeader(title: '分类与分组', icon: Icons.folder),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Column(
                        children: [
                          _buildSettingsTile(
                            context,
                            icon: Icons.folder,
                            iconColor: Colors.orange,
                            title: '事件分组管理',
                            subtitle: '管理首页事件分组',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const GroupManagementScreen()),
                            ),
                          ),
                          const Divider(height: 1),
                          _buildSettingsTile(
                            context,
                            icon: Icons.category,
                            iconColor: Colors.pink,
                            title: '分类管理',
                            subtitle: '添加和编辑自定义分类',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 关于
                    const SectionHeader(title: '其他', icon: Icons.info),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: _buildSettingsTile(
                        context,
                        icon: Icons.info,
                        iconColor: Colors.blueGrey,
                        title: '关于',
                        subtitle: _version,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AboutScreen(version: _version)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
            '设置',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}


