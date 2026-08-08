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
}
