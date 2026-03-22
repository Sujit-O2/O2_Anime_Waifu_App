package com.s002.o2_waifu

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.session.MediaSessionManager
import android.os.BatteryManager
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.s002.o2_waifu/native"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getForegroundApp" -> {
                    val app = getForegroundApp()
                    result.success(app)
                }
                "getNowPlayingInfo" -> {
                    val info = getNowPlayingInfo()
                    result.success(info)
                }
                "getBatteryInfo" -> {
                    val info = getBatteryInfo()
                    result.success(info)
                }
                "isCharging" -> {
                    result.success(isCharging())
                }
                "startForegroundService" -> {
                    startAssistantService()
                    result.success(true)
                }
                "stopForegroundService" -> {
                    stopAssistantService()
                    result.success(true)
                }
                "hasUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsageStatsPermission" -> {
                    requestUsageStatsPermission()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getForegroundApp(): String {
        if (!hasUsageStatsPermission()) return "unknown"
        try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val time = System.currentTimeMillis()
            val stats = usm.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                time - 1000 * 60,
                time
            )
            if (stats.isNullOrEmpty()) return "none"
            val sorted = stats.sortedByDescending { it.lastTimeUsed }
            return sorted.firstOrNull()?.packageName ?: "none"
        } catch (e: Exception) {
            return "error: ${e.message}"
        }
    }

    private fun getNowPlayingInfo(): Map<String, String> {
        val info = mutableMapOf<String, String>()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val msm = getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
                val controllers = msm.getActiveSessions(null)
                if (controllers.isNotEmpty()) {
                    val controller = controllers[0]
                    val metadata = controller.metadata
                    info["title"] = metadata?.getString(android.media.MediaMetadata.METADATA_KEY_TITLE) ?: "unknown"
                    info["artist"] = metadata?.getString(android.media.MediaMetadata.METADATA_KEY_ARTIST) ?: "unknown"
                    info["album"] = metadata?.getString(android.media.MediaMetadata.METADATA_KEY_ALBUM) ?: "unknown"
                    info["package"] = controller.packageName ?: "unknown"
                }
            }
        } catch (e: Exception) {
            info["error"] = e.message ?: "unknown error"
        }
        if (info.isEmpty()) {
            info["status"] = "nothing_playing"
        }
        return info
    }

    private fun getBatteryInfo(): Map<String, Any> {
        val info = mutableMapOf<String, Any>()
        val batteryIntent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        if (batteryIntent != null) {
            val level = batteryIntent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = batteryIntent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            val status = batteryIntent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
            val percentage = if (scale > 0) (level * 100 / scale) else -1
            info["level"] = percentage
            info["isCharging"] = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                    status == BatteryManager.BATTERY_STATUS_FULL
            info["status"] = when (status) {
                BatteryManager.BATTERY_STATUS_CHARGING -> "charging"
                BatteryManager.BATTERY_STATUS_DISCHARGING -> "discharging"
                BatteryManager.BATTERY_STATUS_FULL -> "full"
                BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "not_charging"
                else -> "unknown"
            }
        }
        return info
    }

    private fun isCharging(): Boolean {
        val batteryIntent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val status = batteryIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        return status == BatteryManager.BATTERY_STATUS_CHARGING ||
                status == BatteryManager.BATTERY_STATUS_FULL
    }

    private fun hasUsageStatsPermission(): Boolean {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, time - 1000 * 60, time)
        return stats != null && stats.isNotEmpty()
    }

    private fun requestUsageStatsPermission() {
        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
    }

    private fun startAssistantService() {
        val intent = Intent(this, AssistantForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopAssistantService() {
        val intent = Intent(this, AssistantForegroundService::class.java)
        stopService(intent)
    }
}
