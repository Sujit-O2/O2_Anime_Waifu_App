package com.example.anime_waifu

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.text.SpannableString
import android.text.style.ForegroundColorSpan
import androidx.core.app.NotificationCompat
import android.os.Build

/**
 * Advanced notification enhancements for anime_waifu app
 * Features: Rich styles, actions, progress indicators, grouped notifications
 */
object NotificationEnhancer {
    
    /**
     * Create a notification with action buttons (reply, snooze, open)
     */
    fun createInteractiveNotification(
        context: Context,
        channelId: String,
        notificationId: Int,
        title: String,
        message: String,
        actions: List<Pair<String, PendingIntent>> = emptyList(),
        themeColors: ThemeColorManager.ThemeColors
    ): NotificationCompat.Builder {
        val largeIcon = BitmapFactory.decodeResource(context.resources, android.R.drawable.ic_dialog_map)
        
        val builder = NotificationCompat.Builder(context, channelId)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_notification_clear_all)
            .setLargeIcon(largeIcon)
            .setColor(themeColors.primaryColor)
            .setColorized(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
        
        // Add action buttons (e.g., Reply, Snooze, Open)
        for ((actionLabel, pendingIntent) in actions) {
            builder.addAction(0, actionLabel, pendingIntent)
        }
        
        return builder
    }
    
    /**
     * Create a progress notification (for downloads, uploads, etc.)
     */
    fun createProgressNotification(
        context: Context,
        channelId: String,
        title: String,
        progress: Int, // 0-100
        isIndeterminate: Boolean = false,
        themeColors: ThemeColorManager.ThemeColors,
        cancelIntent: PendingIntent? = null
    ): NotificationCompat.Builder {
        val builder = NotificationCompat.Builder(context, channelId)
            .setContentTitle(title)
            .setContentText("$progress% complete")
            .setSmallIcon(android.R.drawable.ic_notification_clear_all)
            .setOngoing(true)
            .setColor(themeColors.accentColor)
            .setColorized(true)
            .setProgress(100, progress, isIndeterminate)
            .setPriority(NotificationCompat.PRIORITY_LOW)
        
        if (cancelIntent != null) {
            builder.addAction(0, "Cancel", cancelIntent)
        }
        
        return builder
    }
    
    /**
     * Create a big picture notification (for sharing images, screenshots)
     */
    fun createBigPictureNotification(
        context: Context,
        channelId: String,
        title: String,
        summary: String,
        themeColors: ThemeColorManager.ThemeColors
    ): NotificationCompat.Builder {
        val largeTitle = SpannableString(title).apply {
            setSpan(ForegroundColorSpan(themeColors.accentColor), 0, title.length, 0)
        }
        
        return NotificationCompat.Builder(context, channelId)
            .setContentTitle(largeTitle)
            .setContentText(summary)
            .setSmallIcon(android.R.drawable.ic_notification_clear_all)
            .setColor(themeColors.primaryColor)
            .setColorized(true)
            .setStyle(NotificationCompat.BigTextStyle()
                .setBigContentTitle(title)
                .bigText(summary))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
    }
    
    /**
     * Create a grouped notification with summary
     */
    fun createGroupedNotification(
        context: Context,
        channelId: String,
        title: String,
        message: String,
        groupKey: String,
        themeColors: ThemeColorManager.ThemeColors,
        isGroupSummary: Boolean = false
    ): NotificationCompat.Builder {
        return NotificationCompat.Builder(context, channelId)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_notification_clear_all)
            .setColor(themeColors.accentColor)
            .setColorized(true)
            .setGroup(groupKey)
            .setGroupSummary(isGroupSummary)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
    }
    
    /**
     * Create an inbox-style notification (for multiple messages)
     */
    fun createInboxNotification(
        context: Context,
        channelId: String,
        title: String,
        messages: List<String>,
        themeColors: ThemeColorManager.ThemeColors
    ): NotificationCompat.Builder {
        val inboxStyle = NotificationCompat.InboxStyle()
            .setBigContentTitle(title)
        
        for (message in messages.take(5)) {
            inboxStyle.addLine(message)
        }
        
        if (messages.size > 5) {
            inboxStyle.setSummaryText("+${messages.size - 5} more messages")
        }
        
        return NotificationCompat.Builder(context, channelId)
            .setContentTitle(title)
            .setContentText("${messages.size} messages")
            .setSmallIcon(android.R.drawable.ic_notification_clear_all)
            .setColor(themeColors.primaryColor)
            .setColorized(true)
            .setStyle(inboxStyle)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
    }
    
    /**
     * Create a heads-up notification (floating notification for important alerts)
     */
    fun createHeadsUpNotification(
        context: Context,
        channelId: String,
        title: String,
        message: String,
        fullScreenIntent: PendingIntent? = null,
        themeColors: ThemeColorManager.ThemeColors
    ): NotificationCompat.Builder {
        val builder = NotificationCompat.Builder(context, channelId)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_notification_clear_all)
            .setColor(themeColors.accentColor)
            .setColorized(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setVibrate(longArrayOf(0, 250, 250, 250))
            .setLights(themeColors.accentColor, 100, 100)
        
        if (fullScreenIntent != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            builder.setFullScreenIntent(fullScreenIntent, true)
        }
        
        return builder
    }
    
    /**
     * Create a message notification with colored reply text
     */
    fun createMessageNotification(
        context: Context,
        channelId: String,
        sender: String,
        message: String,
        timestamp: String,
        themeColors: ThemeColorManager.ThemeColors
    ): NotificationCompat.Builder {
        // Create colored sender name
        val styledTitle = SpannableString(sender).apply {
            setSpan(ForegroundColorSpan(themeColors.accentColor), 0, sender.length, 0)
        }
        
        return NotificationCompat.Builder(context, channelId)
            .setContentTitle(styledTitle)
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_notification_clear_all)
            .setSubText(timestamp)
            .setColor(themeColors.primaryColor)
            .setColorized(true)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
    }
    
    /**
     * Create a notification with inline reply action (for messaging)
     */
    fun createReplyableNotification(
        context: Context,
        channelId: String,
        title: String,
        message: String,
        replyAction: PendingIntent,
        themeColors: ThemeColorManager.ThemeColors
    ): NotificationCompat.Builder {
        val remoteInput = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            androidx.core.app.RemoteInput.Builder("quick_reply")
                .setLabel("Reply...")
                .build()
        } else {
            null
        }
        
        val builder = NotificationCompat.Builder(context, channelId)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_notification_clear_all)
            .setColor(themeColors.accentColor)
            .setColorized(true)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
        
        if (remoteInput != null) {
            builder.addAction(
                NotificationCompat.Action.Builder(
                    0,
                    "Reply",
                    replyAction
                ).addRemoteInput(remoteInput).build()
            )
        }
        
        return builder
    }
    
    /**
     * Create a themed action button
     */
    fun createThemedAction(
        iconRes: Int,
        title: String,
        pendingIntent: PendingIntent
    ): NotificationCompat.Action {
        return NotificationCompat.Action.Builder(iconRes, title, pendingIntent)
            .build()
    }
    
    /**
     * Update notification with new content
     */
    fun updateNotification(
        context: Context,
        notificationManager: NotificationManager,
        notificationId: Int,
        builder: NotificationCompat.Builder
    ) {
        notificationManager.notify(notificationId, builder.build())
    }
}
