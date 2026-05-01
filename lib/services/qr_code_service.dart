import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/countdown_event.dart';
import '../models/shared_event.dart';
import 'package:uuid/uuid.dart';

/// QR码数据类型
enum QRDataType {
  singleEvent,     // 单个事件
  multipleEvents,  // 多个事件
  sharedEvent,     // 共享事件（带协作信息）
  familyGroup,     // 家庭共享组邀请
}

/// QR码数据封装
class QRCodeData {
  final QRDataType type;
  final int version;
  final Map<String, dynamic> payload;

  const QRCodeData({
    required this.type,
    this.version = 1,
    required this.payload,
  });

  /// 编码为字符串（用于QR码内容）
  String encode() {
    final data = {
      't': type.index,
      'v': version,
      'p': payload,
    };
    return jsonEncode(data);
  }

  /// 从字符串解码
  static QRCodeData? decode(String content) {
    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      return QRCodeData(
        type: QRDataType.values[data['t'] as int],
        version: data['v'] as int? ?? 1,
        payload: data['p'] as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('QRCodeData decode error: $e');
      return null;
    }
  }
}

/// QR码服务
/// 生成和解析事件分享QR码
class QRCodeService {
  static const _uuid = Uuid();

  /// 生成单个事件的QR码数据
  static QRCodeData generateSingleEventQR(CountdownEvent event) {
    return QRCodeData(
      type: QRDataType.singleEvent,
      payload: {
        'id': event.id,
        't': event.title,
        'd': event.targetDate.millisecondsSinceEpoch,
        'l': event.isLunar ? 1 : 0,
        'u': event.isCountUp ? 1 : 0,
        'r': event.isRepeating ? 1 : 0,
        'c': event.categoryId,
        if (event.note != null && event.note!.isNotEmpty) 'n': event.note,
        if (event.lunarDateStr != null) 'ls': event.lunarDateStr,
      },
    );
  }

  /// 生成多个事件的QR码数据
  static QRCodeData generateMultipleEventsQR(List<CountdownEvent> events) {
    return QRCodeData(
      type: QRDataType.multipleEvents,
      payload: {
        'events': events.map((e) => {
          'id': e.id,
          't': e.title,
          'd': e.targetDate.millisecondsSinceEpoch,
          'l': e.isLunar ? 1 : 0,
          'u': e.isCountUp ? 1 : 0,
          'r': e.isRepeating ? 1 : 0,
          'c': e.categoryId,
          if (e.note != null && e.note!.isNotEmpty) 'n': e.note,
          if (e.lunarDateStr != null) 'ls': e.lunarDateStr,
        }).toList(),
      },
    );
  }

  /// 生成共享事件的QR码数据（带协作信息）
  static QRCodeData generateSharedEventQR({
    required CountdownEvent event,
    required SharedEventMetadata metadata,
    required String deviceId,
    required String displayName,
  }) {
    return QRCodeData(
      type: QRDataType.sharedEvent,
      payload: {
        'event': {
          'id': event.id,
          't': event.title,
          'd': event.targetDate.millisecondsSinceEpoch,
          'l': event.isLunar ? 1 : 0,
          'u': event.isCountUp ? 1 : 0,
          'r': event.isRepeating ? 1 : 0,
          'c': event.categoryId,
          if (event.note != null && event.note!.isNotEmpty) 'n': event.note,
          if (event.lunarDateStr != null) 'ls': event.lunarDateStr,
        },
        'share': {
          'shareId': metadata.shareId,
          'ownerDeviceId': metadata.ownerDeviceId,
          'ownerDisplayName': metadata.ownerDisplayName,
          'version': metadata.version,
          'permission': SharePermission.view.index, // 扫码者默认只有查看权限
        },
        'inviter': {
          'deviceId': deviceId,
          'displayName': displayName,
        },
      },
    );
  }

  /// 生成家庭共享组邀请QR码
  static QRCodeData generateFamilyGroupInviteQR({
    required FamilyShareGroup group,
    required String deviceId,
    required String displayName,
  }) {
    return QRCodeData(
      type: QRDataType.familyGroup,
      payload: {
        'groupId': group.id,
        'groupName': group.name,
        'ownerDeviceId': group.ownerDeviceId,
        'ownerDisplayName': group.ownerDisplayName,
        'eventCount': group.sharedEventIds.length,
        'inviter': {
          'deviceId': deviceId,
          'displayName': displayName,
        },
      },
    );
  }

  /// 解析QR码数据
  static QRCodeData? parseQRCode(String content) {
    return QRCodeData.decode(content);
  }

  /// 从QR码数据解析单个事件
  static CountdownEvent? parseSingleEvent(QRCodeData qrData) {
    if (qrData.type != QRDataType.singleEvent) return null;

    try {
      final p = qrData.payload;
      final now = DateTime.now();
      return CountdownEvent(
        id: _uuid.v4(), // 生成新ID
        title: p['t'] as String,
        targetDate: DateTime.fromMillisecondsSinceEpoch(p['d'] as int),
        isLunar: (p['l'] as int?) == 1,
        isCountUp: (p['u'] as int?) == 1,
        isRepeating: (p['r'] as int?) == 1,
        categoryId: p['c'] as String? ?? 'custom',
        note: p['n'] as String?,
        lunarDateStr: p['ls'] as String?,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      debugPrint('parseSingleEvent error: $e');
      return null;
    }
  }

  /// 从QR码数据解析多个事件
  static List<CountdownEvent> parseMultipleEvents(QRCodeData qrData) {
    if (qrData.type != QRDataType.multipleEvents) return [];

    try {
      final events = qrData.payload['events'] as List<dynamic>;
      final now = DateTime.now();
      return events.map((e) {
        final p = e as Map<String, dynamic>;
        return CountdownEvent(
          id: _uuid.v4(),
          title: p['t'] as String,
          targetDate: DateTime.fromMillisecondsSinceEpoch(p['d'] as int),
          isLunar: (p['l'] as int?) == 1,
          isCountUp: (p['u'] as int?) == 1,
          isRepeating: (p['r'] as int?) == 1,
          categoryId: p['c'] as String? ?? 'custom',
          note: p['n'] as String?,
          lunarDateStr: p['ls'] as String?,
          createdAt: now,
          updatedAt: now,
        );
      }).toList();
    } catch (e) {
      debugPrint('parseMultipleEvents error: $e');
      return [];
    }
  }

  /// 解析共享事件数据
  static SharedEventImportData? parseSharedEvent(QRCodeData qrData) {
    if (qrData.type != QRDataType.sharedEvent) return null;

    try {
      final eventP = qrData.payload['event'] as Map<String, dynamic>;
      final shareP = qrData.payload['share'] as Map<String, dynamic>;
      final inviterP = qrData.payload['inviter'] as Map<String, dynamic>;

      final now = DateTime.now();
      final event = CountdownEvent(
        id: _uuid.v4(),
        title: eventP['t'] as String,
        targetDate: DateTime.fromMillisecondsSinceEpoch(eventP['d'] as int),
        isLunar: (eventP['l'] as int?) == 1,
        isCountUp: (eventP['u'] as int?) == 1,
        isRepeating: (eventP['r'] as int?) == 1,
        categoryId: eventP['c'] as String? ?? 'custom',
        note: eventP['n'] as String?,
        lunarDateStr: eventP['ls'] as String?,
        createdAt: now,
        updatedAt: now,
      );

      return SharedEventImportData(
        event: event,
        shareId: shareP['shareId'] as String,
        ownerDeviceId: shareP['ownerDeviceId'] as String,
        ownerDisplayName: shareP['ownerDisplayName'] as String,
        version: shareP['version'] as int? ?? 1,
        permission: SharePermission.values[shareP['permission'] as int? ?? 0],
        inviterDeviceId: inviterP['deviceId'] as String,
        inviterDisplayName: inviterP['displayName'] as String,
      );
    } catch (e) {
      debugPrint('parseSharedEvent error: $e');
      return null;
    }
  }

  /// 解析家庭组邀请数据
  static FamilyGroupInviteData? parseFamilyGroupInvite(QRCodeData qrData) {
    if (qrData.type != QRDataType.familyGroup) return null;

    try {
      final p = qrData.payload;
      final inviterP = p['inviter'] as Map<String, dynamic>;

      return FamilyGroupInviteData(
        groupId: p['groupId'] as String,
        groupName: p['groupName'] as String,
        ownerDeviceId: p['ownerDeviceId'] as String,
        ownerDisplayName: p['ownerDisplayName'] as String,
        eventCount: p['eventCount'] as int? ?? 0,
        inviterDeviceId: inviterP['deviceId'] as String,
        inviterDisplayName: inviterP['displayName'] as String,
      );
    } catch (e) {
      debugPrint('parseFamilyGroupInvite error: $e');
      return null;
    }
  }

  /// 生成QR码图像
  static Future<Uint8List?> generateQRCodeImage({
    required String data,
    int size = 300,
    ui.Color foregroundColor = const ui.Color(0xFF000000),
    ui.Color backgroundColor = const ui.Color(0xFFFFFFFF),
  }) async {
    try {
      final qrPainter = QrPainter.withQr(
        qr: QrCode.fromData(
          data: data,
          errorCorrectLevel: QrErrorCorrectLevel.M,
        ),
        color: foregroundColor,
        emptyColor: backgroundColor,
      );

      final image = await qrPainter.toImageData(size.toDouble());
      return image?.buffer.asUint8List();
    } catch (e) {
      debugPrint('generateQRCodeImage error: $e');
      return null;
    }
  }

  /// 生成带Logo的QR码图像
  static Future<Uint8List?> generateQRCodeWithLogo({
    required String data,
    int size = 300,
    ui.Color foregroundColor = const ui.Color(0xFF000000),
    ui.Color backgroundColor = const ui.Color(0xFFFFFFFF),
  }) async {
    // 简化版：先生成普通QR码
    // TODO: 添加Logo支持
    return generateQRCodeImage(
      data: data,
      size: size,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
    );
  }
}
