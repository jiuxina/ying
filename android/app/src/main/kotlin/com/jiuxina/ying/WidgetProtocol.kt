package com.jiuxina.ying

import android.content.SharedPreferences
import java.time.LocalDate
import java.time.ZoneId
import java.time.temporal.ChronoUnit
import org.json.JSONArray
import org.json.JSONObject

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
    ;

    companion object {
        fun fromName(value: String?): WidgetStyle =
            entries.firstOrNull { it.name == value } ?: card
    }
}

internal fun parseWidgetStyle(value: String?): WidgetStyle = WidgetStyle.fromName(value)

internal fun effectiveWidgetStyle(data: SharedPreferences): WidgetStyle =
    parseWidgetStyle(data.getString("widget_style", "card"))

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
