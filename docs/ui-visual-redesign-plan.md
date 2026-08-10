# 萤 UI 视觉改版计划

## 1. 摘要

目标：解决三个核心视觉问题——文字过多、AI 生成感强、文字与图标和背景同色系。

方向：全应用统一改版，采用“克制专业风”。保留玻璃质感与青绿品牌色，但强化黑白灰层级、压缩装饰文案、降低背景同色干扰，让倒计时数字成为首页的视觉中心。

原则：只改视觉与文案，不改功能、数据模型、手势行为与原生小部件协议。图标一律单色，不出现“彩色图标 + 图标背后垫彩色色块”的层级。

## 2. 关键改动

### 2.1 主题与设计令牌

修改 `lib/ui/app_theme.dart` 与 `lib/ui/glass_ui.dart`：

- 浅色主题：
  - 背景 `#F5F4F0`，表面 `#FFFFFF`
  - 主文字 `#1F2328`，次要文字 `#5C636E`，弱文字 `#8A9099`（仅非关键信息）
  - 主色 `#0F766E` 只用于实底主按钮、开关轨道与状态小圆点等少量位置
  - 边框 `outlineVariant` 统一为 55% 透明度
- 深色主题：
  - 背景 `#101318`，表面 `#1A1E24`
  - 主文字 `#F1F3F5`，次要文字 `#A8B0BB`，弱文字 `#7C8590`
  - 主色 `#BEF264`
- 新增语义状态色：
  - 临近（7 天内）：浅色 `#B45309`，深色 `#FBBF24`
  - 已过：浅色 `#DC2626`，深色 `#F87171`
  - 每年重复：浅色 `#4F46E5`，深色 `#818CF8`
  - 已完成：中性灰
- 图标一律单色：默认浅色 `#4B5563`、深色 `#A8B0BB`，选中态使用中性 `onSurface`，不再用品牌色给图标上色；图标容器透明，不垫色块。主色只保留在实底主按钮、开关与状态小圆点；语义色只允许用于倒计时数字状态与删除警示文字，且这些文字一律不垫色块。
- 输入框 label 与前缀图标默认使用次要文字色，聚焦时才变主色。
- `LiquidBackground` 顶角渐变透明度降到 7% 左右，避免背景与内容同色。

### 2.2 首页

修改 `lib/ui/home_page.dart`、`lib/ui/event_card.dart`、`lib/ui/event_filter_bar.dart`：

- Hero 区：“萤”字号降为 `titleLarge`，删除旁边的主色小圆点；副标题改为 `N 个待完成`（无事件时显示“还没有日子”），使用 14px 次要文字色。
- 工具栏：搜索、排序、筛选三个文字按钮改为 40x40 图标按钮，保留 tooltip；有筛选条件时加主色圆点与中性浅底。移除首页分类 chips 行，分类选择并入“筛选”面板。
- 事件卡片：
  - 左侧：`还有/已经/今天` 标签用 11px 弱文字；数字 44px、`w600`，按状态着色：正常主文字色、临近琥珀、已过红、完成中性灰加删除线；数字不使用色块底。
  - 中间：标题 17px `w600` 主文字；第二行精简为 `M月d日 E` 加“全天”小标签；第三行显示分类 chip（浅中性底、深灰字）与“每年”弱标签。
- 右侧：完成按钮未完成时用 `#4B5563` 描边空心圆，完成时用 `onSurface` 实底圆加 `surface` 对勾；更多菜单按钮与滑出动作区图标、文字一律深灰。
- 空态与无结果：标题保留一句，说明压缩到一行，主操作按钮使用主色。

### 2.3 日历页

修改 `lib/ui/calendar_page.dart`：

- 顶部日期副标题使用次要文字色。
- 「今天」按钮与日期副标题同行靠右，仅在选中非今日时显示；月份/年份切换标题居中。
- 月历容器弱化边框与阴影；选中日期用中性实底加 `onSurface` 文字，今天用加粗文字加主色小圆点；有事件的日期显示主色小圆点。
- 当日事件卡文字精简为“标题 + N 天”。

### 2.4 新建/编辑表单

修改 `lib/ui/event_form_sheet.dart` 与 `lib/ui/reminder_editor.dart`：

- 删除“收藏一个值得期待的时刻 / 调整日期、提醒和显示方式”副标题。
- “全天事件”说明精简为“只记日期，提醒按 09:00”。
- “分类标签”改为小标题加分类 chips，不再使用左侧大文字行。
- 快捷日期按钮改为浅中性底加中性描边；输入框边框对比度提高；字段标签默认次要色。

### 2.5 事件详情页

修改 `lib/ui/event_detail_page.dart`：

- 顶部“还有/已经”改为次要文字色。
- 默认值“不提醒 / 不重复”改为“无”。
- 创建时间移到备注下方，使用小号弱文字。
- 日期值允许两行显示但不再溢出：值文字 13.5px，使用 `Flexible` 与 `TextOverflow.ellipsis`。
- 底部保留一个主操作按钮；辅助操作图标使用深灰。

### 2.6 设置页

修改 `lib/ui/settings_page.dart`、`lib/ui/settings_category_page.dart`、`lib/ui/settings_page_widgets.dart`：

- 删除 slogan“让萤更像你。”。
- 分类副标题精简到 8 字以内；设置项副标题逐条压缩到 12 字以内。
- 设置项图标默认深灰，选中态也用中性色；开关轨道保留主色；分割线使用 40% `outlineVariant`。
- 小部件预览卡片沿用新主题令牌。

### 2.7 文案替换清单

| 位置 | 原文 | 新文案 |
| --- | --- | --- |
| 首页副标题 | `$active 个日子，正在靠近` | `$active 个待完成` |
| 首页空态 | `收藏下一个值得期待的时刻` | `还没有日子` |
| 表单副标题 | `收藏一个值得期待的时刻` / `调整日期、提醒和显示方式` | 删除 |
| 设置 slogan | `让萤更像你。` | 删除 |
| 详情默认值 | `不提醒` / `不重复` | `无` |
| 减少透明度 | `使用高对比度不透明表面，减少模糊负担` | `使用实色背景` |
| 减少动画 | `关闭界面过渡，并始终跟随系统减少动态效果` | `关闭过渡动画` |
| 全天说明 | `全天事件只记录日期，提醒以当天 09:00 为基准` | `只记日期，提醒按 09:00` |

### 2.8 图标与颜色层级清理

统一规则：图标只有单色（浅色 `onSurface`/`onSurfaceVariant`，深色主题自动反转）；所有“图标垫底”的色块删除，容器透明；选中态用中性填充、字重与边框表达，不再用品牌色填充。下列位置全部按此规则修改：

- `lib/ui/settings_page_widgets.dart` `_CategoryCard`：删除图标外 40x40 的 `primary 10%` 圆角色块，图标颜色从 `primary` 改为 `onSurfaceVariant`。这是用户点名的“外观与显示”入口。
- `lib/ui/glass_ui.dart` `GlassIconButton`：删除选中态 `primary 10%` 背景与 `primary` 图标，改为透明背景加中性图标。
- `lib/ui/glass_ui.dart` `GlassChoiceTile`：删除选中态 `primary 10%` 背景、`primary 32%` 边框、`primary` 图标与 `primary` 对勾，全部改中性；选中由字重与中性对勾表达。
- `lib/ui/glass_ui.dart` `GlassStatusPill`：改为纯中性文字，无背景、无边框、无状态圆点；状态仅通过文字表达。
- `lib/ui/event_filter_bar.dart` `_FilterButton`：删除选中态整块 `primary` 填充，改为中性填充加 `onSurface` 图标文字；有筛选条件时仅在图标右上角显示 5px 主色圆点。
- `lib/ui/event_filter_bar.dart` `_CategoryChip`：删除选中态 `primary` 填充，改为中性填充、中性文字加粗。
- `lib/ui/event_filter_bar.dart` “清除筛选”文字按钮：前景色从 `primary` 改为中性 `onSurfaceVariant`，其中的图标不再用品牌色。
- `lib/ui/home_page.dart` Hero：删除“萤”字旁的 `primary` 发光小圆点。
- `lib/ui/home_page.dart` `_TabButton`、`_RailButton`：删除选中态 `primary` 图标/文字与 `GlassPalette.blue 14%` 背景，统一 `onSurface` 加粗；选中表达只用字重。
- `lib/ui/home_page.dart` 底部新建按钮与宽屏侧栏新建按钮：不再用 `GlassIconButton(selected: true)`，改为独立圆形实底主按钮（`primary` 底 + `onPrimary` 白色加号），图标保持白色。
- `lib/ui/home_page.dart` `_UpdateBanner`：更新图标从 `primary` 改为 `onSurfaceVariant`。
- `lib/ui/calendar_page.dart` `_ModeButton`：删除选中态 `primary` 整块填充，改中性填充加 `onSurface` 图标文字。
- `lib/ui/calendar_page.dart` `_DayCell`：删除选中态 `primary 14%` 背景与今天 `primary 45%` 边框，选中改中性填充，今天用加粗加主色小圆点。
- `lib/ui/event_form_sheet.dart` `_EmojiPicker`：删除选中圆圈的 `primary 14%` 背景与 `primary 45%` 边框，改中性填充加 `outlineVariant` 边框。
- `lib/ui/event_form_sheet.dart` `_DirectionOption`：删除选中态 `primary 12%` 背景、`primary 34%` 边框与 `primary` 图标/文字，改中性。
- `lib/ui/event_card.dart` 完成按钮：完成态从 `primary` 图标加淡色底改为 `onSurface` 实底圆加 `surface` 对勾。
- `lib/ui/event_card.dart` 卡片菜单 `_CardActionRow`：删除图标从 `error` 改为 `onSurfaceVariant`，红色只保留给“删除”文字。
- `lib/ui/settings_page_widgets.dart` `_StyleOption`：删除选中态 `primary 10%` 背景、`primary 38%` 边框与 `primary` 图标/文字，改中性。
- `lib/ui/app_theme.dart` `chipTheme`：`selectedColor` 从 `primary` 改为中性 `surfaceContainerHighest`，选中标签用 `onSurface`。
- `lib/ui/reminder_diagnostics_section.dart` 与 `lib/ui/widget_preview_section.dart` 的状态行：行首图标保持 `onSurfaceVariant`，右侧 `GlassStatusPill` 随新规则改为纯中性文字。
- `lib/ui/widget_preview_painters.dart` 与预览卡片内的彩色图标：属于小部件样式预览本身，不改；预览区外壳按钮与图标保持中性。

例外保留：实底主按钮/底部新建圆钮内的图标使用 `onPrimary` 白色；颜色选择器 `_ColorButton` 的白色对勾保留（色块本身就是选项值）；滑块、开关等控件轨道保留单一主色。

### 2.9 彩色文字与文字垫底色块清理

统一规则：正文与标签不使用彩色文字，也不放在彩色垫底上；选中态、状态标签全部改中性。语义色只保留两种用途：倒计时数字的状态色（临近琥珀、已过红、完成灰，数字下方不垫色块）与破坏性操作的红字（如“删除”，无底色）。下列位置全部按此规则修改：

- `lib/ui/glass_ui.dart` `GlassStatusPill`：彩色文字 + 彩色底改为纯中性文字，不保留状态圆点（与 2.8 同项）。
- `lib/ui/event_filter_bar.dart` `_FilterButton` 选中态：`onPrimary` 白字 + `primary` 实底改为 `onSurface` 文字 + 中性填充（与 2.8 同项）。
- `lib/ui/event_filter_bar.dart` `_CategoryChip` 选中态：`onPrimary` 白字 + `primary` 实底改为中性文字 + 中性填充（与 2.8 同项）。
- `lib/ui/calendar_page.dart` `_ModeButton` 选中态：`onPrimary` 白字 + `primary` 实底改为中性文字 + 中性填充（与 2.8 同项）。
- `lib/ui/calendar_page.dart` `_DayCell` 选中态：日期文字下的 `primary 14%` 底色改为中性填充（与 2.8 同项）。
- `lib/ui/event_form_sheet.dart` `_DirectionOption` 选中态：`primary` 文字 + `primary 12%` 底色改为中性文字 + 中性填充（与 2.8 同项）。
- `lib/ui/settings_page_widgets.dart` `_StyleOption` 选中态：`primary` 文字 + `primary 10%` 底色改为中性文字 + 中性填充（与 2.8 同项）。
- `lib/ui/app_theme.dart` `chipTheme`：选中标签 `secondaryLabelStyle` 从 `onPrimary` 改为 `onSurface`，`selectedColor` 从 `primary` 改为中性 `surfaceContainerHighest`（与 2.8 同项）。
- `lib/ui/event_detail_page.dart`：顶部状态文字（“还有”）从 `primary` 改为 `onSurfaceVariant`。
- `lib/ui/event_filter_bar.dart` “清除筛选”文字按钮：前景色从 `primary` 改为 `onSurfaceVariant`，文字与图标都不再用品牌色（与 2.8 同项）。
- `lib/ui/home_page.dart` `_TabButton`、`_RailButton`：选中文字从 `primary` / `GlassPalette.blue` 改为 `onSurface`，仅用字重表达选中（与 2.8 同项）。

例外保留：倒计时数字的状态色（临近琥珀、已过红、完成灰）与删除警示红字无底色；`_ColorButton` 的白色对勾；小部件预览卡片内部文字颜色属于样式预览本身，不改。

## 3. 测试与验收

- 同步更新受影响测试：
  - `test/visual_style_test.dart`：背景色与主色断言改为新令牌。
  - `test/ui_components_test.dart`：工具栏断言从文字改为 tooltip，分类选择改到筛选面板。
  - 其他断言被删除文案的用例同步修正。
- 新增回归测试：`GlassIconButton`、`GlassChoiceTile` 选中态无主色背景与主色图标；`GlassStatusPill` 为中性底；`_CategoryCard` 图标无垫底色块。
- 新增回归测试：选中态控件无 `primary` 文字与 `primary` 填充；详情页状态文字为中性色；`GlassStatusPill` 无彩色文字。
- `flutter analyze` 0 issues。
- `flutter test --concurrency=1` 全量通过（当前 123 项）。
- 集成冒烟测试通过；构建 debug APK 安装到运行中的安卓模拟器。
- 手工验收路径：首页空态 → 添加事件 → 筛选/搜索 → 详情 → 完成/恢复 → 设置 → 日历。
- 每屏截图使用 `tools/vision_bridge/vision_bridge.py` 检查：次要文字对比度正常、图标为黑白单色且无垫底色块、工具栏无文字按钮、装饰文案已移除。

## 4. 假设与边界

- 采用推荐默认值：全应用统一改版、克制专业风、工具栏图标化。
- 不修改功能、数据模型、手势与原生小部件协议；原生小部件仅保证预览卡片随主题变化。
- 模拟器里的测试数据（如 `Exam-30D`）不属于 UI 设计问题，本轮不替换。
- 保持“减少透明度 / 减少动画”设置生效，图标化按钮保留 tooltip 与无障碍语义。
- 图标单色规则例外：实底主按钮与底部新建圆钮使用白色图标；颜色选择器保留白色对勾；滑块/开关轨道保留单一主色；状态小圆点保留语义色。
- 彩色文字规则例外：倒计时数字状态色与删除警示红字保留，但均不垫底色块。

## 5. 实施记录（2026-08-09）

- 已按 2.1-2.9 完成全应用视觉改版：主题令牌、玻璃通用控件、首页、事件卡片、筛选工具栏、日历、表单、详情页、设置页与测试同步更新。
- 验证：`flutter analyze` 0 issues；`flutter test --concurrency=1` 133 项全部通过；debug APK 已构建并安装到模拟器。
- 模拟器手工验收：首页空态与事件卡片、表单、详情页、设置页、日历页截图通过视觉桥复核，确认无装饰文案、无彩色图标与垫底色块、工具栏图标化、黑白灰层级成立。
- 追加调整：按用户反馈移除提醒诊断等处状态文字的圆角矩形底与边框，并进一步移除状态小圆点，只保留纯文字。
