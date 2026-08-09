package com.jiuxina.ying

import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class DaymarkWidgetProviderTest {
    private fun event(
        id: String = "event-1",
        title: String = "考试",
        target: Long = 1_700_000_000_000,
        category: String = "学习",
        note: String = "",
        icon: String = "",
        createdAt: Long = 1_600_000_000_000,
        isCountUp: Boolean = false,
    ) = WidgetEvent(
        id = id,
        title = title,
        targetDate = target,
        targetTimeMillis = target,
        category = category,
        note = note,
        icon = icon,
        createdAt = createdAt,
        isCountUp = isCountUp,
    )

    @Test
    fun `parseEvents reads protocol v6 json and fills defaults`() {
        val raw = """[
            {"id":"a","title":"考试","targetDate":1700000000000,
             "category":"学习","note":"加油","icon":"📚",
             "createdAt":1600000000000,"isCountUp":false}
        ]"""
        val parsed = parseEvents(raw)
        assertEquals(1, parsed.size)
        assertEquals("a", parsed[0].id)
        assertEquals("📚", parsed[0].icon)
        assertEquals("加油", parsed[0].note)
    }

    @Test
    fun `parseEvents falls back to empty list for malformed json`() {
        assertTrue(parseEvents("{broken").isEmpty())
        assertTrue(parseEvents("[]").isEmpty())
    }

    @Test
    fun `countMainText uses weeks preset and absolute days`() {
        val e = event(target = 1_700_000_000_000)
        assertEquals("10", countMainText(e, "", 10))
        assertEquals("约2周", countMainText(e, "weeks", 14))
        assertEquals("0", countMainText(e, "weeks", 0))
    }

    @Test
    fun `countUnitText picks preset verb and today label`() {
        val e = event()
        assertEquals("天 · 还有", countUnitText(e, "remaining", 10, false))
        assertEquals("天 · 已经", countUnitText(e, "elapsed", -3, true))
        assertEquals("就是今天", countUnitText(e, "", 0, false))
    }

    @Test
    fun `urgentLevel thresholds match 7 3 1`() {
        assertEquals(7, urgentLevel(7))
        assertEquals(3, urgentLevel(3))
        assertEquals(1, urgentLevel(1))
        assertEquals(0, urgentLevel(8))
        assertEquals(0, urgentLevel(-1))
    }

    @Test
    fun `urgentLabel switches to today text at zero`() {
        assertEquals("就是今天", urgentLabel(1, 0))
        assertEquals("只剩3天", urgentLabel(3, 3))
        assertEquals("天 · 快到了", urgentLabel(7, 7))
    }

    @Test
    fun `weekCount rounds and clamps to at least one`() {
        assertEquals(1, weekCount(3))
        assertEquals(1, weekCount(10))
        assertEquals(1, weekCount(0))
    }

    @Test
    fun `preciseTimeText formats hours minutes seconds`() {
        val e = event(target = 3_700_000)
        assertEquals("01:01:40", preciseTimeText(e, 0))
    }

    @Test
    fun `progressOf clamps between zero and one`() {
        val createdAt = 1000L
        val target = 2000L
        val e = event(createdAt = createdAt, target = target)
        assertEquals(0.5f, progressOf(e, 1500), 0.001f)
        assertEquals(0f, progressOf(e, 500), 0.001f)
        assertEquals(1f, progressOf(e, 3000), 0.001f)
    }

    @Test
    fun `quoteText alternates note and built-ins by day parity`() {
        val withNote = event(note = "自定义句子")
        val date = LocalDate.of(2026, 8, 9) // epoch day even
        assertEquals("自定义句子", quoteText(withNote, date))
        assertEquals("记得抬头看月亮", quoteText(null, LocalDate.of(2000, 1, 1)))
    }

    @Test
    fun `holiday helpers map known names`() {
        assertEquals("new_year", holidayForDate(LocalDate.of(2026, 1, 1)))
        assertEquals("christmas", holidayForDate(LocalDate.of(2026, 12, 25)))
        assertEquals("新年", holidayLabel("new_year"))
        assertEquals(0xFFE11D48.toInt(), holidayAccent("new_year"))
    }

    @Test
    fun `color helpers compute contrast and alpha`() {
        assertEquals(0xFFFFFFFF.toInt(), contrastTextColor(0xFF000000.toInt()))
        assertEquals(0xFF101418.toInt(), contrastTextColor(0xFFFFFFFF.toInt()))
        assertEquals(0x80FFFFFF.toInt(), withAlpha(0xFFFFFFFF.toInt(), 0x80))
        assertEquals(0xFF111111.toInt(), darken(0xFF222222.toInt(), 0.5f))
        assertEquals(0xFFFFFFFF.toInt(), argb(255, 255, 255))
    }
}
