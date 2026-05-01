import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/widget_config.dart';
import '../../models/widget_theme.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../common/ui_helpers.dart';

class WidgetSettingsCard extends StatefulWidget {
  const WidgetSettingsCard({super.key});

  @override
  State<WidgetSettingsCard> createState() => _WidgetSettingsCardState();
}

class _WidgetSettingsCardState extends State<WidgetSettingsCard> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '桌面小部件', icon: Icons.widgets),
        
        // Live Preview Section
        Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return _buildPreviewSection(context, settings);
          },
        ),
        
        const SizedBox(height: 16),
        
        GlassCard(
          child: Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return Column(
                children: [
                  // Widget type selection
                  ListTile(
                    leading: const IconBox(icon: Icons.dashboard, color: Colors.blue),
                    title: const Text('小部件类型'),
                    subtitle: Text(settings.currentWidgetType.displayName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showWidgetTypeDialog(context, settings),
                  ),
                  const Divider(height: 1),
                  
                  // Theme presets
                  ListTile(
                    leading: const IconBox(icon: Icons.palette, color: Colors.purple),
                    title: const Text('主题预设'),
                    subtitle: Text(_getThemeName(settings)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemePresetsDialog(context, settings),
                  ),
                  const Divider(height: 1),
                  
                  // Style selection
                  ListTile(
                    leading: const IconBox(icon: Icons.style, color: Colors.deepPurple),
                    title: const Text('样式'),
                    subtitle: Text(settings.currentWidgetConfig.style.displayName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showWidgetStyleDialog(context, settings),
                  ),
                  const Divider(height: 1),
                  
                  // Font size
                  ListTile(
                    leading: const IconBox(icon: Icons.text_fields, color: Colors.teal),
                    title: const Text('字体大小'),
                    subtitle: Text(settings.currentWidgetConfig.fontSize.displayName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showFontSizeDialog(context, settings),
                  ),
                  const Divider(height: 1),
                  
                  // Element visibility
                  _buildVisibilitySection(context, settings),
                  
                  const Divider(height: 1),
                  
                  // Background opacity
                  ListTile(
                    leading: const IconBox(icon: Icons.opacity, color: Colors.indigo),
                    title: const Text('背景透明度'),
                    subtitle: Slider(
                      value: settings.currentWidgetConfig.opacity,
                      min: 0.3,
                      max: 1.0,
                      divisions: 7,
                      label: '${(settings.currentWidgetConfig.opacity * 100).toInt()}%',
                      onChanged: (value) {
                        final config = settings.currentWidgetConfig.copyWith(opacity: value);
                        settings.updateCurrentWidgetConfig(config);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  
                  // Background color
                  ListTile(
                    leading: const IconBox(icon: Icons.color_lens, color: Colors.pink),
                    title: const Text('背景颜色'),
                    trailing: ColorPreview(color: Color(settings.currentWidgetConfig.backgroundColor)),
                    onTap: () => _showWidgetColorPicker(context, settings),
                  ),
                  const Divider(height: 1),
                  
                  // Gradient end color (for gradient style)
                  if (settings.currentWidgetConfig.style == WidgetStyle.gradient) ...[
                    ListTile(
                      leading: const IconBox(icon: Icons.gradient, color: Colors.deepOrange),
                      title: const Text('渐变结束色'),
                      trailing: ColorPreview(
                        color: Color(settings.currentWidgetConfig.gradientEndColor ?? settings.currentWidgetConfig.backgroundColor),
                      ),
                      onTap: () => _showGradientColorPicker(context, settings),
                    ),
                    const Divider(height: 1),
                  ],
                  
                  // Background image
                  ListTile(
                    leading: const IconBox(icon: Icons.image, color: Colors.cyan),
                    title: const Text('背景图片'),
                    subtitle: Text(
                      settings.currentWidgetConfig.backgroundImage != null ? '已设置' : '未设置',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (settings.currentWidgetConfig.backgroundImage != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              final config = settings.currentWidgetConfig.copyWith(clearBackgroundImage: true);
                              settings.updateCurrentWidgetConfig(config);
                            },
                          ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => _pickWidgetBackgroundImage(settings),
                  ),
                  const Divider(height: 1),
                  
                  // Corner radius
                  ListTile(
                    leading: const IconBox(icon: Icons.rounded_corner, color: Colors.amber),
                    title: const Text('圆角大小'),
                    subtitle: Slider(
                      value: settings.currentWidgetConfig.cornerRadius,
                      min: 0,
                      max: 32,
                      divisions: 8,
                      label: '${settings.currentWidgetConfig.cornerRadius.toInt()}dp',
                      onChanged: (value) {
                        final config = settings.currentWidgetConfig.copyWith(cornerRadius: value);
                        settings.updateCurrentWidgetConfig(config);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  
                  // Tip
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '修改后请重新添加小部件以应用更改',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
  
  String _getThemeName(SettingsProvider settings) {
    final themeId = settings.currentWidgetConfig.themeId;
    if (themeId == null) return '自定义';
    final theme = WidgetTheme.presetThemes.firstWhere(
      (t) => t.id == themeId,
      orElse: () => WidgetTheme.defaultTheme(),
    );
    return theme.name;
  }

  Widget _buildPreviewSection(BuildContext context, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = settings.currentWidgetConfig;
    final widgetType = settings.currentWidgetType;
    
    // Sample data for preview
    const sampleTitle = '生日倒计时';
    const sampleDays = 30;
    const sampleDate = '2025-05-30';
    
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '预览',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Size selector for preview
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: WidgetType.values.map((type) {
                    final isSelected = widgetType == type;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: InkWell(
                        onTap: () => settings.setCurrentWidgetType(type),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected 
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                              : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            type == WidgetType.mini ? '1×1' : (type == WidgetType.standard ? '2×2' : '4×2'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Preview widgets row
            Center(
              child: _buildPreviewWidget(
                context: context,
                widgetType: widgetType,
                config: config,
                title: sampleTitle,
                days: sampleDays,
                date: sampleDate,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPreviewWidget({
    required BuildContext context,
    required WidgetType widgetType,
    required WidgetConfig config,
    required String title,
    required int days,
    required String date,
    required bool isDark,
  }) {
    final bgColor = Color(config.backgroundColor);
    final textColor = Color(config.textColor);
    final gradientEnd = config.gradientEndColor != null 
      ? Color(config.gradientEndColor!) 
      : bgColor;
    
    double width;
    double height;
    
    switch (widgetType) {
      case WidgetType.mini:
        width = 80;
        height = 80;
        break;
      case WidgetType.standard:
        width = 150;
        height = 150;
        break;
      case WidgetType.large:
        width = 300;
        height = 150;
        break;
    }
    
    final titleStyle = TextStyle(
      color: textColor.withValues(alpha: 0.9),
      fontSize: 12 * config.fontSize.titleScale,
      fontWeight: FontWeight.w600,
    );
    
    final daysStyle = TextStyle(
      color: textColor,
      fontSize: 28 * config.fontSize.daysScale,
      fontWeight: FontWeight.bold,
    );
    
    final prefixStyle = TextStyle(
      color: textColor.withValues(alpha: 0.8),
      fontSize: 11 * config.fontSize.titleScale,
    );
    
    final dateStyle = TextStyle(
      color: textColor.withValues(alpha: 0.7),
      fontSize: 10 * config.fontSize.titleScale,
    );
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: config.style == WidgetStyle.gradient
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bgColor, gradientEnd],
            )
          : null,
        color: config.style != WidgetStyle.gradient ? bgColor : null,
        borderRadius: BorderRadius.circular(config.cornerRadius),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background image if set
          if (config.backgroundImage != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(config.cornerRadius),
                child: Image.file(
                  File(config.backgroundImage!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          
          // Overlay for opacity
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: 1 - config.opacity),
                borderRadius: BorderRadius.circular(config.cornerRadius),
              ),
            ),
          ),
          
          // Content
          Center(
            child: widgetType == WidgetType.mini
              ? _buildMiniContent(days, daysStyle, prefixStyle)
              : widgetType == WidgetType.standard
                ? _buildStandardContent(title, days, date, titleStyle, daysStyle, prefixStyle, dateStyle, config)
                : _buildLargeContent(title, days, date, titleStyle, daysStyle, prefixStyle, dateStyle, config),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMiniContent(int days, TextStyle daysStyle, TextStyle prefixStyle) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$days', style: daysStyle.copyWith(fontSize: 24)),
        Text('天', style: prefixStyle.copyWith(fontSize: 10)),
      ],
    );
  }
  
  Widget _buildStandardContent(
    String title, int days, String date,
    TextStyle titleStyle, TextStyle daysStyle, TextStyle prefixStyle, TextStyle dateStyle,
    WidgetConfig config,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (config.showTitle) Text(title, style: titleStyle, maxLines: 1),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('还有', style: prefixStyle),
            const SizedBox(width: 4),
            Text('$days', style: daysStyle),
            const SizedBox(width: 2),
            Text('天', style: prefixStyle),
          ],
        ),
        if (config.showDate) ...[
          const SizedBox(height: 4),
          Text(date, style: dateStyle),
        ],
      ],
    );
  }
  
  Widget _buildLargeContent(
    String title, int days, String date,
    TextStyle titleStyle, TextStyle daysStyle, TextStyle prefixStyle, TextStyle dateStyle,
    WidgetConfig config,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Main event
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (config.showTitle) Text(title, style: titleStyle, maxLines: 1),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('还有', style: prefixStyle),
                  const SizedBox(width: 4),
                  Text('$days', style: daysStyle.copyWith(fontSize: 24)),
                  const SizedBox(width: 2),
                  Text('天', style: prefixStyle),
                ],
              ),
              if (config.showDate) Text(date, style: dateStyle),
            ],
          ),
        ),
        
        // Divider
        Container(
          width: 1,
          height: 80,
          color: config.textColorValue.withValues(alpha: 0.2),
        ),
        
        // Event list
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildListItem('考试', 15, prefixStyle, config),
              const SizedBox(height: 8),
              _buildListItem('假期', 45, prefixStyle, config),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildListItem(String title, int days, TextStyle style, WidgetConfig config) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: style.copyWith(fontSize: 11)),
        const SizedBox(width: 8),
        Text('$days天', style: style.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildVisibilitySection(BuildContext context, SettingsProvider settings) {
    final config = settings.currentWidgetConfig;
    
    return ExpansionTile(
      leading: const IconBox(icon: Icons.visibility, color: Colors.green),
      title: const Text('显示元素'),
      subtitle: Text(_getVisibilitySummary(config)),
      children: [
        SwitchListTile(
          title: const Text('显示标题'),
          value: config.showTitle,
          onChanged: (v) {
            final newConfig = config.copyWith(showTitle: v);
            settings.updateCurrentWidgetConfig(newConfig);
          },
        ),
        SwitchListTile(
          title: const Text('显示天数'),
          value: config.showDays,
          onChanged: (v) {
            final newConfig = config.copyWith(showDays: v);
            settings.updateCurrentWidgetConfig(newConfig);
          },
        ),
        SwitchListTile(
          title: const Text('显示日期'),
          value: config.showDate,
          onChanged: (v) {
            final newConfig = config.copyWith(showDate: v);
            settings.updateCurrentWidgetConfig(newConfig);
          },
        ),
        SwitchListTile(
          title: const Text('显示图标'),
          value: config.showIcon,
          onChanged: (v) {
            final newConfig = config.copyWith(showIcon: v);
            settings.updateCurrentWidgetConfig(newConfig);
          },
        ),
      ],
    );
  }
  
  String _getVisibilitySummary(WidgetConfig config) {
    final items = <String>[];
    if (config.showTitle) items.add('标题');
    if (config.showDays) items.add('天数');
    if (config.showDate) items.add('日期');
    if (config.showIcon) items.add('图标');
    return items.isEmpty ? '无' : items.join('、');
  }

  // --- Helper Methods ---

  IconData _getWidgetTypeIcon(WidgetType type) {
    switch (type) {
      case WidgetType.mini:
        return Icons.circle_outlined;
      case WidgetType.standard:
        return Icons.crop_square;
      case WidgetType.large:
        return Icons.crop_16_9;
    }
  }

  Future<void> _pickWidgetBackgroundImage(SettingsProvider settings) async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final config = settings.currentWidgetConfig.copyWith(backgroundImage: image.path);
      settings.updateCurrentWidgetConfig(config);
    }
  }

  void _showWidgetTypeDialog(BuildContext context, SettingsProvider settings) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text('小部件类型', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...WidgetType.values.map((type) => ListTile(
                leading: Icon(_getWidgetTypeIcon(type)),
                title: Text(type.displayName),
                subtitle: Text(type.description),
                trailing: settings.currentWidgetType == type
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  settings.setCurrentWidgetType(type);
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
  
  void _showThemePresetsDialog(BuildContext context, SettingsProvider settings) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text('主题预设', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: WidgetTheme.presetThemes.length,
                      itemBuilder: (context, index) {
                        final theme = WidgetTheme.presetThemes[index];
                        final isSelected = settings.currentWidgetConfig.themeId == theme.id;
                        
                        return InkWell(
                          onTap: () {
                            final config = WidgetConfig.fromTheme(
                              settings.currentWidgetType,
                              theme,
                            );
                            settings.updateCurrentWidgetConfig(config);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: theme.styleType == WidgetStyleType.gradient
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(theme.primaryColor),
                                      Color(theme.secondaryColor ?? theme.primaryColor),
                                    ],
                                  )
                                : null,
                              color: theme.styleType != WidgetStyleType.gradient
                                ? Color(theme.primaryColor)
                                : null,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    theme.name,
                                    style: TextStyle(
                                      color: Color(theme.textColor),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  void _showFontSizeDialog(BuildContext context, SettingsProvider settings) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text('字体大小', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...WidgetFontSize.values.map((size) => ListTile(
                leading: Icon(size == WidgetFontSize.small 
                  ? Icons.text_fields 
                  : size == WidgetFontSize.medium 
                    ? Icons.text_fields 
                    : Icons.text_fields),
                title: Text(size.displayName),
                trailing: settings.currentWidgetConfig.fontSize == size
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  final config = settings.currentWidgetConfig.copyWith(fontSize: size);
                  settings.updateCurrentWidgetConfig(config);
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showWidgetStyleDialog(BuildContext context, SettingsProvider settings) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text('小部件样式', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.square_rounded),
                title: const Text('纯色'),
                subtitle: const Text('简洁的单色背景'),
                trailing: settings.currentWidgetConfig.style == WidgetStyle.standard
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  final config = settings.currentWidgetConfig.copyWith(style: WidgetStyle.standard);
                  settings.updateCurrentWidgetConfig(config);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.gradient),
                title: const Text('渐变'),
                subtitle: const Text('优雅的渐变色效果'),
                trailing: settings.currentWidgetConfig.style == WidgetStyle.gradient
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  final config = settings.currentWidgetConfig.copyWith(style: WidgetStyle.gradient);
                  settings.updateCurrentWidgetConfig(config);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.blur_on),
                title: const Text('毛玻璃'),
                subtitle: const Text('半透明模糊效果'),
                trailing: settings.currentWidgetConfig.style == WidgetStyle.glassmorphism
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  final config = settings.currentWidgetConfig.copyWith(style: WidgetStyle.glassmorphism);
                  settings.updateCurrentWidgetConfig(config);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showWidgetColorPicker(BuildContext context, SettingsProvider settings) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('选择背景颜色', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AppConstants.themeColors.map((color) {
                    final isSelected = settings.currentWidgetConfig.backgroundColor == color.toARGB32();
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        final config = settings.currentWidgetConfig.copyWith(backgroundColor: color.toARGB32());
                        settings.updateCurrentWidgetConfig(config);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: AppConstants.animationDuration,
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12)]
                              : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showGradientColorPicker(BuildContext context, SettingsProvider settings) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('选择渐变结束色', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AppConstants.themeColors.map((color) {
                    final isSelected = settings.currentWidgetConfig.gradientEndColor == color.toARGB32();
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        final config = settings.currentWidgetConfig.copyWith(gradientEndColor: color.toARGB32());
                        settings.updateCurrentWidgetConfig(config);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: AppConstants.animationDuration,
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12)]
                              : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
