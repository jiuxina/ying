package com.jiuxina.ying

import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val INSTALL_CHANNEL = "com.jiuxina.ying/install"
    private val NOTIFICATION_CHANNEL = "com.jiuxina.ying/notifications"
    private val WIDGET_CHANNEL = "com.jiuxina.ying/widget"
    
    // 保存最新的 Intent（用于 singleTop 模式下正确获取 Widget ID）
    private var pendingWidgetId: Int? = null
    private var pendingEventId: String? = null

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // 更新当前 intent，以便 MethodChannel 可以读取正确的 extras
        setIntent(intent)
        
        // 检查是否是 Widget 配置启动
        val widgetId = intent.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        
        if (widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
            pendingWidgetId = widgetId
            // 通知 Flutter 端有新的 Widget 配置请求
            notifyWidgetConfigPending(widgetId)
        }
        
        // 检查是否是 Widget 点击启动（带事件ID）
        val eventId = intent.getStringExtra("event_id")
            ?: intent.data?.getQueryParameter("eventId")
        if (eventId != null) {
            pendingEventId = eventId
            notifyWidgetClickPending(eventId)
        }
    }
    
    private fun notifyWidgetConfigPending(widgetId: Int) {
        flutterEngine?.dartExecutor?.let { executor ->
            MethodChannel(executor.binaryMessenger, WIDGET_CHANNEL).invokeMethod(
                "onWidgetConfigPending",
                mapOf("widgetId" to widgetId)
            )
        }
    }
    
    private fun notifyWidgetClickPending(eventId: String) {
        flutterEngine?.dartExecutor?.let { executor ->
            MethodChannel(executor.binaryMessenger, WIDGET_CHANNEL).invokeMethod(
                "onWidgetClickPending",
                mapOf("eventId" to eventId)
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 创建通知渠道（Android 8.0+）
        createNotificationChannel()
        
        // APK 安装 MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTALL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        val success = installApk(filePath)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "filePath is null", null)
                    }
                }
                "getAppWidgetId" -> {
                    // 优先使用 pendingWidgetId（从 onNewIntent 获取）
                    val appWidgetId = pendingWidgetId ?: intent?.extras?.getInt(
                        AppWidgetManager.EXTRA_APPWIDGET_ID,
                        AppWidgetManager.INVALID_APPWIDGET_ID
                    ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
                    
                    if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                        result.success(appWidgetId)
                        // 清除 pending 状态
                        pendingWidgetId = null
                    } else {
                        result.success(null)
                    }
                }
                "consumePendingWidgetId" -> {
                    // 消费并返回 pending widget ID，然后清除
                    val widgetId = pendingWidgetId
                    pendingWidgetId = null
                    result.success(widgetId)
                }
                "finishConfigure" -> {
                    val widgetId = call.argument<Int>("widgetId")
                    if (widgetId != null && widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                        // 正确完成 widget 配置：设置 RESULT_OK 并返回 widget ID
                        val resultValue = Intent()
                        resultValue.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                        setResult(Activity.RESULT_OK, resultValue)
                        finish()
                        result.success(true)
                    } else {
                        result.error("INVALID_WIDGET_ID", "Widget ID is invalid", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // 通知和电池优化 MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkBatteryOptimization" -> {
                    val isIgnoring = isIgnoringBatteryOptimizations()
                    result.success(isIgnoring)
                }
                "requestBatteryOptimization" -> {
                    val requested = requestIgnoreBatteryOptimizations()
                    result.success(requested)
                }
                "openBatterySettings" -> {
                    openBatteryOptimizationSettings()
                    result.success(true)
                }
                "checkBootRestoreNeeded" -> {
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val needsRestore = prefs.getBoolean("flutter.needs_notification_restore", false)
                    result.success(needsRestore)
                }
                "clearBootRestoreFlag" -> {
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    prefs.edit().putBoolean("flutter.needs_notification_restore", false).apply()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        // Widget MethodChannel - 处理 Widget 点击和数据查询
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getWidgetEventId" -> {
                    val widgetId = call.argument<Int>("widgetId")
                    if (widgetId != null && widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                        val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                        val eventId = prefs.getString("event_id_$widgetId", null)
                        result.success(eventId)
                    } else {
                        result.success(null)
                    }
                }
                "getLaunchEventId" -> {
                    // 优先使用 pendingEventId（从 onNewIntent 获取）
                    val eventId = pendingEventId 
                        ?: intent?.getStringExtra("event_id")
                        ?: intent?.data?.getQueryParameter("eventId")
                    // 清除 pending 状态
                    pendingEventId = null
                    result.success(eventId)
                }
                "consumePendingEventId" -> {
                    // 消费并返回 pending event ID，然后清除
                    val eventId = pendingEventId
                    pendingEventId = null
                    result.success(eventId)
                }
                // 兼容旧调用：部分 Flutter 代码可能从 widget 通道读取 pending widget ID
                "consumePendingWidgetId" -> {
                    val widgetId = pendingWidgetId
                    pendingWidgetId = null
                    result.success(widgetId)
                }
                "getAppWidgetId" -> {
                    val appWidgetId = pendingWidgetId ?: intent?.extras?.getInt(
                        AppWidgetManager.EXTRA_APPWIDGET_ID,
                        AppWidgetManager.INVALID_APPWIDGET_ID
                    ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

                    if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                        result.success(appWidgetId)
                        pendingWidgetId = null
                    } else {
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * 检查是否已忽略电池优化
     */
    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            return powerManager.isIgnoringBatteryOptimizations(packageName)
        }
        return true // Android 6.0 以下不需要此权限
    }

    /**
     * 请求忽略电池优化权限
     */
    private fun requestIgnoreBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!isIgnoringBatteryOptimizations()) {
                try {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    intent.data = Uri.parse("package:$packageName")
                    startActivity(intent)
                    return true
                } catch (e: Exception) {
                    // 如果直接请求失败，打开电池优化设置页面
                    openBatteryOptimizationSettings()
                    return false
                }
            }
        }
        return true
    }

    /**
     * 打开电池优化设置页面
     */
    private fun openBatteryOptimizationSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                startActivity(intent)
            }
        } catch (e: Exception) {
            // 如果无法打开特定设置，打开应用详情页
            try {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
            } catch (e2: Exception) {
                e2.printStackTrace()
            }
        }
    }

    private fun installApk(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) {
                return false
            }
            
            val intent = Intent(Intent.ACTION_VIEW)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // Android 7.0+ 需要使用 FileProvider
                val uri = FileProvider.getUriForFile(
                    this,
                    "${applicationContext.packageName}.fileprovider",
                    file
                )
                intent.setDataAndType(uri, "application/vnd.android.package-archive")
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } else {
                intent.setDataAndType(Uri.fromFile(file), "application/vnd.android.package-archive")
            }
            
            startActivity(intent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
    
    /**
     * 创建通知渠道（Android 8.0+）
     * 确保后台通知能正常工作
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "event_reminders"
            val channelName = "事件提醒"
            val channelDescription = "倒数日事件的提醒通知"
            val importance = NotificationManager.IMPORTANCE_HIGH
            
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500)
                enableLights(true)
                lightColor = 0xFF2196F3.toInt()
                setShowBadge(true)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
