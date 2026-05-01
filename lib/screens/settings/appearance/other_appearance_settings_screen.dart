// ============================================================================
// 其他外观设置页面
//
// 包含：底部导航栏透明度
// 排除：已在主题设置中的项目（主题模式、主题色、界面字体颜色、按钮样式、卡片透明度）
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/common/app_background.dart';
import '../../../widgets/common/ui_helpers.dart';
import 'appearance_settings_mixin.dart';

class OtherAppearanceSettingsScreen extends StatefulWidget {
  const OtherAppearanceSettingsScreen({super.key});

  @override
  State<OtherAppearanceSettingsScreen> createState() =>
      _OtherAppearanceSettingsScreenState();
}

class _OtherAppearanceSettingsScreenState
    extends State<OtherAppearanceSettingsScreen>
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
                        // 底部导航栏透明度
                        buildSection(l10n.bottomNavOpacity, Icons.tab_rounded, [
                          _buildBottomNavOpacitySlider(settings, l10n),
                        ]),

                        const SizedBox(height: 16),

                        // 卡片透明度（备用）
                        buildSection(l10n.cardOpacity, Icons.opacity_rounded, [
                          _buildCardOpacitySlider(settings, l10n),
                        ]),
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
            l10n.otherSettings,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  /// 构建底部导航栏透明度滑块
  Widget _buildBottomNavOpacitySlider(SettingsProvider settings, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.opacity),
            Expanded(
              child: Slider(
                value: settings.bottomNavOpacity,
                min: 0.1,
                max: 1.0,
                divisions: 18,
                label: '${(settings.bottomNavOpacity * 100).round()}%',
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  settings.setBottomNavOpacity(value);
                },
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '${(settings.bottomNavOpacity * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.bottomNavOpacity,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  /// 构建卡片透明度滑块
  Widget _buildCardOpacitySlider(SettingsProvider settings, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.opacity),
            Expanded(
              child: Slider(
                value: settings.cardOpacity,
                min: 0.4,
                max: 1.0,
                divisions: 12,
                label: '${(settings.cardOpacity * 100).round()}%',
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  settings.setCardOpacity(value);
                },
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '${(settings.cardOpacity * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.cardOpacity,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
