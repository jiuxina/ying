package com.jiuxina.ying

import android.content.SharedPreferences
import android.view.Gravity
import org.json.JSONObject

internal const val WIDGET_RENDER_SPEC_KEY = "widget_render_spec"
internal const val WIDGET_RENDER_PROTOCOL_VERSION = 8

internal val widgetRenderElementIds = listOf(
    "category",
    "holidayBadge",
    "title",
    "days",
    "unit",
    "note",
    "precise",
    "dateInfo",
    "progress",
    "icon",
    "listHeader",
    "rowTitle",
    "rowSubtitle",
    "rowDays",
    "rowUnit",
    "empty",
    "prevButton",
    "nextButton",
    "completeButton",
)

internal val widgetPrimaryRenderElementIds = setOf(
    "title",
    "days",
    "icon",
    "rowTitle",
    "rowDays",
)

internal data class WidgetElementRender(
    val visible: Boolean,
    val color: Int,
    val size: Float,
    val align: WidgetAlign,
)

internal data class WidgetRenderBranch(
    val mode: String,
    val elements: Map<String, WidgetElementRender>,
) {
    fun element(id: String): WidgetElementRender =
        elements[id] ?: WidgetElementRender(
            visible = false,
            color = 0xFFFFFFFF.toInt(),
            size = 1f,
            align = WidgetAlign.start,
        )
}

internal data class WidgetRenderTexts(
    val title: String,
    val category: String,
    val days: String,
    val unit: String,
)

internal data class WidgetRenderSpec(
    val version: Int,
    val style: String,
    val verticalAlign: WidgetVerticalAlign,
    val eventOrder: List<String>,
    val texts: WidgetRenderTexts,
    val compact: WidgetRenderBranch?,
    val full: WidgetRenderBranch?,
) {
    fun branch(compact: Boolean): WidgetRenderBranch? =
        if (compact) this.compact else this.full
}

internal fun parseRenderSpec(raw: String?): WidgetRenderSpec? {
    if (raw.isNullOrBlank()) return null
    return try {
        val json = JSONObject(raw)
        WidgetRenderSpec(
            version = json.optInt("version", WIDGET_RENDER_PROTOCOL_VERSION),
            style = json.optString("style", "card"),
            verticalAlign = parseVerticalAlign(json.optString("verticalAlign")),
            eventOrder = json.optJSONArray("eventOrder")?.let { array ->
                buildList {
                    for (index in 0 until array.length()) {
                        add(array.getString(index))
                    }
                }
            } ?: emptyList(),
            texts = parseRenderTexts(json.optJSONObject("texts")),
            compact = parseRenderBranch(json.optJSONObject("compact")),
            full = parseRenderBranch(json.optJSONObject("full")),
        )
    } catch (_: Exception) {
        null
    }
}

private fun parseRenderTexts(json: JSONObject?): WidgetRenderTexts {
    return WidgetRenderTexts(
        title = json?.optString("title", "添加一个倒数日") ?: "添加一个倒数日",
        category = json?.optString("category", "萤") ?: "萤",
        days = json?.optString("days", "--") ?: "--",
        unit = json?.optString("unit", "天") ?: "天",
    )
}

private fun parseRenderBranch(json: JSONObject?): WidgetRenderBranch? {
    if (json == null) return null
    val raw = json.optJSONObject("elements")
    val elements = mutableMapOf<String, WidgetElementRender>()
    if (raw != null) {
        raw.keys().forEach { id ->
            val value = raw.optJSONObject(id) ?: return@forEach
            elements[id] = WidgetElementRender(
                visible = value.optBoolean("visible", false),
                color = value.optInt("color", 0xFFFFFFFF.toInt()),
                size = value.optDouble("size", 1.0).toFloat(),
                align = WidgetAlign.fromName(value.optString("align")),
            )
        }
    }
    return WidgetRenderBranch(
        mode = json.optString("mode", "single"),
        elements = elements,
    )
}

internal fun renderAlignGravity(align: WidgetAlign): Int = when (align) {
    WidgetAlign.center -> Gravity.CENTER_HORIZONTAL
    WidgetAlign.end -> Gravity.END
    else -> Gravity.START
}

internal fun fallbackRenderBranch(
    data: SharedPreferences,
    styles: Map<String, WidgetElementStyle>,
    compact: Boolean,
    mode: String,
    style: WidgetStyle,
): WidgetRenderBranch {
    val colors = resolveTextColors(data, style)
    val elements = mutableMapOf<String, WidgetElementRender>()
    for (id in widgetRenderElementIds) {
        val policyVisible = when (id) {
            "category" -> !compact && data.getBoolean("widget_show_category", true)
            "holidayBadge" -> !compact
            "title",
            "days",
            "unit",
            "listHeader",
            "rowTitle",
            "rowSubtitle",
            "rowDays",
            "rowUnit",
            "empty",
            -> true
            "note" -> !compact
            "precise" -> data.getBoolean("widget_show_precise_time", false)
            "dateInfo" -> !compact && data.getBoolean("widget_show_lunar_week", false)
            "progress" -> !compact &&
                (data.getBoolean("widget_show_progress", false) ||
                    style == WidgetStyle.pixelHealth)
            "icon" -> if (mode == "list") {
                data.getBoolean("widget_show_icon", false)
            } else {
                !compact && data.getBoolean("widget_show_icon", false)
            }
            "prevButton",
            "nextButton",
            -> !compact
            "completeButton" -> if (mode == "single") !compact else true
            else -> true
        }
        elements[id] = WidgetElementRender(
            visible = effectiveVisible(styles[id], policyVisible),
            color = elementColor(
                styles[id],
                colors,
                defaultPrimary = id in widgetPrimaryRenderElementIds,
            ),
            size = elementSizeScale(styles[id]),
            align = styles[id]?.align ?: WidgetAlign.start,
        )
    }
    return WidgetRenderBranch(mode = mode, elements = elements)
}
