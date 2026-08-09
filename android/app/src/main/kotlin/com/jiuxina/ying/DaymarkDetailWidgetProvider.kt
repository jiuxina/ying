package com.jiuxina.ying

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context

/**
 * 单事件专注小部件：每个实例用独立索引锁定一个事件，左右切换只影响该实例，
 * 与总览小部件（列表 / 单事件）的数据和索引互不干扰。
 */
class DaymarkDetailWidgetProvider : DaymarkWidgetProvider() {
    override fun providerClass(): Class<out DaymarkWidgetProvider> =
        DaymarkDetailWidgetProvider::class.java

    override fun perWidgetIndexKey(widgetId: Int): String =
        "daymark_detail_widget_index_$widgetId"

    override fun supportsListMode(): Boolean = false

    override fun refreshAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            ComponentName(context, DaymarkDetailWidgetProvider::class.java),
        )
        val data = context.getSharedPreferences(
            prefsName(),
            Context.MODE_PRIVATE,
        )
        updateWidgets(context, manager, ids, data)
    }
}
