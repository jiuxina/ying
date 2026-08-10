import 'avatar_service.dart';

Future<String> pickAndCacheAvatar() async {
  throw const AvatarException('当前平台暂不支持设置头像');
}

Future<void> deleteCachedAvatar() async {}
