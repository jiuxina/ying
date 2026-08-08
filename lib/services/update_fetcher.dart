// 更新检测的 HTTP 抓取抽象。
//
// [fetchUrl] 由各平台实现通过条件导出提供：原生平台使用 dart:io，
// Web 平台暂不支持检测更新，会抛出 [UpdateFetchException]。
export 'update_fetcher_stub.dart'
    if (dart.library.io) 'update_fetcher_io.dart'
    if (dart.library.js_interop) 'update_fetcher_web.dart';

class FetchResult {
  const FetchResult(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

/// 抓取失败时抛出，携带可直接展示给用户的中文说明。
class UpdateFetchException implements Exception {
  const UpdateFetchException(this.message);

  final String message;

  @override
  String toString() => message;
}
