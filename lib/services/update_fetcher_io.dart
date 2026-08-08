import 'dart:convert';
import 'dart:io';

import 'update_fetcher.dart';

/// 原生平台实现：HttpClient 带连接与读取超时，避免弱网长时间挂起。
Future<FetchResult> fetchUrl(Uri url) async {
  const timeout = Duration(seconds: 8);
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.getUrl(url).timeout(timeout);
    // GitHub API 要求携带 User-Agent。
    request.headers.set(HttpHeaders.userAgentHeader, 'ying-update-check');
    request.headers.set(
      HttpHeaders.acceptHeader,
      'application/vnd.github+json',
    );
    final response = await request.close().timeout(timeout);
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(timeout);
    return FetchResult(response.statusCode, body);
  } finally {
    client.close(force: true);
  }
}
