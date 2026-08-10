/// 字体用途：数字、文字，或两者通用。
enum WidgetFontKind {
  digit,
  text,
  both;

  bool get coversDigits => this == digit || this == both;

  bool get coversText => this == text || this == both;

  static WidgetFontKind fromName(String? name) =>
      WidgetFontKind.values.firstWhere(
        (kind) => kind.name == name,
        orElse: () => WidgetFontKind.both,
      );
}

/// 字体来源：在线字体库或用户本地导入。
enum WidgetFontSource { catalog, local }

/// 在线字体库中的一条候选。
class WidgetFontCatalogEntry {
  const WidgetFontCatalogEntry({
    required this.id,
    required this.name,
    required this.kind,
    required this.file,
    required this.bytes,
    required this.sha256,
    this.licenseName,
    this.licenseUrl,
  });

  final String id;
  final String name;
  final WidgetFontKind kind;
  final String file;
  final int bytes;
  final String sha256;
  final String? licenseName;
  final String? licenseUrl;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'file': file,
    'bytes': bytes,
    'sha256': sha256,
    'licenseName': licenseName,
    'licenseUrl': licenseUrl,
  };

  factory WidgetFontCatalogEntry.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final name = json['name'];
    final kind = json['kind'];
    final file = json['file'];
    final bytes = json['bytes'];
    final sha256 = json['sha256'];
    if (id is! String ||
        name is! String ||
        kind is! String ||
        file is! String ||
        bytes is! num ||
        sha256 is! String) {
      throw const FormatException('字体清单条目缺少必需字段');
    }
    return WidgetFontCatalogEntry(
      id: id,
      name: name,
      kind: WidgetFontKind.fromName(kind),
      file: file,
      bytes: bytes.toInt(),
      sha256: sha256.toLowerCase(),
      licenseName: json['licenseName'] as String?,
      licenseUrl: json['licenseUrl'] as String?,
    );
  }
}

/// 在线字体库清单。
class WidgetFontCatalog {
  const WidgetFontCatalog({
    required this.version,
    required this.baseUrl,
    required this.fonts,
  });

  final int version;
  final String baseUrl;
  final List<WidgetFontCatalogEntry> fonts;

  factory WidgetFontCatalog.fromJson(Map<String, Object?> json) {
    final version = json['version'];
    final baseUrl = json['baseUrl'];
    final rawFonts = json['fonts'];
    if (version is! num || baseUrl is! String || rawFonts is! List) {
      throw const FormatException('字体清单格式无效');
    }
    return WidgetFontCatalog(
      version: version.toInt(),
      baseUrl: baseUrl,
      fonts: rawFonts
          .whereType<Map>()
          .map(
            (value) => WidgetFontCatalogEntry.fromJson(
              Map<String, Object?>.from(value),
            ),
          )
          .toList(),
    );
  }
}

/// 已安装到本机的字体。
class WidgetFontAsset {
  const WidgetFontAsset({
    required this.id,
    required this.name,
    required this.kind,
    required this.source,
    required this.filePath,
    required this.bytes,
    required this.sha256,
    this.licenseName,
    this.licenseUrl,
  });

  final String id;
  final String name;
  final WidgetFontKind kind;
  final WidgetFontSource source;
  final String filePath;
  final int bytes;
  final String sha256;
  final String? licenseName;
  final String? licenseUrl;

  String get selection => widgetFontSelection(source: source, id: id);

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'source': source.name,
    'filePath': filePath,
    'bytes': bytes,
    'sha256': sha256,
    'licenseName': licenseName,
    'licenseUrl': licenseUrl,
  };

  factory WidgetFontAsset.fromJson(Map<String, Object?> json) {
    return WidgetFontAsset(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '字体',
      kind: WidgetFontKind.fromName(json['kind'] as String?),
      source: json['source'] == 'local'
          ? WidgetFontSource.local
          : WidgetFontSource.catalog,
      filePath: json['filePath'] as String? ?? '',
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      sha256: (json['sha256'] as String? ?? '').toLowerCase(),
      licenseName: json['licenseName'] as String?,
      licenseUrl: json['licenseUrl'] as String?,
    );
  }
}

/// 组合设置值：`catalog:<id>` 或 `local:<id>`。
String widgetFontSelection({
  required WidgetFontSource source,
  required String id,
}) => '${source.name}:$id';

bool isCatalogFontSelection(String selection) =>
    selection.startsWith('catalog:');

bool isLocalFontSelection(String selection) => selection.startsWith('local:');

bool isCustomFontSelection(String selection) =>
    isCatalogFontSelection(selection) || isLocalFontSelection(selection);

/// 从设置值里取出字体 id；非自定义字体返回 null。
String? widgetFontIdFromSelection(String selection) {
  if (isCatalogFontSelection(selection)) {
    return selection.substring('catalog:'.length);
  }
  if (isLocalFontSelection(selection)) {
    return selection.substring('local:'.length);
  }
  return null;
}

/// Flutter 预览用的字体族名，与文件内容绑定，更新后自动换新族。
String widgetFontFamilyForAsset(WidgetFontAsset asset) =>
    'yingFont-${asset.id}-${asset.sha256.substring(0, asset.sha256.length < 12 ? asset.sha256.length : 12)}';

String widgetFontKindLabel(WidgetFontKind kind) => switch (kind) {
  WidgetFontKind.digit => '数字',
  WidgetFontKind.text => '文字',
  WidgetFontKind.both => '数字 / 文字',
};
