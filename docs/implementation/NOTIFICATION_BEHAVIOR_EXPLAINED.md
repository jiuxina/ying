# 通知行为说明 (Notification Behavior Explained)

## 概述 (Overview)

本文档详细说明定时通知的工作原理，以及为什么通知触发时没有日志记录。

This document explains how scheduled notifications work and why there are no logs when notifications fire.

---

## 通知生命周期 (Notification Lifecycle)

### 1. 调度阶段 (Scheduling Phase) ✅ 有日志

**发生时机**: 当你创建或编辑事件并保存时

**代码位置**: `NotificationService.scheduleEventReminders()` (lib/services/notification_service.dart:214-273)

**系统行为**:
- Flutter 应用调用 `flutter_local_notifications` 插件
- 插件通过 Android AlarmManager API 向操作系统注册定时任务
- 操作系统将通知添加到系统队列

**日志记录** (你会看到这些日志):
```
[14:23:08] [INFO] [Notification] Scheduled 1 reminders for event: qwq
[14:23:08] [INFO] [Notification] Notification queue verified: 1 notifications in system queue
```

**关键点**:
- ✅ Dart 代码正在运行
- ✅ 可以记录日志到 DebugService
- ✅ 通知队列验证会确认通知已成功添加到系统

---

### 2. 触发阶段 (Firing Phase) ❌ **没有日志**

**发生时机**: 到达预定的通知时间

**系统行为**:
- **操作系统** (Android/iOS) 根据之前注册的定时任务触发通知
- 通知直接由系统显示，**不启动应用**
- **没有 Dart 代码运行**

**为什么没有日志?**

这是 **Android/iOS 操作系统的设计限制**，不是应用的 bug:

1. **省电考虑**: 如果每次通知都要启动应用来记录日志，会严重消耗电池
2. **性能考虑**: 系统需要能快速显示通知，不能等待应用启动
3. **安全考虑**: 通知需要在应用未运行时也能工作（比如应用被杀掉的情况）

**技术原因**:
- `flutter_local_notifications` 使用 Android 的 `AlarmManager.setExactAndAllowWhileIdle()`
- 这个 API **没有回调机制**告诉应用"通知已触发"
- 通知直接由 Android 系统的 `NotificationManager` 显示
- Dart VM 不会启动，所以无法执行任何 Dart 代码（包括日志记录）

**类比理解**:
就像你设置手机闹钟，闹钟响时不会打开闹钟应用，而是直接由系统显示通知界面。

---

### 3. 用户交互阶段 (User Interaction Phase) ✅ 有日志

**发生时机**: 用户点击通知

**代码位置**: `NotificationService._onNotificationTapped()` (lib/services/notification_service.dart:120-134)

**系统行为**:
- 用户点击通知
- Android 启动应用（如果未运行）
- `flutter_local_notifications` 调用 `onDidReceiveNotificationResponse` 回调
- 应用导航到事件详情页

**日志记录** (你会看到这些日志):
```
[14:25:30] [INFO] [Notification] Notification tapped: event_id_12345
```

**关键点**:
- ✅ Dart 代码正在运行
- ✅ 可以记录日志

---

## 如何验证通知是否正常工作?

### 方法1: 通知队列验证 (推荐)

设置通知后，查看日志中的验证信息:

```
✅ 成功:
[14:23:08] [INFO] [Notification] Notification queue verified: 1 notifications in system queue

❌ 失败:
[14:23:08] [WARN] [Notification] Notification queue verification failed: expected 1, found 0
```

如果看到 "Notification queue verified"，说明通知**已成功添加到 Android 系统队列**，到时间后系统一定会触发（除非被省电策略杀掉）。

---

### 方法2: 查询系统队列

在调试控制台 (Debug Console) 中，可以看到当前所有待处理的通知:

1. 进入 设置 → 调试设置 → 调试控制台
2. 点击 "系统" 标签页
3. 查看 "待处理通知数量"

---

### 方法3: 设置短时间通知测试

最可靠的验证方法:

1. 创建测试事件，目标日期设为明天
2. 添加提醒: 提前 0 天，时间设为 **当前时间 + 2 分钟**
3. 保存后，检查日志确认队列验证成功
4. **等待 2 分钟**
5. 观察通知是否弹出

---

## 测试通知的特殊性

### "发送测试通知" 功能

**代码位置**: `NotificationService.sendTestNotification()` (lib/services/notification_service.dart:482-550)

**行为**:
- 使用 `_notifications.show()` **立即显示**通知
- 不经过系统定时任务
- 直接由系统的 NotificationManager 显示

**日志记录**:
```
[14:30:15] [INFO] [Notification] Test notification sent: 测试事件 (ID: 2000123456)
```

**为什么测试通知也没有"显示"日志?**
- 因为 `.show()` 方法是同步的，调用后立即返回
- Android 系统会异步显示通知，没有回调告诉应用"已显示"
- 但我们可以在**调用后**记录日志，表示"已请求系统显示"

---

## 常见问题排查

### Q1: 我看到了调度日志和队列验证成功，但到时间没有通知

**可能原因**:

1. **省电模式或后台限制** (最常见)
   - 某些手机厂商（小米、华为、OPPO、vivo）会杀掉后台应用的定时任务
   - **解决方法**:
     - 在系统设置中关闭省电优化（针对本应用）
     - 允许后台自启动
     - 锁定到后台任务列表

2. **权限问题**
   - Android 13+ 需要通知权限
   - Android 12+ 需要精确闹钟权限
   - **验证方法**: 查看日志中的权限状态

3. **系统杀掉了通知队列**
   - 重启手机后，通知队列会被清空（除非应用实现了 BOOT_COMPLETED 监听）
   - **解决方法**: 应用会在启动时自动重新调度所有通知

4. **时区问题**
   - 如果手机时区与应用预期不符
   - **验证方法**: 检查调度日志中的 ISO 时间戳是否正确

---

### Q2: 队列验证显示 "expected 1, found 0"

**原因**: 通知未能添加到系统队列

**排查步骤**:

1. 检查权限日志:
   ```
   [INFO] [Notification] Notification permission granted: true
   [INFO] [Notification] Exact alarm permission granted: true
   ```

2. 检查调度日志是否有错误:
   ```
   [ERROR] [Notification] Failed to schedule reminder: ...
   ```

3. 检查通知时间是否已过期:
   ```
   ⏭ 提醒时间已过，跳过: 事件名称 - 2026-02-14T10:00:00.000+08:00
   ```

---

### Q3: 测试通知能收到，定时通知收不到

**可能原因**:

- 测试通知使用 `.show()` 立即显示，不依赖后台定时任务
- 定时通知需要应用保持后台权限
- **解决方法**: 检查省电设置和后台权限

---

## 代码改进说明 (本次修复)

本次更新添加了以下功能来帮助诊断通知问题:

### 1. 测试通知日志增强
```dart
// 新增: 发送测试通知时记录日志
_debugService.info(
  'Test notification sent: $eventTitle (ID: $testNotificationId)',
  source: 'Notification',
);
```

### 2. 通知队列自动验证
```dart
// 新增: 调度后自动验证系统队列
final actualCount = await getEventNotificationCount(event.id);
if (actualCount != successCount) {
  _debugService.warning(
    'Notification queue verification failed: expected $successCount, found $actualCount',
    source: 'Notification',
  );
} else {
  _debugService.info(
    'Notification queue verified: $actualCount notifications in system queue',
    source: 'Notification',
  );
}
```

**好处**:
- ✅ 立即发现通知未成功调度的问题
- ✅ 区分"调度失败"和"系统杀掉"两种情况
- ✅ 提供明确的诊断信息

---

## 总结

| 阶段 | Dart 代码运行? | 可以记录日志? | 用户能看到什么? |
|------|--------------|-------------|---------------|
| 调度通知 | ✅ 是 | ✅ 是 | 调试控制台中的日志 |
| 通知触发 | ❌ 否 | ❌ 否 | 通知弹出在屏幕上 |
| 点击通知 | ✅ 是 | ✅ 是 | 应用打开 + 日志 |

**关键理解**:
- 通知触发时**没有日志是正常的**，这不是 bug
- 通过**队列验证日志**可以确认通知是否成功调度
- 如果队列验证成功但到时间没有通知，问题在于**系统省电策略**，不是应用代码

---

## 参考资料

- [Android AlarmManager Documentation](https://developer.android.com/reference/android/app/AlarmManager)
- [flutter_local_notifications Plugin](https://pub.dev/packages/flutter_local_notifications)
- [Android Doze Mode 说明](https://developer.android.com/training/monitoring-device-state/doze-standby)

---

**最后更新**: 2026-02-15
**版本**: 1.0
**相关 PR**: #19 (Debug logging enhancements)
