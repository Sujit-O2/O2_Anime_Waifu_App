package com.example.anime_waifu

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.widget.Toast
import androidx.core.app.NotificationCompat
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import org.json.JSONObject
import org.json.JSONArray
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.util.Random

class AssistantForegroundService : Service() {
    companion object {
        private const val CHANNEL_ID = "assistant_mode_channel"
        private const val MESSAGE_CHANNEL_ID = "assistant_wake_event_channel_dar"
        private const val NOTIFICATION_ID = 2002
        private const val TAG = "AssistantService"
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
    private lateinit var prefs: SharedPreferences
    private lateinit var flutterPrefs: SharedPreferences
    private val proactiveRandomIntervalsMs = longArrayOf(
        10 * 60 * 1000L,
        30 * 60 * 1000L,
        60 * 60 * 1000L,
        2 * 60 * 60 * 1000L,
        5 * 60 * 60 * 1000L
    )

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
        Toast.makeText(this, "Zero Two Service Active ❤️", Toast.LENGTH_SHORT).show()
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
        Log.d(TAG, "Config loaded: API_KEY=${!apiKey.isNullOrEmpty()}, proactiveEnabled=$proactiveEnabled, proactiveRandomEnabled=$proactiveRandomEnabled")
    }

    private fun saveConfig() {
        prefs.edit().apply {
            putString("api_key", apiKey)
            putString("api_url", apiUrl)
            putString("model", model)
            putLong("interval_ms", intervalMs)
            putBoolean("proactive_enabled", proactiveEnabled)
            putBoolean("proactive_random_enabled", proactiveRandomEnabled)
            apply()
        }
        Log.d(TAG, "Config saved: proactiveEnabled=$proactiveEnabled, proactiveRandomEnabled=$proactiveRandomEnabled")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action == "SET_PROACTIVE_MODE") {
            // Ensure service is promoted and marked running even when this action
            // is the first entry-point (e.g. process/service recreation).
            if (!isRunning) {
                val notification = buildNotification()
                startForeground(NOTIFICATION_ID, notification)
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

        val notification = buildNotification()
        startForeground(NOTIFICATION_ID, notification)
        
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
        
        return START_STICKY
    }

    override fun onDestroy() {
        isRunning = false
        handler.removeCallbacks(proactiveRunnable)
        executor.shutdown()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onTaskRemoved(rootIntent: Intent?) {
        // This is called when the app is swiped away from recent tasks.
        // We restart the service to ensure it keeps running.
        val restartServiceIntent = Intent(applicationContext, this.javaClass)
        restartServiceIntent.setPackage(packageName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(restartServiceIntent)
        } else {
            startService(restartServiceIntent)
        }
        super.onTaskRemoved(rootIntent)
    }

    private fun buildNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Zero Two Mode Alpha")
            .setContentText("Watching over you... ❤️")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setColor(0xFFFF5252.toInt())
            .setPriority(NotificationCompat.PRIORITY_MIN) // Use MIN/LOW for the persistent icon to stay quiet
            .build()
    }

    private fun getNextDelayMs(): Long {
        if (proactiveRandomEnabled) {
            return proactiveRandomIntervalsMs[Random().nextInt(proactiveRandomIntervalsMs.size)]
        }
        return if (intervalMs > 0) intervalMs else 15000L
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

    private fun fetchAndShowProactiveMessage() {
        handler.post { Toast.makeText(this, "Checking in on you... ❤️", Toast.LENGTH_SHORT).show() }
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
                    showProactiveAlert(content)
                } else {
                    val errorReader = BufferedReader(InputStreamReader(conn.errorStream ?: conn.inputStream))
                    val errorResponse = errorReader.use { it.readText() }
                    Log.e(TAG, "API Error Response: $errorResponse")
                    
                    // Fallback message if API fails so user knows service is alive
                    showProactiveAlert(pickFallbackMessage())
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error fetching proactive message: ${e.message}")
                e.printStackTrace()
                showProactiveAlert(pickFallbackMessage())
            } finally {
                isGenerating = false
            }
        }
    }

    private fun showProactiveAlert(content: String) {
        persistProactiveMessage(content)
        val manager = getSystemService(NotificationManager::class.java)
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        // Use a unique request code to ensure the intent is fresh
        val pendingIntent = PendingIntent.getActivity(
            this, Random().nextInt(), launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, MESSAGE_CHANNEL_ID)
            .setContentTitle("Zero Two ❤️")
            .setContentText(content)
            .setStyle(NotificationCompat.BigTextStyle().bigText(content))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setAutoCancel(true) // Dismissible
            .setContentIntent(pendingIntent)
            .setColor(0xFFFF5252.toInt())
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(Notification.DEFAULT_ALL)
            .setSound(getDarSoundUri())
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .build()
        val uniqueId = (System.currentTimeMillis() % Int.MAX_VALUE).toInt()
        manager?.notify(uniqueId, notification)
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
        try {
            val flutterPendingKey = "flutter.pending_proactive_messages"
            val raw = flutterPrefs.getString(
                flutterPendingKey,
                prefs.getString("pending_proactive_messages", "[]") ?: "[]"
            ) ?: "[]"
            val list = JSONArray(raw)
            list.put(
                JSONObject().apply {
                    put("role", "assistant")
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
            prefs.edit().putString("pending_proactive_messages", trimmed.toString()).apply()
            flutterPrefs.edit().putString(flutterPendingKey, trimmed.toString()).apply()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to persist proactive message: ${e.message}")
        }
    }

    private fun updateNotification(content: String) {
        val manager = getSystemService(NotificationManager::class.java)
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Zero Two")
            .setContentText(content)
            .setStyle(NotificationCompat.BigTextStyle().bigText(content))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setColor(0xFFFF5252.toInt())
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        manager?.notify(NOTIFICATION_ID, notification)
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java) ?: return
            
            // Channel for the persistent service icon
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Assistant Mode",
                NotificationManager.IMPORTANCE_LOW
            )
            manager.createNotificationChannel(serviceChannel)

            // Channel for the 'WhatsApp style' pop-ups
            val messageChannel = NotificationChannel(
                MESSAGE_CHANNEL_ID,
                "Wake Events",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Caring messages from Zero Two"
                enableLights(true)
                lightColor = android.graphics.Color.RED
                enableVibration(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(getDarSoundUri(), getDarAudioAttributes())
            }
            manager.createNotificationChannel(messageChannel)
        }
    }
}
