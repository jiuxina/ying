import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../models/widget_font.dart';

/// 在线字体库配置；默认指向 ying 仓库 main 分支的 raw 清单。
abstract final class FontCatalogConfig {
  static const defaultManifestUrl = String.fromEnvironment(
    'FONT_MANIFEST_URL',
    defaultValue:
        'https://raw.githubusercontent.com/jiuxina/ying-321/master/fonts/fonts.json',
  );

  static const maxFontBytes = 25 * 1024 * 1024;
}

class FontCatalogException implements Exception {
  const FontCatalogException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 拉取在线字体库清单；失败时抛出可直接展示的中文错误。
Future<WidgetFontCatalog> fetchFontCatalog({
  Uri? manifestUri,
  http.Client? client,
}) async {
  final uri = manifestUri ?? Uri.parse(FontCatalogConfig.defaultManifestUrl);
  final ownClient = client == null;
  final active = client ?? http.Client();
  try {
    final response = await active
        .get(
          uri,
          headers: const {'User-Agent': 'ying-font-catalog'},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw FontCatalogException('字体清单加载失败（HTTP ${response.statusCode}）');
    }
    try {
      return WidgetFontCatalog.fromJson(
        jsonDecode(response.body) as Map<String, Object?>,
      );
    } on FormatException {
      throw const FontCatalogException('字体清单格式无效，请稍后再试');
    } on TypeError {
      throw const FontCatalogException('字体清单格式无效，请稍后再试');
    }
  } on FontCatalogException {
    rethrow;
  } on http.ClientException {
    throw const FontCatalogException('网络请求失败，请检查网络后重试');
  } catch (_) {
    throw const FontCatalogException('字体清单加载失败，请稍后再试');
  } finally {
    if (ownClient) active.close();
  }
}

/// 下载并校验一个候选字体，返回字节内容。
Future<Uint8List> downloadFontBytes(
  WidgetFontCatalog catalog,
  WidgetFontCatalogEntry entry, {
  http.Client? client,
}) async {
  final uri = fontFileUri(catalog, entry);
  final ownClient = client == null;
  final active = client ?? http.Client();
  try {
    final response = await active
        .get(uri, headers: const {'User-Agent': 'ying-font-download'})
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw FontCatalogException('字体下载失败（HTTP ${response.statusCode}）');
    }
    final bytes = response.bodyBytes;
    if (bytes.isEmpty) {
      throw const FontCatalogException('字体文件为空，请稍后再试');
    }
    if (bytes.length > FontCatalogConfig.maxFontBytes) {
      throw const FontCatalogException('字体文件过大，下载已取消');
    }
    if (bytes.length != entry.bytes) {
      throw const FontCatalogException('字体文件大小与清单不一致，已取消');
    }
    final digest = sha256.convert(bytes).toString();
    if (digest != entry.sha256) {
      throw const FontCatalogException('字体校验失败，已取消下载');
    }
    if (!isSupportedFontBytes(bytes)) {
      throw const FontCatalogException('下载内容不是有效字体文件');
    }
    return bytes;
  } on FontCatalogException {
    rethrow;
  } on http.ClientException {
    throw const FontCatalogException('网络请求失败，请检查网络后重试');
  } catch (_) {
    throw const FontCatalogException('字体下载失败，请稍后再试');
  } finally {
    if (ownClient) active.close();
  }
}

Uri fontFileUri(WidgetFontCatalog catalog, WidgetFontCatalogEntry entry) {
  final base = catalog.baseUrl.replaceAll(RegExp(r'/$'), '');
  final uri = Uri.parse('$base/${entry.file}');
  if (uri.scheme != 'https') {
    throw const FontCatalogException('字体下载地址不安全，已取消');
  }
  return uri;
}

/// TTF/OTF 魔数校验：TrueType、OpenType 与 TrueType Collection。
bool isSupportedFontBytes(Uint8List bytes) {
  if (bytes.length < 4) return false;
  if (bytes[0] == 0x00 &&
      bytes[1] == 0x01 &&
      bytes[2] == 0x00 &&
      bytes[3] == 0x00) {
    return true;
  }
  if (bytes[0] == 0x4F && bytes[1] == 0x54 && bytes[2] == 0x54) {
    return bytes[3] == 0x4F;
  }
  if (bytes[0] == 0x74 &&
      bytes[1] == 0x74 &&
      bytes[2] == 0x63 &&
      bytes[3] == 0x66) {
    return true;
  }
  return false;
}
