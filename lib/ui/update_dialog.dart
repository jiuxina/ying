import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/update_service.dart';
import 'download_source_dialog.dart';

enum _ReleaseAction { skip, copy, download }

/// 新版本发布详情弹窗：设置页手动检测与首页横幅共用。
///
/// [onSkip] 非空时提供“跳过此版本”操作。
Future<void> showReleaseDialog(
  BuildContext context,
  ReleaseInfo release, {
  VoidCallback? onSkip,
}) async {
  final action = await showDialog<_ReleaseAction>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('发现新版本 v${release.version}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _releaseDetails(dialogContext, release),
          ),
        ),
      ),
      actions: [
        if (onSkip != null)
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, _ReleaseAction.skip);
              onSkip();
            },
            child: const Text('跳过此版本'),
          ),
        TextButton.icon(
          onPressed: () => Navigator.pop(dialogContext, _ReleaseAction.copy),
          icon: const Icon(Icons.link_rounded, size: 18),
          label: const Text('复制发布页链接'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(dialogContext, _ReleaseAction.download),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('下载更新'),
        ),
      ],
    ),
  );
  if (!context.mounted || action == null) return;
  if (action == _ReleaseAction.copy) {
    await Clipboard.setData(ClipboardData(text: release.url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('发布页链接已复制')),
    );
  } else if (action == _ReleaseAction.download) {
    await showDownloadSourceDialog(context, release);
  }
}

List<Widget> _releaseDetails(BuildContext context, ReleaseInfo release) {
  final theme = Theme.of(context);
  final details = <Widget>[];
  final name = release.name?.trim() ?? '';
  final versionLike = RegExp(r'^v?\d+(\.\d+)*$');
  if (name.isNotEmpty && !versionLike.hasMatch(name)) {
    details.add(Text(name, style: theme.textTheme.titleMedium));
    details.add(const SizedBox(height: 8));
  }
  if (release.publishedAt != null) {
    details.add(
      Text(
        '发布于 ${DateFormat.yMMMd('zh_CN').format(release.publishedAt!)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    details.add(const SizedBox(height: 8));
  }
  final notes = release.notes?.trim() ?? '';
  if (notes.isNotEmpty) {
    details.add(
      Text(
        notes,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
    );
  } else if (details.isEmpty) {
    details.add(const Text('前往发布页查看更新内容与下载。'));
  }
  return details;
}
