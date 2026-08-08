import 'dart:math' as math;

import 'package:flutter/services.dart';

/// Android 壁纸取色结果：主色、深色与保证可读性的文字色。
class WallpaperColorResult {
  const WallpaperColorResult({
    required this.primary,
    required this.dark,
    required this.text,
  });

  final int primary;
  final int dark;
  final int text;
}

/// 通过原生通道读取 [WallpaperManager] 颜色，失败或平台不支持时返回 null。
class WallpaperColorService {
  static const _channel = MethodChannel('ying/wallpaper');

  static Future<WallpaperColorResult?> fetch() async {
    try {
      final values = await _channel.invokeMapMethod<Object?, Object?>(
        'getWallpaperColors',
      );
      if (values == null) return null;
      final primary = values['primary'] as int?;
      final dark = values['dark'] as int?;
      final text = values['text'] as int?;
      if (primary == null || dark == null || text == null) return null;
      return WallpaperColorResult(
        primary: primary,
        dark: dark,
        text: text,
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

/// 按相对亮度选择黑/白文字色，供取色结果缺失时兜底。
int contrastTextColor(int argb) {
  final red = (argb >> 16) & 0xFF;
  final green = (argb >> 8) & 0xFF;
  final blue = argb & 0xFF;
  final luminance = 0.2126 * _linearize(red) +
      0.7152 * _linearize(green) +
      0.0722 * _linearize(blue);
  return luminance > 0.45 ? 0xFF101418 : 0xFFFFFFFF;
}

double _linearize(int channel) {
  final value = channel / 255.0;
  return value <= 0.04045
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
}
