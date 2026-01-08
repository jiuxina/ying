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
    // Flutter home_widget 插件默认使用默认的 SharedPreferences
    // 文件名为 <package_name>_preferences
    
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
        val style: WidgetStyle = WidgetStyle.STANDARD,
        val event2Title: String = "",
        val event2Days: String = "",
        val event3Title: String = "",
        val event3Days: String = ""
    )

    /**
     * 从 SharedPreferences 读取小部件数据
     */
    fun loadWidgetData(context: Context, sizePrefix: String = "standard"): WidgetData {
        return try {
            // 尝试获取 Flutter shared_preferences 插件使用的默认 store
            // 通常是 "FlutterSharedPreferences" 或者 "<package>_preferences"
            // home_widget 插件在 Android 上通常写入到 context.getSharedPreferences(name)
            // 如果未指定名称，可能会有所不同。
            // 最稳妥的方式是尝试读取 Dart side 写入的特定 key
            
            // 注意：home_widget: ^0.7.0+ 默认使用 PreferenceManager.getDefaultSharedPreferences
            
            val prefsName = "${context.packageName}_preferences"
            val prefs = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            
            // 辅助函数：安全获取 Int (处理 Flutter 可能存储为 Long 的情况)
            fun getIntSafe(key: String, def: Int): Int {
                if (!prefs.contains(key)) return def
                return try {
                    prefs.getInt(key, def)
                } catch (e: ClassCastException) {
                    try {
                        prefs.getLong(key, def.toLong()).toInt()
                    } catch (e2: Exception) {
                        def
                    }
                }
            }

            // 辅助函数：安全获取 Boolean
            fun getBoolSafe(key: String, def: Boolean): Boolean {
                if (!prefs.contains(key)) return def
                return try {
                    prefs.getBoolean(key, def)
                } catch (e: Exception) {
                    def
                }
            }
            
            // 辅助函数：安全获取 Float (处理 Double/Long)
            fun getFloatSafe(key: String, def: Float): Float {
                if (!prefs.contains(key)) return def
                return try {
                    prefs.getFloat(key, def)
                } catch (e: Exception) {
                    try {
                        // Flutter share_preferences 可能会把 double 存为 float? 或者反之
                         // 但 home_widget saveWidgetData<double> 应该存为 Float 或 String?
                         // 让我们尝试转换
                        def // 暂时降级为默认值，如果类型不匹配
                    } catch (e2: Exception) {
                        def
                    }
                }
            }

            val styleStr = prefs.getString("widget_${sizePrefix}_style", "standard")
            
            WidgetData(
                title = prefs.getString("widget_title", "萤") ?: "萤",
                days = prefs.getString("widget_days", "0") ?: "0",
                prefix = prefs.getString("widget_prefix", "还有") ?: "还有",
                date = prefs.getString("widget_date", "暂无事件") ?: "暂无事件",
                backgroundColor = getIntSafe("widget_${sizePrefix}_bg_color", 0xFF6366F1.toInt()),
                gradientEndColor = getIntSafe("widget_${sizePrefix}_gradient_end", 0xFF8B5CF6.toInt()),
                opacity = getFloatSafe("widget_${sizePrefix}_opacity", 1.0f),
                showDate = getBoolSafe("widget_${sizePrefix}_show_date", true),
                style = WidgetStyle.fromString(styleStr),
                event2Title = prefs.getString("widget_event2_title", "") ?: "",
                event2Days = prefs.getString("widget_event2_days", "") ?: "",
                event3Title = prefs.getString("widget_event3_title", "") ?: "",
                event3Days = prefs.getString("widget_event3_days", "") ?: ""
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error loading widget data", e)
            WidgetData()
        }
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
