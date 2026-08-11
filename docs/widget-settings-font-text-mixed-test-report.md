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
