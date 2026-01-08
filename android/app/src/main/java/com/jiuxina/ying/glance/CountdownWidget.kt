package com.jiuxina.ying.glance

import android.content.Context
import android.content.Intent
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.LocalContext
import androidx.glance.LocalGlanceId
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import androidx.compose.ui.unit.sp
import androidx.compose.ui.unit.dp
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.glance.currentState
import androidx.glance.layout.Spacer
import androidx.glance.layout.height
import androidx.glance.text.FontWeight
import androidx.compose.ui.graphics.Color
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.longPreferencesKey
import com.jiuxina.ying.MainActivity
import java.util.Calendar // Correct import for Calendar computation if needed, or stick to System.currentTimeMillis

class CountdownWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = CountdownWidget()
}

class CountdownWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceTheme {
                val context = LocalContext.current
                val glanceId = LocalGlanceId.current
                val widgetId = GlanceAppWidgetManager(context).getAppWidgetId(glanceId)

                // Flutter 默认的 SharedPreferences 名称
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                
                // 读取带 ID 后缀的数据
                val titleKey = "title_$widgetId"
                val tsKey = "target_ts_$widgetId"
                val dateKey = "date_str_$widgetId"

                val title = prefs.getString(titleKey, null)
                val targetTs = prefs.getLong(tsKey, 0L)
                val dateStr = prefs.getString(dateKey, "")

                // 如果未配置，显示提示
                if (title == null) {
                     Column(
                        modifier = GlanceModifier
                            .fillMaxSize()
                            .background(Color(0xFF1E1E1E))
                            .clickable(actionStartActivity(Intent(context, MainActivity::class.java)))
                            .padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "点击设置",
                            style = TextStyle(color = ColorProvider(Color.White), fontSize = 14.sp)
                        )
                    }
                } else {
                    // 已配置，显示内容
                    val now = System.currentTimeMillis()
                    // 计算逻辑保持一致
                    val days = if (targetTs > now) {
                        ((targetTs - now) / (24 * 60 * 60 * 1000)).toLong() + 1
                    } else {
                        ((now - targetTs) / (24 * 60 * 60 * 1000)).toLong()
                    }
                    val prefix = if (targetTs > now) "还有" else "已经"

                    Column(
                        modifier = GlanceModifier
                            .fillMaxSize()
                            .background(Color(0xFF1E1E1E))
                            .clickable(actionStartActivity(Intent(context, MainActivity::class.java).apply {
                                // 点击时也可以带上 Widget ID，方便定位（可选）
                                putExtra("widget_id", widgetId)
                             }))
                            .padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = title,
                            style = TextStyle(
                                color = ColorProvider(Color.White),
                                fontSize = 14.sp
                            )
                        )
                        
                        Spacer(modifier = GlanceModifier.height(4.dp))

                        Text(
                            text = "$days",
                            style = TextStyle(
                                color = ColorProvider(Color.White),
                                fontSize = 36.sp,
                                fontWeight = FontWeight.Bold
                            )
                        )
                        
                        Text(
                            text = prefix,
                            style = TextStyle(
                                color = ColorProvider(Color.Gray),
                                fontSize = 12.sp
                            )
                        )

                        Spacer(modifier = GlanceModifier.height(4.dp))

                        Text(
                            text = dateStr ?: "",
                            style = TextStyle(
                                color = ColorProvider(Color.White.copy(alpha = 0.7f)),
                                fontSize = 12.sp
                            )
                        )
                    }
                }
            }
        }
    }
}
