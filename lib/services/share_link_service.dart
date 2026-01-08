import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/countdown_event.dart';

/// 分享链接服务
/// 生成和解析事件分享链接
class ShareLinkService {
  /// 应用的 Deep Link Scheme
  static const String appScheme = 'ying';
  static const String webHost = 'ying.app'; // 备用Web域名
  
  /// 生成分享链接
  /// 返回一个可以被其他用户打开的链接
  static String generateShareLink(CountdownEvent event) {
    final data = {
      't': event.title,
      'd': event.targetDate.millisecondsSinceEpoch,
      'l': event.isLunar ? 1 : 0,
      'u': event.isCountUp ? 1 : 0,
      'r': event.isRepeating ? 1 : 0,
      'c': event.categoryId,
      if (event.note != null && event.note!.isNotEmpty) 'n': event.note,
      if (event.lunarDateStr != null) 'ls': event.lunarDateStr,
    };
    
    final jsonStr = jsonEncode(data);
    final encoded = base64Url.encode(utf8.encode(jsonStr));
    
    // 返回 Deep Link 格式
    return '$appScheme://event?data=$encoded';
  }
  
  /// 生成用于文本分享的链接
  /// 包含一个备用的 Web URL
  static String generateShareText(CountdownEvent event) {
    final link = generateShareLink(event);
    final days = event.daysRemaining.abs();
    final status = event.isCountUp 
        ? '已经 $days 天' 
        : (event.daysRemaining >= 0 ? '还有 $days 天' : '已过 $days 天');
    
    return '''
📅 ${event.title}
⏰ $status
🔗 打开萤App导入: $link
''';
  }
  
  /// 解析分享链接
  /// 返回解析后的事件数据，如果解析失败返回 null
  static CountdownEvent? parseShareLink(String link) {
    try {
      final uri = Uri.parse(link);
      
      // 验证 scheme
      if (uri.scheme != appScheme) {
        debugPrint('ShareLinkService: Invalid scheme: ${uri.scheme}');
        return null;
      }
      
      // 验证 path
      if (uri.host != 'event' && uri.path != '/event') {
        debugPrint('ShareLinkService: Invalid path: ${uri.path}');
        return null;
      }
      
      // 获取 data 参数
      final encodedData = uri.queryParameters['data'];
      if (encodedData == null || encodedData.isEmpty) {
        debugPrint('ShareLinkService: No data parameter');
        return null;
      }
      
      // 解码数据
      final jsonStr = utf8.decode(base64Url.decode(encodedData));
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      // 创建事件
      final now = DateTime.now();
      return CountdownEvent(
        id: '', // 导入时会生成新的 ID
        title: data['t'] as String,
        targetDate: DateTime.fromMillisecondsSinceEpoch(data['d'] as int),
        isLunar: (data['l'] as int?) == 1,
        isCountUp: (data['u'] as int?) == 1,
        isRepeating: (data['r'] as int?) == 1,
        categoryId: data['c'] as String? ?? 'custom',
        note: data['n'] as String?,
        lunarDateStr: data['ls'] as String?,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      debugPrint('ShareLinkService: Error parsing link: $e');
      return null;
    }
  }
  
  /// 检查链接是否是有效的分享链接
  static bool isValidShareLink(String link) {
    try {
      final uri = Uri.parse(link);
      return uri.scheme == appScheme && 
             (uri.host == 'event' || uri.path == '/event') &&
             uri.queryParameters.containsKey('data');
    } catch (_) {
      return false;
    }
  }
  
  /// 复制链接到剪贴板并提供文本
  static String getShareableText(CountdownEvent event) {
    return generateShareText(event);
  }
}
