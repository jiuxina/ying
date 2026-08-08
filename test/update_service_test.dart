import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ying/services/update_fetcher.dart';
import 'package:ying/services/update_service.dart';

void main() {
  group('normalizeVersion', () {
    test('strips v prefix, build and pre-release suffixes', () {
      expect(normalizeVersion('v2.0.0'), '2.0.0');
      expect(normalizeVersion('V1.2.3'), '1.2.3');
      expect(normalizeVersion('2.0.0+5'), '2.0.0');
      expect(normalizeVersion('2.0.0-beta.1'), '2.0.0');
      expect(normalizeVersion(' 2.1.0 '), '2.1.0');
    });

    test('rejects non-numeric tags', () {
      expect(normalizeVersion('nightly'), '');
      expect(normalizeVersion('v2.x'), '');
      expect(normalizeVersion(''), '');
    });
  });

  group('compareVersions', () {
    test('compares segment by segment', () {
      expect(compareVersions('2.0.0', '2.0.0'), 0);
      expect(compareVersions('v2.1.0', '2.0.9'), greaterThan(0));
      expect(compareVersions('1.9.9', 'v2.0.0'), lessThan(0));
      expect(compareVersions('2.10.0', '2.9.9'), greaterThan(0));
    });

    test('pads missing segments and ignores metadata', () {
      expect(compareVersions('2.0', '2.0.0'), 0);
      expect(compareVersions('2.0.1', '2.0'), greaterThan(0));
      expect(compareVersions('2.0.0+5', '2.0.0'), 0);
    });
  });

  group('UpdateService.checkForUpdate', () {
    UpdateService serviceFor(Map<String, FetchResult> responses) {
      return UpdateService(
        fetcher: (uri) async {
          final result = responses[uri.path];
          if (result == null) {
            throw const UpdateFetchException('未预期的请求');
          }
          return result;
        },
      );
    }

    String releaseJson({
      String tag = 'v2.1.0',
      String? name = '全新小组件',
      String? body = '- 支持桌面小组件\n- 修复若干问题',
    }) {
      return jsonEncode({
        'tag_name': tag,
        'name': name,
        'body': body,
        'html_url': 'https://github.com/jiuxina/ying/releases/tag/$tag',
        'published_at': '2026-08-01T12:00:00Z',
      });
    }

    test('parses latest release and flags newer version', () async {
      final service = serviceFor({
        '/repos/jiuxina/ying/releases/latest': FetchResult(
          200,
          releaseJson(),
        ),
      });

      final result = await service.checkForUpdate(currentVersion: '2.0.0');
      expect(result.hasError, isFalse);
      expect(result.isNewer, isTrue);
      expect(result.release?.version, '2.1.0');
      expect(result.release?.name, '全新小组件');
      expect(result.release?.notes, contains('桌面小组件'));
      expect(
        result.release?.url,
        'https://github.com/jiuxina/ying/releases/tag/v2.1.0',
      );
      expect(result.release?.publishedAt, DateTime.utc(2026, 8, 1, 12));
    });

    test('reports up-to-date when release is older', () async {
      final service = serviceFor({
        '/repos/jiuxina/ying/releases/latest': FetchResult(
          200,
          releaseJson(tag: 'v1.9.0'),
        ),
      });

      final result = await service.checkForUpdate(currentVersion: '2.0.0');
      expect(result.isNewer, isFalse);
      expect(result.release?.version, '1.9.0');
    });

    test('falls back to the highest tag without releases', () async {
      final service = serviceFor({
        '/repos/jiuxina/ying/releases/latest': const FetchResult(404, ''),
        '/repos/jiuxina/ying/tags': FetchResult(
          200,
          jsonEncode([
            {'name': '1.0.0'},
            {'name': 'v2.0.0'},
            {'name': 'nightly'},
          ]),
        ),
      });

      final result = await service.checkForUpdate(currentVersion: '1.0.0');
      expect(result.hasError, isFalse);
      expect(result.isNewer, isTrue);
      expect(result.release?.version, '2.0.0');
      expect(
        result.release?.url,
        'https://github.com/jiuxina/ying/releases/tag/v2.0.0',
      );
    });

    test('reports missing releases when tag list is empty', () async {
      final service = serviceFor({
        '/repos/jiuxina/ying/releases/latest': const FetchResult(404, ''),
        '/repos/jiuxina/ying/tags': const FetchResult(200, '[]'),
      });

      final result = await service.checkForUpdate(currentVersion: '2.0.0');
      expect(result.errorMessage, '仓库暂无发布');
    });

    test('surfaces rate limiting with a friendly message', () async {
      final service = serviceFor({
        '/repos/jiuxina/ying/releases/latest': const FetchResult(403, ''),
      });

      final result = await service.checkForUpdate(currentVersion: '2.0.0');
      expect(result.errorMessage, '请求过于频繁，请稍后再试');
    });

    test('wraps unexpected status codes', () async {
      final service = serviceFor({
        '/repos/jiuxina/ying/releases/latest': const FetchResult(500, ''),
      });

      final result = await service.checkForUpdate(currentVersion: '2.0.0');
      expect(result.errorMessage, contains('HTTP 500'));
    });

    test('wraps malformed payloads', () async {
      final service = serviceFor({
        '/repos/jiuxina/ying/releases/latest': const FetchResult(
          200,
          'not json',
        ),
      });

      final result = await service.checkForUpdate(currentVersion: '2.0.0');
      expect(result.errorMessage, '发布信息解析失败，请稍后再试');
    });

    test('wraps network failures', () async {
      final service = UpdateService(
        fetcher: (_) async => throw Exception('socket error'),
      );

      final result = await service.checkForUpdate(currentVersion: '2.0.0');
      expect(result.errorMessage, '网络请求失败，请检查网络后重试');
    });
  });
}
