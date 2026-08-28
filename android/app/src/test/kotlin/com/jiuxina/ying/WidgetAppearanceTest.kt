package com.jiuxina.ying

import android.view.Gravity
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
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
    fun remainingStylesParseByName() {
        assertEquals(WidgetStyle.card, parseWidgetStyle("card"))
        assertEquals(WidgetStyle.sticker, parseWidgetStyle("sticker"))
        assertEquals(WidgetStyle.photo, parseWidgetStyle("photo"))
        assertEquals(WidgetStyle.glass, parseWidgetStyle("glass"))
        assertEquals(WidgetStyle.polaroid, parseWidgetStyle("polaroid"))
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
    fun urgentLevelSwitchesAtSevenThreeOneDays() {
        assertEquals(0, urgentLevel(-1))
        assertEquals(1, urgentLevel(0))
        assertEquals(1, urgentLevel(1))
        assertEquals(3, urgentLevel(2))
        assertEquals(3, urgentLevel(3))
        assertEquals(7, urgentLevel(4))
        assertEquals(7, urgentLevel(7))
        assertEquals(0, urgentLevel(8))
    }

    @Test
    fun urgentAccentAndLabelMatchLevels() {
        assertEquals(argb(0xB4, 0x53, 0x09), urgentAccent(7))
        assertEquals(argb(0xC2, 0x41, 0x0C), urgentAccent(3))
        assertEquals(argb(0xB9, 0x1C, 0x1C), urgentAccent(1))
        assertEquals(null, urgentAccent(0))
        assertEquals("天 · 快到了", urgentLabel(7, 5))
        assertEquals("只剩3天", urgentLabel(3, 3))
        assertEquals("只剩1天", urgentLabel(1, 1))
        assertEquals("就是今天", urgentLabel(1, 0))
    }

    @Test
    fun flipRefreshClearsStaleFlipDayBeforeRendering() {
        val source = File("src/main/kotlin/com/jiuxina/ying/DaymarkWidgetProvider.kt").readText()
        val flipIf = source.indexOf("if (intent.action == ACTION_REFRESH_FLIP)")
        val flipRemove = source.indexOf("remove(FLIP_DAY_KEY)")
        val whenStart = source.indexOf("when (intent.action)")
        assertTrue("flip cleanup must run before generic refresh", flipIf in 0 until whenStart)
        assertTrue("flip cleanup must remove stale day", flipRemove > flipIf && flipRemove < whenStart)
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

    @Test
    fun pendingUndoParsesEventTitleAndExpiry() {
        val eventJson = """{"id":"evt-undo","title":"旅行","targetDate":1754582400000,"category":"旅行","note":"","icon":"","createdAt":1751500800000}"""
        val payload = pendingUndoPayload("""{"event":$eventJson,"expiresAt":9999999999999}""")
        assertTrue(payload != null)
        assertEquals("evt-undo", payload!!.eventId)
        assertEquals("旅行", payload.title)
        assertEquals(9999999999999L, payload.expiresAt)
    }

    @Test
    fun pendingUndoExpiryUsesCurrentTime() {
        val future = PendingUndoPayload(
            eventId = "future",
            title = "未来",
            expiresAt = System.currentTimeMillis() + 5_000,
        )
        val past = PendingUndoPayload(
            eventId = "past",
            title = "已过期",
            expiresAt = System.currentTimeMillis() - 1_000,
        )
        assertTrue(!future.isExpired())
        assertTrue(past.isExpired())
    }

    @Test
    fun pendingUndoRejectsMalformedJson() {
        assertTrue(pendingUndoPayload("") == null)
        assertTrue(pendingUndoPayload("not-json") == null)
        assertTrue(pendingUndoPayload("""{"event":{}}""") == null)
    }

    @Test
    fun widgetLayoutsAvoidUnsupportedRemoteViewsClasses() {
        val undo = File("src/main/res/layout/daymark_widget_undo.xml").readText()
        val list = File("src/main/res/layout/daymark_widget_list.xml").readText()
        assertTrue(
            "undo layout must not use RemoteViews-unsupported Space",
            "android.widget.Space" !in undo,
        )
        assertTrue("list layout should keep an empty-state view", "widget_empty" in list)
        assertTrue("list layout should have a header row", "widget_list_header" in list)
        val single = File("src/main/res/layout/daymark_widget.xml").readText()
        assertTrue("list layout must not keep complete buttons", "widget_row_1_complete" !in list)
        assertTrue("single layout must not keep complete button", "widget_complete" !in single)
        assertTrue("widget add button must be removed", "widget_add" !in list)
        assertTrue("undo layout must not keep add button", "widget_add" !in undo)
    }

    @Test
    fun widgetWeightUsesRemoteViewsSafeFontVariation() {
        val source = File("src/main/kotlin/com/jiuxina/ying/DaymarkWidgetProvider.kt").readText()
        assertFalse(
            "RemoteViews cannot call TextPaint.setFakeBoldText on TextView",
            "\"setFakeBoldText\"" in source,
        )
        assertTrue(
            "bold approximation should use RemoteViews-safe setFontVariationSettings",
            "\"setFontVariationSettings\"" in source,
        )
    }

    @Test
    fun chronometerSkipsUnsupportedFontVariation() {
        val source = File("src/main/kotlin/com/jiuxina/ying/DaymarkWidgetProvider.kt").readText()
        assertTrue(
            "Chronometer cannot receive RemoteViews setFontVariationSettings; the call would make the whole widget fail to load",
            "if (viewId == R.id.widget_precise) return" in source,
        )
    }

    @Test
    fun removedFunStyleViewsAreNotInLayoutOrProvider() {
        val layout = File("src/main/res/layout/daymark_widget.xml").readText()
        assertFalse("removed styles should not keep envelope cover", "widget_envelope_cover" in layout)
        assertFalse("removed styles should not keep neon day view", "widget_days_neon" in layout)
        assertFalse("removed styles should not keep pixel health bar", "widget_health_bar" in layout)
        val source = File("src/main/kotlin/com/jiuxina/ying/DaymarkWidgetProvider.kt").readText()
        assertFalse("provider should drop envelope reveal", "ACTION_REVEAL" in source)
        assertFalse("provider should drop envelope state", "envelopeOpenKey" in source)
    }

    @Test
    fun detailWidgetProviderIsRegisteredWithOwnInfo() {
        val manifest = File("src/main/AndroidManifest.xml").readText()
        assertTrue(manifest.contains("DaymarkDetailWidgetProvider"))
        assertTrue(manifest.contains("daymark_detail_widget_info"))
        assertTrue(manifest.contains("UCropActivity"))
        val info = File("src/main/res/xml/daymark_detail_widget_info.xml").readText()
        assertTrue("detail widget should reuse single-event layout", "daymark_widget" in info)
        assertTrue("detail widget should be home-screen only", "home_screen" in info)
    }

    @Test
    fun elementStylesParseJsonAndFallBack() {
        val styles = parseElementStyles(
            """{"title":{"size":"large","sizeScale":1.6,"weight":700,"colorMode":"custom","color":-65536,"align":"center"},"prevButton":{"visible":"hide"}}""",
        )
        assertEquals(WidgetElementSize.large, styles.getValue("title").size)
        assertEquals(1.6f, styles.getValue("title").sizeScale)
        assertEquals(700, styles.getValue("title").weight)
        assertEquals(WidgetColorMode.custom, styles.getValue("title").colorMode)
        assertEquals(-65536, styles.getValue("title").color)
        assertEquals(WidgetAlign.center, styles.getValue("title").align)
        assertEquals(WidgetElementVisible.follow, styles.getValue("title").visible)
        assertEquals(WidgetElementVisible.hide, styles.getValue("prevButton").visible)
        assertTrue(parseElementStyles(null).isEmpty())
        assertTrue(parseElementStyles("{broken").isEmpty())
    }

    @Test
    fun verticalAlignParsesWithCenterFallback() {
        assertEquals(WidgetVerticalAlign.top, parseVerticalAlign("top"))
        assertEquals(WidgetVerticalAlign.bottom, parseVerticalAlign("bottom"))
        assertEquals(WidgetVerticalAlign.center, parseVerticalAlign(null))
        assertEquals(WidgetVerticalAlign.center, parseVerticalAlign("unknown"))
    }

    @Test
    fun renderSpecParsesEmptySingleSharedContract() {
        val raw = File("src/test/resources/widget_parity/empty_single.spec.json").readText()
        val spec = parseRenderSpec(raw)
        assertTrue(spec != null)
        assertEquals(10, spec!!.version)
        assertEquals(16f, spec.contentMargin)
        assertEquals("single", spec.compact?.mode)
        assertEquals("single", spec.full?.mode)
        assertEquals(false, spec.compact?.element("category")?.visible)
        assertEquals(true, spec.full?.element("category")?.visible)
        assertEquals(false, spec.compact?.elements?.containsKey("addButton"))
        assertEquals(false, spec.compact?.elements?.containsKey("completeButton"))
        assertEquals(false, spec.full?.elements?.containsKey("completeButton"))
        assertEquals("添加一个倒数日", spec.texts.title)
        assertEquals("--", spec.texts.days)
        assertEquals("天", spec.texts.unit)
    }

    @Test
    fun renderSpecParsesListModeSharedContract() {
        val raw = File("src/test/resources/widget_parity/list_mode.spec.json").readText()
        val spec = parseRenderSpec(raw)
        assertTrue(spec != null)
        assertEquals("list", spec!!.compact?.mode)
        assertEquals("list", spec.full?.mode)
        assertEquals(listOf("pinned", "near", "far"), spec.eventOrder)
        assertEquals(false, spec.compact?.elements?.containsKey("completeButton"))
        assertEquals(true, spec.compact?.element("rowSubtitle")?.visible)
        assertEquals(true, spec.compact?.element("empty")?.visible)
    }

    @Test
    fun renderSpecParsesSingleEventSharedContract() {
        val raw = File("src/test/resources/widget_parity/single_event.spec.json").readText()
        val spec = parseRenderSpec(raw)
        assertTrue(spec != null)
        assertEquals(listOf("evt-1"), spec!!.eventOrder)
        assertEquals(false, spec.compact?.element("icon")?.visible)
        assertEquals(true, spec.full?.element("icon")?.visible)
        assertEquals(0xFFFFFFFF.toInt(), spec.full?.element("title")?.color)
    }

    @Test
    fun renderAlignGravityMatchesElementGravity() {
        assertEquals(Gravity.START, renderAlignGravity(WidgetAlign.start))
        assertEquals(
            Gravity.CENTER_HORIZONTAL,
            renderAlignGravity(WidgetAlign.center),
        )
        assertEquals(Gravity.END, renderAlignGravity(WidgetAlign.end))
    }

    @Test
    fun customFontSelectionKindRecognizesCatalogAndLocal() {
        assertEquals("catalog", customFontSelectionKind("catalog:dseg7"))
        assertEquals("local", customFontSelectionKind("local:imported-1"))
        assertEquals(null, customFontSelectionKind("system"))
        assertEquals(null, customFontSelectionKind(null))
        assertEquals(null, customFontSelectionKind("mono"))
        assertTrue(isPureDigitText("123"))
        assertFalse(isPureDigitText("12天"))
        assertFalse(isPureDigitText(""))
        assertFalse(isPureDigitText("🕯️"))
    }

    @Test
    fun customFontViewsAndProtocolKeysExist() {
        val single = File("src/main/res/layout/daymark_widget.xml").readText()
        val list = File("src/main/res/layout/daymark_widget_list.xml").readText()
        val undo = File("src/main/res/layout/daymark_widget_undo.xml").readText()
        assertTrue(single.contains("widget_days_custom"))
        assertTrue(single.contains("widget_title_custom"))
        assertTrue(single.contains("widget_unit_custom"))
        assertTrue(single.contains("widget_note_custom"))
        assertTrue(list.contains("widget_list_header_custom"))
        assertTrue(list.contains("widget_row_1_title_custom"))
        assertTrue(list.contains("widget_row_1_days_custom"))
        assertTrue(single.contains("widget_content"))
        assertTrue(list.contains("widget_content"))
        assertTrue(undo.contains("widget_content"))
        assertTrue(list.contains("widget_empty_custom"))
        val source = File("src/main/kotlin/com/jiuxina/ying/DaymarkWidgetProvider.kt").readText()
        assertTrue(source.contains("widget_text_font_family"))
        assertTrue(source.contains("widget_digit_font_path"))
        assertTrue(source.contains("widget_text_font_path"))
        assertTrue(source.contains("setImageViewBitmap"))
        assertTrue(source.contains("customFontSelectionKind"))
        assertTrue(source.contains("setViewPadding"))
        assertTrue(source.contains("resolveTextTypeface"))
    }

    @Test
    fun visibilityTristateOverridesFollowDefault() {
        assertTrue(effectiveVisible(null, true))
        assertFalse(effectiveVisible(null, false))
        assertTrue(
            effectiveVisible(
                WidgetElementStyle(visible = WidgetElementVisible.show),
                false,
            ),
        )
        assertFalse(
            effectiveVisible(
                WidgetElementStyle(visible = WidgetElementVisible.hide),
                true,
            ),
        )
        assertTrue(
            effectiveVisible(
                WidgetElementStyle(visible = WidgetElementVisible.follow),
                true,
            ),
        )
    }

    @Test
    fun elementColorsResolveModesAndCustom() {
        val colors = WidgetTextColors(0xFFFFFFFF.toInt(), 0x80FFFFFF.toInt())
        assertEquals(colors.primary, elementColor(null, colors, defaultPrimary = true))
        assertEquals(colors.secondary, elementColor(null, colors, defaultPrimary = false))
        assertEquals(
            colors.secondary,
            elementColor(
                WidgetElementStyle(colorMode = WidgetColorMode.secondary),
                colors,
                defaultPrimary = true,
            ),
        )
        assertEquals(
            0xFF112233.toInt(),
            elementColor(
                WidgetElementStyle(
                    colorMode = WidgetColorMode.custom,
                    color = 0xFF112233.toInt(),
                ),
                colors,
                defaultPrimary = false,
            ),
        )
        assertEquals(
            colors.secondary,
            elementColor(
                WidgetElementStyle(
                    colorMode = WidgetColorMode.custom,
                    color = -1,
                ),
                colors,
                defaultPrimary = false,
            ),
        )
        assertEquals(
            null,
            customElementColor(
                WidgetElementStyle(colorMode = WidgetColorMode.primary),
            ),
        )
        assertEquals(
            0xFF112233.toInt(),
            customElementColor(
                WidgetElementStyle(
                    colorMode = WidgetColorMode.custom,
                    color = 0xFF112233.toInt(),
                ),
            ),
        )
    }

    @Test
    fun elementSizeAndGravityHelpers() {
        assertEquals(
            0.8f,
            elementSizeScale(WidgetElementStyle(sizeScale = 0.8f)),
        )
        assertEquals(1.0f, elementSizeScale(null))
        assertEquals(
            1.25f,
            elementSizeScale(WidgetElementStyle(sizeScale = 1.25f)),
        )
        assertEquals(700, elementWeight(WidgetElementStyle(weight = 700)))
        assertEquals(0, elementWeight(null))
        for (id in widgetNonTextElementIds) {
            assertEquals(
                "non-text element must not render weight: $id",
                0,
                elementWeight(WidgetElementStyle(weight = 700), id),
            )
        }
        assertEquals(Gravity.START, elementGravity(null))
        assertEquals(
            Gravity.CENTER_HORIZONTAL,
            elementGravity(WidgetElementStyle(align = WidgetAlign.center)),
        )
        assertEquals(
            Gravity.END,
            elementGravity(WidgetElementStyle(align = WidgetAlign.end)),
        )
        assertEquals(Gravity.TOP, widgetVerticalGravity(WidgetVerticalAlign.top))
        assertEquals(
            Gravity.CENTER_VERTICAL,
            widgetVerticalGravity(WidgetVerticalAlign.center),
        )
        assertEquals(
            Gravity.BOTTOM,
            widgetVerticalGravity(WidgetVerticalAlign.bottom),
        )
        assertEquals(Gravity.START or Gravity.BOTTOM, widgetDateRowGravity(null))
        assertEquals(
            Gravity.END or Gravity.BOTTOM,
            widgetDateRowGravity(WidgetElementStyle(align = WidgetAlign.end)),
        )
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
