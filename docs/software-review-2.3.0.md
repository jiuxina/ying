# 萤 2.3.0 全面 Review 报告

## 0. 报告信息

- 审查对象：`F:\xm\ying\daymark`（Flutter 应用仓库）
- 应用名称：萤
- 版本：`2.3.0+5`（`pubspec.yaml`）
- 技术栈：Flutter 3.35.4 / Dart 3.9.2，Riverpod 2.6.1，Android AppWidget + Kotlin，iOS 17 WidgetKit + SwiftUI/AppIntents
- 审查日期：2026-08-09
- 审查基准提交：`45a356d docs: 标记阶段5手工验收通过`
- 审查方式：逐文件阅读 Dart、Kotlin、Swift、Gradle、Manifest、CI 配置与测试代码，并运行静态分析与测试验证

## 1. 结论摘要

萤是一款本地优先、无账号无服务端的倒数日应用，整体工程质量良好：

- 架构分层清楚：`models / services / state / ui / utils` 职责边界明确；
- 依赖注入方式可测试：`AppController` 对存储、通知、小部件同步、更新检查均可注入替身；
- 测试覆盖认真：模型、撤销事务、更新检测、UI 组件、无障碍、小部件协议均有覆盖；
- 视觉系统统一：玻璃材质、主题色、控件语义集中管理，支持减少透明度与减少动画；
- 隐私设计符合定位：无遥测、无埋点，唯一网络请求是 GitHub 更新检查，敏感文件已正确忽略。

但本次 Review 也确认了若干必须优先处理的问题：

- **P1：iOS 小部件点击打开事件的 URL host 与 Flutter 侧不一致，点击小部件无法进入事件详情。**
- **P1：`widget_launch_actions_test.dart` 会稳定挂起，导致完整测试套件无法跑绿。**
- **P1：Release APK 使用 debug keystore 签名，不适合作为正式分发产物。**
- **P2：Dart 侧天数计算使用本地时间差值，夏令时切换日可能差一天，与 Android/iOS 原生侧不一致。**
- **P2：本地数据损坏时的异常处理不完整，坏数据可能让应用启动崩溃。**

严重度统计：P1 × 3，P2 × 4，P3 × 8，建议项 × 5。

### 修复状态（2026-08-09 收尾）

| 编号 | 状态 | 说明 |
| --- | --- | --- |
| P1-01 iOS 小部件跳转 | 已修复 | iOS 统一为 `ying://open` / `ying://add`，Flutter 侧兼容旧 host `event` / `new` |
| P1-02 测试挂起 | 已修复 | 启动动作处理器不再等待 UI Future；测试装置补齐 locale 初始化与数据加载；完整套件 `--concurrency=1` 123 项通过 |
| P1-03 Release 签名 | 已修复 | 移除 debug 签名；无密钥时 release 构建明确失败；CI 增加 Secrets 注入与 `apksigner` 校验 |
| P2-01 夏令时天数 | 已修复 | 天数计算改为 UTC 零点归一化，新增纽约 DST 回归测试 |
| P2-02 坏数据容错 | 已修复 | 解析异常全量兜底，`decodeList` 增加结构校验，新增 3 个坏数据用例 |
| P2-03 iOS 默认色/索引 | 部分修复 | 默认色与占位色已对齐；每实例独立索引受 WidgetKit AppIntent 无实例 ID 限制，保留为已知限制 |
| P2-04 启动 URI 防失控 | 已修复 | 去重表上限 64、冷启动重试上限 20 次、旧 host 兼容 |
| P3 清单 | 已修复 | 通知权限缓存、双重压缩、SnackBar 深浅色、负字距归零、Gradle 模板注释清理等 |
| 依赖升级 | 延后 | 已审计：riverpod 3.x、home_widget 0.9.x、flutter_local_notifications 22.x 需 API 迁移，设回退门槛另行专项升级 |
| 大文件拆分 | 已修复 | Kotlin 协议拆到 `WidgetProtocol.kt`；Dart 预览画家与设置页控件拆为 `part` 文件 |
| 集成测试 | 已修复 | 新增 `integration_test` 冒烟测试并在模拟器通过 |

## 2. 审查范围与方法

### 2.1 覆盖范围

| 区域 | 覆盖内容 |
| --- | --- |
| Dart 应用层 | `lib/` 全部 34 个源文件 |
| Dart 测试 | `test/` 全部 12 个测试文件 |
| Android 原生 | `MainActivity.kt`、两个 AppWidget Provider、`MidnightRefreshScheduler.kt`、Manifest、Gradle 配置、布局与 XML |
| iOS 原生 | `DaymarkWidget.swift`、`AppDelegate.swift`、`BackgroundIntent.swift`、Podfile、entitlements |
| 工程配置 | `pubspec.yaml`、`analysis_options.yaml`、`.gitignore`、`.github/workflows/build-apk.yml` |
| 文档 | `README.md`、`docs/` 下 9 份计划/调研文档 |

### 2.2 执行过的验证

| 命令 | 结果 |
| --- | --- |
| `flutter analyze` | 通过，0 issues |
| `flutter test --concurrency=1`（完整套件） | 修复后 123 项全部通过 |
| `git ls-files` + `.gitignore` 检查 | `tools/vision_bridge/.env` 未被 Git 跟踪，已正确忽略 |

未执行项：

- iOS 构建与真机验证：当前为 Windows 环境，无法执行 Xcode 构建；
- 安卓模拟器安装与手工验收：将按仓库规则在收尾阶段尝试；
- `tools/vision_bridge`：属于开发辅助工具，本次仅做静态检查，未调用外部 API。

## 3. 架构概览

### 3.1 Flutter 应用

入口 `lib/main.dart` 在启动时依次完成：日期格式化、通知服务初始化、小部件服务初始化、小部件冷启动 URI 监听；随后以 `ProviderScope` 挂载 `DaymarkApp`。

状态层：

- `AppController`（`lib/state/app_controller.dart`）是唯一状态中枢，维护事件列表、设置、撤销栈与更新横幅；
- 所有异步副作用（存储、通知、小部件同步、更新检查）通过构造器注入，便于测试；
- 撤销采用“内存先隐藏、持久化安全保留、定时最终化”的设计，删除类操作在窗口内不会被真正落盘。

数据层：

- `StorageService` 使用 `SharedPreferences` 保存事件 JSON 与全部设置；
- `CountdownEvent` 自带旧数据迁移（`reminderMinutes` 转多提醒、`isAllDay` 缺省、`repeatType` 缺省）；
- 小部件协议为版本化 JSON + 偏好键（当前 `widget_protocol_version = 6`）。

服务层：

- `NotificationService`：多提醒调度、iOS 待通知数量上限、通知按钮动作、后台通知回调、提醒诊断；
- `WidgetService`：App Group 与原生小部件同步、跨日翻牌、偏好下发、一键刷新与状态查询；
- `UpdateService`：GitHub Releases 检测，404 时回退最新 tag，限流/网络错误有中文提示；
- 照片背景、壁纸取色、背景图片读取均有 io/web/stub 条件导出。

### 3.2 Android 原生

- `DaymarkWidgetProvider`（1801 行）：总览小部件、单事件切换、列表模式、14 套样式、翻牌、信封/撤销/Toast；
- `DaymarkDetailWidgetProvider`：单事件专注小部件，每实例独立索引；
- `MidnightRefreshScheduler`：本地零点后 5 分钟窗口触发刷新，配合 30 分钟轮询与系统广播兜底；
- `MainActivity`：通知设置与壁纸取色两个 MethodChannel。

### 3.3 iOS 原生

- `DaymarkWidget.swift`：总览小部件（左右切换 + 快速完成）与单事件专注小部件；
- `BackgroundIntent.swift`：通过 `HomeWidgetBackgroundWorker` 执行后台完成动作；
- 主 App 与 Extension 共享 `group.com.jiuxina.ying` App Group。

## 4. 关键发现

严重度定义：

- P1：影响用户核心功能、发布流程或测试流水线，应尽快修复；
- P2：在特定场景产生错误行为或明显风险，应在下一版本修复；
- P3：体验、维护性或规范问题，可安排低优先级修复；
- 建议：不阻塞发布，但值得纳入后续规划。

### 4.1 P1-01：iOS 小部件点击打开事件失效

现象：

- iOS 小部件把整卡链接写为 `ying://event?id=<eventId>`（`ios/DaymarkWidget.swift:190`、`:377`）；
- 空状态写为 `ying://new`（`DaymarkWidget.swift:200`、`:387`）；
- Flutter 侧 `handleWidgetLaunchUri` 只处理 host 为 `add` 和 `open` 的分支（`lib/services/widget_launch_actions.dart:27-39`）。

结论：

- iOS 用户点击小部件卡片只会拉起应用，不会进入事件详情；
- 空状态下点击也只会打开应用，不会弹出新建表单；
- Android 侧使用 `ying://open?id=...`，因此该问题只在 iOS 出现。

建议：

- 统一 iOS 与 Android 的协议：iOS 改为 `ying://open?id=...`，空状态改为 `ying://add`；
- 在 `handleWidgetLaunchUri` 中为未知 host 增加可观测日志，避免再次出现静默失效；
- 补充覆盖 iOS URL host 的单元测试。

### 4.2 P1-02：`widget_launch_actions_test.dart` 稳定挂起

现象：

- `flutter test --timeout 30s test\widget_launch_actions_test.dart` 单独运行也会超时，且无任何测试输出；
- 完整 `flutter test` 因此无法跑绿。

根因分析：

- 测试在 `test/widget_launch_actions_test.dart:47`、`:59`、`:78` 处 `await handleWidgetLaunchUri(...)`；
- 而 `handleWidgetLaunchUri` 内部 `await _showAddSheet(...)` / `await navigator.push(...)`（`widget_launch_actions.dart:28-38`），这两个 Future 只有在底部弹窗或路由被关闭后才会完成；
- 测试从未关闭弹窗/路由，于是 `await` 永久挂起。

建议：

- 方式一：测试改为 `unawaited(handleWidgetLaunchUri(...))` 后 `pumpAndSettle()`，并在用例结束时关闭弹窗/路由；
- 方式二：让 `handleWidgetLaunchUri` 改为 fire-and-forget（不等待 UI Future），与生产调用点 `unawaited(...)` 的语义一致；
- 推荐方式二 + 方式一同时落地：既消除死锁风险，也让测试语义清晰。

注意：审查期间曾尝试方式二并复跑，但当时环境残留了多个 `flutter_tester` 进程导致验证被污染，随后已回退该改动，未把未经验证的修改留在工作区。

### 4.3 P1-03：Release APK 使用 debug 签名

位置：`android/app/build.gradle.kts:43-47`

```kotlin
release {
    // TODO: Add your own signing config for the release build.
    signingConfig = signingConfigs.getByName("debug")
}
```

影响：

- GitHub Actions 在打 tag 时构建的 Release APK（`.github/workflows/build-apk.yml:37-42`）全部使用 debug keystore 签名；
- 用户下载的“正式包”实际是 debug 签名，无法用于 Google Play 发布，也不能安全地升级到正式签名包；
- 若 keystore 泄露，debug 密钥可以伪造应用更新，安全风险不可接受。

建议：

- 配置独立 release keystore，密钥以 CI Secrets 注入，不在仓库保存；
- CI 中增加签名校验步骤，确保产物不是 debug 签名；
- 在 README 明确区分“本地调试包”与“正式发布包”。

### 4.4 P2-01：夏令时切换日天数差一天

位置：

- Dart：`lib/models/countdown_event.dart:52-56` 的 `dayDelta` 使用本地 `DateTime` 差值后取 `.inDays`；
- Android：`DaymarkWidgetProvider.kt:1768-1773` 使用 `ChronoUnit.DAYS.between`（日历日，正确）；
- iOS：`DaymarkWidget.swift:18-24` 使用 `Calendar` 的 `dateComponents([.day])`（日历日，正确）。

影响：

- 在春季拨快或秋季拨慢的日期，本地午夜之间的实际时长是 23/25 小时，`.inDays` 向下取整会得到错误天数；
- 应用内天数与桌面小部件天数可能不一致，且跨日翻牌也可能显示旧值。

建议：

- Dart 侧改用 UTC 零点比较，或先归一化到 `DateTime.utc(year, month, day)` 再求差；
- 增加 DST 边界用例（如 3 月某周日 / 11 月某周日）的单元测试。

### 4.5 P2-02：本地数据损坏时异常处理不完整

位置：`lib/services/storage_service.dart:42-46`

```dart
try {
  return CountdownEvent.decodeList(raw);
} on FormatException {
  return const [];
}
```

问题：

- `CountdownEvent.decodeList`（`lib/models/countdown_event.dart:175-180`）会对 JSON 结果做 `as List<dynamic>` / `as Map<String, dynamic>` 强转；
- 若偏好数据被截断或写坏，可能抛 `TypeError` / `CastError`，不会被 `on FormatException` 捕获，应用启动直接崩溃；
- 用户没有任何备份或恢复入口。

建议：

- 捕获更宽的异常（`catch (_)` 或 `on Object`），解析失败时回退空列表并保留原始数据用于导出；
- 增加坏 JSON、类型错误、非法日期三类数据的回归测试。

### 4.6 P2-03：iOS 小部件默认颜色与索引语义不一致

颜色默认值：

- iOS：`DaymarkWidget.swift:105-109`、`:308-312` 缺省 `ff6750a4`（紫色）；
- 应用默认：`lib/models/app_settings.dart:26` 为 `0xFF0F766E`（青色）；
- 占位预览也是紫色（`DaymarkWidget.swift:82`）。

影响：首次添加小部件或尚未同步时会显示与应用主题不同的颜色。

索引共享：

- iOS 总览小部件使用全局键 `widget_ios_index`（`DaymarkWidget.swift:103`、`:222`）；
- 同一台设备上多个总览小部件会互相改写同一个索引；
- Android 使用 `daymark_widget_index_<widgetId>` 每实例独立（`DaymarkWidgetProvider.kt:78-79`）。

建议：

- iOS 默认色改为与应用一致，或直接从 AppGroup 读取已保存的 `widget_color`；
- iOS 为每个小部件实例保存独立索引（例如按 Timeline/实例 ID 分区）。

### 4.7 P2-04：小部件启动 URI 处理缺少防失控机制

位置：`lib/services/widget_launch_actions.dart:12-25`

- `_handledLaunchUris` 是无上限 Map，每个不同 URI 都会永久保留，长期运行有轻微内存增长；
- 冷启动时若 `appNavigatorKey.currentState` 一直不可用，会每 50ms 无限重试，没有次数上限或超时；
- 若首帧异常，可能形成无界自旋。

建议：

- 对去重表做 LRU/上限裁剪；
- 重试增加最大次数（如 20 次）并在失败时打印日志。

### 4.8 P3 级发现

| 编号 | 位置 | 问题 | 建议 |
| --- | --- | --- | --- |
| P3-01 | `lib/services/notification_service.dart:181-184` | `occurrenceFor` 在列表推导中计算两次，纯性能噪音 | 先算一次再筛选 |
| P3-02 | `lib/ui/event_form_sheet.dart:420-423` | 每次保存带提醒的事件都请求通知权限，即使已授权 | 记录授权状态，仅在未授权时请求 |
| P3-03 | `lib/services/photo_background_service_io.dart:9,20-22,43` | 系统 Picker 先压到 quality 90，应用又压到 82，双重压缩；固定文件名不随设置清理 | 单次压缩；清除背景时同步删除缓存文件 |
| P3-04 | `lib/ui/app_theme.dart:55,59,64` 等 | 多处使用负 `letterSpacing`（`home_page.dart:653,723`、`event_card.dart:430`、`event_detail_page.dart:125`、`settings_page.dart:48`、`glass_ui.dart:445`、`event_form_sheet.dart:115`） | 中文环境下负字距可能裁剪/叠字，建议统一为 0 或做字形验证 |
| P3-05 | `android/app/build.gradle.kts:26` | 模板 TODO 仍残留 | 清理模板注释 |
| P3-06 | `.github/workflows/build-apk.yml` | CI 只构建，不跑 `flutter analyze` / `flutter test` | 增加质量门禁，先修 P1-02 再启用 |
| P3-07 | `lib/services/update_service.dart:125-135` | GitHub API 无鉴权、无 ETag，依赖限流文案兜底 | 评估缓存/条件请求，减少 403/429 |
| P3-08 | `lib/ui/app_theme.dart:178-182` | 深浅色 SnackBar 背景使用同一颜色 | 按主题区分，保持对比度 |

## 5. 测试与验证评估

### 5.1 已通过的隔离测试

按文件分别运行（每用例 30s 超时），以下全部通过：

| 文件 | 结果 |
| --- | --- |
| `widget_test.dart` | 14 项通过 |
| `update_service_test.dart` | 12 项通过 |
| `widget_content_test.dart` | 10 项通过 |
| `visual_style_test.dart` | 22 项通过 |
| `widget_protocol_test.dart` | 通过 |
| `widget_phase1_test.dart` | 通过 |
| `app_controller_test.dart` | 15 项通过 |
| `accessibility_test.dart` | 2 项通过 |
| `ui_components_test.dart` | 26 项通过 |
| `widget_interaction_test.dart` | 8 项通过 |

修复后完整套件使用 `flutter test --concurrency=1` 运行，123 项全部通过；`widget_launch_actions_test.dart` 已恢复绿灯。

### 5.2 覆盖亮点

- 撤销事务：删除/清空/完成/恢复/撤销/最终化；
- 旧数据迁移：`reminderMinutes`、全天、重复、置顶；
- 小部件协议：翻牌、待撤销载荷、同步顺序；
- 无障碍：200% 文字缩放、减少动画；
- 视觉回归：主题色与玻璃导航；
- 更新检测：版本归一化、比较、404 回退、限流、坏数据。

### 5.3 覆盖缺口

- `NotificationService` 的调度/取消/诊断仍无单测；
- iOS Swift 原生代码仍需 macOS 环境构建验证；
- 已新增 Android Kotlin 纯函数单测（39 项）、DST/坏数据/iOS URL host 测试与集成冒烟测试；
- 仍无覆盖“App 修改事件 -> 原生小部件同步 -> 点击小部件回跳”的完整 E2E。

## 6. 安全与隐私评估

### 6.1 隐私

- 数据只写本地 `SharedPreferences`，无账号、无服务端；
- 导出/导入仅走系统剪贴板；
- 照片背景使用系统 Photo Picker，无存储权限；
- 唯一外部网络调用是 GitHub Releases 检查，未携带业务数据；
- 未发现埋点、崩溃上报或第三方统计 SDK。

### 6.2 密钥与敏感文件

- `tools/vision_bridge/.env` 已由 `.gitignore:46` 忽略，`git ls-files` 确认未被跟踪；
- 仓库内未发现提交的 API Key 或签名密钥；
- 主要风险仍是 Release 构建使用 debug keystore（P1-03）。

### 6.3 建议

- Release 前引入正式签名与签名校验；
- 若未来增加备份/云同步，需重新做威胁建模；
- 为剪贴板导入增加大小与嵌套深度限制，防止超大 JSON 拖垮 UI 线程。

## 7. 可维护性与技术债

### 7.1 做得好的部分

- 协议版本化（v6）与旧值回退，前后端（Flutter/原生）解耦清晰；
- 平台差异大多有注释与文档说明（如 MuMu CMake workaround、Glance 版本覆盖）；
- 工具函数集中，重复逻辑少；
- 提交历史按阶段组织，文档与代码同步演进。

### 7.2 技术债

- `DaymarkWidgetProvider.kt` 单文件 1801 行，建议拆分为协议解析、样式渲染、交互调度、位图工厂等模块；
- `widget_preview_section.dart`（43168 字节）与 `settings_page.dart`（41448 字节）体量偏大，可拆文件；
- 依赖版本普遍落后（`flutter_local_notifications` 19.x vs 22.x、`home_widget` 0.8.0 vs 0.9.x、`riverpod` 2.x vs 3.x），升级需要专项迁移；
- `kotlin.incremental=false`、`android.enableJetifier=true` 属于历史配置，可评估关闭/替换。

## 8. 文档评估

### 8.1 现状

- `README.md`：功能、构建、平台说明、权限、FAQ 完整，质量高；
- `docs/`：阶段 0-5 计划、平台调研、更新计划齐备；
- `outputs/release-notes-v2.3.0-phase5.md` 等发布说明按阶段维护。

### 8.2 缺口

- 没有架构总览文档（模块图、数据流、小部件协议字段说明）；
- 没有测试策略/覆盖说明；
- 没有发布检查单（签名、版本号、CI 门禁、回归范围）；
- 本 Review 报告补齐“质量快照”这一环，但建议后续沉淀为持续文档。

## 9. 建议优先级

### 立即可做（下一迭代）

1. 修复 iOS 小部件 URL host（P1-01），统一为 `ying://open` / `ying://add`；
2. 修复测试挂起（P1-02），恢复完整测试套件绿灯；
3. 配置正式 release 签名并更新 CI（P1-03）；
4. 修复 DST 天数计算并补测试（P2-01）；
5. 加强坏数据容错（P2-02）。

### 短期（1-2 个版本内）

6. iOS 小部件默认色与索引语义对齐（P2-03）；
7. 启动 URI 处理加防失控（P2-04）；
8. CI 增加 analyze/test 门禁；
9. 清理 P3 清单中的通知权限、照片双压缩、负字距问题。

### 中长期

10. 原生代码与协议文档化，沉淀小部件协议 v7 说明；
11. 拆分大文件，控制单文件规模；
12. 依赖升级专项；
13. 引入 E2E 回归（模拟器 + 小部件）。

## 10. 附录：审查命令记录

```powershell
cd F:\xm\ying\daymark
flutter analyze
flutter test --timeout 30s test\widget_test.dart test\update_service_test.dart test\widget_content_test.dart test\visual_style_test.dart test\widget_protocol_test.dart test\widget_phase1_test.dart
flutter test --timeout 30s test\app_controller_test.dart
flutter test --timeout 30s test\accessibility_test.dart
flutter test --timeout 30s test\ui_components_test.dart
flutter test --timeout 30s test\widget_interaction_test.dart
flutter test --timeout 30s test\widget_launch_actions_test.dart   # 复现挂起
git ls-files tools\vision_bridge
git check-ignore -v tools\vision_bridge\.env
```
