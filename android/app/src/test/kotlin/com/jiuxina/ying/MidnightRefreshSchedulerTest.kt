package com.jiuxina.ying

import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.ZoneId
import java.time.ZonedDateTime

class MidnightRefreshSchedulerTest {
    private val shanghai = ZoneId.of("Asia/Shanghai")

    @Test
    fun nextMidnightBeforeMidnight() {
        val now = ZonedDateTime.of(2026, 8, 8, 23, 59, 0, 0, shanghai)
        val expected = ZonedDateTime.of(2026, 8, 9, 0, 0, 0, 0, shanghai)
        assertEquals(
            expected.toInstant().toEpochMilli(),
            MidnightRefreshScheduler.nextMidnightMillis(now),
        )
    }

    @Test
    fun nextMidnightJustAfterMidnight() {
        val now = ZonedDateTime.of(2026, 8, 8, 0, 1, 0, 0, shanghai)
        val expected = ZonedDateTime.of(2026, 8, 9, 0, 0, 0, 0, shanghai)
        assertEquals(
            expected.toInstant().toEpochMilli(),
            MidnightRefreshScheduler.nextMidnightMillis(now),
        )
    }

    @Test
    fun nextMidnightCrossesMonthAndYear() {
        val newYear = ZonedDateTime.of(2026, 12, 31, 23, 0, 0, 0, shanghai)
        assertEquals(
            ZonedDateTime.of(2027, 1, 1, 0, 0, 0, 0, shanghai)
                .toInstant().toEpochMilli(),
            MidnightRefreshScheduler.nextMidnightMillis(newYear),
        )
    }

    @Test
    fun nextMidnightAfterLeapDay() {
        val leapDay = ZonedDateTime.of(2028, 2, 29, 12, 0, 0, 0, shanghai)
        assertEquals(
            ZonedDateTime.of(2028, 3, 1, 0, 0, 0, 0, shanghai)
                .toInstant().toEpochMilli(),
            MidnightRefreshScheduler.nextMidnightMillis(leapDay),
        )
    }

    @Test
    fun nextMidnightRespectsDstTransition() {
        val zone = ZoneId.of("America/New_York")
        val now = ZonedDateTime.of(2026, 3, 8, 0, 30, 0, 0, zone)
        val expected = ZonedDateTime.of(2026, 3, 9, 0, 0, 0, 0, zone)
        val next = ZonedDateTime.ofInstant(
            java.time.Instant.ofEpochMilli(MidnightRefreshScheduler.nextMidnightMillis(now)),
            zone,
        )
        assertEquals(expected.toInstant().toEpochMilli(), next.toInstant().toEpochMilli())
        assertEquals("-04:00", next.offset.id)
    }

    @Test
    fun refreshWindowIsFiveMinutes() {
        assertEquals(5 * 60 * 1000L, MidnightRefreshScheduler.WINDOW_MILLIS)
    }
}
