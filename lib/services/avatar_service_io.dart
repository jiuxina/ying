import 'dart:io';

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'avatar_service.dart';

const _cacheFileName = 'app_avatar.jpg';

/// 用系统 Photo Picker 选图，圆形裁切后缓存为正方形头像，
/// 返回可持久化到 [AppSettings.avatarPath] 的绝对路径。
Future<String> pickAndCacheAvatar({
  int maxDimension = 512,
  int quality = 90,
}) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: maxDimension.toDouble(),
    maxHeight: maxDimension.toDouble(),
  );
  if (picked == null) {
    throw const AvatarException('已取消选择头像');
  }
  try {
    final dir = await getApplicationDocumentsDirectory();
    final temp = File(
      '${dir.path}${Platform.pathSeparator}'
      'avatar_temp_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    final bytes = await picked.readAsBytes();
    await temp.writeAsBytes(bytes, flush: true);
    final cropped = await ImageCropper().cropImage(
      sourcePath: temp.path,
      maxWidth: maxDimension,
      maxHeight: maxDimension,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: quality,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁切头像',
          cropStyle: CropStyle.circle,
          lockAspectRatio: true,
          hideBottomControls: true,
          initAspectRatio: CropAspectRatioPreset.square,
          aspectRatioPresets: const [
            CropAspectRatioPreset.square,
          ],
        ),
      ],
    );
    if (cropped == null) {
      throw const AvatarException('已取消选择头像');
    }
    final target = File(
      '${dir.path}${Platform.pathSeparator}$_cacheFileName',
    );
    final croppedBytes = await cropped.readAsBytes();
    await target.writeAsBytes(croppedBytes, flush: true);
    await temp.delete();
    return target.path;
  } on AvatarException {
    rethrow;
  } catch (_) {
    throw const AvatarException('头像处理失败，请重试');
  }
}

/// 删除缓存的头像文件；文件不存在或删除失败时静默返回。
Future<void> deleteCachedAvatar() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final target = File('${dir.path}${Platform.pathSeparator}$_cacheFileName');
    if (await target.exists()) {
      await target.delete();
    }
  } catch (_) {
    // 删除失败不阻塞设置流程，下次重新选择会覆盖同名缓存文件。
  }
}
