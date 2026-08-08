import 'dart:convert';

import 'update_fetcher.dart';

/// GitHub 上最新一次发布的信息。
class ReleaseInfo {
  const ReleaseInfo({
    required this.version,
    required this.url,
    this.name,
    this.notes,
    this.publishedAt,
  });

  /// 规范化后的版本号，如 `2.1.0`。
  final String version;

  /// 发布页链接。
  final String url;
  final String? name;

  /// 发布说明正文。
  final String? notes;
  final DateTime? publishedAt;
}

/// 一次检测的结果：[errorMessage] 非空表示失败；
/// 否则 [release] 为最新版本，[isNewer] 表示是否比当前版本更新。
class UpdateCheckResult {
  const UpdateCheckResult({
    this.release,
    this.isNewer = false,
    this.errorMessage,
  });

  final ReleaseInfo? release;
  final bool isNewer;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
}

typedef ReleaseFetcher = Future<FetchResult> Function(Uri url);

/// 通过 GitHub API 检测仓库的最新发布。
class UpdateService {
  UpdateService({
    ReleaseFetcher? fetcher,
    this.owner = defaultOwner,
    this.repo = defaultRepo,
  }) : fetcher = fetcher ?? fetchUrl;

  static const defaultOwner = 'jiuxina';
  static const defaultRepo = 'ying';

  final ReleaseFetcher fetcher;
  final String owner;
  final String repo;

  Uri get _latestReleaseUri => Uri.parse(
    'https://api.github.com/repos/$owner/$repo/releases/latest',
  );

  Uri get _tagsUri => Uri.parse(
    'https://api.github.com/repos/$owner/$repo/tags?per_page=30',
  );

  Future<UpdateCheckResult> checkForUpdate({
    required String currentVersion,
  }) async {
    try {
      final release = await fetchLatestRelease();
      if (release == null) {
        return const UpdateCheckResult(errorMessage: '仓库暂无发布');
      }
      return UpdateCheckResult(
        release: release,
        isNewer: compareVersions(release.version, currentVersion) > 0,
      );
    } on UpdateFetchException catch (error) {
      return UpdateCheckResult(errorMessage: error.message);
    } on FormatException {
      return const UpdateCheckResult(errorMessage: '发布信息解析失败，请稍后再试');
    } catch (_) {
      return const UpdateCheckResult(errorMessage: '网络请求失败，请检查网络后重试');
    }
  }

  /// 拉取最新发布；仓库没有 Release 时回退到最新的 tag。
  Future<ReleaseInfo?> fetchLatestRelease() async {
    final response = await fetcher(_latestReleaseUri);
    if (response.statusCode == 200) {
      return _parseRelease(jsonDecode(response.body) as Map<String, Object?>);
    }
    if (response.statusCode == 404) {
      return _fetchLatestTag();
    }
    throw _errorForStatus(response.statusCode);
  }

  Future<ReleaseInfo?> _fetchLatestTag() async {
    final response = await fetcher(_tagsUri);
    if (response.statusCode != 200) {
      throw _errorForStatus(response.statusCode);
    }
    final tags = jsonDecode(response.body);
    if (tags is! List || tags.isEmpty) return null;
    String? bestTag;
    for (final item in tags) {
      if (item is! Map) continue;
      final name = item['name'];
      if (name is! String || normalizeVersion(name).isEmpty) continue;
      if (bestTag == null || compareVersions(name, bestTag) > 0) {
        bestTag = name;
      }
    }
    if (bestTag == null) return null;
    return ReleaseInfo(
      version: normalizeVersion(bestTag),
      url: 'https://github.com/$owner/$repo/releases/tag/$bestTag',
      name: bestTag,
    );
  }

  ReleaseInfo _parseRelease(Map<String, Object?> json) {
    final tag = json['tag_name'];
    return ReleaseInfo(
      version: normalizeVersion(tag is String ? tag : ''),
      url: (json['html_url'] as String?) ??
          'https://github.com/$owner/$repo/releases',
      name: json['name'] as String?,
      notes: json['body'] as String?,
      publishedAt: DateTime.tryParse((json['published_at'] as String?) ?? ''),
    );
  }

  UpdateFetchException _errorForStatus(int statusCode) {
    if (statusCode == 403 || statusCode == 429) {
      return const UpdateFetchException('请求过于频繁，请稍后再试');
    }
    return UpdateFetchException('检查更新失败（HTTP $statusCode）');
  }
}

/// 去掉 `v` 前缀与预发布/构建后缀，如 `v2.1.0-beta+3` → `2.1.0`；
/// 无法解析为空字符串。
String normalizeVersion(String raw) {
  var version = raw.trim();
  if (version.startsWith('v') || version.startsWith('V')) {
    version = version.substring(1);
  }
  final suffix = version.indexOf(RegExp(r'[-+\s]'));
  if (suffix >= 0) version = version.substring(0, suffix);
  if (version.isEmpty) return '';
  final valid = version
      .split('.')
      .every((part) => part.isNotEmpty && int.tryParse(part) != null);
  return valid ? version : '';
}

/// 按语义化版本逐段比较，位宽不同时以 0 补齐。
int compareVersions(String a, String b) {
  final left = _versionSegments(a);
  final right = _versionSegments(b);
  final length = left.length > right.length ? left.length : right.length;
  for (var index = 0; index < length; index++) {
    final l = index < left.length ? left[index] : 0;
    final r = index < right.length ? right[index] : 0;
    if (l != r) return l.compareTo(r);
  }
  return 0;
}

List<int> _versionSegments(String raw) {
  final version = normalizeVersion(raw);
  if (version.isEmpty) return const [0];
  return version.split('.').map(int.parse).toList();
}
