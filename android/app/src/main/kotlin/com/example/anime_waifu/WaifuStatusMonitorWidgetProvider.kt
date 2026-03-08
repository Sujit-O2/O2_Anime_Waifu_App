package com.example.anime_waifu

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WaifuStatusMonitorWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val battery = WidgetSupport.batteryPercent(context)
        val memory = WidgetSupport.memoryPercent(context)

        for (id in appWidgetIds) {
            val pendingIntent = WidgetSupport.launchAppPendingIntent(context, id + 1000)
            val views = RemoteViews(context.packageName, R.layout.widget_status_monitor)
            views.setProgressBar(R.id.pb_battery, 100, battery, false)
            views.setProgressBar(R.id.pb_memory, 100, memory, false)
            views.setTextViewText(R.id.tv_battery, "$battery%")
            views.setTextViewText(R.id.tv_memory, "$memory%")
            WidgetSupport.wireClicks(
                views,
                pendingIntent,
                R.id.pb_battery,
                R.id.pb_memory,
                R.id.tv_battery,
                R.id.tv_memory,
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
