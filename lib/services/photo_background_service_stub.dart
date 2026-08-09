import 'photo_background_service.dart';

/// 非原生平台没有可写的本地缓存目录，明确提示暂不支持。
Future<String> pickAndCacheWidgetBackground({
  int maxDimension = 1600,
  int quality = 82,
}) {
  throw const PhotoBackgroundException('当前平台暂不支持相册背景');
}

/// 非原生平台没有可删除的缓存文件。
Future<void> deleteCachedWidgetBackground() async {}
