# 萤 · 买断制商业化改造方案

> 已废弃：本方案已被 [sponsor-unlock-plan.md](sponsor-unlock-plan.md) 取代。
> 最终采用"核心功能免费 + 赞助制解锁 + 爱发电 / 卡密 + 不走应用商店"的模式，此文档仅作历史记录保留。

> 目标：基础功能免费使用，专业版通过一次性买断解锁；不引入订阅、不强制注册账号，并保留"本地优先"的产品定位。

## 1. 现状结论

- 当前版本完全免费，代码中没有任何订阅、会员、支付或购买记录逻辑。
- App 是 Flutter 多端工程（`lib/`），Android 桌面小部件为原生 AppWidget（`android/app/src/main/kotlin/com/jiuxina/ying/`），iOS 为 WidgetKit（`ios/DaymarkWidget/`）。
- 数据与设置全部存在本地 `SharedPreferences`，无服务端、无账号体系。
- 项目当前为 MIT 开源，GitHub 公开源码。这是本方案最大的前提风险：懂技术的用户可以直接编译源码获得全功能，无法从技术上彻底防住。

## 2. 商业模式定义

### 2.1 核心原则

- 倒数日核心能力必须保持免费可用，否则没有用户留存基础。
- 专业版是"永久权益"，一次购买、换机/重装后可通过商店恢复购买。
- 免费版通过"刚好不够用"的额度与个性化限制引导升级，而不是直接砍掉核心功能。

### 2.2 推荐功能分层（示例，最终由你确认）

| 能力 | 免费版 | 专业版（买断） |
| --- | --- | --- |
| 事件数量 | 最多 10 个 | 不限 |
| 事件创建 / 编辑 / 删除 / 搜索 / 分类 | 可用 | 可用 |
| 倒计时 / 正计时 / 日历总览 | 可用 | 可用 |
| 每事件提醒 | 最多 1 条 | 最多 5 条 |
| 桌面小部件 | 总览 1 个实例，基础卡片样式 | 全部实例模式与 14 套样式 |
| 小部件个性化 | 仅颜色 | 自定义颜色 / 字号 / 字段 / Emoji / 单位 / 精确到秒 / 农历星期 / 进度环 / 神秘模式 / 每日一句 / 临近高亮 / 数字字体 / 文字描边 |
| 相册背景 / 壁纸取色 / 节日皮肤 | 不支持 | 支持 |
| 主题 | 深色 / 浅色 / 跟随系统 | 全部 |
| 未来高级功能 | 不包含 | 统一纳入专业版权益 |

### 2.3 定价建议

- 建议买断价 ¥25 左右，首发优惠期 ¥15–¥18。
- 不要做"限时订阅式买断"或模糊文案，商店审核和用户信任都要求页面明确写"一次购买，永久使用"。

### 2.4 老用户策略

- 在收费版本发布前安装过 2.x 的用户建议直接赠送专业版（发布版本写入 `legacy_entitlement` 标记，并随更新保留）。
- 如果做不到精确识别老用户，可做发布窗口期的"感谢升级"：更新到收费版本后 30 天内原价用户免费领取专业版。
- 老用户补偿直接影响评分，建议优先做。

## 3. 渠道与合规

- **Google Play**：数字内容必须走 Play Billing。新增一个非消耗型商品（non-consumable IAP），例如 `premium_unlock`。不能用微信 / 支付宝收款，否则违反商店政策。
- **iOS App Store**：新增非消耗型内购商品，必须实现"恢复购买"（Restore Purchases），否则无法过审。
- **中国大陆商店**（华为 / 小米 / OPPO / vivo）：每家有自己的 IAP SDK，需逐个接入；如果不打算铺所有渠道，第一版可只上 Google Play / 单一国内渠道。
- **直发 APK / 官网分发**：没有商店支付环境，只能自建兑换码或授权服务，工程量明显增加，不建议第一版做。
- **开源协议**：MIT 允许商业化，但源码公开意味着付费墙可被绕过。可选路径：
  1. 继续开源，接受"懂技术的人能自编译"（成本最低，推荐先做）；
  2. 改为 source-available 许可（如 BSL / PolyForm / 自定义许可），付费代码与完整实现不公开；
  3. 增加服务端收据校验（与本地优先、无账号定位冲突，谨慎评估）。

## 4. 技术方案

### 4.1 新增模块

```text
lib/
  models/entitlement.dart                 # 权益模型：unlocked、购买时间、订单号、来源
  services/entitlement_store.dart         # 抽象：load / purchase / restore / listen
  services/entitlement_store_io.dart      # Android+iOS：in_app_purchase 实现
  services/entitlement_store_stub.dart    # 桌面/调试：直接解锁或不可用
  state/entitlement_controller.dart       # Riverpod StateNotifier，启动加载并广播状态
  ui/premium_page.dart                    # 专业版介绍与购买页
  ui/premium_gate.dart                    # 统一付费墙组件
  ui/premium_badge.dart                   # 专业版徽标
```

- 依赖新增 `in_app_purchase`（Flutter 官方插件，兼容 Play Billing 与 StoreKit 2）。
- `main.dart` 启动时加载权益状态；购买回调实时更新 Riverpod 状态。

### 4.2 持久化与恢复

- `StorageService` 新增键：`premium_unlocked`、`premium_purchased_at`、`premium_order_id`、`legacy_entitlement`。
- 本地标记只用于快速读取；换机 / 重装后必须通过商店的"恢复购买"重新确认，避免只靠本地备份伪造。
- 小部件同步新增 `widget_premium_unlocked` 字段，随 `WidgetService.sync` 写入，供原生小部件读取。

### 4.3 功能墙接入点

- `lib/ui/settings_page.dart`：分类菜单顶部新增"专业版"卡片，展示当前状态与升级入口。
- `lib/ui/settings_category_page.dart`：小部件样式、相册背景、壁纸取色、进度环、神秘模式等专业项加锁；未解锁时点击弹出购买页。
- `lib/ui/event_form_sheet.dart`：提醒条数限制（免费 1 条，专业 5 条）。
- `lib/state/app_controller.dart`：`saveEvent` 增加事件数量上限校验。这是数据层强约束，不能只做 UI 隐藏。
- `lib/services/widget_service.dart`：写入专业版标记，并在未解锁时把样式参数降级为基础值。
- Android：`DaymarkWidgetProvider.kt`、`DaymarkDetailWidgetProvider.kt` 读取 `widget_premium_unlocked`，未解锁强制回退基础卡片样式。
- iOS：`DaymarkWidget.swift` 读取 App Group 中的同一标记，未解锁时隐藏专业样式与模式。

### 4.4 购买流程

1. 初始化 `in_app_purchase`，查询商品并显示当前商店价格。
2. 点击购买发起 `buyNonConsumable`。
3. 监听 `PurchaseUpdated`，校验商品 ID 与状态后写入本地权益并刷新 UI。
4. 处理取消、重复购买、Pending 状态与恢复购买。
5. 免费额度超限时只禁止新增，绝不删除已有数据；提示"升级后继续创建"。

## 5. 防绕过与安全

- 第一版采用"商店收据 + 本地权益 + 恢复购买"，可以拦住普通用户，防不住逆向 / 自编译，这是开源项目的客观边界。
- 发布构建启用 Flutter 混淆（`--obfuscate --split-debug-info`）与 Android R8，提高逆向成本。
- 不要在客户端隐藏"万能开关"，很容易被反编译发现。
- 如果后续收入受影响，再评估 Play Integrity API、App Store Server API 或轻量服务端校验。

## 6. 实施步骤

### Phase 0：产品决策（1–2 天）

1. 确认免费 / 专业功能分层表。
2. 确认价格、首发优惠、老用户补偿。
3. 确认第一版发行渠道（Google Play / 国内商店 / 双端）。

### Phase 1：付费底座（2–3 天）

1. `pubspec.yaml` 增加 `in_app_purchase`。
2. 实现权益模型、存储、控制器与平台实现。
3. 实现专业版购买页、设置入口、恢复购买。
4. 补充 Dart 单元测试与购买页 Widget 测试。

### Phase 2：功能墙（2–3 天）

1. 事件数量与提醒条数限制（数据层 + UI）。
2. 小部件样式与个性化项加锁。
3. `WidgetService` 同步专业版标记，Android / iOS 原生小部件降级。
4. 小部件相关测试与回归。

### Phase 3：商店与发布（3–5 天）

1. Google Play Console 创建 `premium_unlock` 商品、定价、许可测试账号。
2. App Store Connect 创建非消耗型商品、沙盒测试账号。
3. 商店标题、描述、截图补充"专业版"说明。
4. 模拟器 / 真机回归（购买、恢复、取消、重装、小部件降级），提交审核。

### Phase 4：上线后（1–2 天）

1. 老用户补偿策略落地并验证。
2. 收集恢复购买异常与差评，快速修复。

## 7. 测试与验收要点

- Dart 单元测试：权益序列化、免费额度限制、恢复购买状态机。
- Flutter Widget 测试：购买页各状态、加锁项点击行为、设置页专业版入口。
- Android 原生测试：未解锁时小部件样式回退。
- 模拟器验证：Play 结算测试账号购买 / 取消 / 恢复，`adb install` 后检查小部件。
- iOS 验证：Sandbox 购买 / 恢复购买 / WidgetKit 降级。
- 发布前跑完整 `flutter test` 与现有 Android 单测，确保不破坏现功能。

## 8. 风险与对策

| 风险 | 影响 | 对策 |
| --- | --- | --- |
| 开源源码可自编译绕过 | 收入损失 | 第一版接受；后续改许可或服务端校验 |
| 国内商店 IAP SDK 分散 | 接入成本高 | 第一版只上单渠道，验证模式后再铺开 |
| 老用户不满 | 差评、卸载 | 老用户补偿 + 发布前公告 |
| 免费版转化率低 | 收入低于预期 | 用事件数量 / 提醒条数做"刚好不够用"的引导 |
| 商店审核 | 发版延迟 | 文案明确"一次买断"，实现恢复购买，提供测试账号说明 |

## 9. 依赖与工作量

- 需要准备：Google Play 开发者账号、App Store 开发者账号、商店商品与税务信息。
- 预估工作量：方案确认后约 1.5–2 周（含商店配置与审核等待，审核时长不可控）。
