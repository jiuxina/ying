package com.jiuxina.ying

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.util.Log

/**
 * 小部件工具类 - 共享的数据读取逻辑
 */
object WidgetUtils {
    private const val TAG = "WidgetUtils"
    private const val WIDGET_PREFERENCES = "HomeWidgetPreferences"
    
    // 颜色常量
    object Colors {
        const val WHITE = Color.WHITE
        val WHITE_80 = 0xCCFFFFFF.toInt()
        val WHITE_60 = 0xAAFFFFFF.toInt()
        val WHITE_50 = 0x88FFFFFF.toInt()
        val WHITE_30 = 0x55FFFFFF.toInt()
        val WHITE_20 = 0x33FFFFFF.toInt()
        val DIVIDER = 0x33FFFFFF
    }

    /**
     * 小部件样式枚举
     */
    enum class WidgetStyle {
        STANDARD,   // 纯色
        GRADIENT,   // 渐变
        GLASSMORPHISM; // 毛玻璃

        companion object {
            fun fromString(value: String?): WidgetStyle {
                if (value == null) return STANDARD
                return try {
                    valueOf(value.uppercase())
                } catch (e: Exception) {
                    STANDARD
                }
            }
        }
    }

    /**
     * 字体大小枚举
     */
    enum class FontSize {
        SMALL, MEDIUM, LARGE;

        companion object {
            fun fromString(value: String?): FontSize {
                if (value == null) return MEDIUM
                return try {
                    valueOf(value.uppercase())
                } catch (e: Exception) {
                    MEDIUM
                }
            }
        }

        val titleScale: Float
            get() = when (this) {
                SMALL -> 0.85f
                MEDIUM -> 1.0f
                LARGE -> 1.15f
            }

        val daysScale: Float
            get() = when (this) {
                SMALL -> 0.85f
                MEDIUM -> 1.0f
                LARGE -> 1.2f
            }
    }

    /**
     * 小部件数据模型
     */
    data class WidgetData(
        val title: String = "萤",
        val days: String = "0",
        val prefix: String = "还有",
        val date: String = "暂无事件",
        val backgroundColor: Int = 0xFF6366F1.toInt(),
        val gradientEndColor: Int = 0xFF8B5CF6.toInt(),
        val opacity: Float = 1.0f,
        val showDate: Boolean = true,
        val showTitle: Boolean = true,
        val showDays: Boolean = true,
        val showIcon: Boolean = false,
        val style: WidgetStyle = WidgetStyle.STANDARD,
        val fontSize: FontSize = FontSize.MEDIUM,
        val cornerRadius: Float = 16.0f,
        val textColor: Int = Color.WHITE,
        val backgroundImage: String? = null,
        val event2Title: String = "",
        val event2Days: String = "",
        val event3Title: String = "",
        val event3Days: String = ""
    )

    fun getWidgetPreferences(context: Context): SharedPreferences {
        return context.getSharedPreferences(WIDGET_PREFERENCES, Context.MODE_PRIVATE)
    }

    fun getStringSafe(prefs: SharedPreferences, key: String, def: String? = null): String? {
        return when (val value = prefs.all[key]) {
            is String -> value
            is Number -> value.toString()
            is Boolean -> value.toString()
            else -> def
        }
    }

    fun getLongSafe(prefs: SharedPreferences, key: String, def: Long = 0L): Long {
        return when (val value = prefs.all[key]) {
            is Long -> value
            is Int -> value.toLong()
            is Float -> value.toLong()
            is String -> value.toLongOrNull() ?: def
            else -> def
        }
    }

    fun getIntSafe(prefs: SharedPreferences, key: String, def: Int): Int {
        return when (val value = prefs.all[key]) {
            is Int -> value
            is Long -> value.toInt()
            is Float -> value.toInt()
            is String -> value.toIntOrNull() ?: def
            else -> def
        }
    }

    fun getFloatSafe(prefs: SharedPreferences, key: String, def: Float): Float {
        return when (val value = prefs.all[key]) {
            is Float -> value
            is Double -> value.toFloat()
            is Int -> value.toFloat()
            is Long -> value.toFloat()
            is String -> value.toFloatOrNull() ?: def
            else -> def
        }
    }

    fun getBoolSafe(prefs: SharedPreferences, key: String, def: Boolean): Boolean {
        return when (val value = prefs.all[key]) {
            is Boolean -> value
            is String -> value.toBooleanStrictOrNull() ?: def
            else -> def
        }
    }

    /**
     * 从 SharedPreferences 读取小部件数据
     */
    fun loadWidgetData(context: Context, sizePrefix: String = "standard"): WidgetData {
        return try {
            val prefs = getWidgetPreferences(context)
            val styleStr = getStringSafe(prefs, "widget_${sizePrefix}_style", "standard")
            
            WidgetData(
                title = getStringSafe(prefs, "widget_title", "萤") ?: "萤",
                days = getStringSafe(prefs, "widget_days", "0") ?: "0",
                prefix = getStringSafe(prefs, "widget_prefix", "还有") ?: "还有",
                date = getStringSafe(prefs, "widget_date", "暂无事件") ?: "暂无事件",
                backgroundColor = getIntSafe(prefs, "widget_${sizePrefix}_bg_color", 0xFF6366F1.toInt()),
                gradientEndColor = getIntSafe(prefs, "widget_${sizePrefix}_gradient_end", 0xFF8B5CF6.toInt()),
                showDate = getBoolSafe(prefs, "widget_${sizePrefix}_show_date", true),
                showTitle = getBoolSafe(prefs, "widget_${sizePrefix}_show_title", true),
                showDays = getBoolSafe(prefs, "widget_${sizePrefix}_show_days", true),
                showIcon = getBoolSafe(prefs, "widget_${sizePrefix}_show_icon", false),
                style = WidgetStyle.fromString(styleStr),
                fontSize = FontSize.fromString(getStringSafe(prefs, "widget_${sizePrefix}_font_size", "medium")),
                cornerRadius = getFloatSafe(prefs, "widget_${sizePrefix}_corner_radius", 16.0f),
                textColor = getIntSafe(prefs, "widget_${sizePrefix}_text_color", Color.WHITE),
                backgroundImage = getStringSafe(prefs, "widget_${sizePrefix}_bg_image", null),
                event2Title = getStringSafe(prefs, "widget_event2_title", "") ?: "",
                event2Days = getStringSafe(prefs, "widget_event2_days", "") ?: "",
                event3Title = getStringSafe(prefs, "widget_event3_title", "") ?: "",
                event3Days = getStringSafe(prefs, "widget_event3_days", "") ?: ""
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error loading widget data", e)
            WidgetData()
        }
    }

    /**
     * 从 per-widget 配置读取样式数据
     */
    fun loadWidgetStyle(prefs: SharedPreferences, widgetId: Int): WidgetData {
        val prefix = "style_$widgetId"
        val styleStr = getStringSafe(prefs, "${prefix}_style", null)
        
        return WidgetData(
            style = WidgetStyle.fromString(styleStr),
            backgroundColor = getIntSafe(prefs, "${prefix}_bg_color", 0xFF6366F1.toInt()),
            gradientEndColor = getIntSafe(prefs, "${prefix}_gradient_end", 0xFF8B5CF6.toInt()),
            opacity = getFloatSafe(prefs, "${prefix}_opacity", 1.0f),
            showDate = getBoolSafe(prefs, "${prefix}_show_date", true),
            showTitle = getBoolSafe(prefs, "${prefix}_show_title", true),
            showDays = getBoolSafe(prefs, "${prefix}_show_days", true),
            showIcon = getBoolSafe(prefs, "${prefix}_show_icon", false),
            fontSize = FontSize.fromString(getStringSafe(prefs, "${prefix}_font_size", "medium")),
            cornerRadius = getFloatSafe(prefs, "${prefix}_corner_radius", 16.0f),
            textColor = getIntSafe(prefs, "${prefix}_text_color", Color.WHITE),
            backgroundImage = getStringSafe(prefs, "${prefix}_bg_image", null)
        )
    }

    /**
     * 将颜色与透明度合并
     */
    fun applyOpacity(color: Int, opacity: Float): Int {
        val alpha = (opacity * 255).toInt().coerceIn(0, 255)
        return (color and 0x00FFFFFF) or (alpha shl 24)
    }

    /**
     * 计算渐变中间色（用于模拟渐变效果）
     */
    fun blendColors(color1: Int, color2: Int, ratio: Float): Int {
        val inverseRatio = 1f - ratio
        val a = (Color.alpha(color1) * inverseRatio + Color.alpha(color2) * ratio).toInt()
        val r = (Color.red(color1) * inverseRatio + Color.red(color2) * ratio).toInt()
        val g = (Color.green(color1) * inverseRatio + Color.green(color2) * ratio).toInt()
        val b = (Color.blue(color1) * inverseRatio + Color.blue(color2) * ratio).toInt()
        return Color.argb(a, r, g, b)
    }
}
