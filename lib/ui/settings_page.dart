import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_controller.dart';
import 'glass_ui.dart';
import 'reminder_diagnostics_section.dart';
import 'widget_preview_section.dart';

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
            fontWeight: FontWeight.w800,
            letterSpacing: -2.1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '让 萤 更像你。',
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
          title: '小部件色彩',
          subtitle: '选择桌面上的主色调',
          child: Wrap(
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
        ),
        const SizedBox(height: 16),
        _Section(
          title: '文字大小',
          subtitle: '${(settings.widgetFontScale * 100).round()}%',
          child: Semantics(
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
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
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
        ),
        const SizedBox(height: 16),
        _Section(
          title: '显示内容',
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
            ],
          ),
        ),
        const SizedBox(height: 16),
        ReminderDiagnosticsSection(events: appState.events),
        const SizedBox(height: 16),
        WidgetPreviewSection(events: appState.events, settings: settings),
      ],
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
    return Row(
      children: [
        _ThemeOption(
          icon: Icons.auto_awesome_rounded,
          label: '自动',
          selected: value == ThemeMode.system,
          onTap: () => onChanged(ThemeMode.system),
        ),
        const SizedBox(width: 10),
        _ThemeOption(
          icon: Icons.light_mode_rounded,
          label: '浅色',
          selected: value == ThemeMode.light,
          onTap: () => onChanged(ThemeMode.light),
        ),
        const SizedBox(width: 10),
        _ThemeOption(
          icon: Icons.dark_mode_rounded,
          label: '深色',
          selected: value == ThemeMode.dark,
          onTap: () => onChanged(ThemeMode.dark),
        ),
      ],
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
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  width: selected ? 1.6 : 1,
                  color: selected ? scheme.primary : scheme.outlineVariant,
                ),
              ),
              // 外层 Semantics 已提供完整 label，排除内部文字避免重复播报。
              child: ExcludeSemantics(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
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
