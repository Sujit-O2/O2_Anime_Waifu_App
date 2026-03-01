package com.example.anime_waifu

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
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
    private var intervalMs: Long = 20000 // Default 20s
    private var isGenerating = false

    private val proactiveRunnable = object : Runnable {
        override fun run() {
            if (isRunning && !isGenerating) {
                fetchAndShowProactiveMessage()
            }
            handler.postDelayed(this, intervalMs)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        apiKey = intent?.getStringExtra("API_KEY")
        apiUrl = intent?.getStringExtra("API_URL")
        model = intent?.getStringExtra("MODEL")
        intervalMs = intent?.getLongExtra("INTERVAL_MS", 20000L) ?: 20000L

        val notification = buildNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        if (!isRunning) {
            isRunning = true
            handler.postDelayed(proactiveRunnable, intervalMs)
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
        startService(restartServiceIntent)
        super.onTaskRemoved(rootIntent)
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Zero Two")
            .setContentText("Always here for you... ❤️")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setColor(0xFFFF5252.toInt()) // Set to red/pink accent color
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun fetchAndShowProactiveMessage() {
        val key = apiKey
        val urlStr = apiUrl
        if (key.isNullOrEmpty() || urlStr.isNullOrEmpty()) return

        isGenerating = true
        executor.execute {
            try {
                val url = URL(urlStr)
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod = "POST"
                conn.setRequestProperty("Authorization", "Bearer $key")
                conn.setRequestProperty("Content-Type", "application/json")
                conn.doOutput = true

                val payload = JSONObject().apply {
                    put("model", model ?: "moonshotai/kimi-k2-instruct")
                    val messages = JSONArray().apply {
                        put(JSONObject().apply {
                            put("role", "system")
                            put("content", "You are Zero Two, a loving and caring anime waifu. Generate a very short (max 10 words), cute check-up message for your darling. Use emojis. One sentence.")
                        })
                        put(JSONObject().apply {
                            put("role", "user")
                            put("content", "Say something sweet!")
                        })
                    }
                    put("messages", messages)
                }

                OutputStreamWriter(conn.outputStream).use { it.write(payload.toString()) }

                if (conn.responseCode == 200) {
                    val reader = BufferedReader(InputStreamReader(conn.inputStream))
                    val response = reader.use { it.readText() }
                    val jsonResponse = JSONObject(response)
                    val content = jsonResponse.getJSONArray("choices")
                        .getJSONObject(0)
                        .getJSONObject("message")
                        .getString("content")
                        .trim()

                    updateNotification(content)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error fetching proactive message: ${e.message}")
            } finally {
                isGenerating = false
            }
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
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
        manager?.notify(NOTIFICATION_ID, notification)
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Assistant Mode",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            manager?.createNotificationChannel(channel)
        }
    }
}
