# 萤 - 倒数日 ✨

<p align="center">
  <img src="app.png" width="180" alt="萤 Logo">
</p>
<p align="center">
  <b>用心记录每一个重要时刻</b><br>
  倒数日 · 正计时 · 桌面小部件 · 云端同步 · 分享卡片
</p>

<p align="center">
  <a href="https://github.com/jiuxina/ying/stargazers">
    <img src="https://img.shields.io/github/stars/jiuxina/ying?style=social" alt="GitHub stars">
  </a>
  <a href="https://github.com/jiuxina/ying/network/members">
    <img src="https://img.shields.io/github/forks/jiuxina/ying?style=social" alt="GitHub forks">
  </a>
  <a href="https://github.com/jiuxina/ying/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/jiuxina/ying" alt="GitHub license">
  </a>
  <a href="https://www.android.com">
    <img src="https://img.shields.io/badge/platform-Android-brightgreen" alt="Platform Android">
  </a>
</p>

## 目录

- [功能特性](#✨-功能特性)
- [安装](#📦-安装)
- [使用说明](#📖-使用说明)
- [权限说明](#📋-权限说明)
- [贡献](#🤝-贡献)
- [开源协议](#📄-开源协议)
- [作者](#👨‍💻-作者)

## ✨ 功能特性

### ⏱️ 倒计时与正计时

- 精确到秒的倒数日/正计时显示
- 支持农历日期（节日、生日等传统日期）
- 智能天数计算，自动识别已过/未到事件
- 多种时间单位显示：天/小时/分钟/秒
- 自定义事件图标与分类管理
- 重复事件支持（年度/月度周期）

### 🎨 个性化定制

- 深色/浅色主题自动跟随系统
- 12+ 种精选主题色彩
- 自定义分类颜色标签
- 事件备注与详细描述
- 星标收藏重要事件
- 灵活的排序方式（时间/创建/自定义）

### 📱 桌面小部件
> 正在开发中

- 多尺寸小部件支持（1x1 / 2x2 / 4x2）
- 实时更新倒计时显示
- 极简设计，一目了然
- 点击直达事件详情
- 自定义小部件主题

### 📅 日历视图

- 月历视图，直观查看所有事件
- 农历日期并排显示
- 快速跳转到指定日期
- 事件密度提示
- 长按日期创建新事件

### 🎁 精美分享卡片

- 5 种专业设计模板（极简/渐变/卡片/节日/海报）
- 3 种比例自由切换（正方形 1:1 / 竖版 3:4 / 横版 16:9）
- **自定义背景图片**，打造独一无二的分享卡片
- 智能裁剪，完美适配各种社交平台
- 可自定义显示内容：标题/天数/日期/备注/底部标识
- 一键保存到相册或分享给好友

### ☁️ 云端同步

- WebDAV 协议，兼容主流网盘（坚果云/Nextcloud 等）
- 智能冲突检测，数据安全可靠
- 多设备无缝同步
- 密码加密存储，隐私有保障
- 手动/自动同步模式

### 🔔 提醒通知
> 正在开发中

- 事件到期推送提醒
- 自定义提醒时间
- 重要事件多次提醒
- Android 14+ 通知权限适配

### 📤 导入导出

- iCalendar (.ics) 文件导入
- 一键导出所有事件
- 批量备份与恢复
- 支持跨平台日历数据迁移

### 🚀 快捷操作

- 3D Touch / 长按应用图标快速创建
- Deep Link 支持，快速跳转
- 手势操作，左滑删除/右滑编辑
- 搜索功能，快速定位事件

## 📦 安装

### 方式一：下载 APK

1. 前往 [Releases](https://github.com/jiuxina/ying/releases) 下载最新 APK
2. 根据设备架构选择：
   - **arm64-v8a** (推荐，适用于大多数现代安卓手机)
   - armeabi-v7a (旧款 32 位设备)
   - x86_64 (模拟器)
3. 安装后授予必要权限
4. 开始记录你的重要时刻～

### 方式二：从源码构建

```bash
# 克隆仓库
git clone https://github.com/jiuxina/ying.git
cd ying

# 安装依赖
flutter pub get

# 构建 APK
flutter build apk --release --split-per-abi

# APK 位于: build/app/outputs/flutter-apk/
```

## 📖 使用说明

### 创建事件

1. 点击首页右下角 `+` 按钮
2. 填写事件标题、日期、分类
3. （可选）添加备注、设置重复、选择图标
4. 保存即可

### 添加桌面小部件
> 正在开发中

1. 长按桌面空白处
2. 选择"小部件"
3. 找到"萤"应用
4. 拖拽到桌面，选择要显示的事件

### 生成分享卡片

1. 打开事件详情
2. 点击右上角分享按钮
3. 选择模板和比例
4. 自定义显示内容
5. （可选）添加自定义背景图片
6. 保存或分享

### 设置云同步

1. 进入设置 → 云端同步
2. 输入 WebDAV 服务器地址
3. 输入用户名和密码
4. 测试连接后保存
5. 选择同步方式（手动/WiFi 下自动）

## 📋 权限说明

| 权限           | 用途                         |
| -------------- | ---------------------------- |
| 存储权限       | 保存分享卡片到相册           |
| 网络权限       | 云端同步功能                 |

## 🤝 贡献

发现 bug、想加新功能、优化体验，或者单纯想打个招呼，都欢迎提交 Issue 或 Pull Request～

### 开发环境

- Flutter SDK: ^3.9.2
- Dart SDK: ^3.9.2

### 主要依赖

- **状态管理**: Provider
- **本地存储**: sqflite, shared_preferences
- **日期处理**: intl, lunar (农历支持)
- **云同步**: webdav_client
- **分享功能**: share_plus, image_cropper

## 📄 开源协议

[MIT License](https://github.com/jiuxina/ying/blob/main/LICENSE)

## 👨‍💻 作者

**jiuxina**  

Made with ❤️ by Me & You

---

<p align="center">
  如果这个项目对你有帮助，请给个 ⭐️ Star 支持一下吧～
</p>
