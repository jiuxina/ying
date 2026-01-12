import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../common/ui_helpers.dart';

class AppearanceCard extends StatefulWidget {
  const AppearanceCard({super.key});

  @override
  State<AppearanceCard> createState() => _AppearanceCardState();
}

class _AppearanceCardState extends State<AppearanceCard> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '外观与显示', icon: Icons.palette),
        GlassCard(
          child: Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return Column(
                children: [
                  // Theme
                  ListTile(
                    leading: const IconBox(icon: Icons.dark_mode, color: Colors.purple),
                    title: const Text('主题'),
                    trailing: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.settings_suggest, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode, size: 18),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (modes) {
                        HapticFeedback.selectionClick();
                        settings.setThemeMode(modes.first);
                      },
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  // 浅色主题方案（仅在浅色模式下显示）
                  if (settings.themeMode == ThemeMode.light) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const IconBox(icon: Icons.light_mode, color: Colors.amber),
                      title: const Text('浅色主题'),
                      subtitle: Text(AppConstants.lightThemeSchemes[settings.lightThemeIndex].name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showLightThemeSelector(context, settings),
                    ),
                  ],
                  // 夜间主题方案（仅在深色模式下显示）
                  if (settings.themeMode == ThemeMode.dark) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const IconBox(icon: Icons.dark_mode, color: Colors.indigo),
                      title: const Text('夜间主题'),
                      subtitle: Text(AppConstants.darkThemeSchemes[settings.darkThemeIndex].name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showDarkThemeSelector(context, settings),
                    ),
                  ],
                  const Divider(height: 1),
                  // Theme Color
                  ListTile(
                    leading: const IconBox(icon: Icons.color_lens, color: Colors.blue),
                    title: const Text('主题色'),
                    trailing: ColorPreview(color: settings.themeColor),
                    onTap: () => _showColorPicker(context, settings),
                  ),
                  const Divider(height: 1),
                  // Font Size
                  ListTile(
                    leading: const IconBox(icon: Icons.format_size, color: Colors.green),
                    title: const Text('字体大小'),
                    subtitle: Text('${settings.fontSizePx.toInt()}px'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Slider(
                      value: settings.fontSizePx,
                      min: 12,
                      max: 24,
                      divisions: 12,
                      label: '${settings.fontSizePx.toInt()}px',
                      onChanged: (value) => settings.setFontSizePx(value),
                    ),
                  ),
                  const Divider(height: 1),
                  // Font Family
                  ListTile(
                    leading: const IconBox(icon: Icons.font_download, color: Colors.indigo),
                    title: const Text('字体'),
                    subtitle: Text(settings.fontFamily ?? '系统默认'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showFontDialog(context, settings),
                  ),
                  const Divider(height: 1),
                  // Date Format
                  ListTile(
                    leading: const IconBox(icon: Icons.calendar_month, color: Colors.orange),
                    title: const Text('日期格式'),
                    subtitle: Text(settings.dateFormat),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDateFormatDialog(context, settings),
                  ),
                  const Divider(height: 1),
                  // Card Display Format
                  ListTile(
                    leading: const IconBox(icon: Icons.view_agenda, color: Colors.teal),
                    title: const Text('卡片日期显示'),
                    subtitle: Text(settings.cardDisplayFormat == 'days' ? '仅剩余天数' : '详细年月日'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showCardDisplayFormatDialog(context, settings),
                  ),
                  const Divider(height: 1),
                  // Background Image
                  ListTile(
                    leading: const IconBox(icon: Icons.image, color: Colors.pink),
                    title: const Text('背景图片'),
                    subtitle: Text(
                      settings.backgroundImagePath != null ? '已设置' : '使用默认渐变',
                    ),
                    trailing: settings.backgroundImagePath != null
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => settings.setBackgroundImage(null),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: () => _pickBackgroundImage(settings),
                  ),
                  if (settings.backgroundImagePath != null) ...[
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const IconBox(icon: Icons.blur_on, color: Colors.cyan),
                      title: const Text('模糊效果'),
                      value: settings.backgroundEffect == 'blur',
                      onChanged: (v) => settings.setBackgroundEffect(v ? 'blur' : 'none'),
                    ),
                    if (settings.backgroundEffect == 'blur') ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Slider(
                          value: settings.backgroundBlur,
                          min: 0,
                          max: 30,
                          divisions: 30,
                          label: '${settings.backgroundBlur.toInt()}',
                          onChanged: (value) => settings.setBackgroundBlur(value),
                        ),
                      ),
                    ],
                  ],
                  const Divider(height: 1),
                  // Particles
                  ListTile(
                    leading: const IconBox(icon: Icons.auto_awesome, color: Colors.amber),
                    title: const Text('粒子效果'),
                    subtitle: Text(_getParticleTypeLabel(settings.particleType)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showParticleDialog(context, settings),
                  ),
                  if (settings.particleEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const IconBox(icon: Icons.speed, color: Colors.deepOrange),
                      title: const Text('粒子速率'),
                      subtitle: Text('${settings.particleSpeed.toStringAsFixed(1)}x'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Slider(
                        value: settings.particleSpeed,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        label: '${settings.particleSpeed.toStringAsFixed(1)}x',
                        onChanged: (value) => settings.setParticleSpeed(value),
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const IconBox(icon: Icons.visibility, color: Colors.teal),
                      title: const Text('全局显示'),
                      subtitle: const Text('包含编辑器区域'),
                      value: settings.particleGlobal,
                      onChanged: (v) => settings.setParticleGlobal(v),
                    ),
                  ],
                  const Divider(height: 1),
                  // Progress Style
                  ListTile(
                    leading: const IconBox(icon: Icons.linear_scale, color: Colors.deepPurple),
                    title: const Text('进度条样式'),
                    subtitle: Text(
                      settings.progressStyle == 'background' ? '背景进度条' : '标准进度条',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showProgressStyleDialog(context, settings),
                  ),
                  const Divider(height: 1),
                  // Calculation
                  ListTile(
                    leading: const IconBox(icon: Icons.calculate, color: Colors.brown),
                    title: const Text('进度计算方式'),
                    subtitle: Text(_getProgressCalculationLabel(settings.progressCalculation)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showProgressCalculationDialog(context, settings),
                  ),
                  if (settings.progressCalculation == 'fixed') ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const IconBox(icon: Icons.timer, color: Colors.grey),
                      title: const Text('固定天数'),
                      subtitle: Text('${settings.progressFixedDays} 天'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showFixedDaysDialog(context, settings),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Helper Methods ---

  String _getParticleTypeLabel(String type) {
    switch (type) {
      case 'sakura': return '樱花';
      case 'rain': return '雨滴';
      case 'firefly': return '萤火虫';
      case 'snow': return '雪花';
      default: return '关闭';
    }
  }

  String _getProgressCalculationLabel(String calculation) {
    switch (calculation) {
      case 'year': return '本年百分比';
      case 'month': return '本月百分比';
      case 'week': return '本周百分比';
      case 'day': return '今日百分比';
      case 'fixed': return '固定天数';
      default: return '本年百分比';
    }
  }

  Future<void> _pickBackgroundImage(SettingsProvider settings) async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      settings.setBackgroundImage(image.path);
    }
  }

  void _showColorPicker(BuildContext context, SettingsProvider settings) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('选择主题色', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AppConstants.themeColors.map((color) {
                    final isSelected = settings.themeColor.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        final index = AppConstants.themeColors.indexOf(color);
                        if (index != -1) {
                          settings.setThemeColor(index);
                        }
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

  void _showFontDialog(BuildContext context, SettingsProvider settings) {
    HapticFeedback.selectionClick();
    final fonts = [
      {'name': null, 'label': '系统默认'},
      {'name': 'Roboto', 'label': 'Roboto'},
      {'name': 'NotoSansSC', 'label': '思源黑体'},
      {'name': 'NotoSerifSC', 'label': '思源宋体'},
      {'name': 'LXGWWenKai', 'label': '霞鹜文楷'},
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text('选择字体', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...fonts.map((font) => ListTile(
                title: Text(font['label']!),
                trailing: settings.fontFamily == font['name']
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  settings.setFontFamily(font['name']);
                  Navigator.pop(context);
                },
              )),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('导入本地字体 (.ttf/.otf)'),
                onTap: () {
                  Navigator.pop(context);
                  _importFont(context, settings);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _importFont(BuildContext context, SettingsProvider settings) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ttf', 'otf'],
      );

      if (result != null && result.files.single.path != null) {
        final originalFile = File(result.files.single.path!);
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(originalFile.path);
        final fontDir = Directory('${appDir.path}/fonts');
        if (!await fontDir.exists()) {
          await fontDir.create(recursive: true);
        }
        
        final savedFile = await originalFile.copy('${fontDir.path}/$fileName');
        final fontName = path.basenameWithoutExtension(fileName);

        await settings.setCustomFont(fontName, savedFile.path);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已应用字体: $fontName')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入字体失败: $e')),
        );
      }
    }
  }

  void _showCardDisplayFormatDialog(BuildContext context, SettingsProvider settings) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text('卡片日期显示', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('仅剩余天数'),
                subtitle: const Text('如: 3 天'),
                trailing: settings.cardDisplayFormat == 'days'
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  settings.setCardDisplayFormat('days');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('详细年月日'),
                subtitle: const Text('如: 1年2个月3天'),
                trailing: settings.cardDisplayFormat == 'detailed'
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  settings.setCardDisplayFormat('detailed');
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

  void _showDateFormatDialog(BuildContext context, SettingsProvider settings) {
    HapticFeedback.selectionClick();
    final formats = [
      'yyyy-MM-dd',
      'yyyy/MM/dd',
      'yyyy年MM月dd日',
      'MM-dd-yyyy',
      'dd/MM/yyyy',
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text('选择日期格式', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...formats.map((fmt) => ListTile(
                title: Text(fmt),
                trailing: settings.dateFormat == fmt
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  settings.setDateFormat(fmt);
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

  void _showParticleDialog(BuildContext context, SettingsProvider settings) {
    HapticFeedback.selectionClick();
    final particles = [
      {'type': 'none', 'label': '关闭', 'icon': Icons.close},
      {'type': 'sakura', 'label': '樱花', 'icon': Icons.local_florist},
      {'type': 'rain', 'label': '雨滴', 'icon': Icons.water_drop},
      {'type': 'firefly', 'label': '萤火虫', 'icon': Icons.blur_on},
      {'type': 'snow', 'label': '雪花', 'icon': Icons.ac_unit},
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text('粒子效果', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...particles.map((p) => ListTile(
                leading: Icon(p['icon'] as IconData),
                title: Text(p['label'] as String),
                trailing: settings.particleType == p['type']
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  settings.setParticleType(p['type'] as String);
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

  void _showProgressStyleDialog(BuildContext context, SettingsProvider settings) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text('进度条样式', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('标准进度条'),
                subtitle: const Text('经典的线通过度条'),
                trailing: settings.progressStyle == 'standard'
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  settings.setProgressStyle('standard');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('背景进度条'),
                subtitle: const Text('整个卡片作为进度背景'),
                trailing: settings.progressStyle == 'background'
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  settings.setProgressStyle('background');
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

  void _showProgressCalculationDialog(BuildContext context, SettingsProvider settings) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text('进度计算方式', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...['year', 'month', 'week', 'day', 'fixed'].map((calc) => ListTile(
                title: Text(_getProgressCalculationLabel(calc)),
                trailing: settings.progressCalculation == calc
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  settings.setProgressCalculation(calc);
                  Navigator.pop(context);
                  if (calc == 'fixed') {
                    _showFixedDaysDialog(context, settings);
                  }
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showFixedDaysDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.progressFixedDays.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置固定天数'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(suffixText: '天'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final days = int.tryParse(controller.text) ?? 365;
              settings.setProgressFixedDays(days);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示浅色主题方案选择器
  void _showLightThemeSelector(BuildContext context, SettingsProvider settings) {
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
                child: Text('浅色主题方案', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListView.builder(
                shrinkWrap: true,
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
                    trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                    onTap: () {
                      settings.setLightThemeIndex(index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 显示夜间主题方案选择器
  void _showDarkThemeSelector(BuildContext context, SettingsProvider settings) {
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
                child: Text('夜间主题方案', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListView.builder(
                shrinkWrap: true,
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
                    title: Text(scheme.name, style: const TextStyle(color: Colors.white70)),
                    trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                    onTap: () {
                      settings.setDarkThemeIndex(index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

