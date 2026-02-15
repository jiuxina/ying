package com.jiuxina.ying

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Boot Receiver - 监听系统开机广播
 * 
 * 在系统重启后恢复定时通知，确保应用关闭或重启后通知仍能正常工作。
 * 当设备开机时，调用 Flutter 层的通知恢复方法。
 */
class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
        private const val CHANNEL = "com.jiuxina.ying/notifications"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "系统开机完成，准备恢复通知调度")
            
            try {
                // 通过 SharedPreferences 标记需要恢复通知
                // Flutter 应用启动时会检查这个标记并恢复通知
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                prefs.edit().putBoolean("flutter.needs_notification_restore", true).apply()
                
                Log.d(TAG, "已设置通知恢复标记，将在应用启动时恢复")
            } catch (e: Exception) {
                Log.e(TAG, "设置通知恢复标记失败", e)
            }
        }
    }
}
