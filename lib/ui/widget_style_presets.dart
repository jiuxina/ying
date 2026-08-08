import 'package:flutter/material.dart';

import '../models/app_settings.dart';

/// 设置页与预览共用的样式预设元数据，保持入口与视觉一一对应。
const widgetStylePresets = <(WidgetStyle, String, IconData)>[
  (WidgetStyle.card, '卡片', Icons.crop_square_rounded),
  (WidgetStyle.sticker, '贴纸', Icons.sell_outlined),
  (WidgetStyle.photo, '照片', Icons.photo_outlined),
  (WidgetStyle.glass, '玻璃', Icons.blur_on_rounded),
  (WidgetStyle.polaroid, '拍立得', Icons.camera_alt_outlined),
  (WidgetStyle.neon, '霓虹', Icons.bolt_rounded),
  (WidgetStyle.pixel, '像素', Icons.grid_view_rounded),
  (WidgetStyle.minimal, '极简', Icons.auto_awesome_outlined),
];

String widgetStyleLabel(WidgetStyle style) {
  return widgetStylePresets
      .firstWhere((preset) => preset.$1 == style)
      .$2;
}
