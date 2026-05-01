// ============================================================================
// 背景设置页面
//
// 包含：背景图片、背景效果（模糊、亮度）、粒子特效
// 排除：编辑器相关背景设置
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/common/app_background.dart';
import '../../../widgets/common/ui_helpers.dart';
import 'appearance_settings_mixin.dart';

class BackgroundSettingsScreen extends StatefulWidget {
  const BackgroundSettingsScreen({super.key});

  @override
  State<BackgroundSettingsScreen> createState() =>
      _BackgroundSettingsScreenState();
}

class _BackgroundSettingsScreenState extends State<BackgroundSettingsScreen>
    with AppearanceSettingsMixin {
  final ImagePicker _picker = ImagePicker();

  /// 临时背景亮度值（用于实时预览）
  double _pendingBackgroundBrightness = 1.0;

  @override
  void initState() {
    super.initState();
    // 初始化临时值
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      setState(() {
        _pendingBackgroundBrightness = settings.backgroundBrightness;
      });
    });
  }

  /// 选择背景图片
  Future<void> _pickBackgroundImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        final settings = context.read<SettingsProvider>();
        await settings.setBackgroundImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.selectImage}: $e')),
        );
      }
    }
  }

  /// 移除背景图片
  void _removeBackgroundImage() {
    final settings = context.read<SettingsProvider>();
    settings.setBackgroundImage(null);
  }

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
                    // 初始化临时值
                    _pendingBackgroundBrightness = settings.backgroundBrightness;

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // 背景图片设置
                        buildSection(l10n.background, Icons.image, [
                          _buildBackgroundSettings(settings, l10n),
                        ]),

                        const SizedBox(height: 16),

                        // 粒子特效设置
                        buildSection(l10n.particleEffect, Icons.auto_awesome, [
                          _buildParticleSettings(settings, l10n),
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
            l10n.backgroundSettings,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  /// 构建背景图片设置
  Widget _buildBackgroundSettings(SettingsProvider settings, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 选择背景图片按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.background),
            TextButton.icon(
              onPressed: _pickBackgroundImage,
              icon: const Icon(Icons.image, size: 18),
              label: Text(l10n.selectImage),
            ),
          ],
        ),

        if (settings.backgroundImagePath != null) ...[
          const SizedBox(height: 8),

          // 背景预览
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(settings.backgroundImagePath!),
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(l10n.selectImage)),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 模糊效果开关
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.blurEffect),
              Switch(
                value: settings.backgroundEffect == 'blur',
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  settings.setBackgroundEffect(value ? 'blur' : 'none');
                },
              ),
            ],
          ),

          // 模糊强度滑块（仅在启用模糊时显示）
          if (settings.backgroundEffect == 'blur') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(l10n.blurStrength),
                Expanded(
                  child: Slider(
                    value: settings.backgroundBlur,
                    min: 0,
                    max: 30,
                    divisions: 30,
                    label: settings.backgroundBlur.round().toString(),
                    onChanged: (value) => settings.setBackgroundBlur(value),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${settings.backgroundBlur.round()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          // 背景亮度滑块
          Row(
            children: [
              Text(l10n.brightness),
              Expanded(
                child: Slider(
                  value: _pendingBackgroundBrightness,
                  min: 0.2,
                  max: 1.8,
                  divisions: 16,
                  label: '${(_pendingBackgroundBrightness * 100).round()}%',
                  onChanged: (value) {
                    setState(() {
                      _pendingBackgroundBrightness = value;
                    });
                    settings.setBackgroundBrightness(value);
                  },
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${(_pendingBackgroundBrightness * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 移除背景按钮
          TextButton.icon(
            onPressed: _removeBackgroundImage,
            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
            label: Text(
              l10n.clearBackground,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ],
    );
  }

  /// 构建粒子特效设置
  Widget _buildParticleSettings(SettingsProvider settings, AppLocalizations l10n) {
    final particleTypes = [
      {'id': 'none', 'name': l10n.off, 'icon': Icons.block},
      {'id': 'sakura', 'name': l10n.particleSakura, 'icon': Icons.local_florist},
      {'id': 'rain', 'name': l10n.particleRain, 'icon': Icons.water_drop},
      {'id': 'firefly', 'name': l10n.particleFirefly, 'icon': Icons.auto_awesome},
      {'id': 'snow', 'name': l10n.particleSnow, 'icon': Icons.ac_unit},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 效果类型选择器
        Text(
          l10n.particleType,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        // 使用 GridView 来显示粒子类型选择器
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
          ),
          itemCount: particleTypes.length,
          itemBuilder: (context, index) {
            final type = particleTypes[index];
            final isSelected = settings.particleType == type['id'];
            final primary = Theme.of(context).colorScheme.primary;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                settings.setParticleType(type['id'] as String);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? primary : Theme.of(context).dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type['icon'] as IconData,
                      size: 18,
                      color: isSelected
                          ? primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        type['name'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // 仅在启用粒子时显示速度滑块
        if (settings.particleEnabled) ...[
          const SizedBox(height: 16),
          Text(
            l10n.particleSpeed,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(l10n.particleSpeed),
              Expanded(
                child: Slider(
                  value: settings.particleSpeed,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: '${(settings.particleSpeed * 100).round()}%',
                  onChanged: (value) => settings.setParticleSpeed(value),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${(settings.particleSpeed * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
