# Android 定时通知修复说明

## 问题描述

用户反馈在 Android 手机上：
- ✅ "测试通知"按钮能正常发送通知
- ❌ 定时通知不会自动触发
- 需求：无论是否在应用内，都要能收到定时通知

## 根本原因

Android 系统为了节省电量和系统资源，会限制应用的后台活动。定时通知需要在应用关闭或后台运行时也能工作，因此需要：

1. **系统权限**：精确闹钟、唤醒设备、前台服务等权限
2. **电池优化白名单**：防止系统强制关闭应用
3. **自启动权限**：设备重启后能自动恢复通知调度
4. **通知渠道配置**：Android 8.0+ 需要正确配置通知渠道

## 已实施的修复

### 1. 添加必要的 Android 权限

在 `android/app/src/main/AndroidManifest.xml` 中添加：

```xml
<!-- 后台通知权限 - 确保应用关闭后通知仍能工作 -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE"/>
```

**作用**：
- `RECEIVE_BOOT_COMPLETED`：设备重启后自动重新调度通知
- `WAKE_LOCK`：允许应用唤醒设备以发送通知
- `FOREGROUND_SERVICE`：允许应用运行前台服务
- `FOREGROUND_SERVICE_SPECIAL_USE`：Android 14+ 需要的权限

### 2. 在原生代码中创建通知渠道

在 `MainActivity.kt` 中添加了 `createNotificationChannel()` 方法：

```kotlin
private fun createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val channel = NotificationChannel(channelId, channelName, importance).apply {
            description = channelDescription
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 500, 200, 500)
            enableLights(true)
            lightColor = 0xFF2196F3.toInt()
            setShowBadge(true)
        }
        notificationManager.createNotificationChannel(channel)
    }
}
```

**作用**：确保 Android 8.0+ 设备上通知渠道正确配置，通知能正常显示。

### 3. 完善通知调度参数

在 `notification_service.dart` 的 `zonedSchedule` 调用中添加：

```dart
uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
```

**作用**：确保通知在指定的绝对时间触发，而不是相对时间。

### 4. 添加诊断和用户指导功能

新增以下功能：

#### a) 通知状态诊断 API
- `checkNotificationStatus()` - 检查所有权限状态
- `printNotificationDiagnostics()` - 打印诊断信息到控制台

#### b) 通知设置界面
创建了新的设置页面 `NotificationSettingsScreen`，可在"设置 → 通知设置"中访问。

**功能**：
- 实时显示通知权限状态
- 显示待处理通知数量
- 提供详细的配置指南
- 一键请求权限按钮

## 用户配置指南

完成应用更新后，用户需要进行以下配置：

### 步骤 1：检查通知权限

1. 打开应用
2. 进入"设置" → "通知设置"
3. 查看权限状态：
   - ✅ 通知权限
   - ✅ 精确闹钟权限

### 步骤 2：授予必要权限

如果权限未授予，点击"请求通知权限"按钮，或手动前往：

**系统设置 → 应用 → 萤 → 权限**

确保以下权限已开启：
- [x] 通知
- [x] 闹钟和提醒（或"精确闹钟"）

### 步骤 3：关闭电池优化（重要！）

**方法 1（推荐）**：
1. 系统设置 → 应用 → 萤
2. 电池 → 不限制（或"无限制"）

**方法 2**：
1. 系统设置 → 电池
2. 应用耗电管理（或"电池优化"）
3. 找到"萤" → 选择"允许后台活动"或"不优化"

**不同品牌手机路径**：
- **小米 MIUI**：设置 → 应用设置 → 应用管理 → 萤 → 省电策略 → 无限制
- **华为 EMUI**：设置 → 应用 → 应用启动管理 → 萤 → 手动管理（全部开启）
- **OPPO ColorOS**：设置 → 电池 → 应用耗电管理 → 萤 → 允许后台运行
- **vivo OriginOS**：设置 → 电池 → 后台耗电管理 → 萤 → 允许后台高耗电

### 步骤 4：开启自启动（国产手机）

**小米**：
- 设置 → 应用设置 → 应用管理 → 萤 → 自启动 → 允许

**华为**：
- 设置 → 应用 → 应用启动管理 → 萤 → 手动管理 → 开启"允许自启动"

**OPPO**：
- 设置 → 应用管理 → 萤 → 自启动 → 允许

**vivo**：
- i管家 → 应用管理 → 自启动管理 → 萤 → 允许

### 步骤 5：验证配置

1. 在应用中添加一个事件
2. 设置一个提醒（比如 1 分钟后）
3. 关闭应用（完全退出）
4. 等待通知到达

如果收到通知，说明配置成功！✅

## 技术细节

### 通知调度机制

使用 `flutter_local_notifications` 插件的 `zonedSchedule` 方法：

```dart
await _notifications.zonedSchedule(
  notificationId,
  event.title,
  _getReminderMessage(event, reminder),
  tzNotificationDateTime,
  notificationDetails,
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
  payload: event.id,
);
```

**关键参数**：
- `androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle`
  - 即使设备处于 Doze 模式也能准时触发
  - 适合高优先级提醒
- `uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime`
  - 使用绝对时间，不受时区变化影响

### 设备重启处理

应用启动时（`main.dart`）自动重新调度所有通知：

```dart
// 重新调度所有活动事件的提醒（应用启动时恢复）
await notificationService.rescheduleAllReminders(eventsProvider.events);
```

有了 `RECEIVE_BOOT_COMPLETED` 权限后，设备重启时 Flutter Local Notifications 插件会自动恢复通知调度。

### 通知渠道配置

通知渠道 `event_reminders` 配置：
- **重要性**：HIGH（高优先级）
- **振动模式**：0-500-200-500 毫秒
- **LED 灯**：蓝色，1000ms 亮 / 500ms 灭
- **声音**：系统默认通知音
- **横幅显示**：支持

## 已知问题和限制

### 1. 厂商定制系统的限制

部分国产手机厂商（特别是小米、华为、OPPO、vivo）对后台应用有更严格的限制。即使授予了所有权限，系统仍可能：
- 在一段时间后杀死后台应用
- 清理后台任务时清除通知调度

**解决方案**：
- 将应用加入"电池优化白名单"
- 锁定应用在最近任务中（防止清理）
- 开启"自启动"权限

### 2. Doze 模式

Android 6.0+ 引入了 Doze 模式，设备长时间静止时会进入深度休眠。虽然我们使用了 `exactAllowWhileIdle` 模式，但极端情况下通知可能延迟几分钟。

**影响**：低（大多数情况下不受影响）

### 3. 电池优化

某些激进的电池优化策略可能影响通知。建议用户：
- 关闭应用的电池优化
- 不要使用"省电模式"或"超级省电模式"

## 调试方法

### 查看日志

应用启动时会打印详细的诊断信息：

```
═══ 通知状态诊断 ═══
✓ 通知服务初始化: true
✓ 通知权限: true
✓ 精确闹钟权限: true

📋 待处理通知数量: 3
待处理通知列表:
  - ID: 123456, Title: 生日提醒
  - ID: 234567, Title: 纪念日
  - ID: 345678, Title: 重要会议
═══════════════════
```

### 检查待处理通知

在"通知设置"页面可以看到待处理通知的数量。如果数量为 0，说明通知没有被正确调度。

### 使用 adb 调试

```bash
# 查看应用日志
adb logcat | grep -i ying

# 检查通知调度
adb shell dumpsys notification

# 查看精确闹钟
adb shell dumpsys alarm | grep -A 10 com.jiuxina.ying
```

## 更新日志

### v1.0 - 初始修复
- 添加 Android 后台通知权限
- 创建原生通知渠道
- 完善通知调度参数
- 添加诊断工具
- 创建通知设置界面

## 反馈

如果用户在配置后仍然无法收到通知，请提供以下信息：
1. 手机品牌和型号
2. Android 版本
3. 应用日志（特别是通知诊断部分）
4. 已完成的配置步骤
5. 待处理通知数量（在通知设置中查看）

---

**最后更新**：2024-02-14
