import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/ui_helpers.dart';
import '../../widgets/settings/appearance_card.dart';
import 'appearance/theme_settings_screen.dart';
import 'appearance/background_settings_screen.dart';
import 'appearance/other_appearance_settings_screen.dart';

/// 外观设置主页面
class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

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
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 导航到主题设置
                    _buildNavigationCard(
                      context,
                      l10n: l10n,
                      icon: Icons.palette,
                      title: l10n.themeSettings,
                      subtitle: l10n.themeSettingsSubtitle,
                      onTap: () => _navigateTo(context, const ThemeSettingsScreen()),
                    ),

                    const SizedBox(height: 12),

                    // 导航到背景设置
                    _buildNavigationCard(
                      context,
                      l10n: l10n,
                      icon: Icons.image,
                      title: l10n.backgroundSettings,
                      subtitle: l10n.backgroundSettingsSubtitle,
                      onTap: () => _navigateTo(context, const BackgroundSettingsScreen()),
                    ),

                    const SizedBox(height: 12),

                    // 导航到其他外观设置
                    _buildNavigationCard(
                      context,
                      l10n: l10n,
                      icon: Icons.tune,
                      title: l10n.otherSettings,
                      subtitle: l10n.otherSettingsSubtitle,
                      onTap: () => _navigateTo(context, const OtherAppearanceSettingsScreen()),
                    ),

                    const SizedBox(height: 24),

                    // 分隔线
                    Center(
                      child: Text(
                        l10n.orUseClassicView,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 传统视图（保留原有的 AppearanceCard）
                    const AppearanceCard(),
                  ],
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
            l10n.appearanceSettings,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  /// 构建导航卡片
  Widget _buildNavigationCard(
    BuildContext context, {
    required AppLocalizations l10n,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).colorScheme.primary;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  /// 导航到子页面
  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
