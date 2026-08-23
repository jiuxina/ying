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
  });

  group('APK asset selection', () {
    test('prefers device ABI over universal and other ABIs', () {
      final asset = pickApkAsset(
        [
          _asset('app-x86_64-release.apk'),
          _asset('app-arm64-v8a-release.apk'),
          _asset('ying-universal.apk'),
        ],
        preferredAbis: const ['arm64-v8a'],
      );
      expect(asset?['name'], 'app-arm64-v8a-release.apk');
    });

    test('falls back to universal package', () {
      final asset = pickApkAsset([
        _asset('app-arm64-v8a-release.apk'),
        _asset('ying-universal.apk'),
      ]);
      expect(asset?['name'], 'ying-universal.apk');
    });

    test('falls back to first apk when no abi marker exists', () {
      final asset = pickApkAsset([
        _asset('ying-3.4.0.apk'),
        _asset('notes.txt'),
      ]);
      expect(asset?['name'], 'ying-3.4.0.apk');
    });
  });

  group('UpdateService.checkForUpdate', () {
    UpdateService serviceFor(
      Map<String, FetchResult> responses, {
      List<String> abis = const [],
    }) {
      return UpdateService(
        fetcher: (uri) async {
          final result = responses[uri.path];
          if (result == null) {
            throw const UpdateFetchException('未预期的请求');
          }
          return result;
        },
        abiProvider: () async => abis,
      );
    }

    String releaseJson({
      String tag = 'v3.4.0',
      String? name = '完全免费开源',
      String? body = '- 支持镜像下载更新',
      List<Map<String, Object?>>? assets,
    }) {
      return jsonEncode({
        'tag_name': tag,
        'name': name,
        'body': body,
        'html_url': 'https://github.com/jiuxina/ying/releases/tag/$tag',
        'published_at': '2026-08-23T12:00:00Z',
        'assets': assets ??
            [
              {
                'name': 'ying-3.4.0.apk',
                'browser_download_url':
                    'https://github.com/jiuxina/ying/releases/download/v3.4.0/ying-3.4.0.apk',
                'size': 1024,
              },
            ],
      });
    }

    test('reads the ying repo and exposes apk download url', () async {
      final service = serviceFor({
        '/repos/jiuxina/ying/releases/latest': FetchResult(
          200,
          releaseJson(),
        ),
      });

      final result = await service.checkForUpdate(currentVersion: '3.3.0');
      expect(result.hasError, isFalse);
      expect(result.isNewer, isTrue);
      expect(result.release?.version, '3.4.0');
      expect(result.release?.name, '完全免费开源');
      expect(result.release?.notes, contains('镜像下载更新'));
      expect(
        result.release?.downloadUrl,
        'https://github.com/jiuxina/ying/releases/download/v3.4.0/ying-3.4.0.apk',
      );
      expect(result.release?.downloadSize, 1024);
    });

    test('selects the apk matching the device abi', () async {
      final service = serviceFor(
        {
          '/repos/jiuxina/ying/releases/latest': FetchResult(
            200,
            releaseJson(
              assets: [
                _asset('app-x86_64-release.apk'),
                _asset('app-arm64-v8a-release.apk'),
              ],
            ),
          ),
        },
        abis: const ['arm64-v8a'],
      );

      final result = await service.checkForUpdate(currentVersion: '3.3.0');
      expect(
        result.release?.downloadUrl,
        contains('app-arm64-v8a-release.apk'),
      );
    });

    test('reports up-to-date when release is older', () async {
      final service = serviceFor({
        '/repos/jiuxina/ying/releases/latest': FetchResult(
          200,
          releaseJson(tag: 'v3.2.0'),
        ),
      });

      final result = await service.checkForUpdate(currentVersion: '3.3.0');
      expect(result.isNewer, isFalse);
    });

    test('falls back to the highest tag without releases', () async {
      final service = serviceFor({
        '/repos/jiuxina/ying/releases/latest': const FetchResult(404, ''),
        '/repos/jiuxina/ying/tags': FetchResult(
          200,
          jsonEncode([
            {'name': '1.0.0'},
            {'name': 'v3.4.0'},
            {'name': 'nightly'},
          ]),
        ),
      });

      final result = await service.checkForUpdate(currentVersion: '3.3.0');
      expect(result.hasError, isFalse);
      expect(result.release?.version, '3.4.0');
    });

    test('surfaces rate limiting and network failures', () async {
      final limited = serviceFor({
        '/repos/jiuxina/ying/releases/latest': const FetchResult(403, ''),
      });
      expect(
        (await limited.checkForUpdate(currentVersion: '3.3.0')).errorMessage,
        '请求过于频繁，请稍后再试',
      );

      final broken = UpdateService(
        fetcher: (_) async => throw Exception('socket error'),
      );
      expect(
        (await broken.checkForUpdate(currentVersion: '3.3.0')).errorMessage,
        '网络请求失败，请检查网络后重试',
      );
    });
  });
}

Map<String, Object?> _asset(String name) => {
  'name': name,
  'browser_download_url': 'https://github.com/jiuxina/ying/releases/download/v3.4.0/$name',
  'size': 2048,
};
