import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../app_version.dart';
import '../models/app_settings.dart';
import '../models/countdown_event.dart';
import '../state/app_controller.dart';
import '../services/photo_background_service.dart';
import '../services/wallpaper_color_service.dart';
import '../utils/widget_content_utils.dart';
import 'glass_ui.dart';
import 'reminder_diagnostics_section.dart';
import 'update_dialog.dart';
import 'widget_preview_section.dart';
import 'widget_style_presets.dart';

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
    final appState = ref.watch(appControllerProvider);
    final settings = appState.settings;
    final controller = ref.read(appControllerProvider.notifier);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width >= 760 ? 34 : 20,
        28,
        20,
        132,
      ),
      children: [
        Text(
          '设置',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '让萤更像你。',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 26),
        _Section(
          title: '外观',
          child: Column(
            children: [
              _ThemePicker(
                value: settings.themeMode,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(themeMode: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.layers_clear_rounded,
                title: '减少透明度',
                subtitle: '使用高对比度不透明表面，减少模糊负担',
                value: settings.reduceTransparency,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(reduceTransparency: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.motion_photos_off_rounded,
                title: '减少动画',
                subtitle: '关闭界面过渡，并始终跟随系统减少动态效果',
                value: settings.reduceMotion,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(reduceMotion: value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '小部件样式',
          subtitle: '预设、主色与文字缩放',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widgetStylePresets
                    .map(
                      (preset) => _StyleOption(
                        style: preset.$1,
                        label: preset.$2,
                        icon: preset.$3,
                        selected: settings.widgetStyle == preset.$1,
                        onTap: () => controller.updateSettings(
                          settings.copyWith(widgetStyle: preset.$1),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const _InsetDivider(),
              Wrap(
                spacing: 13,
                runSpacing: 13,
                children: colorOptions
                    .map(
                      (option) => _ColorButton(
                        color: option.$1,
                        label: option.$2,
                        selected: settings.widgetColor == option.$1.toARGB32(),
                        onTap: () => controller.updateSettings(
                          settings.copyWith(widgetColor: option.$1.toARGB32()),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const _InsetDivider(),
              Semantics(
                label: '小部件文字大小',
                value: '${(settings.widgetFontScale * 100).round()}%',
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    inactiveTrackColor: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    thumbColor: Theme.of(context).colorScheme.primary,
                    overlayColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.12),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 9,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 20,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.text_decrease_rounded, size: 19),
                      Expanded(
                        child: Slider(
                          value: settings.widgetFontScale,
                          min: 0.85,
                          max: 1.3,
                          divisions: 3,
                          onChanged: (value) => controller.updateSettings(
                            settings.copyWith(widgetFontScale: value),
                          ),
                        ),
                      ),
                      const Icon(Icons.text_increase_rounded, size: 23),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '小部件背景',
          subtitle: '壁纸取色与相册背景',
          child: Column(
            children: [
              _SettingSwitch(
                icon: Icons.wallpaper_rounded,
                title: '跟随壁纸颜色',
                subtitle: '读取当前壁纸主色并自动生成对比文字色',
                value: settings.widgetWallpaperColor != -1,
                onChanged: (value) => unawaited(
                  _toggleWallpaperColors(context, ref, settings, value),
                ),
              ),
              const _InsetDivider(),
              _SettingsActionTile(
                icon: Icons.add_photo_alternate_outlined,
                title: '选择照片背景',
                subtitle: settings.widgetBackgroundPath.isEmpty
                    ? '从相册挑选一张作为小部件背景'
                    : '已设置照片背景，点击可重新选择',
                onTap: () => unawaited(_pickBackgroundPhoto(context, ref)),
              ),
              if (settings.widgetBackgroundPath.isNotEmpty) ...[
                const _InsetDivider(),
                _SettingsActionTile(
                  icon: Icons.hide_image_outlined,
                  title: '清除照片背景',
                  subtitle: '恢复为样式默认背景',
                  onTap: () => unawaited(_clearWidgetBackground(context, ref)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '小部件内容',
          subtitle: '选择桌面卡片显示的字段',
          child: Column(
            children: [
              _SettingSwitch(
                icon: Icons.tag_rounded,
                title: '分类标签',
                subtitle: '在桌面小部件中显示分类',
                value: settings.widgetShowCategory,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetShowCategory: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.notes_rounded,
                title: '事件备注',
                subtitle: '显示一行简短备注',
                value: settings.widgetShowNote,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetShowNote: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.emoji_emotions_outlined,
                title: '事件图标',
                subtitle: '显示事件 Emoji 图标',
                value: settings.widgetShowIcon,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetShowIcon: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.timer_outlined,
                title: '精确到秒',
                subtitle: '倒计时精确到时分秒',
                value: settings.widgetShowPreciseTime,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetShowPreciseTime: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.calendar_month_outlined,
                title: '农历与星期',
                subtitle: '显示当天农历与星期',
                value: settings.widgetShowLunarWeek,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetShowLunarWeek: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.donut_small_rounded,
                title: '进度百分比',
                subtitle: '从创建日到目标日的完成进度',
                value: settings.widgetShowProgress,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetShowProgress: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.visibility_off_outlined,
                title: '神秘模式',
                subtitle: '隐藏具体数字，只显示蜡烛与“快到了”',
                value: settings.widgetMysteryMode,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetMysteryMode: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.format_quote_outlined,
                title: '每日一句',
                subtitle: '备注与内置句子按天轮播',
                value: settings.widgetQuoteMode,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetQuoteMode: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.local_fire_department_outlined,
                title: '临近高亮',
                subtitle: '7 天、3 天、1 天内自动切换强调色与文案',
                value: settings.widgetUrgentHighlight,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetUrgentHighlight: value),
                ),
              ),
              const _InsetDivider(),
              _ChoiceSetting(
                icon: Icons.text_fields_rounded,
                title: '单位文案',
                subtitle: '选择“还有、只剩、距离、已经、约 X 周”等预设',
                options: widgetUnitPresetOptions,
                selected: (
                  settings.widgetUnitText,
                  widgetUnitPresetOptions
                      .firstWhere(
                        (option) => option.$1 == settings.widgetUnitText,
                        orElse: () => widgetUnitPresetOptions.first,
                      )
                      .$2,
                ),
                onSelected: (option) => controller.updateSettings(
                  settings.copyWith(widgetUnitText: option.$1),
                ),
              ),
              const _InsetDivider(),
              _ChoiceSetting(
                icon: Icons.pin_outlined,
                title: '数字字体',
                subtitle: '切换数字区域的字体风格',
                options: widgetFontOptions,
                selected: (
                  settings.widgetFontFamily,
                  widgetFontOptions
                      .firstWhere(
                        (option) => option.$1 == settings.widgetFontFamily,
                        orElse: () => widgetFontOptions.first,
                      )
                      .$2,
                ),
                onSelected: (option) => controller.updateSettings(
                  settings.copyWith(widgetFontFamily: option.$1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '小部件列表',
          subtitle: '在一个小部件里滚动浏览所有事件',
          child: Column(
            children: [
              _SettingSwitch(
                icon: Icons.view_agenda_outlined,
                title: '事件列表模式',
                subtitle: '显示全部事件的滚动列表，关闭后回到单事件卡片',
                value: settings.widgetListMode,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetListMode: value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ReminderDiagnosticsSection(events: appState.events),
        const SizedBox(height: 16),
        WidgetPreviewSection(events: appState.events, settings: settings),
        const SizedBox(height: 16),
        _Section(
          title: '检查更新',
          subtitle: '当前版本 v$appVersion',
          child: Column(
            children: [
              _SettingSwitch(
                icon: Icons.system_update_outlined,
                title: '自动检测更新',
                subtitle: '启动后每天最多向 GitHub 仓库查询一次最新发布',
                value: settings.autoCheckUpdate,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(autoCheckUpdate: value),
                ),
              ),
              const _InsetDivider(),
              const _UpdateCheckTile(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '数据管理',
          subtitle: '导出、导入或清除本地数据',
          child: Column(
            children: [
              _SettingsActionTile(
                icon: Icons.upload_file_outlined,
                title: '导出数据',
                subtitle: '将全部事件复制到剪贴板，可粘贴到备忘录备份',
                onTap: () => _exportData(context, ref),
              ),
              const _InsetDivider(),
              _SettingsActionTile(
                icon: Icons.download_outlined,
                title: '导入数据',
                subtitle: '从剪贴板读取备份并合并到当前列表',
                onTap: () => _importData(context, ref),
              ),
              const _InsetDivider(),
              _SettingsActionTile(
                icon: Icons.delete_sweep_outlined,
                title: '清除所有事件',
                subtitle: '删除全部事件及其提醒，可撤销',
                onTap: () => _clearAllData(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '关于',
          child: Column(
            children: [
              _SettingsActionTile(
                icon: Icons.lightbulb_outline_rounded,
                title: '萤 $appVersion',
                subtitle: '本地优先的倒数日 · 正计时',
              ),
              const _InsetDivider(),
              _SettingsActionTile(
                icon: Icons.privacy_tip_outlined,
                title: '数据仅保存在本机',
                subtitle: '无账号、无服务端，删除应用前请先导出备份',
              ),
              const _InsetDivider(),
              _SettingsActionTile(
                icon: Icons.code_rounded,
                title: 'github.com/jiuxina/ying',
                subtitle: '开源仓库，欢迎 Star 与 Issues 反馈',
                onTap: () => _copyLink(context, 'https://github.com/jiuxina/ying'),
              ),
            ],
          ),
        ),
      ],
    );
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

  Future<void> _pickBackgroundPhoto(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = ref.read(appControllerProvider.notifier);
    final settings = ref.read(appControllerProvider).settings;
    try {
      final path = await pickAndCacheWidgetBackground();
      await controller.updateSettings(
        settings.copyWith(widgetBackgroundPath: path),
      );
      if (context.mounted) _showMessage(context, '照片背景已更新');
    } on PhotoBackgroundException catch (error) {
      if (context.mounted) _showMessage(context, error.message);
    } catch (_) {
      if (context.mounted) _showMessage(context, '选择照片失败，请重试');
    }
  }

  Future<void> _clearWidgetBackground(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await deleteCachedWidgetBackground();
    await ref.read(appControllerProvider.notifier).updateSettings(
      ref
          .read(appControllerProvider)
          .settings
          .copyWith(widgetBackgroundPath: ''),
    );
    if (context.mounted) _showMessage(context, '已清除照片背景');
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
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
    final subtitle = _checking ? '正在检查…' : (_status ?? '查询 GitHub 仓库的最新发布');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassSectionTitle(title: title, subtitle: subtitle),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _ThemeOption(
              icon: Icons.auto_awesome_rounded,
              label: '自动',
              selected: value == ThemeMode.system,
              onTap: () => onChanged(ThemeMode.system),
            ),
            _ThemeOption(
              icon: Icons.light_mode_rounded,
              label: '浅色',
              selected: value == ThemeMode.light,
              onTap: () => onChanged(ThemeMode.light),
            ),
            _ThemeOption(
              icon: Icons.dark_mode_rounded,
              label: '深色',
              selected: value == ThemeMode.dark,
              onTap: () => onChanged(ThemeMode.dark),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '主题：$label',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: motionDuration(
                context,
                const Duration(milliseconds: 180),
              ),
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? scheme.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              // 外层 Semantics 已提供完整 label，排除内部文字避免重复播报。
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: selected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StyleOption extends StatelessWidget {
  const _StyleOption({
    required this.style,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final WidgetStyle style;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '小部件样式：$label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: motionDuration(
              context,
              const Duration(milliseconds: 180),
            ),
            constraints: const BoxConstraints(minHeight: 46, minWidth: 76),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.38)
                    : scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: selected
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '主色调：$label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: motionDuration(
              context,
              const Duration(milliseconds: 180),
            ),
            // 48x48 触控热区，内部色块 36px。
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? color : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: value,
      label: title,
      hint: subtitle,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(14),
          // 整行可点，扩大触控区域；最小高度保证 48px。
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  GlassSwitch(value: value, onChanged: onChanged),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceSetting extends StatelessWidget {
  const _ChoiceSetting({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<(String, String)> options;
  final (String, String) selected;
  final ValueChanged<(String, String)> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 13),
            child: Icon(icon, color: scheme.onSurfaceVariant, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in options)
                      Semantics(
                        button: true,
                        selected: option.$1 == selected.$1,
                        label: '$title：${option.$2}',
                        child: ChoiceChip(
                          label: Text(option.$2),
                          selected: option.$1 == selected.$1,
                          onSelected: (_) => onSelected(option),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsetDivider extends StatelessWidget {
  const _InsetDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 12, 0, 12),
      child: Divider(height: 1, color: Theme.of(context).dividerColor),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: onTap != null,
      label: title,
      hint: subtitle,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(icon, color: scheme.onSurfaceVariant, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

