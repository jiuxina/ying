// 头像的跨平台抽象：原生平台走系统 Photo Picker 与圆形裁切并缓存，
// Web 兜底实现直接给出明确错误。
export 'avatar_service_stub.dart'
    if (dart.library.io) 'avatar_service_io.dart';

class AvatarException implements Exception {
  const AvatarException(this.message);

  final String message;

  @override
  String toString() => message;
}
