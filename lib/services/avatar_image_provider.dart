// 预览用的头像图片提供器；原生平台读取本地缓存文件，Web 返回 null。
export 'avatar_image_provider_stub.dart'
    if (dart.library.io) 'avatar_image_provider_io.dart';
