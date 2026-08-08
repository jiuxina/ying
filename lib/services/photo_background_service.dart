// 相册背景的跨平台抽象：原生平台走系统 Photo Picker 并压缩缓存，
// Web 兜底实现直接给出明确错误。
export 'photo_background_service_stub.dart'
    if (dart.library.io) 'photo_background_service_io.dart';

class PhotoBackgroundException implements Exception {
  const PhotoBackgroundException(this.message);

  final String message;

  @override
  String toString() => message;
}
