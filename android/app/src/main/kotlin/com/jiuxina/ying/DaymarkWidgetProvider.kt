package com.jiuxina.ying

import android.app.AlarmManager
import android.app.ActivityOptions
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import android.widget.Toast
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.time.LocalDate
import java.time.ZoneId
import java.time.temporal.ChronoUnit
import java.util.Calendar
import java.util.Date
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.roundToLong

private const val LAUNCH_REQUEST_ROOT = 0
private const val LAUNCH_REQUEST_ADD = 1
private const val LAUNCH_REQUEST_OPEN = 2
private const val ROW_LAUNCH_REQUEST_BASE = 0x10000000
private const val MAX_LIST_ROWS = 4

internal fun launchIntent(
    context: Context,
    uri: String?,
    requestCode: Int,
): PendingIntent {
    val intent = Intent(context, MainActivity::class.java).apply {
        data = uri?.let { Uri.parse(it) }
        action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
    }
    var flags = PendingIntent.FLAG_UPDATE_CURRENT
    if (Build.VERSION.SDK_INT >= 23) {
        flags = flags or PendingIntent.FLAG_IMMUTABLE
    }
    return if (Build.VERSION.SDK_INT < 34) {
        PendingIntent.getActivity(context, requestCode, intent, flags)
    } else {
        val options = ActivityOptions.makeBasic()
        if (Build.VERSION.SDK_INT >= 35) {
            options.setPendingIntentCreatorBackgroundActivityStartMode(
                ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED,
            )
        } else {
            options.pendingIntentBackgroundActivityStartMode =
                ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
        }
        PendingIntent.getActivity(context, requestCode, intent, flags, options.toBundle())
    }
}

open class DaymarkWidgetProvider : HomeWidgetProvider() {
    protected open fun providerClass(): Class<out DaymarkWidgetProvider> =
        DaymarkWidgetProvider::class.java

    protected open fun perWidgetIndexKey(widgetId: Int): String =
        "daymark_widget_index_$widgetId"

    protected open fun supportsListMode(): Boolean = true

    protected open fun prefsName(): String = "HomeWidgetPreferences"

    protected open fun refreshAll(context: Context) {
        updateAllWidgets(context)
    }

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
        if (intent.action == ACTION_REFRESH_FLIP) {
            val data = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            data.edit().remove(FLIP_DAY_KEY).apply()
            refreshAll(context)
            return
        }
        if (intent.action == ACTION_REVEAL) {
            val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
            if (widgetId >= 0) {
                val data = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val key = envelopeOpenKey(widgetId)
                data.edit().putBoolean(key, !data.getBoolean(key, false)).apply()
                refreshAll(context)
            }
            return
        }
        when (intent.action) {
            ACTION_NAVIGATE -> {
                val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
                val newIndex = intent.getIntExtra(EXTRA_INDEX, 0)
                val data = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                data.edit().putInt(perWidgetIndexKey(widgetId), newIndex).apply()
                val manager = AppWidgetManager.getInstance(context)
                onUpdate(context, manager, intArrayOf(widgetId), data)
                return
            }
            MidnightRefreshScheduler.ACTION_MIDNIGHT_REFRESH,
            ACTION_REFRESH_PENDING_UNDO,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                refreshAll(context)
                MidnightRefreshScheduler.schedule(context)
                return
            }
        }
        super.onReceive(context, intent)
    }

    protected open fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        showPendingToast(context, widgetData)
        val events = parseEvents(widgetData.getString("widget_events", "[]") ?: "[]")
        val listMode = widgetData.getBoolean("widget_list_mode", false) && supportsListMode()
        val rawPending = widgetData.getString(PENDING_UNDO_KEY, "")
        val expired = pendingUndoPayload(rawPending)?.takeIf { it.isExpired() }
        if (expired != null) {
            widgetData.edit().remove(PENDING_UNDO_KEY).apply()
        }
        val pendingUndo = pendingUndoPayload(widgetData.getString(PENDING_UNDO_KEY, ""))
        if (pendingUndo != null) {
            scheduleUndoExpiry(context, pendingUndo)
            appWidgetIds.forEach { widgetId ->
                val views = RemoteViews(
                    context.packageName,
                    R.layout.daymark_widget_undo,
                )
                applyBackdrop(
                    context,
                    views,
                    widgetData,
                    parseWidgetStyle(widgetData.getString("widget_style", "card")),
                )
                views.setTextViewText(R.id.widget_title, pendingUndo.title)
                views.setOnClickPendingIntent(
                    R.id.widget_undo,
                    backgroundIntent(
                        context,
                        "undo",
                        pendingUndo.eventId,
                    ),
                )
                views.setOnClickPendingIntent(
                    R.id.widget_add,
                    launchIntent(context, "ying://add", LAUNCH_REQUEST_ADD),
                )
                views.setOnClickPendingIntent(
                    R.id.widget_root,
                    launchIntent(context, null, LAUNCH_REQUEST_ROOT),
                )
                appWidgetManager.updateAppWidget(widgetId, views)
            }
            return
        }
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(
                context.packageName,
                if (listMode) R.layout.daymark_widget_list else R.layout.daymark_widget,
            )
            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val compact = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250) < 220 ||
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 130) < 120
            val style = parseWidgetStyle(widgetData.getString("widget_style", "card"))
            val holiday = resolveHoliday(
                widgetData.getString("widget_holiday", ""),
                LocalDate.now(),
                events.getOrNull(widgetData.getInt(perWidgetIndexKey(widgetId), 0)),
            )
            if (listMode) {
                updateListWidget(context, views, widgetData, style)
            } else {
                updateSingleWidget(
                    context,
                    views,
                    widgetData,
                    widgetId,
                    events,
                    compact,
                    style,
                    holiday,
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun updateSingleWidget(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
        widgetId: Int,
        events: List<WidgetEvent>,
        compact: Boolean,
        style: WidgetStyle,
        holiday: String,
    ) {
        views.setOnClickPendingIntent(
            R.id.widget_root,
            launchIntent(context, null, LAUNCH_REQUEST_ROOT),
        )
        views.setOnClickPendingIntent(
            R.id.widget_add,
            launchIntent(context, "ying://add", LAUNCH_REQUEST_ADD),
        )
        val indexKey = perWidgetIndexKey(widgetId)
        val requestedIndex = widgetData.getInt(indexKey, 0)
        val index = if (events.isEmpty()) 0 else requestedIndex.coerceIn(0, events.lastIndex)
        val event = events.getOrNull(index)
        if (event != null) {
            views.setOnClickPendingIntent(
                R.id.widget_title_row,
                launchIntent(
                    context,
                    "ying://open?id=${Uri.encode(event.id)}",
                    LAUNCH_REQUEST_OPEN,
                ),
            )
        }
        applyAppearance(context, views, widgetData, compact, style, holiday)
        if (style == WidgetStyle.mirror) {
            views.setFloat(R.id.widget_content, "setRotation", -2.5f)
        }
        views.setViewVisibility(R.id.widget_previous, if (compact) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.widget_next, if (compact) View.GONE else View.VISIBLE)

        if (event == null) {
            views.setTextViewText(R.id.widget_title, "添加一个倒数日")
            setDaysText(views, "--", widgetData, compact, style)
            views.setViewVisibility(R.id.widget_days_old, View.GONE)
            views.setTextViewText(R.id.widget_unit, "天")
            views.setTextViewText(R.id.widget_category, "萤")
            views.setViewVisibility(R.id.widget_icon, View.GONE)
            views.setViewVisibility(R.id.widget_note, View.GONE)
            views.setViewVisibility(R.id.widget_complete, View.GONE)
            views.setViewVisibility(R.id.widget_precise, View.GONE)
            views.setViewVisibility(R.id.widget_date_info, View.GONE)
            views.setViewVisibility(R.id.widget_progress_ring, View.GONE)
            views.setViewVisibility(R.id.widget_progress_text, View.GONE)
            views.setViewVisibility(R.id.widget_health_bar, View.GONE)
            views.setViewVisibility(R.id.widget_envelope_cover, View.GONE)
            return
        }

        val days = event.daysFromToday()
        val countUp = event.isCountUp || days < 0
        val preset = widgetData.getString("widget_unit_text", "")
        val mystery = widgetData.getBoolean("widget_mystery_mode", false)
        val flipDay = widgetData.getInt(FLIP_DAY_KEY, -1)
        if (flipDay >= 0 && abs(days.toInt()) != flipDay && !mystery) {
            views.setTextViewText(R.id.widget_days_old, countMainText(event, preset, flipDay.toLong()))
            views.setTextViewTextSize(
                R.id.widget_days_old,
                2,
                (if (flipDay.toString().length > 3) 26f else 44f) *
                    widgetFontScale(widgetData),
            )
            views.setViewVisibility(R.id.widget_days_old, View.VISIBLE)
            scheduleFlipRefresh(context)
        } else {
            views.setViewVisibility(R.id.widget_days_old, View.GONE)
        }
        views.setTextViewText(R.id.widget_title, event.title)
        if (widgetData.getBoolean("widget_show_icon", false) && event.icon.isNotBlank()) {
            views.setTextViewText(R.id.widget_icon, event.icon)
            views.setViewVisibility(R.id.widget_icon, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_icon, View.GONE)
        }
        setDaysText(
            views,
            if (mystery) "🕯️" else countMainText(event, preset, days),
            widgetData,
            compact,
            style,
        )
        views.setTextViewText(
            R.id.widget_unit,
            if (mystery) "快到了" else countUnitText(event, preset, days, countUp),
        )
        applyUrgentHighlight(views, widgetData, days, mystery, preset)
        if (style == WidgetStyle.capsule && days == 0L) {
            val congratsAccent = accentColor(widgetData, holiday)
            views.setTextViewText(R.id.widget_title, "恭喜！${event.title}")
            setDaysText(views, "🎉", widgetData, compact, style)
            views.setTextViewText(R.id.widget_unit, "就是今天")
            listOf(
                R.id.widget_days,
                R.id.widget_days_mono,
                R.id.widget_days_pixel,
                R.id.widget_days_hand,
                R.id.widget_days_neon,
            ).forEach { id -> views.setTextColor(id, congratsAccent) }
            views.setTextColor(R.id.widget_unit, congratsAccent)
        }
        if (!compact && widgetData.getBoolean("widget_show_category", true)) {
            views.setTextViewText(R.id.widget_category, event.category)
            views.setViewVisibility(R.id.widget_category, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_category, View.INVISIBLE)
        }

        if (widgetData.getBoolean("widget_show_precise_time", false)) {
            applyPreciseTime(views, event)
        } else {
            views.setViewVisibility(R.id.widget_precise, View.GONE)
        }
        if (!compact && widgetData.getBoolean("widget_show_lunar_week", false)) {
            val info = widgetData.getString("widget_date_info", "")
                ?.takeIf { it.isNotBlank() }
                ?: widgetDateInfo(LocalDate.now())
            views.setTextViewText(R.id.widget_date_info, info)
            views.setViewVisibility(R.id.widget_date_info, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_date_info, View.GONE)
        }
        if (!compact && widgetData.getBoolean("widget_show_progress", false)) {
            val progress = progressOf(event, System.currentTimeMillis())
            views.setImageViewBitmap(
                R.id.widget_progress_ring,
                progressRingBitmap(context, progress, accentColor(widgetData, holiday)),
            )
            views.setTextViewText(
                R.id.widget_progress_text,
                "${(progress * 100).toInt()}%",
            )
            views.setViewVisibility(R.id.widget_progress_ring, View.VISIBLE)
            views.setViewVisibility(R.id.widget_progress_text, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_progress_ring, View.GONE)
            views.setViewVisibility(R.id.widget_progress_text, View.GONE)
        }
        if (style == WidgetStyle.pixelHealth && !compact) {
            val progress = progressOf(event, System.currentTimeMillis())
            views.setImageViewBitmap(
                R.id.widget_health_bar,
                pixelHealthBarBitmap(
                    context,
                    progress,
                    accentColor(widgetData, holiday),
                ),
            )
            views.setViewVisibility(R.id.widget_health_bar, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_health_bar, View.GONE)
        }

        val quote = if (widgetData.getBoolean("widget_quote_mode", false)) {
            quoteText(event, LocalDate.now())
        } else {
            ""
        }
        val showNote = widgetData.getBoolean("widget_show_note", true)
        if (!compact && (quote.isNotEmpty() || (showNote && event.note.isNotBlank()))) {
            views.setTextViewText(R.id.widget_note, quote.ifEmpty { event.note })
            views.setViewVisibility(R.id.widget_note, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_note, View.GONE)
        }
        views.setViewVisibility(R.id.widget_complete, View.VISIBLE)
        views.setOnClickPendingIntent(
            R.id.widget_complete,
            backgroundIntent(context, "complete", event.id),
        )
        views.setOnClickPendingIntent(
            R.id.widget_date_row,
            backgroundIntent(context, "copy", event.id),
        )
        if (style == WidgetStyle.envelope) {
            val open = widgetData.getBoolean(envelopeOpenKey(widgetId), false)
            views.setImageViewBitmap(
                R.id.widget_envelope_cover,
                envelopeCoverBitmap(
                    context,
                    accentColor(widgetData, holiday),
                ),
            )
            views.setViewVisibility(
                R.id.widget_envelope_cover,
                if (open) View.GONE else View.VISIBLE,
            )
            views.setOnClickPendingIntent(
                R.id.widget_envelope_cover,
                revealIntent(context, widgetId),
            )
        } else {
            views.setViewVisibility(R.id.widget_envelope_cover, View.GONE)
        }

        views.setOnClickPendingIntent(
            R.id.widget_previous,
            navigationIntent(context, widgetId, index - 1, events.size),
        )
        views.setOnClickPendingIntent(
            R.id.widget_next,
            navigationIntent(context, widgetId, index + 1, events.size),
        )
    }

    private fun widgetFontScale(data: SharedPreferences): Float =
        java.lang.Double.longBitsToDouble(
            data.getLong("widget_font_scale", java.lang.Double.doubleToRawLongBits(1.0)),
        ).toFloat()

    private fun scheduleFlipRefresh(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, providerClass()).apply {
            action = ACTION_REFRESH_FLIP
        }
        alarmManager.set(
            AlarmManager.RTC,
            System.currentTimeMillis() + FLIP_WINDOW_MILLIS,
            PendingIntent.getBroadcast(
                context,
                FLIP_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            ),
        )
    }

    private fun updateListWidget(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
        style: WidgetStyle,
    ) {
        views.setOnClickPendingIntent(
            R.id.widget_root,
            launchIntent(context, null, LAUNCH_REQUEST_ROOT),
        )
        views.setOnClickPendingIntent(
            R.id.widget_add,
            launchIntent(context, "ying://add", LAUNCH_REQUEST_ADD),
        )
        applyBackdrop(context, views, widgetData, style)
        val events = parseEvents(widgetData.getString("widget_events", "[]") ?: "[]")
        val colors = resolveTextColors(widgetData, style)
        val showIcon = widgetData.getBoolean("widget_show_icon", false)
        val mystery = widgetData.getBoolean("widget_mystery_mode", false)
        val preset = widgetData.getString("widget_unit_text", "")
        val showCategory = widgetData.getBoolean("widget_show_category", true)
        val showPrecise = widgetData.getBoolean("widget_show_precise_time", false)
        var visibleCount = 0
        repeat(MAX_LIST_ROWS) { rowIndex ->
            val ids = widgetRowIds(rowIndex + 1)
            val event = events.getOrNull(rowIndex)
            if (event == null) {
                views.setViewVisibility(ids.root, View.GONE)
                return@repeat
            }
            visibleCount++
            views.setViewVisibility(ids.root, View.VISIBLE)
            views.setTextViewText(ids.title, event.title)
            views.setTextColor(ids.title, colors.primary)
            views.setTextColor(ids.days, colors.primary)
            views.setTextColor(ids.unit, colors.secondary)
            views.setTextColor(ids.subtitle, colors.secondary)
            if (showIcon && event.icon.isNotBlank()) {
                views.setTextViewText(ids.icon, event.icon)
                views.setViewVisibility(ids.icon, View.VISIBLE)
            } else {
                views.setViewVisibility(ids.icon, View.GONE)
            }
            val days = event.daysFromToday()
            val countUp = event.isCountUp || days < 0
            views.setTextViewText(
                ids.days,
                if (mystery) "🕯️" else countMainText(event, preset, days),
            )
            views.setTextViewText(
                ids.unit,
                if (mystery) "快到了" else countUnitText(event, preset, days, countUp),
            )
            if (widgetData.getBoolean("widget_urgent_highlight", false) && !mystery) {
                val level = urgentLevel(days)
                val accent = urgentAccent(level)
                if (accent != null) {
                    views.setTextColor(ids.days, accent)
                    views.setTextColor(ids.unit, accent)
                    if (preset != "weeks") {
                        views.setTextViewText(ids.unit, urgentLabel(level, days))
                    }
                }
            }
            val subtitle = buildList {
                if (showCategory) add(event.category)
                if (showPrecise) add(preciseTimeText(event, System.currentTimeMillis()))
            }.joinToString(" · ")
            if (subtitle.isNotEmpty()) {
                views.setTextViewText(ids.subtitle, subtitle)
                views.setViewVisibility(ids.subtitle, View.VISIBLE)
            } else {
                views.setViewVisibility(ids.subtitle, View.GONE)
            }
            views.setOnClickPendingIntent(
                ids.complete,
                backgroundIntent(context, "complete", event.id),
            )
            views.setOnClickPendingIntent(
                ids.root,
                launchIntent(
                    context,
                    "ying://open?id=${Uri.encode(event.id)}",
                    rowLaunchRequestCode(event.id),
                ),
            )
        }
        views.setViewVisibility(
            R.id.widget_empty,
            if (visibleCount == 0) View.VISIBLE else View.GONE,
        )
    }

    private fun showPendingToast(context: Context, data: SharedPreferences) {
        val message = data.getString(TOAST_KEY, "") ?: ""
        if (message.isBlank()) return
        data.edit().remove(TOAST_KEY).apply()
        Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
    }

    private fun scheduleUndoExpiry(context: Context, pending: PendingUndoPayload) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, providerClass()).apply {
            action = ACTION_REFRESH_PENDING_UNDO
            data = Uri.parse("ying://undo-expire/${pending.eventId}")
        }
        val requestCode = pending.eventId.hashCode() and 0x7FFFFFFF
        alarmManager.set(
            AlarmManager.RTC,
            pending.expiresAt + 500,
            PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            ),
        )
    }

    private fun cancelUndoExpiry(context: Context, eventId: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, providerClass()).apply {
            action = ACTION_REFRESH_PENDING_UNDO
            data = Uri.parse("ying://undo-expire/$eventId")
        }
        alarmManager.cancel(
            PendingIntent.getBroadcast(
                context,
                eventId.hashCode() and 0x7FFFFFFF,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            ),
        )
    }

    private fun applyAppearance(
        context: Context,
        views: RemoteViews,
        data: SharedPreferences,
        compact: Boolean,
        style: WidgetStyle,
        holiday: String,
    ) {
        val colors = resolveTextColors(data, style)
        applyBackdrop(context, views, data, style)

        val holidayVisible = holiday.isNotEmpty() && !compact
        if (holidayVisible) {
            views.setTextViewText(R.id.widget_holiday_badge, holidayLabel(holiday))
            views.setViewVisibility(R.id.widget_holiday_badge, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_holiday_badge, View.GONE)
        }

        views.setTextColor(R.id.widget_title, colors.primary)
        views.setTextColor(R.id.widget_unit, colors.secondary)
        views.setTextColor(R.id.widget_category, colors.secondary)
        views.setTextColor(R.id.widget_note, colors.secondary)
        views.setTextColor(R.id.widget_icon, colors.primary)
        views.setTextColor(R.id.widget_precise, colors.secondary)
        views.setTextColor(R.id.widget_date_info, colors.secondary)
        views.setTextColor(R.id.widget_progress_text, colors.secondary)
        listOf(
            R.id.widget_days,
            R.id.widget_days_mono,
            R.id.widget_days_pixel,
            R.id.widget_days_hand,
            R.id.widget_days_neon,
        ).forEach { id -> views.setTextColor(id, colors.primary) }
        views.setInt(R.id.widget_previous, "setColorFilter", colors.secondary)
        views.setInt(R.id.widget_next, "setColorFilter", colors.secondary)
        views.setInt(R.id.widget_complete, "setColorFilter", colors.secondary)

        val scale = widgetFontScale(data)
        views.setTextViewTextSize(R.id.widget_title, 2, 18f * scale)
        views.setTextViewTextSize(R.id.widget_note, 2, 14f * scale)
    }

    private fun applyUrgentHighlight(
        views: RemoteViews,
        data: SharedPreferences,
        days: Long,
        mystery: Boolean,
        preset: String?,
    ) {
        if (!data.getBoolean("widget_urgent_highlight", false) || mystery) return
        val level = urgentLevel(days)
        val accent = urgentAccent(level) ?: return
        listOf(
            R.id.widget_days,
            R.id.widget_days_mono,
            R.id.widget_days_pixel,
            R.id.widget_days_hand,
            R.id.widget_days_neon,
        ).forEach { id -> views.setTextColor(id, accent) }
        views.setTextColor(R.id.widget_unit, accent)
        if (preset != "weeks") {
            views.setTextViewText(R.id.widget_unit, urgentLabel(level, days))
        }
    }

    private fun applyBackdrop(
        context: Context,
        views: RemoteViews,
        data: SharedPreferences,
        style: WidgetStyle,
    ) {
        val colors = resolveTextColors(data, style)
        val baseColor = baseColor(data)
        val accent = accentColor(data, "")
        val backdrop = buildBackdrop(
            context,
            style,
            baseColor,
            accent,
            colors.primary,
            data.getString("widget_background_path", ""),
        )
        if (backdrop == null) {
            views.setViewVisibility(R.id.widget_backdrop, View.GONE)
        } else {
            views.setViewVisibility(R.id.widget_backdrop, View.VISIBLE)
            views.setImageViewBitmap(R.id.widget_backdrop, backdrop)
        }
        val scrimVisible = style == WidgetStyle.sticker || style == WidgetStyle.photo
        if (scrimVisible) {
            views.setImageViewBitmap(R.id.widget_scrim, scrimBitmap(320, 240))
            views.setViewVisibility(R.id.widget_scrim, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_scrim, View.GONE)
        }
    }

    private fun buildBackdrop(
        context: Context,
        style: WidgetStyle,
        baseColor: Int,
        accent: Int,
        textColor: Int,
        photoPath: String?,
    ): Bitmap? {
        val width = 320
        val height = 240
        val density = context.resources.displayMetrics.density
        return when (style) {
            WidgetStyle.card -> roundedRectBitmap(
                width,
                height,
                baseColor,
                10f * density,
            )
            WidgetStyle.sticker -> null
            WidgetStyle.photo -> {
                loadPhotoBitmap(photoPath, 10f * density)
                    ?: photoPlaceholderBitmap(width, height, accent, 10f * density)
            }
            WidgetStyle.glass -> roundedRectBitmap(
                width,
                height,
                0xB8FFFFFF.toInt(),
                10f * density,
                borderColor = 0xBFFFFFFF.toInt(),
                borderWidth = 1f * density,
            )
            WidgetStyle.polaroid -> polaroidBitmap(width, height, 4f * density)
            WidgetStyle.neon -> roundedRectBitmap(
                width,
                height,
                0xFF0A0F1E.toInt(),
                8f * density,
                borderColor = accent,
                borderWidth = 1f * density,
            )
            WidgetStyle.pixel -> roundedRectBitmap(
                width,
                height,
                0xFF141414.toInt(),
                0f,
                borderColor = withAlpha(accent, 0xE6),
                borderWidth = 1f * density,
            )
            WidgetStyle.envelope -> roundedRectBitmap(
                width,
                height,
                0xFF3B2A26.toInt(),
                10f * density,
                borderColor = withAlpha(accent, 0x99),
                borderWidth = 1f * density,
            )
            WidgetStyle.capsule -> capsuleBitmap(width, height, baseColor, accent)
            WidgetStyle.crt -> crtBitmap(width, height, accent)
            WidgetStyle.neonSign -> neonSignBackdropBitmap(width, height, accent)
            WidgetStyle.pixelHealth -> pixelHealthBackdropBitmap(width, height, accent)
            WidgetStyle.mirror -> mirrorBackdropBitmap(width, height, accent)
            WidgetStyle.minimal -> roundedRectBitmap(
                width,
                height,
                0x00000000,
                8f * density,
                borderColor = withAlpha(textColor, 0x66),
                borderWidth = 1f * density,
            )
        }
    }

    private fun roundedRectBitmap(
        width: Int,
        height: Int,
        color: Int,
        radius: Float,
        borderColor: Int? = null,
        borderWidth: Float = 0f,
    ): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color }
        canvas.drawRoundRect(0f, 0f, width.toFloat(), height.toFloat(), radius, radius, fill)
        if (borderColor != null && borderWidth > 0f) {
            val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                this.color = borderColor
                style = Paint.Style.STROKE
                strokeWidth = borderWidth
            }
            val half = borderWidth / 2f
            canvas.drawRoundRect(
                half,
                half,
                width - half,
                height - half,
                radius,
                radius,
                stroke,
            )
        }
        return bitmap
    }

    private fun polaroidBitmap(width: Int, height: Int, radius: Float): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val white = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = Color.WHITE }
        val band = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = Color.rgb(240, 237, 230) }
        canvas.drawRoundRect(0f, 0f, width.toFloat(), height.toFloat(), radius, radius, white)
        val bandTop = height - (height * 0.17f).toInt()
        canvas.drawRect(0f, bandTop.toFloat(), width.toFloat(), height.toFloat(), band)
        return bitmap
    }

    private fun photoPlaceholderBitmap(
        width: Int,
        height: Int,
        accent: Int,
        radius: Float,
    ): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = android.graphics.LinearGradient(
                0f,
                0f,
                width.toFloat(),
                height.toFloat(),
                withAlpha(accent, 0x8C),
                withAlpha(accent, 0x4D),
                android.graphics.Shader.TileMode.CLAMP,
            )
        }
        canvas.drawRoundRect(
            0f,
            0f,
            width.toFloat(),
            height.toFloat(),
            radius,
            radius,
            paint,
        )
        return bitmap
    }

    private fun capsuleBitmap(
        width: Int,
        height: Int,
        baseColor: Int,
        accent: Int,
    ): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val background = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = android.graphics.LinearGradient(
                0f,
                0f,
                width.toFloat(),
                height.toFloat(),
                intArrayOf(0xFF24453F.toInt(), 0xFFC58A4B.toInt()),
                floatArrayOf(0f, 1f),
                android.graphics.Shader.TileMode.CLAMP,
            )
        }
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), background)
        val capsule = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0x33FFFFFF.toInt()
        }
        val capsuleRect = RectF(
            width * 0.18f,
            height * 0.16f,
            width * 0.82f,
            height * 0.84f,
        )
        canvas.drawRoundRect(
            capsuleRect,
            height * 0.24f,
            height * 0.24f,
            capsule,
        )
        val band = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = withAlpha(accent, 0xCC)
            style = Paint.Style.STROKE
            strokeWidth = 3f
        }
        canvas.drawRoundRect(
            capsuleRect,
            height * 0.24f,
            height * 0.24f,
            band,
        )
        val dial = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xCCFFFFFF.toInt()
            style = Paint.Style.STROKE
            strokeWidth = 2f
        }
        canvas.drawCircle(
            width / 2f,
            height / 2f,
            height * 0.12f,
            dial,
        )
        return bitmap
    }

    private fun crtBitmap(width: Int, height: Int, accent: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(0xFF0A120C.toInt())
        val scanline = Paint().apply {
            color = 0x1A000000
            strokeWidth = 1f
        }
        var y = 0f
        while (y < height) {
            canvas.drawLine(0f, y, width.toFloat(), y, scanline)
            y += 4f
        }
        val border = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = withAlpha(accent, 0xA6)
            style = Paint.Style.STROKE
            strokeWidth = 1.5f
        }
        canvas.drawRoundRect(
            1f,
            1f,
            width - 1f,
            height - 1f,
            8f,
            8f,
            border,
        )
        return bitmap
    }

    private fun neonSignBackdropBitmap(
        width: Int,
        height: Int,
        accent: Int,
    ): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(0xFF0A0F1E.toInt())
        val bounds = RectF(3f, 3f, width - 3f, height - 3f)
        for (index in 4 downTo 1) {
            val glow = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = withAlpha(accent, (0x0D * index).coerceAtMost(0x66))
                style = Paint.Style.STROKE
                strokeWidth = index * 3f
            }
            canvas.drawRoundRect(bounds, 8f, 8f, glow)
        }
        val border = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = withAlpha(accent, 0xE6)
            style = Paint.Style.STROKE
            strokeWidth = 1.5f
        }
        canvas.drawRoundRect(bounds, 8f, 8f, border)
        return bitmap
    }

    private fun pixelHealthBackdropBitmap(
        width: Int,
        height: Int,
        accent: Int,
    ): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(0xFF101418.toInt())
        val grid = Paint().apply {
            color = withAlpha(accent, 0x24)
            strokeWidth = 1f
        }
        var x = 0f
        while (x < width) {
            canvas.drawLine(x, 0f, x, height.toFloat(), grid)
            x += 16f
        }
        var gridY = 0f
        while (gridY < height) {
            canvas.drawLine(0f, gridY, width.toFloat(), gridY, grid)
            gridY += 16f
        }
        val block = Paint().apply { color = withAlpha(accent, 0xBF) }
        canvas.drawRect(12f, 14f, 22f, 24f, block)
        canvas.drawRect(34f, 30f, 44f, 40f, block)
        canvas.drawRect(width - 40f, height - 36f, width - 26f, height - 22f, block)
        return bitmap
    }

    private fun mirrorBackdropBitmap(
        width: Int,
        height: Int,
        accent: Int,
    ): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val background = Paint().apply {
            shader = android.graphics.LinearGradient(
                0f,
                0f,
                width.toFloat(),
                height.toFloat(),
                intArrayOf(0xFF312E81.toInt(), 0xFF9D174D.toInt()),
                floatArrayOf(0f, 1f),
                android.graphics.Shader.TileMode.CLAMP,
            )
        }
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), background)
        val stripe = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = withAlpha(accent, 0x38)
            strokeWidth = 10f
        }
        var startX = -height.toFloat()
        while (startX < width) {
            canvas.drawLine(
                startX,
                height.toFloat(),
                startX + height,
                0f,
                stripe,
            )
            startX += 34f
        }
        return bitmap
    }

    private fun envelopeCoverBitmap(context: Context, accent: Int): Bitmap {
        val density = context.resources.displayMetrics.density
        val width = (320 * density).toInt()
        val height = (240 * density).toInt()
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val background = Paint().apply {
            shader = android.graphics.LinearGradient(
                0f,
                0f,
                width.toFloat(),
                height.toFloat(),
                intArrayOf(0xFF5B3330.toInt(), 0xFF2C1917.toInt()),
                floatArrayOf(0f, 1f),
                android.graphics.Shader.TileMode.CLAMP,
            )
        }
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), background)
        val envelope = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xE6FFFFFF.toInt()
        }
        val envelopeRect = RectF(
            width * 0.14f,
            height * 0.26f,
            width * 0.86f,
            height * 0.74f,
        )
        canvas.drawRoundRect(envelopeRect, 12f * density, 12f * density, envelope)
        val flap = Path().apply {
            moveTo(envelopeRect.left, envelopeRect.top)
            lineTo(width / 2f, height * 0.52f)
            lineTo(envelopeRect.right, envelopeRect.top)
            close()
        }
        val flapPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = withAlpha(accent, 0xCC)
        }
        canvas.drawPath(flap, flapPaint)
        val seal = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = accent
        }
        canvas.drawCircle(width / 2f, height * 0.52f, 13f * density, seal)
        val titlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textSize = 17f * density
            isFakeBoldText = true
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText(
            "神秘信封",
            width / 2f,
            height * 0.16f,
            titlePaint,
        )
        val hintPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xCCFFFFFF.toInt()
            textSize = 12f * density
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText(
            "点击查看事件",
            width / 2f,
            height * 0.88f,
            hintPaint,
        )
        return bitmap
    }

    private fun pixelHealthBarBitmap(
        context: Context,
        progress: Float,
        color: Int,
    ): Bitmap {
        val density = context.resources.displayMetrics.density
        val width = (90 * density).toInt().coerceAtLeast(48)
        val height = (14 * density).toInt().coerceAtLeast(10)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val track = Paint().apply { this.color = 0x2EFFFFFF.toInt() }
        canvas.drawRoundRect(
            0f,
            0f,
            width.toFloat(),
            height.toFloat(),
            2f * density,
            2f * density,
            track,
        )
        val segments = 12
        val gap = 2f * density
        val segmentWidth = (width - gap * (segments - 1)) / segments
        val filled = (progress.coerceIn(0f, 1f) * segments).toInt().coerceAtLeast(0)
        val fill = Paint().apply { this.color = color }
        for (index in 0 until filled) {
            val left = index * (segmentWidth + gap)
            canvas.drawRect(
                left,
                1f * density,
                left + segmentWidth,
                height - 1f * density,
                fill,
            )
        }
        return bitmap
    }

    private fun scrimBitmap(width: Int, height: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint().apply {
            shader = android.graphics.LinearGradient(
                0f,
                0f,
                0f,
                height.toFloat(),
                intArrayOf(0x00000000, 0x66000000.toInt()),
                floatArrayOf(0.35f, 1f),
                android.graphics.Shader.TileMode.CLAMP,
            )
        }
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
        return bitmap
    }

    private fun loadPhotoBitmap(path: String?, radius: Float): Bitmap? {
        if (path.isNullOrBlank()) return null
        val file = File(path)
        if (!file.exists()) return null
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            var sampleSize = 1
            val maxDimension = 480
            while (maxOf(bounds.outWidth, bounds.outHeight) / (sampleSize * 2) >= maxDimension) {
                sampleSize *= 2
            }
            val options = BitmapFactory.Options().apply {
                inSampleSize = sampleSize
                inPreferredConfig = Bitmap.Config.RGB_565
            }
            val source = BitmapFactory.decodeFile(path, options) ?: return null
            val output = Bitmap.createBitmap(320, 240, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(output)
            val clip = Path().apply {
                addRoundRect(
                    0f,
                    0f,
                    320f,
                    240f,
                    radius,
                    radius,
                    Path.Direction.CW,
                )
            }
            canvas.clipPath(clip)
            val scale = maxOf(320f / source.width, 240f / source.height)
            val matrix = Matrix().apply {
                setScale(scale, scale)
                postTranslate(
                    (320f - source.width * scale) / 2f,
                    (240f - source.height * scale) / 2f,
                )
            }
            val paint = Paint(
                Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG,
            )
            canvas.drawBitmap(source, matrix, paint)
            source.recycle()
            output
        } catch (_: Exception) {
            null
        }
    }

    private fun setDaysText(
        views: RemoteViews,
        text: String,
        data: SharedPreferences,
        compact: Boolean,
        style: WidgetStyle = WidgetStyle.card,
    ) {
        val scale = widgetFontScale(data)
        val size = if (text.length > 3) {
            26f * scale
        } else {
            (if (compact) 38f else 44f) * scale
        }
        listOf(
            R.id.widget_days,
            R.id.widget_days_mono,
            R.id.widget_days_pixel,
            R.id.widget_days_hand,
            R.id.widget_days_neon,
        ).forEach { id ->
            views.setTextViewText(id, text)
            views.setTextViewTextSize(id, 2, size)
        }
        applyFontVariant(
            views,
            data.getString("widget_font_family", "system"),
            style,
        )
    }

    private fun applyFontVariant(
        views: RemoteViews,
        family: String?,
        style: WidgetStyle = WidgetStyle.card,
    ) {
        val selected = when {
            style == WidgetStyle.neonSign -> R.id.widget_days_neon
            family == "mono" -> R.id.widget_days_mono
            family == "pixel" -> R.id.widget_days_pixel
            family == "hand" -> R.id.widget_days_hand
            else -> R.id.widget_days
        }
        listOf(
            R.id.widget_days,
            R.id.widget_days_mono,
            R.id.widget_days_pixel,
            R.id.widget_days_hand,
            R.id.widget_days_neon,
        ).forEach { id ->
            views.setViewVisibility(id, if (id == selected) View.VISIBLE else View.GONE)
        }
    }

    private fun applyPreciseTime(views: RemoteViews, event: WidgetEvent) {
        val target = event.targetTimeMillis
        val now = System.currentTimeMillis()
        val countUp = event.isCountUp || event.daysFromToday() < 0
        val remaining = if (countUp) now - target else target - now
        if (Build.VERSION.SDK_INT >= 24) {
            val base = SystemClock.elapsedRealtime() + (if (countUp) -remaining else remaining)
            views.setChronometer(R.id.widget_precise, base, "%s", true)
            views.setChronometerCountDown(R.id.widget_precise, !countUp)
            views.setViewVisibility(R.id.widget_precise, View.VISIBLE)
        } else {
            views.setTextViewText(R.id.widget_precise, preciseTimeText(event, now))
            views.setViewVisibility(R.id.widget_precise, View.VISIBLE)
        }
    }

    private fun progressRingBitmap(context: Context, progress: Float, color: Int): Bitmap {
        val density = context.resources.displayMetrics.density
        val size = (42 * density).toInt().coerceAtLeast(24)
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val strokeWidth = 4f * density
        val center = size / 2f
        val radius = center - strokeWidth / 2f
        val track = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            this.strokeWidth = strokeWidth
            this.color = 0x38FFFFFF.toInt()
        }
        canvas.drawCircle(center, center, radius, track)
        val arc = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            this.strokeWidth = strokeWidth
            strokeCap = Paint.Cap.ROUND
            this.color = color
        }
        val bounds = RectF(
            center - radius,
            center - radius,
            center + radius,
            center + radius,
        )
        canvas.drawArc(bounds, -90f, 360f * progress.coerceIn(0f, 1f), false, arc)
        return bitmap
    }

    private fun navigationIntent(
        context: Context,
        widgetId: Int,
        requested: Int,
        size: Int,
    ): PendingIntent {
        val index = if (size == 0) 0 else (requested % size + size) % size
        val intent = Intent(context, providerClass()).apply {
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

    private fun revealIntent(context: Context, widgetId: Int): PendingIntent {
        val intent = Intent(context, providerClass()).apply {
            action = ACTION_REVEAL
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }
        return PendingIntent.getBroadcast(
            context,
            8000 + widgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"
        private const val ACTION_NAVIGATE = "com.jiuxina.ying.NAVIGATE"
        private const val ACTION_REVEAL = "com.jiuxina.ying.REVEAL"
        private const val ACTION_REFRESH_PENDING_UNDO = "com.jiuxina.ying.REFRESH_PENDING_UNDO"
        private const val ACTION_REFRESH_FLIP = "com.jiuxina.ying.REFRESH_FLIP"
        private const val EXTRA_INDEX = "index"
        private const val FLIP_REQUEST_CODE = 9107
        private const val FLIP_WINDOW_MILLIS = 400L
        internal const val FLIP_DAY_KEY = "widget_flip_day"
        internal const val PENDING_UNDO_KEY = "widget_pending_undo"
        internal const val TOAST_KEY = "widget_toast"

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

private fun envelopeOpenKey(widgetId: Int): String = "widget_envelope_open_$widgetId"

private data class WidgetRowIds(
    val root: Int,
    val icon: Int,
    val title: Int,
    val subtitle: Int,
    val days: Int,
    val unit: Int,
    val complete: Int,
)

private fun widgetRowIds(row: Int): WidgetRowIds = when (row) {
    1 -> WidgetRowIds(
        R.id.widget_row_1_root,
        R.id.widget_row_1_icon,
        R.id.widget_row_1_title,
        R.id.widget_row_1_subtitle,
        R.id.widget_row_1_days,
        R.id.widget_row_1_unit,
        R.id.widget_row_1_complete,
    )
    2 -> WidgetRowIds(
        R.id.widget_row_2_root,
        R.id.widget_row_2_icon,
        R.id.widget_row_2_title,
        R.id.widget_row_2_subtitle,
        R.id.widget_row_2_days,
        R.id.widget_row_2_unit,
        R.id.widget_row_2_complete,
    )
    3 -> WidgetRowIds(
        R.id.widget_row_3_root,
        R.id.widget_row_3_icon,
        R.id.widget_row_3_title,
        R.id.widget_row_3_subtitle,
        R.id.widget_row_3_days,
        R.id.widget_row_3_unit,
        R.id.widget_row_3_complete,
    )
    else -> WidgetRowIds(
        R.id.widget_row_4_root,
        R.id.widget_row_4_icon,
        R.id.widget_row_4_title,
        R.id.widget_row_4_subtitle,
        R.id.widget_row_4_days,
        R.id.widget_row_4_unit,
        R.id.widget_row_4_complete,
    )
}

internal fun rowLaunchRequestCode(eventId: String): Int =
    ROW_LAUNCH_REQUEST_BASE + (eventId.hashCode() and 0x0FFFFFFF)

internal fun backgroundIntent(
    context: Context,
    action: String,
    eventId: String,
): PendingIntent {
    val intent = Intent(context, es.antonborri.home_widget.HomeWidgetBackgroundReceiver::class.java).apply {
        this.action = "es.antonborri.home_widget.action.BACKGROUND"
        data = Uri.parse("ying://$action?id=${Uri.encode(eventId)}")
    }
    val requestCode = eventId.hashCode() and 0x0FFFFFFF
    return PendingIntent.getBroadcast(
        context,
        requestCode,
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}

internal data class PendingUndoPayload(
    val eventId: String,
    val title: String,
    val expiresAt: Long,
) {
    fun isExpired(): Boolean = System.currentTimeMillis() >= expiresAt
}

internal fun pendingUndoPayload(raw: String?): PendingUndoPayload? {
    if (raw.isNullOrBlank()) return null
    return try {
        val json = JSONObject(raw)
        val event = json.getJSONObject("event")
        PendingUndoPayload(
            eventId = event.getString("id"),
            title = event.optString("title", "已标记完成"),
            expiresAt = json.getLong("expiresAt"),
        )
    } catch (_: Exception) {
        null
    }
}

enum class WidgetStyle {
    card,
    sticker,
    photo,
    glass,
    polaroid,
    neon,
    pixel,
    minimal,
    envelope,
    capsule,
    crt,
    neonSign,
    pixelHealth,
    mirror,
    ;

    companion object {
        fun fromName(value: String?): WidgetStyle =
            entries.firstOrNull { it.name == value } ?: card
    }
}

internal fun parseWidgetStyle(value: String?): WidgetStyle = WidgetStyle.fromName(value)

internal data class WidgetTextColors(
    val primary: Int,
    val secondary: Int,
)

internal fun resolveTextColors(
    data: SharedPreferences,
    style: WidgetStyle,
): WidgetTextColors {
    val wallpaperTextColor = data.getInt("widget_wallpaper_text_color", -1)
    val darkSurface = style == WidgetStyle.glass ||
        style == WidgetStyle.polaroid ||
        style == WidgetStyle.minimal ||
        style == WidgetStyle.capsule
    val primary = when {
        style == WidgetStyle.neonSign -> baseColor(data)
        style == WidgetStyle.crt -> Color.rgb(201, 247, 208)
        style == WidgetStyle.pixelHealth -> Color.rgb(183, 255, 158)
        wallpaperTextColor != -1 && (style == WidgetStyle.sticker ||
            style == WidgetStyle.photo ||
            style == WidgetStyle.minimal) -> wallpaperTextColor
        darkSurface -> Color.rgb(28, 28, 30)
        else -> Color.WHITE
    }
    return WidgetTextColors(primary, withAlpha(primary, 0xBD))
}

internal fun baseColor(data: SharedPreferences): Int = try {
    data.getString("widget_color", "ff0f766e")?.toLong(16)?.toInt()
        ?: Color.rgb(15, 118, 110)
} catch (_: Exception) {
    Color.rgb(15, 118, 110)
}

internal fun accentColor(data: SharedPreferences, holiday: String): Int =
    holidayAccent(holiday) ?: baseColor(data)

internal fun countMainText(event: WidgetEvent, preset: String?, days: Long): String {
    if (preset == "weeks" && days != 0L) return "约${weekCount(days)}周"
    return abs(days).toString()
}

internal fun countUnitText(
    event: WidgetEvent,
    preset: String?,
    days: Long,
    countUp: Boolean,
): String {
    if (preset == "weeks" && days != 0L) return ""
    val verb = when (preset) {
        "remaining" -> "还有"
        "only" -> "只剩"
        "distance" -> "距离"
        "elapsed" -> "已经"
        else -> when {
            days == 0L -> "就是今天"
            countUp -> "已经"
            else -> "还有"
        }
    }
    return if (verb == "就是今天") "就是今天" else "天 · $verb"
}

internal fun urgentLevel(days: Long): Int = when {
    days < 0L -> 0
    days <= 1L -> 1
    days <= 3L -> 3
    days <= 7L -> 7
    else -> 0
}

internal fun urgentAccent(level: Int): Int? = when (level) {
    7 -> argb(0xB4, 0x53, 0x09)
    3 -> argb(0xC2, 0x41, 0x0C)
    1 -> argb(0xB9, 0x1C, 0x1C)
    else -> null
}

internal fun urgentLabel(level: Int, days: Long): String = when (level) {
    7 -> "天 · 快到了"
    3 -> "只剩${days}天"
    1 -> if (days == 0L) "就是今天" else "只剩${days}天"
    else -> ""
}

internal fun weekCount(days: Long): Long =
    (abs(days) / 7.0).roundToLong().coerceAtLeast(1)

internal fun preciseTimeText(event: WidgetEvent, nowMillis: Long): String {
    val target = event.targetTimeMillis
    val difference = if (event.isCountUp || target < nowMillis) {
        nowMillis - target
    } else {
        target - nowMillis
    }
    val totalSeconds = (difference / 1000).coerceAtLeast(0)
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    val seconds = totalSeconds % 60
    return "%02d:%02d:%02d".format(hours, minutes, seconds)
}

internal fun progressOf(event: WidgetEvent, nowMillis: Long): Float {
    val createdAt = event.createdAt
    val target = event.targetTimeMillis
    if (target <= createdAt) return 1f
    val ratio = (nowMillis - createdAt).toFloat() / (target - createdAt).toFloat()
    return ratio.coerceIn(0f, 1f)
}

private val builtInQuotes = listOf(
    "把日子过成诗",
    "今天也值得纪念",
    "慢慢来，比较快",
    "每个今天都是礼物",
    "好事会发生",
    "记得抬头看月亮",
    "认真生活的你闪闪发光",
    "向前走，别回头",
)

internal fun quoteText(event: WidgetEvent?, date: LocalDate): String {
    val note = event?.note?.trim().orEmpty()
    val dayNumber = date.toEpochDay()
    return if (note.isNotEmpty() && dayNumber % 2 == 0L) {
        note
    } else {
        builtInQuotes[Math.floorMod(dayNumber, builtInQuotes.size.toLong()).toInt()]
    }
}

private val chineseMonths = listOf(
    "",
    "正",
    "二",
    "三",
    "四",
    "五",
    "六",
    "七",
    "八",
    "九",
    "十",
    "冬",
    "腊",
)

private val chineseDays = listOf(
    "",
    "初一",
    "初二",
    "初三",
    "初四",
    "初五",
    "初六",
    "初七",
    "初八",
    "初九",
    "初十",
    "十一",
    "十二",
    "十三",
    "十四",
    "十五",
    "十六",
    "十七",
    "十八",
    "十九",
    "二十",
    "廿一",
    "廿二",
    "廿三",
    "廿四",
    "廿五",
    "廿六",
    "廿七",
    "廿八",
    "廿九",
    "三十",
)

internal fun widgetDateInfo(date: LocalDate): String = try {
    val calendar = android.icu.util.ChineseCalendar()
    calendar.time = Date.from(date.atStartOfDay(ZoneId.systemDefault()).toInstant())
    val month = calendar.get(Calendar.MONTH) + 1
    val day = calendar.get(Calendar.DAY_OF_MONTH)
    val weekday = when (date.dayOfWeek) {
        java.time.DayOfWeek.MONDAY -> "星期一"
        java.time.DayOfWeek.TUESDAY -> "星期二"
        java.time.DayOfWeek.WEDNESDAY -> "星期三"
        java.time.DayOfWeek.THURSDAY -> "星期四"
        java.time.DayOfWeek.FRIDAY -> "星期五"
        java.time.DayOfWeek.SATURDAY -> "星期六"
        java.time.DayOfWeek.SUNDAY -> "星期日"
    }
    val monthName = chineseMonths.getOrElse(month) { "" }
    val dayName = chineseDays.getOrElse(day) { "" }
    "农历${monthName}月$dayName · $weekday"
} catch (_: Exception) {
    ""
}

internal fun holidayForDate(date: LocalDate): String = when {
    date.monthValue == 1 && date.dayOfMonth == 1 -> "new_year"
    date.monthValue == 12 && date.dayOfMonth in 24..26 -> "christmas"
    isMidAutumn(date) -> "mid_autumn"
    else -> ""
}

internal fun holidayForEvent(event: WidgetEvent, date: LocalDate): String {
    val birthdayMarked = event.title.contains("生日") || event.category.contains("生日")
    if (!birthdayMarked) return ""
    val target = java.time.Instant.ofEpochMilli(event.targetDate)
        .atZone(ZoneId.systemDefault())
        .toLocalDate()
    return if (target.monthValue == date.monthValue && target.dayOfMonth == date.dayOfMonth) {
        "birthday"
    } else {
        ""
    }
}

internal fun resolveHoliday(pref: String?, date: LocalDate, event: WidgetEvent?): String {
    val dateHoliday = holidayForDate(date)
    if (dateHoliday.isNotEmpty()) return dateHoliday
    if (event != null) {
        val birthday = holidayForEvent(event, date)
        if (birthday.isNotEmpty()) return birthday
    }
    return pref?.takeIf { it in HOLIDAY_NAMES } ?: ""
}

internal fun holidayLabel(holiday: String): String = when (holiday) {
    "new_year" -> "新年"
    "christmas" -> "圣诞"
    "mid_autumn" -> "中秋"
    "birthday" -> "生日"
    else -> ""
}

internal fun holidayAccent(holiday: String): Int? = when (holiday) {
    "new_year" -> argb(225, 29, 72)
    "christmas" -> argb(22, 163, 74)
    "mid_autumn" -> argb(217, 119, 6)
    "birthday" -> argb(236, 72, 153)
    else -> null
}

internal fun contrastTextColor(argb: Int): Int {
    val red = (argb shr 16) and 0xFF
    val green = (argb shr 8) and 0xFF
    val blue = argb and 0xFF
    val luminance = 0.2126 * linearize(red) + 0.7152 * linearize(green) + 0.0722 * linearize(blue)
    return if (luminance > 0.45) argb(16, 20, 24) else 0xFFFFFFFF.toInt()
}

internal fun withAlpha(argb: Int, alpha: Int): Int =
    (argb and 0x00FFFFFF) or ((alpha and 0xFF) shl 24)

internal fun darken(argb: Int, factor: Float = 0.55f): Int {
    val red = ((argb shr 16) and 0xFF) * factor
    val green = ((argb shr 8) and 0xFF) * factor
    val blue = (argb and 0xFF) * factor
    return argb(red.toInt(), green.toInt(), blue.toInt())
}

internal fun argb(red: Int, green: Int, blue: Int): Int =
    (0xFF shl 24) or ((red and 0xFF) shl 16) or ((green and 0xFF) shl 8) or (blue and 0xFF)

private fun linearize(channel: Int): Double {
    val value = channel / 255.0
    return if (value <= 0.04045) {
        value / 12.92
    } else {
        Math.pow((value + 0.055) / 1.055, 2.4)
    }
}

private fun isMidAutumn(date: LocalDate): Boolean = try {
    val calendar = android.icu.util.ChineseCalendar()
    calendar.time = Date.from(date.atStartOfDay(ZoneId.systemDefault()).toInstant())
    calendar.get(Calendar.MONTH) == Calendar.AUGUST &&
        calendar.get(Calendar.DAY_OF_MONTH) == 15
} catch (_: Exception) {
    false
}

private val HOLIDAY_NAMES = setOf("new_year", "christmas", "mid_autumn", "birthday")

internal data class WidgetEvent(
    val id: String,
    val title: String,
    val targetDate: Long,
    val targetTimeMillis: Long,
    val category: String,
    val note: String,
    val icon: String,
    val createdAt: Long,
    val isCountUp: Boolean,
) {
    fun daysFromToday(): Long {
        val target = java.time.Instant.ofEpochMilli(targetTimeMillis)
            .atZone(ZoneId.systemDefault())
            .toLocalDate()
        return ChronoUnit.DAYS.between(LocalDate.now(), target)
    }
}

internal fun parseEvents(raw: String): List<WidgetEvent> = try {
    val array = JSONArray(raw)
    buildList {
        for (index in 0 until array.length()) {
            val value = array.getJSONObject(index)
            val targetDate = value.getLong("targetDate")
            add(
                WidgetEvent(
                    id = value.getString("id"),
                    title = value.getString("title"),
                    targetDate = targetDate,
                    targetTimeMillis = value.optLong("targetTime", targetDate),
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

private const val PREFS_NAME = "HomeWidgetPreferences"
