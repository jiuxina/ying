// 预览用的背景图片提供器；原生平台读取本地缓存文件，Web 返回 null。
export 'background_image_provider_stub.dart'
    if (dart.library.io) 'background_image_provider_io.dart';
