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
          child: GlassPressable(
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
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
        child: GlassPressable(
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
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
                      color: selected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
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
        child: GlassPressable(
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
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
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
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
                        child: GlassPressable(
                          child: ChoiceChip(
                            label: Text(option.$2),
                            selected: option.$1 == selected.$1,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              onSelected(option);
                            },
                          ),
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

const _widgetSliderDebounce = Duration(milliseconds: 150);

String _formatPercent(double value) {
  final percent = value * 100;
  return percent == percent.roundToDouble()
      ? '${percent.round()}%'
      : '${percent.toStringAsFixed(1)}%';
}

String _formatUnit(double value, String unit) {
  final number = value == value.roundToDouble()
      ? '${value.round()}'
      : value.toStringAsFixed(1);
  return '$number $unit';
}

class _SliderSetting extends StatefulWidget {
  const _SliderSetting({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.formatLabel,
    required this.onChanged,
    this.divisions,
    this.subtitle,
    this.debounce = Duration.zero,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double value) formatLabel;
  final ValueChanged<double> onChanged;
  final Duration debounce;

  @override
  State<_SliderSetting> createState() => _SliderSettingState();
}

class _SliderSettingState extends State<_SliderSetting> {
  Timer? _debounce;
  bool _dragging = false;
  late double _displayValue;
  late double _committedValue;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value;
    _committedValue = widget.value;
  }

  @override
  void didUpdateWidget(_SliderSetting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_dragging) {
      _displayValue = widget.value;
      _committedValue = widget.value;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _handleChanged(double value) {
    _dragging = true;
    setState(() => _displayValue = value);
    if (widget.debounce == Duration.zero) {
      _commit(value);
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () => _commit(value));
  }

  void _handleChangeEnd(double value) {
    _dragging = false;
    _debounce?.cancel();
    _debounce = null;
    _commit(value);
  }

  void _commit(double value) {
    if (value == _committedValue) return;
    _committedValue = value;
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayValue = _displayValue.clamp(widget.min, widget.max);
    final valueLabel = widget.formatLabel(displayValue);
    return Semantics(
      label: widget.title,
      value: valueLabel,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(widget.icon, color: scheme.onSurfaceVariant, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      activeTrackColor: scheme.primary,
                      inactiveTrackColor: scheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                      thumbColor: scheme.primary,
                      overlayColor: scheme.primary.withValues(alpha: 0.12),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 9,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 20,
                      ),
                    ),
                    child: Slider(
                      key: ValueKey('slider-${widget.title}'),
                      value: displayValue,
                      min: widget.min,
                      max: widget.max,
                      divisions: widget.divisions,
                      onChanged: _handleChanged,
                      onChangeEnd: _handleChangeEnd,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: motionDuration(context, AppMotion.state),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.03),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                valueLabel,
                key: ValueKey(valueLabel),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
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
        child: GlassPressable(
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  },
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
      ),
    );
  }
}

class _AvatarSettingTile extends StatelessWidget {
  const _AvatarSettingTile({required this.path, required this.onTap});

  final String path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final image = avatarImage(path);
    return Semantics(
      button: true,
      label: '首页头像',
      hint: path.isEmpty ? '选择自定义图片' : '点击更换头像',
      child: Material(
        color: Colors.transparent,
        child: GlassPressable(
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.transparent,
                      backgroundImage: image ?? const AssetImage('app.png'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '首页头像',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            path.isEmpty ? '点击设置自定义头像' : '点击更换头像',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
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

  AppSettings _withSelection({required bool digit, required String selection}) {
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
          subtitle: '下载 · 导入本地字体',
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
        haptic: GlassHaptic.selectionClick,
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
  final size = (style?.sizeScale ?? 1.0).toStringAsFixed(2);
  final isNonText = widgetNonTextElementIds.contains(elementId);
  final sizeLabel = isNonText ? '大小' : '字号';
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
  final parts = ['颜色：$color', '$sizeLabel：${size}x'];
  if (!isNonText) {
    final weight = style == null || style.weight == 0
        ? '默认'
        : '${style.weight}';
    parts.add('粗细：$weight');
  }
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
  {
  required bool isButton,
}) async {
  await showGlassBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
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
    required this.isButton,
    required this.onChanged,
    required this.onReset,
  });

  final String elementId;
  final String label;
  final IconData icon;
  final WidgetElementStyle? style;
  final bool isButton;
  final ValueChanged<WidgetElementStyle?> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final current = style ?? const WidgetElementStyle();
    final isNonText = widgetNonTextElementIds.contains(elementId);
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
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
                  _SliderSetting(
                    icon: Icons.text_fields_rounded,
                    title: isNonText ? '大小' : '字号',
                    subtitle: '叠加在全局字号缩放之上',
                    value: current.sizeScale,
                    min: 0.5,
                    max: 1.75,
                    divisions: 50,
                    formatLabel: _formatPercent,
                    debounce: _widgetSliderDebounce,
                    onChanged: (value) => onChanged(
                      current.copyWith(
                        sizeScale: value,
                        size: _nearestSizeOption(value),
                      ),
                    ),
                  ),
                  if (!isNonText) ...[
                    const _InsetDivider(),
                    _SliderSetting(
                      icon: Icons.format_bold_rounded,
                      title: '粗细',
                      subtitle: '0 表示跟随默认，50–800 为字重',
                      value: current.weight.toDouble(),
                      min: 0,
                      max: 800,
                      divisions: 16,
                      formatLabel: (value) =>
                          value == 0 ? '默认' : '${value.round()}',
                      debounce: _widgetSliderDebounce,
                      onChanged: (value) =>
                          onChanged(current.copyWith(weight: value.round())),
                    ),
                  ],
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
                          .firstWhere(
                            (option) => option.$1 == current.colorMode,
                          )
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
        child: GlassPressable(
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
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
      ),
    );
  }
}

WidgetElementSize _nearestSizeOption(double scale) {
  if (scale < 0.9) return WidgetElementSize.small;
  if (scale < 1.125) return WidgetElementSize.normal;
  if (scale < 1.375) return WidgetElementSize.large;
  return WidgetElementSize.xlarge;
}

class _PhotoBackgroundEditorSheet extends ConsumerStatefulWidget {
  const _PhotoBackgroundEditorSheet({
    required this.path,
    required this.brightness,
    required this.blur,
  });

  final String path;
  final double brightness;
  final double blur;

  @override
  ConsumerState<_PhotoBackgroundEditorSheet> createState() =>
      _PhotoBackgroundEditorSheetState();
}

class _PhotoBackgroundEditorSheetState
    extends ConsumerState<_PhotoBackgroundEditorSheet> {
  late double _brightness;
  late double _blur;
  late String _path;
  bool _busy = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _brightness = widget.brightness;
    _blur = widget.blur;
    _path = widget.path;
  }

  Future<void> _recrop() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final path = await recropWidgetBackground(
        brightness: _brightness,
        blur: _blur,
      );
      final controller = ref.read(appControllerProvider.notifier);
      final current = ref.read(appControllerProvider).settings;
      await controller.updateSettings(
        current.copyWith(widgetBackgroundPath: path),
      );
      if (mounted) {
        setState(() {
          _path = path;
          _dirty = false;
        });
      }
    } on PhotoBackgroundException catch (error) {
      if (mounted) _showMessage(context, error.message);
    } catch (_) {
      if (mounted) _showMessage(context, '重新裁切失败，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      var path = _path;
      if (_dirty) {
        path = await reprocessWidgetBackground(
          brightness: _brightness,
          blur: _blur,
        );
      }
      final controller = ref.read(appControllerProvider.notifier);
      final current = ref.read(appControllerProvider).settings;
      await controller.updateSettings(
        current.copyWith(
          widgetBackgroundPath: path,
          widgetBackgroundBrightness: _brightness,
          widgetBackgroundBlur: _blur,
        ),
      );
      if (mounted) Navigator.pop(context);
    } on PhotoBackgroundException catch (error) {
      if (mounted) _showMessage(context, error.message);
    } catch (_) {
      if (mounted) _showMessage(context, '保存背景失败，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<double> _brightnessMatrix(double value) => [
    value,
    0,
    0,
    0,
    0,
    0,
    value,
    0,
    0,
    0,
    0,
    0,
    value,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final image = widgetBackgroundImage(_path);
    final rawImage = image == null
        ? const SizedBox.expand()
        : Image(
            image: image,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          );
    final filteredImage = ColorFiltered(
      colorFilter: ColorFilter.matrix(_brightnessMatrix(_brightness)),
      child: _blur > 0
          ? ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
              child: rawImage,
            )
          : rawImage,
    );
    final preview = AnimatedSwitcher(
      duration: motionDuration(context, AppMotion.state),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Container(
        key: ValueKey('preview-${_brightness.toStringAsFixed(2)}-$_blur'),
        height: 180,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(fit: StackFit.expand, children: [filteredImage]),
      ),
    );

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
                    Icon(
                      Icons.photo_filter_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '照片背景编辑',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _busy ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                preview,
                const SizedBox(height: 12),
                _SliderSetting(
                  icon: Icons.brightness_6_rounded,
                  title: '亮度',
                  value: _brightness,
                  min: 0.5,
                  max: 1.5,
                  divisions: 20,
                  formatLabel: _formatPercent,
                  onChanged: (value) {
                    setState(() {
                      _brightness = value;
                      _dirty = true;
                    });
                  },
                ),
                const _InsetDivider(),
                _SliderSetting(
                  icon: Icons.blur_on_rounded,
                  title: '高斯模糊',
                  value: _blur,
                  min: 0,
                  max: 20,
                  divisions: 40,
                  formatLabel: (value) => value == value.roundToDouble()
                      ? '${value.round()}'
                      : value.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _blur = value;
                      _dirty = true;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _recrop,
                        icon: const Icon(Icons.crop_rounded, size: 18),
                        label: const Text('重新裁切'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _save,
                        icon: _busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: const Text('保存'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
