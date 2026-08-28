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
import android.graphics.Typeface
import android.net.Uri
import android.os.Bundle
import android.os.Build
import android.os.SystemClock
import android.text.TextPaint
import android.view.Gravity
import android.view.View
import android.widget.RemoteViews
import android.widget.Toast
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File
import java.time.LocalDate
import java.time.ZoneId
import java.util.Calendar
import java.util.Date
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.roundToLong

private const val LAUNCH_REQUEST_ROOT = 0
private const val LAUNCH_REQUEST_OPEN = 2
private const val ROW_LAUNCH_REQUEST_BASE = 0x10000000
private const val MAX_LIST_ROWS = 4

private data class WidgetBackdropSize(val width: Int, val height: Int)

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

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?,
    ) {
        refreshAll(context)
        super.onAppWidgetOptionsChanged(
            context,
            appWidgetManager,
            appWidgetId,
            newOptions,
        )
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_REFRESH_FLIP) {
            val data = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            data.edit().remove(FLIP_DAY_KEY).apply()
            refreshAll(context)
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
                val size = backdropSize(
                    context,
                    appWidgetManager.getAppWidgetOptions(widgetId),
                )
                val views = RemoteViews(
                    context.packageName,
                    R.layout.daymark_widget_undo,
                )
                applyBackdrop(
                    context,
                    views,
                    widgetData,
                    effectiveWidgetStyle(widgetData),
                    size.width,
                    size.height,
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
                    R.id.widget_root,
                    launchIntent(context, null, LAUNCH_REQUEST_ROOT),
                )
                applyContentMargin(context, views, widgetData, null)
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
            val compact = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250) < 260 ||
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 130) < 150
            val size = backdropSize(context, options)
            val style = effectiveWidgetStyle(widgetData)
            val holiday = resolveHoliday(
                widgetData.getString("widget_holiday", ""),
                LocalDate.now(),
                events.getOrNull(widgetData.getInt(perWidgetIndexKey(widgetId), 0)),
            )
            val elementStyles = parseElementStyles(
                widgetData.getString(WIDGET_ELEMENT_STYLES_KEY, ""),
            )
            val renderSpec = parseRenderSpec(
                widgetData.getString(WIDGET_RENDER_SPEC_KEY, ""),
            )
            val verticalAlign = parseVerticalAlign(
                widgetData.getString(WIDGET_VERTICAL_ALIGN_KEY, "center"),
            )
            val digitTypeface = customFontTypeface(
                context,
                widgetData,
                "widget_font_family",
                "widget_digit_font_path",
            )
            val textTypeface = customFontTypeface(
                context,
                widgetData,
                "widget_text_font_family",
                "widget_text_font_path",
            )
            if (listMode) {
                updateListWidget(
                    context,
                    views,
                    widgetData,
                    style,
                    compact,
                    size,
                    elementStyles,
                    renderSpec,
                    digitTypeface,
                    textTypeface,
                )
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
                    size,
                    elementStyles,
                    verticalAlign,
                    renderSpec,
                    digitTypeface,
                    textTypeface,
                )
            }
            applyContentMargin(context, views, widgetData, renderSpec)
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
        size: WidgetBackdropSize,
        styles: Map<String, WidgetElementStyle>,
        verticalAlign: WidgetVerticalAlign,
        renderSpec: WidgetRenderSpec?,
        digitTypeface: Typeface?,
        textTypeface: Typeface?,
    ) {
        val branch = renderSpec?.branch(compact)?.takeIf { it.mode == "single" }
            ?: fallbackRenderBranch(widgetData, styles, compact, "single", style)
        views.setOnClickPendingIntent(
            R.id.widget_root,
            launchIntent(context, null, LAUNCH_REQUEST_ROOT),
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
        applyAppearance(
            context,
            views,
            widgetData,
            compact,
            style,
            holiday,
            size.width,
            size.height,
            verticalAlign,
            branch,
        )
        if (compact) {
            views.setViewPadding(R.id.widget_content, 12, 12, 12, 12)
        }
        views.setViewVisibility(
            R.id.widget_previous,
            if (branch.element("prevButton").visible) View.VISIBLE else View.GONE,
        )
        views.setViewVisibility(
            R.id.widget_next,
            if (branch.element("nextButton").visible) View.VISIBLE else View.GONE,
        )
        views.setInt(
            R.id.widget_date_row,
            "setGravity",
            renderAlignGravity(branch.element("days").align) or Gravity.BOTTOM,
        )
        val scale = widgetFontScale(widgetData)
        val maxDaysWidth = (size.width * 0.9f).toInt().coerceAtLeast(80)
        val maxTitleWidth = (size.width * 0.85f).toInt().coerceAtLeast(80)
        val maxUnitWidth = (size.width * 0.6f).toInt().coerceAtLeast(80)
        val maxCategoryWidth = (size.width * 0.8f).toInt().coerceAtLeast(80)
        val maxNoteWidth = (size.width * 0.9f).toInt().coerceAtLeast(80)
        val maxDateInfoWidth = (size.width * 0.9f).toInt().coerceAtLeast(80)
        val maxProgressWidth = (size.width * 0.5f).toInt().coerceAtLeast(80)

        if (event == null) {
            views.setTextViewText(R.id.widget_title, "添加一个倒数日")
            setDaysText(
                context,
                views,
                "--",
                widgetData,
                compact,
                branch.element("days").size,
                branch.element("days").color,
                digitTypeface,
                maxDaysWidth,
            )
            if (!branch.element("days").visible) {
                hideDays(views)
            }
            views.setViewVisibility(R.id.widget_days_old, View.GONE)
            views.setTextViewText(R.id.widget_unit, "天")
            views.setTextViewText(R.id.widget_category, "萤")
            views.setViewVisibility(
                R.id.widget_title,
                if (branch.element("title").visible) View.VISIBLE else View.GONE,
            )
            views.setViewVisibility(
                R.id.widget_unit,
                if (branch.element("unit").visible) View.VISIBLE else View.GONE,
            )
            views.setViewVisibility(
                R.id.widget_category,
                if (branch.element("category").visible) View.VISIBLE else View.GONE,
            )
            views.setViewVisibility(R.id.widget_icon, View.GONE)
            views.setViewVisibility(R.id.widget_note, View.GONE)
            views.setViewVisibility(R.id.widget_precise, View.GONE)
            views.setViewVisibility(R.id.widget_date_info, View.GONE)
            views.setViewVisibility(R.id.widget_progress_ring, View.GONE)
            views.setViewVisibility(R.id.widget_progress_text, View.GONE)
            if (textTypeface != null) {
                setCustomText(
                    context,
                    views,
                    R.id.widget_title,
                    R.id.widget_title_custom,
                    "添加一个倒数日",
                    textTypeface,
                    branch.element("title").color,
                    (if (compact) 15f else 18f) * scale * branch.element("title").size,
                    maxTitleWidth,
                    branch.element("title").visible,
                    renderAlignGravity(branch.element("title").align),
                )
                setCustomText(
                    context,
                    views,
                    R.id.widget_unit,
                    R.id.widget_unit_custom,
                    "天",
                    textTypeface,
                    branch.element("unit").color,
                    14f * scale * branch.element("unit").size,
                    maxUnitWidth,
                    branch.element("unit").visible,
                    renderAlignGravity(branch.element("unit").align),
                )
                setCustomText(
                    context,
                    views,
                    R.id.widget_category,
                    R.id.widget_category_custom,
                    "萤",
                    textTypeface,
                    branch.element("category").color,
                    14f * scale * branch.element("category").size,
                    maxCategoryWidth,
                    branch.element("category").visible,
                    renderAlignGravity(branch.element("category").align),
                )
            }
            return
        }

        val days = event.daysFromToday()
        val countUp = event.isCountUp || days < 0
        val preset = widgetData.getString("widget_unit_text", "")
        val mystery = widgetData.getBoolean("widget_mystery_mode", false)
        val flipDay = widgetData.getInt(FLIP_DAY_KEY, -1)
        if (flipDay >= 0 && abs(days.toInt()) != flipDay && !mystery) {
            val oldText = countMainText(event, preset, flipDay.toLong())
            val oldSize = (if (flipDay.toString().length > 3) 26f else 44f) *
                scale *
                branch.element("days").size
            views.setTextViewText(R.id.widget_days_old, oldText)
            views.setTextViewTextSize(
                R.id.widget_days_old,
                2,
                oldSize,
            )
            if (digitTypeface != null && isPureDigitText(oldText)) {
                views.setViewVisibility(R.id.widget_days_old, View.GONE)
                renderDaysCustom(
                    context,
                    views,
                    oldText,
                    digitTypeface,
                    0,
                    branch.element("days").color,
                    oldSize,
                    maxDaysWidth,
                    R.id.widget_days_old_custom,
                )
            } else {
                views.setViewVisibility(R.id.widget_days_old, View.VISIBLE)
                views.setViewVisibility(R.id.widget_days_old_custom, View.GONE)
            }
            scheduleFlipRefresh(context)
        } else {
            views.setViewVisibility(R.id.widget_days_old, View.GONE)
            views.setViewVisibility(R.id.widget_days_old_custom, View.GONE)
        }
        views.setTextViewText(R.id.widget_title, event.title)
        views.setViewVisibility(
            R.id.widget_title,
            if (branch.element("title").visible) View.VISIBLE else View.GONE,
        )
        val iconVisible =
            branch.element("icon").visible && event.icon.isNotBlank()
        if (iconVisible) {
            views.setTextViewText(R.id.widget_icon, event.icon)
            views.setViewVisibility(R.id.widget_icon, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_icon, View.GONE)
        }
        setDaysText(
            context,
            views,
            if (mystery) "🕯️" else countMainText(event, preset, days),
            widgetData,
            compact,
            branch.element("days").size,
            branch.element("days").color,
            digitTypeface,
            maxDaysWidth,
        )
        if (!branch.element("days").visible) {
            hideDays(views)
        }
        views.setTextViewText(
            R.id.widget_unit,
            if (mystery) "快到了" else countUnitText(event, preset, days, countUp),
        )
        views.setViewVisibility(
            R.id.widget_unit,
            if (branch.element("unit").visible) View.VISIBLE else View.GONE,
        )
        applyUrgentHighlight(views, widgetData, days, mystery, preset, styles)
        val categoryVisible = branch.element("category").visible
        if (categoryVisible) {
            views.setTextViewText(R.id.widget_category, event.category)
            views.setViewVisibility(R.id.widget_category, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_category, View.INVISIBLE)
        }

        if (branch.element("precise").visible) {
            applyPreciseTime(views, event)
        } else {
            views.setViewVisibility(R.id.widget_precise, View.GONE)
        }
        if (branch.element("dateInfo").visible) {
            val info = widgetData.getString("widget_date_info", "")
                ?.takeIf { it.isNotBlank() }
                ?: widgetDateInfo(LocalDate.now())
            views.setTextViewText(R.id.widget_date_info, info)
            views.setViewVisibility(R.id.widget_date_info, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_date_info, View.GONE)
        }
        if (branch.element("progress").visible &&
            widgetData.getBoolean("widget_show_progress", false)
        ) {
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

        val quote = if (widgetData.getBoolean("widget_quote_mode", false)) {
            quoteText(event, LocalDate.now())
        } else {
            ""
        }
        val showNote = widgetData.getBoolean("widget_show_note", true)
        if (branch.element("note").visible &&
            (quote.isNotEmpty() || (showNote && event.note.isNotBlank()))
        ) {
            views.setTextViewText(R.id.widget_note, quote.ifEmpty { event.note })
            views.setViewVisibility(R.id.widget_note, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_note, View.GONE)
        }
        views.setOnClickPendingIntent(
            R.id.widget_date_row,
            backgroundIntent(context, "copy", event.id),
        )

        applyCustomTextPass(
            context,
            views,
            widgetData,
            event,
            branch,
            compact,
            textTypeface,
            size,
            styles,
        )
        applyCustomDaysPass(
            context,
            views,
            widgetData,
            event,
            branch,
            compact,
            digitTypeface,
            maxDaysWidth,
        )

        views.setOnClickPendingIntent(
            R.id.widget_previous,
            navigationIntent(context, widgetId, index - 1, events.size),
        )
        views.setOnClickPendingIntent(
            R.id.widget_next,
            navigationIntent(context, widgetId, index + 1, events.size),
        )
    }

    private fun backdropSize(
        context: Context,
        options: Bundle?,
    ): WidgetBackdropSize {
        val density = context.resources.displayMetrics.density
        val minWidthDp = options?.getInt(
            AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH,
            250,
        ) ?: 250
        val minHeightDp = options?.getInt(
            AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT,
            130,
        ) ?: 130
        val maxWidthDp = options?.getInt(
            AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH,
            minWidthDp,
        ) ?: minWidthDp
        val maxHeightDp = options?.getInt(
            AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT,
            minHeightDp,
        ) ?: minHeightDp
        val width = (maxWidthDp * density).toInt().coerceIn(320, 1600)
        val height = (maxHeightDp * density).toInt().coerceIn(240, 1600)
        return WidgetBackdropSize(width, height)
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
        compact: Boolean,
        size: WidgetBackdropSize,
        styles: Map<String, WidgetElementStyle>,
        renderSpec: WidgetRenderSpec?,
        digitTypeface: Typeface?,
        textTypeface: Typeface?,
    ) {
        val branch = renderSpec?.branch(compact)?.takeIf { it.mode == "list" }
            ?: fallbackRenderBranch(widgetData, styles, compact, "list", style)
        views.setOnClickPendingIntent(
            R.id.widget_root,
            launchIntent(context, null, LAUNCH_REQUEST_ROOT),
        )
        applyBackdrop(context, views, widgetData, style, size.width, size.height)
        val events = parseEvents(widgetData.getString("widget_events", "[]") ?: "[]")
        val scale = widgetFontScale(widgetData)
        val mystery = widgetData.getBoolean("widget_mystery_mode", false)
        val preset = widgetData.getString("widget_unit_text", "")
        val showCategory = widgetData.getBoolean("widget_show_category", true)
        val showPrecise = widgetData.getBoolean("widget_show_precise_time", false)
        views.setTextColor(
            R.id.widget_list_header,
            branch.element("listHeader").color,
        )
        views.setTextViewTextSize(
            R.id.widget_list_header,
            2,
            13f * scale * branch.element("listHeader").size,
        )
        views.setInt(
            R.id.widget_list_header,
            "setGravity",
            renderAlignGravity(branch.element("listHeader").align),
        )
        views.setViewVisibility(
            R.id.widget_list_header,
            if (branch.element("listHeader").visible) View.VISIBLE else View.GONE,
        )
        setCustomText(
            context,
            views,
            R.id.widget_list_header,
            R.id.widget_list_header_custom,
            "事件列表",
            textTypeface,
            branch.element("listHeader").color,
            13f * scale * branch.element("listHeader").size,
            (size.width * 0.9f).toInt().coerceAtLeast(80),
            branch.element("listHeader").visible,
            renderAlignGravity(branch.element("listHeader").align),
            branch.element("listHeader").weight,
        )
        var visibleCount = 0
        val maxRows = if (compact) 2 else MAX_LIST_ROWS
        repeat(maxRows) { rowIndex ->
            val ids = widgetRowIds(rowIndex + 1)
            val event = events.getOrNull(rowIndex)
            if (event == null) {
                views.setViewVisibility(ids.root, View.GONE)
                return@repeat
            }
            visibleCount++
            views.setViewVisibility(ids.root, View.VISIBLE)
            views.setTextViewText(ids.title, event.title)
            views.setTextColor(
                ids.title,
                branch.element("rowTitle").color,
            )
            views.setTextColor(
                ids.days,
                branch.element("rowDays").color,
            )
            views.setTextColor(
                ids.unit,
                branch.element("rowUnit").color,
            )
            views.setTextColor(
                ids.subtitle,
                branch.element("rowSubtitle").color,
            )
            views.setTextViewTextSize(
                ids.title,
                2,
                14f * scale * branch.element("rowTitle").size,
            )
            views.setTextViewTextSize(
                ids.days,
                2,
                18f * scale * branch.element("rowDays").size,
            )
            views.setTextViewTextSize(
                ids.unit,
                2,
                11f * scale * branch.element("rowUnit").size,
            )
            views.setTextViewTextSize(
                ids.subtitle,
                2,
                11f * scale * branch.element("rowSubtitle").size,
            )
            views.setInt(
                ids.title,
                "setGravity",
                renderAlignGravity(branch.element("rowTitle").align),
            )
            views.setInt(
                ids.subtitle,
                "setGravity",
                renderAlignGravity(branch.element("rowSubtitle").align),
            )
            views.setViewVisibility(
                ids.title,
                if (branch.element("rowTitle").visible) View.VISIBLE else View.GONE,
            )
            views.setViewVisibility(
                ids.days,
                if (branch.element("rowDays").visible) View.VISIBLE else View.GONE,
            )
            views.setViewVisibility(
                ids.unit,
                if (branch.element("rowUnit").visible) View.VISIBLE else View.GONE,
            )
            val iconVisible =
                branch.element("icon").visible && event.icon.isNotBlank()
            if (iconVisible) {
                views.setTextViewText(ids.icon, event.icon)
                views.setTextColor(
                    ids.icon,
                    branch.element("icon").color,
                )
                views.setTextViewTextSize(
                    ids.icon,
                    2,
                    16f * scale * branch.element("icon").size,
                )
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
                    if (customElementColor(styles["rowDays"]) == null) {
                        views.setTextColor(ids.days, accent)
                    }
                    if (customElementColor(styles["rowUnit"]) == null) {
                        views.setTextColor(ids.unit, accent)
                    }
                    if (preset != "weeks") {
                        views.setTextViewText(ids.unit, urgentLabel(level, days))
                    }
                }
            }
            val subtitle = buildList {
                if (showCategory) add(event.category)
                if (showPrecise) add(preciseTimeText(event, System.currentTimeMillis()))
            }.joinToString(" · ")
            if (branch.element("rowSubtitle").visible && subtitle.isNotEmpty()) {
                views.setTextViewText(ids.subtitle, subtitle)
                views.setViewVisibility(ids.subtitle, View.VISIBLE)
            } else {
                views.setViewVisibility(ids.subtitle, View.GONE)
            }
            applyRowCustomText(
                context,
                views,
                ids,
                event,
                widgetData,
                branch,
                scale,
                size,
                styles,
                digitTypeface,
                textTypeface,
                mystery,
                preset,
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
        views.setTextColor(
            R.id.widget_empty,
            branch.element("empty").color,
        )
        views.setTextViewTextSize(
            R.id.widget_empty,
            2,
            15f * scale * branch.element("empty").size,
        )
        views.setInt(
            R.id.widget_empty,
            "setGravity",
            renderAlignGravity(branch.element("empty").align),
        )
        views.setViewVisibility(
            R.id.widget_empty,
            if (branch.element("empty").visible && visibleCount == 0) {
                View.VISIBLE
            } else {
                View.GONE
            },
        )
        setCustomText(
            context,
            views,
            R.id.widget_empty,
            R.id.widget_empty_custom,
            "添加一个倒数日",
            textTypeface,
            branch.element("empty").color,
            15f * scale * branch.element("empty").size,
            (size.width * 0.9f).toInt().coerceAtLeast(80),
            branch.element("empty").visible && visibleCount == 0,
            renderAlignGravity(branch.element("empty").align),
            branch.element("empty").weight,
        )
    }

    private fun applyRowCustomText(
        context: Context,
        views: RemoteViews,
        ids: WidgetRowIds,
        event: WidgetEvent,
        data: SharedPreferences,
        branch: WidgetRenderBranch,
        scale: Float,
        size: WidgetBackdropSize,
        styles: Map<String, WidgetElementStyle>,
        digitTypeface: Typeface?,
        textTypeface: Typeface?,
        mystery: Boolean,
        preset: String?,
    ) {
        val days = event.daysFromToday()
        val countUp = event.isCountUp || days < 0
        val daysText = if (mystery) "🕯️" else countMainText(event, preset, days)
        val urgentLevel = if (data.getBoolean("widget_urgent_highlight", false) &&
            !mystery
        ) {
            urgentLevel(days)
        } else {
            0
        }
        val urgentAccent = urgentAccent(urgentLevel)
        val unitText = if (mystery) {
            "快到了"
        } else if (urgentAccent != null && preset != "weeks") {
            urgentLabel(urgentLevel, days)
        } else {
            countUnitText(event, preset, days, countUp)
        }
        val daysColor = if (customElementColor(styles["rowDays"]) == null &&
            urgentAccent != null
        ) {
            urgentAccent
        } else {
            branch.element("rowDays").color
        }
        val unitColor = if (customElementColor(styles["rowUnit"]) == null &&
            urgentAccent != null
        ) {
            urgentAccent
        } else {
            branch.element("rowUnit").color
        }
        val subtitle = buildList {
            if (data.getBoolean("widget_show_category", true)) add(event.category)
            if (data.getBoolean("widget_show_precise_time", false)) {
                add(preciseTimeText(event, System.currentTimeMillis()))
            }
        }.joinToString(" · ")
        val maxTitle = (size.width * 0.5f).toInt().coerceAtLeast(80)
        val maxSubtitle = maxTitle
        val maxDays = (size.width * 0.3f).toInt().coerceAtLeast(60)
        val maxUnit = (size.width * 0.25f).toInt().coerceAtLeast(50)
        setCustomText(
            context,
            views,
            ids.title,
            ids.titleCustom,
            event.title,
            textTypeface,
            branch.element("rowTitle").color,
            14f * scale * branch.element("rowTitle").size,
            maxTitle,
            branch.element("rowTitle").visible,
            renderAlignGravity(branch.element("rowTitle").align),
            branch.element("rowTitle").weight,
        )
        setCustomText(
            context,
            views,
            ids.subtitle,
            ids.subtitleCustom,
            subtitle,
            textTypeface,
            branch.element("rowSubtitle").color,
            11f * scale * branch.element("rowSubtitle").size,
            maxSubtitle,
            branch.element("rowSubtitle").visible && subtitle.isNotEmpty(),
            renderAlignGravity(branch.element("rowSubtitle").align),
            branch.element("rowSubtitle").weight,
        )
        setCustomText(
            context,
            views,
            ids.days,
            ids.daysCustom,
            daysText,
            digitTypeface,
            daysColor,
            18f * scale * branch.element("rowDays").size,
            maxDays,
            branch.element("rowDays").visible,
            renderAlignGravity(branch.element("rowDays").align),
            branch.element("rowDays").weight,
        )
        setCustomText(
            context,
            views,
            ids.unit,
            ids.unitCustom,
            unitText,
            textTypeface,
            unitColor,
            11f * scale * branch.element("rowUnit").size,
            maxUnit,
            branch.element("rowUnit").visible && unitText.isNotEmpty(),
            renderAlignGravity(branch.element("rowUnit").align),
            branch.element("rowUnit").weight,
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
        width: Int,
        height: Int,
        verticalAlign: WidgetVerticalAlign,
        branch: WidgetRenderBranch,
    ) {
        applyBackdrop(context, views, data, style, width, height)

        val holidayVisible =
            branch.element("holidayBadge").visible && holiday.isNotEmpty()
        applyBoldApprox(
            views,
            R.id.widget_holiday_badge,
            branch.element("holidayBadge").weight,
        )
        if (holidayVisible) {
            views.setTextViewText(R.id.widget_holiday_badge, holidayLabel(holiday))
            views.setTextColor(
                R.id.widget_holiday_badge,
                branch.element("holidayBadge").color,
            )
            views.setTextViewTextSize(
                R.id.widget_holiday_badge,
                2,
                11f * widgetFontScale(data) * branch.element("holidayBadge").size,
            )
            views.setViewVisibility(R.id.widget_holiday_badge, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_holiday_badge, View.GONE)
        }

        views.setTextColor(
            R.id.widget_title,
            branch.element("title").color,
        )
        views.setTextColor(
            R.id.widget_unit,
            branch.element("unit").color,
        )
        views.setTextColor(
            R.id.widget_category,
            branch.element("category").color,
        )
        views.setTextColor(
            R.id.widget_note,
            branch.element("note").color,
        )
        views.setTextColor(
            R.id.widget_icon,
            branch.element("icon").color,
        )
        views.setTextColor(
            R.id.widget_precise,
            branch.element("precise").color,
        )
        views.setTextColor(
            R.id.widget_date_info,
            branch.element("dateInfo").color,
        )
        views.setTextColor(
            R.id.widget_progress_text,
            branch.element("progress").color,
        )
        listOf(
            R.id.widget_days,
            R.id.widget_days_mono,
            R.id.widget_days_pixel,
            R.id.widget_days_hand,
        ).forEach { id ->
            views.setTextColor(
                id,
                branch.element("days").color,
            )
        }
        views.setInt(
            R.id.widget_previous,
            "setColorFilter",
            branch.element("prevButton").color,
        )
        views.setInt(
            R.id.widget_next,
            "setColorFilter",
            branch.element("nextButton").color,
        )
        val scale = widgetFontScale(data)
        views.setTextViewTextSize(
            R.id.widget_title,
            2,
            (if (compact) 15f else 18f) * scale * branch.element("title").size,
        )
        views.setTextViewTextSize(
            R.id.widget_note,
            2,
            14f * scale * branch.element("note").size,
        )
        views.setTextViewTextSize(
            R.id.widget_category,
            2,
            14f * scale * branch.element("category").size,
        )
        views.setTextViewTextSize(
            R.id.widget_unit,
            2,
            14f * scale * branch.element("unit").size,
        )
        views.setTextViewTextSize(
            R.id.widget_precise,
            2,
            14f * scale * branch.element("precise").size,
        )
        views.setTextViewTextSize(
            R.id.widget_date_info,
            2,
            12f * scale * branch.element("dateInfo").size,
        )
        views.setTextViewTextSize(
            R.id.widget_progress_text,
            2,
            13f * scale * branch.element("progress").size,
        )
        views.setTextViewTextSize(
            R.id.widget_icon,
            2,
            18f * scale * branch.element("icon").size,
        )
        views.setInt(
            R.id.widget_category,
            "setGravity",
            renderAlignGravity(branch.element("category").align),
        )
        views.setInt(
            R.id.widget_title,
            "setGravity",
            renderAlignGravity(branch.element("title").align),
        )
        views.setInt(
            R.id.widget_note,
            "setGravity",
            renderAlignGravity(branch.element("note").align),
        )
        views.setInt(
            R.id.widget_precise,
            "setGravity",
            renderAlignGravity(branch.element("precise").align),
        )
        views.setInt(
            R.id.widget_date_info,
            "setGravity",
            renderAlignGravity(branch.element("dateInfo").align),
        )
        views.setInt(
            R.id.widget_content,
            "setGravity",
            widgetVerticalGravity(verticalAlign),
        )
    }

    private fun applyUrgentHighlight(
        views: RemoteViews,
        data: SharedPreferences,
        days: Long,
        mystery: Boolean,
        preset: String?,
        styles: Map<String, WidgetElementStyle>,
    ) {
        if (!data.getBoolean("widget_urgent_highlight", false) || mystery) return
        val level = urgentLevel(days)
        val accent = urgentAccent(level) ?: return
        if (customElementColor(styles["days"]) == null) {
            listOf(
                R.id.widget_days,
                R.id.widget_days_mono,
                R.id.widget_days_pixel,
                R.id.widget_days_hand,
            ).forEach { id -> views.setTextColor(id, accent) }
        }
        if (customElementColor(styles["unit"]) == null) {
            views.setTextColor(R.id.widget_unit, accent)
        }
        if (preset != "weeks") {
            views.setTextViewText(R.id.widget_unit, urgentLabel(level, days))
        }
    }

    private fun applyBackdrop(
        context: Context,
        views: RemoteViews,
        data: SharedPreferences,
        style: WidgetStyle,
        width: Int,
        height: Int,
    ) {
        views.setInt(
            R.id.widget_root,
            "setBackgroundResource",
            R.drawable.daymark_widget_clip,
        )
        views.setBoolean(R.id.widget_root, "setClipToOutline", true)
        val accent = accentColor(data, "")
        val backdrop = buildBackdrop(
            context,
            data,
            style,
            accent,
            data.getString("widget_background_path", ""),
            width,
            height,
        )
        if (backdrop == null) {
            views.setViewVisibility(R.id.widget_backdrop, View.GONE)
        } else {
            views.setViewVisibility(R.id.widget_backdrop, View.VISIBLE)
            views.setImageViewBitmap(R.id.widget_backdrop, backdrop)
        }
        val scrimVisible = style == WidgetStyle.sticker || style == WidgetStyle.photo
        if (scrimVisible) {
            val density = context.resources.displayMetrics.density
            views.setImageViewBitmap(
                R.id.widget_scrim,
                scrimBitmap(width, height, 10f * density),
            )
            views.setViewVisibility(R.id.widget_scrim, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_scrim, View.GONE)
        }
    }

    private fun applyContentMargin(
        context: Context,
        views: RemoteViews,
        data: SharedPreferences,
        renderSpec: WidgetRenderSpec?,
    ) {
        val marginDp = renderSpec?.contentMargin
            ?: data.getFloat("widget_content_margin", 16f)
        val density = context.resources.displayMetrics.density
        val margin = (marginDp * density).toInt().coerceAtLeast(0)
        views.setViewPadding(R.id.widget_content, margin, margin, margin, margin)
    }

    private fun buildBackdrop(
        context: Context,
        data: SharedPreferences,
        style: WidgetStyle,
        accent: Int,
        photoPath: String?,
        width: Int,
        height: Int,
    ): Bitmap? {
        val density = context.resources.displayMetrics.density
        return when (style) {
            WidgetStyle.card -> roundedRectBitmap(
                width,
                height,
                baseColor(data),
                10f * density,
            )
            WidgetStyle.sticker -> null
            WidgetStyle.photo -> {
                loadPhotoBitmap(photoPath, 10f * density, width, height)
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

    private fun scrimBitmap(width: Int, height: Int, radius: Float): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val clip = Path().apply {
            addRoundRect(
                0f,
                0f,
                width.toFloat(),
                height.toFloat(),
                radius,
                radius,
                Path.Direction.CW,
            )
        }
        canvas.clipPath(clip)
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

    private fun loadPhotoBitmap(
        path: String?,
        radius: Float,
        width: Int,
        height: Int,
    ): Bitmap? {
        if (path.isNullOrBlank() || width <= 0 || height <= 0) return null
        val file = File(path)
        if (!file.exists()) return null
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            var sampleSize = 1
            val targetLongEdge = max(width, height)
            while (maxOf(bounds.outWidth, bounds.outHeight) / (sampleSize * 2) >=
                targetLongEdge * 2
            ) {
                sampleSize *= 2
            }
            val options = BitmapFactory.Options().apply {
                inSampleSize = sampleSize
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }
            val source = BitmapFactory.decodeFile(path, options) ?: return null
            val output = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(output)
            val clip = Path().apply {
                addRoundRect(
                    0f,
                    0f,
                    width.toFloat(),
                    height.toFloat(),
                    radius,
                    radius,
                    Path.Direction.CW,
                )
            }
            canvas.clipPath(clip)
            val scale = maxOf(
                width.toFloat() / source.width,
                height.toFloat() / source.height,
            )
            val matrix = Matrix().apply {
                setScale(scale, scale)
                postTranslate(
                    (width.toFloat() - source.width * scale) / 2f,
                    (height.toFloat() - source.height * scale) / 2f,
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

    private fun customFontTypeface(
        context: Context,
        data: SharedPreferences,
        selectionKey: String,
        pathKey: String,
    ): Typeface? {
        val selection = data.getString(selectionKey, "system") ?: "system"
        val kind = customFontSelectionKind(selection)
        if (kind == null) return null
        val path = data.getString(pathKey, "") ?: ""
        if (path.isBlank()) return null
        return try {
            val file = File(path)
            if (file.exists() && file.isFile) Typeface.createFromFile(file) else null
        } catch (_: Exception) {
            null
        }
    }

    private fun renderCustomTextBitmap(
        context: Context,
        text: String,
        typeface: Typeface,
        color: Int,
        textSizeSp: Float,
        maxWidthPx: Int,
        align: Int,
    ): Bitmap {
        val density = context.resources.displayMetrics.density
        val paint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            this.typeface = typeface
            textSize = textSizeSp * density
            this.color = color
            setShadowLayer(2f * density, 0f, 1f * density, 0x40000000)
        }
        val ellipsized = ellipsizeText(text, paint, maxWidthPx)
        val measured = paint.measureText(ellipsized)
        val width = minOf(measured.toInt() + 1, maxWidthPx.coerceAtLeast(1)).coerceAtLeast(1)
        val height = (paint.fontMetrics.bottom - paint.fontMetrics.top).toInt() + 2
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val x = when (align) {
            Gravity.CENTER_HORIZONTAL, Gravity.CENTER -> (width - measured) / 2f
            Gravity.END, Gravity.RIGHT -> width - measured
            else -> 0f
        }
        canvas.drawText(ellipsized, x, -paint.fontMetrics.top, paint)
        return bitmap
    }

    private fun ellipsizeText(text: String, paint: TextPaint, maxWidthPx: Int): String {
        if (maxWidthPx <= 0 || paint.measureText(text) <= maxWidthPx) return text
        var end = text.length
        while (end > 0 && paint.measureText(text.substring(0, end) + "…") > maxWidthPx) {
            end--
        }
        return text.substring(0, end) + "…"
    }

    private fun setCustomText(
        context: Context,
        views: RemoteViews,
        textViewId: Int,
        imageViewId: Int,
        text: String,
        typeface: Typeface?,
        color: Int,
        sizeSp: Float,
        maxWidthPx: Int,
        visible: Boolean,
        align: Int,
        weight: Int = 0,
    ) {
        val effectiveTypeface = resolveTextTypeface(typeface, weight)
        val renderBitmap = effectiveTypeface != null
        views.setTextViewText(textViewId, text)
        views.setTextColor(textViewId, color)
        views.setTextViewTextSize(textViewId, 2, sizeSp)
        views.setInt(textViewId, "setGravity", align)
        views.setViewVisibility(
            textViewId,
            if (!visible || renderBitmap) View.GONE else View.VISIBLE,
        )
        views.setViewVisibility(
            imageViewId,
            if (!visible || !renderBitmap) View.GONE else View.VISIBLE,
        )
        if (effectiveTypeface != null && visible) {
            val bitmap = renderCustomTextBitmap(
                context,
                text,
                effectiveTypeface,
                color,
                sizeSp,
                maxWidthPx,
                align,
            )
            views.setImageViewBitmap(imageViewId, bitmap)
            views.setContentDescription(imageViewId, text)
        }
    }

    private fun resolveTextTypeface(
        custom: Typeface?,
        weight: Int,
    ): Typeface? {
        if (weight <= 0) return custom
        val base = custom ?: Typeface.DEFAULT
        return if (Build.VERSION.SDK_INT >= 28) {
            Typeface.create(base, weight, false)
        } else {
            Typeface.create(base, if (weight >= 600) Typeface.BOLD else Typeface.NORMAL)
        }
    }

    private fun applyBoldApprox(
        views: RemoteViews,
        viewId: Int,
        weight: Int,
    ) {
        if (weight < 600 || Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        // Chronometer does not expose setFontVariationSettings through
        // RemoteViews; applying it breaks the whole widget inflation.
        if (viewId == R.id.widget_precise) return
        views.setString(viewId, "setFontVariationSettings", "'wght' 700")
    }

    private fun renderDaysCustom(
        context: Context,
        views: RemoteViews,
        text: String,
        typeface: Typeface?,
        weight: Int,
        color: Int,
        sizeSp: Float,
        maxWidthPx: Int,
        imageViewId: Int,
    ) {
        val effectiveTypeface = resolveTextTypeface(typeface, weight)
        if (effectiveTypeface == null || !isPureDigitText(text)) {
            views.setViewVisibility(imageViewId, View.GONE)
            return
        }
        val bitmap = renderCustomTextBitmap(
            context,
            text,
            effectiveTypeface,
            color,
            sizeSp,
            maxWidthPx,
            Gravity.START,
        )
        views.setImageViewBitmap(imageViewId, bitmap)
        views.setContentDescription(imageViewId, text)
        views.setViewVisibility(imageViewId, View.VISIBLE)
    }

    private fun setDaysText(
        context: Context,
        views: RemoteViews,
        text: String,
        data: SharedPreferences,
        compact: Boolean,
        elementScale: Float = 1f,
        color: Int = 0xFFFFFFFF.toInt(),
        digitTypeface: Typeface? = null,
        maxWidthPx: Int = 320,
    ) {
        val scale = widgetFontScale(data)
        val size = if (text.length > 3) {
            (if (compact) 22f else 26f) * scale * elementScale
        } else {
            (if (compact) 32f else 44f) * scale * elementScale
        }
        val useCustom = digitTypeface != null && isPureDigitText(text)
        val selected = if (useCustom) {
            R.id.widget_days_custom
        } else {
            when {
                data.getString("widget_font_family", "system") == "mono" ->
                    R.id.widget_days_mono
                data.getString("widget_font_family", "system") == "pixel" ->
                    R.id.widget_days_pixel
                data.getString("widget_font_family", "system") == "hand" ->
                    R.id.widget_days_hand
                else -> R.id.widget_days
            }
        }
        listOf(
            R.id.widget_days,
            R.id.widget_days_mono,
            R.id.widget_days_pixel,
            R.id.widget_days_hand,
            R.id.widget_days_custom,
        ).forEach { id ->
            views.setViewVisibility(id, if (id == selected) View.VISIBLE else View.GONE)
            if (id == selected && id != R.id.widget_days_custom) {
                views.setTextViewText(id, text)
                views.setTextViewTextSize(id, 2, size)
            }
        }
        if (useCustom) {
            renderDaysCustom(
                context,
                views,
                text,
                digitTypeface,
                0,
                color,
                size,
                maxWidthPx,
                R.id.widget_days_custom,
            )
        }
    }

    private fun hideDays(views: RemoteViews) {
        listOf(
            R.id.widget_days,
            R.id.widget_days_mono,
            R.id.widget_days_pixel,
            R.id.widget_days_hand,
            R.id.widget_days_custom,
            R.id.widget_days_old,
            R.id.widget_days_old_custom,
        ).forEach { id -> views.setViewVisibility(id, View.GONE) }
    }

    private fun applyCustomTextPass(
        context: Context,
        views: RemoteViews,
        data: SharedPreferences,
        event: WidgetEvent,
        branch: WidgetRenderBranch,
        compact: Boolean,
        textTypeface: Typeface?,
        size: WidgetBackdropSize,
        styles: Map<String, WidgetElementStyle>,
    ) {
        val needsPass = textTypeface != null ||
            listOf(
                "title",
                "category",
                "unit",
                "note",
                "dateInfo",
                "progress",
                "precise",
                "holidayBadge",
            ).any { branch.element(it).weight > 0 }
        if (!needsPass) return
        val scale = widgetFontScale(data)
        val days = event.daysFromToday()
        val countUp = event.isCountUp || days < 0
        val preset = data.getString("widget_unit_text", "")
        val mystery = data.getBoolean("widget_mystery_mode", false)
        val urgentLevel = if (data.getBoolean("widget_urgent_highlight", false) &&
            !mystery
        ) {
            urgentLevel(days)
        } else {
            0
        }
        val urgentAccent = urgentAccent(urgentLevel)
        val title = event.title
        val category = event.category
        val unitText = if (mystery) {
            "快到了"
        } else if (urgentAccent != null && preset != "weeks") {
            urgentLabel(urgentLevel, days)
        } else {
            countUnitText(event, preset, days, countUp)
        }
        val unitColor = when {
            customElementColor(styles["unit"]) != null ->
                branch.element("unit").color
            urgentAccent != null -> urgentAccent
            else -> branch.element("unit").color
        }
        val unitVisible = branch.element("unit").visible && unitText.isNotEmpty()
        val quote = if (data.getBoolean("widget_quote_mode", false)
        ) {
            quoteText(event, LocalDate.now())
        } else {
            ""
        }
        val showNote = data.getBoolean("widget_show_note", true)
        val noteText = if (quote.isNotEmpty()) {
            quote
        } else if (showNote) {
            event.note
        } else {
            ""
        }
        val noteVisible =
            branch.element("note").visible && noteText.isNotBlank()
        val dateInfoText = data.getString("widget_date_info", "")
            ?.takeIf { it.isNotBlank() }
            ?: widgetDateInfo(LocalDate.now())
        val progressText = if (branch.element("progress").visible &&
            data.getBoolean("widget_show_progress", false)
        ) {
            "${(progressOf(event, System.currentTimeMillis()) * 100).toInt()}%"
        } else {
            ""
        }
        val maxTitle = (size.width * 0.85f).toInt().coerceAtLeast(80)
        val maxCategory = (size.width * 0.8f).toInt().coerceAtLeast(80)
        val maxUnit = (size.width * 0.6f).toInt().coerceAtLeast(80)
        val maxNote = (size.width * 0.9f).toInt().coerceAtLeast(80)
        val maxDateInfo = (size.width * 0.9f).toInt().coerceAtLeast(80)
        val maxProgress = (size.width * 0.5f).toInt().coerceAtLeast(80)
        setCustomText(
            context,
            views,
            R.id.widget_title,
            R.id.widget_title_custom,
            title,
            textTypeface,
            branch.element("title").color,
            (if (compact) 15f else 18f) * scale * branch.element("title").size,
            maxTitle,
            branch.element("title").visible,
            renderAlignGravity(branch.element("title").align),
            branch.element("title").weight,
        )
        setCustomText(
            context,
            views,
            R.id.widget_category,
            R.id.widget_category_custom,
            category,
            textTypeface,
            branch.element("category").color,
            14f * scale * branch.element("category").size,
            maxCategory,
            branch.element("category").visible,
            renderAlignGravity(branch.element("category").align),
            branch.element("category").weight,
        )
        setCustomText(
            context,
            views,
            R.id.widget_unit,
            R.id.widget_unit_custom,
            unitText,
            textTypeface,
            unitColor,
            14f * scale * branch.element("unit").size,
            maxUnit,
            unitVisible,
            renderAlignGravity(branch.element("unit").align),
            branch.element("unit").weight,
        )
        setCustomText(
            context,
            views,
            R.id.widget_note,
            R.id.widget_note_custom,
            noteText,
            textTypeface,
            branch.element("note").color,
            14f * scale * branch.element("note").size,
            maxNote,
            noteVisible,
            renderAlignGravity(branch.element("note").align),
            branch.element("note").weight,
        )
        setCustomText(
            context,
            views,
            R.id.widget_date_info,
            R.id.widget_date_info_custom,
            dateInfoText,
            textTypeface,
            branch.element("dateInfo").color,
            12f * scale * branch.element("dateInfo").size,
            maxDateInfo,
            branch.element("dateInfo").visible,
            renderAlignGravity(branch.element("dateInfo").align),
            branch.element("dateInfo").weight,
        )
        setCustomText(
            context,
            views,
            R.id.widget_progress_text,
            R.id.widget_progress_text_custom,
            progressText,
            textTypeface,
            branch.element("progress").color,
            13f * scale * branch.element("progress").size,
            maxProgress,
            progressText.isNotEmpty(),
            renderAlignGravity(branch.element("progress").align),
            branch.element("progress").weight,
        )
        applyBoldApprox(
            views,
            R.id.widget_precise,
            branch.element("precise").weight,
        )
    }

    private fun applyCustomDaysPass(
        context: Context,
        views: RemoteViews,
        data: SharedPreferences,
        event: WidgetEvent,
        branch: WidgetRenderBranch,
        compact: Boolean,
        digitTypeface: Typeface?,
        maxWidthPx: Int,
    ) {
        if (digitTypeface == null && branch.element("days").weight <= 0) return
        val days = event.daysFromToday()
        val preset = data.getString("widget_unit_text", "")
        val mystery = data.getBoolean("widget_mystery_mode", false)
        val text = if (mystery) "🕯️" else countMainText(event, preset, days)
        if (!isPureDigitText(text)) return
        val urgentLevel = if (data.getBoolean("widget_urgent_highlight", false) &&
            !mystery
        ) {
            urgentLevel(days)
        } else {
            0
        }
        val urgentAccent = urgentAccent(urgentLevel)
        val color = when {
            urgentAccent != null -> urgentAccent
            else -> branch.element("days").color
        }
        val scale = widgetFontScale(data)
        val size = if (text.length > 3) {
            (if (compact) 22f else 26f) * scale * branch.element("days").size
        } else {
            (if (compact) 32f else 44f) * scale * branch.element("days").size
        }
        listOf(
            R.id.widget_days,
            R.id.widget_days_mono,
            R.id.widget_days_pixel,
            R.id.widget_days_hand,
        ).forEach { id -> views.setViewVisibility(id, View.GONE) }
        renderDaysCustom(
            context,
            views,
            text,
            digitTypeface,
            branch.element("days").weight,
            color,
            size,
            maxWidthPx,
            R.id.widget_days_custom,
        )
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

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"
        private const val ACTION_NAVIGATE = "com.jiuxina.ying.NAVIGATE"
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

private data class WidgetRowIds(
    val root: Int,
    val icon: Int,
    val title: Int,
    val titleCustom: Int,
    val subtitle: Int,
    val subtitleCustom: Int,
    val days: Int,
    val daysCustom: Int,
    val unit: Int,
    val unitCustom: Int,
)

private fun widgetRowIds(row: Int): WidgetRowIds = when (row) {
    1 -> WidgetRowIds(
        R.id.widget_row_1_root,
        R.id.widget_row_1_icon,
        R.id.widget_row_1_title,
        R.id.widget_row_1_title_custom,
        R.id.widget_row_1_subtitle,
        R.id.widget_row_1_subtitle_custom,
        R.id.widget_row_1_days,
        R.id.widget_row_1_days_custom,
        R.id.widget_row_1_unit,
        R.id.widget_row_1_unit_custom,
    )
    2 -> WidgetRowIds(
        R.id.widget_row_2_root,
        R.id.widget_row_2_icon,
        R.id.widget_row_2_title,
        R.id.widget_row_2_title_custom,
        R.id.widget_row_2_subtitle,
        R.id.widget_row_2_subtitle_custom,
        R.id.widget_row_2_days,
        R.id.widget_row_2_days_custom,
        R.id.widget_row_2_unit,
        R.id.widget_row_2_unit_custom,
    )
    3 -> WidgetRowIds(
        R.id.widget_row_3_root,
        R.id.widget_row_3_icon,
        R.id.widget_row_3_title,
        R.id.widget_row_3_title_custom,
        R.id.widget_row_3_subtitle,
        R.id.widget_row_3_subtitle_custom,
        R.id.widget_row_3_days,
        R.id.widget_row_3_days_custom,
        R.id.widget_row_3_unit,
        R.id.widget_row_3_unit_custom,
    )
    else -> WidgetRowIds(
        R.id.widget_row_4_root,
        R.id.widget_row_4_icon,
        R.id.widget_row_4_title,
        R.id.widget_row_4_title_custom,
        R.id.widget_row_4_subtitle,
        R.id.widget_row_4_subtitle_custom,
        R.id.widget_row_4_days,
        R.id.widget_row_4_days_custom,
        R.id.widget_row_4_unit,
        R.id.widget_row_4_unit_custom,
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
        style == WidgetStyle.polaroid
    val primary = when {
        wallpaperTextColor != -1 && (style == WidgetStyle.sticker ||
            style == WidgetStyle.photo) -> wallpaperTextColor
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

internal fun customFontSelectionKind(selection: String?): String? = when {
    selection?.startsWith("catalog:") == true -> "catalog"
    selection?.startsWith("local:") == true -> "local"
    else -> null
}

internal fun isPureDigitText(text: String): Boolean =
    text.isNotEmpty() && text.all { it.isDigit() }

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

private const val PREFS_NAME = "HomeWidgetPreferences"
