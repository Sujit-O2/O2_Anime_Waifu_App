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
        val assistantPrefs = context.getSharedPreferences("assistant_prefs", Context.MODE_PRIVATE)

        val assistantEnabled = flutterPrefs.getBoolean("flutter.assistant_mode_enabled", true)
        val proactiveEnabled = flutterPrefs.getBoolean("flutter.proactive_enabled", true)
        val wakeWordEnabled = flutterPrefs.getBoolean("flutter.wake_word_enabled", true)
        val trueBgProactiveEnabled =
            flutterPrefs.getBoolean("flutter.true_background_proactive_enabled", false)

        // Also check if we have a saved API key — if yes, the user has set up the service
        val hasApiKey = !assistantPrefs.getString("api_key", null).isNullOrBlank()

        // Start if: assistant is enabled AND (proactive OR wake is on) OR trueBg is on
        // Also start if we have a saved config (user set it up before) to ensure continuity
        val shouldStart = (assistantEnabled && (proactiveEnabled || wakeWordEnabled)) ||
            trueBgProactiveEnabled ||
            (hasApiKey && assistantEnabled)

        if (!shouldStart) {
            Log.d(
                TAG,
                "Skipping boot start: assistant=$assistantEnabled proactive=$proactiveEnabled wake=$wakeWordEnabled trueBg=$trueBgProactiveEnabled hasApiKey=$hasApiKey"
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
