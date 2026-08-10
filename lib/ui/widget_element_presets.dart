import 'package:flutter/material.dart';

import '../models/widget_element_style.dart';

/// 逐元素自定义可选用的 12 色预设。
const widgetElementColorPalette = <Color>[
  Color(0xFFFFFFFF),
  Color(0xFFF4F4F5),
  Color(0xFF0F766E),
  Color(0xFF2563EB),
  Color(0xFF7C3AED),
  Color(0xFFDB2777),
  Color(0xFFEA580C),
  Color(0xFFFACC15),
  Color(0xFF22C55E),
  Color(0xFF06B6D4),
  Color(0xFF1C1C1E),
  Color(0xFFFF6B6B),
];

const widgetTextElementOptions = <(String, String, IconData)>[
  ('category', '分类标签样式', Icons.tag_rounded),
  ('holidayBadge', '节日徽章样式', Icons.celebration_outlined),
  ('title', '标题样式', Icons.title_rounded),
  ('days', '天数数字样式', Icons.pin_rounded),
  ('unit', '单位文案样式', Icons.text_fields_rounded),
  ('note', '备注样式', Icons.notes_rounded),
  ('precise', '精确时间样式', Icons.timer_outlined),
  ('dateInfo', '农历星期样式', Icons.calendar_month_outlined),
  ('progress', '进度元素样式', Icons.donut_small_rounded),
  ('icon', '图标样式', Icons.emoji_emotions_outlined),
  ('listHeader', '列表标题样式', Icons.view_headline_rounded),
  ('rowTitle', '列表行标题样式', Icons.article_outlined),
  ('rowSubtitle', '列表行副标题样式', Icons.subtitles_rounded),
  ('rowDays', '列表行天数样式', Icons.tag_rounded),
  ('rowUnit', '列表行单位样式', Icons.abc_rounded),
  ('empty', '空状态样式', Icons.inbox_outlined),
];

const widgetButtonElementOptions = <(String, String, IconData)>[
  ('prevButton', '上一个事件', Icons.chevron_left_rounded),
  ('nextButton', '下一个事件', Icons.chevron_right_rounded),
];

const widgetVisibleOptions = <(WidgetElementVisible, String)>[
  (WidgetElementVisible.follow, '跟随'),
  (WidgetElementVisible.show, '显示'),
  (WidgetElementVisible.hide, '隐藏'),
];

const widgetSizeOptions = <(WidgetElementSize, String)>[
  (WidgetElementSize.small, '小'),
  (WidgetElementSize.normal, '默认'),
  (WidgetElementSize.large, '大'),
  (WidgetElementSize.xlarge, '特大'),
];

const widgetColorModeOptions = <(WidgetColorMode, String)>[
  (WidgetColorMode.primary, '主色'),
  (WidgetColorMode.secondary, '次要色'),
  (WidgetColorMode.custom, '自定义'),
];

const widgetAlignOptions = <(WidgetAlign, String)>[
  (WidgetAlign.start, '左'),
  (WidgetAlign.center, '中'),
  (WidgetAlign.end, '右'),
];

const widgetVerticalAlignOptions = <(WidgetVerticalAlign, String)>[
  (WidgetVerticalAlign.top, '顶部'),
  (WidgetVerticalAlign.center, '居中'),
  (WidgetVerticalAlign.bottom, '底部'),
];

/// 只有独立成行的文字与天数数字区提供水平对齐选项。
const widgetAlignableElementIds = <String>{
  'category',
  'title',
  'days',
  'note',
  'precise',
  'dateInfo',
  'empty',
  'listHeader',
  'rowTitle',
  'rowSubtitle',
};

/// 默认使用主色的文字角色；其余角色默认使用次要色。
const widgetPrimaryElementIds = <String>{
  'title',
  'days',
  'icon',
  'rowTitle',
  'rowDays',
};
