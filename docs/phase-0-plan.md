# 第 0 阶段详细计划：小部件个性化底座

> 状态：已实现，MuMu 模拟器手工验收通过（2026-08-08），对应 [update-plan.md](update-plan.md) 阶段 0。

## 摘要

第 0 阶段只搭建地基，不改动桌面小部件现有视觉效果。完成三件事：小部件数据协议升级到 v2（向后兼容）、Android 午夜准点刷新、设置页按「样式 / 内容」重构配置面板。交付物包括本详细文档、代码改动、单元测试，以及 `docs/update-plan.md` 中阶段 0 条目的勾选标记。

## 关键改动

### 1. 小部件数据协议 v2

- `CountdownEvent` 新增 `icon` 字段（String，默认 `''`，`toJson` / `fromJson` 用 `optString` 兼容旧数据）；`createdAt` 已存在，直接加入 widget 协议。
- `widget_events` JSON 每个事件追加 `icon`、`createdAt`（毫秒时间戳），供阶段 2 的 Emoji 与进度环使用；`DaymarkWidgetProvider` 的 `WidgetEvent` 同步增加两个 `optString` / `optLong` 读取，渲染逻辑保持现状。
- `AppSettings` 新增协议字段并全部带默认值：`widgetStyle=card`（枚举 card/sticker/photo/glass/polaroid/neon/pixel/minimal，未知值回退 card）、`widgetBackgroundPath=''`、`widgetUnitText=''`、`widgetShowIcon=false`、`widgetShowProgress=false`、`widgetShowPreciseTime=false`、`widgetMysteryMode=false`、`widgetQuoteMode=false`、`widgetFontFamily='system'`、`widgetTextOutline=false`、`widgetWallpaperColor=-1`、`widgetWallpaperDarkColor=-1`、`widgetWallpaperTextColor=-1`。
- `StorageService` 为上述字段新增 SharedPreferences key 并接入 `loadSettings` / `saveSettings`。
- `WidgetService.sync` 额外写入 `widget_protocol_version=2` 和上述全部 key；把事件编码与偏好值构建抽成纯函数 `encodeWidgetEvents(List<CountdownEvent>)`、`widgetPreferenceValues(AppSettings)`，方便单测且阶段 1 直接复用。
- 阶段 1-3 不在此阶段实现，协议字段只负责「写入、解析、回退」，provider 不消费它们。

### 2. Android 午夜准点刷新

- 新增 `MidnightRefreshScheduler.kt`：纯函数 `nextMidnightMillis(now: ZonedDateTime)`；`schedule(context)` 用 `AlarmManager.setWindow(RTC_WAKEUP, 下一个零点, 5 分钟窗口, PendingIntent)`，`cancel(context)` 配套；PendingIntent 统一 `FLAG_IMMUTABLE | FLAG_UPDATE_CURRENT`，action 为 `com.jiuxina.ying.MIDNIGHT_REFRESH`。
- `DaymarkWidgetProvider` 抽出 `updateAllWidgets(context)` 静态方法；`onUpdate` 末尾调用 `MidnightRefreshScheduler.schedule(context)`；`onReceive` 除现有 `NAVIGATE` 外，处理 `MIDNIGHT_REFRESH`、`DATE_CHANGED`、`TIME_SET`、`TIMEZONE_CHANGED`、`BOOT_COMPLETED`、`MY_PACKAGE_REPLACED`，统一执行刷新并重新排程。
- AndroidManifest 的 provider intent-filter 追加 `BOOT_COMPLETED` 与 `MY_PACKAGE_REPLACED`（权限已存在）。不申请 `SCHEDULE_EXACT_ALARM`，保留 30 分钟 `updatePeriodMillis` 作为降级兜底。
- 注意：现有 manifest 虽声明了 `DATE_CHANGED` 等 action，但 `AppWidgetProvider` 默认忽略它们，本次改动才让它们真正生效。

### 3. 设置页与预览重构

- 设置页把「小部件色彩」「文字大小」合并为「小部件样式」区块，把「显示内容」调整为「小部件内容」；「背景」「交互」两个分区不新增占位 UI，等各自第一个功能落地时再显示，避免死控件。
- `WidgetPreviewSection` 改为读取扩展后的 `AppSettings`，因默认值保持现有效果，预览视觉不变。
- 同步更新 `ui_components_test.dart` 中依赖区块标题和开关数量的断言。

### 4. 文档与完成标记

- 新增 `docs/phase-0-plan.md` 并把本计划全文落库，在 `docs/update-plan.md` 阶段 0 处链接过去。
- 实现并验证后，把 `docs/update-plan.md` 阶段 0 的 4 个目标勾为 `[x]`，标注完成版本与日期。

## 测试计划

- Dart 单测：`AppSettings` 新字段默认值、round-trip、旧配置缺字段回退；`CountdownEvent.icon` 序列化；`encodeWidgetEvents` 输出含 `icon` 与 `createdAt`；`widgetPreferenceValues` 输出全部 key 且 `widget_protocol_version=2`。
- Widget 测试：设置页重命名后原有交互全部通过，预览区在深色 / 浅色、200% 字号下无异常。
- Android 单测：`MidnightRefreshSchedulerTest` 覆盖零点前后、跨日、闰日、DST 时区的 `nextMidnightMillis` 计算，以及窗口落在 5 分钟内。
- 验证命令：`flutter analyze`、`flutter test`、`gradlew -p android :app:testDebugUnitTest`（MuMu 环境用现有 `-Pmumu-x64` 构建开关验证）。
- 手工验收：MuMu 添加旧小部件确认视觉与现在一致；跨零点 5 分钟内天数更新；改系统时间 / 时区后小部件立即刷新；无精确闹钟权限仍能工作。

## 验收确认

MuMu 模拟器（x86_64 / Android 12）手工验收通过，日期 2026-08-08：

- [x] 已安装并启动新构建，`widget_protocol_version=2` 与全部新字段默认值写入 `HomeWidgetPreferences`
- [x] 桌面小部件视觉与现状一致，小 / 中尺寸、左右切换、快速完成正常
- [x] 午夜刷新闹钟已排定到下一个 00:00（`RTC_WAKEUP com.jiuxina.ying.MIDNIGHT_REFRESH`）
- [x] 跨零点 5 分钟窗口内天数更新；`DATE_CHANGED` / `TIME_SET` / `TIMEZONE_CHANGED` 广播触发立即刷新
- [x] 未申请精确闹钟权限，30 分钟 `updatePeriodMillis` 轮询保留为降级兜底

## 假设与注意事项

- Android 先行；iOS WidgetKit 不在本阶段改动，共享 Dart 新增 key 对 iOS 无害。
- 「准点」定义为零点的 5 分钟窗口，换取零新权限与低电耗；Doze 下系统可能延迟，由 `DATE_CHANGED` 与 30 分钟轮询兜底。
- 所有新字段缺失时回退默认值，旧小部件无需重新配置；未知 style 值不崩溃。
- 阶段 1-3 的视觉、内容、交互功能均不在第 0 阶段实现，只完成协议与配置底座。
- 工作区当前存在用户未提交的更新检测相关改动，第 0 阶段只触碰协议、刷新、设置页相关文件，不覆盖这些改动。
