import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ying/models/widget_font.dart';
import 'package:ying/services/font_catalog_service.dart';
import 'package:ying/services/font_library_service.dart';

void main() {
  final sampleCatalogJson = <String, Object?>{
    'version': 1,
    'baseUrl': 'https://raw.githubusercontent.com/jiuxina/ying-321/master/fonts/files',
    'fonts': [
      {
        'id': 'dseg7',
        'name': 'DSEG7',
        'kind': 'digit',
        'file': 'DSEG7-Classic-Bold.ttf',
        'bytes': 128,
        'sha256': 'a' * 64,
        'licenseName': 'OFL-1.1',
      },
    ],
  };

  test('parses catalog and joins file urls', () {
    final catalog = WidgetFontCatalog.fromJson(
      Map<String, Object?>.from(sampleCatalogJson),
    );
    expect(catalog.version, 1);
    expect(catalog.fonts, hasLength(1));
    expect(catalog.fonts.single.kind, WidgetFontKind.digit);
    final uri = fontFileUri(catalog, catalog.fonts.single);
    expect(
      uri.toString(),
      'https://raw.githubusercontent.com/jiuxina/ying-321/master/fonts/files/'
          'DSEG7-Classic-Bold.ttf',
    );
  });

  test('rejects malformed catalog', () {
    expect(
      () => WidgetFontCatalog.fromJson(const {'fonts': []}),
      throwsFormatException,
    );
    expect(
      () => WidgetFontCatalog.fromJson({
        'version': 1,
        'baseUrl': 'https://example.com',
        'fonts': [
          {'id': 'missing-fields'},
        ],
      }),
      throwsFormatException,
    );
  });

  test('selection helpers round-trip catalog and local ids', () {
    expect(
      widgetFontSelection(
        source: WidgetFontSource.catalog,
        id: 'orbitron',
      ),
      'catalog:orbitron',
    );
    expect(
      widgetFontSelection(source: WidgetFontSource.local, id: 'imported-1'),
      'local:imported-1',
    );
    expect(widgetFontIdFromSelection('catalog:orbitron'), 'orbitron');
    expect(widgetFontIdFromSelection('local:imported-1'), 'imported-1');
    expect(widgetFontIdFromSelection('system'), isNull);
    expect(isCatalogFontSelection('catalog:x'), isTrue);
    expect(isLocalFontSelection('local:x'), isTrue);
  });

  test('font magic validation accepts ttf otf and rejects others', () {
    final ttf = Uint8List.fromList([0x00, 0x01, 0x00, 0x00]);
    final otf = Uint8List.fromList([0x4F, 0x54, 0x54, 0x4F]);
    final bad = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
    expect(isSupportedFontBytes(ttf), isTrue);
    expect(isSupportedFontBytes(otf), isTrue);
    expect(isSupportedFontBytes(bad), isFalse);
  });

  test('install, load, apply and remove font in temp directory', () async {
    final dir = await Directory.systemTemp.createTemp('ying-font-test');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final bytes = Uint8List.fromList([0x00, 0x01, 0x00, 0x00, 0x2A]);
    final entry = WidgetFontCatalogEntry(
      id: 'test-font',
      name: '测试字体',
      kind: WidgetFontKind.both,
      file: 'test-font.ttf',
      bytes: bytes.length,
      sha256: sha256.convert(bytes).toString(),
      licenseName: 'OFL-1.1',
    );
    final asset = await FontLibraryService.installCatalogFont(
      entry,
      bytes,
      dir: dir,
    );
    expect(asset.selection, 'catalog:test-font');
    expect(asset.kind, WidgetFontKind.both);
    expect(
      await FontLibraryService.loadRegistry(dir: dir),
      hasLength(1),
    );

    final localSource = File('${dir.path}${Platform.pathSeparator}local.ttf');
    await localSource.writeAsBytes(bytes, flush: true);
    final local = await FontLibraryService.installLocalFont(
      source: localSource,
      kind: WidgetFontKind.text,
      name: '本地文字',
      dir: dir,
    );
    expect(local.selection, startsWith('local:'));
    expect(
      FontLibraryService.findAssetBySelection(
        await FontLibraryService.loadRegistry(dir: dir),
        'catalog:test-font',
      )?.name,
      '测试字体',
    );

    await FontLibraryService.removeFont(asset, dir: dir);
    final remaining = await FontLibraryService.loadRegistry(dir: dir);
    expect(remaining, hasLength(1));
    expect(remaining.single.id, local.id);
  });

  test('registry round-trips through json', () {
    final asset = WidgetFontAsset(
      id: 'round',
      name: '往返',
      kind: WidgetFontKind.digit,
      source: WidgetFontSource.catalog,
      filePath: '/tmp/round.ttf',
      bytes: 42,
      sha256: 'b' * 64,
      licenseName: 'OFL-1.1',
    );
    final restored = WidgetFontAsset.fromJson(
      jsonDecode(jsonEncode(asset.toJson())) as Map<String, dynamic>,
    );
    expect(restored.id, asset.id);
    expect(restored.selection, asset.selection);
    expect(restored.sha256, asset.sha256);
  });
}
