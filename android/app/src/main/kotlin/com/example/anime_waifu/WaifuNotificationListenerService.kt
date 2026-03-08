package com.example.anime_waifu

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import java.util.LinkedList

class WaifuNotificationListenerService : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return
        try {
            val extras = sbn.notification?.extras ?: return
            val title = extras.getString("android.title") ?: return
            val text = extras.getCharSequence("android.text")?.toString() ?: ""
            val appName = try {
                packageManager.getApplicationLabel(
                    packageManager.getApplicationInfo(sbn.packageName, 0)
                ).toString()
            } catch (_: Exception) { sbn.packageName }

            synchronized(recent) {
                recent.addFirst(mapOf("app" to appName, "text" to "$title: $text"))
                while (recent.size > MAX_NOTIFS) recent.removeLast()
            }
        } catch (_: Exception) {}
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) { /* no-op */ }

    companion object {
        private const val MAX_NOTIFS = 20
        private val recent = LinkedList<Map<String, String>>()

        @JvmStatic
        fun getRecentNotifications(): List<Map<String, String>> {
            synchronized(recent) { return recent.toList() }
        }
    }
}
