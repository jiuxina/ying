import 'update_fetcher.dart';

/// 兜底实现：既没有 dart:io 也没有 js_interop 的平台直接报错。
Future<FetchResult> fetchUrl(Uri url) {
  throw const UpdateFetchException('当前平台暂不支持检测更新');
}
