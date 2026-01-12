import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final String? backgroundImage;
  final bool? enableBlur;
  final double? blurAmount;

  const AppBackground({
    super.key,
    required this.child,
    this.backgroundImage,
    this.enableBlur,
    this.blurAmount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        // 基础渐变背景
        Widget content = Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.getGradientColors(isDark),
            ),
          ),
          child: child,
        );

        // 确定使用的背景图片路径
        final bgPath = backgroundImage ?? settings.backgroundImagePath;
        
        // 确定是否启用模糊
        final shouldBlur = enableBlur ?? (settings.backgroundEffect == 'blur');
        
        // 确定模糊程度
        final blurRadius = blurAmount ?? settings.backgroundBlur;

        // 应用背景图片
        if (bgPath != null) {
          final bgFile = File(bgPath);
          if (bgFile.existsSync()) {
            Widget bgImage = Image.file(
              bgFile,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );

            // 应用模糊效果
            if (shouldBlur) {
              bgImage = ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: blurRadius,
                  sigmaY: blurRadius,
                ),
                child: bgImage,
              );
            }

            content = Stack(
              fit: StackFit.expand,
              children: [
                bgImage,
                // 半透明遮罩
                Container(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.3),
                ),
                child,
              ],
            );
          }
        }

        return content;
      },
    );
  }
}
