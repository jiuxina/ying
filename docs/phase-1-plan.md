# 第 1 阶段详细计划：视觉与壁纸个性化

> 状态：已实现，代码与单元测试验证通过（2026-08-08），对应 [update-plan.md](update-plan.md) 阶段 1。

## 摘要

第 1 阶段在阶段 0 的小部件数据协议与午夜刷新底座上落地视觉个性化：8 套样式预设、壁纸取色、相册背景、材质主题与节日皮肤。小部件协议升级到 v3（向后兼容），旧小部件缺少新字段时继续按卡片样式渲染。

## 关键改动

### 1. 样式预设

- 新增 `WidgetStyle` 枚举（card / sticker / photo / glass / polaroid / neon / pixel / minimal），未知值统一回退 `card`。
- 设置页「小部件样式」区块提供 8 个入口，选择后立即持久化并同步预览与小部件；`lib/ui/widget_style_presets.dart` 集中维护入口元数据。
- Android `DaymarkWidgetProvider` 按样式生成背景位图：卡片主色圆角、贴纸透明、照片图、玻璃半透明白、拍立得白底下沿、霓虹深色描边、像素深色块状边框、极简透明细边框。
- 圆角按小部件实际尺寸收敛：卡片 / 玻璃 / 照片 10dp，霓虹 / 极简 8dp，拍立得 4dp，像素直角，预览与 Android 侧同步。

### 2. 壁纸取色

- `MainActivity` 新增 `ying/wallpaper` MethodChannel，`getWallpaperColors` 优先读取 `WallpaperManager.getWallpaperColors`（API 26+）的主色 / 深色 / 文字对比色，低版本回退到壁纸位图采样。
- `lib/services/wallpaper_color_service.dart` 提供 Dart 侧调用，失败或平台不支持时返回 null，设置页给出提示。
- 文字色按相对亮度选择黑 / 白，贴纸、照片、极简样式优先使用壁纸文字色。

### 3. 相册背景图

- `lib/services/photo_background_service*.dart` 使用系统 Photo Picker 选图，缩放到 1600px 内并 JPEG 压缩后缓存到应用文档目录，路径写入小部件配置。
- `lib/services/background_image_provider*.dart` 为预览提供本地图片加载，Web 平台返回 null。
- Android 侧解码时按 480px 上限降采样并限制为 RGB_565，避免大图进入 RemoteViews binder。

### 4. 节日皮肤

- `lib/models/widget_holiday.dart` 定义新年、圣诞、中秋、生日四种节日；中秋按农历八月十五判定，农历换算复用 `lunar` 包。
- `WidgetService` 每次同步时计算当天节日并写入 `widget_holiday`；Android 侧用 `android.icu.util.ChineseCalendar` 兜底计算，并支持按事件标题 / 分类匹配生日。
- 小部件显示节日徽章与节日强调色（新年红、圣诞绿、中秋橙、生日粉）。

### 5. 协议与版本

- `widget_protocol_version` 升到 3，新增 `widget_holiday` 键；全部新字段读取使用 `opt*` / 默认值回退。
- `pubspec.yaml` 与 `lib/app_version.dart` 统一为 2.1.0。

## 测试计划

- Dart 单测：节日判定（新年、圣诞、中秋农历、生日命中 / 未命中）、对比色辅助函数、协议 v3 字段与节日写入。
- Widget 测试：设置页样式入口选中与持久化、新增「跟随壁纸颜色」开关后的整行开关数量断言、预览与诊断区块回归。
- Android 单测：`WidgetAppearanceTest` 覆盖样式回退、日期节日、生日匹配、`resolveHoliday` 优先级、对比色与颜色辅助函数；`MidnightRefreshSchedulerTest` 保持通过。
- 验证命令：`flutter analyze`、`flutter test`、`gradlew -p android :app:testDebugUnitTest`（MuMu 环境用现有 `-Pmumu-x64` 构建开关验证）。
- 手工验收：MuMu 添加小部件确认各样式与节日皮肤实际生效，应用内预览同步展示；旧小部件缺少新配置时保持卡片样式。

## 假设与注意事项

- 相册优先走系统 Photo Picker，不申请存储权限；图片压缩缓存后路径持久化，避免每次刷新重新解码。
- 壁纸取色在应用侧完成，小部件只读取计算好的颜色值。
- 节日皮肤按本地日期判断；Android 侧农历换算失败时静默回退无节日。
- AppWidget 布局只允许系统白名单内的 View 类型，纯 `<View>` 会被 launcher 拒绝膨胀并提示「无法加载微件」，遮罩统一用 `FrameLayout` 承载。
- 阶段 2-5 的滚动列表、文案、交互与趣味主题不在本阶段实现。
