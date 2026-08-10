package com.jiuxina.ying

import android.content.SharedPreferences
import android.view.Gravity
import org.json.JSONObject

internal const val WIDGET_ELEMENT_STYLES_KEY = "widget_element_styles"
internal const val WIDGET_VERTICAL_ALIGN_KEY = "widget_vertical_align"

internal enum class WidgetElementVisible {
    follow,
    show,
    hide,
    ;

    companion object {
        fun fromName(value: String?): WidgetElementVisible =
            entries.firstOrNull { it.name == value } ?: follow
    }
}

internal enum class WidgetElementSize(val multiplier: Float) {
    small(0.8f),
    normal(1.0f),
    large(1.25f),
    xlarge(1.5f),
    ;

    companion object {
        fun fromName(value: String?): WidgetElementSize =
            entries.firstOrNull { it.name == value } ?: normal
    }
}

internal enum class WidgetColorMode {
    primary,
    secondary,
    custom,
    ;

    companion object {
        fun fromName(value: String?): WidgetColorMode =
            entries.firstOrNull { it.name == value } ?: primary
    }
}

internal enum class WidgetAlign {
    start,
    center,
    end,
    ;

    companion object {
        fun fromName(value: String?): WidgetAlign =
            entries.firstOrNull { it.name == value } ?: start
    }
}

internal enum class WidgetVerticalAlign {
    top,
    center,
    bottom,
    ;

    companion object {
        fun fromName(value: String?): WidgetVerticalAlign =
            entries.firstOrNull { it.name == value } ?: center
    }
}

internal data class WidgetElementStyle(
    val visible: WidgetElementVisible = WidgetElementVisible.follow,
    val size: WidgetElementSize = WidgetElementSize.normal,
    val colorMode: WidgetColorMode = WidgetColorMode.primary,
    val color: Int = -1,
    val align: WidgetAlign = WidgetAlign.start,
)

internal fun parseElementStyles(raw: String?): Map<String, WidgetElementStyle> {
    if (raw.isNullOrBlank()) return emptyMap()
    return try {
        val json = JSONObject(raw)
        buildMap {
            json.keys().forEach { key ->
                val value = json.optJSONObject(key) ?: return@forEach
                put(key, parseElementStyle(value))
            }
        }
    } catch (_: Exception) {
        emptyMap()
    }
}

internal fun parseElementStyle(json: JSONObject): WidgetElementStyle {
    return WidgetElementStyle(
        visible = WidgetElementVisible.fromName(json.optString("visible")),
        size = WidgetElementSize.fromName(json.optString("size")),
        colorMode = WidgetColorMode.fromName(json.optString("colorMode")),
        color = json.optInt("color", -1),
        align = WidgetAlign.fromName(json.optString("align")),
    )
}

internal fun parseVerticalAlign(value: String?): WidgetVerticalAlign =
    WidgetVerticalAlign.fromName(value)

internal fun elementStyle(
    data: SharedPreferences,
    id: String,
): WidgetElementStyle? = parseElementStyles(
    data.getString(WIDGET_ELEMENT_STYLES_KEY, ""),
).get(id)

internal fun effectiveVisible(
    style: WidgetElementStyle?,
    followDefault: Boolean,
): Boolean = when (style?.visible) {
    WidgetElementVisible.show -> true
    WidgetElementVisible.hide -> false
    else -> followDefault
}

internal fun customElementColor(style: WidgetElementStyle?): Int? =
    if (style?.colorMode == WidgetColorMode.custom && style.color != -1) {
        style.color
    } else {
        null
    }

internal fun elementColor(
    style: WidgetElementStyle?,
    colors: WidgetTextColors,
    defaultPrimary: Boolean,
): Int {
    val fallback = if (defaultPrimary) colors.primary else colors.secondary
    return when {
        style == null -> fallback
        style.colorMode == WidgetColorMode.custom ->
            customElementColor(style) ?: fallback
        style.colorMode == WidgetColorMode.secondary -> colors.secondary
        else -> colors.primary
    }
}

internal fun elementSizeScale(style: WidgetElementStyle?): Float =
    style?.size?.multiplier ?: 1f

internal fun elementGravity(style: WidgetElementStyle?): Int = when (style?.align) {
    WidgetAlign.center -> Gravity.CENTER_HORIZONTAL
    WidgetAlign.end -> Gravity.END
    else -> Gravity.START
}

internal fun widgetDateRowGravity(style: WidgetElementStyle?): Int =
    elementGravity(style) or Gravity.BOTTOM

internal fun widgetVerticalGravity(align: WidgetVerticalAlign): Int = when (align) {
    WidgetVerticalAlign.top -> Gravity.TOP
    WidgetVerticalAlign.bottom -> Gravity.BOTTOM
    else -> Gravity.CENTER_VERTICAL
}
