import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../app_version.dart';
import '../models/app_settings.dart';
import '../models/countdown_event.dart';
import '../models/widget_font.dart';
import '../state/app_controller.dart';
import '../state/font_library_controller.dart';
import '../services/avatar_service.dart';
import '../services/avatar_image_provider.dart';
import '../services/background_image_provider.dart';
import '../services/photo_background_service.dart';
import '../services/font_library_service.dart';
import '../services/wallpaper_color_service.dart';
import '../utils/widget_content_utils.dart';
import '../models/widget_element_style.dart';
import 'font_library_page.dart';
import 'glass_ui.dart';
import 'permission_manage_section.dart';
import 'reminder_diagnostics_section.dart';
import 'sponsor_navigation.dart';
import 'update_dialog.dart';
import 'widget_element_presets.dart';
import 'widget_preview_section.dart';
import 'widget_style_presets.dart';

part 'settings_category_page.dart';
part 'settings_page_widgets.dart';

enum SettingsCategory {
  appearance,
  widget,
  notifications,
  permissions,
  data,
  updateAbout,
}

extension SettingsCategoryInfo on SettingsCategory {
  String get label => switch (this) {
    SettingsCategory.appearance => '外观与显示',
    SettingsCategory.widget => '桌面小部件',
    SettingsCategory.notifications => '通知与提醒',
    SettingsCategory.permissions => '权限管理',
    SettingsCategory.data => '数据管理',
    SettingsCategory.updateAbout => '更新与关于',
  };

  IconData get icon => switch (this) {
    SettingsCategory.appearance => Icons.palette_outlined,
    SettingsCategory.widget => Icons.widgets_outlined,
    SettingsCategory.notifications => Icons.notifications_outlined,
    SettingsCategory.permissions => Icons.shield_outlined,
    SettingsCategory.data => Icons.folder_copy_outlined,
    SettingsCategory.updateAbout => Icons.info_outline_rounded,
  };

  String get subtitle => switch (this) {
    SettingsCategory.appearance => '主题与动画',
    SettingsCategory.widget => '样式与内容',
    SettingsCategory.notifications => '权限与提醒',
    SettingsCategory.permissions => '通知、自启动与电池优化',
    SettingsCategory.data => '备份与清除',
    SettingsCategory.updateAbout => '版本与更新',
  };
}

/// 设置二级页：右上角入口进入后先看到分类菜单，
/// 点击分类进入对应的三级设置页。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const colorOptions = [
    (GlassPalette.blue, '蓝色'),
    (GlassPalette.indigo, '靛蓝'),
    (GlassPalette.pink, '粉色'),
    (GlassPalette.mint, '薄荷绿'),
    (Color(0xFF636366), '灰色'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    key: const ValueKey('settings-index-back'),
                    icon: Icons.arrow_back_rounded,
                    tooltip: '返回',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '设置',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 24),
              for (final category in SettingsCategory.values) ...[
                _CategoryCard(
                  category: category,
                  onTap: () => Navigator.push(
                    context,
                    GlassPageRoute(
                      builder: (context) =>
                          SettingsCategoryPage(category: category),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _exportData(BuildContext context, WidgetRef ref) async {
  final events = ref.read(appControllerProvider).events;
  if (events.isEmpty) {
    _showMessage(context, '还没有可导出的事件');
    return;
  }
  await Clipboard.setData(
    ClipboardData(text: CountdownEvent.encodeList(events)),
  );
  if (!context.mounted) return;
  _showMessage(context, '已导出 ${events.length} 个事件到剪贴板');
}

Future<void> _importData(BuildContext context, WidgetRef ref) async {
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  final source = data?.text;
  if (source == null || source.trim().isEmpty) {
    if (context.mounted) _showMessage(context, '剪贴板中没有可导入的数据');
    return;
  }
  List<CountdownEvent> incoming;
  try {
    incoming = CountdownEvent.decodeList(source);
  } catch (_) {
    if (context.mounted) {
      _showMessage(context, '剪贴板数据格式无效，请确认是萤导出的备份');
    }
    return;
  }
  if (incoming.isEmpty) {
    if (context.mounted) _showMessage(context, '备份中没有事件');
    return;
  }
  if (!context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('导入数据'),
      content: Text(
        '将从剪贴板导入 ${incoming.length} 个事件，与现有数据按 ID 合并（同 ID 以剪贴板为准）。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('导入'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await ref.read(appControllerProvider.notifier).importEvents(incoming);
  if (!context.mounted) return;
  _showMessage(context, '已导入 ${incoming.length} 个事件');
}

Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
  final count = ref.read(appControllerProvider).events.length;
  if (count == 0) {
    _showMessage(context, '当前没有事件');
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('清除所有事件？'),
      content: Text('将删除全部 $count 个事件及其提醒，可在 10 秒内撤销。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('清除'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await ref.read(appControllerProvider.notifier).clearAllEventsWithUndo();
}

Future<void> _copyLink(BuildContext context, String url) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) return;
  _showMessage(context, '链接已复制');
}

Future<void> _toggleWallpaperColors(
  BuildContext context,
  WidgetRef ref,
  AppSettings settings,
  bool enabled,
) async {
  final controller = ref.read(appControllerProvider.notifier);
  if (!enabled) {
    await controller.updateSettings(
      settings.copyWith(
        widgetWallpaperColor: -1,
        widgetWallpaperDarkColor: -1,
        widgetWallpaperTextColor: -1,
      ),
    );
    return;
  }
  final colors = await WallpaperColorService.fetch();
  if (colors == null) {
    if (context.mounted) {
      _showMessage(context, '无法读取壁纸颜色，请稍后再试');
    }
    return;
  }
  await controller.updateSettings(
    settings.copyWith(
      widgetWallpaperColor: colors.primary,
      widgetWallpaperDarkColor: colors.dark,
      widgetWallpaperTextColor: colors.text,
    ),
  );
}

Future<void> _pickBackgroundPhoto(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(appControllerProvider.notifier);
  final settings = ref.read(appControllerProvider).settings;
  try {
    final path = await pickAndCacheWidgetBackground(
      brightness: settings.widgetBackgroundBrightness,
      blur: settings.widgetBackgroundBlur,
    );
    await controller.updateSettings(
      settings.copyWith(
        widgetBackgroundPath: path,
        widgetBackgroundBrightness: settings.widgetBackgroundBrightness,
        widgetBackgroundBlur: settings.widgetBackgroundBlur,
      ),
    );
    if (context.mounted) {
      _showMessage(context, '照片已选择，可继续调整亮度与模糊');
      await _openBackgroundEditor(context, ref);
    }
  } on PhotoBackgroundException catch (error) {
    if (context.mounted) _showMessage(context, error.message);
  } catch (_) {
    if (context.mounted) _showMessage(context, '选择照片失败，请重试');
  }
}

Future<void> _recropBackgroundPhoto(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(appControllerProvider.notifier);
  final settings = ref.read(appControllerProvider).settings;
  try {
    final path = await recropWidgetBackground(
      brightness: settings.widgetBackgroundBrightness,
      blur: settings.widgetBackgroundBlur,
    );
    await controller.updateSettings(
      settings.copyWith(widgetBackgroundPath: path),
    );
    if (context.mounted) {
      _showMessage(context, '照片已重新裁切');
      await _openBackgroundEditor(context, ref);
    }
  } on PhotoBackgroundException catch (error) {
    if (error.message.contains('缺少源图')) {
      if (context.mounted) {
        await _pickBackgroundPhoto(context, ref);
      }
      return;
    }
    if (context.mounted) _showMessage(context, error.message);
  } catch (_) {
    if (context.mounted) _showMessage(context, '重新裁切失败，请重试');
  }
}

Future<void> _openBackgroundEditor(BuildContext context, WidgetRef ref) async {
  final settings = ref.read(appControllerProvider).settings;
  if (settings.widgetBackgroundPath.isEmpty) return;
  await showGlassBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _PhotoBackgroundEditorSheet(
      path: settings.widgetBackgroundPath,
      brightness: settings.widgetBackgroundBrightness,
      blur: settings.widgetBackgroundBlur,
    ),
  );
}

Future<void> _pickAvatar(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(appControllerProvider.notifier);
  try {
    final path = await pickAndCacheAvatar();
    await controller.updateSettings(
      ref.read(appControllerProvider).settings.copyWith(avatarPath: path),
    );
    if (context.mounted) _showMessage(context, '头像已更新');
  } on AvatarException catch (error) {
    if (context.mounted) _showMessage(context, error.message);
  } catch (_) {
    if (context.mounted) _showMessage(context, '选择头像失败，请重试');
  }
}

Future<void> _clearAvatar(BuildContext context, WidgetRef ref) async {
  await deleteCachedAvatar();
  await ref
      .read(appControllerProvider.notifier)
      .updateSettings(
        ref.read(appControllerProvider).settings.copyWith(avatarPath: ''),
      );
  if (context.mounted) _showMessage(context, '已恢复默认头像');
}

Future<void> _clearWidgetBackground(BuildContext context, WidgetRef ref) async {
  await deleteCachedWidgetBackground();
  await ref
      .read(appControllerProvider.notifier)
      .updateSettings(
        ref
            .read(appControllerProvider)
            .settings
            .copyWith(
              widgetBackgroundPath: '',
              widgetBackgroundBrightness: 1.0,
              widgetBackgroundBlur: 0.0,
            ),
      );
  if (context.mounted) _showMessage(context, '已清除照片背景');
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// 手动检测仓库 Release 更新，展示检查进度与最近一次结果。
class _UpdateCheckTile extends ConsumerStatefulWidget {
  const _UpdateCheckTile();

  @override
  ConsumerState<_UpdateCheckTile> createState() => _UpdateCheckTileState();
}

class _UpdateCheckTileState extends ConsumerState<_UpdateCheckTile> {
  bool _checking = false;
  String? _status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = _checking ? '正在检查…' : (_status ?? '查询最新发布');
    return Semantics(
      button: true,
      label: '检查更新',
      hint: subtitle,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _checking ? null : _check,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.system_update_alt_rounded,
                    color: scheme.onSurfaceVariant,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '立即检查',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_checking)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _status = null;
    });
    final result = await ref
        .read(appControllerProvider.notifier)
        .checkForUpdateNow();
    if (!mounted) return;
    setState(() => _checking = false);
    final release = result.release;
    if (result.hasError) {
      _finish(result.errorMessage ?? '检查更新失败，请稍后再试');
      return;
    }
    if (release == null) {
      _finish('仓库暂无发布');
      return;
    }
    if (result.isNewer) {
      setState(() => _status = '发现新版本 v${release.version}');
      await showReleaseDialog(
        context,
        release,
        onSkip: () => ref
            .read(appControllerProvider.notifier)
            .dismissUpdateRelease(skipVersion: true),
      );
      return;
    }
    _finish('已是最新版本');
  }

  void _finish(String message) {
    setState(() => _status = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
