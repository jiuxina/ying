// ============================================================================
// 外观设置 Mixin
//
// 包含所有外观设置页面的共用方法
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/constants.dart';
import '../../../widgets/common/ui_helpers.dart';
import '../../../widgets/settings/appearance_card.dart';
import 'appearance_utils.dart';

/// 外观设置共用方法 Mixin
mixin AppearanceSettingsMixin<T extends StatefulWidget> on State<T> {
  /// 构建设置区块
  Widget buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, icon: icon),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  /// 构建主题模式选择器
  Widget buildThemeModeSelector(SettingsProvider settings, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildThemeModeOption(
            settings,
            ThemeMode.system,
            Icons.brightness_auto,
            l10n.followSystem,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildThemeModeOption(
            settings,
            ThemeMode.light,
            Icons.light_mode,
            l10n.light,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildThemeModeOption(
            settings,
            ThemeMode.dark,
            Icons.dark_mode,
            l10n.dark,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeOption(
    SettingsProvider settings,
    ThemeMode mode,
    IconData icon,
    String label,
  ) {
    final isSelected = settings.themeMode == mode;
    final primary = Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        settings.setThemeMode(mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建语言选择器
  Widget buildLanguageSelector(SettingsProvider settings, AppLocalizations l10n) {
    final currentLocale = settings.locale;
    return Row(
      children: [
        Expanded(
          child: _buildLanguageOption(
            settings,
            const Locale('zh'),
            '中文',
            currentLocale.languageCode == 'zh',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildLanguageOption(
            settings,
            const Locale('en'),
            'English',
            currentLocale.languageCode == 'en',
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageOption(
    SettingsProvider settings,
    Locale locale,
    String label,
    bool isSelected,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        settings.setLocale(locale);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected
                  ? primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建主题色选择器
  Widget buildThemeColorSelector(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 预设主题色
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppConstants.themeColors.asMap().entries.map((entry) {
            final index = entry.key;
            final color = entry.value;
            final isSelected = settings.themeColorIndex == index;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                settings.setThemeColor(index);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建界面字体颜色选择器
  Widget buildUiFontColorSelector(SettingsProvider settings, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 预设界面字体颜色
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppConstants.uiFontColors.asMap().entries.map((entry) {
            final index = entry.key;
            final color = entry.value;
            final isSelected =
                !settings.useCustomUiFontColor && settings.uiFontColorIndex == index;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                settings.setUiFontColorIndex(index);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // 自定义界面字体颜色
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.customColor),
            Switch(
              value: settings.useCustomUiFontColor,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                settings.setUseCustomUiFontColor(value);
              },
            ),
          ],
        ),
        if (settings.useCustomUiFontColor) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text(l10n.customColor),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _showUiFontColorPicker(settings, l10n),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: settings.customUiFontColor ??
                        Theme.of(context).colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (settings.customUiFontColor ??
                                Theme.of(context).colorScheme.onSurface)
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.colorize,
                    size: 20,
                    color: (settings.customUiFontColor ??
                                Theme.of(context).colorScheme.onSurface)
                            .computeLuminance() >
                            0.5
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (settings.customUiFontColor != null)
                Text(
                  '#${settings.customUiFontColor!.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // 自适应渐变色开关
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.adaptiveGradient),
                    const SizedBox(height: 2),
                    Text(
                      l10n.adaptiveGradientDesc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: settings.uiFontAdaptiveGradientEnabled,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  settings.setUiFontAdaptiveGradientEnabled(value);
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// 显示界面字体颜色选择弹窗
  void _showUiFontColorPicker(SettingsProvider settings, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        Color selectedColor =
            settings.customUiFontColor ?? Theme.of(context).colorScheme.onSurface;
        bool useHslMode = true;
        final hexController = TextEditingController(
          text: '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
        );

        return StatefulBuilder(
          builder: (context, setState) {
            final newHex =
                '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';
            if (hexController.text.toUpperCase() != newHex) {
              hexController.text = newHex;
            }

            return AlertDialog(
              title: Text(l10n.selectColor),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 颜色预览（白色背景）
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          l10n.previewText,
                          style: TextStyle(
                            color: selectedColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 预设颜色
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          AppConstants.uiFontColors.asMap().entries.map((entry) {
                        final color = entry.value;
                        final isSelected = selectedColor.value == color.value;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 20,
                                    color: color.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // 十六进制输入
                    Row(
                      children: [
                        Text('HEX',
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: hexController,
                            decoration: InputDecoration(
                              hintText: '#RRGGBB',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onSubmitted: (value) {
                              final color = AppearanceUtils.parseHexColor(value);
                              if (color != null) {
                                setState(() {
                                  selectedColor = color;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // HSL/RGB 切换
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => useHslMode = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: useHslMode
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              child: Text(
                                'HSL',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: useHslMode
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => useHslMode = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !useHslMode
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              child: Text(
                                'RGB',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !useHslMode
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 滑块
                    if (useHslMode)
                      ...AppearanceUtils.buildHslSliders(selectedColor, (color) {
                        setState(() {
                          selectedColor = color;
                        });
                      })
                    else
                      ...AppearanceUtils.buildRgbSliders(selectedColor, (color) {
                        setState(() {
                          selectedColor = color;
                        });
                      }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () {
                    settings.setCustomUiFontColor(selectedColor);
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n.confirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 构建按钮样式选择器
  Widget buildButtonStyleSelector(SettingsProvider settings, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildButtonStyleOption(
            settings,
            AppButtonStyleMode.classic,
            Icons.crop_square_rounded,
            l10n.buttonStyleClassic,
            l10n.buttonStyleClassicDesc,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildButtonStyleOption(
            settings,
            AppButtonStyleMode.softShadow,
            Icons.auto_awesome_rounded,
            l10n.buttonStyleModern,
            l10n.buttonStyleModernDesc,
          ),
        ),
      ],
    );
  }

  Widget _buildButtonStyleOption(
    SettingsProvider settings,
    AppButtonStyleMode mode,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = settings.buttonStyleMode == mode;
    final previewPrimary = Theme.of(context).colorScheme.primary;
    final previewSurface = Theme.of(context).colorScheme.surface;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        settings.setButtonStyleMode(mode);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? previewPrimary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? previewPrimary : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? previewPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle, color: previewPrimary, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? previewPrimary : null,
                  ),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: mode == AppButtonStyleMode.softShadow
                        ? BoxDecoration(
                            color: previewSurface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          )
                        : BoxDecoration(
                            color: previewPrimary,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: previewPrimary),
                          ),
                    alignment: Alignment.center,
                    child: Text(
                      l10n.preview,
                      style: TextStyle(
                        color: mode == AppButtonStyleMode.softShadow
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建卡片透明度滑块
  Widget buildCardOpacitySlider(SettingsProvider settings, AppLocalizations l10n) {
    return Row(
      children: [
        Text(l10n.opacity),
        Expanded(
          child: Slider(
            value: settings.cardOpacity,
            min: 0.4,
            max: 1.0,
            divisions: 12,
            label: '${(settings.cardOpacity * 100).round()}%',
            onChanged: (value) => settings.setCardOpacity(value),
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
    );
  }

  /// 构建底部导航栏透明度滑块
  Widget buildBottomNavOpacitySlider(SettingsProvider settings, AppLocalizations l10n) {
    return Row(
      children: [
        Text(l10n.opacity),
        Expanded(
          child: Slider(
            value: settings.bottomNavOpacity,
            min: 0.1,
            max: 1.0,
            divisions: 18,
            label: '${(settings.bottomNavOpacity * 100).round()}%',
            onChanged: (value) => settings.setBottomNavOpacity(value),
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
    );
  }

  /// 构建背景亮度滑块
  Widget buildBackgroundBrightnessSlider(SettingsProvider settings, AppLocalizations l10n) {
    return Row(
      children: [
        Text(l10n.brightness),
        Expanded(
          child: Slider(
            value: settings.backgroundBrightness,
            min: 0.2,
            max: 1.8,
            divisions: 16,
            label: '${(settings.backgroundBrightness * 100).round()}%',
            onChanged: (value) => settings.setBackgroundBrightness(value),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '${(settings.backgroundBrightness * 100).round()}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
