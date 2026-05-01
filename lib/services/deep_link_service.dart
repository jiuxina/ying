import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import '../models/countdown_event.dart';
import '../models/shared_event.dart';
import '../services/qr_code_service.dart';
import 'package:uuid/uuid.dart';

/// Deep Link类型
enum DeepLinkType {
  event,           // 单个事件导入
  sharedEvent,     // 共享事件加入
  familyGroup,     // 家庭组加入
  qrData,          // QR码数据
}

/// Deep Link解析结果
class DeepLinkResult {
  final DeepLinkType type;
  final dynamic data;

  const DeepLinkResult({
    required this.type,
    required this.data,
  });
}

/// Deep Link服务
/// 处理应用内Deep Link和Universal Links
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  static const _uuid = Uuid();

  /// Deep Link Scheme
  static const String appScheme = 'ying';

  /// Deep Link路径
  static const String eventPath = 'event';
  static const String sharedEventPath = 'shared';
  static const String familyGroupPath = 'family';
  static const String qrPath = 'qr';

  /// 初始化Deep Link监听
  void init({
    required Function(DeepLinkResult) onLinkReceived,
  }) {
    // 监听 incoming links
    _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('DeepLink received: $uri');
        final result = parseUri(uri);
        if (result != null) {
          onLinkReceived(result);
        }
      },
      onError: (error) {
        debugPrint('DeepLink error: $error');
      },
    );

    // 处理冷启动时的初始链接
    _handleInitialLink(onLinkReceived);
  }

  Future<void> _handleInitialLink(
    Function(DeepLinkResult) onLinkReceived,
  ) async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('DeepLink initial: $initialUri');
        final result = parseUri(initialUri);
        if (result != null) {
          onLinkReceived(result);
        }
      }
    } catch (e) {
      debugPrint('DeepLink initial error: $e');
    }
  }

  /// 解析URI
  DeepLinkResult? parseUri(Uri uri) {
    try {
      // 检查scheme
      if (uri.scheme != appScheme) {
        // 也支持 https scheme (Universal Links)
        if (uri.scheme != 'https' && uri.scheme != 'http') {
          return null;
        }
      }

      // 根据路径处理
      final pathSegments = uri.pathSegments;
      if (pathSegments.isEmpty) {
        return _parseLegacyEventLink(uri);
      }

      final firstPath = pathSegments[0];

      switch (firstPath) {
        case eventPath:
          return _parseEventUri(uri);

        case sharedEventPath:
          return _parseSharedEventUri(uri);

        case familyGroupPath:
          return _parseFamilyGroupUri(uri);

        case qrPath:
          return _parseQrDataUri(uri);

        default:
          // 尝试解析为旧版事件链接
          return _parseLegacyEventLink(uri);
      }
    } catch (e) {
      debugPrint('parseUri error: $e');
      return null;
    }
  }

  /// 解析事件URI
  DeepLinkResult? _parseEventUri(Uri uri) {
    final data = uri.queryParameters['data'];
    if (data == null) return null;

    try {
      final decoded = utf8.decode(base64Url.decode(data));
      final json = jsonDecode(decoded) as Map<String, dynamic>;

      final now = DateTime.now();
      final event = CountdownEvent(
        id: _uuid.v4(),
        title: json['t'] as String,
        targetDate: DateTime.fromMillisecondsSinceEpoch(json['d'] as int),
        isLunar: (json['l'] as int?) == 1,
        isCountUp: (json['u'] as int?) == 1,
        isRepeating: (json['r'] as int?) == 1,
        categoryId: json['c'] as String? ?? 'custom',
        note: json['n'] as String?,
        lunarDateStr: json['ls'] as String?,
        createdAt: now,
        updatedAt: now,
      );

      return DeepLinkResult(
        type: DeepLinkType.event,
        data: event,
      );
    } catch (e) {
      debugPrint('_parseEventUri error: $e');
      return null;
    }
  }

  /// 解析共享事件URI
  DeepLinkResult? _parseSharedEventUri(Uri uri) {
    final shareId = uri.queryParameters['shareId'];
    final eventId = uri.queryParameters['eventId'];
    final ownerDeviceId = uri.queryParameters['owner'];
    final ownerName = uri.queryParameters['name'];
    final version = uri.queryParameters['version'];
    final permission = uri.queryParameters['permission'];

    if (shareId == null) return null;

    // 如果有事件数据，解析事件
    final eventData = uri.queryParameters['data'];
    CountdownEvent? event;

    if (eventData != null) {
      try {
        final decoded = utf8.decode(base64Url.decode(eventData));
        final json = jsonDecode(decoded) as Map<String, dynamic>;

        final now = DateTime.now();
        event = CountdownEvent(
          id: eventId ?? _uuid.v4(),
          title: json['t'] as String,
          targetDate: DateTime.fromMillisecondsSinceEpoch(json['d'] as int),
          isLunar: (json['l'] as int?) == 1,
          isCountUp: (json['u'] as int?) == 1,
          isRepeating: (json['r'] as int?) == 1,
          categoryId: json['c'] as String? ?? 'custom',
          note: json['n'] as String?,
          lunarDateStr: json['ls'] as String?,
          createdAt: now,
          updatedAt: now,
        );
      } catch (e) {
        debugPrint('_parseSharedEventUri event parse error: $e');
      }
    }

    final importData = SharedEventImportData(
      event: event!,
      shareId: shareId,
      ownerDeviceId: ownerDeviceId ?? '',
      ownerDisplayName: ownerName ?? '用户',
      version: int.tryParse(version ?? '1') ?? 1,
      permission: SharePermission.values[int.tryParse(permission ?? '0') ?? 0],
      inviterDeviceId: ownerDeviceId ?? '',
      inviterDisplayName: ownerName ?? '用户',
    );

    return DeepLinkResult(
      type: DeepLinkType.sharedEvent,
      data: importData,
    );
  }

  /// 解析家庭组URI
  DeepLinkResult? _parseFamilyGroupUri(Uri uri) {
    final groupId = uri.queryParameters['groupId'];
    final groupName = uri.queryParameters['name'];
    final ownerDeviceId = uri.queryParameters['owner'];
    final ownerName = uri.queryParameters['ownerName'];
    final eventCount = uri.queryParameters['count'];

    if (groupId == null) return null;

    final inviteData = FamilyGroupInviteData(
      groupId: groupId,
      groupName: groupName ?? '家庭共享',
      ownerDeviceId: ownerDeviceId ?? '',
      ownerDisplayName: ownerName ?? '用户',
      eventCount: int.tryParse(eventCount ?? '0') ?? 0,
      inviterDeviceId: ownerDeviceId ?? '',
      inviterDisplayName: ownerName ?? '用户',
    );

    return DeepLinkResult(
      type: DeepLinkType.familyGroup,
      data: inviteData,
    );
  }

  /// 解析QR数据URI
  DeepLinkResult? _parseQrDataUri(Uri uri) {
    final data = uri.queryParameters['data'];
    if (data == null) return null;

    try {
      final qrData = QRCodeService.parseQRCode(data);
      if (qrData == null) return null;

      switch (qrData.type) {
        case QRDataType.singleEvent:
          final event = QRCodeService.parseSingleEvent(qrData);
          if (event != null) {
            return DeepLinkResult(
              type: DeepLinkType.event,
              data: event,
            );
          }
          break;

        case QRDataType.multipleEvents:
          final events = QRCodeService.parseMultipleEvents(qrData);
          if (events.isNotEmpty) {
            return DeepLinkResult(
              type: DeepLinkType.event,
              data: events,
            );
          }
          break;

        case QRDataType.sharedEvent:
          final importData = QRCodeService.parseSharedEvent(qrData);
          if (importData != null) {
            return DeepLinkResult(
              type: DeepLinkType.sharedEvent,
              data: importData,
            );
          }
          break;

        case QRDataType.familyGroup:
          final inviteData = QRCodeService.parseFamilyGroupInvite(qrData);
          if (inviteData != null) {
            return DeepLinkResult(
              type: DeepLinkType.familyGroup,
              data: inviteData,
            );
          }
          break;
      }
    } catch (e) {
      debugPrint('_parseQrDataUri error: $e');
    }

    return null;
  }

  /// 解析旧版事件链接（兼容性）
  DeepLinkResult? _parseLegacyEventLink(Uri uri) {
    // 旧版格式: ying://event?data=xxx
    if (uri.host == eventPath || uri.path == '/$eventPath') {
      return _parseEventUri(uri);
    }

    // 尝试从query参数解析
    final data = uri.queryParameters['data'];
    if (data != null) {
      // 可能是QR码数据
      try {
        final qrData = QRCodeService.parseQRCode(data);
        if (qrData != null) {
          return DeepLinkResult(
            type: DeepLinkType.qrData,
            data: qrData,
          );
        }
      } catch (e) {
        // 忽略，尝试其他解析方式
      }
    }

    return null;
  }

  // ==================== 生成Deep Link ====================

  /// 生成事件分享链接
  static String generateEventLink(CountdownEvent event) {
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

    return '$appScheme://$eventPath?data=$encoded';
  }

  /// 生成共享事件链接
  static String generateSharedEventLink({
    required CountdownEvent event,
    required SharedEventMetadata metadata,
    required String deviceId,
    required String displayName,
  }) {
    final eventData = {
      't': event.title,
      'd': event.targetDate.millisecondsSinceEpoch,
      'l': event.isLunar ? 1 : 0,
      'u': event.isCountUp ? 1 : 0,
      'r': event.isRepeating ? 1 : 0,
      'c': event.categoryId,
      if (event.note != null && event.note!.isNotEmpty) 'n': event.note,
      if (event.lunarDateStr != null) 'ls': event.lunarDateStr,
    };

    final encoded = base64Url.encode(utf8.encode(jsonEncode(eventData)));

    return '$appScheme://$sharedEventPath'
        '?shareId=${metadata.shareId}'
        '&eventId=${event.id}'
        '&owner=${metadata.ownerDeviceId}'
        '&name=${Uri.encodeComponent(metadata.ownerDisplayName)}'
        '&version=${metadata.version}'
        '&permission=${SharePermission.view.index}'
        '&data=$encoded';
  }

  /// 生成家庭组邀请链接
  static String generateFamilyGroupLink({
    required FamilyShareGroup group,
    required String deviceId,
    required String displayName,
  }) {
    return '$appScheme://$familyGroupPath'
        '?groupId=${group.id}'
        '&name=${Uri.encodeComponent(group.name)}'
        '&owner=${group.ownerDeviceId}'
        '&ownerName=${Uri.encodeComponent(group.ownerDisplayName)}'
        '&count=${group.sharedEventIds.length}';
  }

  /// 生成QR数据链接
  static String generateQrDataLink(String qrContent) {
    return '$appScheme://$qrPath?data=${Uri.encodeComponent(qrContent)}';
  }
}
