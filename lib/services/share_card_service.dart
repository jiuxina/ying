import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 分享卡片服务
class ShareCardService {
  /// 生成分享图片并分享
  static Future<void> shareEventCard(
    BuildContext context,
    GlobalKey boundaryKey, {
    String? subject,
    String? text,
  }) async {
    try {
      final imageBytes = await _capturePng(boundaryKey);
      if (imageBytes == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/event_card.png').create();
      await file.writeAsBytes(imageBytes);

      if (context.mounted) {
        // 获取屏幕位置用于iPad分享
        final box = context.findRenderObject() as RenderBox?;
        
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: subject,
          text: text,
          sharePositionOrigin: box != null 
              ? box.localToGlobal(Offset.zero) & box.size 
              : null,
        );
      }
    } catch (e) {
      debugPrint('分享失败: $e');
    }
  }

  /// 截图整个Widget
  static Future<Uint8List?> _capturePng(GlobalKey boundaryKey) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // 提高像素密度以获得更清晰的图片
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('截图失败: $e');
      return null;
    }
  }
}
