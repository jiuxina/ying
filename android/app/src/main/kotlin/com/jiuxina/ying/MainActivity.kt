package com.jiuxina.ying

import android.app.WallpaperManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.drawable.BitmapDrawable
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "ying/settings",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openAppNotificationSettings" -> {
                    val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                    startActivity(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "ying/wallpaper",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getWallpaperColors" -> {
                    val palette = WallpaperPalette.extract(this)
                    if (palette == null) {
                        result.error(
                            "unavailable",
                            "壁纸颜色不可用",
                            null,
                        )
                    } else {
                        result.success(
                            mapOf(
                                "primary" to palette.primary,
                                "dark" to palette.dark,
                                "text" to palette.text,
                            ),
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}

data class WallpaperPalette(
    val primary: Int,
    val dark: Int,
    val text: Int,
) {
    companion object {
        fun extract(context: Context): WallpaperPalette? {
            val manager = WallpaperManager.getInstance(context)
            if (Build.VERSION.SDK_INT >= 26) {
                val colors = manager.getWallpaperColors(WallpaperManager.FLAG_SYSTEM)
                    ?: manager.getWallpaperColors(WallpaperManager.FLAG_LOCK)
                if (colors != null) {
                    val primary = colors.primaryColor?.toArgb() ?: Color.rgb(15, 118, 110)
                    val dark = colors.tertiaryColor?.toArgb() ?: darken(primary)
                    return WallpaperPalette(primary, dark, contrastTextColor(primary))
                }
            }
            val drawable = manager.drawable ?: return null
            val source = when (drawable) {
                is BitmapDrawable -> drawable.bitmap
                else -> null
            } ?: return null
            val sampled = Bitmap.createScaledBitmap(source, 1, 1, true)
            val primary = sampled.getPixel(0, 0)
            if (sampled != source) sampled.recycle()
            return WallpaperPalette(primary, darken(primary), contrastTextColor(primary))
        }
    }
}
