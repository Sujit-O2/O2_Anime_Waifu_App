package com.example.anime_waifu

import android.Manifest
import android.app.AlarmManager
import android.app.ActivityManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.graphics.BitmapFactory
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import com.example.anime_waifu.AppLog as Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import java.io.BufferedReader
import java.io.DataOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale
import java.util.Random
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import org.json.JSONArray
import org.json.JSONObject

class AssistantForegroundService : Service() {
    private data class PendingCommand(
        val text: String,
        val speakReply: Boolean
    )

    companion object {
        private const val CHANNEL_ID = "assistant_mode_channel_silent_v3"
        private const val MESSAGE_CHANNEL_ID = "assistant_background_alert_v4"
        private const val WAKE_VIBRATE_CHANNEL_ID = "assistant_wake_vibrate_only_v1"
        private const val NOTIFICATION_ID = 2002
        private const val WAKE_EVENT_NOTIFICATION_ID = 2003
        private const val TAG = "AssistantService"
        private const val BACKGROUND_WAKE_ALLOWED = true
        @Volatile
        var isRunning: Boolean = false
            private set
    }

    private var handler = Handler(Looper.getMainLooper())
    private var executor: ExecutorService = Executors.newSingleThreadExecutor()
    private var apiKey: String? = null
    private var apiUrl: String? = null
    private var model: String? = null
    private var systemPrompt: String? = null
    private var ttsApiKey: String? = null
    private var ttsModel: String? = null
    private var ttsVoice: String? = null
    private var ttsSpeed: Double = 1.0
    private var intervalMs: Long = 10000 // Default 10s for testing
    private var isGenerating = false
    private var proactiveEnabled = true
    private var proactiveRandomEnabled = false
    private var wakeModeEnabled = false
    private lateinit var prefs: SharedPreferences
    private lateinit var flutterPrefs: SharedPreferences
    private val queueLock = Any()
    private val pendingVoiceCommands = ArrayDeque<PendingCommand>()
    private var wakeRecorder: MediaRecorder? = null
    private var wakeAudioFile: File? = null
    @Volatile
    private var wakeCaptureInProgress = false
    @Volatile
    private var wakeLoopRunning = false
    private var waitingForCommand = false
    private var wakeWindowOpenUntilMs = 0L
    private var overlayListenSessionActive = false
    @Volatile
    private var commandGenerating = false
    private var replyPlayer: MediaPlayer? = null
    private val replyPlayerLock = Any()
    private val random = Random()
    @Volatile
    private var resumeWakeAfterReply = false
    private val openActionRegex = Regex(
        "Action\\s*:\\s*open[\\s_-]*app",
        setOf(RegexOption.IGNORE_CASE)
    )
    private val appLineRegex = Regex(
        "^\\s*App\\s*:\\s*(.+?)\\s*$",
        setOf(RegexOption.IGNORE_CASE, RegexOption.MULTILINE)
    )
    private val wakePhrases = listOf(
        "zero two",
        "zerotwo",
        "baby girl",
        "babygirl",
        "darling"
    )
    private val wakeWindowMs = 12000L
    private val wakeCaptureDurationMs = 1500L
    private val wakeCommandCaptureDurationMs = 3000L
    private val wakeCapturePauseMs = 120L
    private val wakeCaptureFastPauseMs = 80L
    private val wakeTranscriptionUrl = "https://api.groq.com/openai/v1/audio/transcriptions"
    private val wakeTtsUrl = "https://api.groq.com/openai/v1/audio/speech"
    private val wakeTranscriptionModel = "whisper-large-v3-turbo"
    private val wakeTranscriptionLanguage = "en"
    private val minWakeAudioBytes = 1536L
    private val proactiveRandomIntervalsMs = longArrayOf(
        10 * 60 * 1000L,
        30 * 60 * 1000L,
        60 * 60 * 1000L,
        2 * 60 * 60 * 1000L,
        5 * 60 * 60 * 1000L
    )
    private val wakeCaptureRunnable = object : Runnable {
        override fun run() {
            val listeningAllowed = wakeModeEnabled || overlayListenSessionActive
            if (!isRunning || !listeningAllowed || !hasMicPermission()) {
                return
            }
            startWakeCaptureSnippet()
        }
    }

    /** Periodically checks and revives the wake loop if it should be running but isn't. */
    private val wakeWatchdogRunnable = object : Runnable {
        override fun run() {
            if (!isRunning) return
            if (wakeModeEnabled && !wakeLoopRunning && hasMicPermission()) {
                Log.w(TAG, "WakeWatchdog: wake loop dead — restarting via applyWakeRecognizerState")
                applyWakeRecognizerState()
            }
            handler.postDelayed(this, 45_000L)
        }
    }

    private val proactiveRunnable = object : Runnable {
        override fun run() {
            Log.d(TAG, "Proactive timer fired. isRunning=$isRunning, isGenerating=$isGenerating, enabled=$proactiveEnabled")
            if (isRunning && !isGenerating && proactiveEnabled) {
                fetchAndShowProactiveMessage()
            }
            
            val delayMs = getNextDelayMs()
             
            Log.d(TAG, "Scheduling next proactive check in ${delayMs / 1000} seconds")
            handler.postDelayed(this, delayMs)
        }
    }

    // BroadcastReceiver for swipe-gesture-triggered overlay
    private val showOverlayReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(ctx: android.content.Context, intent: Intent) {
            if (intent.action == "com.example.anime_waifu.SHOW_OVERLAY") {
                handler.post { showWakeAlert("Say your command...", false) }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences("assistant_prefs", Context.MODE_PRIVATE)
        flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        loadConfig()
        createChannel()
        // Register swipe-gesture overlay receiver
        val filter = android.content.IntentFilter("com.example.anime_waifu.SHOW_OVERLAY")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(showOverlayReceiver, filter, android.content.Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(showOverlayReceiver, filter)
        }
    }

    private fun loadConfig() {
        apiKey = prefs.getString("api_key", null)
        apiUrl = prefs.getString("api_url", null)
        model = prefs.getString("model", null)
        systemPrompt = prefs.getString("system_prompt", null)
        ttsApiKey = prefs.getString("tts_api_key", null)
        ttsModel = prefs.getString("tts_model", null)
        ttsVoice = prefs.getString("tts_voice", null)
        ttsSpeed = prefs.getFloat("tts_speed", 1.0f).toDouble()
        // Flutter SharedPreferences stores interval as Int, but we need Long.
        // Try Long first; fall back to Int if a ClassCastException occurs.
        intervalMs = try {
            prefs.getLong("interval_ms", 10000L)
        } catch (_: ClassCastException) {
            prefs.getInt("interval_ms", 10000).toLong()
        }
        proactiveEnabled = prefs.getBoolean("proactive_enabled", true)
        proactiveRandomEnabled = prefs.getBoolean("proactive_random_enabled", false)
        wakeModeEnabled = prefs.getBoolean("wake_mode_enabled", false) && BACKGROUND_WAKE_ALLOWED
        Log.d(TAG, "Config loaded: API_KEY=${!apiKey.isNullOrEmpty()}, proactiveEnabled=$proactiveEnabled, proactiveRandomEnabled=$proactiveRandomEnabled, wakeModeEnabled=$wakeModeEnabled")
    }

    private fun saveConfig() {
        prefs.edit().apply {
            putString("api_key", apiKey)
            putString("api_url", apiUrl)
            putString("model", model)
            putString("system_prompt", systemPrompt)
            putString("tts_api_key", ttsApiKey)
            putString("tts_model", ttsModel)
            putString("tts_voice", ttsVoice)
            putFloat("tts_speed", ttsSpeed.toFloat())
            putLong("interval_ms", intervalMs)
            putBoolean("proactive_enabled", proactiveEnabled)
            putBoolean("proactive_random_enabled", proactiveRandomEnabled)
            putBoolean("wake_mode_enabled", wakeModeEnabled)
            apply()
        }
        Log.d(TAG, "Config saved: proactiveEnabled=$proactiveEnabled, proactiveRandomEnabled=$proactiveRandomEnabled, wakeModeEnabled=$wakeModeEnabled")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val forceBackgroundWake = intent?.getBooleanExtra("FORCE_BACKGROUND_WAKE", false) ?: false
        val action = intent?.action
        if (action == "SET_PROACTIVE_MODE") {
            // Ensure service is promoted and marked running even when this action
            // is the first entry-point (e.g. process/service recreation).
            if (!isRunning) {
                if (!ensureForegroundStarted()) {
                    Log.e(TAG, "SET_PROACTIVE_MODE: foreground start denied")
                    stopSelf()
                    return START_NOT_STICKY
                }
                isRunning = true
            }

            proactiveEnabled = intent.getBooleanExtra("ENABLED", true)
            saveConfig()
            Log.d(TAG, "Proactive mode updated: $proactiveEnabled")
             
            // If enabled, ensure timer is running
            if (proactiveEnabled) {
                handler.removeCallbacks(proactiveRunnable)
                val delayMs = getNextDelayMs()
                handler.postDelayed(proactiveRunnable, delayMs)
            } else {
                handler.removeCallbacks(proactiveRunnable)
            }
            applyWakeRecognizerState()
            return START_STICKY
        }

        if (action == "SET_WAKE_MODE") {
            if (!isRunning) {
                if (!ensureForegroundStarted()) {
                    Log.e(TAG, "SET_WAKE_MODE: foreground start denied")
                    stopSelf()
                    return START_NOT_STICKY
                }
                isRunning = true
            }
            wakeModeEnabled = intent.getBooleanExtra("ENABLED", false)
            wakeModeEnabled = wakeModeEnabled && BACKGROUND_WAKE_ALLOWED
            saveConfig()
            applyWakeRecognizerState()
            return START_STICKY
        }

        if (action == "OVERLAY_CANCEL_SESSION") {
            Log.d(TAG, "OVERLAY_CANCEL_SESSION received. Stopping active listen.")
            waitingForCommand = false
            commandGenerating = false
            if (overlayListenSessionActive) {
                overlayListenSessionActive = false
                stopWakeCaptureLoop()
                applyWakeRecognizerState()
            }
            return START_STICKY
        }

        if (action == "OVERLAY_SEND_TEXT" || action == "OVERLAY_LISTEN_NOW") {
            if (!isRunning) {
                loadConfig()
                val needsMicForeground = action == "OVERLAY_LISTEN_NOW"
                if (!ensureForegroundStarted(requireMicrophone = needsMicForeground)) {
                    Log.e(TAG, "$action: foreground start denied")
                    stopSelf()
                    return START_NOT_STICKY
                }
                isRunning = true
                handler.removeCallbacks(proactiveRunnable)
                handler.postDelayed(proactiveRunnable, getNextDelayMs())
            }

            if (action == "OVERLAY_SEND_TEXT") {
                val overlayText = intent?.getStringExtra("OVERLAY_TEXT")?.trim().orEmpty()
                if (overlayText.isBlank()) {
                    showWakeAlert("Type a command to continue.", pulse = true)
                    return START_STICKY
                }
                // Typed popup input should stay text-only (no TTS playback).
                handleVoiceCommand(overlayText, speakReply = false)
                return START_STICKY
            }

            // action == OVERLAY_LISTEN_NOW
            if (!hasMicPermission()) {
                showWakeAlert("Microphone permission is required.", pulse = true)
                return START_STICKY
            }
            // Overlay mic should work even if persistent wake mode is disabled.
            overlayListenSessionActive = !wakeModeEnabled
            if (overlayListenSessionActive) {
                if (!ensureForegroundStarted(requireMicrophone = true)) {
                    showWakeAlert("Unable to activate microphone right now.", pulse = true)
                    return START_STICKY
                }
                startWakeCaptureLoop()
            } else {
                applyWakeRecognizerState()
            }
            waitingForCommand = true
            wakeWindowOpenUntilMs = System.currentTimeMillis() + wakeWindowMs
            showWakeAlert("Speak your command now.", pulse = true)
            scheduleNextWakeCapture(80L)
            return START_STICKY
        }

        val newApiKey = intent?.getStringExtra("API_KEY")
        val hasSystemPrompt = intent?.hasExtra("SYSTEM_PROMPT") == true
        val hasTtsApiKey = intent?.hasExtra("TTS_API_KEY") == true
        val hasTtsModel = intent?.hasExtra("TTS_MODEL") == true
        val hasTtsVoice = intent?.hasExtra("TTS_VOICE") == true
        if (newApiKey != null) {
            apiKey = newApiKey
            apiUrl = intent.getStringExtra("API_URL")
            model = intent.getStringExtra("MODEL")
            if (hasSystemPrompt) {
                systemPrompt = intent.getStringExtra("SYSTEM_PROMPT")
            }
            if (hasTtsApiKey) {
                ttsApiKey = intent.getStringExtra("TTS_API_KEY")
            }
            if (hasTtsModel) {
                ttsModel = intent.getStringExtra("TTS_MODEL")
            }
            if (hasTtsVoice) {
                ttsVoice = intent.getStringExtra("TTS_VOICE")
            }
            if (intent.hasExtra("TTS_SPEED")) {
                ttsSpeed = intent.getDoubleExtra("TTS_SPEED", 1.0)
            }
            intervalMs = intent.getLongExtra("INTERVAL_MS", 10000L)
            if (intent.hasExtra("PROACTIVE_RANDOM_ENABLED")) {
                proactiveRandomEnabled = intent.getBooleanExtra("PROACTIVE_RANDOM_ENABLED", false)
            }
            saveConfig()
        } else {
            loadConfig()
            if (hasSystemPrompt) {
                systemPrompt = intent?.getStringExtra("SYSTEM_PROMPT")
            }
            if (hasTtsApiKey) {
                ttsApiKey = intent?.getStringExtra("TTS_API_KEY")
            }
            if (hasTtsModel) {
                ttsModel = intent?.getStringExtra("TTS_MODEL")
            }
            if (hasTtsVoice) {
                ttsVoice = intent?.getStringExtra("TTS_VOICE")
            }
            if (intent?.hasExtra("TTS_SPEED") == true) {
                ttsSpeed = intent.getDoubleExtra("TTS_SPEED", 1.0)
            }
            if (hasSystemPrompt || hasTtsApiKey || hasTtsModel || hasTtsVoice || intent?.hasExtra("TTS_SPEED") == true) {
                saveConfig()
            }
        }

        val shouldResyncFromFlutterPrefs =
            forceBackgroundWake || (intent == null) || (action == null && newApiKey == null)
        if (shouldResyncFromFlutterPrefs) {
            syncBackgroundWakeFromFlutterPrefs()
        }

        val requestMicForeground = intent?.getBooleanExtra("REQUIRE_MICROPHONE", false) ?: false
        val reserveMicForeground = requestMicForeground || shouldReserveMicForeground()
        val foregroundStarted = if (reserveMicForeground) {
            ensureForegroundStarted(requireMicrophone = true) || ensureForegroundStarted()
        } else {
            ensureForegroundStarted()
        }

        if (!foregroundStarted) {
            Log.e(TAG, "onStartCommand: foreground start denied")
            stopSelf()
            return START_NOT_STICKY
        }
        
        // Always update isRunning and ensure timer is active when starting with new config
        if (!isRunning) {
            isRunning = true
            val delayMs = getNextDelayMs()
            Log.d(TAG, "Service started. First proactive check in ${delayMs / 1000}s. wakeModeEnabled=$wakeModeEnabled mic=${hasMicPermission()}")
            handler.postDelayed(proactiveRunnable, delayMs)
            // Start wake watchdog — revives wake loop if it dies silently.
            handler.removeCallbacks(wakeWatchdogRunnable)
            handler.postDelayed(wakeWatchdogRunnable, 20_000L)
        } else {
            Log.d(TAG, "Service already running. Updated config. wakeModeEnabled=$wakeModeEnabled")
            handler.removeCallbacks(proactiveRunnable)
            val delayMs = getNextDelayMs()
            handler.postDelayed(proactiveRunnable, delayMs)
        }
        applyWakeRecognizerState()
        
        return START_STICKY
    }

    private fun ensureForegroundStarted(requireMicrophone: Boolean = false): Boolean {
        val notification = buildNotification()
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val fgsType = if (requireMicrophone) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC or
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                } else {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                }
                startForeground(NOTIFICATION_ID, notification, fgsType)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            true
        } catch (e: SecurityException) {
            Log.e(TAG, "startForeground SecurityException: ${e.message}")
            false
        } catch (e: RuntimeException) {
            // Handles ForegroundServiceStartNotAllowedException on newer Android.
            Log.e(TAG, "startForeground RuntimeException: ${e.message}")
            false
        } catch (t: Throwable) {
            Log.e(TAG, "startForeground failed: ${t.message}")
            false
        }
    }

    override fun onDestroy() {
        isRunning = false
        handler.removeCallbacks(proactiveRunnable)
        handler.removeCallbacks(wakeWatchdogRunnable)
        stopWakeCaptureLoop()
        stopReplyPlayback()
        AssistantOverlayController.hide()
        executor.shutdown()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onTaskRemoved(rootIntent: Intent?) {
        syncBackgroundWakeFromFlutterPrefs()
        applyWakeRecognizerState()

        // This is called when the app is swiped away from recent tasks.
        // We restart the service to ensure it keeps running.
        val restartServiceIntent = Intent(applicationContext, this.javaClass)
        restartServiceIntent.setPackage(packageName)
        restartServiceIntent.putExtra("FORCE_BACKGROUND_WAKE", true)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(restartServiceIntent)
            } else {
                startService(restartServiceIntent)
            }
        } catch (e: RuntimeException) {
            Log.w(TAG, "Restart service onTaskRemoved blocked: ${e.message}")
            // On Android 12+ startForegroundService may throw
            // ForegroundServiceStartNotAllowedException from onTaskRemoved.
            // Schedule an alarm as a fallback restart mechanism.
            scheduleAlarmRestart()
        } catch (t: Throwable) {
            Log.w(TAG, "Restart service onTaskRemoved failed: ${t.message}")
            scheduleAlarmRestart()
        }
        super.onTaskRemoved(rootIntent)
    }

    /**
     * Schedules a one-shot AlarmManager alarm to restart the service a few seconds
     * after the app is swiped away. This is the fallback for Android 12+ where
     * startForegroundService() is blocked from onTaskRemoved().
     */
    private fun scheduleAlarmRestart() {
        try {
            val alarmManager = getSystemService(ALARM_SERVICE) as? AlarmManager ?: return
            val intent = Intent(applicationContext, AlarmRestartReceiver::class.java).apply {
                action = AlarmRestartReceiver.ACTION_RESTART_SERVICE
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getBroadcast(
                applicationContext,
                9001,
                intent,
                flags
            )
            val triggerAtMs = System.currentTimeMillis() + 3_000L
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMs,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMs, pendingIntent)
            }
            Log.d(TAG, "AlarmManager restart scheduled for ~3s from now")
        } catch (e: Exception) {
            Log.w(TAG, "scheduleAlarmRestart failed: ${e.message}")
        }
    }

    private fun syncBackgroundWakeFromFlutterPrefs() {
        try {
            val assistantEnabled = flutterPrefs.getBoolean("flutter.assistant_mode_enabled", true)
            val wakeWordEnabled = flutterPrefs.getBoolean("flutter.wake_word_enabled", true)
            val proactiveUserEnabled = flutterPrefs.getBoolean("flutter.proactive_enabled", true)
            proactiveRandomEnabled = flutterPrefs.getBoolean(
                "flutter.proactive_random_enabled",
                proactiveRandomEnabled
            )
            val shouldEnableWake = assistantEnabled &&
                wakeWordEnabled &&
                hasMicPermission() &&
                BACKGROUND_WAKE_ALLOWED

            wakeModeEnabled = shouldEnableWake
            proactiveEnabled = assistantEnabled && proactiveUserEnabled
            saveConfig()
            Log.d(
                TAG,
                "syncBackgroundWakeFromFlutterPrefs: assistant=$assistantEnabled, proactive=$proactiveEnabled, wakeWord=$wakeWordEnabled, mic=${hasMicPermission()}, wakeModeEnabled=$wakeModeEnabled"
            )
        } catch (e: Exception) {
            Log.w(TAG, "syncBackgroundWakeFromFlutterPrefs failed: ${e.message}")
        }
    }

    private fun shouldReserveMicForeground(): Boolean {
        if (!BACKGROUND_WAKE_ALLOWED) return false
        val assistantEnabled = flutterPrefs.getBoolean("flutter.assistant_mode_enabled", true)
        val wakeWordEnabled = flutterPrefs.getBoolean("flutter.wake_word_enabled", true)
        return assistantEnabled && wakeWordEnabled && hasMicPermission()
    }

    private fun buildNotification(): Notification {
        val pendingIntent = buildLaunchPendingIntent(0)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Zero Two Assistant")
            .setContentText("Watching over you in background")
            .setSubText("Background service")
            .setSmallIcon(R.drawable.ic_stat_waifu)
            .setLargeIcon(BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher))
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setColor(0xFFFF5252.toInt())
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
    private fun getNextDelayMs(): Long {
        if (proactiveRandomEnabled) {
            return proactiveRandomIntervalsMs[random.nextInt(proactiveRandomIntervalsMs.size)]
        }
        return if (intervalMs > 0) intervalMs else 15000L
    }

    private fun fetchAndShowProactiveMessage() {
        val key = pickRandomChatApiKey()
        val urlStr = apiUrl
        if (key.isNullOrEmpty() || urlStr.isNullOrEmpty()) {
            Log.e(TAG, "Cannot fetch message: apiKey or apiUrl is null — skipping notification")
            isGenerating = false
            return  // ← Do NOT show a fallback notification when there's no API key
        }

        isGenerating = true
        executor.execute {
            try {
                Log.d(TAG, "Fetching proactive message from $urlStr using model $model")
                val url = URL(urlStr)
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod = "POST"
                conn.setRequestProperty("Authorization", "Bearer $key")
                conn.setRequestProperty("Content-Type", "application/json")
                conn.connectTimeout = 10000
                conn.readTimeout = 10000
                conn.doOutput = true

                val payload = JSONObject().apply {
                    put("model", if (model.isNullOrEmpty()) "moonshotai/kimi-k2-instruct" else model)
                    val messages = JSONArray().apply {
                        put(JSONObject().apply {
                            put("role", "system")
                            put(
                                "content",
                                activeSystemPrompt() +
                                    "\nFor proactive check-ins, keep it very short (max 10 words)."
                            )
                        })
                        put(JSONObject().apply {
                            put("role", "user")
                            put("content", "...")
                        })
                    }
                    put("messages", messages)
                }

                OutputStreamWriter(conn.outputStream).use { it.write(payload.toString()) }

                val responseCode = conn.responseCode
                Log.d(TAG, "API Response Code: $responseCode")

                if (responseCode == 200) {
                    val reader = BufferedReader(InputStreamReader(conn.inputStream))
                    val response = reader.use { it.readText() }
                    val jsonResponse = JSONObject(response)
                    val content = jsonResponse.getJSONArray("choices")
                        .getJSONObject(0)
                        .getJSONObject("message")
                        .getString("content")
                        .trim()

                    Log.d(TAG, "Successfully fetched message: $content")
                    showCheckInAlert(content)
                } else {
                    val errorReader = BufferedReader(InputStreamReader(conn.errorStream ?: conn.inputStream))
                    val errorResponse = errorReader.use { it.readText() }
                    Log.e(TAG, "API Error Response: $errorResponse")
                    
                    // Fallback message if API fails so user knows service is alive
                    showCheckInAlert(pickFallbackMessage())
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error fetching proactive message: ${e.message}")
                e.printStackTrace()
                showCheckInAlert(pickFallbackMessage())
            } finally {
                isGenerating = false
            }
        }
    }

    private fun showCheckInAlert(content: String) {
        persistProactiveMessage(content)
        // Don't send a notification if the app is already open — Flutter will
        // pick up the persisted message and show it in the chat directly.
        if (isAppInForeground()) return

        val manager = getSystemService(NotificationManager::class.java)
        val pendingIntent = buildLaunchPendingIntent(random.nextInt())
        val largeIcon = BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)

        val notification = NotificationCompat.Builder(this, MESSAGE_CHANNEL_ID)
            .setContentTitle("Zero Two Check-in")
            .setContentText(content)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .setBigContentTitle("Zero Two Check-in")
                    .bigText(content)
                    .setSummaryText("Tap to open O2-WAIFU")
            )
            .setSmallIcon(R.drawable.ic_stat_waifu)
            .setLargeIcon(largeIcon)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setColor(0xFFFF5252.toInt())
            .setColorized(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOnlyAlertOnce(false)
            .setDefaults(NotificationCompat.DEFAULT_LIGHTS or NotificationCompat.DEFAULT_VIBRATE)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(
                android.R.drawable.ic_menu_view,
                "Open App",
                pendingIntent
            )
            .build()
        val uniqueId = (System.currentTimeMillis() % Int.MAX_VALUE).toInt()
        safeNotify(manager, uniqueId, notification)
    }

    private fun showWakeAlert(content: String, pulse: Boolean) {
        // Never show popup/notification when the app is open and in foreground
        if (isAppInForeground()) {
            // App is visible — just update the persistent notification silently
            updateNotification(content)
            return
        }

        val wakePrompt = isWakePrompt(content)
        val shouldPulse = if (wakePrompt) {
            pulse && isSoundOnWakeEnabled()
        } else {
            pulse
        }
        val popupEnabled = isWakePopupEnabled()
        val shouldShowPopup = popupEnabled && (wakePrompt || shouldPulse)
        if (shouldShowPopup) {
            AssistantOverlayController.show(
                applicationContext,
                status = "Zero Two",
                transcript = content,
                autoHideMs = 300_000L
            )
        }

        val popupVisible = AssistantOverlayController.isShowing()
        if (!shouldPulse || popupVisible) {
            updateNotification(content)
            return
        }

        val manager = getSystemService(NotificationManager::class.java)
        val pendingIntent = buildLaunchPendingIntent(WAKE_EVENT_NOTIFICATION_ID)
        val largeIcon = BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)
        val wakeChannel = if (wakePrompt) {
            WAKE_VIBRATE_CHANNEL_ID
        } else {
            MESSAGE_CHANNEL_ID
        }

        val notification = NotificationCompat.Builder(this, wakeChannel)
            .setContentTitle("Zero Two Assistant")
            .setContentText(content)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .setBigContentTitle("Zero Two Assistant")
                    .bigText(content)
                    .setSummaryText("Tap to open O2-WAIFU")
            )
            .setSmallIcon(R.drawable.ic_stat_waifu)
            .setLargeIcon(largeIcon)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setColor(0xFFFF5252.toInt())
            .setColorized(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setOnlyAlertOnce(false)
            .setDefaults(NotificationCompat.DEFAULT_LIGHTS or NotificationCompat.DEFAULT_VIBRATE)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(
                android.R.drawable.ic_menu_view,
                "Open App",
                pendingIntent
            )
            .build()

        safeNotify(manager, WAKE_EVENT_NOTIFICATION_ID, notification)
    }

    private fun isWakePopupEnabled(): Boolean {
        return flutterPrefs.getBoolean("flutter.wake_popup_enabled", true)
    }

    /** Returns true when our app process is currently visible to the user. */
    private fun isAppInForeground(): Boolean {
        return try {
            val am = getSystemService(ACTIVITY_SERVICE) as? ActivityManager ?: return false
            val runningApps = am.runningAppProcesses ?: return false
            runningApps.any { proc ->
                proc.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND &&
                    proc.processName == packageName
            }
        } catch (_: Exception) { false }
    }

    private fun isSoundOnWakeEnabled(): Boolean {
        return flutterPrefs.getBoolean("flutter.sound_on_wake_v1", true)
    }

    private fun isWakePrompt(content: String): Boolean {
        val lower = content.lowercase(Locale.getDefault())
        return lower.contains("wake word") ||
            lower.contains("speak your command") ||
            lower.contains("listening")
    }

    private fun syncOverlayStatus(
        status: String,
        transcript: String,
        autoHideMs: Long = 300_000L
    ) {
        AssistantOverlayController.update(
            applicationContext,
            status = status,
            transcript = transcript,
            autoHideMs = autoHideMs
        )
    }

    private fun pickFallbackMessage(): String {
        val options = listOf(
            "Hey darling, what are you doing now?",
            "Can we talk for a minute? I miss you.",
            "I am here with you. Want to chat now?",
            "Darling, are you free? Let us talk."
        )
        return options[random.nextInt(options.size)]
    }

    private fun persistProactiveMessage(content: String) {
        persistChatMessage("assistant", content)
    }

    private fun persistChatMessage(role: String, content: String) {
        try {
            synchronized(queueLock) {
                val flutterPendingKey = "flutter.pending_proactive_messages"
                val legacyKey = "pending_proactive_messages"
                val rawFlutter = flutterPrefs.getString(flutterPendingKey, "[]") ?: "[]"
                val rawLegacy = prefs.getString(legacyKey, "[]") ?: "[]"

                val flutterList = try {
                    JSONArray(rawFlutter)
                } catch (_: Exception) {
                    JSONArray()
                }
                val legacyList = try {
                    JSONArray(rawLegacy)
                } catch (_: Exception) {
                    JSONArray()
                }
                val list = if (flutterList.length() >= legacyList.length()) {
                    flutterList
                } else {
                    legacyList
                }

                list.put(
                    JSONObject().apply {
                        put("role", role)
                        put("content", content)
                    }
                )

                val maxItems = 50
                val trimmed = if (list.length() > maxItems) {
                    JSONArray().apply {
                        val start = list.length() - maxItems
                        for (i in start until list.length()) {
                            put(list.get(i))
                        }
                    }
                } else {
                    list
                }

                // Keep both storages in sync for backward compatibility.
                val encoded = trimmed.toString()
                prefs.edit().putString(legacyKey, encoded).commit()
                flutterPrefs.edit().putString(flutterPendingKey, encoded).commit()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to persist chat message: ${e.message}")
        }
    }

    private fun recentChatContext(maxItems: Int = 10): JSONArray {
        return try {
            synchronized(queueLock) {
                val flutterPendingKey = "flutter.pending_proactive_messages"
                val legacyKey = "pending_proactive_messages"
                val rawFlutter = flutterPrefs.getString(flutterPendingKey, "[]") ?: "[]"
                val rawLegacy = prefs.getString(legacyKey, "[]") ?: "[]"

                val flutterList = try {
                    JSONArray(rawFlutter)
                } catch (_: Exception) {
                    JSONArray()
                }
                val legacyList = try {
                    JSONArray(rawLegacy)
                } catch (_: Exception) {
                    JSONArray()
                }
                val source = if (flutterList.length() >= legacyList.length()) {
                    flutterList
                } else {
                    legacyList
                }

                val start = (source.length() - maxItems).coerceAtLeast(0)
                JSONArray().apply {
                    for (i in start until source.length()) {
                        val item = source.optJSONObject(i) ?: continue
                        val rawRole = item.optString("role", "assistant")
                            .trim()
                            .lowercase(Locale.getDefault())
                        val rawContent = item.optString("content", "").trim()
                        if (rawContent.isBlank()) continue
                        val safeRole = if (rawRole == "user") "user" else "assistant"
                        put(
                            JSONObject().apply {
                                put("role", safeRole)
                                put("content", rawContent)
                            }
                        )
                    }
                }
            }
        } catch (_: Exception) {
            JSONArray()
        }
    }

    private fun hasMicPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            android.Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun canPostNotifications(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun safeNotify(
        manager: NotificationManager?,
        notificationId: Int,
        notification: Notification
    ) {
        if (!canPostNotifications()) {
            Log.w(TAG, "Notification blocked: POST_NOTIFICATIONS not granted")
            return
        }
        try {
            manager?.notify(notificationId, notification)
        } catch (e: SecurityException) {
            Log.w(TAG, "Notification security error: ${e.message}")
        } catch (e: RuntimeException) {
            Log.w(TAG, "Notification runtime error: ${e.message}")
        }
    }

    private fun startWakeCaptureLoop() {
        if (!isRunning) return
        if (!hasMicPermission()) {
            Log.w(TAG, "Mic permission missing - wake loop not started")
            return
        }
        if (wakeLoopRunning) return
        wakeLoopRunning = true
        handler.removeCallbacks(wakeCaptureRunnable)
        handler.post(wakeCaptureRunnable)
    }

    private fun applyWakeRecognizerState() {
        if (!isRunning) {
            stopWakeCaptureLoop()
            return
        }
        val listeningAllowed = wakeModeEnabled || overlayListenSessionActive
        if (listeningAllowed) {
            if (!hasMicPermission()) {
                Log.w(TAG, "Wake mode requested without mic permission; disabling wake mode")
                wakeModeEnabled = false
                overlayListenSessionActive = false
                saveConfig()
                stopWakeCaptureLoop()
                ensureForegroundStarted(requireMicrophone = false)
                return
            }
            if (!ensureForegroundStarted(requireMicrophone = true)) {
                Log.w(TAG, "Microphone foreground escalation blocked; retrying wake state shortly")
                stopWakeCaptureLoop()
                handler.removeCallbacks(wakeCaptureRunnable)
                handler.postDelayed({
                    if (isRunning && (wakeModeEnabled || overlayListenSessionActive)) {
                        applyWakeRecognizerState()
                    }
                }, 2500L)
                return
            }
            startWakeCaptureLoop()
        } else {
            ensureForegroundStarted(requireMicrophone = shouldReserveMicForeground())
            stopWakeCaptureLoop()
        }
    }

    private fun stopWakeCaptureLoop() {
        wakeLoopRunning = false
        handler.removeCallbacks(wakeCaptureRunnable)
        wakeCaptureInProgress = false
        stopWakeRecorderSafely()
        try {
            wakeAudioFile?.delete()
        } catch (_: Exception) {}
        wakeAudioFile = null
        waitingForCommand = false
        wakeWindowOpenUntilMs = 0L
        overlayListenSessionActive = false
    }

    private fun startWakeCaptureSnippet() {
        if (wakeCaptureInProgress) {
            scheduleNextWakeCapture(300L)
            return
        }
        val listeningAllowed = wakeModeEnabled || overlayListenSessionActive
        if (!isRunning || !listeningAllowed || !hasMicPermission()) {
            return
        }

        val tmp = try {
            File.createTempFile("wake_", ".m4a", cacheDir)
        } catch (e: Exception) {
            Log.e(TAG, "Wake temp file create error: ${e.message}")
            scheduleNextWakeCapture(1500L)
            return
        }

        val recorder = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(this)
            } else {
                MediaRecorder()
            }
        } catch (e: Exception) {
            Log.e(TAG, "MediaRecorder init error: ${e.message}")
            tmp.delete()
            scheduleNextWakeCapture(1500L)
            return
        }

        try {
            recorder.setAudioSource(MediaRecorder.AudioSource.MIC)
            recorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            recorder.setAudioSamplingRate(16000)
            recorder.setAudioChannels(1)
            recorder.setAudioEncodingBitRate(64000)
            recorder.setOutputFile(tmp.absolutePath)
            recorder.prepare()
            recorder.start()
        } catch (e: Exception) {
            Log.e(TAG, "Wake recorder start error: ${e.message}")
            try {
                recorder.release()
            } catch (_: Exception) {}
            tmp.delete()
            scheduleNextWakeCapture(1500L)
            return
        }

        wakeCaptureInProgress = true
        wakeRecorder = recorder
        wakeAudioFile = tmp
        val captureDurationMs = currentWakeCaptureDurationMs()
        handler.postDelayed({ stopWakeCaptureAndProcess() }, captureDurationMs)
    }

    private fun stopWakeCaptureAndProcess() {
        val file = wakeAudioFile
        val commandMode = waitingForCommand
        stopWakeRecorderSafely()
        wakeAudioFile = null

        if (file == null || !file.exists()) {
            wakeCaptureInProgress = false
            scheduleNextWakeCapture(nextWakeCaptureDelayMs())
            return
        }

        executor.execute {
            try {
                if (file.length() >= minWakeAudioBytes) {
                    val heard = transcribeWakeAudio(file, commandMode)
                    if (heard.isNotBlank()) {
                        handleRecognizedText(heard)
                    } else if (commandMode) {
                        syncOverlayStatus(
                            "Listening",
                            "Didn't catch that clearly. Speak again."
                        )
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Wake capture process error: ${e.message}")
            } finally {
                try {
                    file.delete()
                } catch (_: Exception) {}
                wakeCaptureInProgress = false
                scheduleNextWakeCapture(nextWakeCaptureDelayMs())
            }
        }
    }

    private fun stopWakeRecorderSafely() {
        val recorder = wakeRecorder ?: return
        wakeRecorder = null
        try {
            recorder.stop()
        } catch (_: Exception) {}
        try {
            recorder.reset()
        } catch (_: Exception) {}
        try {
            recorder.release()
        } catch (_: Exception) {}
    }

    private fun scheduleNextWakeCapture(delayMs: Long) {
        val listeningAllowed = wakeModeEnabled || overlayListenSessionActive
        if (!wakeLoopRunning || !isRunning || !listeningAllowed) return
        handler.removeCallbacks(wakeCaptureRunnable)
        handler.postDelayed(wakeCaptureRunnable, delayMs.coerceAtLeast(80L))
    }

    private fun nextWakeCaptureDelayMs(): Long {
        return if (waitingForCommand) wakeCaptureFastPauseMs else wakeCapturePauseMs
    }

    private fun currentWakeCaptureDurationMs(): Long {
        return if (waitingForCommand) wakeCommandCaptureDurationMs else wakeCaptureDurationMs
    }

    private fun transcribeWakeAudio(file: File, commandMode: Boolean): String {
        val key = pickRandomChatApiKey()
        if (key.isNullOrBlank()) {
            if (commandMode) {
                syncOverlayStatus(
                    "Setup needed",
                    "Open app once and enable Background Assistant."
                )
            }
            return ""
        }

        val boundary = "----ZeroTwoBoundary${System.currentTimeMillis()}"
        val connectMs = if (commandMode) 8000 else 4500
        val readMs = if (commandMode) 15000 else 6500
        val conn = (URL(wakeTranscriptionUrl).openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            setRequestProperty("Authorization", "Bearer $key")
            setRequestProperty("Content-Type", "multipart/form-data; boundary=$boundary")
            connectTimeout = connectMs
            readTimeout = readMs
            doOutput = true
        }

        DataOutputStream(conn.outputStream).use { out ->
            fun writeText(value: String) {
                out.write(value.toByteArray(Charsets.UTF_8))
            }

            writeText("--$boundary\r\n")
            writeText("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
            writeText("$wakeTranscriptionModel\r\n")

            writeText("--$boundary\r\n")
            writeText("Content-Disposition: form-data; name=\"language\"\r\n\r\n")
            writeText("$wakeTranscriptionLanguage\r\n")

            writeText("--$boundary\r\n")
            writeText("Content-Disposition: form-data; name=\"file\"; filename=\"${file.name}\"\r\n")
            writeText("Content-Type: audio/mp4\r\n\r\n")

            FileInputStream(file).use { input ->
                input.copyTo(out)
            }

            writeText("\r\n--$boundary--\r\n")
            out.flush()
        }

        val code = conn.responseCode
        val responseBody = if (code in 200..299) {
            BufferedReader(InputStreamReader(conn.inputStream)).use { it.readText() }
        } else {
            BufferedReader(InputStreamReader(conn.errorStream ?: conn.inputStream)).use { it.readText() }
        }

        if (code != 200) {
            Log.e(TAG, "Wake transcription failed: $code $responseBody")
            return ""
        }

        return try {
            JSONObject(responseBody).optString("text", "").trim()
        } catch (_: Exception) {
            ""
        }
    }

    private fun normalizeSpeechText(text: String): String {
        return text
            .lowercase(Locale.getDefault())
            .replace(Regex("[^\\p{L}\\p{N}\\s]"), " ")
            .replace(Regex("\\s+"), " ")
            .trim()
    }

    private fun cleanSpokenCommand(text: String): String {
        return text
            .replace(Regex("\\s+"), " ")
            .trim()
    }

    private fun containsWakePhrase(normalizedText: String): Boolean {
        if (normalizedText.isBlank()) return false
        return wakePhrases.any { normalizedText.contains(it) }
    }

    private fun stripWakePhrases(normalizedText: String): String {
        var stripped = normalizedText
        for (phrase in wakePhrases) {
            stripped = stripped.replace(phrase, " ")
        }
        return stripped.replace(Regex("\\s+"), " ").trim()
    }

    private fun handleRecognizedText(rawText: String) {
        val spokenCommand = cleanSpokenCommand(rawText)
        val normalized = normalizeSpeechText(rawText)
        if (normalized.isBlank() && spokenCommand.isBlank()) return

        if (waitingForCommand && System.currentTimeMillis() > wakeWindowOpenUntilMs) {
            waitingForCommand = false
            if (overlayListenSessionActive && !wakeModeEnabled) {
                stopWakeCaptureLoop()
                syncOverlayStatus(
                    "Listening ended",
                    "Mic timed out. Tap mic and try again."
                )
                return
            }
        }

        if (waitingForCommand) {
            if (spokenCommand.isBlank()) return
            waitingForCommand = false
            if (overlayListenSessionActive && !wakeModeEnabled) {
                stopWakeCaptureLoop()
            }
            syncOverlayStatus("You", spokenCommand)
            handleVoiceCommand(spokenCommand, speakReply = true)
            return
        }

        if (!containsWakePhrase(normalized)) {
            return
        }

        val inlineCommand = stripWakePhrases(normalized)
        if (inlineCommand.isNotBlank()) {
            syncOverlayStatus("You", inlineCommand)
            handleVoiceCommand(inlineCommand, speakReply = true)
            return
        }

        waitingForCommand = true
        wakeWindowOpenUntilMs = System.currentTimeMillis() + wakeWindowMs
        showWakeAlert("Wake word detected. Speak your command now.", pulse = true)
    }

    private fun handleVoiceCommand(command: String, speakReply: Boolean = true) {
        val cleaned = command.trim()
        if (cleaned.isBlank()) return
        syncOverlayStatus("You", cleaned)
        persistChatMessage("user", cleaned)
        fetchAndRespondToVoiceCommand(cleaned, speakReply)
    }

    private fun fetchAndRespondToVoiceCommand(command: String, speakReply: Boolean) {
        if (commandGenerating) {
            synchronized(queueLock) {
                pendingVoiceCommands.addLast(
                    PendingCommand(
                        text = command,
                        speakReply = speakReply
                    )
                )
            }
            syncOverlayStatus(
                "Queued",
                "I'll handle this after the current request."
            )
            return
        }

        val key = apiKey
        val urlStr = apiUrl
        if (key.isNullOrEmpty() || urlStr.isNullOrEmpty()) {
            Log.e(TAG, "Cannot process voice command: apiKey or apiUrl missing")
            val setupMissing = "I need API setup to answer you."
            persistChatMessage("assistant", setupMissing)
            syncOverlayStatus("Zero Two", setupMissing)
            showWakeAlert(setupMissing, pulse = true)
            if (speakReply) {
                queueWakeReplySpeech(setupMissing)
            }
            return
        }

        commandGenerating = true
        syncOverlayStatus(
            "Processing",
            "Working on: ${command.take(90)}"
        )
        executor.execute {
            try {
                val url = URL(urlStr)
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod = "POST"
                conn.setRequestProperty("Authorization", "Bearer ${pickRandomChatApiKey() ?: key}")
                conn.setRequestProperty("Content-Type", "application/json")
                conn.connectTimeout = 15000
                conn.readTimeout = 15000
                conn.doOutput = true

                val payload = JSONObject().apply {
                    put("model", if (model.isNullOrEmpty()) "moonshotai/kimi-k2-instruct" else model)
                    val messages = buildVoiceRequestMessages(command)
                    put("messages", messages)
                }

                OutputStreamWriter(conn.outputStream).use { it.write(payload.toString()) }
                val code = conn.responseCode
                val body = if (code in 200..299) {
                    BufferedReader(InputStreamReader(conn.inputStream)).use { it.readText() }
                } else {
                    BufferedReader(InputStreamReader(conn.errorStream ?: conn.inputStream)).use { it.readText() }
                }

                val reply = if (code == 200) {
                    JSONObject(body)
                        .getJSONArray("choices")
                        .getJSONObject(0)
                        .getJSONObject("message")
                        .getString("content")
                        .trim()
                } else {
                    Log.e(TAG, "Voice command API failed: $code $body")
                    "I could not reach the server right now."
                }

                val finalReply = handleAssistantReplyAction(reply)
                persistChatMessage("assistant", finalReply)
                syncOverlayStatus("Zero Two", finalReply)
                showWakeAlert(finalReply, pulse = true)
                if (speakReply) {
                    queueWakeReplySpeech(finalReply)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Voice command error: ${e.message}")
                val fallback = "I had trouble processing that. Try again."
                persistChatMessage("assistant", fallback)
                syncOverlayStatus("Zero Two", fallback)
                showWakeAlert(fallback, pulse = true)
                if (speakReply) {
                    queueWakeReplySpeech(fallback)
                }
            } finally {
                commandGenerating = false
                val nextCommand = synchronized(queueLock) {
                    if (pendingVoiceCommands.isEmpty()) null else pendingVoiceCommands.removeFirst()
                }
                if (nextCommand != null && nextCommand.text.isNotBlank()) {
                    fetchAndRespondToVoiceCommand(
                        nextCommand.text,
                        nextCommand.speakReply
                    )
                }
            }
        }
    }

    private fun activeSystemPrompt(): String {
        val prompt = systemPrompt?.trim()
        if (!prompt.isNullOrBlank()) {
            return prompt
        }
        return "You are Zero Two. Keep answers short, clear, and caring."
    }

    private fun handleAssistantReplyAction(reply: String): String {
        val trimmed = reply.trim()
        if (!openActionRegex.containsMatchIn(trimmed)) {
            return trimmed
        }

        val appName = extractAppNameFromReply(trimmed)
        if (appName.isBlank()) {
            return "App name missing. Use Action: OPEN_APP and App: <app name>."
        }

        val launched = AppLaunchResolver.openByName(this, appName) != null
        return if (launched) {
            "Opened ${titleCase(appName)}."
        } else {
            "I could not open ${titleCase(appName)}. It may be unavailable, disabled, or not installed."
        }
    }

    private fun extractAppNameFromReply(reply: String): String {
        val line = appLineRegex.find(reply)?.groupValues?.getOrNull(1)?.trim()
        if (!line.isNullOrBlank()) {
            return sanitizeAppName(line)
        }
        val inline = Regex(
            "Action\\s*:\\s*open[\\s_-]*app[\\s\\S]*?App\\s*:\\s*([^\\r\\n]+)",
            setOf(RegexOption.IGNORE_CASE)
        ).find(reply)?.groupValues?.getOrNull(1)?.trim()
        if (!inline.isNullOrBlank()) {
            return sanitizeAppName(inline)
        }
        return ""
    }

    private fun sanitizeAppName(value: String): String {
        return value
            .trim()
            .trim('"', '\'')
            .replace(Regex("[\\.;,\\)\\]]+$"), "")
            .replace(Regex("\\s+"), " ")
            .trim()
    }

    private fun titleCase(input: String): String {
        if (input.isBlank()) return input
        return input
            .split(Regex("\\s+"))
            .filter { it.isNotBlank() }
            .joinToString(" ") { word ->
                val lower = word.lowercase(Locale.getDefault())
                lower.replaceFirstChar { ch ->
                    if (ch.isLowerCase()) ch.titlecase(Locale.getDefault()) else ch.toString()
                }
            }
    }

    private fun effectiveTtsApiKey(): String? {
        val configured = ttsApiKey?.trim()
        if (!configured.isNullOrBlank()) return configured
        val fallback = apiKey?.trim()
        if (!fallback.isNullOrBlank()) return fallback
        return null
    }

    /** Returns a random key from a comma-separated key string. Helps spread load across keys. */
    private fun pickRandomApiKey(): String? {
        val source = effectiveTtsApiKey()?.trim()
        if (source.isNullOrBlank()) return null
        val keys = source.split(",").map { it.trim() }.filter { it.isNotBlank() }
        if (keys.isEmpty()) return null
        return keys[random.nextInt(keys.size)]
    }

    /** Returns a random key from the chat API key pool (comma-separated). */
    private fun pickRandomChatApiKey(): String? {
        val source = apiKey?.trim() ?: return null
        if (source.isBlank()) return null
        val keys = source.split(",").map { it.trim() }.filter { it.isNotBlank() }
        if (keys.isEmpty()) return null
        return keys[random.nextInt(keys.size)]
    }

    private fun effectiveTtsModel(): String {
        val configured = ttsModel?.trim()
        if (!configured.isNullOrBlank()) return configured
        return "playai-tts"  // English by default
    }

    private fun effectiveTtsVoice(): String {
        val configured = ttsVoice?.trim()
        if (!configured.isNullOrBlank()) return configured
        return "aisha"
    }

    private fun sanitizeTtsInput(text: String): String {
        val compact = text.trim().replace(Regex("\\s+"), " ")
        if (compact.length <= 320) return compact
        return compact.take(320)
    }

    private fun queueWakeReplySpeech(content: String) {
        val prepared = sanitizeTtsInput(content)
        if (prepared.isBlank()) return

        executor.execute {
            speakWakeReply(prepared)
        }
    }

    private fun speakWakeReply(content: String) {
        val key = pickRandomApiKey() ?: return
        try {
            val url = URL(wakeTtsUrl)
            val conn = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                setRequestProperty("Authorization", "Bearer $key")
                setRequestProperty("Content-Type", "application/json")
                connectTimeout = 9000
                readTimeout = 18000
                doOutput = true
            }

            val payload = JSONObject().apply {
                put("model", effectiveTtsModel())
                put("voice", effectiveTtsVoice())
                put("input", content)
                put("response_format", "wav")
            }
            OutputStreamWriter(conn.outputStream).use { it.write(payload.toString()) }

            val code = conn.responseCode
            if (code != 200) {
                val err = BufferedReader(InputStreamReader(conn.errorStream ?: conn.inputStream))
                    .use { it.readText() }
                Log.w(TAG, "Wake TTS failed: $code $err")
                return
            }

            val audioBytes = conn.inputStream.use { it.readBytes() }
            if (audioBytes.isEmpty()) return
            val tmp = try {
                File.createTempFile("wake_reply_", ".wav", cacheDir)
            } catch (e: Exception) {
                Log.w(TAG, "Wake TTS temp file create failed: ${e.message}")
                return
            }
            tmp.writeBytes(audioBytes)
            handler.post { playWakeReplyAudio(tmp) }
        } catch (e: Exception) {
            Log.w(TAG, "Wake TTS error: ${e.message}")
        }
    }

    private fun playWakeReplyAudio(file: File) {
        if (!isRunning) {
            try {
                file.delete()
            } catch (_: Exception) {}
            return
        }
        if (wakeModeEnabled && wakeLoopRunning) {
            resumeWakeAfterReply = true
            stopWakeCaptureLoop()
        }
        synchronized(replyPlayerLock) {
            stopReplyPlaybackLocked()
            val player = MediaPlayer()
            try {
                player.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                player.setDataSource(file.absolutePath)
                player.setOnCompletionListener { mp ->
                    synchronized(replyPlayerLock) {
                        if (replyPlayer === mp) {
                            replyPlayer = null
                        }
                    }
                    try {
                        mp.release()
                    } catch (_: Exception) {}
                    try {
                        file.delete()
                    } catch (_: Exception) {}
                    resumeWakeCaptureIfNeeded()
                }
                player.setOnErrorListener { mp, _, _ ->
                    synchronized(replyPlayerLock) {
                        if (replyPlayer === mp) {
                            replyPlayer = null
                        }
                    }
                    try {
                        mp.release()
                    } catch (_: Exception) {}
                    try {
                        file.delete()
                    } catch (_: Exception) {}
                    resumeWakeCaptureIfNeeded()
                    true
                }
                player.prepare()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && ttsSpeed != 1.0) {
                    try {
                        player.playbackParams = player.playbackParams.setSpeed(ttsSpeed.toFloat())
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to set playback speed: ${e.message}")
                    }
                }
                player.start()
                replyPlayer = player
            } catch (e: Exception) {
                try {
                    player.release()
                } catch (_: Exception) {}
                try {
                    file.delete()
                } catch (_: Exception) {}
                Log.w(TAG, "Wake TTS playback failed: ${e.message}")
                resumeWakeCaptureIfNeeded()
            }
        }
    }

    private fun stopReplyPlayback() {
        synchronized(replyPlayerLock) {
            stopReplyPlaybackLocked()
        }
        resumeWakeCaptureIfNeeded()
    }

    private fun stopReplyPlaybackLocked() {
        val player = replyPlayer ?: return
        replyPlayer = null
        try {
            player.stop()
        } catch (_: Exception) {}
        try {
            player.reset()
        } catch (_: Exception) {}
        try {
            player.release()
        } catch (_: Exception) {}
    }

    private fun resumeWakeCaptureIfNeeded() {
        if (!resumeWakeAfterReply) return
        resumeWakeAfterReply = false
        handler.post {
            if (isRunning && wakeModeEnabled) {
                applyWakeRecognizerState()
            }
        }
    }

    private fun buildVoiceRequestMessages(command: String): JSONArray {
        val prompt = activeSystemPrompt()
        val normalizedCommand = command.trim()
        val context = recentChatContext(maxItems = 10)
        return JSONArray().apply {
            put(
                JSONObject().apply {
                    put("role", "system")
                    put("content", prompt)
                }
            )
            for (i in 0 until context.length()) {
                val item = context.optJSONObject(i) ?: continue
                put(item)
            }

            val appendExplicitCommand = if (context.length() == 0) {
                true
            } else {
                val last = context.optJSONObject(context.length() - 1)
                val lastRole = last?.optString("role", "")?.trim() ?: ""
                val lastContent = last?.optString("content", "")?.trim() ?: ""
                !(lastRole == "user" && lastContent == normalizedCommand)
            }
            if (appendExplicitCommand) {
                put(
                    JSONObject().apply {
                        put("role", "user")
                        put("content", normalizedCommand)
                    }
                )
            }
        }
    }

    private fun updateNotification(content: String) {
        val manager = getSystemService(NotificationManager::class.java)
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Zero Two")
            .setContentText(content)
            .setStyle(NotificationCompat.BigTextStyle().bigText(content))
            .setSmallIcon(R.drawable.ic_stat_waifu)
            .setOngoing(true)
            .setColor(0xFFFF5252.toInt())
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        safeNotify(manager, NOTIFICATION_ID, notification)
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java) ?: return

            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Assistant Mode",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                setSound(null, null)
                enableVibration(false)
            }
            manager.createNotificationChannel(serviceChannel)

            val messageChannel = NotificationChannel(
                MESSAGE_CHANNEL_ID,
                "Background Messages",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Check-ins and wake replies from Zero Two"
                enableLights(true)
                lightColor = android.graphics.Color.RED
                enableVibration(true)
                vibrationPattern = longArrayOf(0L, 180L, 120L, 180L)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(notificationSoundUri(), notificationAudioAttributes())
            }
            manager.createNotificationChannel(messageChannel)

            val wakeVibrateChannel = NotificationChannel(
                WAKE_VIBRATE_CHANNEL_ID,
                "Wake Events (Vibrate)",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Wake detection alerts with vibration only"
                enableLights(true)
                lightColor = android.graphics.Color.RED
                enableVibration(true)
                vibrationPattern = longArrayOf(0L, 180L, 120L, 180L)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(null, null)
            }
            manager.createNotificationChannel(wakeVibrateChannel)
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
}
