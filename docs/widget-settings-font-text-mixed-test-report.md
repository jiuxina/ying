# 萤 · 小部件字体与文字样式混合测试报告

测试日期：2026-08-11
环境：MuMu Android 12（API 32，x86_64），adb 设备 `emulator-5556`，Flutter debug APK（`-Pmumu-x64`）
测试方式：向 debug 包写入组合配置 → 冷启动触发小部件同步 → 截图应用内小号/中号预览与桌面小部件 → 使用 `tools/vision_bridge` 做图像文字描述 → 抓取 logcat 检查异常。

## 一、测试范围

针对用户反馈“字体、文字样式冲突较多”的收敛范围，覆盖：

- 数字字体：系统 / 等宽 / 像素 / 手写，以及缺失字体文件回退。
- 文字字体：系统 / 未知选择回退。
- 全局字号 0.5–2.0 与内容边距 4–40dp 的组合。
- 描边开关、神秘模式、每日一句、精确秒、农历星期、进度、图标、临近高亮、列表模式。
- 逐元素文字样式：标题 / 天数 / 单位 / 备注 / 分类 / 精确时间 / 农历星期 / 进度 / 图标 / 列表行 / 按钮，含显隐、字号档位、100–900 字重、自定义颜色、对齐。
- 字体与整活样式的交叉：复古 CRT、霓虹灯牌、像素血条、神秘信封、镜像整活、极简、时间胶囊。

共 18 个组合场景（`f01`–`f18`），具体配置由
`tool/run_widget_settings_mixed_test.ps1` 中的 `Get-FontTextScenarios` 定义。

## 二、发现的问题

### P1：精确时间元素字重 ≥600 时，整个桌面小部件“无法加载微件”

复现场景：

- `f08-hide-title-days`：精确时间元素 weight=700。
- `f11-hide-everything-near-empty`：精确时间元素 weight=900。

复现现象：

- 应用内小号/中号预览正常，但 Lawnchair 桌面小部件显示“无法加载微件”。
- logcat 固定出现：

```text
AppWidgetHostView: Error inflating RemoteViews
android.widget.RemoteViews$ActionException: view: android.widget.Chronometer
can't use method with RemoteViews: setFontVariationSettings(class java.lang.String)
```

根因：`DaymarkWidgetProvider.kt` 的 `applyBoldApprox` 会对精确时间元素调用
`setFontVariationSettings`，但 `widget_precise` 是 `Chronometer`，RemoteViews
不允许对它执行该方法，抛错后整个小部件加载失败。

修复：`applyBoldApprox` 对 `R.id.widget_precise` 直接跳过该调用，避免远程视图
加载异常；精确时间元素字重继续由应用内预览与渲染协议表达，Android 桌面端保持
系统默认字重。

### P2：Lawnchair 偶发“recycled bitmap”绘制崩溃

`f15-mirror-hand-outline` 首次执行时，logcat 出现一次：

```text
Process: app.lawnchair
java.lang.RuntimeException: Canvas: trying to use a recycled bitmap
```

崩溃发生在 Lawnchair 绘制小部件 ImageView 时，属于启动器侧与 RemoteViews 位图
更新竞争的偶发问题；重启模拟器并复跑同一场景未再复现，小部件最终正常显示。
建议在标准 Launcher/真机继续观察。

### P3：360×640 短屏下标题样式弹层底部溢出 127px

在模拟器 360×640 逻辑分辨率打开“文字样式 → 标题样式”时，弹层底部出现
`BOTTOM OVERFLOWED BY 127 PIXELS` 黄色调试条纹，遮挡“对齐”设置与“重置此元素”按钮。

根因：`showGlassBottomSheet` 在显示拖拽把手时用外层 `Column(mainAxisSize: min)`
包裹弹层内容，弹层内容高于屏幕时外层 Column 没有滚动约束，内部
`SingleChildScrollView` 撑满内容高度后整体溢出。

修复：把拖拽把手后的弹层内容改为 `Flexible(child: child)`，让内部滚动视图获得
剩余可用高度并正常滚动。该修复同时覆盖照片背景编辑等同类长弹层。

### 其他观察

- 紧凑尺寸 + 2.0 全局字号 + 4dp 内容边距时，文字会被省略号截断（应用内预览与
  桌面一致），属于空间受限下的预期行为，不影响加载。
- 缺失字体文件、未知文字字体选择均安全回退系统字体，不抛异常。

## 三、验证结果

- `flutter analyze`：No issues found。
- `flutter test`：193 项全部通过。
- `gradlew :app:testDebugUnitTest`：BUILD SUCCESSFUL。
- 新增回归测试 `chronometerSkipsUnsupportedFontVariation` 通过。
- 修复后重新构建安装 debug APK：
  - `f08` 与 `f11` 复跑 logcat 不再出现 `AppWidgetHostView` / `ActionException`，
    视觉桥描述桌面小部件正常显示，无“无法加载微件”。
  - `f15` 复跑无 FATAL EXCEPTION、无 recycled bitmap 崩溃。
  - 标题样式弹层在 360×640 短屏下无溢出条纹，可滚动到“对齐”与“重置此元素”。
- 18 个场景的应用内预览与桌面小部件截图均已收集。

## 四、证据位置

测试证据保存在工作区（未纳入 Git）：

```text
F:\xm\ying\outputs\widget-font-text-mixed-test\
  prefs\fXX.xml                每个场景注入的配置
  settings\fXX-settings.png    应用内小号/中号预览截图
  settings\fXX-settings.xml    预览页 UI 层级
  home\fXX-home.png            桌面小部件截图
  home\fXX-home.xml            桌面 UI 层级
  logs\fXX-errors.txt          场景异常过滤
  logs\fXX-repro-logcat.txt    问题复现完整日志
  logs\fXX-fixed-logcat.txt    修复后验证日志
```

## 五、复测步骤

1. 构建并安装 debug 包：

   ```powershell
   flutter build apk --debug -Pmumu-x64 --target-platform android-x64
   adb install -r build\app\outputs\flutter-apk\app-debug.apk
   ```

2. 运行字体/文字样式矩阵（会覆盖应用数据，仅用于测试）：

   ```powershell
   pwsh -NoProfile -File tool\run_widget_settings_mixed_test.ps1 `
     -Serial emulator-5556 -FontTextOnly -SkipInstall
   ```

3. 手工复测精确时间字重：
   - 设置 → 桌面小部件 → 文字样式 → 精确时间样式 → 字重选择 700 或 900。
   - 返回桌面确认小部件仍正常显示，不出现“无法加载微件”。

## 六、2026-08-11 补充：防抖、滑块精细度与逐元素混合测试

### 设置项防抖

- `_SliderSetting` 改为有状态组件：滑动过程中用 150ms `Timer` 合并连续
  `onChanged`，松手（`onChangeEnd`）时立即落盘，避免拖动滑块时高频执行
  `updateSettings` 造成的 SharedPreferences 写入与小部件同步压力。
- 已启用防抖的滑块：元素字号/大小、元素粗细、全局字号、内容边距。照片背景
  编辑里的亮度/高斯模糊仍即时更新本地预览，仅在保存时统一写入。

### 滑块精细度与上限

| 设置项 | 原范围/步进 | 新范围/步进 |
| --- | --- | --- |
| 元素字号/大小 | 0.5–2.0，30 档（5%） | 0.5–1.75，50 档（2.5%） |
| 元素粗细 | 0–900，9 档（100） | 0–800，16 档（50） |
| 全局字号 | 0.5–2.0，30 档（5%） | 0.5–1.75，50 档（2.5%） |
| 内容边距 | 4–40dp，18 档（2dp） | 4–32dp，56 档（0.5dp） |
| 照片亮度 | 0.5–1.6，11 档（10%） | 0.5–1.5，20 档（5%） |
| 高斯模糊 | 0–24，24 档（1） | 0–20，40 档（0.5） |

百分比与 dp 标签在非整数值时显示一位小数（如 `122.5%`、`16.5 dp`）。

### 逐元素全设置项混合测试

`tool/run_widget_settings_mixed_test.ps1` 新增 `-EveryElement` 模式，共 19 个
场景（`e01`–`e19`）：

- `e01`–`e16`：分类、节日徽章、标题、天数、单位、备注、精确时间、农历星期、
  进度、图标、列表标题、列表行标题/副标题/天数/单位、空状态，每个元素单独
  改变显隐、颜色（自定义色）、大小/字号、字重（仅文字元素）、对齐。
- `e17`/`e18`：上一个/下一个按钮显隐。
- `e19`：全部元素同时改变 + 列表模式 + 全局字号 1.5 + 内容边距 4dp。

非文字元素（节日徽章、进度、图标、空状态）不设置字重，“字号”改称“大小”。

### 发现并修复的问题

#### P1：设置页预览在极端字号组合下溢出

`e19-all-combined`（全局字号 1.5 + 元素大小 1.6 + 边距 4dp）复现：

- 小号单事件预览 `BOTTOM OVERFLOWED BY 36 PIXELS`。
- 中号列表预览每行 `BOTTOM OVERFLOWED BY 52–55 PIXELS`。
- `e11`/`e16` 等列表场景单行溢出 2.8–4.8px。

根因：`widget_preview_section.dart` 的预览使用固定高度容器，字号放大后内容
总高超过容器；列表行等高均分后同样放不下放大内容。

修复：单事件预览内容放入 `FittedBox(fit: BoxFit.scaleDown)` 等比缩放进固定
预览框；列表行同样缩放；天数/单位文字改为 `Flexible` + 单行省略号，避免
横向溢出。修复后复跑 `e11`/`e14`/`e16`/`e19`，视觉桥确认无 `BOTTOM
OVERFLOWED`，列表标题、行标题、天数、单位颜色与大小均正确渲染。

新增回归测试“极端字号与逐元素样式组合预览不溢出”，覆盖单事件与列表两种
预览。

#### 观察：Lawnchair 启动器偶发崩溃弹窗

完整矩阵执行中 `e05`–`e10` 的桌面截图曾被“Lawnchair 屡次停止运行”系统弹窗
遮挡，logcat 仅见 `FATAL EXCEPTION: main`。与上一轮 `P2 recycled bitmap`
启动器侧问题同类；单独复跑 `e03`、`e05`–`e10` 均无异常，桌面小部件正常
显示，非应用渲染缺陷。

### 验证结果

- `flutter analyze`：No issues found。
- `flutter test`：204 项全部通过（含新增防抖、滑块步进/上限、预览溢出回归）。
- `gradlew :app:testDebugUnitTest`：BUILD SUCCESSFUL。
- debug APK 已重新构建并安装到 `emulator-5556`（MuMu Android 12 / x86_64）。
- 19 个逐元素场景的桌面小部件截图与设置页预览截图均已收集：
  `F:\xm\ying\outputs\widget-every-element-mixed-test\`。
