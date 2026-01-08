// ============================================================================
// iCalendar 解析服务
// 
// 解析 .ics 文件，提取事件信息
// ============================================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import '../models/countdown_event.dart';
import '../models/event_category.dart';
import 'package:uuid/uuid.dart';

class ICalService {
  static const Uuid _uuid = Uuid();

  /// 解析 .ics 文件内容并返回 CountdownEvent 列表
  static Future<List<CountdownEvent>> parseIcsFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('ICS文件不存在: $filePath');
        return [];
      }

      final content = await file.readAsString();
      return parseIcsContent(content);
    } catch (e) {
      debugPrint('解析ICS文件失败: $e');
      return [];
    }
  }

  /// 解析 .ics 字符串内容
  static List<CountdownEvent> parseIcsContent(String content) {
    try {
      final iCalendar = ICalendar.fromString(content);
      final events = <CountdownEvent>[];
      final now = DateTime.now();

      if (iCalendar.data.isEmpty) return [];

      for (final item in iCalendar.data) {
        if (item['type'] != 'VEVENT') continue;
        
        // 提取标题
        final summary = item['summary']?.toString() ?? '未命名事件';
        
        // 提取日期 (DTSTART;VALUE=DATE:20250101 或 DTSTART:20250101T000000)
        final dtstart = item['dtstart'];
        DateTime? targetDate;

        if (dtstart is IcsDateTime) {
          targetDate = dtstart.toDateTime();
        } else if (dtstart != null) {
          // 尝试手动解析
          targetDate = DateTime.tryParse(dtstart.toString());
        }

        if (targetDate == null) continue;

        // 提取备注
        final description = item['description']?.toString();

        // 提取重复规则 (RRULE) - 简化处理，只识别每年的重复
        bool isRepeating = false;
        final rrule = item['rrule'];
        if (rrule != null && rrule.toString().contains('FREQ=YEARLY')) {
          isRepeating = true;
        }

        events.add(CountdownEvent(
          id: _uuid.v4(),
          title: summary,
          note: description,
          targetDate: targetDate,
          isRepeating: isRepeating,
          categoryId: 'custom', // 默认为自定义
          createdAt: now,
          updatedAt: now,
        ));
      }

      return events;
    } catch (e) {
      debugPrint('解析ICS内容失败: $e');
      return [];
    }
  }
}
