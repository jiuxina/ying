# 锁屏 / 负一屏小部件形态调研

> 结论：Android 现阶段不实现锁屏 / 负一屏小部件；iOS 锁屏小部件（WidgetKit accessory
> family）留作后续独立小版本评估。调研日期 2026-08-09。

## Android 锁屏小部件

- 原生 Android 从 API 8 开始只在「主屏幕」提供 `AppWidgetProvider`，
  `android:widgetCategory` 仅支持 `home_screen`，系统没有锁屏小部件的公开 API。
- 部分厂商（三星、部分国产 ROM）通过自家 Launcher / 系统 UI 支持锁屏卡片或小组件，
  但实现、权限、交互和尺寸均无统一标准，无法用一套 RemoteViews 兼容多机型。
- Android 12+ 的锁屏只允许通知样式内容（`Notification.Style`），
  与「倒数日小部件」的信息密度和点击交互不匹配。
- 第三方锁屏应用需要常驻前台服务、悬浮窗或辅助功能权限，能耗与隐私代价高，不建议采用。

结论：不实现 Android 锁屏小部件，保持主屏幕小部件与通知提醒作为入口。

## Android 负一屏

- 负一屏（智慧助手 / Discover / App Drawer 等）由各厂商 Launcher 私有实现，
  Google 提供的是 `Feed` / 快捷方式协议，第三方应用没有通用的小部件挂载接口。
- 小米、华为、vivo、OPPO 各有自己的负一屏卡片协议，需逐厂商申请与适配，
  维护成本高且无统一验收标准。

结论：不实现 Android 负一屏卡片；后续若需覆盖，优先评估各厂商卡片平台与用户占比。

## iOS 锁屏小部件

- WidgetKit 从 iOS 16 开始支持锁屏形态：`accessoryCircular`、`accessoryRectangular`、
  `accessoryInline` 三种 accessory family，可放在锁屏与 StandBy 上。
- 限制：交互极少（无按钮 AppIntent，只能 `widgetURL` 跳转）、背景固定深色、
  字体很小，适合单数字或单行文本，不适合完整倒数卡片。
- 对「萤」而言，`accessoryRectangular` 可显示「标题 + 剩余 N 天」，是最合理的锁屏形态。

结论：iOS 锁屏可作为后续独立小版本（配合 accessory family 与 timeline 刷新）实现，
本轮先完成可行性结论，不阻塞 2.3.0 发版。

## 与双端一致的关系

- 本轮双端一致范围限定主屏幕小部件：Android AppWidget 与 iOS WidgetKit 对等实现
  临近高亮与单事件专注小部件。
- 锁屏 / 负一屏属于平台能力差异，按上述结论分别处理，不纳入「双端一致」验收。
