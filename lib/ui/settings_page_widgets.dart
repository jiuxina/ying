part of 'settings_page.dart';

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
    this.locked = false,
    this.onLockedTap,
  });

  final WidgetStyle style;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool locked;
  final VoidCallback? onLockedTap;

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
          onTap: locked ? (onLockedTap ?? () {}) : onTap,
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
                  ? scheme.surfaceContainerHighest
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? scheme.outlineVariant
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
                    color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (locked) ...[
                    const SizedBox(width: 5),
                    Icon(
                      Icons.lock_rounded,
                      size: 12,
                      color: scheme.onSurfaceVariant,
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
    this.locked = false,
    this.onLockedTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool locked;
  final VoidCallback? onLockedTap;

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
          onTap: locked
              ? (onLockedTap ?? () {})
              : () => onChanged(!value),
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
                  if (locked) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
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
    this.locked = false,
    this.onLockedTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<(String, String)> options;
  final (String, String) selected;
  final ValueChanged<(String, String)> onSelected;
  final bool locked;
  final VoidCallback? onLockedTap;

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
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (locked) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ],
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
                          onSelected: locked
                              ? null
                              : (_) => onSelected(option),
                        ),
                      ),
                  ],
                ),
                if (locked) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: onLockedTap,
                    child: Text(
                      '赞助后解锁',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
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

class _FontSettingsSection extends StatelessWidget {
  const _FontSettingsSection({
    required this.settings,
    required this.installed,
    required this.onChanged,
    required this.onOpenLibrary,
  });

  final AppSettings settings;
  final List<WidgetFontAsset> installed;
  final ValueChanged<AppSettings> onChanged;
  final VoidCallback onOpenLibrary;

  List<(String, String)> _digitOptions() => [
    ...widgetFontOptions,
    for (final asset in installed.where((value) => value.kind.coversDigits))
      (asset.selection, asset.name),
  ];

  List<(String, String)> _textOptions() => [
    ...widgetTextFontOptions,
    for (final asset in installed.where((value) => value.kind.coversText))
      (asset.selection, asset.name),
  ];

  WidgetFontAsset? _assetFor(String selection) =>
      FontLibraryService.findAssetBySelection(installed, selection);

  AppSettings _withSelection({
    required bool digit,
    required String selection,
  }) {
    final asset = _assetFor(selection);
    return digit
        ? settings.copyWith(
            widgetFontFamily: selection,
            widgetDigitFontPath: asset?.filePath ?? '',
          )
        : settings.copyWith(
            widgetTextFontFamily: selection,
            widgetTextFontPath: asset?.filePath ?? '',
          );
  }

  @override
  Widget build(BuildContext context) {
    final digitOptions = _digitOptions();
    final textOptions = _textOptions();
    final digitLabel = digitOptions
        .firstWhere(
          (option) => option.$1 == settings.widgetFontFamily,
          orElse: () => digitOptions.first,
        )
        .$2;
    final textLabel = textOptions
        .firstWhere(
          (option) => option.$1 == settings.widgetTextFontFamily,
          orElse: () => textOptions.first,
        )
        .$2;
    return Column(
      children: [
        _ChoiceSetting(
          icon: Icons.pin_outlined,
          title: '数字字体',
          subtitle: '天数等数字区域',
          options: digitOptions,
          selected: (settings.widgetFontFamily, digitLabel),
          onSelected: (option) =>
              onChanged(_withSelection(digit: true, selection: option.$1)),
        ),
        const _InsetDivider(),
        _ChoiceSetting(
          icon: Icons.text_fields_rounded,
          title: '文字字体',
          subtitle: '标题、单位与备注等文字区域',
          options: textOptions,
          selected: (settings.widgetTextFontFamily, textLabel),
          onSelected: (option) =>
              onChanged(_withSelection(digit: false, selection: option.$1)),
        ),
        const _InsetDivider(),
        _SettingsActionTile(
          icon: Icons.font_download_outlined,
          title: '字体库',
          subtitle: '下载并应用 · 导入本地字体',
          onTap: onOpenLibrary,
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final SettingsCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: category.label,
      hint: category.subtitle,
      child: GlassSurface(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        onTap: onTap,
        child: Row(
          children: [
            Icon(category.icon, color: scheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SponsorCard extends ConsumerWidget {
  const _SponsorCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = isSponsorUnlocked(ref);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '赞助支持',
      hint: unlocked ? '已解锁全部赞助功能' : '一次赞助 ¥5 解锁赞助功能',
      child: GlassSurface(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              unlocked ? Icons.verified_rounded : Icons.favorite_rounded,
              color: unlocked
                  ? const Color(0xFF0F766E)
                  : scheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '赞助支持',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unlocked ? '已解锁全部赞助功能' : '一次赞助 ¥5，解锁整活样式等',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

String _elementStyleSummary(AppSettings settings, String elementId) {
  final style = settings.widgetElementStyles[elementId];
  final visible = switch (style?.visible) {
    WidgetElementVisible.show => '显示',
    WidgetElementVisible.hide => '隐藏',
    _ => '跟随默认',
  };
  if (widgetButtonElementOptions.any((option) => option.$1 == elementId)) {
    return '当前：$visible';
  }
  final size = widgetSizeOptions
      .firstWhere(
        (option) => option.$1 == style?.size,
        orElse: () => widgetSizeOptions[1],
      )
      .$2;
  final color = switch (style?.colorMode) {
    WidgetColorMode.custom => '自定义色',
    WidgetColorMode.secondary => '次要色',
    _ => '主色',
  };
  final align = switch (style?.align) {
    WidgetAlign.center => '居中',
    WidgetAlign.end => '右对齐',
    _ => '左对齐',
  };
  final parts = ['颜色：$color', '字号：$size'];
  if (widgetAlignableElementIds.contains(elementId)) {
    parts.add('对齐：$align');
  }
  parts.add('显隐：$visible');
  return parts.join(' · ');
}

Future<void> _openElementStyleSheet(
  BuildContext context,
  WidgetRef ref,
  String elementId,
  String label,
  IconData icon,
  bool unlocked, {
  required bool isButton,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final current = ref.watch(appControllerProvider).settings;
        final style = current.widgetElementStyles[elementId];
        final controller = ref.read(appControllerProvider.notifier);
        void update(WidgetElementStyle? next) {
          final styles = {...current.widgetElementStyles};
          if (next == null) {
            styles.remove(elementId);
          } else {
            styles[elementId] = next;
          }
          unawaited(
            controller.updateSettings(
              current.copyWith(widgetElementStyles: styles),
            ),
          );
        }

        return _ElementStyleSheet(
          elementId: elementId,
          label: label,
          icon: icon,
          style: style,
          unlocked: unlocked,
          isButton: isButton,
          onChanged: update,
          onReset: () {
            update(null);
            Navigator.pop(sheetContext);
          },
        );
      },
    ),
  );
}

class _ElementStyleSheet extends StatelessWidget {
  const _ElementStyleSheet({
    required this.elementId,
    required this.label,
    required this.icon,
    required this.style,
    required this.unlocked,
    required this.isButton,
    required this.onChanged,
    required this.onReset,
  });

  final String elementId;
  final String label;
  final IconData icon;
  final WidgetElementStyle? style;
  final bool unlocked;
  final bool isButton;
  final ValueChanged<WidgetElementStyle?> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final current = style ?? const WidgetElementStyle();
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ChoiceSetting(
                icon: Icons.visibility_outlined,
                title: '显隐',
                subtitle: '跟随默认，或强制显示 / 隐藏',
                options: widgetVisibleOptions
                    .map((option) => (option.$1.name, option.$2))
                    .toList(),
                selected: (
                  current.visible.name,
                  widgetVisibleOptions
                      .firstWhere((option) => option.$1 == current.visible)
                      .$2,
                ),
                locked: !unlocked,
                onLockedTap: () => openSponsorPage(context),
                onSelected: (option) => onChanged(
                  current.copyWith(
                    visible: WidgetElementVisible.values.firstWhere(
                      (visible) => visible.name == option.$1,
                    ),
                  ),
                ),
              ),
              if (!isButton) ...[
                const _InsetDivider(),
                _ChoiceSetting(
                  icon: Icons.text_fields_rounded,
                  title: '字号',
                  subtitle: '叠加在全局字号缩放之上',
                  options: widgetSizeOptions
                      .map((option) => (option.$1.name, option.$2))
                      .toList(),
                  selected: (
                    current.size.name,
                    widgetSizeOptions
                        .firstWhere((option) => option.$1 == current.size)
                        .$2,
                  ),
                  onSelected: (option) => onChanged(
                    current.copyWith(
                      size: WidgetElementSize.values.firstWhere(
                        (size) => size.name == option.$1,
                      ),
                    ),
                  ),
                ),
                const _InsetDivider(),
                _ChoiceSetting(
                  icon: Icons.palette_outlined,
                  title: '颜色',
                  subtitle: '跟随主色、次要色或自定义',
                  options: widgetColorModeOptions
                      .map((option) => (option.$1.name, option.$2))
                      .toList(),
                  selected: (
                    current.colorMode.name,
                    widgetColorModeOptions
                        .firstWhere((option) => option.$1 == current.colorMode)
                        .$2,
                  ),
                  onSelected: (option) => onChanged(
                    current.copyWith(
                      colorMode: WidgetColorMode.values.firstWhere(
                        (mode) => mode.name == option.$1,
                      ),
                    ),
                  ),
                ),
                if (current.colorMode == WidgetColorMode.custom) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 13,
                    runSpacing: 13,
                    children: [
                      for (final color in widgetElementColorPalette)
                        _ElementColorSwatch(
                          color: color,
                          selected: current.color == color.toARGB32(),
                          onTap: () => onChanged(
                            current.copyWith(color: color.toARGB32()),
                          ),
                        ),
                    ],
                  ),
                ],
                if (widgetAlignableElementIds.contains(elementId)) ...[
                  const _InsetDivider(),
                  _ChoiceSetting(
                    icon: Icons.format_align_left_rounded,
                    title: '对齐',
                    subtitle: '独立成行文字的水平位置',
                    options: widgetAlignOptions
                        .map((option) => (option.$1.name, option.$2))
                        .toList(),
                    selected: (
                      current.align.name,
                      widgetAlignOptions
                          .firstWhere((option) => option.$1 == current.align)
                          .$2,
                    ),
                    onSelected: (option) => onChanged(
                      current.copyWith(
                        align: WidgetAlign.values.firstWhere(
                          (align) => align.name == option.$1,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('重置此元素'),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ElementColorSwatch extends StatelessWidget {
  const _ElementColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '自定义颜色',
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
