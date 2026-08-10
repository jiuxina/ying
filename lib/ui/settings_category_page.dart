part of 'settings_page.dart';

/// 设置三级页：承载某一分类下的具体设置项。
class SettingsCategoryPage extends ConsumerWidget {
  const SettingsCategoryPage({super.key, required this.category});

  final SettingsCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appControllerProvider);
    final settings = appState.settings;
    final controller = ref.read(appControllerProvider.notifier);
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
                    key: const ValueKey('settings-category-back'),
                    icon: Icons.arrow_back_rounded,
                    tooltip: '返回',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                category.label,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 26),
              ..._buildContent(context, ref, appState, settings, controller),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    WidgetRef ref,
    AppState appState,
    AppSettings incomingSettings,
    AppController controller,
  ) {
    final unlocked = isSponsorUnlocked(ref);
    final settings = unlocked
        ? incomingSettings
        : sanitizeSponsorSettings(incomingSettings);
    return switch (category) {
      SettingsCategory.appearance => [
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
                subtitle: '使用实色背景',
                value: settings.reduceTransparency,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(reduceTransparency: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.motion_photos_off_rounded,
                title: '减少动画',
                subtitle: '关闭过渡动画',
                value: settings.reduceMotion,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(reduceMotion: value),
                ),
              ),
            ],
          ),
        ),
      ],
      SettingsCategory.widget => [
        _Section(
          title: '小部件样式',
          subtitle: '预设、主色与缩放',
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
                        locked: !unlocked &&
                            sponsorWidgetStyles.contains(preset.$1),
                        onLockedTap: () => openSponsorPage(context),
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
                children: SettingsPage.colorOptions
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
          subtitle: '壁纸取色与相册',
          child: Column(
            children: [
              _SettingSwitch(
                icon: Icons.wallpaper_rounded,
                title: '跟随壁纸颜色',
                subtitle: '自动适配壁纸主色',
                value: settings.widgetWallpaperColor != -1,
                locked: !unlocked,
                onLockedTap: () => openSponsorPage(context),
                onChanged: (value) => unawaited(
                  _toggleWallpaperColors(context, ref, settings, value),
                ),
              ),
              const _InsetDivider(),
              _SettingsActionTile(
                icon: Icons.add_photo_alternate_outlined,
                title: '选择照片背景',
                subtitle: settings.widgetBackgroundPath.isEmpty
                    ? '从相册选择一张图片'
                    : '已设置，点击可更换',
                onTap: () => unawaited(_pickBackgroundPhoto(context, ref)),
              ),
              if (settings.widgetBackgroundPath.isNotEmpty) ...[
                const _InsetDivider(),
                _SettingsActionTile(
                  icon: Icons.hide_image_outlined,
                  title: '清除照片背景',
                  subtitle: '恢复默认背景',
                  onTap: () => unawaited(_clearWidgetBackground(context, ref)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '小部件内容',
          subtitle: '选择卡片显示字段',
          child: Column(
            children: [
              _SettingSwitch(
                icon: Icons.tag_rounded,
                title: '分类标签',
                subtitle: '显示分类',
                value: settings.widgetShowCategory,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetShowCategory: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.notes_rounded,
                title: '事件备注',
                subtitle: '显示一行备注',
                value: settings.widgetShowNote,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetShowNote: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.emoji_emotions_outlined,
                title: '事件图标',
                subtitle: '显示 Emoji',
                value: settings.widgetShowIcon,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetShowIcon: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.timer_outlined,
                title: '精确到秒',
                subtitle: '精确到时分秒',
                value: settings.widgetShowPreciseTime,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetShowPreciseTime: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.calendar_month_outlined,
                title: '农历与星期',
                subtitle: '显示农历与星期',
                value: settings.widgetShowLunarWeek,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetShowLunarWeek: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.donut_small_rounded,
                title: '进度百分比',
                subtitle: '显示完成进度',
                value: settings.widgetShowProgress,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetShowProgress: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.visibility_off_outlined,
                title: '神秘模式',
                subtitle: '隐藏数字与日期',
                value: settings.widgetMysteryMode,
                locked: !unlocked,
                onLockedTap: () => openSponsorPage(context),
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetMysteryMode: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.format_quote_outlined,
                title: '每日一句',
                subtitle: '每日轮播一句话',
                value: settings.widgetQuoteMode,
                locked: !unlocked,
                onLockedTap: () => openSponsorPage(context),
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetQuoteMode: value),
                ),
              ),
              const _InsetDivider(),
              _SettingSwitch(
                icon: Icons.local_fire_department_outlined,
                title: '临近高亮',
                subtitle: '临近自动切换强调色',
                value: settings.widgetUrgentHighlight,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetUrgentHighlight: value),
                ),
              ),
              const _InsetDivider(),
              _ChoiceSetting(
                icon: Icons.text_fields_rounded,
                title: '单位文案',
                subtitle: '选择单位文案预设',
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
                subtitle: '切换数字字体',
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
                locked: !unlocked,
                onLockedTap: () => openSponsorPage(context),
                onSelected: (option) => controller.updateSettings(
                  settings.copyWith(widgetFontFamily: option.$1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '整体布局',
          subtitle: '单事件小部件垂直位置',
          child: _ChoiceSetting(
            icon: Icons.vertical_align_center_rounded,
            title: '内容垂直对齐',
            subtitle: '顶部、居中或底部',
            options: widgetVerticalAlignOptions
                .map((option) => (option.$1.name, option.$2))
                .toList(),
            selected: (
              settings.widgetVerticalAlign.name,
              widgetVerticalAlignOptions
                  .firstWhere(
                    (option) =>
                        option.$1 == settings.widgetVerticalAlign,
                  )
                  .$2,
            ),
            onSelected: (option) => controller.updateSettings(
              settings.copyWith(
                widgetVerticalAlign: WidgetVerticalAlign.values.firstWhere(
                  (align) => align.name == option.$1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '文字样式',
          subtitle: '逐元素颜色、字号与对齐',
          child: Column(
            children: [
              for (final (index, option)
                  in widgetTextElementOptions.indexed) ...[
                if (index > 0) const _InsetDivider(),
                _SettingsActionTile(
                  icon: option.$3,
                  title: option.$2,
                  subtitle: _elementStyleSummary(settings, option.$1),
                  onTap: () => unawaited(
                    _openElementStyleSheet(
                      context,
                      ref,
                      option.$1,
                      option.$2,
                      option.$3,
                      unlocked,
                      isButton: false,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '按钮显隐',
          subtitle: '上一个、下一个按钮',
          child: Column(
            children: [
              for (final (index, option)
                  in widgetButtonElementOptions.indexed) ...[
                if (index > 0) const _InsetDivider(),
                _SettingsActionTile(
                  icon: option.$3,
                  title: option.$2,
                  subtitle: _elementStyleSummary(settings, option.$1),
                  onTap: () => unawaited(
                    _openElementStyleSheet(
                      context,
                      ref,
                      option.$1,
                      option.$2,
                      option.$3,
                      unlocked,
                      isButton: true,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '小部件列表',
          subtitle: '滚动浏览全部事件',
          child: Column(
            children: [
              _SettingSwitch(
                icon: Icons.view_agenda_outlined,
                title: '事件列表模式',
                subtitle: '显示全部事件列表',
                value: settings.widgetListMode,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(widgetListMode: value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WidgetPreviewSection(events: appState.events, settings: settings),
      ],
      SettingsCategory.notifications => [
        ReminderDiagnosticsSection(events: appState.events),
      ],
      SettingsCategory.permissions => [
        const PermissionManageSection(),
      ],
      SettingsCategory.data => [
        _Section(
          title: '数据管理',
          subtitle: '导出、导入与清除',
          child: Column(
            children: [
              _SettingsActionTile(
                icon: Icons.upload_file_outlined,
                title: '导出数据',
                subtitle: '复制到剪贴板备份',
                onTap: () => _exportData(context, ref),
              ),
              const _InsetDivider(),
              _SettingsActionTile(
                icon: Icons.download_outlined,
                title: '导入数据',
                subtitle: '从剪贴板导入备份',
                onTap: () => _importData(context, ref),
              ),
              const _InsetDivider(),
              _SettingsActionTile(
                icon: Icons.delete_sweep_outlined,
                title: '清除所有事件',
                subtitle: '删除全部并可撤销',
                onTap: () => _clearAllData(context, ref),
              ),
            ],
          ),
        ),
      ],
      SettingsCategory.updateAbout => [
        _Section(
          title: '检查更新',
          subtitle: '当前版本 v$appVersion',
          child: Column(
            children: [
              _SettingSwitch(
                icon: Icons.system_update_outlined,
                title: '自动检测更新',
                subtitle: '启动时自动查询最新版',
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
                subtitle: '无账号无服务端，卸载前先备份',
              ),
              const _InsetDivider(),
              _SettingsActionTile(
                icon: Icons.code_rounded,
                title: 'github.com/jiuxina/ying',
                subtitle: '开源仓库，欢迎反馈',
                onTap: () =>
                    _copyLink(context, 'https://github.com/jiuxina/ying'),
              ),
            ],
          ),
        ),
      ],
    };
  }
}
