package com.example.anime_waifu

import android.app.ActivityManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.BatteryManager
import android.widget.RemoteViews
import kotlin.math.roundToInt

internal object WidgetSupport {
    fun launchAppPendingIntent(context: Context, requestCode: Int = 0): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    fun wireClicks(views: RemoteViews, pendingIntent: PendingIntent, vararg ids: Int) {
        ids.forEach { id -> views.setOnClickPendingIntent(id, pendingIntent) }
    }

    fun readString(value: String?, fallback: String): String {
        val trimmed = value?.trim()
        return if (trimmed.isNullOrEmpty()) fallback else trimmed
    }

    fun batteryPercent(context: Context): Int {
        val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
        return batteryManager
            ?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            ?.coerceIn(0, 100)
            ?: 0
    }

    fun memoryPercent(context: Context): Int {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
        val info = ActivityManager.MemoryInfo()
        activityManager?.getMemoryInfo(info)
        if (info.totalMem <= 0L) return 0
        val usedFraction = (info.totalMem - info.availMem).toDouble() / info.totalMem.toDouble()
        return (usedFraction * 100).roundToInt().coerceIn(0, 100)
    }
}
