package com.example.anime_waifu

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WaifuWeatherTimeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val temperature =
            WidgetSupport.readString(widgetData.getString("weather_temp", null), "--°")
        val description =
            WidgetSupport.readString(
                widgetData.getString("weather_desc", null),
                "Open app to refresh",
            )

        for (id in appWidgetIds) {
            val pendingIntent = WidgetSupport.launchAppPendingIntent(context, id + 2000)
            val views = RemoteViews(context.packageName, R.layout.widget_weather_time)
            views.setTextViewText(R.id.tv_temperature, temperature)
            views.setTextViewText(R.id.tv_weather_desc, description)
            WidgetSupport.wireClicks(
                views,
                pendingIntent,
                R.id.tc_time,
                R.id.tc_date,
                R.id.tv_temperature,
                R.id.tv_weather_desc,
                R.id.widget_weather_bg,
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
