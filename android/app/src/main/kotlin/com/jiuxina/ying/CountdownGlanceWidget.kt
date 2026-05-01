package com.jiuxina.ying

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.LocalContext
import androidx.glance.LocalGlanceId
import androidx.glance.LocalSize
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
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

/**
 * 标准倒计时小部件 (2×2) - 使用 Jetpack Glance
 * 支持响应式尺寸、多种样式和多实例独立配置
 */
class CountdownGlanceWidget : GlanceAppWidget() {

    companion object {
        // 支持的尺寸
        private val SMALL_SIZE = DpSize(110.dp, 110.dp)
        private val MEDIUM_SIZE = DpSize(180.dp, 110.dp)
        private val LARGE_SIZE = DpSize(250.dp, 180.dp)
    }

    override val sizeMode = SizeMode.Responsive(
        setOf(SMALL_SIZE, MEDIUM_SIZE, LARGE_SIZE)
    )

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
                val dateKey = "date_str_$widgetId"

                val title = prefs.getString(titleKey, null)
                val targetTs = prefs.getLong(tsKey, 0L)
                val dateStr = prefs.getString(dateKey, "") ?: ""

                if (title == null) {
                    // 未配置 -> 显示 "点击设置" placeholder
                    val widgetEventId = prefs.getString("event_id_$widgetId", null)
                    Box(
                        modifier = GlanceModifier
                            .fillMaxSize()
                            .cornerRadius(16.dp)
                            .background(ColorProvider(Color(0xFF1E1E1E)))
                            .clickable(actionStartActivity(
                                Intent(context, MainActivity::class.java).apply {
                                    action = AppWidgetManager.ACTION_APPWIDGET_CONFIGURE
                                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                                    widgetEventId?.let { putExtra("event_id", it) }
                                }
                            ))
                            .padding(16.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "点击设置",
                            style = TextStyle(color = ColorProvider(Color.White), fontSize = 14.sp)
                        )
                    }
                } else {
                    // 已配置 -> 计算并显示
                    val now = System.currentTimeMillis()
                    val daysLong = if (targetTs > now) {
                        ((targetTs - now) / 86400000) + 1
                    } else {
                        ((now - targetTs) / 86400000)
                    }
                    val prefix = if (targetTs > now) "还有" else "已经"

                    // 读取样式配置 (per-widget)
                    val styleData = WidgetUtils.loadWidgetStyle(prefs, widgetId)
                    
                    // 如果 per-widget 样式不存在，尝试读取全局样式
                    val finalStyleStr = prefs.getString("style_${widgetId}_style", null)
                        ?: prefs.getString("widget_standard_style", "standard")
                    
                    val finalBgColor = if (styleData.backgroundColor != 0xFF6366F1.toInt()) {
                        styleData.backgroundColor
                    } else {
                        try {
                            prefs.getInt("widget_standard_bg_color", styleData.backgroundColor)
                        } catch (e: Exception) {
                            styleData.backgroundColor
                        }
                    }
                    
                    val finalShowDate = if (prefs.getString("style_${widgetId}_style", null) != null) {
                        styleData.showDate
                    } else {
                        try {
                            prefs.getBoolean("widget_standard_show_date", styleData.showDate)
                        } catch (e: Exception) {
                            styleData.showDate
                        }
                    }
                    
                    val finalShowTitle = if (prefs.getString("style_${widgetId}_style", null) != null) {
                        styleData.showTitle
                    } else {
                        try {
                            prefs.getBoolean("widget_standard_show_title", true)
                        } catch (e: Exception) {
                            true
                        }
                    }
                    
                    val finalShowDays = if (prefs.getString("style_${widgetId}_style", null) != null) {
                        styleData.showDays
                    } else {
                        try {
                            prefs.getBoolean("widget_standard_show_days", true)
                        } catch (e: Exception) {
                            true
                        }
                    }
                    
                    val finalFontSize = styleData.fontSize
                    val finalCornerRadius = styleData.cornerRadius
                    val finalTextColor = styleData.textColor

                    // 获取事件 ID 用于点击跳转
                    val widgetEventId = prefs.getString("event_id_$widgetId", null)

                    val data = WidgetUtils.WidgetData(
                        title = title,
                        days = daysLong.toString(),
                        prefix = prefix,
                        date = dateStr,
                        backgroundColor = finalBgColor,
                        gradientEndColor = styleData.gradientEndColor,
                        opacity = styleData.opacity,
                        showDate = finalShowDate,
                        showTitle = finalShowTitle,
                        showDays = finalShowDays,
                        style = WidgetUtils.WidgetStyle.fromString(finalStyleStr),
                        fontSize = finalFontSize,
                        cornerRadius = finalCornerRadius,
                        textColor = finalTextColor,
                        backgroundImage = styleData.backgroundImage
                    )
                    
                    WidgetContent(data, widgetEventId)
                }
            }
        }
    }

    @Composable
    private fun WidgetContent(data: WidgetUtils.WidgetData, eventId: String? = null) {
        val size = LocalSize.current
        val isCompact = size.width < 150.dp
        val context = LocalContext.current
        
        // 根据样式计算背景色
        val bgColor = when (data.style) {
            WidgetUtils.WidgetStyle.GRADIENT -> {
                // Glance 不直接支持渐变，使用混合色模拟
                WidgetUtils.applyOpacity(
                    WidgetUtils.blendColors(data.backgroundColor, data.gradientEndColor, 0.5f),
                    data.opacity
                )
            }
            WidgetUtils.WidgetStyle.GLASSMORPHISM -> {
                // 毛玻璃效果使用较低透明度
                WidgetUtils.applyOpacity(data.backgroundColor, data.opacity * 0.7f)
            }
            else -> {
                WidgetUtils.applyOpacity(data.backgroundColor, data.opacity)
            }
        }
        
        // 字体缩放
        val titleSize = (if (isCompact) 12.sp else 14.sp) * data.fontSize.titleScale
        val daysSize = (if (isCompact) 24.sp else 32.sp) * data.fontSize.daysScale
        val labelSize = (if (isCompact) 10.sp else 12.sp) * data.fontSize.titleScale
        val dateSize = (if (isCompact) 9.sp else 10.sp) * data.fontSize.titleScale
        
        val cornerRadius = data.cornerRadius.dp
        
        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .cornerRadius(cornerRadius)
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
                modifier = GlanceModifier
                    .fillMaxSize()
                    .padding(if (isCompact) 8.dp else 12.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // 事件标题
                if (data.showTitle) {
                    Text(
                        text = data.title,
                        style = TextStyle(
                            color = ColorProvider(data.textColor),
                            fontSize = titleSize,
                            fontWeight = FontWeight.Bold,
                            textAlign = TextAlign.Center
                        ),
                        maxLines = 1
                    )
                    Spacer(modifier = GlanceModifier.height(if (isCompact) 4.dp else 8.dp))
                }
                
                // 天数显示
                if (data.showDays) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = data.prefix,
                            style = TextStyle(
                                color = ColorProvider(WidgetUtils.applyOpacity(data.textColor, 0.8f)),
                                fontSize = labelSize
                            )
                        )
                        Spacer(modifier = GlanceModifier.width(4.dp))
                        Text(
                            text = data.days,
                            style = TextStyle(
                                color = ColorProvider(data.textColor),
                                fontSize = daysSize,
                                fontWeight = FontWeight.Bold
                            )
                        )
                        Spacer(modifier = GlanceModifier.width(2.dp))
                        Text(
                            text = "天",
                            style = TextStyle(
                                color = ColorProvider(WidgetUtils.applyOpacity(data.textColor, 0.8f)),
                                fontSize = labelSize
                            )
                        )
                    }
                }
                
                // 目标日期
                if (data.showDate && data.date.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    Text(
                        text = data.date,
                        style = TextStyle(
                            color = ColorProvider(WidgetUtils.applyOpacity(data.textColor, 0.6f)),
                            fontSize = dateSize,
                            textAlign = TextAlign.Center
                        ),
                        maxLines = 1
                    )
                }
            }
        }
    }
}

/**
 * 标准小部件 Receiver (2×2)
 */
class CountdownWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = CountdownGlanceWidget()

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        // 系统触发更新时重新加载数据
        // Glance 会自动处理 provideGlance 调用
    }
}
