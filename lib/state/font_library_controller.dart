import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../models/widget_font.dart';
import '../services/font_library_service.dart';
import '../services/font_preview_loader.dart';

class FontLibraryController extends ChangeNotifier {
  FontLibraryController({this.directory});

  final Directory? directory;

  List<WidgetFontAsset> installed = const [];
  bool loading = true;

  Future<void> load() async {
    try {
      installed = await FontLibraryService.loadRegistry(dir: directory);
    } catch (_) {
      installed = const [];
    }
    loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      installed = await FontLibraryService.loadRegistry(dir: directory);
    } catch (_) {
      installed = const [];
    }
    notifyListeners();
    fontLibraryRevision.value++;
  }

  /// 为当前设置选中的自定义字体注册预览字体族；失败时静默回退系统字体。
  Future<void> ensureSelectedFonts(AppSettings settings) async {
    for (final selection in [
      settings.widgetFontFamily,
      settings.widgetTextFontFamily,
    ]) {
      final asset = FontLibraryService.findAssetBySelection(
        installed,
        selection,
      );
      if (asset == null) continue;
      try {
        await FontPreviewLoader.ensureLoaded(asset).timeout(
          const Duration(seconds: 2),
        );
      } catch (_) {
        // 预览字体加载失败不阻塞设置页。
      }
    }
  }
}

final fontLibraryProvider = ChangeNotifierProvider<FontLibraryController>(
  (ref) => FontLibraryController()..load(),
);
