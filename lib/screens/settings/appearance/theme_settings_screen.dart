// ============================================================================
// 主题设置页面
//
// 包含：主题模式、语言、主题色、界面字体颜色、按钮样式、卡片透明度、浅色/深色主题方案
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../providers/settings_provider.dart';
import '../../../utils/constants.dart';
import '../../../widgets/common/app_background.dart';
import '../../../widgets/common/ui_helpers.dart';
import '../../../l10n/app_localizations.dart';
import 'appearance_settings_mixin.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen>
    with AppearanceSettingsMixin {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, l10n),
              Expanded(
                child: Consumer<SettingsProvider>(
                  builder: (context, settings, child) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // 主题模式
                        buildSection(l10n.themeMode, Icons.brightness_6, [
                          buildThemeModeSelector(settings, l10n),
                        ]),

                        const SizedBox(height: 16),

                        // 语言
                        buildSection(l10n.language, Icons.language, [
                          buildLanguageSelector(settings, l10n),
                        ]),

                        const SizedBox(height: 16),

                        // 主题色
                        buildSection(l10n.themeColor, Icons.color_lens, [
                          buildThemeColorSelector(settings),
                        ]),

                        const SizedBox(height: 16),

                        // 界面字体颜色
                        buildSection(l10n.uiFontColor, Icons.text_fields, [
                          buildUiFontColorSelector(settings, l10n),
                        ]),

                        const SizedBox(height: 16),

                        // 按钮样式
                        buildSection(l10n.buttonStyle, Icons.smart_button_outlined, [
                          buildButtonStyleSelector(settings, l10n),
                        ]),

                        const SizedBox(height: 16),

                        // 卡片透明度
                        buildSection(l10n.cardOpacity, Icons.opacity_rounded, [
                          buildCardOpacitySlider(settings, l10n),
                        ]),

                        // 浅色主题方案（仅在浅色模式下显示）
                        if (settings.themeMode == ThemeMode.light) ...[
                          const SizedBox(height: 16),
                          _buildLightThemeSelector(settings, l10n),
                        ],

                        // 深色主题方案（仅在深色模式下显示）
                        if (settings.themeMode == ThemeMode.dark) ...[
                          const SizedBox(height: 16),
                          _buildDarkThemeSelector(settings, l10n),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.themeSettings,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  /// 构建浅色主题方案选择器
  Widget _buildLightThemeSelector(SettingsProvider settings, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.lightTheme, icon: Icons.light_mode),
        GlassCard(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppConstants.lightThemeSchemes.length,
            itemBuilder: (context, index) {
              final scheme = AppConstants.lightThemeSchemes[index];
              final isSelected = settings.lightThemeIndex == index;
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                title: Text(scheme.name),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  settings.setLightThemeIndex(index);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// 构建深色主题方案选择器
  Widget _buildDarkThemeSelector(SettingsProvider settings, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.darkTheme, icon: Icons.dark_mode),
        GlassCard(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppConstants.darkThemeSchemes.length,
            itemBuilder: (context, index) {
              final scheme = AppConstants.darkThemeSchemes[index];
              final isSelected = settings.darkThemeIndex == index;
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  scheme.name,
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  settings.setDarkThemeIndex(index);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
