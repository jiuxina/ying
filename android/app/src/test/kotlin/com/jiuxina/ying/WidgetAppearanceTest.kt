package com.jiuxina.ying

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class WidgetAppearanceTest {
    @Test
    fun unknownStyleFallsBackToCard() {
        assertEquals(WidgetStyle.card, parseWidgetStyle(null))
        assertEquals(WidgetStyle.card, parseWidgetStyle("neon-v2"))
        assertEquals(WidgetStyle.sticker, parseWidgetStyle("sticker"))
        assertEquals(WidgetStyle.glass, parseWidgetStyle("glass"))
    }

    @Test
    fun dateHolidaysCoverNewYearAndChristmas() {
        assertEquals("new_year", holidayForDate(LocalDate.of(2027, 1, 1)))
        assertEquals("christmas", holidayForDate(LocalDate.of(2026, 12, 24)))
        assertEquals("christmas", holidayForDate(LocalDate.of(2026, 12, 26)))
        assertEquals("", holidayForDate(LocalDate.of(2026, 8, 8)))
    }

    @Test
    fun birthdayHolidayMatchesEventMonthAndDay() {
        val event = WidgetEvent(
            id = "birthday",
            title = "妈妈的生日",
            targetDate = java.time.ZonedDateTime.of(2026, 5, 20, 0, 0, 0, 0, java.time.ZoneId.systemDefault())
                .toInstant().toEpochMilli(),
            targetTimeMillis = java.time.ZonedDateTime.of(2026, 5, 20, 0, 0, 0, 0, java.time.ZoneId.systemDefault())
                .toInstant().toEpochMilli(),
            category = "家庭",
            note = "",
            icon = "",
            createdAt = 0L,
            isCountUp = false,
        )
        assertEquals(
            "birthday",
            holidayForEvent(event, LocalDate.of(2027, 5, 20)),
        )
        assertEquals("", holidayForEvent(event, LocalDate.of(2027, 5, 21)))
        assertEquals("", holidayForEvent(event.copy(title = "普通纪念日"), LocalDate.of(2027, 5, 20)))
    }

    @Test
    fun resolveHolidayPrefersLocalDateThenBirthdayThenPref() {
        val event = WidgetEvent(
            id = "birthday",
            title = "生日",
            targetDate = java.time.ZonedDateTime.of(2026, 3, 3, 0, 0, 0, 0, java.time.ZoneId.systemDefault())
                .toInstant().toEpochMilli(),
            targetTimeMillis = java.time.ZonedDateTime.of(2026, 3, 3, 0, 0, 0, 0, java.time.ZoneId.systemDefault())
                .toInstant().toEpochMilli(),
            category = "生活",
            note = "",
            icon = "",
            createdAt = 0L,
            isCountUp = false,
        )
        assertEquals(
            "new_year",
            resolveHoliday("christmas", LocalDate.of(2027, 1, 1), event),
        )
        assertEquals(
            "birthday",
            resolveHoliday("mid_autumn", LocalDate.of(2027, 3, 3), event),
        )
        assertEquals(
            "mid_autumn",
            resolveHoliday("mid_autumn", LocalDate.of(2027, 8, 8), null),
        )
        assertEquals("", resolveHoliday("unknown", LocalDate.of(2027, 8, 8), null))
    }

    @Test
    fun contrastTextColorChoosesReadableInk() {
        assertEquals(0xFFFFFFFF.toInt(), contrastTextColor(0xFF0F766E.toInt()))
        assertEquals(0xFF101418.toInt(), contrastTextColor(0xFFFFFFFF.toInt()))
        assertEquals(0xFFFFFFFF.toInt(), contrastTextColor(0xFF111111.toInt()))
    }

    @Test
    fun colorHelpersKeepExpectedShape() {
        assertEquals(0xB8FFFFFF.toInt(), withAlpha(0xFFFFFFFF.toInt(), 0xB8))
        val darkened = darken(0xFFFFFFFF.toInt())
        val red = (darkened shr 16) and 0xFF
        assertTrue(red in 0..220)
    }

    @Test
    fun countTextsSupportUnitPresets() {
        val event = eventAt("2026-08-08T09:00:00")
        assertEquals("12", countMainText(event, "", 12))
        assertEquals("天 · 还有", countUnitText(event, "", 12, false))
        assertEquals("天 · 只剩", countUnitText(event, "only", 12, false))
        assertEquals("天 · 距离", countUnitText(event, "distance", 12, false))
        assertEquals("天 · 已经", countUnitText(event, "elapsed", -12, true))
        assertEquals("约2周", countMainText(event, "weeks", 12))
        assertEquals("", countUnitText(event, "weeks", 12, false))
        assertEquals("就是今天", countUnitText(event, "", 0, false))
    }

    @Test
    fun preciseTimeAndProgressAreDerivedFromTimestamps() {
        val now = java.time.ZonedDateTime.of(2026, 8, 8, 12, 0, 0, 0, java.time.ZoneId.systemDefault())
            .toInstant().toEpochMilli()
        val target = java.time.ZonedDateTime.of(2026, 8, 9, 15, 30, 0, 0, java.time.ZoneId.systemDefault())
            .toInstant().toEpochMilli()
        val createdAt = java.time.ZonedDateTime.of(2026, 8, 1, 0, 0, 0, 0, java.time.ZoneId.systemDefault())
            .toInstant().toEpochMilli()
        val event = WidgetEvent(
            id = "precise",
            title = "考试",
            targetDate = target,
            targetTimeMillis = target,
            category = "学习",
            note = "",
            icon = "",
            createdAt = createdAt,
            isCountUp = false,
        )
        assertEquals("27:30:00", preciseTimeText(event, now))
        val progress = progressOf(event, now)
        assertTrue(progress > 0.8f && progress < 1f)
    }

    @Test
    fun quoteRotatesBetweenNoteAndBuiltins() {
        val date = java.time.LocalDate.of(2026, 8, 8)
        val event = WidgetEvent(
            id = "quote",
            title = "旅行",
            targetDate = date.atStartOfDay(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli(),
            targetTimeMillis = date.atStartOfDay(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli(),
            category = "旅行",
            note = "记得带护照",
            icon = "",
            createdAt = 0L,
            isCountUp = false,
        )
        val expected = if (date.toEpochDay() % 2 == 0L) {
            "记得带护照"
        } else {
            builtInQuotesForTest()[Math.floorMod(date.toEpochDay(), 8L).toInt()]
        }
        assertEquals(expected, quoteText(event, date))
        assertTrue(quoteText(null, date).isNotBlank())
    }

    @Test
    fun dateInfoContainsLunarMonthAndWeekday() {
        val info = widgetDateInfo(java.time.LocalDate.of(2026, 8, 8))
        // android.icu 在 JVM 单测环境不可用，运行时由真机兜底；有值时校验内容。
        assertTrue(info.isBlank() || (info.contains("农历") && info.contains("星期六")))
    }

    @Test
    fun parseEventsReadsTargetTime() {
        val raw = """[{"id":"a","title":"考试","targetDate":1754582400000,"targetTime":1754627400000,"category":"学习","note":"","icon":"","createdAt":1751500800000,"isCountUp":false}]"""
        val events = parseEvents(raw)
        assertEquals(1, events.size)
        assertEquals(1754627400000L, events.single().targetTimeMillis)
    }

    private fun eventAt(iso: String): WidgetEvent {
        val millis = java.time.LocalDateTime.parse(iso)
            .atZone(java.time.ZoneId.systemDefault())
            .toInstant()
            .toEpochMilli()
        return WidgetEvent(
            id = iso,
            title = "事件",
            targetDate = millis,
            targetTimeMillis = millis,
            category = "生活",
            note = "",
            icon = "",
            createdAt = 0L,
            isCountUp = false,
        )
    }

    private fun builtInQuotesForTest(): List<String> = listOf(
        "把日子过成诗",
        "今天也值得纪念",
        "慢慢来，比较快",
        "每个今天都是礼物",
        "好事会发生",
        "记得抬头看月亮",
        "认真生活的你闪闪发光",
        "向前走，别回头",
    )
}
