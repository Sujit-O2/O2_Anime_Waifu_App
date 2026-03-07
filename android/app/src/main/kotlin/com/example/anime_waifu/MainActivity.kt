package com.example.anime_waifu

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.AudioAttributes
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import android.provider.AlarmClock
import android.provider.Settings
import android.view.KeyEvent
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "anime_waifu/assistant_mode"
    private val assistantChannelId = "assistant_mode_channel_silent_v3"
    private val assistantStatusChannelId = "assistant_status_channel_v2"
    private val wakeEventChannelId = "assistant_wake_event_channel_alert_v4"
    private val wakeVibrateChannelId = "assistant_wake_event_channel_vibrate_v1"
    private val assistantNotificationId = 2002
    private val wakeEventNotificationId = 2003

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val apiKey = call.argument<String>("apiKey")
                        val apiUrl = call.argument<String>("apiUrl")
                        val model = call.argument<String>("model")
                        val systemPrompt = call.argument<String>("systemPrompt")
                        val ttsApiKey = call.argument<String>("ttsApiKey")
                        val ttsModel = call.argument<String>("ttsModel")
                        val ttsVoice = call.argument<String>("ttsVoice")
                        val ttsSpeed = call.argument<Double>("ttsSpeed")
                        val requireMicrophone = call.argument<Boolean>("requireMicrophone")
                        val intervalMs = when (val arg = call.argument<Any>("intervalMs")) {
                            is Number -> arg.toLong()
                            else -> 15000L
                        }
                        val proactiveRandomEnabled = call.argument<Boolean>("proactiveRandomEnabled")
                        startAssistantService(
                            apiKey,
                            apiUrl,
                            model,
                            systemPrompt,
                            ttsApiKey,
                            ttsModel,
                            ttsVoice,
                            ttsSpeed,
                            requireMicrophone,
                            intervalMs,
                            proactiveRandomEnabled
                        )
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
                    "openNotificationSettings" -> {
                        openNotificationSettings()
                        result.success(true)
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        result.success(isIgnoringBatteryOptimizations())
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        requestIgnoreBatteryOptimizations()
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
                    "setProactiveMode" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        setProactiveMode(enabled)
                        result.success(true)
                    }
                    "setWakeMode" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        setWakeMode(enabled)
                        result.success(true)
                    }
                    "openAppByPackage" -> {
                        val packageName = call.argument<String>("package") ?: ""
                        result.success(openAppByPackage(packageName))
                    }
                    "openResolvedIntent" -> {
                        val action = call.argument<String>("action") ?: ""
                        val category = call.argument<String>("category")
                        val data = call.argument<String>("data")
                        result.success(openResolvedIntent(action, category, data))
                    }
                    "openAppByName" -> {
                        val query = call.argument<String>("query") ?: ""
                        result.success(openAppByName(query))
                    }
                    "setLauncherIconVariant" -> {
                        val variant = call.argument<String>("variant") ?: "old"
                        result.success(setLauncherIconVariant(variant))
                    }
                    "getLauncherIconVariant" -> {
                        result.success(getLauncherIconVariant())
                    }
                    "setAlarm" -> {
                        val hour = call.argument<Int>("hour") ?: -1
                        val minute = call.argument<Int>("minute") ?: 0
                        val message = call.argument<String>("message") ?: "Zero Two Alarm"
                        result.success(setAlarm(hour, minute, message))
                    }
                    "shareText" -> {
                        val text = call.argument<String>("text") ?: ""
                        shareText(text)
                        result.success(true)
                    }
                    "toggleFlashlight" -> {
                        val on = call.argument<Boolean>("on") ?: false
                        toggleFlashlight(on)
                        result.success(true)
                    }
                    "getBatteryLevel" -> {
                        result.success(getBatteryLevel())
                    }
                    "setTimer" -> {
                        val seconds = call.argument<Int>("seconds") ?: -1
                        val message = call.argument<String>("message") ?: "Zero Two Timer"
                        result.success(setTimer(seconds, message))
                    }
                    "setVolume" -> {
                        val level = call.argument<Int>("level") ?: -1
                        setVolume(level)
                        result.success(true)
                    }
                    "isWifiConnected" -> {
                        result.success(isWifiConnected())
                    }
                    "mediaControl" -> {
                        val action = call.argument<String>("action") ?: "play"
                        sendMediaKey(action)
                        result.success(true)
                    }

                     "scheduleReminder" -> {
                        val id = call.argument<String>("id") ?: ""
                        val text = call.argument<String>("text") ?: ""
                        val delayMs = call.argument<Int>("delayMs") ?: 0
                        scheduleReminderNotification(id, text, delayMs.toLong())
                        result.success(true)
                    }
                    "addCalendarEvent" -> {
                        val title = call.argument<String>("title") ?: ""
                        val date = call.argument<String>("date") ?: ""
                        val time = call.argument<String>("time") ?: ""
                        result.success(addCalendarEvent(title, date, time))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setLauncherIconVariant(variant: String): Boolean {
        return try {
            val useNew = variant.equals("new", ignoreCase = true)
            val pm = packageManager
            val oldAlias = ComponentName(this, "com.example.anime_waifu.MainActivityOld")
            val newAlias = ComponentName(this, "com.example.anime_waifu.MainActivityNew")

            pm.setComponentEnabledSetting(
                oldAlias,
                if (useNew) PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                else PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )
            pm.setComponentEnabledSetting(
                newAlias,
                if (useNew) PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun getLauncherIconVariant(): String {
        return try {
            val pm = packageManager
            val oldAlias = ComponentName(this, "com.example.anime_waifu.MainActivityOld")
            val newAlias = ComponentName(this, "com.example.anime_waifu.MainActivityNew")
            val oldEnabled = componentEnabled(pm, oldAlias, defaultEnabled = true)
            val newEnabled = componentEnabled(pm, newAlias, defaultEnabled = false)
            if (newEnabled && !oldEnabled) "new" else "old"
        } catch (_: Exception) {
            "old"
        }
    }

    private fun componentEnabled(
        pm: PackageManager,
        component: ComponentName,
        defaultEnabled: Boolean
    ): Boolean {
        return when (pm.getComponentEnabledSetting(component)) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED_USER,
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED_UNTIL_USED -> false
            PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> defaultEnabled
            else -> defaultEnabled
        }
    }

    private fun startAssistantService(
        apiKey: String?,
        apiUrl: String?,
        model: String?,
        systemPrompt: String?,
        ttsApiKey: String?,
        ttsModel: String?,
        ttsVoice: String?,
        ttsSpeed: Double?,
        requireMicrophone: Boolean?,
        intervalMs: Long?,
        proactiveRandomEnabled: Boolean?
    ) {
        val intent = Intent(this, AssistantForegroundService::class.java).apply {
            putExtra("API_KEY", apiKey)
            putExtra("API_URL", apiUrl)
            putExtra("MODEL", model)
            putExtra("SYSTEM_PROMPT", systemPrompt)
            putExtra("TTS_API_KEY", ttsApiKey)
            putExtra("TTS_MODEL", ttsModel)
            putExtra("TTS_VOICE", ttsVoice)
            if (ttsSpeed != null) putExtra("TTS_SPEED", ttsSpeed)
            if (requireMicrophone != null) putExtra("REQUIRE_MICROPHONE", requireMicrophone)
            if (intervalMs != null) putExtra("INTERVAL_MS", intervalMs)
            if (proactiveRandomEnabled != null) {
                putExtra("PROACTIVE_RANDOM_ENABLED", proactiveRandomEnabled)
            }
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

    private fun openAppByPackage(targetPackage: String): Boolean {
        return AppLaunchResolver.openByPackage(this, targetPackage)
    }

    private fun openResolvedIntent(
        action: String,
        category: String?,
        data: String?
    ): Boolean {
        return AppLaunchResolver.openResolvedIntent(this, action, category, data)
    }

    private fun openAppByName(query: String): String? {
        return AppLaunchResolver.openByName(this, query)
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

    private fun setProactiveMode(enabled: Boolean) {
        val intent = Intent(this, AssistantForegroundService::class.java).apply {
            action = "SET_PROACTIVE_MODE"
            putExtra("ENABLED", enabled)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun setWakeMode(enabled: Boolean) {
        val intent = Intent(this, AssistantForegroundService::class.java).apply {
            action = "SET_WAKE_MODE"
            putExtra("ENABLED", enabled)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun openNotificationSettings() {
        try {
            val intent = Intent().apply {
                action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (_: Exception) {
            val fallbackIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(fallbackIntent)
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val pm = getSystemService(POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(packageName)
    }

    private fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        if (isIgnoringBatteryOptimizations()) return
        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun canDrawOverlays(): Boolean {
        return AssistantOverlayController.canDrawOverlays(this)
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
        AssistantOverlayController.show(
            applicationContext,
            status = status,
            transcript = transcript
        )
    }

    private fun updateOverlay(status: String, transcript: String) {
        AssistantOverlayController.update(
            applicationContext,
            status = status,
            transcript = transcript
        )
    }

    private fun hideOverlay() {
        AssistantOverlayController.hide()
    }

    private fun setAssistantIdleNotification() {
        if (!canPostNotifications()) return
        ensureNotificationChannels()
        val manager = getSystemService(NotificationManager::class.java)
        val openPendingIntent = buildLaunchPendingIntent(assistantNotificationId)
        val notification = NotificationCompat.Builder(this, assistantStatusChannelId)
            .setContentTitle("O2-WAIFU Assistant")
            .setContentText("Wake word is active in background")
            .setSubText("Background status")
            .setSmallIcon(R.drawable.ic_stat_waifu)
            .setLargeIcon(BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher))
            .setContentIntent(openPendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
        manager?.notify(assistantNotificationId, notification)
    }

    private fun showListeningNotification(status: String, transcript: String, pulse: Boolean) {
        if (!canPostNotifications()) return
        ensureNotificationChannels()
        val manager = getSystemService(NotificationManager::class.java)
        val openPendingIntent = buildLaunchPendingIntent(wakeEventNotificationId)
        val largeIcon = BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)

        val body = if (transcript.isBlank()) {
            status
        } else {
            "$status\n$transcript"
        }

        val mainNotification = NotificationCompat.Builder(this, assistantStatusChannelId)
            .setContentTitle("Zero Two Assistant")
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setSmallIcon(R.drawable.ic_stat_waifu)
            .setLargeIcon(largeIcon)
            .setSubText("Live status")
            .setContentIntent(openPendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        manager?.notify(assistantNotificationId, mainNotification)

        if (pulse) {
            val isWakeDetection = isWakeDetectionPulse(status, transcript)
            val pulseChannel = if (isWakeDetection) wakeVibrateChannelId else wakeEventChannelId
            val wakeNotification = NotificationCompat.Builder(this, pulseChannel)
                .setContentTitle(if (status.isNotBlank()) status else "Wake word detected")
                .setContentText(if (transcript.isNotBlank()) transcript else "Zero Two is listening...")
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setSmallIcon(R.drawable.ic_stat_waifu)
                .setLargeIcon(largeIcon)
                .setSubText("Tap to open O2-WAIFU")
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setOnlyAlertOnce(false)
                .setContentIntent(openPendingIntent)
                .setDefaults(NotificationCompat.DEFAULT_LIGHTS or NotificationCompat.DEFAULT_VIBRATE)
                .setCategory(NotificationCompat.CATEGORY_MESSAGE)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setTimeoutAfter(15000)
                .build()
            manager?.notify(wakeEventNotificationId, wakeNotification)
        }
    }

    private fun isWakeDetectionPulse(status: String, transcript: String): Boolean {
        val s = status.lowercase()
        val t = transcript.lowercase()
        return s.contains("wake word") ||
            t.contains("wake word") ||
            s.contains("speak your command") ||
            t.contains("speak your command")
    }

    private fun ensureNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val assistantChannel = NotificationChannel(
                assistantChannelId,
                "Assistant Mode",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                setSound(null, null)
                enableVibration(false)
            }
            val assistantStatusChannel = NotificationChannel(
                assistantStatusChannelId,
                "Assistant Status",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                setSound(null, null)
                enableVibration(false)
                vibrationPattern = longArrayOf(0L)
            }
            val wakeEventChannel = NotificationChannel(
                wakeEventChannelId,
                "Wake Events (Alert)",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                setSound(notificationSoundUri(), notificationAudioAttributes())
                enableVibration(true)
                vibrationPattern = longArrayOf(0L, 180L, 120L, 180L)
            }
            val wakeVibrateChannel = NotificationChannel(
                wakeVibrateChannelId,
                "Wake Events (Vibrate)",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                setSound(null, null)
                enableVibration(true)
                vibrationPattern = longArrayOf(0L, 180L, 120L, 180L)
            }
            manager?.createNotificationChannel(assistantChannel)
            manager?.createNotificationChannel(assistantStatusChannel)
            manager?.createNotificationChannel(wakeEventChannel)
            manager?.createNotificationChannel(wakeVibrateChannel)
        }
    }

    private fun buildLaunchPendingIntent(requestCode: Int): PendingIntent? {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName) ?: return null
        launchIntent.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
        )
        return PendingIntent.getActivity(
            this,
            requestCode,
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    private fun notificationSoundUri(): Uri {
        return Uri.parse("android.resource://$packageName/${R.raw.dar}")
    }

    private fun notificationAudioAttributes(): AudioAttributes {
        return AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
    }

    private fun setAlarm(hour: Int, minute: Int, message: String): Boolean {
        if (hour < 0 || hour > 23) return false
        return try {
            val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
                putExtra(AlarmClock.EXTRA_HOUR, hour)
                putExtra(AlarmClock.EXTRA_MINUTES, minute)
                putExtra(AlarmClock.EXTRA_MESSAGE, message)
                putExtra(AlarmClock.EXTRA_SKIP_UI, false)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun shareText(text: String) {
        if (text.isBlank()) return
        try {
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            val chooser = Intent.createChooser(intent, "Share via").apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(chooser)
        } catch (_: Exception) {}
    }

    private fun toggleFlashlight(on: Boolean) {
        try {
            val cameraManager = getSystemService(CAMERA_SERVICE) as CameraManager
            val cameraId = cameraManager.cameraIdList.firstOrNull { id ->
                val chars = cameraManager.getCameraCharacteristics(id)
                chars.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            } ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                cameraManager.setTorchMode(cameraId, on)
            }
        } catch (_: Exception) {}
    }

    private fun getBatteryLevel(): Int {
        return try {
            val bm = getSystemService(BATTERY_SERVICE) as BatteryManager
            bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } catch (_: Exception) {
            -1
        }
    }

    private fun setTimer(seconds: Int, message: String): Boolean {
        if (seconds <= 0) return false
        return try {
            val intent = Intent(AlarmClock.ACTION_SET_TIMER).apply {
                putExtra(AlarmClock.EXTRA_LENGTH, seconds)
                putExtra(AlarmClock.EXTRA_MESSAGE, message)
                putExtra(AlarmClock.EXTRA_SKIP_UI, false)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (_: Exception) { false }
    }

    private fun setVolume(level: Int) {
        if (level < 0 || level > 100) return
        try {
            val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            val scaled = (level / 100.0 * max).toInt()
            am.setStreamVolume(AudioManager.STREAM_MUSIC, scaled, AudioManager.FLAG_SHOW_UI)
        } catch (_: Exception) {}
    }

    private fun isWifiConnected(): Boolean {
        return try {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = cm.activeNetwork ?: return false
            val caps = cm.getNetworkCapabilities(network) ?: return false
            caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
        } catch (_: Exception) { false }
    }

    private fun sendMediaKey(action: String) {
        try {
            val keyCode = when (action) {
                "pause", "play" -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
                "next" -> KeyEvent.KEYCODE_MEDIA_NEXT
                "prev" -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
                else -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
            }
            val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            am.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
            am.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, keyCode))
        } catch (_: Exception) {}
    }

    private fun openResolvedIntent(action: String, category: String?): Boolean {
        return try {
            val intent = Intent(action).apply {
                if (category != null) addCategory(category)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                true
            } else false
        } catch (_: Exception) { false }
    }

    private fun scheduleReminderNotification(id: String, text: String, delayMs: Long) {
        try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val notifIntent = Intent(this, MainActivity::class.java).apply {
                putExtra("reminder_text", text)
                putExtra("reminder_id", id)
            }
            val pending = PendingIntent.getActivity(
                this, id.hashCode(), notifIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            val triggerAt = System.currentTimeMillis() + delayMs
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pending)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pending)
            }
        } catch (_: Exception) {}
    }

    private fun addCalendarEvent(title: String, date: String, time: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_INSERT).apply {
                data = android.provider.CalendarContract.Events.CONTENT_URI
                putExtra(android.provider.CalendarContract.Events.TITLE, title)
                if (date.isNotBlank()) {
                    // Best effort: if date is parseable we add it, otherwise calendar opens clean
                    putExtra(android.provider.CalendarContract.EXTRA_EVENT_ALL_DAY, false)
                }
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                true
            } else false
        } catch (_: Exception) { false }
    }

    override fun onDestroy() {
        AssistantOverlayController.hide()
        super.onDestroy()
    }
}

