import 'dart:async';

import 'package:http/http.dart' as http;

import 'update_service.dart';

class UpdateSource {
  const UpdateSource({
    required this.id,
    required this.label,
    required this.resolve,
  });

  final String id;
  final String label;
  final Uri Function(ReleaseInfo release) resolve;
}

class SourceSpeedResult {
  const SourceSpeedResult({
    required this.source,
    required this.duration,
    required this.success,
    this.error,
  });

  final UpdateSource source;
  final Duration duration;
  final bool success;
  final String? error;
}

/// GitHub 直连 + 3 个常用加速镜像。
List<UpdateSource> updateSourcesFor(ReleaseInfo release) {
  final direct = release.downloadUrl;
  if (direct == null || direct.isEmpty) return const [];
  return [
    UpdateSource(
      id: 'github',
      label: 'GitHub 直连',
      resolve: (_) => Uri.parse(direct),
    ),
    UpdateSource(
      id: 'ghfast',
      label: 'ghfast.top 镜像',
      resolve: (_) => Uri.parse('https://ghfast.top/$direct'),
    ),
    UpdateSource(
      id: 'gh-proxy',
      label: 'gh-proxy.com 镜像',
      resolve: (_) => Uri.parse('https://gh-proxy.com/$direct'),
    ),
    UpdateSource(
      id: 'ghproxy',
      label: 'ghproxy.net 镜像',
      resolve: (_) => Uri.parse('https://ghproxy.net/$direct'),
    ),
  ];
}

Future<List<SourceSpeedResult>> measureSourceSpeeds(
  ReleaseInfo release, {
  http.Client? client,
  Duration timeout = const Duration(seconds: 6),
  int probeBytes = 256 * 1024,
}) async {
  final sources = updateSourcesFor(release);
  final ownClient = client == null;
  final active = client ?? http.Client();
  try {
    return await Future.wait(
      sources.map(
        (source) => measureSourceSpeed(
          source,
          release,
          client: active,
          timeout: timeout,
          probeBytes: probeBytes,
        ),
      ),
    );
  } finally {
    if (ownClient) active.close();
  }
}

Future<SourceSpeedResult> measureSourceSpeed(
  UpdateSource source,
  ReleaseInfo release, {
  required http.Client client,
  Duration timeout = const Duration(seconds: 6),
  int probeBytes = 256 * 1024,
}) async {
  final stopwatch = Stopwatch()..start();
  final request = http.Request('GET', source.resolve(release))
    ..headers['Range'] = 'bytes=0-${probeBytes - 1}'
    ..headers['User-Agent'] = 'ying-update-speed';
  final completer = Completer<SourceSpeedResult>();
  StreamSubscription<List<int>>? subscription;
  var received = 0;
  try {
    final response = await client.send(request).timeout(timeout);
    final status = response.statusCode;
    if (status != 200 && status != 206) {
      return SourceSpeedResult(
        source: source,
        duration: stopwatch.elapsed,
        success: false,
        error: 'HTTP $status',
      );
    }
    subscription = response.stream.listen(
      (chunk) {
        received += chunk.length;
        if (received >= probeBytes) {
          subscription?.cancel();
          if (!completer.isCompleted) {
            completer.complete(
              SourceSpeedResult(
                source: source,
                duration: stopwatch.elapsed,
                success: true,
              ),
            );
          }
        }
      },
      onError: (Object error) {
        if (!completer.isCompleted) {
          completer.complete(
            SourceSpeedResult(
              source: source,
              duration: stopwatch.elapsed,
              success: false,
              error: '连接失败',
            ),
          );
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(
            SourceSpeedResult(
              source: source,
              duration: stopwatch.elapsed,
              success: received > 0,
              error: received > 0 ? null : '无数据',
            ),
          );
        }
      },
    );
    return await completer.future.timeout(timeout, onTimeout: () {
      subscription?.cancel();
      return SourceSpeedResult(
        source: source,
        duration: stopwatch.elapsed,
        success: false,
        error: '测速超时',
      );
    });
  } catch (_) {
    subscription?.cancel();
    return SourceSpeedResult(
      source: source,
      duration: stopwatch.elapsed,
      success: false,
      error: '连接失败',
    );
  }
}

/// 从测速结果中选出最快的可用源；全部失败时回退 GitHub 直连。
UpdateSource? bestSource(List<SourceSpeedResult> results) {
  SourceSpeedResult? best;
  for (final result in results) {
    if (!result.success) continue;
    if (best == null || result.duration < best.duration) best = result;
  }
  if (best != null) return best.source;
  for (final result in results) {
    if (result.source.id == 'github') return result.source;
  }
  return results.isEmpty ? null : results.first.source;
}
