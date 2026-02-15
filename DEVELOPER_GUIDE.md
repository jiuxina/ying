# Android 本地通知实现 - 开发者技术文档

## 架构概述

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Layer                         │
├─────────────────────────────────────────────────────────┤
│  NotificationService (notification_service.dart)         │
│  - checkBatteryOptimization()                           │
│  - requestBatteryOptimization()                         │
│  - checkBootRestoreNeeded()                             │
│  - clearBootRestoreFlag()                               │
└──────────────────┬──────────────────────────────────────┘
                   │ MethodChannel
                   │ 'com.jiuxina.ying/notifications'
                   ▼
┌─────────────────────────────────────────────────────────┐
│                   Android Layer                          │
├─────────────────────────────────────────────────────────┤
│  MainActivity (MainActivity.kt)                          │
│  - checkBatteryOptimization                             │
│  - requestBatteryOptimization                           │
│  - openBatterySettings                                  │
│  - checkBootRestoreNeeded                               │
│  - clearBootRestoreFlag                                 │
└─────────────────────────────────────────────────────────┘
                   ▲
                   │ BroadcastReceiver
                   │
┌─────────────────────────────────────────────────────────┐
│  BootReceiver (BootReceiver.kt)                         │
│  - Listens to BOOT_COMPLETED                            │
│  - Sets restore flag in SharedPreferences               │
└─────────────────────────────────────────────────────────┘
```

## 实现细节

### 1. 电池优化豁免

#### Android 原生实现

**检查电池优化状态**
```kotlin
private fun isIgnoringBatteryOptimizations(): Boolean {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }
    return true // Android 6.0 以下不需要
}
```

**请求电池优化豁免**
```kotlin
private fun requestIgnoreBatteryOptimizations(): Boolean {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        if (!isIgnoringBatteryOptimizations()) {
            try {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
                return true
            } catch (e: Exception) {
                // 降级方案：打开电池优化设置列表
                openBatteryOptimizationSettings()
                return false
            }
        }
    }
    return true
}
```

#### Flutter 调用

```dart
// 检查状态
final isIgnoring = await _notificationChannel.invokeMethod<bool>('checkBatteryOptimization');

// 请求豁免
final requested = await _notificationChannel.invokeMethod<bool>('requestBatteryOptimization');

// 打开设置
await _notificationChannel.invokeMethod('openBatterySettings');
```

### 2. 开机广播接收

#### BootReceiver 实现

```kotlin
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "系统开机完成，准备恢复通知调度")
            
            try {
                // 设置恢复标记
                val prefs = context.getSharedPreferences(
                    "FlutterSharedPreferences", 
                    Context.MODE_PRIVATE
                )
                prefs.edit()
                    .putBoolean("flutter.needs_notification_restore", true)
                    .apply()
                
                Log.d(TAG, "已设置通知恢复标记")
            } catch (e: Exception) {
                Log.e(TAG, "设置通知恢复标记失败", e)
            }
        }
    }
}
```

#### AndroidManifest 注册

```xml
<receiver
    android:name=".BootReceiver"
    android:enabled="true"
    android:exported="true"
    android:directBootAware="false">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
        <category android:name="android.intent.category.DEFAULT" />
    </intent-filter>
</receiver>
```

#### Flutter 恢复逻辑

```dart
// main.dart 中的恢复逻辑
final needsBootRestore = await notificationService.checkBootRestoreNeeded();
if (needsBootRestore) {
    debugPrint('检测到系统重启，正在恢复通知调度...');
    
    // 恢复所有通知
    await notificationService.rescheduleAllReminders(eventsProvider.events);
    
    // 清除标记
    await notificationService.clearBootRestoreFlag();
    
    debugPrint('✓ 通知调度已恢复');
}
```

### 3. SharedPreferences 通信

#### 为什么使用 SharedPreferences？

1. **跨进程通信** - BootReceiver 和 Flutter 应用在不同进程
2. **持久化存储** - 重启后数据仍然存在
3. **简单可靠** - 不需要复杂的 IPC 机制

#### 数据流

```
系统开机
  ↓
BootReceiver.onReceive()
  ↓
写入 SharedPreferences
  key: "flutter.needs_notification_restore"
  value: true
  ↓
用户打开应用
  ↓
Flutter main.dart
  ↓
checkBootRestoreNeeded()
  ↓
读取 SharedPreferences
  ↓
rescheduleAllReminders()
  ↓
clearBootRestoreFlag()
  ↓
写入 SharedPreferences
  key: "flutter.needs_notification_restore"
  value: false
```

### 4. MethodChannel 通信

#### 定义 Channel

**Flutter 端**
```dart
static const MethodChannel _notificationChannel =
    MethodChannel('com.jiuxina.ying/notifications');
```

**Android 端**
```kotlin
private val NOTIFICATION_CHANNEL = "com.jiuxina.ying/notifications"

MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
    .setMethodCallHandler { call, result ->
        when (call.method) {
            "checkBatteryOptimization" -> { /* ... */ }
            "requestBatteryOptimization" -> { /* ... */ }
            "openBatterySettings" -> { /* ... */ }
            "checkBootRestoreNeeded" -> { /* ... */ }
            "clearBootRestoreFlag" -> { /* ... */ }
            else -> result.notImplemented()
        }
    }
```

#### 调用示例

```dart
// Flutter 调用 Android 方法
try {
    final result = await _notificationChannel.invokeMethod<bool>('checkBatteryOptimization');
    return result ?? false;
} catch (e) {
    debugPrint('检查电池优化状态失败: $e');
    return false;
}
```

### 5. 权限声明

#### AndroidManifest.xml

```xml
<!-- 电池优化豁免权限 -->
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>

<!-- 开机广播权限 -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<!-- 唤醒锁权限 -->
<uses-permission android:name="android.permission.WAKE_LOCK"/>

<!-- 前台服务权限 -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE"/>

<!-- 通知权限 (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- 精确闹钟权限 -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```

## 最佳实践

### 1. 错误处理

**始终使用 try-catch**
```dart
Future<bool> checkBatteryOptimization() async {
    try {
        final isIgnoring = await _notificationChannel
            .invokeMethod<bool>('checkBatteryOptimization');
        return isIgnoring ?? false;
    } catch (e) {
        debugPrint('检查电池优化状态失败: $e');
        return false; // 降级处理
    }
}
```

### 2. 版本兼容

**检查 Android 版本**
```kotlin
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
    // Android 6.0+ 才需要电池优化豁免
}
```

### 3. 用户体验

**提供多种方式**
```kotlin
// 方式1: 直接请求
val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
intent.data = Uri.parse("package:$packageName")
startActivity(intent)

// 方式2: 打开设置列表（降级方案）
val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
startActivity(intent)

// 方式3: 应用详情页（最后备选）
val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
intent.data = Uri.parse("package:$packageName")
startActivity(intent)
```

### 4. 日志记录

**集成 DebugService**
```dart
_debugService.info(
    'Battery optimization exemption requested',
    source: 'Notification',
);
```

## 测试指南

### 单元测试

**模拟 MethodChannel 调用**
```dart
// TODO: 添加单元测试
testWidgets('checkBatteryOptimization returns correct value', (tester) async {
    // Mock MethodChannel
    // Call checkBatteryOptimization
    // Verify result
});
```

### 集成测试

**测试开机恢复**
```
1. 创建测试通知
2. adb shell reboot (重启设备)
3. 打开应用
4. 验证通知已恢复
```

**测试电池优化**
```
1. 清除电池优化豁免
   adb shell dumpsys deviceidle whitelist -<package>
2. 打开应用
3. 点击请求按钮
4. 验证系统设置页面打开
5. 授予豁免
6. 返回应用，刷新状态
7. 验证状态更新
```

## 性能考虑

### 1. MethodChannel 调用开销

- 每次调用都涉及序列化/反序列化
- 避免频繁调用
- 缓存结果（如果合适）

### 2. SharedPreferences 读写

- 使用 apply() 而非 commit()（异步写入）
- 避免在主线程阻塞

### 3. 开机广播

- BootReceiver 应快速执行
- 只设置标记，不做耗时操作
- 实际恢复在应用启动时进行

## 常见问题

### Q: 为什么不在 BootReceiver 中直接恢复通知？

A: 因为：
1. Flutter Engine 未初始化
2. 应用可能未启动
3. 耗时操作不应在 BroadcastReceiver 中执行
4. 使用标记 + 应用启动时恢复更可靠

### Q: SharedPreferences 的 key 为什么用 "flutter." 前缀？

A: 为了与 Flutter 的 SharedPreferences 插件兼容，使用相同的命名规范。

### Q: 为什么电池优化请求可能失败？

A: 
1. 用户拒绝授权
2. 系统限制（某些定制ROM）
3. 权限声明缺失
4. Intent 不支持（旧版本Android）

### Q: 如何调试开机恢复？

A:
```bash
# 查看系统日志
adb logcat | grep BootReceiver

# 查看 SharedPreferences
adb shell run-as com.jiuxina.ying cat /data/data/com.jiuxina.ying/shared_prefs/FlutterSharedPreferences.xml
```

## 扩展功能

### 未来可以添加

1. **设备品牌检测**
```kotlin
val manufacturer = Build.MANUFACTURER.toLowerCase()
when (manufacturer) {
    "xiaomi" -> // 小米特殊处理
    "huawei" -> // 华为特殊处理
    // ...
}
```

2. **智能引导**
- 根据品牌显示不同引导
- 检测权限状态自动跳转
- 提供一键配置功能

3. **通知监控**
- 检测通知是否真正触发
- 长期未触发时提醒用户
- 收集兼容性数据

## 参考资料

- [Android Battery Optimization](https://developer.android.com/training/monitoring-device-state/doze-standby)
- [Boot Completed Broadcast](https://developer.android.com/reference/android/content/Intent#ACTION_BOOT_COMPLETED)
- [Flutter Platform Channels](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
