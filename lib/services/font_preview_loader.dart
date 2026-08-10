import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show FontLoader;

import '../models/widget_font.dart';

/// 把已安装字体注册成 Flutter 运行时字体，供应用内小部件预览使用。
class FontPreviewLoader {
  static final Set<String> _loadedFamilies = {};

  static Future<void> ensureLoaded(WidgetFontAsset asset) async {
    final family = widgetFontFamilyForAsset(asset);
    if (_loadedFamilies.contains(family)) return;
    final bytes = await File(asset.filePath).readAsBytes();
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    _loadedFamilies.add(family);
  }
}
