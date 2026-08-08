package com.jiuxina.ying

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.time.LocalDate
import java.time.ZoneId
import java.time.temporal.ChronoUnit

class DaymarkWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        updateWidgets(context, appWidgetManager, appWidgetIds, widgetData)
        MidnightRefreshScheduler.schedule(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_NAVIGATE -> {
                val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
                val newIndex = intent.getIntExtra(EXTRA_INDEX, 0)
                val data = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                data.edit().putInt("daymark_widget_index_$widgetId", newIndex).apply()
                val manager = AppWidgetManager.getInstance(context)
                onUpdate(context, manager, intArrayOf(widgetId), data)
                return
            }
            MidnightRefreshScheduler.ACTION_MIDNIGHT_REFRESH,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                updateAllWidgets(context)
                MidnightRefreshScheduler.schedule(context)
                return
            }
        }
        super.onReceive(context, intent)
    }

    private fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val events = parseEvents(widgetData.getString("widget_events", "[]") ?: "[]")
        appWidgetIds.forEach { widgetId ->
            val indexKey = "daymark_widget_index_$widgetId"
            val requestedIndex = widgetData.getInt(indexKey, 0)
            val index = if (events.isEmpty()) 0 else requestedIndex.coerceIn(0, events.lastIndex)
            val event = events.getOrNull(index)
            val views = RemoteViews(context.packageName, R.layout.daymark_widget)
            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val compact = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250) < 220 ||
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 130) < 120
            val launchIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent)
            applyAppearance(views, widgetData, compact)
            views.setViewVisibility(R.id.widget_previous, if (compact) View.GONE else View.VISIBLE)
            views.setViewVisibility(R.id.widget_next, if (compact) View.GONE else View.VISIBLE)

            if (event == null) {
                views.setTextViewText(R.id.widget_title, "添加一个倒数日")
                views.setTextViewText(R.id.widget_days, "--")
                views.setTextViewText(R.id.widget_unit, "天")
                views.setTextViewText(R.id.widget_category, "萤")
                views.setViewVisibility(R.id.widget_note, View.GONE)
                views.setViewVisibility(R.id.widget_complete, View.GONE)
            } else {
                val days = event.daysFromToday()
                val countUp = event.isCountUp || days < 0
                views.setTextViewText(R.id.widget_title, event.title)
                views.setTextViewText(R.id.widget_days, kotlin.math.abs(days).toString())
                views.setTextViewText(
                    R.id.widget_unit,
                    when {
                        days == 0L -> "就是今天"
                        countUp -> "天 · 已经"
                        else -> "天 · 还有"
                    },
                )
                if (!compact && widgetData.getBoolean("widget_show_category", true)) {
                    views.setTextViewText(R.id.widget_category, event.category.uppercase())
                    views.setViewVisibility(R.id.widget_category, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_category, View.INVISIBLE)
                }
                if (!compact && widgetData.getBoolean("widget_show_note", true) && event.note.isNotBlank()) {
                    views.setTextViewText(R.id.widget_note, event.note)
                    views.setViewVisibility(R.id.widget_note, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_note, View.GONE)
                }
                views.setViewVisibility(R.id.widget_complete, View.VISIBLE)
                views.setOnClickPendingIntent(
                    R.id.widget_complete,
                    HomeWidgetBackgroundIntent.getBroadcast(
                        context,
                        Uri.parse("ying://complete?id=${Uri.encode(event.id)}"),
                    ),
                )
            }

            views.setOnClickPendingIntent(
                R.id.widget_previous,
                navigationIntent(context, widgetId, index - 1, events.size),
            )
            views.setOnClickPendingIntent(
                R.id.widget_next,
                navigationIntent(context, widgetId, index + 1, events.size),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun navigationIntent(
        context: Context,
        widgetId: Int,
        requested: Int,
        size: Int,
    ): PendingIntent {
        val index = if (size == 0) 0 else (requested % size + size) % size
        val intent = Intent(context, DaymarkWidgetProvider::class.java).apply {
            action = ACTION_NAVIGATE
            data = Uri.parse("ying://navigate/$widgetId/$index")
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            putExtra(EXTRA_INDEX, index)
        }
        return PendingIntent.getBroadcast(
            context,
            widgetId * 1000 + index,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun applyAppearance(views: RemoteViews, data: SharedPreferences, compact: Boolean) {
        val color = try {
            data.getString("widget_color", "ff6750a4")?.toLong(16)?.toInt()
                ?: Color.rgb(103, 80, 164)
        } catch (_: Exception) {
            Color.rgb(103, 80, 164)
        }
        views.setInt(R.id.widget_root, "setBackgroundColor", color)
        val scale = java.lang.Double.longBitsToDouble(
            data.getLong("widget_font_scale", java.lang.Double.doubleToRawLongBits(1.0)),
        ).toFloat()
        views.setTextViewTextSize(R.id.widget_title, 2, (if (compact) 17f else 20f) * scale)
        views.setTextViewTextSize(R.id.widget_days, 2, (if (compact) 38f else 44f) * scale)
        views.setTextViewTextSize(R.id.widget_note, 2, 13f * scale)
    }

    private fun parseEvents(raw: String): List<WidgetEvent> = try {
        val array = JSONArray(raw)
        buildList {
            for (index in 0 until array.length()) {
                val value = array.getJSONObject(index)
                add(
                    WidgetEvent(
                        id = value.getString("id"),
                        title = value.getString("title"),
                        targetDate = value.getLong("targetDate"),
                        category = value.optString("category", "生活"),
                        note = value.optString("note", ""),
                        icon = value.optString("icon", ""),
                        createdAt = value.optLong("createdAt", 0L),
                        isCountUp = value.optBoolean("isCountUp", false),
                    ),
                )
            }
        }
    } catch (_: Exception) {
        emptyList()
    }

    private data class WidgetEvent(
        val id: String,
        val title: String,
        val targetDate: Long,
        val category: String,
        val note: String,
        val icon: String,
        val createdAt: Long,
        val isCountUp: Boolean,
    ) {
        fun daysFromToday(): Long {
            val target = java.time.Instant.ofEpochMilli(targetDate)
                .atZone(ZoneId.systemDefault()).toLocalDate()
            return ChronoUnit.DAYS.between(LocalDate.now(), target)
        }
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"
        private const val ACTION_NAVIGATE = "com.jiuxina.ying.NAVIGATE"
        private const val EXTRA_INDEX = "index"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, DaymarkWidgetProvider::class.java),
            )
            val data = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            DaymarkWidgetProvider().updateWidgets(context, manager, ids, data)
        }
    }
}
