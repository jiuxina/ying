import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/countdown_event.dart';
import '../models/shared_event.dart';
import '../providers/events_provider.dart';
import '../utils/responsive_utils.dart';
import '../widgets/qr_code_dialog.dart';

/// 分享管理屏幕
class ShareManagementScreen extends StatefulWidget {
  final CountdownEvent event;

  const ShareManagementScreen({
    super.key,
    required this.event,
  });

  @override
  State<ShareManagementScreen> createState() => _ShareManagementScreenState();
}

class _ShareManagementScreenState extends State<ShareManagementScreen> {
  SharedEventMetadata? _metadata;
  bool _isLoading = true;
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // TODO: 从SharedEventService获取元数据
      // final metadata = await sharedEventService.getSharedEventMetadata(widget.event.id);

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isLoading = false;
          // _metadata = metadata;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分享管理'),
        actions: [
          if (_metadata != null)
            IconButton(
              onPressed: _syncChanges,
              icon: const Icon(Icons.sync),
              tooltip: '同步',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(ResponsiveSpacing.lg(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 事件信息卡片
                  _buildEventCard(context),
                  SizedBox(height: ResponsiveSpacing.xl(context)),

                  // 分享状态
                  if (_metadata != null)
                    _buildSharedStatus(context)
                  else
                    _buildShareOptions(context),
                ],
              ),
            ),
    );
  }

  Widget _buildEventCard(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<EventsProvider>();
    final category = provider.getCategoryById(widget.event.categoryId);

    return Container(
      padding: EdgeInsets.all(ResponsiveSpacing.base(context)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(category.color),
              borderRadius: BorderRadius.circular(
                ResponsiveBorderRadius.md(context),
              ),
            ),
            child: Center(
              child: Text(
                category.icon,
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
          SizedBox(width: ResponsiveSpacing.md(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.title,
                  style: TextStyle(
                    fontSize: ResponsiveFontSize.lg(context),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: ResponsiveSpacing.xs(context)),
                Text(
                  '${widget.event.targetDate.year}-${widget.event.targetDate.month.toString().padLeft(2, '0')}-${widget.event.targetDate.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: ResponsiveFontSize.sm(context),
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_metadata != null)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSpacing.sm(context),
                vertical: ResponsiveSpacing.xs(context),
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(
                  ResponsiveBorderRadius.sm(context),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people,
                    size: ResponsiveIconSize.xs(context),
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: ResponsiveSpacing.xs(context)),
                  Text(
                    '${_metadata!.memberCount}',
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.xs(context),
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShareOptions(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '分享方式',
          style: TextStyle(
            fontSize: ResponsiveFontSize.lg(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveSpacing.md(context)),

        // QR码分享
        _buildShareOptionCard(
          context: context,
          icon: Icons.qr_code_2,
          title: '二维码分享',
          subtitle: '生成QR码，他人扫码即可导入',
          color: theme.colorScheme.primary,
          onTap: () => _showQRCode(context, forSharing: false),
        ),
        SizedBox(height: ResponsiveSpacing.md(context)),

        // 协作分享
        _buildShareOptionCard(
          context: context,
          icon: Icons.people,
          title: '协作分享',
          subtitle: '邀请他人共同关注此事件',
          color: Colors.green,
          onTap: () => _startCollaborativeSharing(context),
        ),
        SizedBox(height: ResponsiveSpacing.md(context)),

        // 链接分享
        _buildShareOptionCard(
          context: context,
          icon: Icons.link,
          title: '链接分享',
          subtitle: '生成分享链接',
          color: Colors.blue,
          onTap: _shareViaLink,
        ),
        SizedBox(height: ResponsiveSpacing.xl(context)),

        // 显示名称输入
        Text(
          '你的显示名称',
          style: TextStyle(
            fontSize: ResponsiveFontSize.base(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveSpacing.sm(context)),
        TextField(
          decoration: InputDecoration(
            hintText: '输入你的名字（可选）',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveBorderRadius.md(context),
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveSpacing.md(context),
              vertical: ResponsiveSpacing.sm(context),
            ),
          ),
          onChanged: (value) => _displayName = value,
        ),
      ],
    );
  }

  Widget _buildShareOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
        child: Container(
          padding: EdgeInsets.all(ResponsiveSpacing.base(context)),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveSpacing.sm(context)),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: ResponsiveIconSize.lg(context),
                ),
              ),
              SizedBox(width: ResponsiveSpacing.md(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.base(context),
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.sm(context),
                        color: color.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: ResponsiveIconSize.sm(context),
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSharedStatus(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 成员列表
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '共享成员',
              style: TextStyle(
                fontSize: ResponsiveFontSize.lg(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: _inviteMore,
              icon: Icon(
                Icons.person_add,
                size: ResponsiveIconSize.sm(context),
              ),
              label: const Text('邀请'),
            ),
          ],
        ),
        SizedBox(height: ResponsiveSpacing.md(context)),

        // 成员卡片列表
        ..._metadata!.members.map((member) => _buildMemberCard(context, member)),

        SizedBox(height: ResponsiveSpacing.xl(context)),

        // 更新历史
        Text(
          '最近更新',
          style: TextStyle(
            fontSize: ResponsiveFontSize.lg(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveSpacing.md(context)),
        Container(
          padding: EdgeInsets.all(ResponsiveSpacing.base(context)),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(ResponsiveBorderRadius.md(context)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history,
                    size: ResponsiveIconSize.sm(context),
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: ResponsiveSpacing.sm(context)),
                  Text(
                    '版本 ${_metadata!.version}',
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.sm(context),
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(width: ResponsiveSpacing.md(context)),
                  Text(
                    '更新于 ${_formatDateTime(_metadata!.updatedAt)}',
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.sm(context),
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveSpacing.xl(context)),

        // 操作按钮
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showQRCodeForSharing,
                icon: const Icon(Icons.qr_code),
                label: const Text('显示QR码'),
              ),
            ),
            SizedBox(width: ResponsiveSpacing.md(context)),
            Expanded(
              child: FilledButton.icon(
                onPressed: _syncChanges,
                icon: const Icon(Icons.sync),
                label: const Text('同步'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMemberCard(BuildContext context, SharedEventMember member) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSpacing.sm(context)),
      padding: EdgeInsets.all(ResponsiveSpacing.base(context)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.md(context)),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: member.isOwner
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            child: Text(
              member.displayName.isNotEmpty
                  ? member.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: ResponsiveFontSize.base(context),
                fontWeight: FontWeight.w600,
                color: member.isOwner
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(width: ResponsiveSpacing.md(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.displayName,
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.base(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (member.isOwner) ...[
                      SizedBox(width: ResponsiveSpacing.sm(context)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveSpacing.xs(context),
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(
                            ResponsiveBorderRadius.xs(context),
                          ),
                        ),
                        child: Text(
                          '创建者',
                          style: TextStyle(
                            fontSize: ResponsiveFontSize.xs(context),
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _getPermissionText(member.permission),
                  style: TextStyle(
                    fontSize: ResponsiveFontSize.sm(context),
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // 权限管理（仅管理员可见）
          if (_metadata!.hasPermission(
            _metadata!.members.firstWhere((m) => m.isOwner).id,
            SharePermission.admin,
          ))
            PopupMenuButton<SharePermission>(
              icon: Icon(
                Icons.more_vert,
                size: ResponsiveIconSize.md(context),
              ),
              onSelected: (permission) => _updateMemberPermission(member, permission),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: SharePermission.view,
                  child: Text('只读'),
                ),
                const PopupMenuItem(
                  value: SharePermission.edit,
                  child: Text('可编辑'),
                ),
                const PopupMenuItem(
                  value: SharePermission.admin,
                  child: Text('管理员'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _getPermissionText(SharePermission permission) {
    switch (permission) {
      case SharePermission.view:
        return '只读';
      case SharePermission.edit:
        return '可编辑';
      case SharePermission.admin:
        return '管理员';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} 分钟前';
      }
      return '${diff.inHours} 小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  Future<void> _showQRCode(BuildContext context, {bool forSharing = true}) async {
    await showDialog(
      context: context,
      builder: (context) => QRCodeDialog(
        event: widget.event,
        metadata: forSharing ? _metadata : null,
        deviceId: 'local-device', // TODO: 获取实际设备ID
        displayName: _displayName,
      ),
    );
  }

  Future<void> _startCollaborativeSharing(BuildContext context) async {
    // 显示名称确认对话框
    final displayName = await _askForDisplayName();
    if (displayName == null) return;

    // TODO: 创建共享事件
    setState(() {
      _isLoading = true;
    });

    try {
      // final metadata = await sharedEventService.createSharedEvent(
      //   event: widget.event,
      //   displayName: displayName,
      // );

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          // _metadata = metadata;
          _isLoading = false;
        });

        // 显示QR码
        _showQRCode(context, forSharing: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建共享失败: $e')),
        );
      }
    }
  }

  Future<String?> _askForDisplayName() async {
    final controller = TextEditingController(text: _displayName);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置显示名称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入你的名字',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _shareViaLink() {
    // 使用现有的分享功能
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请使用事件详情页的分享功能')),
    );
  }

  void _showQRCodeForSharing() {
    _showQRCode(context, forSharing: true);
  }

  Future<void> _syncChanges() async {
    setState(() => _isLoading = true);

    try {
      // TODO: 同步共享事件
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('同步成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步失败: $e')),
        );
      }
    }
  }

  void _inviteMore() {
    _showQRCode(context, forSharing: true);
  }

  Future<void> _updateMemberPermission(
    SharedEventMember member,
    SharePermission permission,
  ) async {
    // TODO: 更新成员权限
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已更新 ${member.displayName} 的权限')),
    );
  }
}
