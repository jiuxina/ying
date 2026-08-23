import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ying/services/update_service.dart';
import 'package:ying/services/update_sources.dart';

void main() {
  final release = ReleaseInfo(
    version: '3.4.0',
    url: 'https://github.com/jiuxina/ying/releases/tag/v3.4.0',
    downloadUrl:
        'https://github.com/jiuxina/ying/releases/download/v3.4.0/ying-3.4.0.apk',
  );

  test('builds github direct plus three mirrors', () {
    final sources = updateSourcesFor(release);
    expect(sources, hasLength(4));
    expect(sources.first.id, 'github');
    expect(sources.first.resolve(release).toString(), release.downloadUrl);
    expect(
      sources[1].resolve(release).toString(),
      'https://ghfast.top/${release.downloadUrl}',
    );
    expect(
      sources[2].resolve(release).toString(),
      'https://gh-proxy.com/${release.downloadUrl}',
    );
    expect(
      sources[3].resolve(release).toString(),
      'https://ghproxy.net/${release.downloadUrl}',
    );
  });

  test('returns empty sources when no apk url exists', () {
    expect(
      updateSourcesFor(const ReleaseInfo(version: '1.0.0', url: '')),
      isEmpty,
    );
  });

  test('measures speeds concurrently and keeps fastest', () async {
    final client = MockClient((request) async {
      if (request.url.host == 'ghfast.top') {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      return http.Response.bytes(
        List<int>.filled(1024, 1),
        206,
        headers: const {'content-range': 'bytes 0-1023/*'},
      );
    });

    final results = await measureSourceSpeeds(release, client: client);
    expect(results, hasLength(4));
    expect(results.every((result) => result.success), isTrue);
    expect(bestSource(results)?.id, isNot('ghfast'));
  });

  test('falls back to github direct when every source fails', () {
    final results = [
      const SourceSpeedResult(
        source: UpdateSource(
          id: 'github',
          label: 'GitHub 直连',
          resolve: _dummyResolve,
        ),
        duration: Duration(seconds: 2),
        success: false,
        error: '超时',
      ),
      const SourceSpeedResult(
        source: UpdateSource(
          id: 'ghfast',
          label: 'ghfast.top 镜像',
          resolve: _dummyResolve,
        ),
        duration: Duration(seconds: 1),
        success: false,
        error: '失败',
      ),
    ];
    expect(bestSource(results)?.id, 'github');
  });
}

Uri _dummyResolve(ReleaseInfo release) => Uri.parse(release.url);
