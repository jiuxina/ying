import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/countdown_event.dart';
import '../models/shared_event.dart';
import '../services/qr_code_service.dart';
import '../utils/responsive_utils.dart';

/// QR码显示对话框
class QRCodeDialog extends StatefulWidget {
  final CountdownEvent event;
  final SharedEventMetadata? metadata;
  final List<CountdownEvent>? multipleEvents;
  final FamilyShareGroup? familyGroup;
  final String? deviceId;
  final String? displayName;
  final bool showSharingOptions;

  const QRCodeDialog({
    super.key,
    required this.event,
    this.metadata,
    this.multipleEvents,
    this.familyGroup,
    this.deviceId,
    this.displayName,
    this.showSharingOptions = true,
  });

  @override
  State<QRCodeDialog> createState() => _QRCodeDialogState();
}

class _QRCodeDialogState extends State<QRCodeDialog> {
  Uint8List? _qrCodeBytes;
  bool _isLoading = true;
  String? _qrContent;
  QRDataType _shareType = QRDataType.singleEvent;

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  Future<void> _generateQRCode() async {
    setState(() => _isLoading = true);

    try {
      QRCodeData qrData;

      // 根据上下文决定生成哪种类型的QR码
      if (widget.metadata != null && widget.deviceId != null) {
        // 共享事件QR码
        _shareType = QRDataType.sharedEvent;
        qrData = QRCodeService.generateSharedEventQR(
          event: widget.event,
          metadata: widget.metadata!,
          deviceId: widget.deviceId!,
          displayName: widget.displayName ?? '用户',
        );
      } else if (widget.familyGroup != null && widget.deviceId != null) {
        // 家庭组邀请QR码
        _shareType = QRDataType.familyGroup;
        qrData = QRCodeService.generateFamilyGroupInviteQR(
          group: widget.familyGroup!,
          deviceId: widget.deviceId!,
          displayName: widget.displayName ?? '用户',
        );
      } else if (widget.multipleEvents != null && widget.multipleEvents!.isNotEmpty) {
        // 多事件QR码
        _shareType = QRDataType.multipleEvents;
        qrData = QRCodeService.generateMultipleEventsQR(widget.multipleEvents!);
      } else {
        // 单事件QR码
        _shareType = QRDataType.singleEvent;
        qrData = QRCodeService.generateSingleEventQR(widget.event);
      }

      _qrContent = qrData.encode();

      // 生成QR码图像
      final theme = Theme.of(context);
      final bytes = await QRCodeService.generateQRCodeImage(
        data: _qrContent!,
        size: 280,
        foregroundColor: theme.brightness == Brightness.dark
            ? ui.Color(0xFFFFFFFF)
            : ui.Color(0xFF000000),
        backgroundColor: theme.brightness == Brightness.dark
            ? ui.Color(0xFF1E1E1E)
            : ui.Color(0xFFFFFFFF),
      );

      if (mounted) {
        setState(() {
          _qrCodeBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('QR Code generation error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.xl(context)),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveUtils.scaledSize(context, 360),
        ),
        padding: EdgeInsets.all(ResponsiveSpacing.xl(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                    Icons.qr_code_2,
                    color: theme.colorScheme.primary,
                    size: ResponsiveIconSize.lg(context),
                  ),
                ),
                SizedBox(width: ResponsiveSpacing.md(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDialogTitle(),
                        style: TextStyle(
                          fontSize: ResponsiveFontSize.xl(context),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _getDialogSubtitle(),
                        style: TextStyle(
                          fontSize: ResponsiveFontSize.sm(context),
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveSpacing.xl(context)),

            // QR码显示区域
            Container(
              padding: EdgeInsets.all(ResponsiveSpacing.lg(context)),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(ResponsiveBorderRadius.lg(context)),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 280,
                      height: 280,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : _qrCodeBytes != null
                      ? Image.memory(
                          _qrCodeBytes!,
                          width: 280,
                          height: 280,
                          fit: BoxFit.contain,
                        )
                      : SizedBox(
                          width: 280,
                          height: 280,
                          child: Center(
                            child: Icon(
                              Icons.error_outline,
                              size: 64,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
            ),
            SizedBox(height: ResponsiveSpacing.md(context)),

            // 事件信息
            Container(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title,
                          style: TextStyle(
                            fontSize: ResponsiveFontSize.base(context),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: ResponsiveSpacing.xs(context)),
                        Text(
                          _getEventSubtitle(),
                          style: TextStyle(
                            fontSize: ResponsiveFontSize.sm(context),
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (widget.metadata != null) ...[
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
                            '${widget.metadata!.memberCount}人',
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
                ],
              ),
            ),

            // 分享选项
            if (widget.showSharingOptions) ...[
              SizedBox(height: ResponsiveSpacing.lg(context)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: Icon(
                        Icons.copy,
                        size: ResponsiveIconSize.sm(context),
                      ),
                      label: const Text('复制链接'),
                    ),
                  ),
                  SizedBox(width: ResponsiveSpacing.md(context)),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _shareViaSystem,
                      icon: Icon(
                        Icons.share,
                        size: ResponsiveIconSize.sm(context),
                      ),
                      label: const Text('分享'),
                    ),
                  ),
                ],
              ),
            ],

            // 关闭按钮
            SizedBox(height: ResponsiveSpacing.md(context)),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      ),
    );
  }

  String _getDialogTitle() {
    switch (_shareType) {
      case QRDataType.singleEvent:
        return '分享事件';
      case QRDataType.multipleEvents:
        return '分享多个事件';
      case QRDataType.sharedEvent:
        return '协作分享';
      case QRDataType.familyGroup:
        return '家庭共享邀请';
    }
  }

  String _getDialogSubtitle() {
    switch (_shareType) {
      case QRDataType.singleEvent:
        return '扫码即可导入此事件';
      case QRDataType.multipleEvents:
        return '扫码即可批量导入';
      case QRDataType.sharedEvent:
        return '扫码加入协作，共同关注';
      case QRDataType.familyGroup:
        return '扫码加入家庭共享';
    }
  }

  String _getEventSubtitle() {
    final days = widget.event.daysRemaining;
    if (widget.multipleEvents != null && widget.multipleEvents!.length > 1) {
      return '共 ${widget.multipleEvents!.length} 个事件';
    }
    if (widget.event.isCountUp) {
      return '已 ${days.abs()} 天';
    }
    return days >= 0 ? '还有 $days 天' : '已过 ${days.abs()} 天';
  }

  void _copyToClipboard() {
    if (_qrContent != null) {
      Clipboard.setData(ClipboardData(text: _qrContent!));
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('分享内容已复制'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareViaSystem() {
    // 使用系统分享功能
    // TODO: 集成 share_plus
    _copyToClipboard();
  }
}

/// 显示QR码对话框
Future<void> showQRCodeDialog(
  BuildContext context, {
  required CountdownEvent event,
  SharedEventMetadata? metadata,
  List<CountdownEvent>? multipleEvents,
  FamilyShareGroup? familyGroup,
  String? deviceId,
  String? displayName,
}) {
  return showDialog(
    context: context,
    builder: (context) => QRCodeDialog(
      event: event,
      metadata: metadata,
      multipleEvents: multipleEvents,
      familyGroup: familyGroup,
      deviceId: deviceId,
      displayName: displayName,
    ),
  );
}
