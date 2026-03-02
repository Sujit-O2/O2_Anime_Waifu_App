package com.example.anime_waifu

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
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
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
    companion object {
        private const val CHANNEL_ID = "assistant_mode_channel_silent_v3"
        private const val MESSAGE_CHANNEL_ID = "assistant_background_alert_v3"
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
    private var intervalMs: Long = 10000 // Default 10s for testing
    private var isGenerating = false
    private var proactiveEnabled = true
    private var proactiveRandomEnabled = false
    private var wakeModeEnabled = false
    private lateinit var prefs: SharedPreferences
    private lateinit var flutterPrefs: SharedPreferences
    private val queueLock = Any()
    private var wakeRecorder: MediaRecorder? = null
    private var wakeAudioFile: File? = null
    @Volatile
    private var wakeCaptureInProgress = false
    private var wakeLoopRunning = false
    private var waitingForCommand = false
    private var wakeWindowOpenUntilMs = 0L
    private var commandGenerating = false
    private val wakePhrases = listOf(
        "zero two",
        "zerotwo",
        "baby girl",
        "babygirl",
        "darling"
    )
    private val wakeWindowMs = 9000L
    private val wakeCaptureDurationMs = 1600L
    private val wakeCapturePauseMs = 220L
    private val wakeCaptureFastPauseMs = 90L
    private val wakeTranscriptionUrl = "https://api.groq.com/openai/v1/audio/transcriptions"
    private val wakeTranscriptionModel = "whisper-large-v3-turbo"
    private val wakeTranscriptionLanguage = "en"
    private val minWakeAudioBytes = 2048L
    private val proactiveRandomIntervalsMs = longArrayOf(
        10 * 60 * 1000L,
        30 * 60 * 1000L,
        60 * 60 * 1000L,
        2 * 60 * 60 * 1000L,
        5 * 60 * 60 * 1000L
    )
    private val wakeCaptureRunnable = object : Runnable {
        override fun run() {
            if (!isRunning || !wakeModeEnabled || !hasMicPermission()) {
                return
            }
            startWakeCaptureSnippet()
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

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences("assistant_prefs", Context.MODE_PRIVATE)
        flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        loadConfig()
        createChannel()
    }

    private fun loadConfig() {
    apiKey = prefs.getString("api_key", null)
        apiUrl = prefs.getString("api_url", null)
        model = prefs.getString("model", null)
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

        val newApiKey = intent?.getStringExtra("API_KEY")
        if (newApiKey != null) {
            apiKey = newApiKey
            apiUrl = intent.getStringExtra("API_URL")
            model = intent.getStringExtra("MODEL")
            intervalMs = intent.getLongExtra("INTERVAL_MS", 10000L)
            if (intent.hasExtra("PROACTIVE_RANDOM_ENABLED")) {
                proactiveRandomEnabled = intent.getBooleanExtra("PROACTIVE_RANDOM_ENABLED", false)
            }
            saveConfig()
        } else {
            loadConfig()
        }

        val shouldResyncFromFlutterPrefs =
            forceBackgroundWake || (intent == null) || (action == null && newApiKey == null)
        if (shouldResyncFromFlutterPrefs) {
            syncBackgroundWakeFromFlutterPrefs()
        }

        if (!ensureForegroundStarted()) {
            Log.e(TAG, "onStartCommand: foreground start denied")
            stopSelf()
            return START_NOT_STICKY
        }
        
        // Always update isRunning and ensure timer is active when starting with new config
        if (!isRunning) {
            isRunning = true
            val delayMs = getNextDelayMs()
            Log.d(TAG, "Service started. First proactive check in ${delayMs / 1000} seconds")
            handler.postDelayed(proactiveRunnable, delayMs)
        } else {
            Log.d(TAG, "Service already running. Timer will continue with updated intervalMs: $intervalMs")
            // Optional: Restart timer immediately with new interval
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
        stopWakeCaptureLoop()
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
        } catch (t: Throwable) {
            Log.w(TAG, "Restart service onTaskRemoved failed: ${t.message}")
        }
        super.onTaskRemoved(rootIntent)
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

    private fun buildNotification(): Notification {
        val pendingIntent = buildLaunchPendingIntent(0)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Zero Two Assistant")
            .setContentText("Watching over you in background")
            .setSubText("Background service")
            .setSmallIcon(R.drawable.ic_stat_waifu)
            .setLargeIcon(BitmapFactory.decodeResource(resources, R.drawable.logi))
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
            return proactiveRandomIntervalsMs[Random().nextInt(proactiveRandomIntervalsMs.size)]
        }
        return if (intervalMs > 0) intervalMs else 15000L
    }

    private fun fetchAndShowProactiveMessage() {
        val key = apiKey
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
                            put("content", "You are Zero Two, a loving anime wife. Refer to me as 'honey' or 'darling'. Keep it short (max 10 words). No expressions.")
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
        val manager = getSystemService(NotificationManager::class.java)
        val pendingIntent = buildLaunchPendingIntent(Random().nextInt())
        val largeIcon = BitmapFactory.decodeResource(resources, R.drawable.logi)

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
            .setTimeoutAfter(25000)
            .addAction(
                android.R.drawable.ic_menu_view,
                "Open App",
                pendingIntent
            )
            .build()
        val uniqueId = (System.currentTimeMillis() % Int.MAX_VALUE).toInt()
        manager?.notify(uniqueId, notification)
    }

    private fun showWakeAlert(content: String, pulse: Boolean) {
        if (!pulse) {
            updateNotification(content)
            return
        }

        val manager = getSystemService(NotificationManager::class.java)
        val pendingIntent = buildLaunchPendingIntent(WAKE_EVENT_NOTIFICATION_ID)
        val largeIcon = BitmapFactory.decodeResource(resources, R.drawable.logi)

        val notification = NotificationCompat.Builder(this, MESSAGE_CHANNEL_ID)
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
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOnlyAlertOnce(false)
            .setDefaults(NotificationCompat.DEFAULT_LIGHTS or NotificationCompat.DEFAULT_VIBRATE)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setTimeoutAfter(14000)
            .addAction(
                android.R.drawable.ic_menu_view,
                "Open App",
                pendingIntent
            )
            .build()

        manager?.notify(WAKE_EVENT_NOTIFICATION_ID, notification)
    }

    private fun pickFallbackMessage(): String {
        val options = listOf(
            "Hey darling, what are you doing now?",
            "Can we talk for a minute? I miss you.",
            "I am here with you. Want to chat now?",
            "Darling, are you free? Let us talk."
        )
        return options[Random().nextInt(options.size)]
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

    private fun hasMicPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            android.Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
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
        if (wakeModeEnabled) {
            if (!ensureForegroundStarted(requireMicrophone = true)) {
                Log.w(TAG, "Microphone foreground escalation blocked; disabling wake mode")
                wakeModeEnabled = false
                saveConfig()
                stopWakeCaptureLoop()
                return
            }
            startWakeCaptureLoop()
        } else {
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
    }

    private fun startWakeCaptureSnippet() {
        if (wakeCaptureInProgress) {
            scheduleNextWakeCapture(300L)
            return
        }
        if (!isRunning || !wakeModeEnabled || !hasMicPermission()) {
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
        handler.postDelayed({ stopWakeCaptureAndProcess() }, wakeCaptureDurationMs)
    }

    private fun stopWakeCaptureAndProcess() {
        val file = wakeAudioFile
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
                    val heard = transcribeWakeAudio(file)
                    if (heard.isNotBlank()) {
                        handleRecognizedText(heard)
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
        if (!wakeLoopRunning || !isRunning || !wakeModeEnabled) return
        handler.removeCallbacks(wakeCaptureRunnable)
        handler.postDelayed(wakeCaptureRunnable, delayMs.coerceAtLeast(80L))
    }

    private fun nextWakeCaptureDelayMs(): Long {
        return if (waitingForCommand) wakeCaptureFastPauseMs else wakeCapturePauseMs
    }

    private fun transcribeWakeAudio(file: File): String {
        val key = apiKey
        if (key.isNullOrBlank()) return ""

        val boundary = "----ZeroTwoBoundary${System.currentTimeMillis()}"
        val conn = (URL(wakeTranscriptionUrl).openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            setRequestProperty("Authorization", "Bearer $key")
            setRequestProperty("Content-Type", "multipart/form-data; boundary=$boundary")
            connectTimeout = 8000
            readTimeout = 12000
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
            .replace(Regex("[^a-z0-9\\s]"), " ")
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
        val normalized = normalizeSpeechText(rawText)
        if (normalized.isBlank()) return

        if (waitingForCommand && System.currentTimeMillis() > wakeWindowOpenUntilMs) {
            waitingForCommand = false
        }

        if (waitingForCommand) {
            waitingForCommand = false
            handleVoiceCommand(normalized)
            return
        }

        if (!containsWakePhrase(normalized)) {
            return
        }

        val inlineCommand = stripWakePhrases(normalized)
        if (inlineCommand.isNotBlank()) {
            handleVoiceCommand(inlineCommand)
            return
        }

        waitingForCommand = true
        wakeWindowOpenUntilMs = System.currentTimeMillis() + wakeWindowMs
        showWakeAlert("Wake word detected. Speak your command now.", pulse = false)
    }

    private fun handleVoiceCommand(command: String) {
        val cleaned = command.trim()
        if (cleaned.isBlank()) return
        persistChatMessage("user", cleaned)
        fetchAndRespondToVoiceCommand(cleaned)
    }

    private fun fetchAndRespondToVoiceCommand(command: String) {
        if (commandGenerating) return

        val key = apiKey
        val urlStr = apiUrl
        if (key.isNullOrEmpty() || urlStr.isNullOrEmpty()) {
            Log.e(TAG, "Cannot process voice command: apiKey or apiUrl missing")
            showWakeAlert("I need API setup to answer you.", pulse = true)
            return
        }

        commandGenerating = true
        executor.execute {
            try {
                val url = URL(urlStr)
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod = "POST"
                conn.setRequestProperty("Authorization", "Bearer $key")
                conn.setRequestProperty("Content-Type", "application/json")
                conn.connectTimeout = 15000
                conn.readTimeout = 15000
                conn.doOutput = true

                val payload = JSONObject().apply {
                    put("model", if (model.isNullOrEmpty()) "moonshotai/kimi-k2-instruct" else model)
                    val messages = JSONArray().apply {
                        put(JSONObject().apply {
                            put("role", "system")
                            put("content", "You are Zero Two. Keep answers short, clear, and caring.")
                        })
                        put(JSONObject().apply {
                            put("role", "user")
                            put("content", command)
                        })
                    }
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

                persistChatMessage("assistant", reply)
                showWakeAlert(reply, pulse = true)
            } catch (e: Exception) {
                Log.e(TAG, "Voice command error: ${e.message}")
                val fallback = "I had trouble processing that. Try again."
                persistChatMessage("assistant", fallback)
                showWakeAlert(fallback, pulse = true)
            } finally {
                commandGenerating = false
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
        manager?.notify(NOTIFICATION_ID, notification)
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
