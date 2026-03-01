package com.example.anime_waifu

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.graphics.Color
import android.graphics.PixelFormat
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
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
    private val wakeEventChannelId = "assistant_wake_event_channel_dar"
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
                        val intervalMs = when (val arg = call.argument<Any>("intervalMs")) {
                            is Number -> arg.toLong()
                            else -> 15000L
                        }
                        val proactiveRandomEnabled = call.argument<Boolean>("proactiveRandomEnabled")
                        startAssistantService(
                            apiKey,
                            apiUrl,
                            model,
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
        intervalMs: Long?,
        proactiveRandomEnabled: Boolean?
    ) {
        val intent = Intent(this, AssistantForegroundService::class.java).apply {
            putExtra("API_KEY", apiKey)
            putExtra("API_URL", apiUrl)
            putExtra("MODEL", model)
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
        if (targetPackage.isBlank()) return false
        return try {
            val launchIntent = packageManager.getLaunchIntentForPackage(targetPackage)
            if (launchIntent != null) {
                launchIntent.addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
                )
                startActivity(launchIntent)
                return true
            }

            // Fallback: query launcher activity by package explicitly.
            val launcherIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_LAUNCHER)
                `package` = targetPackage
            }
            @Suppress("DEPRECATION")
            val candidates = packageManager.queryIntentActivities(launcherIntent, 0)
            if (!candidates.isNullOrEmpty()) {
                val first = candidates.first().activityInfo
                val explicit = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_LAUNCHER)
                    component = ComponentName(first.packageName, first.name)
                    addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP
                    )
                }
                startActivity(explicit)
                return true
            }

            // Last-resort hardcoded launch components for popular apps.
            val knownClasses = knownLaunchComponents(targetPackage)
            for (className in knownClasses) {
                try {
                    val explicit = Intent(Intent.ACTION_MAIN).apply {
                        addCategory(Intent.CATEGORY_LAUNCHER)
                        component = ComponentName(targetPackage, className)
                        addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK or
                                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                                Intent.FLAG_ACTIVITY_CLEAR_TOP
                        )
                    }
                    startActivity(explicit)
                    return true
                } catch (_: Exception) {
                    // keep trying next component
                }
            }
            false
        } catch (_: Exception) {
            false
        }
    }

    private fun openResolvedIntent(
        action: String,
        category: String?,
        data: String?
    ): Boolean {
        if (action.isBlank()) return false
        return try {
            val baseIntent = Intent(action).apply {
                if (!category.isNullOrBlank()) addCategory(category)
                if (!data.isNullOrBlank()) {
                    this.data = Uri.parse(data)
                }
            }

            val resolved = packageManager.resolveActivity(baseIntent, PackageManager.MATCH_DEFAULT_ONLY)
                ?: packageManager.resolveActivity(baseIntent, 0)
                ?: return false

            val activityInfo = resolved.activityInfo ?: return false
            val explicitIntent = Intent(baseIntent).apply {
                setClassName(activityInfo.packageName, activityInfo.name)
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
                )
            }

            startActivity(explicitIntent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openAppByName(query: String): String? {
        if (query.isBlank()) return null
        return try {
            val packageLike = query.trim()
            if (packageLike.contains(".") && openAppByPackage(packageLike)) {
                return packageLike
            }

            val q = normalizeAppToken(query)
            val knownPackages = resolveKnownPackagesByQuery(q)
            for (pkg in knownPackages) {
                if (openAppByPackage(pkg)) {
                    return pkg
                }
            }

            val launcherIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_LAUNCHER)
            }
            @Suppress("DEPRECATION")
            val apps = packageManager.queryIntentActivities(launcherIntent, 0)
            if (apps.isNullOrEmpty()) return null

            var best: android.content.pm.ResolveInfo? = null
            var bestScore = 0

            for (resolve in apps) {
                val activity = resolve.activityInfo ?: continue
                val label = normalizeAppToken(resolve.loadLabel(packageManager)?.toString() ?: "")
                val pkg = normalizeAppToken(activity.packageName)
                val score = when {
                    label == q || pkg == q -> 100
                    label.startsWith(q) || pkg.startsWith(q) -> 90
                    label.contains(q) || pkg.contains(q) -> 80
                    q.contains(label) && label.length >= 4 -> 60
                    hasStrongTokenOverlap(label, q) || hasStrongTokenOverlap(pkg, q) -> 55
                    else -> 0
                }
                if (score > bestScore) {
                    bestScore = score
                    best = resolve
                }
            }

            val target = best?.activityInfo ?: return null
            if (bestScore <= 0) return null

            val explicitIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_LAUNCHER)
                setClassName(target.packageName, target.name)
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
                )
            }
            startActivity(explicitIntent)
            target.packageName
        } catch (_: Exception) {
            null
        }
    }

    private fun normalizeAppToken(input: String): String {
        return input
            .lowercase()
            .replace(Regex("[^a-z0-9]"), "")
    }

    private fun hasStrongTokenOverlap(a: String, b: String): Boolean {
        if (a.isBlank() || b.isBlank()) return false
        if (a.length < 4 || b.length < 4) return false
        val minLen = minOf(a.length, b.length)
        var longest = 0
        for (i in a.indices) {
            for (j in b.indices) {
                var k = 0
                while (i + k < a.length && j + k < b.length && a[i + k] == b[j + k]) {
                    k++
                }
                if (k > longest) longest = k
                if (longest >= minLen.coerceAtMost(6)) return true
            }
        }
        return longest >= 5
    }

    private fun resolveKnownPackagesByQuery(query: String): List<String> {
        return when (query) {
            "whatsapp",
            "whatsap",
            "whatsaapp",
            "watsapp",
            "whatsup",
            "wa",
            "whatsappmessenger" -> listOf("com.whatsapp", "com.whatsapp.w4b")
            "whatsappbusiness",
            "wabusiness",
            "whatsappbiz" -> listOf("com.whatsapp.w4b", "com.whatsapp")
            "gmail",
            "gmain",
            "gmial",
            "googlemail",
            "mail" -> listOf(
                "com.google.android.gm",
                "com.google.android.gm.lite",
                "com.google.android.email",
            )
            "youtube",
            "youtub",
            "yt" -> listOf("com.google.android.youtube")
            "telegram",
            "tele",
            "tg",
            "telegrammessenger",
            "telegramapp" -> listOf("org.telegram.messenger")
            "telegramx",
            "tgx",
            "tx",
            "xtelegram",
            "telegramxapp" -> listOf("org.thunderdog.challegram")
            "xplayer",
            "xvideo",
            "xvideos",
            "xvideoplayer",
            "xvideoplayerapp" -> listOf(
                "video.player.videoplayer",
                "com.inshot.xplayer",
                "com.mxtech.videoplayer.ad",
            )
            "google",
            "googlesearch",
            "googleapp" -> listOf(
                "com.google.android.googlequicksearchbox",
                "com.android.chrome",
            )
            "playstore",
            "playstoreapp",
            "googleplay",
            "googleplaystore" -> listOf("com.android.vending")
            else -> emptyList()
        }
    }

    private fun knownLaunchComponents(pkg: String): List<String> {
        return when (pkg) {
            "com.whatsapp" -> listOf(
                "com.whatsapp.HomeActivity",
                "com.whatsapp.Main",
            )
            "com.whatsapp.w4b" -> listOf(
                "com.whatsapp.w4b.HomeActivity",
            )
            "com.google.android.gm" -> listOf(
                "com.google.android.gm.ConversationListActivityGmail",
                "com.google.android.gm.GmailActivity",
            )
            "com.google.android.youtube" -> listOf(
                "com.google.android.apps.youtube.app.WatchWhileActivity",
                "com.google.android.youtube.HomeActivity",
            )
            "org.telegram.messenger" -> listOf(
                "org.telegram.ui.LaunchActivity",
            )
            "org.thunderdog.challegram" -> listOf(
                "org.thunderdog.challegram.MainActivity",
            )
            "video.player.videoplayer" -> listOf(
                "video.player.videoplayer.videoeffect.MainActivity",
                "video.player.videoplayer.MainActivity",
            )
            "com.google.android.googlequicksearchbox" -> listOf(
                "com.google.android.apps.gsa.searchnow.SearchNowActivity",
                "com.google.android.apps.gsa.search.core.google.GoogleAppActivity",
            )
            else -> emptyList()
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

    private fun openNotificationSettings() {
        val intent = Intent().apply {
            action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
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
                .setContentTitle(if (status.isNotBlank()) status else "Wake word detected")
                .setContentText(if (transcript.isNotBlank()) transcript else "Zero Two is listening...")
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setSmallIcon(R.mipmap.ic_launcher)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setDefaults(android.app.Notification.DEFAULT_ALL)
                .setSound(getDarSoundUri())
                .setTimeoutAfter(6000)
                .build()
            manager?.notify(wakeEventNotificationId, wakeNotification)
        }
    }

    private fun getDarSoundUri(): Uri {
        val resId = resources.getIdentifier("dar", "raw", packageName)
        if (resId != 0) {
            return Uri.parse("android.resource://$packageName/$resId")
        }
        return RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
    }

    private fun getDarAudioAttributes(): AudioAttributes {
        return AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
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
            ).apply {
                setSound(getDarSoundUri(), getDarAudioAttributes())
            }
            manager?.createNotificationChannel(assistantChannel)
            manager?.createNotificationChannel(wakeEventChannel)
        }
    }

    override fun onDestroy() {
        hideOverlay()
        super.onDestroy()
    }
}
