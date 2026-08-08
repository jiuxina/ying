import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'photo_background_service.dart';

const _cacheFileName = 'widget_background.jpg';

/// 用系统 Photo Picker 选图，缩放到 [_maxDimension] 内并压缩缓存，
/// 返回可持久化到 [AppSettings.widgetBackgroundPath] 的绝对路径。
Future<String> pickAndCacheWidgetBackground({
  int maxDimension = 1600,
  int quality = 82,
}) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: maxDimension.toDouble(),
    maxHeight: maxDimension.toDouble(),
    imageQuality: 90,
  );
  if (picked == null) {
    throw const PhotoBackgroundException('已取消选择照片');
  }
  try {
    final dir = await getApplicationDocumentsDirectory();
    final target = File('${dir.path}${Platform.pathSeparator}$_cacheFileName');
    final bytes = await picked.readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) {
      throw const PhotoBackgroundException('无法读取所选图片，请换一张试试');
    }
    if (image.width > maxDimension || image.height > maxDimension) {
      image = img.copyResize(
        image,
        width: image.width >= image.height ? maxDimension : null,
        height: image.height > image.width ? maxDimension : null,
        interpolation: img.Interpolation.cubic,
      );
    }
    final encoded = img.encodeJpg(image, quality: quality);
    await target.writeAsBytes(encoded, flush: true);
    return target.path;
  } on PhotoBackgroundException {
    rethrow;
  } catch (_) {
    throw const PhotoBackgroundException('照片处理失败，请重试');
  }
}
