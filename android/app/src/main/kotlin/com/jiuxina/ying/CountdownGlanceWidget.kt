package com.jiuxina.ying

import android.appwidget.AppWidgetManager
import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.LocalSize
import androidx.glance.appwidget.GlanceAppWidget
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
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable

/**
 * 标准倒计时小部件 (2×2) - 使用 Jetpack Glance
 * 支持响应式尺寸和多种样式
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
        val data = try {
            WidgetUtils.loadWidgetData(context, "standard")
        } catch (e: Exception) {
            WidgetUtils.WidgetData()
        }
        
        provideContent {
            GlanceTheme {
                WidgetContent(data)
            }
        }
    }

    @Composable
    private fun WidgetContent(data: WidgetUtils.WidgetData) {
        val size = LocalSize.current
        val isCompact = size.width < 150.dp
        
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
        
        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .cornerRadius(16.dp)
                .background(ColorProvider(bgColor))
                .clickable(actionStartActivity<MainActivity>()),
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
                Text(
                    text = data.title,
                    style = TextStyle(
                        color = ColorProvider(WidgetUtils.Colors.WHITE),
                        fontSize = if (isCompact) 12.sp else 14.sp,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center
                    ),
                    maxLines = 1
                )
                
                Spacer(modifier = GlanceModifier.height(if (isCompact) 4.dp else 8.dp))
                
                // 天数显示
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = data.prefix,
                        style = TextStyle(
                            color = ColorProvider(WidgetUtils.Colors.WHITE_80),
                            fontSize = if (isCompact) 10.sp else 12.sp
                        )
                    )
                    Spacer(modifier = GlanceModifier.width(4.dp))
                    Text(
                        text = data.days,
                        style = TextStyle(
                            color = ColorProvider(WidgetUtils.Colors.WHITE),
                            fontSize = if (isCompact) 24.sp else 32.sp,
                            fontWeight = FontWeight.Bold
                        )
                    )
                    Spacer(modifier = GlanceModifier.width(2.dp))
                    Text(
                        text = "天",
                        style = TextStyle(
                            color = ColorProvider(WidgetUtils.Colors.WHITE_80),
                            fontSize = if (isCompact) 10.sp else 12.sp
                        )
                    )
                }
                
                // 目标日期
                if (data.showDate) {
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    Text(
                        text = data.date,
                        style = TextStyle(
                            color = ColorProvider(WidgetUtils.Colors.WHITE_60),
                            fontSize = if (isCompact) 9.sp else 10.sp,
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
