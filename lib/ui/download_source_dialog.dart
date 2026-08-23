import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/update_downloader.dart';
import '../services/update_service.dart';
import '../services/update_sources.dart';

class DownloadOutcome {
  const DownloadOutcome({this.result, this.error});

  final UpdateDownloadResult? result;
  final String? error;
}

Future<void> showDownloadSourceDialog(
  BuildContext context,
  ReleaseInfo release,
) async {
  final sources = updateSourcesFor(release);
  if (sources.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('当前版本没有可下载的 APK')),
    );
    return;
  }
  final source = await showDialog<UpdateSource>(
    context: context,
    builder: (_) => DownloadSourceDialog(release: release, sources: sources),
  );
  if (source == null || !context.mounted) return;
  await runUpdateDownload(context, release, source);
}

class DownloadSourceDialog extends StatefulWidget {
  const DownloadSourceDialog({
    super.key,
    required this.release,
    required this.sources,
  });

  final ReleaseInfo release;
  final List<UpdateSource> sources;

  @override
  State<DownloadSourceDialog> createState() => _DownloadSourceDialogState();
}

class _DownloadSourceDialogState extends State<DownloadSourceDialog> {
  UpdateSource? _selected;
  bool _measuring = true;
  final Map<String, SourceSpeedResult> _results = {};

  @override
  void initState() {
    super.initState();
    _selected = widget.sources.first;
    unawaited(_measure());
  }

  Future<void> _measure() async {
    final results = await measureSourceSpeeds(widget.release);
    if (!mounted) return;
    setState(() {
      _measuring = false;
      for (final result in results) {
        _results[result.source.id] = result;
      }
      _selected = bestSource(results) ?? _selected;
    });
  }

  String _statusFor(UpdateSource source) {
    if (_measuring) return '测速中…';
    final result = _results[source.id];
    if (result == null) return '未测速';
    if (!result.success) return result.error ?? '连接失败';
    final best = _results.values
        .where((value) => value.success)
        .map((value) => value.duration)
        .reduce((a, b) => a < b ? a : b);
    final fastest = result.duration == best ? ' · 最快' : '';
    return '${result.duration.inMilliseconds} ms$fastest';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text('下载 v${widget.release.version}'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              '正在测速并默认选择最快的下载源，也可以手动切换。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final source in widget.sources)
              ListTile(
                key: ValueKey('update-source-${source.id}'),
                onTap: () {
                  setState(() {
                    _selected = widget.sources.firstWhere(
                      (candidate) => candidate.id == source.id,
                    );
                  });
                },
                leading: Icon(
                  _selected?.id == source.id
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                ),
                title: Text(source.label),
                subtitle: Text(_statusFor(source)),
                trailing: _measuring
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _results[source.id]?.success == true
                    ? Icon(
                        Icons.check_circle_outline_rounded,
                        color: scheme.primary,
                        size: 18,
                      )
                    : Icon(
                        Icons.error_outline_rounded,
                        color: scheme.error,
                        size: 18,
                      ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: _selected == null
              ? null
              : () => Navigator.pop(context, _selected),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('下载'),
        ),
      ],
    );
  }
}

Future<void> runUpdateDownload(
  BuildContext context,
  ReleaseInfo release,
  UpdateSource source,
) async {
  final outcome = await showDialog<DownloadOutcome>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DownloadProgressDialog(
      release: release,
      source: source,
    ),
  );
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  if (outcome?.error != null) {
    messenger.showSnackBar(SnackBar(content: Text(outcome!.error!)));
    return;
  }
  final result = outcome?.result;
  if (result == null) {
    messenger.showSnackBar(const SnackBar(content: Text('已取消下载')));
    return;
  }
  await _requestInstall(context, result.file);
}

Future<void> _requestInstall(BuildContext context, File file) async {
  final messenger = ScaffoldMessenger.of(context);
  const channel = MethodChannel('ying/installer');
  try {
    final response = await channel.invokeMethod<Map<Object?, Object?>>(
      'installApk',
      {'path': file.path},
    );
    if (!context.mounted) return;
    final permissionRequired = response?['permissionRequired'] == true;
    if (!permissionRequired) {
      messenger.showSnackBar(
        const SnackBar(content: Text('更新包已下载，正在安装')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('需要安装权限'),
        content: const Text('请允许萤安装未知应用，之后系统会继续完成更新安装。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('稍后'),
          ),
          FilledButton(
            onPressed: () async {
              await channel.invokeMethod<void>('openInstallPermissionSettings');
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('去授权'),
          ),
        ],
      ),
    );
  } on MissingPluginException {
    messenger.showSnackBar(
      SnackBar(content: Text('更新包已下载：${file.path}，请手动安装')),
    );
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text('更新包已下载：${file.path}，请手动安装')),
    );
  }
}

class _DownloadProgressDialog extends StatefulWidget {
  const _DownloadProgressDialog({
    required this.release,
    required this.source,
  });

  final ReleaseInfo release;
  final UpdateSource source;

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  int _received = 0;
  int? _total;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    unawaited(_download());
  }

  Future<void> _download() async {
    final outcome = await downloadUpdate(
      uri: widget.source.resolve(widget.release),
      version: widget.release.version,
      abi: 'apk',
      onProgress: (received, total) {
        if (mounted) {
          setState(() {
            _received = received;
            _total = total;
          });
        }
      },
      shouldCancel: () => _cancelled,
    )
        .then<DownloadOutcome>(
          (result) => DownloadOutcome(result: result),
        )
        .catchError(
          (Object error) => DownloadOutcome(
            error: error is UpdateDownloadException
                ? error.message
                : '下载失败，请稍后重试',
          ),
        );
    if (!mounted) return;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total == null || _total == 0
        ? null
        : (_received / _total!).clamp(0.0, 1.0);
    final percent = progress == null
        ? ''
        : ' ${(progress * 100).round()}%';
    final sizeText = _total == null
        ? '${_received ~/ 1024} KB'
        : '${_received ~/ 1024} / ${_total! ~/ 1024} KB';
    return AlertDialog(
      title: const Text('正在下载更新'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.source.label} · $sizeText$percent'),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _cancelled
              ? null
              : () => setState(() => _cancelled = true),
          child: Text(_cancelled ? '正在取消…' : '取消'),
        ),
      ],
    );
  }
}
