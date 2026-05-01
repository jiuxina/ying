package com.jiuxina.ying

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.LocalContext
import androidx.glance.LocalGlanceId
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

/**
 * 迷你倒计时小部件 (1×1) - 极简设计，仅显示天数
 * 适合桌面空间有限的场景
 */
class CountdownMiniGlanceWidget : GlanceAppWidget() {

    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceTheme {
                val context = LocalContext.current
                val glanceId = LocalGlanceId.current
                
                // 获取 Widget ID
                val widgetId = try {
                    GlanceAppWidgetManager(context).getAppWidgetId(glanceId)
                } catch (e: Exception) {
                    -1
                }
                
                // home_widget 插件在 Android 上写入 HomeWidgetPreferences
                val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

                // 读取 per-instance 数据
                val titleKey = "title_$widgetId"
                val tsKey = "target_ts_$widgetId"

                val title = prefs.getString(titleKey, null)
                val targetTs = prefs.getLong(tsKey, 0L)

                if (title == null || targetTs == 0L) {
                    // 未配置 -> 显示 "点击设置" placeholder
                    Box(
                        modifier = GlanceModifier
                            .fillMaxSize()
                            .cornerRadius(12.dp)
                            .background(ColorProvider(Color(0xFF1E1E1E)))
                            .clickable(actionStartActivity(
                                Intent(context, MainActivity::class.java).apply {
                                    action = AppWidgetManager.ACTION_APPWIDGET_CONFIGURE
                                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                                }
                            ))
                            .padding(8.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "设置",
                            style = TextStyle(color = ColorProvider(Color.White), fontSize = 12.sp)
                        )
                    }
                } else {
                    // 已配置 -> 计算并显示天数
                    val now = System.currentTimeMillis()
                    val daysLong = if (targetTs > now) {
                        ((targetTs - now) / 86400000) + 1
                    } else {
                        ((now - targetTs) / 86400000)
                    }
                    
                    // 读取样式配置
                    val styleData = WidgetUtils.loadWidgetStyle(prefs, widgetId)
                    val cornerRadius = styleData.cornerRadius.dp

                    // 获取事件 ID 用于点击跳转
                    val widgetEventId = prefs.getString("event_id_$widgetId", null)

                    MiniWidgetContent(
                        days = daysLong.toInt(),
                        isFuture = targetTs > now,
                        styleData = styleData,
                        eventId = widgetEventId
                    )
                }
            }
        }
    }

    @androidx.compose.runtime.Composable
    private fun MiniWidgetContent(
        days: Int,
        isFuture: Boolean,
        styleData: WidgetUtils.WidgetData,
        eventId: String? = null
    ) {
        val context = LocalContext.current
        
        // 根据样式计算背景色
        val bgColor = when (styleData.style) {
            WidgetUtils.WidgetStyle.GRADIENT -> {
                WidgetUtils.applyOpacity(
                    WidgetUtils.blendColors(styleData.backgroundColor, styleData.gradientEndColor, 0.5f),
                    styleData.opacity
                )
            }
            WidgetUtils.WidgetStyle.GLASSMORPHISM -> {
                WidgetUtils.applyOpacity(styleData.backgroundColor, styleData.opacity * 0.7f)
            }
            else -> {
                WidgetUtils.applyOpacity(styleData.backgroundColor, styleData.opacity)
            }
        }
        
        // 字体缩放
        val daysSize = 28.sp * styleData.fontSize.daysScale
        val labelSize = 10.sp * styleData.fontSize.titleScale
        
        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .cornerRadius(styleData.cornerRadius.dp)
                .background(ColorProvider(bgColor))
                .clickable(actionStartActivity(
                    Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        eventId?.let { putExtra("event_id", it) }
                    }
                )),
            contentAlignment = Alignment.Center
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // 天数
                Text(
                    text = days.toString(),
                    style = TextStyle(
                        color = ColorProvider(styleData.textColor),
                        fontSize = daysSize,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center
                    )
                )
                // "天"字
                Text(
                    text = "天",
                    style = TextStyle(
                        color = ColorProvider(styleData.textColor),
                        fontSize = labelSize,
                        textAlign = TextAlign.Center
                    )
                )
            }
        }
    }
}

/**
 * 迷你小部件 Receiver (1×1)
 */
class CountdownMiniWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = CountdownMiniGlanceWidget()

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        // 系统触发更新时重新加载数据
    }
}
