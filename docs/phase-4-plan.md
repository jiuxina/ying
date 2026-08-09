# 第 4 阶段详细计划：实用增强与双端一致

> 状态：已实现，`flutter analyze`、Dart 回归测试与 Android `testDebugUnitTest` 通过（2026-08-09），
> 对应 [update-plan.md](update-plan.md) 阶段 4。

## 摘要

第 4 阶段在阶段 0-3 的基础上补齐实用增强与双端一致：最后 N 天高亮在 7 / 3 / 1 天内自动切换
强调色与文案；新增与总览小部件联动的「单事件专注小部件」，每个实例独立保存事件索引；锁屏 /
负一屏形态完成可行性调研并输出结论；iOS WidgetKit 同步获得临近高亮与单事件专注小部件。
小部件协议升级到 v5（向后兼容），旧配置缺字段时保持原显示。

## 关键改动

### 1. 最后 N 天高亮

- 设置新增「临近高亮」开关，默认关闭，旧配置不回退；写入协议 `widget_urgent_highlight`。
- 7 天内（含 7 天）切换为「快到了」，3 天内切换为「只剩 N 天」，1 天内切换为「只剩 N 天 /
  就是今天」，并分别使用琥珀、橙、红三档强调色渲染数字与单位文案。
- Android 单事件卡片与列表行、应用内预览、iOS WidgetKit 均按同一阈值与配色实现；
  神秘模式与「约 X 周」单位预设不覆盖用户已有的显示选择。

### 2. 双小部件联动

- 新增 Android 单事件专注小部件 `DaymarkDetailWidgetProvider`，复用单事件卡片布局，
  与总览小部件（`DaymarkWidgetProvider`，支持单事件 / 列表）共享同一份事件与偏好数据。
- 每个单事件实例使用独立索引键 `daymark_detail_widget_index_$widgetId`，左右切换只影响
  该实例；总览小部件仍使用原 `daymark_widget_index_$widgetId`，互不干扰。
- 数据同步时同时刷新两个 provider；午夜准点刷新也分别调度两个 provider。
- 设置页预览新增「添加单事件小部件」入口，仅在系统支持固定小部件时显示。
- iOS 新增 `DaymarkDetailWidget` WidgetKit 小部件，配置意图可选择一个事件固定显示。

### 3. 锁屏 / 负一屏形态调研

- 输出调研结论到 [phase-4-platform-research.md](phase-4-platform-research.md)：Android 原生
  锁屏小部件没有系统级 API，负一屏由各厂商 Launcher 自行实现，现阶段不建议实现；
  iOS 锁屏由 WidgetKit accessory family 支持，可作为后续独立小版本评估。

## 测试计划

- Dart 单测：7 / 3 / 1 天阈值、强调色 ARGB、高亮文案；协议 v5 字段默认值与往返。
- Widget 测试：临近高亮开启后预览替换单位文案；设置页开关与持久化。
- Android 单测：`urgentLevel` / `urgentAccent` / `urgentLabel` 边界；
  Manifest 注册单事件小部件及其独立 `appwidget-provider` 配置。
- 验证命令：`flutter analyze`、`flutter test`（本机启动器偶发卡住时按文件拆分回归）、
  `gradlew -p android :app:testDebugUnitTest`。

## 假设与注意事项

- 单事件小部件用左右按钮切换事件，不新增配置页；每实例索引保存在
  `HomeWidgetPreferences`，卸载重装后回到第一个事件。
- 高亮阈值按剩余天数计算，已过去的事件（正计时）不触发高亮。
- 高亮文案优先于自动单位文案，但不覆盖「约 X 周」与神秘模式。
- 协议升级到 v5 只新增布尔字段，Android / iOS 均以 `getBoolean(..., false)` 回退。

## 验收修复记录（2026-08-09）

- 本机 `flutter test` 全量启动器仍会卡住（阶段 3 已知问题），本次按文件拆分回归：
  `widget_content_test`、`widget_protocol_test`、`ui_components_test` 均通过。
- MuMu 模拟器（x86_64 / Android 12）已安装 2.3.0 调试构建并启动，桌面手工验收步骤见
  [release-notes-v2.3.0-phase4.md](../../outputs/release-notes-v2.3.0-phase4.md)。
- 修复跨日翻牌旧天数未清除导致数字残留（`ACTION_REFRESH_FLIP` 先清理 `widget_flip_day`
  再刷新）；临近高亮 7 天档文案补回「天」，如「4天 · 快到了」（2026-08-09）。
- 用户复核通过（2026-08-09）：临近高亮显示「4天 · 快到了」，切换事件后不再残留旧天数。
