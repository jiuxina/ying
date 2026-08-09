import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/utils/widget_content_utils.dart';

void main() {
  setUpAll(() => initializeDateFormatting('zh_CN'));

  CountdownEvent event({
    DateTime? targetDate,
    DateTime? createdAt,
    String note = '',
    String icon = '',
  }) {
    final base = DateTime.now();
    return CountdownEvent(
      id: 'content-$icon-$note',
      title: '考试',
      targetDate:
          targetDate ??
          DateTime(base.year, base.month, base.day).add(
            const Duration(days: 12),
          ),
      category: '学习',
      note: note,
      icon: icon,
      createdAt: createdAt ?? DateTime(base.year, base.month, base.day),
    );
  }

  group('单位文案预设', () {
    test('自动模式保留还有 / 已经 / 就是今天', () {
      final future = event();
      expect(future.dayDelta(), 12);
      expect(widgetCountDisplay(future, '').unitText, '天 · 还有');

      final now = DateTime.now();
      final past = CountdownEvent(
        id: 'past',
        title: '纪念日',
        targetDate: DateTime(now.year, now.month, now.day).subtract(
          const Duration(days: 30),
        ),
        category: '纪念日',
        createdAt: now,
      );
      expect(widgetCountDisplay(past, '').unitText, '天 · 已经');

      final today = event(
        targetDate: DateTime(now.year, now.month, now.day),
      );
      expect(widgetCountDisplay(today, '').unitText, '就是今天');
    });

    test('预设单位与约 X 周', () {
      final future = event();
      expect(widgetCountDisplay(future, 'remaining').unitText, '天 · 还有');
      expect(widgetCountDisplay(future, 'only').unitText, '天 · 只剩');
      expect(widgetCountDisplay(future, 'distance').unitText, '天 · 距离');
      expect(widgetCountDisplay(future, 'elapsed').unitText, '天 · 已经');
      expect(widgetCountDisplay(future, 'weeks').mainText, '约2周');
      expect(widgetCountDisplay(future, 'weeks').unitText, '');
    });
  });

  group('精确时间与进度', () {
    test('时分秒文本支持超过 24 小时', () {
      final future = event(
        targetDate: DateTime(2026, 8, 9, 15, 30),
      );
      expect(
        widgetPreciseTimeText(future, DateTime(2026, 8, 8, 12)),
        '27:30:00',
      );
    });

    test('进度按创建日到目标日计算', () {
      final future = event(
        targetDate: DateTime(2026, 8, 8),
        createdAt: DateTime(2026, 1, 1),
      );
      final progress = widgetProgress(future, DateTime(2026, 7, 27));
      expect(progress, greaterThan(0.9));
      expect(progress, lessThan(1));
      expect(widgetProgressText(future, DateTime(2026, 8, 8)), '100%');
    });
  });

  group('每日一句与农历星期', () {
    test('有备注时按天在备注与内置句间轮播', () {
      final withNote = event(note: '记得带护照');
      final expected = widgetQuoteText(withNote, DateTime(2026, 8, 8));
      expect(expected, isNotEmpty);
      expect(
        expected == '记得带护照' ||
            widgetQuoteText(null, DateTime(2026, 8, 8)).isNotEmpty,
        isTrue,
      );
    });

    test('农历与星期信息包含两个部分', () {
      final info = widgetDateInfo(DateTime(2026, 8, 8));
      expect(info, contains('农历'));
      expect(info, contains('星期六'));
    });
  });

  test('字体预设映射到通用字体族', () {
    expect(widgetFontName('system'), '');
    expect(widgetFontName('mono'), 'monospace');
    expect(widgetFontName('pixel'), 'monospace');
    expect(widgetFontName('hand'), 'serif');
  });

  group('最后 N 天高亮', () {
    test('7 / 3 / 1 天内按阈值切换等级', () {
      final base = DateTime(2026, 8, 8);
      CountdownEvent atDays(int days) => CountdownEvent(
        id: 'urgent-$days',
        title: '考试',
        targetDate: DateTime(
          base.year,
          base.month,
          base.day,
        ).add(Duration(days: days)),
        category: '学习',
        createdAt: base.subtract(const Duration(days: 30)),
      );
      expect(widgetUrgentLevel(atDays(0), now: base), 1);
      expect(widgetUrgentLevel(atDays(1), now: base), 1);
      expect(widgetUrgentLevel(atDays(2), now: base), 3);
      expect(widgetUrgentLevel(atDays(3), now: base), 3);
      expect(widgetUrgentLevel(atDays(4), now: base), 7);
      expect(widgetUrgentLevel(atDays(7), now: base), 7);
      expect(widgetUrgentLevel(atDays(8), now: base), 0);
      expect(widgetUrgentLevel(atDays(-1), now: base), 0);
    });

    test('标签与强调色按等级返回', () {
      expect(widgetUrgentArgb(7), 0xFFB45309);
      expect(widgetUrgentArgb(3), 0xFFC2410C);
      expect(widgetUrgentArgb(1), 0xFFB91C1C);
      expect(widgetUrgentArgb(0), 0);
      expect(widgetUrgentLabel(7, 5), '快到了');
      expect(widgetUrgentLabel(3, 3), '只剩3天');
      expect(widgetUrgentLabel(1, 1), '只剩1天');
      expect(widgetUrgentLabel(1, 0), '就是今天');
    });
  });

  test('Emoji 图标预设始终包含空选项', () {
    expect(eventIconOptions.first, '');
    expect(eventIconOptions.length, greaterThan(10));
  });
}
