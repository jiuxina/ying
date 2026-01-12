package com.jiuxina.ying

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.LocalSize
import androidx.glance.LocalContext
import androidx.glance.LocalGlanceId
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.compose.ui.graphics.Color

/**
 * 大型倒计时小部件 (4×2) - 显示主事件 + 事件列表
 * 支持响应式尺寸和多种样式
 */
class CountdownLargeGlanceWidget : GlanceAppWidget() {

    companion object {
        // 支持的尺寸
        private val STANDARD_SIZE = DpSize(250.dp, 110.dp)
        private val EXPANDED_SIZE = DpSize(350.dp, 110.dp)
        private val TALL_SIZE = DpSize(250.dp, 180.dp)
    }

    override val sizeMode = SizeMode.Responsive(
        setOf(STANDARD_SIZE, EXPANDED_SIZE, TALL_SIZE)
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
                
                val prefs = context.getSharedPreferences("${context.packageName}_preferences", Context.MODE_PRIVATE)

                // 1. 读取主事件 (ID-Based)
                val titleKey = "title_$widgetId"
                val tsKey = "target_ts_$widgetId"
                val dateKey = "date_str_$widgetId"

                val title = prefs.getString(titleKey, null)
                val targetTs = prefs.getLong(tsKey, 0L)
                val dateStr = prefs.getString(dateKey, "")

                if (title == null) {
                    // 未配置 -> 显示 "点击设置"
                    Box(
                        modifier = GlanceModifier
                            .fillMaxSize()
                            .background(ColorProvider(Color(0xFF1E1E1E)))
                            .clickable(actionStartActivity(
                                Intent(context, MainActivity::class.java).apply {
                                    action = AppWidgetManager.ACTION_APPWIDGET_CONFIGURE
                                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
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
                    // 已配置 -> 组装数据并显示
                    
                    // 计算主事件倒数日
                    val now = System.currentTimeMillis()
                    val daysLong = if (targetTs > now) {
                        ((targetTs - now) / (86400000)) + 1
                    } else {
                        ((now - targetTs) / (86400000))
                    }
                    val prefix = if (targetTs > now) "还有" else "已经"

                    // 2. 读取列表事件 (Global)
                    // 注意：这里读取的是全局的 event2, event3，所有大组件的列表部分是一样的
                    val e2Title = prefs.getString("widget_event2_title", "") ?: ""
                    val e2Days = prefs.getString("widget_event2_days", "") ?: ""
                    val e3Title = prefs.getString("widget_event3_title", "") ?: ""
                    val e3Days = prefs.getString("widget_event3_days", "") ?: ""
                    
                    // 3. 读取样式 (Global Large Style)
                    val styleStr = prefs.getString("widget_large_style", "standard")
                    val bgColor = prefs.getInt("widget_large_bg_color", 0xFF6366F1.toInt())
                    val showDate = prefs.getBoolean("widget_large_show_date", true)

                    val data = WidgetUtils.WidgetData(
                        title = title,
                        days = daysLong.toString(),
                        prefix = prefix,
                        date = dateStr ?: "",
                        backgroundColor = bgColor,
                        showDate = showDate,
                        style = WidgetUtils.WidgetStyle.fromString(styleStr),
                        
                        event2Title = e2Title,
                        event2Days = e2Days,
                        event3Title = e3Title,
                        event3Days = e3Days
                    )
                    
                    LargeWidgetContent(data)
                }
            }
        }
    }

    @Composable
    private fun LargeWidgetContent(data: WidgetUtils.WidgetData) {
        val size = LocalSize.current
        val isExpanded = size.width > 300.dp
        
        // 根据样式计算背景色
        val bgColor = when (data.style) {
            WidgetUtils.WidgetStyle.GRADIENT -> {
                WidgetUtils.applyOpacity(
                    WidgetUtils.blendColors(data.backgroundColor, data.gradientEndColor, 0.5f),
                    data.opacity
                )
            }
            WidgetUtils.WidgetStyle.GLASSMORPHISM -> {
                WidgetUtils.applyOpacity(data.backgroundColor, data.opacity * 0.7f)
            }
            else -> {
                WidgetUtils.applyOpacity(data.backgroundColor, data.opacity)
            }
        }
        
        val context = LocalContext.current
        
        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .cornerRadius(16.dp)
                .background(ColorProvider(bgColor))
                .clickable(actionStartActivity(Intent(context, MainActivity::class.java)))
        ) {
            Row(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .padding(if (isExpanded) 20.dp else 16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // 左侧：主事件
                Column(
                    modifier = GlanceModifier.defaultWeight(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = data.title,
                        style = TextStyle(
                            color = ColorProvider(WidgetUtils.Colors.WHITE),
                            fontSize = if (isExpanded) 18.sp else 16.sp,
                            fontWeight = FontWeight.Bold,
                            textAlign = TextAlign.Center
                        ),
                        maxLines = 1
                    )
                    
                    Spacer(modifier = GlanceModifier.height(8.dp))
                    
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = data.prefix,
                            style = TextStyle(
                                color = ColorProvider(WidgetUtils.Colors.WHITE_80),
                                fontSize = 12.sp
                            )
                        )
                        Spacer(modifier = GlanceModifier.width(4.dp))
                        Text(
                            text = data.days,
                            style = TextStyle(
                                color = ColorProvider(WidgetUtils.Colors.WHITE),
                                fontSize = if (isExpanded) 40.sp else 36.sp,
                                fontWeight = FontWeight.Bold
                            )
                        )
                        Spacer(modifier = GlanceModifier.width(2.dp))
                        Text(
                            text = "天",
                            style = TextStyle(
                                color = ColorProvider(WidgetUtils.Colors.WHITE_80),
                                fontSize = 12.sp
                            )
                        )
                    }
                    
                    if (data.showDate) {
                        Spacer(modifier = GlanceModifier.height(4.dp))
                        Text(
                            text = data.date,
                            style = TextStyle(
                                color = ColorProvider(WidgetUtils.Colors.WHITE_60),
                                fontSize = 10.sp
                            ),
                            maxLines = 1
                        )
                    }
                }
                
                // 分隔线
                Spacer(
                    modifier = GlanceModifier
                        .width(1.dp)
                        .fillMaxHeight()
                        .background(ColorProvider(WidgetUtils.Colors.DIVIDER))
                )
                
                // 右侧：事件列表
                Column(
                    modifier = GlanceModifier
                        .defaultWeight()
                        .padding(start = 12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (data.event2Title.isNotEmpty()) {
                        EventListItem(data.event2Title, data.event2Days)
                        Spacer(modifier = GlanceModifier.height(8.dp))
                    }
                    if (data.event3Title.isNotEmpty()) {
                        EventListItem(data.event3Title, data.event3Days)
                    }
                    if (data.event2Title.isEmpty() && data.event3Title.isEmpty()) {
                        Text(
                            text = "暂无更多事件",
                            style = TextStyle(
                                color = ColorProvider(WidgetUtils.Colors.WHITE_50),
                                fontSize = 11.sp
                            )
                        )
                    }
                }
            }
        }
    }

    @Composable
    private fun EventListItem(title: String, days: String) {
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = title,
                style = TextStyle(
                    color = ColorProvider(WidgetUtils.Colors.WHITE_80),
                    fontSize = 12.sp
                ),
                maxLines = 1,
                modifier = GlanceModifier.defaultWeight()
            )
            Spacer(modifier = GlanceModifier.width(8.dp))
            Text(
                text = days,
                style = TextStyle(
                    color = ColorProvider(WidgetUtils.Colors.WHITE),
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold
                )
            )
        }
    }
}

/**
 * 大型小部件 Receiver (4×2)
 */
class CountdownLargeWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = CountdownLargeGlanceWidget()

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        // 系统触发更新时重新加载数据
    }
}
