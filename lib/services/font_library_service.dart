import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/widget_font.dart';
import 'font_catalog_service.dart';

/// 字体库变更版本号；应用内预览监听它重新加载自定义字体。
final ValueNotifier<int> fontLibraryRevision = ValueNotifier<int>(0);

/// 本地字体文件与注册表管理；注册表保存在应用文档目录 `fonts/registry.json`。
class FontLibraryService {
  const FontLibraryService();

  static Future<Directory> fontsDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${documents.path}${Platform.pathSeparator}fonts',
    );
    await dir.create(recursive: true);
    return dir;
  }

  static Future<List<WidgetFontAsset>> loadRegistry({
    Directory? dir,
  }) async {
    final target = dir ?? await fontsDirectory();
    final file = File('${target.path}${Platform.pathSeparator}registry.json');
    if (!await file.exists()) return const [];
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (value) => WidgetFontAsset.fromJson(
              Map<String, Object?>.from(value),
            ),
          )
          .where((asset) => asset.id.isNotEmpty && asset.filePath.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> saveRegistry(
    List<WidgetFontAsset> assets, {
    Directory? dir,
  }) async {
    final target = dir ?? await fontsDirectory();
    final file = File('${target.path}${Platform.pathSeparator}registry.json');
    await file.writeAsString(
      jsonEncode(assets.map((asset) => asset.toJson()).toList()),
      flush: true,
    );
  }

  static String sanitizeFontId(String id) =>
      id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  static String fileExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot < 0 ? 'ttf' : fileName.substring(dot + 1).toLowerCase();
  }

  /// 安装在线候选字体到字体库并写回注册表。
  static Future<WidgetFontAsset> installCatalogFont(
    WidgetFontCatalogEntry entry,
    Uint8List bytes, {
    Directory? dir,
  }) async {
    final target = dir ?? await fontsDirectory();
    final safeId = sanitizeFontId(entry.id);
    final fileName = '$safeId.${fileExtension(entry.file)}';
    final file = File('${target.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    final asset = WidgetFontAsset(
      id: safeId,
      name: entry.name,
      kind: entry.kind,
      source: WidgetFontSource.catalog,
      filePath: file.path,
      bytes: bytes.length,
      sha256: entry.sha256,
      licenseName: entry.licenseName,
      licenseUrl: entry.licenseUrl,
    );
    final registry = await loadRegistry(dir: target);
    final next = [
      asset,
      ...registry.where((value) => value.id != asset.id),
    ];
    await saveRegistry(next, dir: target);
    return asset;
  }

  /// 导入本地字体文件；返回已注册的字体资产。
  static Future<WidgetFontAsset> installLocalFont({
    required File source,
    required WidgetFontKind kind,
    required String name,
    Directory? dir,
  }) async {
    if (!await source.exists()) {
      throw const FontCatalogException('所选字体文件不存在');
    }
    final extension = fileExtension(source.path);
    if (extension != 'ttf' && extension != 'otf') {
      throw const FontCatalogException('仅支持 TTF 或 OTF 字体文件');
    }
    final bytes = await source.readAsBytes();
    if (bytes.isEmpty) {
      throw const FontCatalogException('字体文件为空，请换一个文件');
    }
    if (bytes.length > FontCatalogConfig.maxFontBytes) {
      throw const FontCatalogException('字体文件过大，无法导入');
    }
    if (!isSupportedFontBytes(bytes)) {
      throw const FontCatalogException('所选文件不是有效的 TTF/OTF 字体');
    }
    final target = dir ?? await fontsDirectory();
    final id = 'imported-${DateTime.now().microsecondsSinceEpoch}';
    final fileName = '$id.$extension';
    final file = File('${target.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    final digest = sha256.convert(bytes).toString();
    final asset = WidgetFontAsset(
      id: id,
      name: name.trim().isEmpty ? '本地字体' : name.trim(),
      kind: kind,
      source: WidgetFontSource.local,
      filePath: file.path,
      bytes: bytes.length,
      sha256: digest,
    );
    final registry = await loadRegistry(dir: target);
    await saveRegistry([...registry, asset], dir: target);
    return asset;
  }

  /// 删除字体文件与注册表条目；已应用字体由调用方先回退设置。
  static Future<void> removeFont(
    WidgetFontAsset asset, {
    Directory? dir,
  }) async {
    final target = dir ?? await fontsDirectory();
    try {
      final file = File(asset.filePath);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // 文件删除失败不阻塞注册表更新，下次清理会再尝试。
    }
    final registry = await loadRegistry(dir: target);
    await saveRegistry(
      registry.where((value) => value.id != asset.id).toList(),
      dir: target,
    );
  }

  static WidgetFontAsset? findAssetBySelection(
    List<WidgetFontAsset> assets,
    String selection,
  ) {
    final id = widgetFontIdFromSelection(selection);
    if (id == null) return null;
    for (final asset in assets) {
      if (asset.id == id) return asset;
    }
    return null;
  }
}
