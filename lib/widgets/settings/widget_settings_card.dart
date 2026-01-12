import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/widget_config.dart';
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
        GlassCard(
          child: Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return Column(
                children: [
                  // 小部件类型选择
                  ListTile(
                    leading: const IconBox(icon: Icons.dashboard, color: Colors.blue),
                    title: const Text('小部件类型'),
                    subtitle: Text(settings.currentWidgetType.displayName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showWidgetTypeDialog(context, settings),
                  ),
                  const Divider(height: 1),
                  // 样式选择
                  ListTile(
                    leading: const IconBox(icon: Icons.style, color: Colors.purple),
                    title: const Text('样式'),
                    subtitle: Text(settings.currentWidgetConfig.style.displayName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showWidgetStyleDialog(context, settings),
                  ),
                  const Divider(height: 1),
                  // 显示日期开关
                  SwitchListTile(
                    secondary: const IconBox(icon: Icons.calendar_today, color: Colors.orange),
                    title: const Text('显示日期'),
                    value: settings.currentWidgetConfig.showDate,
                    onChanged: (v) {
                      final config = settings.currentWidgetConfig.copyWith(showDate: v);
                      settings.updateCurrentWidgetConfig(config);
                    },
                  ),
                  const Divider(height: 1),
                  // 背景透明度
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
                  // 背景颜色
                  ListTile(
                    leading: const IconBox(icon: Icons.color_lens, color: Colors.pink),
                    title: const Text('背景颜色'),
                    trailing: ColorPreview(color: Color(settings.currentWidgetConfig.backgroundColor)),
                    onTap: () => _showWidgetColorPicker(context, settings),
                  ),
                  const Divider(height: 1),
                  // 背景图片
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
                              final config = settings.currentWidgetConfig.copyWith(backgroundImage: null);
                              settings.updateCurrentWidgetConfig(config);
                            },
                          ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => _pickWidgetBackgroundImage(settings),
                  ),
                  const Divider(height: 1),
                  // 提示
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

  // --- Helper Methods ---

  IconData _getWidgetTypeIcon(WidgetType type) {
    switch (type) {
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
}
