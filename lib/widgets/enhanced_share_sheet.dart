import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/countdown_event.dart';
import '../models/shared_event.dart';
import '../services/qr_code_service.dart';
import '../services/share_analytics_service.dart';
import '../utils/responsive_utils.dart';
import '../providers/events_provider.dart';
import 'qr_code_dialog.dart';
import '../screens/share_management_screen.dart';

/// 增强版分享底部弹窗
/// 支持QR码、链接、协作分享等多种方式
class EnhancedShareSheet extends StatefulWidget {
  final CountdownEvent event;
  final List<CountdownEvent>? multipleEvents;
  final bool showCollaboration;

  const EnhancedShareSheet({
    super.key,
    required this.event,
    this.multipleEvents,
    this.showCollaboration = true,
  });

  @override
  State<EnhancedShareSheet> createState() => _EnhancedShareSheetState();
}

class _EnhancedShareSheetState extends State<EnhancedShareSheet> {
  final ShareAnalyticsService _analyticsService = ShareAnalyticsService();
  bool _isCreatingCollaboration = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = context.watch<EventsProvider>().getCategoryById(widget.event.categoryId);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveBorderRadius.xl(context)),
        ),
      ),
      padding: EdgeInsets.all(ResponsiveSpacing.xl(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 拖动条
          Center(
            child: Container(
              width: ResponsiveUtils.scaledSize(context, 40),
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: ResponsiveSpacing.lg(context)),

          // 事件信息
          _buildEventInfo(context, category),
          SizedBox(height: ResponsiveSpacing.xl(context)),

          // 分享方式网格
          _buildShareGrid(context),
          SizedBox(height: ResponsiveSpacing.xl(context)),

          // 提示
          _buildTip(context),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildEventInfo(BuildContext context, dynamic category) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(ResponsiveSpacing.base(context)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.md(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(category.color as int),
              borderRadius: BorderRadius.circular(ResponsiveBorderRadius.md(context)),
            ),
            child: Center(
              child: Text(
                category.icon as String,
                style: const TextStyle(fontSize: 24),
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
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: ResponsiveFontSize.sm(context),
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    final days = widget.event.daysRemaining;
    if (widget.event.isCountUp) return '已 ${days.abs()} 天';
    if (days == 0) return '今天';
    return days > 0 ? '还有 $days 天' : '已过 ${days.abs()} 天';
  }

  Widget _buildShareGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择分享方式',
          style: TextStyle(
            fontSize: ResponsiveFontSize.base(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveSpacing.md(context)),
        Row(
          children: [
            Expanded(
              child: _buildShareOption(
                context: context,
                icon: Icons.qr_code_2,
                label: '二维码',
                subtitle: '扫码导入',
                color: Theme.of(context).colorScheme.primary,
                onTap: () => _shareViaQR(context),
              ),
            ),
            SizedBox(width: ResponsiveSpacing.md(context)),
            Expanded(
              child: _buildShareOption(
                context: context,
                icon: Icons.link,
                label: '链接',
                subtitle: '复制链接',
                color: Colors.blue,
                onTap: () => _shareViaLink(context),
              ),
            ),
            SizedBox(width: ResponsiveSpacing.md(context)),
            Expanded(
              child: _buildShareOption(
                context: context,
                icon: Icons.share,
                label: '分享',
                subtitle: '系统分享',
                color: Colors.green,
                onTap: () => _shareViaSystem(context),
              ),
            ),
          ],
        ),

        if (widget.showCollaboration) ...[
          SizedBox(height: ResponsiveSpacing.md(context)),
          Row(
            children: [
              Expanded(
                child: _buildShareOption(
                  context: context,
                  icon: Icons.people,
                  label: '协作分享',
                  subtitle: '共同关注',
                  color: Colors.orange,
                  onTap: () => _startCollaboration(context),
                  isLoading: _isCreatingCollaboration,
                ),
              ),
              SizedBox(width: ResponsiveSpacing.md(context)),
              Expanded(
                child: _buildShareOption(
                  context: context,
                  icon: Icons.family_restroom,
                  label: '家庭共享',
                  subtitle: '多人协作',
                  color: Colors.purple,
                  onTap: () => _openFamilySharing(context),
                ),
              ),
              SizedBox(width: ResponsiveSpacing.md(context)),
              Expanded(
                child: _buildShareOption(
                  context: context,
                  icon: Icons.history,
                  label: '历史',
                  subtitle: '分享记录',
                  color: Colors.grey,
                  onTap: () => _showHistory(context),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildShareOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSpacing.sm(context),
            vertical: ResponsiveSpacing.base(context),
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              isLoading
                  ? SizedBox(
                      width: ResponsiveIconSize.lg(context),
                      height: ResponsiveIconSize.lg(context),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(
                      icon,
                      color: color,
                      size: ResponsiveIconSize.xl(context),
                    ),
              SizedBox(height: ResponsiveSpacing.sm(context)),
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveFontSize.sm(context),
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: ResponsiveFontSize.xs(context),
                  color: color.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(ResponsiveSpacing.md(context)),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.md(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: ResponsiveIconSize.md(context),
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: ResponsiveSpacing.sm(context)),
          Expanded(
            child: Text(
              '协作分享支持多人共同关注事件，需要WebDAV同步功能',
              style: TextStyle(
                fontSize: ResponsiveFontSize.sm(context),
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 操作方法 ====================

  Future<void> _shareViaQR(BuildContext context) async {
    HapticFeedback.mediumImpact();

    // 记录分享
    await _analyticsService.recordShare(
      eventId: widget.event.id,
      shareMethod: 'qr',
      categoryId: widget.event.categoryId,
    );

    // 显示QR码对话框
    if (mounted) {
      Navigator.pop(context);
      showQRCodeDialog(
        context,
        event: widget.event,
        multipleEvents: widget.multipleEvents,
      );
    }
  }

  Future<void> _shareViaLink(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final link = QRCodeService.generateSingleEventQR(widget.event).encode();

    await Clipboard.setData(ClipboardData(text: link));

    // 记录分享
    await _analyticsService.recordShare(
      eventId: widget.event.id,
      shareMethod: 'link',
      categoryId: widget.event.categoryId,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('链接已复制到剪贴板')),
      );
    }
  }

  Future<void> _shareViaSystem(BuildContext context) async {
    HapticFeedback.mediumImpact();

    // 记录分享
    await _analyticsService.recordShare(
      eventId: widget.event.id,
      shareMethod: 'system',
      categoryId: widget.event.categoryId,
    );

    if (mounted) {
      Navigator.pop(context);
      // TODO: 使用 share_plus
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请使用系统分享功能')),
      );
    }
  }

  Future<void> _startCollaboration(BuildContext context) async {
    HapticFeedback.mediumImpact();

    setState(() => _isCreatingCollaboration = true);

    try {
      // 记录分享
      await _analyticsService.recordShare(
        eventId: widget.event.id,
        shareMethod: 'collaboration',
        categoryId: widget.event.categoryId,
      );

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShareManagementScreen(event: widget.event),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingCollaboration = false);
      }
    }
  }

  Future<void> _openFamilySharing(BuildContext context) async {
    HapticFeedback.mediumImpact();

    // 记录分享
    await _analyticsService.recordShare(
      eventId: widget.event.id,
      shareMethod: 'family',
      categoryId: widget.event.categoryId,
    );

    if (mounted) {
      Navigator.pop(context);
      // TODO: 打开家庭共享管理页面
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('家庭共享功能开发中')),
      );
    }
  }

  Future<void> _showHistory(BuildContext context) async {
    final history = await _analyticsService.getHistory(
      eventId: widget.event.id,
      limit: 10,
    );

    if (!mounted) return;

    if (history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无分享记录')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareHistorySheet(history: history),
    );
  }
}

/// 分享历史底部弹窗
class _ShareHistorySheet extends StatelessWidget {
  final List<ShareHistoryEntry> history;

  const _ShareHistorySheet({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveBorderRadius.xl(context)),
        ),
      ),
      padding: EdgeInsets.all(ResponsiveSpacing.xl(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '分享历史',
                style: TextStyle(
                  fontSize: ResponsiveFontSize.xl(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSpacing.md(context)),

          // 历史列表
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                return _buildHistoryItem(context, entry);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, ShareHistoryEntry entry) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getMethodIcon(entry.shareMethod),
          size: ResponsiveIconSize.sm(context),
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(
        _getMethodLabel(entry.shareMethod),
        style: TextStyle(fontSize: ResponsiveFontSize.base(context)),
      ),
      subtitle: Text(
        _formatDateTime(entry.sharedAt),
        style: TextStyle(
          fontSize: ResponsiveFontSize.sm(context),
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: entry.wasImported
          ? Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSpacing.sm(context),
                vertical: ResponsiveSpacing.xs(context),
              ),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveBorderRadius.sm(context),
                ),
              ),
              child: Text(
                '已导入',
                style: TextStyle(
                  fontSize: ResponsiveFontSize.xs(context),
                  color: Colors.green,
                ),
              ),
            )
          : null,
    );
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'qr':
        return Icons.qr_code_2;
      case 'link':
        return Icons.link;
      case 'family':
        return Icons.family_restroom;
      case 'collaboration':
        return Icons.people;
      default:
        return Icons.share;
    }
  }

  String _getMethodLabel(String method) {
    switch (method) {
      case 'qr':
        return '二维码分享';
      case 'link':
        return '链接分享';
      case 'family':
        return '家庭共享';
      case 'collaboration':
        return '协作分享';
      case 'system':
        return '系统分享';
      default:
        return '分享';
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
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// 显示增强版分享弹窗
void showEnhancedShareSheet(
  BuildContext context, {
  required CountdownEvent event,
  List<CountdownEvent>? multipleEvents,
  bool showCollaboration = true,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => EnhancedShareSheet(
      event: event,
      multipleEvents: multipleEvents,
      showCollaboration: showCollaboration,
    ),
  );
}
