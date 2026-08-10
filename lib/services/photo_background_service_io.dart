import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'photo_background_service.dart';

const _sourceFileName = 'widget_background_source.png';
const _processedFileName = 'widget_background.jpg';

class _BackgroundProcessRequest {
  const _BackgroundProcessRequest({
    required this.bytes,
    required this.brightness,
    required this.blur,
    required this.maxDimension,
    required this.quality,
  });

  final Uint8List bytes;
  final double brightness;
  final int blur;
  final int maxDimension;
  final int quality;
}

/// 纯图片处理：缩放、亮度与高斯模糊，最后编码为 JPG。
/// 供设置编辑保存与单元测试共用，耗时操作放到后台 isolate。
Future<Uint8List> processWidgetBackgroundBytes(
  Uint8List bytes, {
  double brightness = 1.0,
  double blur = 0.0,
  int maxDimension = 1600,
  int quality = 82,
}) {
  return compute(
    _processBackgroundRequest,
    _BackgroundProcessRequest(
      bytes: bytes,
      brightness: brightness,
      blur: blur.round(),
      maxDimension: maxDimension,
      quality: quality,
    ),
  );
}

Uint8List _processBackgroundRequest(_BackgroundProcessRequest request) {
  final decoded = img.decodeImage(request.bytes);
  if (decoded == null) {
    throw const PhotoBackgroundException('无法读取所选图片，请换一张试试');
  }
  var image = decoded;
  if (image.width > request.maxDimension ||
      image.height > request.maxDimension) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? request.maxDimension : null,
      height: image.height > image.width ? request.maxDimension : null,
      interpolation: img.Interpolation.cubic,
    );
  }
  image = img.adjustColor(image, brightness: request.brightness);
  final radius = request.blur
      .clamp(0, (image.width < image.height ? image.width : image.height) ~/ 2);
  if (radius > 0) {
    image = img.gaussianBlur(image, radius: radius);
  }
  return img.encodeJpg(image, quality: request.quality);
}

/// 用系统 Photo Picker 选图，自由矩形裁切后按亮度/模糊处理并缓存。
Future<String> pickAndCacheWidgetBackground({
  int maxDimension = 1600,
  int quality = 82,
  double brightness = 1.0,
  double blur = 0.0,
}) async {
  final sourcePath = await _pickAndSaveSource(maxDimension: maxDimension);
  return _cropAndProcess(
    sourcePath,
    brightness: brightness,
    blur: blur,
    maxDimension: maxDimension,
    quality: quality,
  );
}

/// 使用已保存的源图重新裁切并处理；旧版本没有源图时抛错，
/// 由设置页回退到重新选图。
Future<String> recropWidgetBackground({
  int maxDimension = 1600,
  int quality = 82,
  double brightness = 1.0,
  double blur = 0.0,
}) async {
  final sourcePath = await existingWidgetBackgroundSource();
  if (sourcePath == null) {
    throw const PhotoBackgroundException('旧照片缺少源图，请重新选择');
  }
  return _cropAndProcess(
    sourcePath,
    brightness: brightness,
    blur: blur,
    maxDimension: maxDimension,
    quality: quality,
    replaceSource: true,
  );
}

/// 不重新裁切，仅按当前亮度/模糊重新处理源图并覆盖成品缓存。
Future<String> reprocessWidgetBackground({
  int maxDimension = 1600,
  int quality = 82,
  required double brightness,
  required double blur,
}) async {
  final sourcePath = await existingWidgetBackgroundSource();
  if (sourcePath == null) {
    throw const PhotoBackgroundException('旧照片缺少源图，请重新选择');
  }
  final bytes = await File(sourcePath).readAsBytes();
  final processed = await processWidgetBackgroundBytes(
    bytes,
    brightness: brightness,
    blur: blur,
    maxDimension: maxDimension,
    quality: quality,
  );
  final target = await _processedFile();
  await target.writeAsBytes(processed, flush: true);
  return target.path;
}

/// 返回已保存的源图路径；不存在时为 null。
Future<String?> existingWidgetBackgroundSource() async {
  try {
    final source = await _sourceFile();
    return await source.exists() ? source.path : null;
  } catch (_) {
    return null;
  }
}

Future<String> _pickAndSaveSource({required int maxDimension}) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: maxDimension.toDouble(),
    maxHeight: maxDimension.toDouble(),
  );
  if (picked == null) {
    throw const PhotoBackgroundException('已取消选择照片');
  }
  try {
    final bytes = await picked.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const PhotoBackgroundException('无法读取所选图片，请换一张试试');
    }
    var image = decoded;
    if (image.width > maxDimension || image.height > maxDimension) {
      image = img.copyResize(
        image,
        width: image.width >= image.height ? maxDimension : null,
        height: image.height > image.width ? maxDimension : null,
        interpolation: img.Interpolation.cubic,
      );
    }
    final source = await _sourceFile();
    await source.writeAsBytes(img.encodePng(image), flush: true);
    return source.path;
  } on PhotoBackgroundException {
    rethrow;
  } catch (_) {
    throw const PhotoBackgroundException('照片处理失败，请重试');
  }
}

Future<String> _cropAndProcess(
  String sourcePath, {
  required double brightness,
  required double blur,
  required int maxDimension,
  required int quality,
  bool replaceSource = false,
}) async {
  try {
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      maxWidth: maxDimension,
      maxHeight: maxDimension,
      compressFormat: ImageCompressFormat.png,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁切背景',
          cropStyle: CropStyle.rectangle,
          lockAspectRatio: false,
          hideBottomControls: false,
          initAspectRatio: CropAspectRatioPreset.original,
          aspectRatioPresets: const [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );
    if (cropped == null) {
      throw const PhotoBackgroundException('已取消裁切照片');
    }
    final bytes = await cropped.readAsBytes();
    if (replaceSource) {
      final source = File(sourcePath);
      if (await source.exists()) {
        await source.writeAsBytes(bytes, flush: true);
      }
    }
    final processed = await processWidgetBackgroundBytes(
      bytes,
      brightness: brightness,
      blur: blur,
      maxDimension: maxDimension,
      quality: quality,
    );
    final target = await _processedFile();
    await target.writeAsBytes(processed, flush: true);
    return target.path;
  } on PhotoBackgroundException {
    rethrow;
  } catch (_) {
    throw const PhotoBackgroundException('照片处理失败，请重试');
  }
}

Future<File> _sourceFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}${Platform.pathSeparator}$_sourceFileName');
}

Future<File> _processedFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}${Platform.pathSeparator}$_processedFileName');
}

/// 删除缓存的源图与成品；文件不存在或删除失败时静默返回。
Future<void> deleteCachedWidgetBackground() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final files = [
      File('${dir.path}${Platform.pathSeparator}$_sourceFileName'),
      File('${dir.path}${Platform.pathSeparator}$_processedFileName'),
    ];
    for (final file in files) {
      if (await file.exists()) {
        await file.delete();
      }
    }
  } catch (_) {
    // 删除失败不阻塞设置流程，下次重新选择会覆盖同名缓存文件。
  }
}
