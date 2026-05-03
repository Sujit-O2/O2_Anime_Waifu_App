package com.example.anime_waifu

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log

class AssistantShortcutActivity : Activity() {
    companion object {
        private const val TAG = "AssistantShortcut"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val canDraw = AssistantOverlayController.canDrawOverlays(this)
        Log.e(TAG, "canDrawOverlays=$canDraw")

        if (canDraw) {
            // Show overlay directly — this activity has a valid window context
            // Keep activity alive briefly so WindowManager can attach the view
            Handler(Looper.getMainLooper()).post {
                Log.e(TAG, "Calling showNow directly")
                val shown = AssistantOverlayController.showNow(
                    this,
                    status = "Zero Two",
                    transcript = "How can I help?",
                    autoHideMs = 300_000L
                )
                Log.e(TAG, "showNow returned: $shown")

                // Also start the service so it can handle voice commands
                try {
                    val svcIntent = Intent(this, AssistantForegroundService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(svcIntent)
                    } else {
                        startService(svcIntent)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "startService failed: ${e.message}")
                }

                // Delay finish so overlay attaches before activity dies
                Handler(Looper.getMainLooper()).postDelayed({
                    finish()
                    @Suppress("DEPRECATION")
                    overridePendingTransition(0, 0)
                }, 200)
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
            startActivity(intent)
            finish()
            @Suppress("DEPRECATION")
            overridePendingTransition(0, 0)
        } else {
            finish()
        }
    }
}
