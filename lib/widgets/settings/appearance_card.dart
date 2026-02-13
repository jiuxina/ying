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
import '../../utils/responsive_utils.dart';
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
                  Builder(
                    builder: (context) => ListTile(
                      leading: const IconBox(icon: Icons.dark_mode, color: Colors.purple),
                      title: Text('主题', overflow: TextOverflow.ellipsis),
                      trailing: SegmentedButton<ThemeMode>(
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode, size: ResponsiveFontSize.xl(context)),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.settings_suggest, size: ResponsiveFontSize.xl(context)),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode, size: ResponsiveFontSize.xl(context)),
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
                  ),
                  // 浅色主题方案（仅在浅色模式下显示）
                  if (settings.themeMode == ThemeMode.light) ...[
                    Divider(height: ResponsiveSpacing.xs(context) / 4),
                    ListTile(
                      leading: const IconBox(icon: Icons.light_mode, color: Colors.amber),
                      title: Text('浅色主题', overflow: TextOverflow.ellipsis),
                      subtitle: Text(AppConstants.lightThemeSchemes[settings.lightThemeIndex].name, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showLightThemeSelector(context, settings),
                    ),
                  ],
                  // 夜间主题方案（仅在深色模式下显示）
                  if (settings.themeMode == ThemeMode.dark) ...[
                    Divider(height: ResponsiveSpacing.xs(context) / 4),
                    ListTile(
                      leading: const IconBox(icon: Icons.dark_mode, color: Colors.indigo),
                      title: Text('夜间主题', overflow: TextOverflow.ellipsis),
                      subtitle: Text(AppConstants.darkThemeSchemes[settings.darkThemeIndex].name, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showDarkThemeSelector(context, settings),
                    ),
                  ],
                  Builder(builder: (context) => Divider(height: ResponsiveSpacing.xs(context) / 4)),
                  // Theme Color
                  ListTile(
                    leading: const IconBox(icon: Icons.color_lens, color: Colors.blue),
                    title: Text('主题色', overflow: TextOverflow.ellipsis),
                    trailing: ColorPreview(color: settings.themeColor),
                    onTap: () => _showColorPicker(context, settings),
                  ),
                  Builder(builder: (context) => Divider(height: ResponsiveSpacing.xs(context) / 4)),
                  // Font Size
                  ListTile(
                    leading: const IconBox(icon: Icons.format_size, color: Colors.green),
                    title: Text('字体大小', overflow: TextOverflow.ellipsis),
                    subtitle: Text('${settings.fontSizePx.toInt()}px', overflow: TextOverflow.ellipsis),
                  ),
                  Builder(
                    builder: (context) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: ResponsiveSpacing.base(context)),
                      child: Slider(
                        value: settings.fontSizePx,
                        min: 12,
                        max: 24,
                        divisions: 12,
                        label: '${settings.fontSizePx.toInt()}px',
                        onChanged: (value) => settings.setFontSizePx(value),
                      ),
                    ),
                  ),
                  Builder(builder: (context) => Divider(height: ResponsiveSpacing.xs(context) / 4)),
                  // Font Family
                  ListTile(
                    leading: const IconBox(icon: Icons.font_download, color: Colors.indigo),
                    title: Text('字体', overflow: TextOverflow.ellipsis),
                    subtitle: Text(settings.fontFamily ?? '系统默认', overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showFontDialog(context, settings),
                  ),
                  Builder(builder: (context) => Divider(height: ResponsiveSpacing.xs(context) / 4)),
                  // Date Format
                  ListTile(
                    leading: const IconBox(icon: Icons.calendar_month, color: Colors.orange),
                    title: Text('日期格式', overflow: TextOverflow.ellipsis),
                    subtitle: Text(settings.dateFormat, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDateFormatDialog(context, settings),
                  ),
                  Builder(builder: (context) => Divider(height: ResponsiveSpacing.xs(context) / 4)),
                  // Card Display Format
                  ListTile(
                    leading: const IconBox(icon: Icons.view_agenda, color: Colors.teal),
                    title: Text('卡片日期显示', overflow: TextOverflow.ellipsis),
                    subtitle: Text(settings.cardDisplayFormat == 'days' ? '仅剩余天数' : '详细年月日', overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showCardDisplayFormatDialog(context, settings),
                  ),
                  Builder(builder: (context) => Divider(height: ResponsiveSpacing.xs(context) / 4)),
                  // Background Image
                  Builder(
                    builder: (context) => ListTile(
                      leading: const IconBox(icon: Icons.image, color: Colors.pink),
                      title: Text('背景图片', overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        settings.backgroundImagePath != null ? '已设置' : '使用默认渐变',
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: settings.backgroundImagePath != null
                          ? IconButton(
                              icon: Icon(Icons.close, size: ResponsiveIconSize.md(context)),
                              onPressed: () => settings.setBackgroundImage(null),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: () => _pickBackgroundImage(settings),
                    ),
                  ),
                  if (settings.backgroundImagePath != null) ...[
                    Builder(builder: (context) => Divider(height: ResponsiveSpacing.xs(context) / 4)),
                    SwitchListTile(
                      secondary: const IconBox(icon: Icons.blur_on, color: Colors.cyan),
                      title: Text('模糊效果', overflow: TextOverflow.ellipsis),
                      value: settings.backgroundEffect == 'blur',
                      onChanged: (v) => settings.setBackgroundEffect(v ? 'blur' : 'none'),
                    ),
                    if (settings.backgroundEffect == 'blur') ...[
                      Builder(
                        builder: (context) => Padding(
                          padding: EdgeInsets.symmetric(horizontal: ResponsiveSpacing.base(context)),
                          child: Slider(
                            value: settings.backgroundBlur,
                            min: 0,
                            max: 30,
                            divisions: 30,
                            label: '${settings.backgroundBlur.toInt()}',
                            onChanged: (value) => settings.setBackgroundBlur(value),
                          ),
                        ),
                      ),
                    ],
                  ],
                  Builder(builder: (context) => Divider(height: ResponsiveSpacing.xs(context) / 4)),
                  // Particles
                  ListTile(
                    leading: const IconBox(icon: Icons.auto_awesome, color: Colors.amber),
                    title: Text('粒子效果', overflow: TextOverflow.ellipsis),
                    subtitle: Text(_getParticleTypeLabel(settings.particleType), overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showParticleDialog(context, settings),
                  ),
                  if (settings.particleEnabled) ...[
                    Builder(builder: (context) => Divider(height: ResponsiveSpacing.xs(context) / 4)),
                    ListTile(
                      leading: const IconBox(icon: Icons.speed, color: Colors.deepOrange),
                      title: Text('粒子速率', overflow: TextOverflow.ellipsis),
                      subtitle: Text('${settings.particleSpeed.toStringAsFixed(1)}x', overflow: TextOverflow.ellipsis),
                    ),
                    Builder(
                      builder: (context) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: ResponsiveSpacing.base(context)),
                        child: Slider(
                          value: settings.particleSpeed,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          label: '${settings.particleSpeed.toStringAsFixed(1)}x',
                          onChanged: (value) => settings.setParticleSpeed(value),
                        ),
                      ),
                    ),
                    Builder(builder: (context) => Divider(height: ResponsiveSpacing.xs(context) / 4)),
                    SwitchListTile(
                      secondary: const IconBox(icon: Icons.visibility, color: Colors.teal),
                      title: Text('全局显示', overflow: TextOverflow.ellipsis),
                      subtitle: Text('包含编辑器区域', overflow: TextOverflow.ellipsis),
                      value: settings.particleGlobal,
                      onChanged: (v) => settings.setParticleGlobal(v),
                    ),
                  ],
                  Builder(builder: (context) => Divider(height: ResponsiveSpacing.xs(context) / 4)),
                  // Progress Style
                  ListTile(
                    leading: const IconBox(icon: Icons.linear_scale, color: Colors.deepPurple),
                    title: Text('进度条样式', overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      settings.progressStyle == 'background' ? '背景进度条' : '标准进度条',
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showProgressStyleDialog(context, settings),
                  ),
                  Builder(builder: (context) => Divider(height: ResponsiveSpacing.xs(context) / 4)),
                  // Calculation
                  ListTile(
                    leading: const IconBox(icon: Icons.calculate, color: Colors.brown),
                    title: Text('进度计算方式', overflow: TextOverflow.ellipsis),
                    subtitle: Text(_getProgressCalculationLabel(settings.progressCalculation), overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showProgressCalculationDialog(context, settings),
                  ),
                  if (settings.progressCalculation == 'fixed') ...[
                    Builder(builder: (context) => Divider(height: ResponsiveSpacing.xs(context) / 4)),
                    ListTile(
                      leading: const IconBox(icon: Icons.timer, color: Colors.grey),
                      title: Text('固定天数', overflow: TextOverflow.ellipsis),
                      subtitle: Text('${settings.progressFixedDays} 天', overflow: TextOverflow.ellipsis),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ResponsiveBorderRadius.lg(context))),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(ResponsiveSpacing.base(context)),
                child: Text('选择主题色', style: TextStyle(fontSize: ResponsiveFontSize.xl(context), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(ResponsiveSpacing.base(context), 0, ResponsiveSpacing.base(context), ResponsiveSpacing.xl(context)),
                child: Wrap(
                  spacing: ResponsiveSpacing.md(context),
                  runSpacing: ResponsiveSpacing.md(context),
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
                        width: ResponsiveUtils.scaledSize(context, 48),
                        height: ResponsiveUtils.scaledSize(context, 48),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: ResponsiveUtils.scaledSize(context, 3),
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: ResponsiveSpacing.md(context))]
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
              SizedBox(height: ResponsiveSpacing.base(context)),
              Text('选择字体', style: TextStyle(fontSize: ResponsiveFontSize.xl(context), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              SizedBox(height: ResponsiveSpacing.base(context)),
              ...fonts.map((font) => ListTile(
                title: Text(font['label']!, overflow: TextOverflow.ellipsis),
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
                title: Text('导入本地字体 (.ttf/.otf)', overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.pop(context);
                  _importFont(context, settings);
                },
              ),
              SizedBox(height: ResponsiveSpacing.base(context)),
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
              SizedBox(height: ResponsiveSpacing.base(context)),
              Text('卡片日期显示', style: TextStyle(fontSize: ResponsiveFontSize.xl(context), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              SizedBox(height: ResponsiveSpacing.base(context)),
              ListTile(
                title: Text('仅剩余天数', overflow: TextOverflow.ellipsis),
                subtitle: Text('如: 3 天', overflow: TextOverflow.ellipsis),
                trailing: settings.cardDisplayFormat == 'days'
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  settings.setCardDisplayFormat('days');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('详细年月日', overflow: TextOverflow.ellipsis),
                subtitle: Text('如: 1年2个月3天', overflow: TextOverflow.ellipsis),
                trailing: settings.cardDisplayFormat == 'detailed'
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  settings.setCardDisplayFormat('detailed');
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: ResponsiveSpacing.base(context)),
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
              SizedBox(height: ResponsiveSpacing.base(context)),
              Text('选择日期格式', style: TextStyle(fontSize: ResponsiveFontSize.xl(context), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              SizedBox(height: ResponsiveSpacing.base(context)),
              ...formats.map((fmt) => ListTile(
                title: Text(fmt, overflow: TextOverflow.ellipsis),
                trailing: settings.dateFormat == fmt
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  settings.setDateFormat(fmt);
                  Navigator.pop(context);
                },
              )),
              SizedBox(height: ResponsiveSpacing.base(context)),
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
              SizedBox(height: ResponsiveSpacing.base(context)),
              Text('粒子效果', style: TextStyle(fontSize: ResponsiveFontSize.xl(context), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              SizedBox(height: ResponsiveSpacing.base(context)),
              ...particles.map((p) => ListTile(
                leading: Icon(p['icon'] as IconData),
                title: Text(p['label'] as String, overflow: TextOverflow.ellipsis),
                trailing: settings.particleType == p['type']
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  settings.setParticleType(p['type'] as String);
                  Navigator.pop(context);
                },
              )),
              SizedBox(height: ResponsiveSpacing.base(context)),
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
              SizedBox(height: ResponsiveSpacing.base(context)),
              Text('进度条样式', style: TextStyle(fontSize: ResponsiveFontSize.xl(context), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              SizedBox(height: ResponsiveSpacing.base(context)),
              ListTile(
                title: Text('标准进度条', overflow: TextOverflow.ellipsis),
                subtitle: Text('经典的线通过度条', overflow: TextOverflow.ellipsis),
                trailing: settings.progressStyle == 'standard'
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  settings.setProgressStyle('standard');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('背景进度条', overflow: TextOverflow.ellipsis),
                subtitle: Text('整个卡片作为进度背景', overflow: TextOverflow.ellipsis),
                trailing: settings.progressStyle == 'background'
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  settings.setProgressStyle('background');
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: ResponsiveSpacing.base(context)),
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
              SizedBox(height: ResponsiveSpacing.base(context)),
              Text('进度计算方式', style: TextStyle(fontSize: ResponsiveFontSize.xl(context), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              SizedBox(height: ResponsiveSpacing.base(context)),
              ...['year', 'month', 'week', 'day', 'fixed'].map((calc) => ListTile(
                title: Text(_getProgressCalculationLabel(calc), overflow: TextOverflow.ellipsis),
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
              SizedBox(height: ResponsiveSpacing.base(context)),
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
        title: Text('设置固定天数', overflow: TextOverflow.ellipsis),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(suffixText: '天'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', overflow: TextOverflow.ellipsis),
          ),
          FilledButton(
            onPressed: () {
              final days = int.tryParse(controller.text) ?? 365;
              settings.setProgressFixedDays(days);
              Navigator.pop(context);
            },
            child: Text('确定', overflow: TextOverflow.ellipsis),
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
              Padding(
                padding: EdgeInsets.all(ResponsiveSpacing.base(context)),
                child: Text('浅色主题方案', style: TextStyle(fontSize: ResponsiveFontSize.xl(context), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: AppConstants.lightThemeSchemes.length,
                itemBuilder: (context, index) {
                  final scheme = AppConstants.lightThemeSchemes[index];
                  final isSelected = settings.lightThemeIndex == index;
                  return ListTile(
                    leading: Container(
                      width: ResponsiveUtils.scaledSize(context, 40),
                      height: ResponsiveUtils.scaledSize(context, 40),
                      decoration: BoxDecoration(
                        color: scheme.background,
                        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.sm(context)),
                        border: Border.all(color: scheme.surface, width: ResponsiveUtils.scaledSize(context, 2)),
                      ),
                      child: Center(
                        child: Container(
                          width: ResponsiveUtils.scaledSize(context, 20),
                          height: ResponsiveUtils.scaledSize(context, 20),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(ResponsiveBorderRadius.xs(context)),
                          ),
                        ),
                      ),
                    ),
                    title: Text(scheme.name, overflow: TextOverflow.ellipsis),
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
              Padding(
                padding: EdgeInsets.all(ResponsiveSpacing.base(context)),
                child: Text('夜间主题方案', style: TextStyle(fontSize: ResponsiveFontSize.xl(context), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: AppConstants.darkThemeSchemes.length,
                itemBuilder: (context, index) {
                  final scheme = AppConstants.darkThemeSchemes[index];
                  final isSelected = settings.darkThemeIndex == index;
                  return ListTile(
                    leading: Container(
                      width: ResponsiveUtils.scaledSize(context, 40),
                      height: ResponsiveUtils.scaledSize(context, 40),
                      decoration: BoxDecoration(
                        color: scheme.background,
                        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.sm(context)),
                        border: Border.all(color: scheme.surface, width: ResponsiveUtils.scaledSize(context, 2)),
                      ),
                      child: Center(
                        child: Container(
                          width: ResponsiveUtils.scaledSize(context, 20),
                          height: ResponsiveUtils.scaledSize(context, 20),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(ResponsiveBorderRadius.xs(context)),
                          ),
                        ),
                      ),
                    ),
                    title: Text(scheme.name, style: const TextStyle(color: Colors.white70), overflow: TextOverflow.ellipsis),
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

