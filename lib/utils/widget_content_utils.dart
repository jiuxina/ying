import 'package:lunar/lunar.dart';

import '../models/countdown_event.dart';

/// 阶段 2 单位文案预设；空值表示沿用自动（还有 / 已经 / 就是今天）。
const widgetUnitPresetOptions = <(String, String)>[
  ('', '自动'),
  ('remaining', '还有'),
  ('only', '只剩'),
  ('distance', '距离'),
  ('elapsed', '已经'),
  ('weeks', '约 X 周'),
];

/// 数字字体预设；协议值与 Android `Typeface` 映射见各自实现。
const widgetFontOptions = <(String, String)>[
  ('system', '系统'),
  ('mono', '等宽'),
  ('pixel', '像素'),
  ('hand', '手写'),
];

/// 事件表单可选的 Emoji 图标，空字符串表示不显示。
const eventIconOptions = <String>[
  '',
  '🎂',
  '🎉',
  '🎓',
  '✈️',
  '❤️',
  '💍',
  '🏠',
  '💼',
  '📚',
  '🏆',
  '🎁',
  '🌱',
  '⭐',
  '🎄',
  '⛰️',
  '🏝️',
  '📝',
  '🚗',
  '🎯',
];

class WidgetCountDisplay {
  const WidgetCountDisplay({required this.mainText, required this.unitText});

  final String mainText;
  final String unitText;
}

/// 计算小部件主数字与单位文案；「约 X 周」模式把完整短语放主数字区。
WidgetCountDisplay widgetCountDisplay(CountdownEvent event, String preset) {
  if (preset == 'weeks' && event.dayDelta() != 0) {
    return WidgetCountDisplay(
      mainText: '约${widgetWeekCount(event)}周',
      unitText: '',
    );
  }
  final verb = widgetUnitVerb(event, preset);
  final unit = switch (verb) {
    '就是今天' => '就是今天',
    '还有' => '天 · 还有',
    '只剩' => '天 · 只剩',
    '距离' => '天 · 距离',
    '已经' => '天 · 已经',
    _ => '天',
  };
  return WidgetCountDisplay(
    mainText: '${event.displayDays}',
    unitText: unit,
  );
}

String widgetUnitVerb(CountdownEvent event, String preset) {
  switch (preset) {
    case 'remaining':
      return '还有';
    case 'only':
      return '只剩';
    case 'distance':
      return '距离';
    case 'elapsed':
      return '已经';
  }
  if (event.dayDelta() == 0) return '就是今天';
  return event.isCountingUp ? '已经' : '还有';
}

int widgetWeekCount(CountdownEvent event) =>
    (event.displayDays / 7).round().clamp(1, 999);

/// 精确到时分秒的倒计时 / 正计时文本，小时数可超过 24。
String widgetPreciseTimeText(CountdownEvent event, DateTime now) {
  final difference = event.isCountingUp
      ? now.difference(event.targetDate)
      : event.targetDate.difference(now);
  final totalSeconds = difference.inSeconds.clamp(0, 359999999);
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

/// 从创建日到目标日的完成进度，区间为 0..1。
double widgetProgress(CountdownEvent event, DateTime now) {
  final total = event.targetDate.difference(event.createdAt).inMilliseconds;
  if (total <= 0) return 1;
  final elapsed = now.difference(event.createdAt).inMilliseconds;
  return (elapsed / total).clamp(0.0, 1.0);
}

String widgetProgressText(CountdownEvent event, DateTime now) =>
    '${(widgetProgress(event, now) * 100).round()}%';

const _builtInQuotes = <String>[
  '把日子过成诗',
  '今天也值得纪念',
  '慢慢来，比较快',
  '每个今天都是礼物',
  '好事会发生',
  '记得抬头看月亮',
  '认真生活的你闪闪发光',
  '向前走，别回头',
];

/// 每日一句 / 备注轮播：有备注时按天在备注与内置句子间切换。
String widgetQuoteText(CountdownEvent? event, DateTime now) {
  final note = event?.note.trim() ?? '';
  final dayNumber = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(2000)).inDays;
  if (note.isNotEmpty && dayNumber.isEven) return note;
  return _builtInQuotes[dayNumber.abs() % _builtInQuotes.length];
}

/// 农历与星期信息，例如「农历八月十五 · 星期六」。
String widgetDateInfo(DateTime date) {
  final lunar = Solar.fromDate(date).getLunar();
  const weekdays = <int, String>{
    1: '星期一',
    2: '星期二',
    3: '星期三',
    4: '星期四',
    5: '星期五',
    6: '星期六',
    7: '星期日',
  };
  final weekday = weekdays[date.weekday] ?? '';
  return '农历${lunar.getMonthInChinese()}月${lunar.getDayInChinese()} · $weekday';
}

/// 把协议字体预设映射为 Flutter 可用的通用字体族，空字符串表示系统默认。
String widgetFontName(String family) => switch (family) {
  'mono' || 'pixel' => 'monospace',
  'hand' => 'serif',
  _ => '',
};

/// 最后 N 天高亮等级：0 表示未触发，7 / 3 / 1 对应 7 天、3 天、1 天内。
/// 已过去的事件（正计时）不触发高亮。
int widgetUrgentLevel(CountdownEvent event, {DateTime? now}) {
  final days = event.dayDelta(now);
  if (days < 0) return 0;
  if (days <= 1) return 1;
  if (days <= 3) return 3;
  if (days <= 7) return 7;
  return 0;
}

/// 临近高亮对应的 ARGB 强调色；0 表示未触发，调用方自行决定是否使用。
int widgetUrgentArgb(int level) => switch (level) {
  7 => 0xFFB45309,
  3 => 0xFFC2410C,
  1 => 0xFFB91C1C,
  _ => 0,
};

/// 临近高亮替换单位区域的文案；[days] 为剩余天数（非负）。
String widgetUrgentLabel(int level, int days) => switch (level) {
  7 => '天 · 快到了',
  3 => '只剩$days天',
  1 => days == 0 ? '就是今天' : '只剩$days天',
  _ => '',
};
