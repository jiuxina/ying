package com.jiuxina.ying

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
import android.graphics.Paint
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.io.File
import java.time.LocalDate
import java.time.ZoneId
import java.time.temporal.ChronoUnit
import java.util.Calendar
import java.util.Date

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
            val style = parseWidgetStyle(widgetData.getString("widget_style", "card"))
            val holiday = resolveHoliday(
                widgetData.getString("widget_holiday", ""),
                LocalDate.now(),
                event,
            )
            applyAppearance(context, views, widgetData, compact, style, holiday)
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

    private fun applyAppearance(
        context: Context,
        views: RemoteViews,
        data: SharedPreferences,
        compact: Boolean,
        style: WidgetStyle,
        holiday: String,
    ) {
        val baseColor = try {
            data.getString("widget_color", "ff0f766e")?.toLong(16)?.toInt()
                ?: Color.rgb(15, 118, 110)
        } catch (_: Exception) {
            Color.rgb(15, 118, 110)
        }
        val wallpaperTextColor = data.getInt("widget_wallpaper_text_color", -1)
        val accent = holidayAccent(holiday) ?: baseColor
        val darkSurface = style == WidgetStyle.glass ||
            style == WidgetStyle.polaroid ||
            style == WidgetStyle.minimal
        val wallpaperText = if (wallpaperTextColor != -1) wallpaperTextColor else -1
        val primaryText = when {
            wallpaperText != -1 && (style == WidgetStyle.sticker ||
                style == WidgetStyle.photo ||
                style == WidgetStyle.minimal) -> wallpaperText
            darkSurface -> Color.rgb(28, 28, 30)
            else -> Color.WHITE
        }
        val secondaryText = withAlpha(primaryText, 0xB8)

        val backdrop = buildBackdrop(
            context,
            style,
            baseColor,
            accent,
            data.getString("widget_background_path", ""),
        )
        if (backdrop == null) {
            views.setViewVisibility(R.id.widget_backdrop, View.GONE)
        } else {
            views.setViewVisibility(R.id.widget_backdrop, View.VISIBLE)
            views.setImageViewBitmap(R.id.widget_backdrop, backdrop)
        }
        val scrimVisible = style == WidgetStyle.sticker ||
            (style == WidgetStyle.photo && backdrop != null)
        views.setViewVisibility(R.id.widget_scrim, if (scrimVisible) View.VISIBLE else View.GONE)

        val holidayVisible = holiday.isNotEmpty() && !compact
        if (holidayVisible) {
            views.setTextViewText(R.id.widget_holiday_badge, holidayLabel(holiday))
            views.setViewVisibility(R.id.widget_holiday_badge, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_holiday_badge, View.GONE)
        }

        views.setTextColor(R.id.widget_title, primaryText)
        views.setTextColor(R.id.widget_days, primaryText)
        views.setTextColor(R.id.widget_unit, secondaryText)
        views.setTextColor(R.id.widget_category, secondaryText)
        views.setTextColor(R.id.widget_note, secondaryText)
        if (style == WidgetStyle.neon || style == WidgetStyle.pixel) {
            views.setTextColor(R.id.widget_days, accent)
        }
        views.setInt(R.id.widget_previous, "setColorFilter", secondaryText)
        views.setInt(R.id.widget_next, "setColorFilter", secondaryText)
        views.setInt(R.id.widget_complete, "setColorFilter", secondaryText)

        val scale = java.lang.Double.longBitsToDouble(
            data.getLong("widget_font_scale", java.lang.Double.doubleToRawLongBits(1.0)),
        ).toFloat()
        views.setTextViewTextSize(R.id.widget_title, 2, (if (compact) 17f else 20f) * scale)
        views.setTextViewTextSize(R.id.widget_days, 2, (if (compact) 38f else 44f) * scale)
        views.setTextViewTextSize(R.id.widget_note, 2, 13f * scale)
    }

    private fun buildBackdrop(
        context: Context,
        style: WidgetStyle,
        baseColor: Int,
        accent: Int,
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
                16f * density,
            )
            WidgetStyle.sticker -> null
            WidgetStyle.photo -> {
                loadPhotoBitmap(photoPath) ?: roundedRectBitmap(
                    width,
                    height,
                    baseColor,
                    16f * density,
                )
            }
            WidgetStyle.glass -> roundedRectBitmap(
                width,
                height,
                0x99FFFFFF.toInt(),
                16f * density,
                borderColor = 0x33FFFFFF,
                borderWidth = 2f * density,
            )
            WidgetStyle.polaroid -> polaroidBitmap(width, height)
            WidgetStyle.neon -> roundedRectBitmap(
                width,
                height,
                0xFF0A0F1E.toInt(),
                12f * density,
                borderColor = accent,
                borderWidth = 3f * density,
            )
            WidgetStyle.pixel -> pixelBitmap(width, height, accent)
            WidgetStyle.minimal -> roundedRectBitmap(
                width,
                height,
                0x00000000,
                12f * density,
                borderColor = 0x661C1C1E.toInt(),
                borderWidth = 2f * density,
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

    private fun polaroidBitmap(width: Int, height: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val white = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE }
        val band = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.rgb(240, 237, 230) }
        val radius = 6f
        canvas.drawRoundRect(0f, 0f, width.toFloat(), height.toFloat(), radius, radius, white)
        val bandTop = height - (height * 0.16f).toInt()
        canvas.drawRect(0f, bandTop.toFloat(), width.toFloat(), height.toFloat(), band)
        return bitmap
    }

    private fun pixelBitmap(width: Int, height: Int, accent: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val dark = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.rgb(20, 20, 20) }
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), dark)
        val edge = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = accent }
        val thickness = 8f
        val step = 28f
        var y = 0f
        while (y < height) {
            val block = minOf(step, height - y)
            canvas.drawRect(0f, y, thickness, y + block, edge)
            canvas.drawRect(width - thickness, y, width.toFloat(), y + block, edge)
            y += step
        }
        var x = 0f
        while (x < width) {
            val block = minOf(step, width - x)
            canvas.drawRect(x, 0f, x + block, thickness, edge)
            canvas.drawRect(x, height - thickness, x + block, height.toFloat(), edge)
            x += step
        }
        return bitmap
    }

    private fun loadPhotoBitmap(path: String?): Bitmap? {
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
            BitmapFactory.decodeFile(path, options)
        } catch (_: Exception) {
            null
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

enum class WidgetStyle {
    card,
    sticker,
    photo,
    glass,
    polaroid,
    neon,
    pixel,
    minimal,
    ;

    companion object {
        fun fromName(value: String?): WidgetStyle =
            entries.firstOrNull { it.name == value } ?: card
    }
}

internal fun parseWidgetStyle(value: String?): WidgetStyle = WidgetStyle.fromName(value)

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
