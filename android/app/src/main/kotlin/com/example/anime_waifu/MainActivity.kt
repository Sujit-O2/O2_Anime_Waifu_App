package com.example.anime_waifu

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.Gravity
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "anime_waifu/assistant_mode"
    private val assistantChannelId = "assistant_mode_channel"
    private val wakeEventChannelId = "assistant_wake_event_channel"
    private val assistantNotificationId = 2002
    private val wakeEventNotificationId = 2003
    private var overlayView: LinearLayout? = null
    private var overlayStatusText: TextView? = null
    private var overlayTranscriptText: TextView? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val apiKey = call.argument<String>("apiKey")
                        val apiUrl = call.argument<String>("apiUrl")
                        val model = call.argument<String>("model")
                        val intervalMs = call.argument<Long>("intervalMs")
                        startAssistantService(apiKey, apiUrl, model, intervalMs)
                        result.success(true)
                    }
                    "stop" -> {
                        stopAssistantService()
                        result.success(true)
                    }
                    "isRunning" -> {
                        result.success(AssistantForegroundService.isRunning)
                    }
                    "bringToFront" -> {
                        bringAppToFront()
                        result.success(true)
                    }
                    "canDrawOverlays" -> {
                        result.success(canDrawOverlays())
                    }
                    "requestOverlayPermission" -> {
                        requestOverlayPermission()
                        result.success(true)
                    }
                    "showOverlay" -> {
                        val status = call.argument<String>("status") ?: "Listening..."
                        val transcript = call.argument<String>("transcript") ?: ""
                        showOverlay(status, transcript)
                        result.success(true)
                    }
                    "updateOverlay" -> {
                        val status = call.argument<String>("status") ?: "Listening..."
                        val transcript = call.argument<String>("transcript") ?: ""
                        updateOverlay(status, transcript)
                        result.success(true)
                    }
                    "hideOverlay" -> {
                        hideOverlay()
                        result.success(true)
                    }
                    "canPostNotifications" -> {
                        result.success(canPostNotifications())
                    }
                    "requestNotificationPermission" -> {
                        requestNotificationPermission()
                        result.success(true)
                    }
                    "showListeningNotification" -> {
                        val status = call.argument<String>("status") ?: "Listening..."
                        val transcript = call.argument<String>("transcript") ?: ""
                        val pulse = call.argument<Boolean>("pulse") ?: false
                        showListeningNotification(status, transcript, pulse)
                        result.success(true)
                    }
                    "setAssistantIdleNotification" -> {
                        setAssistantIdleNotification()
                        result.success(true)
                    }
                    "openNotificationSettings" -> {
                        openNotificationSettings()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startAssistantService(apiKey: String?, apiUrl: String?, model: String?, intervalMs: Long?) {
        val intent = Intent(this, AssistantForegroundService::class.java).apply {
            putExtra("API_KEY", apiKey)
            putExtra("API_URL", apiUrl)
            putExtra("MODEL", model)
            if (intervalMs != null) putExtra("INTERVAL_MS", intervalMs)
        }
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

    private fun bringAppToFront() {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        launchIntent?.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
        )
        if (launchIntent != null) {
            startActivity(launchIntent)
        }
    }

    private fun canPostNotifications(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !canPostNotifications()) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                1002
            )
        }
    }

    private fun openNotificationSettings() {
        val intent = Intent().apply {
            action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !canDrawOverlays()) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivity(intent)
        }
    }

    private fun showOverlay(status: String, transcript: String) {
        if (!canDrawOverlays()) return

        runOnUiThread {
            if (overlayView == null) {
                val root = LinearLayout(this).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(40, 30, 40, 30)
                    setBackgroundColor(Color.parseColor("#CC1E1E1E"))
                }

                val statusText = TextView(this).apply {
                    setTextColor(Color.parseColor("#FFFF5252"))
                    textSize = 16f
                }
                val transcriptText = TextView(this).apply {
                    setTextColor(Color.WHITE)
                    textSize = 14f
                }

                root.addView(statusText)
                root.addView(transcriptText)
                overlayView = root
                overlayStatusText = statusText
                overlayTranscriptText = transcriptText

                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                    else
                        WindowManager.LayoutParams.TYPE_PHONE,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
                    y = 160
                }

                val wm = getSystemService(WINDOW_SERVICE) as WindowManager
                wm.addView(root, params)
            }

            overlayStatusText?.text = status
            overlayTranscriptText?.text = if (transcript.isBlank()) "Say something..." else transcript
        }
    }

    private fun updateOverlay(status: String, transcript: String) {
        runOnUiThread {
            overlayStatusText?.text = status
            overlayTranscriptText?.text = if (transcript.isBlank()) "Say something..." else transcript
        }
    }

    private fun hideOverlay() {
        runOnUiThread {
            val view = overlayView ?: return@runOnUiThread
            val wm = getSystemService(WINDOW_SERVICE) as WindowManager
            wm.removeView(view)
            overlayView = null
            overlayStatusText = null
            overlayTranscriptText = null
        }
    }

    private fun setAssistantIdleNotification() {
        if (!canPostNotifications()) return
        ensureNotificationChannels()
        val manager = getSystemService(NotificationManager::class.java)
        val notification = NotificationCompat.Builder(this, assistantChannelId)
            .setContentTitle("Zero Two Assistant")
            .setContentText("Wake word is active in background")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        manager?.notify(assistantNotificationId, notification)
    }

    private fun showListeningNotification(status: String, transcript: String, pulse: Boolean) {
        if (!canPostNotifications()) return
        ensureNotificationChannels()
        val manager = getSystemService(NotificationManager::class.java)

        val body = if (transcript.isBlank()) {
            status
        } else {
            "$status\n$transcript"
        }

        val mainNotification = NotificationCompat.Builder(this, assistantChannelId)
            .setContentTitle("Zero Two Assistant")
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        manager?.notify(assistantNotificationId, mainNotification)

        if (pulse) {
            val wakeNotification = NotificationCompat.Builder(this, wakeEventChannelId)
                .setContentTitle("Wake word detected")
                .setContentText("Zero Two is listening...")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setTimeoutAfter(4000)
                .build()
            manager?.notify(wakeEventNotificationId, wakeNotification)
        }
    }

    private fun ensureNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val assistantChannel = NotificationChannel(
                assistantChannelId,
                "Assistant Mode",
                NotificationManager.IMPORTANCE_LOW
            )
            val wakeEventChannel = NotificationChannel(
                wakeEventChannelId,
                "Wake Events",
                NotificationManager.IMPORTANCE_HIGH
            )
            manager?.createNotificationChannel(assistantChannel)
            manager?.createNotificationChannel(wakeEventChannel)
        }
    }

    override fun onDestroy() {
        hideOverlay()
        super.onDestroy()
    }
}
