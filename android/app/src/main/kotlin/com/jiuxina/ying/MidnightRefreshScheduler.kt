package com.jiuxina.ying

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import java.time.ZonedDateTime

/**
 * 每个本地零点后的 5 分钟窗口内触发一次小部件刷新。
 *
 * 使用 `setWindow(RTC_WAKEUP, ...)` 不需要精确闹钟权限，Doze 下可能被系统
 * 延迟，由 30 分钟轮询与 DATE_CHANGED / TIME_SET 等广播兜底。
 */
object MidnightRefreshScheduler {
    const val ACTION_MIDNIGHT_REFRESH = "com.jiuxina.ying.MIDNIGHT_REFRESH"
    const val WINDOW_MILLIS: Long = 5 * 60 * 1000L

    fun nextMidnightMillis(now: ZonedDateTime): Long {
        val nextMidnight = now.toLocalDate().plusDays(1).atStartOfDay(now.zone)
        return nextMidnight.toInstant().toEpochMilli()
    }

    fun schedule(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        scheduleProvider(context, alarmManager, DaymarkWidgetProvider::class.java, 0)
        scheduleProvider(
            context,
            alarmManager,
            DaymarkDetailWidgetProvider::class.java,
            1,
        )
    }

    fun cancel(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent(context, DaymarkWidgetProvider::class.java, 0))
        alarmManager.cancel(
            pendingIntent(context, DaymarkDetailWidgetProvider::class.java, 1),
        )
    }

    private fun scheduleProvider(
        context: Context,
        alarmManager: AlarmManager,
        providerClass: Class<out Any>,
        requestCode: Int,
    ) {
        alarmManager.setWindow(
            AlarmManager.RTC_WAKEUP,
            nextMidnightMillis(ZonedDateTime.now()),
            WINDOW_MILLIS,
            pendingIntent(context, providerClass, requestCode),
        )
    }

    private fun pendingIntent(
        context: Context,
        providerClass: Class<out Any>,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, providerClass).apply {
            action = ACTION_MIDNIGHT_REFRESH
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }
}
