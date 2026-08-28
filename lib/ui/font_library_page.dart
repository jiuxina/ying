import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import '../models/widget_font.dart';
import '../services/font_catalog_service.dart';
import '../services/font_library_service.dart';
import '../state/app_controller.dart';
import '../state/font_library_controller.dart';
import 'glass_ui.dart';

typedef CatalogFetcher = Future<WidgetFontCatalog> Function();
typedef LocalFontPicker = Future<String?> Function();
typedef FontDownloader =
    Future<Uint8List> Function(
      WidgetFontCatalog catalog,
      WidgetFontCatalogEntry entry,
    );
typedef FontInstaller =
    Future<WidgetFontAsset> Function(
      WidgetFontCatalogEntry entry,
      Uint8List bytes,
    );

class FontLibraryPage extends ConsumerStatefulWidget {
  const FontLibraryPage({
    super.key,
    this.catalogFetcher,
    this.localFontPicker,
    this.fontDownloader,
    this.fontInstaller,
    this.fontDirectory,
  });

  final CatalogFetcher? catalogFetcher;
  final LocalFontPicker? localFontPicker;
  final FontDownloader? fontDownloader;
  final FontInstaller? fontInstaller;
  final Directory? fontDirectory;

  @override
  ConsumerState<FontLibraryPage> createState() => _FontLibraryPageState();
}

class _FontLibraryPageState extends ConsumerState<FontLibraryPage> {
  WidgetFontCatalog? _catalog;
  String? _error;
  bool _loading = true;
  final Set<String> _downloading = {};

  @override
  void initState() {
    super.initState();
    unawaited(_loadCatalog());
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = await (widget.catalogFetcher ?? fetchFontCatalog)();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error is FontCatalogException
            ? error.message
            : '字体清单加载失败，请稍后再试';
      });
    }
  }

  AppSettings _currentSettings() => ref.read(appControllerProvider).settings;

  Future<void> _download(WidgetFontCatalogEntry entry) async {
    final catalog = _catalog;
    if (catalog == null) return;
    setState(() => _downloading.add(entry.id));
    try {
      final bytes = await (widget.fontDownloader ?? downloadFontBytes)(
        catalog,
        entry,
      );
      final installer = widget.fontInstaller ??
          (entry, bytes) => FontLibraryService.installCatalogFont(
            entry,
            bytes,
            dir: widget.fontDirectory,
          );
      final asset = await installer(entry, bytes);
      await ref.read(fontLibraryProvider.notifier).refresh();
      if (!mounted) return;
      _showMessage('已下载“${asset.name}”');
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        error is FontCatalogException ? error.message : '字体下载失败，请稍后再试',
      );
    } finally {
      if (mounted) {
        setState(() => _downloading.remove(entry.id));
      }
    }
  }

  Future<void> _pickLocalFont() async {
    final path = await (widget.localFontPicker ?? _pickFontFile)();
    if (path == null || !mounted) return;
    final kind = await _chooseImportKind();
    if (kind == null || !mounted) return;
    try {
      final asset = await FontLibraryService.installLocalFont(
        source: File(path),
        kind: kind,
        name: File(path).uri.pathSegments.last,
        dir: widget.fontDirectory,
      );
      await ref.read(fontLibraryProvider.notifier).refresh();
      if (!mounted) return;
      _showMessage('已导入“${asset.name}”');
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        error is FontCatalogException ? error.message : '导入字体失败，请重试',
      );
    }
  }

  Future<String?> _pickFontFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['ttf', 'otf'],
      withData: false,
    );
    final files = result?.files ?? const [];
    final file = files.length == 1 ? files.single : null;
    return file?.path;
  }

  Future<WidgetFontKind?> _chooseImportKind() async {
    return showGlassBottomSheet<WidgetFontKind>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: GlassSurface(
          radius: 20,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GlassSectionTitle(title: '导入到', subtitle: '选择这个字体的用途'),
              const SizedBox(height: 14),
              for (final kind in WidgetFontKind.values) ...[
                ListTile(
                  leading: const Icon(Icons.text_fields_rounded),
                  title: Text(widgetFontKindLabel(kind)),
                  onTap: () => Navigator.pop(sheetContext, kind),
                ),
                if (kind != WidgetFontKind.both) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(WidgetFontAsset asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除字体？'),
        content: Text('将删除“${asset.name}”，已应用的字体区域会恢复为系统字体。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    var settings = _currentSettings();
    if (settings.widgetFontFamily == asset.selection) {
      settings = settings.copyWith(
        widgetFontFamily: 'system',
        widgetDigitFontPath: '',
      );
    }
    if (settings.widgetTextFontFamily == asset.selection) {
      settings = settings.copyWith(
        widgetTextFontFamily: 'system',
        widgetTextFontPath: '',
      );
    }
    await ref.read(appControllerProvider.notifier).updateSettings(settings);
    await FontLibraryService.removeFont(asset, dir: widget.fontDirectory);
    await ref.read(fontLibraryProvider.notifier).refresh();
    if (!mounted) return;
    _showMessage('已删除“${asset.name}”');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Scaffold(
      body: LiquidBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              wide ? 34 : 20,
              12,
              wide ? 34 : 20,
              40,
            ),
            children: [
              Row(
                children: [
                  GlassIconButton(
                    key: const ValueKey('font-library-back'),
                    icon: Icons.arrow_back_rounded,
                    tooltip: '返回',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '字体库',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '在线字体按需下载，本地 TTF/OTF 可导入；下载或导入后在「字体」设置中选择应用。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              GlassReveal(
                slide: false,
                child: _ImportCard(
                  onTap: _pickLocalFont,
                ),
              ),
              const SizedBox(height: 16),
              GlassReveal(
                delay: const Duration(milliseconds: 60),
                slide: false,
                child: GlassSurface(
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GlassSectionTitle(
                        title: '在线候选',
                        subtitle: '免费下载',
                      ),
                      const SizedBox(height: 12),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator.adaptive(),
                          ),
                        )
                      else if (_error != null) ...[
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _loadCatalog,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('重试'),
                          ),
                        ),
                      ] else if (_catalog == null || _catalog!.fonts.isEmpty)
                        Text(
                          '暂无在线字体',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        )
                      else
                        for (final entry in _catalog!.fonts) ...[
                          if (entry != _catalog!.fonts.first)
                            const _FontDivider(),
                          _CatalogFontTile(
                            entry: entry,
                            installed: _installedFor(entry),
                            downloading: _downloading.contains(entry.id),
                            onDownload: () => unawaited(_download(entry)),
                            onDelete: _delete,
                          ),
                        ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GlassReveal(
                delay: const Duration(milliseconds: 120),
                slide: false,
                child: _InstalledFontsSection(
                  installed: ref
                      .watch(fontLibraryProvider)
                      .installed
                      .where((asset) => asset.source == WidgetFontSource.local)
                      .toList(),
                  onDelete: _delete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  WidgetFontAsset? _installedFor(WidgetFontCatalogEntry entry) {
    final installed = ref.watch(fontLibraryProvider).installed;
    for (final asset in installed) {
      if (asset.id == entry.id && asset.source == WidgetFontSource.catalog) {
        return asset;
      }
    }
    return null;
  }

}

class _ImportCard extends StatelessWidget {
  const _ImportCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassSurface(
      radius: 20,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      haptic: GlassHaptic.selectionClick,
      child: Row(
        children: [
          Icon(
            Icons.upload_file_outlined,
            color: scheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '导入本地字体',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '选择 TTF / OTF 文件导入',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: scheme.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _CatalogFontTile extends StatelessWidget {
  const _CatalogFontTile({
    required this.entry,
    required this.installed,
    required this.downloading,
    required this.onDownload,
    required this.onDelete,
  });

  final WidgetFontCatalogEntry entry;
  final WidgetFontAsset? installed;
  final bool downloading;
  final VoidCallback onDownload;
  final ValueChanged<WidgetFontAsset> onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.text_fields_rounded, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    widgetFontKindLabel(entry.kind),
                    _sizeLabel(entry.bytes),
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  AnimatedSwitcher(
                    duration: motionDuration(context, AppMotion.state),
                    switchInCurve: AppMotion.enter,
                    switchOutCurve: AppMotion.exit,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: AppMotion.enter,
                          ),
                        ),
                        child: child,
                      ),
                    ),
                    child: downloading
                        ? const SizedBox(
                            key: ValueKey('font-downloading'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : installed != null
                        ? Row(
                            key: ValueKey('font-downloaded-${entry.id}'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '已下载',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          )
                        : FilledButton.icon(
                            key: ValueKey('font-download-${entry.id}'),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              onDownload();
                            },
                            icon: const Icon(
                              Icons.download_rounded,
                              size: 16,
                            ),
                            label: const Text('下载'),
                          ),
                  ),
                  if (installed != null)
                    IconButton(
                      key: ValueKey('font-delete-${entry.id}'),
                      tooltip: '删除',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onDelete(installed!);
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                ],
              ),
              if (entry.licenseName != null) ...[
                const SizedBox(height: 6),
                Text(
                  '许可：${entry.licenseName}',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _sizeLabel(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).round()} KB';
  }
}

class _InstalledFontsSection extends StatelessWidget {
  const _InstalledFontsSection({
    required this.installed,
    required this.onDelete,
  });

  final List<WidgetFontAsset> installed;
  final ValueChanged<WidgetFontAsset> onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassSurface(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlassSectionTitle(title: '本地已导入'),
          const SizedBox(height: 10),
          if (installed.isEmpty)
            Text(
              '还没有导入的字体',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            )
          else
            for (final asset in installed) ...[
              if (asset != installed.first) const _FontDivider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_zip_outlined),
                title: Text(asset.name),
                subtitle: Text(widgetFontKindLabel(asset.kind)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '删除',
                      onPressed: () => onDelete(asset),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _FontDivider extends StatelessWidget {
  const _FontDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Theme.of(context).dividerColor);
  }
}
