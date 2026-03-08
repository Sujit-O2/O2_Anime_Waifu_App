package com.example.anime_waifu

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import com.example.anime_waifu.AppLog as Log

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        val shouldHandle = action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_LOCKED_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON"

        if (!shouldHandle) return

        val flutterPrefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE
        )
        val assistantEnabled = flutterPrefs.getBoolean("flutter.assistant_mode_enabled", true)
        val proactiveEnabled = flutterPrefs.getBoolean("flutter.proactive_enabled", true)
        val wakeWordEnabled = flutterPrefs.getBoolean("flutter.wake_word_enabled", true)
        if (!assistantEnabled || (!proactiveEnabled && !wakeWordEnabled)) {
            Log.d(
                TAG,
                "Skipping boot start: assistant=$assistantEnabled proactive=$proactiveEnabled wake=$wakeWordEnabled"
            )
            return
        }

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
            Log.w(TAG, "Service start blocked by system policy: ${e.message}")
        } catch (t: Throwable) {
            Log.w(TAG, "Service start failed: ${t.message}")
        }
    }
}
