package com.example.anime_waifu

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import com.example.anime_waifu.AppLog as Log

/**
 * Receives an AlarmManager broadcast scheduled by [AssistantForegroundService.onTaskRemoved]
 * to restart the foreground service after the app is swiped away on Android 12+.
 *
 * On Android 12+ (API 31), calling startForegroundService() from onTaskRemoved() throws
 * ForegroundServiceStartNotAllowedException. The AlarmManager fires a few seconds later
 * when the system considers the alarm privileged enough to allow FGS start.
 */
class AlarmRestartReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "AlarmRestartReceiver"
        const val ACTION_RESTART_SERVICE = "com.example.anime_waifu.ACTION_RESTART_ASSISTANT"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != ACTION_RESTART_SERVICE) return

        // Skip restart if the service is already running.
        if (AssistantForegroundService.isRunning) {
            Log.d(TAG, "Service already running — skipping alarm restart")
            return
        }

        val flutterPrefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE
        )
        val assistantEnabled = flutterPrefs.getBoolean("flutter.assistant_mode_enabled", true)
        val wakeWordEnabled  = flutterPrefs.getBoolean("flutter.wake_word_enabled", true)

        if (!assistantEnabled && !wakeWordEnabled) {
            Log.d(TAG, "AlarmRestart: assistant and wake both disabled — skipping restart")
            return
        }

        Log.d(TAG, "AlarmRestart: restarting AssistantForegroundService")
        val serviceIntent = Intent(context, AssistantForegroundService::class.java).apply {
            putExtra("FORCE_BACKGROUND_WAKE", true)
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (e: RuntimeException) {
            Log.w(TAG, "AlarmRestart: service start blocked: ${e.message}")
        } catch (t: Throwable) {
            Log.w(TAG, "AlarmRestart: service start failed: ${t.message}")
        }
    }
}
