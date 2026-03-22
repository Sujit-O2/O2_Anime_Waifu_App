package com.example.anime_waifu

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WaifuDashboardWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val affectionLevel =
            WidgetSupport.readString(widgetData.getString("affection_level", null), "Her Darling")
        val affectionProgress = widgetData.getInt("affection_progress", 0).coerceIn(0, 100)
        val latestChat =
            WidgetSupport.readString(
                widgetData.getString("latest_chat", null),
                "Tap to talk to me, Darling~",
            )

        for (id in appWidgetIds) {
            val pendingIntent = WidgetSupport.launchAppPendingIntent(context, id)
            val views = RemoteViews(context.packageName, R.layout.widget_dashboard)
            views.setTextViewText(R.id.tv_affection, "$affectionLevel  $affectionProgress%")
            views.setTextViewText(R.id.tv_latest_chat, latestChat)
            WidgetSupport.wireClicks(
                views,
                pendingIntent,
                R.id.btn_chat,
                R.id.btn_voice,
                R.id.widget_bg,
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
