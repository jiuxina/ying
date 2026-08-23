package com.jiuxina.ying

import android.app.WallpaperManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.drawable.BitmapDrawable
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "ying/permissions",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> {
                    result.success(isIgnoringBatteryOptimizations())
                }
                "requestIgnoreBatteryOptimizations" -> {
                    result.success(requestIgnoreBatteryOptimizations())
                }
                "autoStartSupported" -> {
                    result.success(autoStartActivityComponent() != null)
                }
                "openAutoStartSettings" -> {
                    result.success(openAutoStartSettings())
                }
                "openAppDetailsSettings" -> {
                    result.success(openAppDetailsSettings())
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.jiuxina.ying/device",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "androidId" -> {
                    try {
                        result.success(
                            Settings.Secure.getString(
                                contentResolver,
                                Settings.Secure.ANDROID_ID,
                            ),
                        )
                    } catch (error: Exception) {
                        result.error("unavailable", error.message, null)
                    }
                }
                "abis" -> {
                    result.success(Build.SUPPORTED_ABIS.toList())
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "ying/installer",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("bad_argument", "缺少安装包路径", null)
                        return@setMethodCallHandler
                    }
                    val file = File(path)
                    if (!file.exists()) {
                        result.error("not_found", "安装包不存在", null)
                        return@setMethodCallHandler
                    }
                    if (!packageManager.canRequestPackageInstalls()) {
                        result.success(mapOf("permissionRequired" to true))
                        return@setMethodCallHandler
                    }
                    val uri = FileProvider.getUriForFile(
                        this,
                        "$packageName.fileprovider",
                        file,
                    )
                    val intent = Intent(Intent.ACTION_VIEW)
                        .setDataAndType(uri, "application/vnd.android.package-archive")
                        .addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK or
                                Intent.FLAG_GRANT_READ_URI_PERMISSION,
                        )
                    startActivity(intent)
                    result.success(mapOf("permissionRequired" to false))
                }
                "openInstallPermissionSettings" -> {
                    val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
                        .setData(Uri.parse("package:$packageName"))
                    if (resolveActivity(intent)) {
                        startActivity(intent)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }

    private fun requestIgnoreBatteryOptimizations(): Map<String, Any> {
        if (isIgnoringBatteryOptimizations()) {
            return mapOf("opened" to true, "fallback" to false)
        }
        try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                .setData(Uri.parse("package:$packageName"))
            if (resolveActivity(intent)) {
                startActivity(intent)
                return mapOf("opened" to true, "fallback" to false)
            }
        } catch (_: Exception) {
            // 部分 ROM 不支持专用请求页，继续走应用详情兜底。
        }
        val fallback = openAppDetailsSettings()
        return mapOf("opened" to fallback, "fallback" to fallback)
    }

    private fun autoStartCandidates(): List<Pair<String, String>> = listOf(
        "com.miui.securitycenter" to "com.miui.permcenter.autostart.AutoStartManagementActivity",
        "com.huawei.systemmanager" to "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
        "com.huawei.systemmanager" to "com.huawei.systemmanager.optimize.process.ProtectActivity",
        "com.coloros.safecenter" to "com.coloros.safecenter.permission.startup.StartupAppListActivity",
        "com.coloros.safecenter" to "com.coloros.safecenter.startupapp.StartupAppListActivity",
        "com.oppo.safe" to "com.oppo.safe.permission.startup.StartupAppListActivity",
        "com.oneplus.security" to "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity",
        "com.vivo.permissionmanager" to "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
        "com.iqoo.secure" to "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager",
        "com.samsung.android.lool" to "com.samsung.android.sm.ui.battery.BatteryActivity",
        "com.meizu.safe" to "com.meizu.safe.permission.SmartBGActivity",
        "com.letv.android.letvsafe" to "com.letv.android.letvsafe.AutobootManageActivity",
        "com.asus.mobilemanager" to "com.asus.mobilemanager.entry.FunctionActivity",
    )

    private fun autoStartActivityComponent(): Pair<String, String>? {
        for ((pkg, cls) in autoStartCandidates()) {
            val intent = Intent().setClassName(pkg, cls)
            if (resolveActivity(intent)) return pkg to cls
        }
        return null
    }

    private fun openAutoStartSettings(): Map<String, Any> {
        val component = autoStartActivityComponent()
        if (component != null) {
            try {
                startActivity(
                    Intent().setClassName(component.first, component.second),
                )
                return mapOf("opened" to true, "fallback" to false)
            } catch (_: Exception) {
                // 组件解析成功但启动失败时继续走应用详情兜底。
            }
        }
        val fallback = openAppDetailsSettings()
        return mapOf("opened" to fallback, "fallback" to fallback)
    }

    private fun openAppDetailsSettings(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.parse("package:$packageName"))
            if (resolveActivity(intent)) {
                startActivity(intent)
                true
            } else {
                false
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun resolveActivity(intent: Intent): Boolean =
        intent.resolveActivity(packageManager) != null
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
