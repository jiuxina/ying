# 第 3 阶段详细计划：交互增强

> 状态：已实现，`flutter analyze`、`flutter test` 与 Android `testDebugUnitTest` 通过（2026-08-08），对应 [update-plan.md](update-plan.md) 阶段 3。

## 摘要

第 3 阶段在 RemoteViews 的交互限制内，把单事件小部件的点击目标拆细：标题区打开详情、日期区复制卡片、完成按钮快速完成并支持 6 秒内撤销、`+` 按钮直接新建；天数变化时用短时两帧切换模拟跨日翻牌。列表模式同时获得 `+` 快捷新建与行内完成按钮。

## 关键改动

### 1. 小部件分区点击

- 单事件小部件标题行绑定 `ying://open?id=...` 前台启动 URI，点击直达事件详情页。
- 日期区绑定 `ying://copy?id=...` 后台回调，复制「XXX：还有 N 天」样式卡片文案并提示。
- 完成按钮沿用 `ying://complete?id=...` 后台回调；列表行新增行内完成按钮，同一回调处理。
- `HomeWidgetBackgroundIntent` 的 PendingIntent 改为按事件 ID 生成独立 requestCode，避免多行共享同一个 PendingIntent。

### 2. 直接新建

- 单事件与列表小部件均新增「+」按钮，绑定 `ying://add` 前台启动 URI。
- `lib/services/widget_launch_actions.dart` 统一处理小部件启动 URI：冷启动与前台点击都打开新建表单或详情页。

### 3. 快速完成与 6 秒撤销

- 小部件完成回调写 `widget_pending_undo`（事件 JSON + 过期时间），6 秒内小部件切换到撤销面板。
- Android 侧用 `AlarmManager` 在过期后刷新并清理撤销状态；撤销按钮绑定 `ying://undo?id=...` 后台回调，恢复事件后写回小部件。
- 撤销与 App 内完成共用 `AppController.toggleCompletedWithUndo` 的同一持久化与撤销模型。

### 4. 跨日翻牌动效

- `WidgetService.syncWithFlip` 检测天数变化，把旧天数写入 `widget_flip_day`。
- Android 侧先渲染旧天数（半透明旧值 + 新值），400ms 后由 `ACTION_REFRESH_FLIP` 刷新切换到新天数，模拟短时两帧翻牌。

## 测试计划

- Dart 单测：分享卡片文案（还有 / 已经 / 就是今天）、`PendingUndoPayload` 编解码与异常回退、6 秒窗口、`syncWithFlip` 天数变化写旧值。
- AppController 测试：`beforeWidgetSync` 在小部件同步前执行。
- Android 单测：`PendingUndoPayload` 解析、过期判定与异常 JSON 回退。
- 验证命令：`flutter analyze`、`flutter test`、`gradlew -p android :app:testDebugUnitTest -Pmumu-x64`。

## 假设与注意事项

- RemoteViews 不支持手势，复制 / 撤销均用按钮与背景回调实现；分享先用复制到剪贴板，不调用系统分享面板。
- 连点彩蛋与列表行长按分享留待后续版本；列表滚动本身由 `RemoteViewsService` 提供。
- 撤销窗口固定 6 秒，过期后由闹钟刷新清理，普通轮询刷新也会兜底。
