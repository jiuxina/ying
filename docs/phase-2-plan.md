# 第 2 阶段详细计划：内容个性化

> 状态：代码与自动化验证已完成（2026-08-08），模拟器手工验收待执行，对应 [update-plan.md](update-plan.md) 阶段 2。

## 摘要

第 2 阶段在阶段 0 的协议底座与阶段 1 的视觉底座上落地内容个性化：滚动事件列表、单位文案预设、事件 Emoji、精确到时分秒、农历与星期、进度环、神秘模式、每日一句与数字字体。小部件协议升级到 v4（向后兼容），旧配置缺字段时继续按原行为渲染。

## 关键改动

### 1. 内容工具层

- 新增 `lib/utils/widget_content_utils.dart`，集中提供单位文案预设（自动 / 还有 / 只剩 / 距离 / 已经 / 约 X 周）、精确时分秒文本、进度百分比、农历与星期信息、每日一句轮播、字体映射与事件 Emoji 预设。
- 单位文案按协议值写入 `widget_unit_text`；「约 X 周」把完整短语放在主数字区，其余预设沿用天数 + 文案结构。
- 精确时间用 `widgetPreciseTimeText` 生成超过 24 小时的 `HH:MM:SS`；Android 侧优先用 `Chronometer` 自动走秒，API 24 以下回退静态文本。
- 每日一句复用内置句子列表，有备注时按天在备注与内置句间轮播。
- 农历与星期在应用侧用 `lunar` 包计算后写入 `widget_date_info`，Android 侧用 `android.icu.util.ChineseCalendar` 兜底。

### 2. 协议与配置

- 小部件协议升到 v4，事件 JSON 新增 `targetTime`（完整目标时间戳），偏好值新增 `widget_show_lunar_week`、`widget_list_mode`、`widget_date_info`。
- `AppSettings` 新增 `widgetShowLunarWeek`、`widgetListMode` 两个字段，默认关闭；`StorageService` 同步读写。
- 旧配置缺少新字段时一律回退默认值，未知单位 / 字体值不崩溃。

### 3. 事件 Emoji

- 事件表单新增 Emoji 选择器（空选项 + 20 个常用 Emoji），保存到 `CountdownEvent.icon`。
- 事件卡片与详情页在标题前显示 Emoji；小部件开启「事件图标」后显示。

### 4. 设置页与预览

- 「小部件内容」区块新增：事件图标、精确到秒、农历与星期、进度百分比、神秘模式、每日一句、单位文案、数字字体。
- 新增「小部件列表」区块，提供事件列表模式开关。
- 应用内预览同步渲染全部新功能：进度环、Emoji、精确时间、农历星期、轮播文案与字体；列表模式展示多行事件预览。

### 5. Android 小部件

- 单事件卡片支持 Emoji、单位预设、Chronometer 精确秒、农历星期、进度环位图、神秘模式（蜡烛 + 快到了）、每日一句与数字字体（系统 / 等宽 / 像素 / 手写，用预置字体族 TextView 切换）。
- 列表模式使用 `RemoteViewsService` + `RemoteViewsFactory` 渲染可滚动事件列表，每行显示图标、标题、分类、精确时间与天数；数据变化时调用 `notifyAppWidgetViewDataChanged`。
- 新增 `daymark_widget_list.xml`、`daymark_widget_list_item.xml` 与 `DaymarkWidgetRemoteViewsService`，Manifest 注册 `BIND_REMOTEVIEWS` 服务。

## 测试计划

- Dart 单测：单位文案预设、精确时分秒、进度、农历星期、每日一句轮播、字体映射、协议 v4 字段与 `targetTime`。
- Widget 测试：Emoji 保存、单位 / 字体预设持久化、列表模式开关、内容个性化预览渲染与列表预览。
- Android 单测：`WidgetAppearanceTest` 覆盖单位文案、精确时间、进度、轮播、农历星期兜底与 `targetTime` 解析；`org.json` 作为 testImplementation 保证 JVM 单测可解析协议。
- 验证命令：`flutter analyze`、`flutter test`、`gradlew -p android :app:testDebugUnitTest`（MuMu 环境用现有 `-Pmumu-x64` 构建开关验证）。

## 假设与注意事项

- 数字字体先用系统字体族（monospace / serif）与像素风格排版实现，打包字体素材留待后续补充。
- `Chronometer.setCountDown` 依赖 API 24+，低版本自动回退为静态时分秒文本。
- 农历与星期由应用侧计算写入，Android 只在缺少配置时兜底，避免每次刷新重复换算。
- 列表模式复用样式背景与文字配色，行内点击统一打开应用；左右切换按钮在列表模式下不显示。

## 验收确认

设备检查（MuMu x86_64 / Android 12，2026-08-08）：

- [x] 已安装 2.2.0 调试构建并启动，无 FATAL / AndroidRuntime 异常
- [x] `HomeWidgetPreferences` 写入 `widget_protocol_version=4`、`widget_date_info`、`widget_list_mode`、`widget_show_lunar_week`，事件 JSON 含 `targetTime`
- [x] Manifest 合并产物注册 `DaymarkWidgetRemoteViewsService` 与 `BIND_REMOTEVIEWS`

待桌面手工验收：

- [ ] 应用内设置与预览：各新开关、单位 / 字体预设、Emoji、列表模式切换后预览即时同步
- [ ] 桌面小部件单事件卡片：Emoji、精确秒走秒、农历星期、进度环、神秘模式、每日一句、字体生效
- [ ] 桌面小部件列表模式：多事件滚动、点击行打开应用、无「无法加载微件」提示
- [ ] 旧小部件缺少新配置时保持原显示
- [ ] `flutter analyze`、`flutter test`、Android `testDebugUnitTest` 全部通过
