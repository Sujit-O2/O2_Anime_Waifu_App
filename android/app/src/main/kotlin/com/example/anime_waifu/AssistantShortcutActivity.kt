package com.example.anime_waifu

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings

class AssistantShortcutActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (AssistantOverlayController.canDrawOverlays(this)) {
            AssistantOverlayController.show(
                applicationContext,
                status = "Zero Two",
                transcript = "How can I help?",
                autoHideMs = 300_000L
            )
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            ).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        }

        finish()
        overridePendingTransition(0, 0)
    }
}
