package com.example.anime_waifu

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WaifuActionsHubWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val pendingIntent = WidgetSupport.launchAppPendingIntent(context, id + 4000)
            val views = RemoteViews(context.packageName, R.layout.widget_actions_hub)
            WidgetSupport.wireClicks(
                views,
                pendingIntent,
                R.id.btn_morning,
                R.id.btn_sleep,
                R.id.btn_pomodoro,
                R.id.btn_chat,
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
