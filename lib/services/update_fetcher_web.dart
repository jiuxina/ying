import 'update_fetcher.dart';

/// Web 版暂不支持检测更新，给出明确提示而非静默失败。
Future<FetchResult> fetchUrl(Uri url) {
  throw const UpdateFetchException('网页版暂不支持检测更新');
}
