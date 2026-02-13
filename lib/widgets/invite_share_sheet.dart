import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/countdown_event.dart';
import '../services/share_link_service.dart';
import '../utils/responsive_utils.dart';

/// 事件邀请分享对话框
/// 允许用户分享事件链接邀请他人共同关注
class InviteShareBottomSheet extends StatelessWidget {
  final CountdownEvent event;

  const InviteShareBottomSheet({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shareLink = ShareLinkService.generateShareLink(event);
    final shareText = ShareLinkService.getShareableText(event);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveBorderRadius.lg(context)),
        ),
      ),
      padding: EdgeInsets.all(ResponsiveSpacing.xl(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 把手
          Center(
            child: Container(
              width: ResponsiveUtils.scaledSize(context, 40),
              height: ResponsiveUtils.scaledSize(context, 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(
                  ResponsiveBorderRadius.xs(context),
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveSpacing.lg(context)),

          // 标题
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveSpacing.sm(context)),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    ResponsiveBorderRadius.md(context),
                  ),
                ),
                child: Icon(
                  Icons.person_add,
                  color: theme.colorScheme.primary,
                  size: ResponsiveIconSize.base(context),
                ),
              ),
              SizedBox(width: ResponsiveSpacing.md(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '邀请共同关注',
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.xl(context),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      '分享链接，与好友一起倒数',
                      style: TextStyle(
                        fontSize: ResponsiveFontSize.md(context),
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSpacing.xl(context)),

          // 事件信息卡片
          Container(
            padding: EdgeInsets.all(ResponsiveSpacing.base(context)),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(
                ResponsiveBorderRadius.md(context),
              ),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: ResponsiveFontSize.lg(context),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                SizedBox(height: ResponsiveSpacing.sm(context)),
                Wrap(
                  spacing: ResponsiveSpacing.base(context),
                  runSpacing: ResponsiveSpacing.sm(context),
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: ResponsiveIconSize.xs(context),
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: ResponsiveSpacing.xs(context)),
                        Text(
                          '${event.targetDate.year}-${event.targetDate.month.toString().padLeft(2, '0')}-${event.targetDate.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: ResponsiveFontSize.md(context),
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveSpacing.sm(context),
                        vertical: ResponsiveSpacing.xs(context) / 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          ResponsiveBorderRadius.sm(context),
                        ),
                      ),
                      child: Text(
                        event.isCountUp
                            ? '已 ${event.daysRemaining.abs()} 天'
                            : (event.daysRemaining >= 0
                                ? '还有 ${event.daysRemaining} 天'
                                : '已过 ${event.daysRemaining.abs()} 天'),
                        style: TextStyle(
                          fontSize: ResponsiveFontSize.sm(context),
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveSpacing.lg(context)),

          // 分享链接区域
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveSpacing.md(context),
              vertical: ResponsiveSpacing.sm(context),
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(
                ResponsiveBorderRadius.sm(context),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    shareLink,
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.sm(context),
                      color: Colors.grey.shade700,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: ResponsiveSpacing.sm(context)),
                IconButton(
                  onPressed: () => _copyLink(context, shareLink),
                  icon: Icon(
                    Icons.copy,
                    size: ResponsiveIconSize.md(context),
                  ),
                  tooltip: '复制链接',
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveSpacing.xl(context)),

          // 分享方式
          Text(
            '选择分享方式',
            style: TextStyle(
              fontSize: ResponsiveFontSize.base(context),
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: ResponsiveSpacing.md(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildShareOption(
                context: context,
                icon: Icons.textsms,
                label: '短信',
                color: Colors.green,
                onTap: () => _shareVia(context, shareText, 'sms'),
              ),
              _buildShareOption(
                context: context,
                icon: Icons.chat_bubble,
                label: '微信',
                color: Colors.green.shade700,
                onTap: () => _shareVia(context, shareText, 'wechat'),
              ),
              _buildShareOption(
                context: context,
                icon: Icons.mail,
                label: '邮件',
                color: Colors.blue,
                onTap: () => _shareVia(context, shareText, 'email'),
              ),
              _buildShareOption(
                context: context,
                icon: Icons.more_horiz,
                label: '更多',
                color: Colors.grey.shade600,
                onTap: () => _shareVia(context, shareText, 'more'),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSpacing.xl(context)),

          // 提示信息
          Container(
            padding: EdgeInsets.all(ResponsiveSpacing.md(context)),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(
                ResponsiveBorderRadius.sm(context),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: ResponsiveIconSize.sm(context),
                  color: Colors.blue.shade700,
                ),
                SizedBox(width: ResponsiveSpacing.sm(context)),
                Expanded(
                  child: Text(
                    '对方需要安装"萤·倒数日"App才能打开链接并导入事件',
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.sm(context),
                      color: Colors.blue.shade700,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom +
                ResponsiveSpacing.sm(context),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final size = ResponsiveUtils.scaledSize(context, 52);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(
                ResponsiveBorderRadius.md(context),
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: ResponsiveIconSize.base(context),
            ),
          ),
          SizedBox(height: ResponsiveSpacing.xs(context)),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveFontSize.sm(context),
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  void _copyLink(BuildContext context, String link) {
    Clipboard.setData(ClipboardData(text: link));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('链接已复制'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareVia(BuildContext context, String text, String platform) {
    // 复制文本到剪贴板（通用方案）
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('分享内容已复制，请粘贴发送'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// 显示邀请分享底部弹窗
void showInviteShareSheet(BuildContext context, CountdownEvent event) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => InviteShareBottomSheet(event: event),
  );
}
