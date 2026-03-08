package com.example.anime_waifu

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WaifuQuoteBannerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val quote =
            WidgetSupport.readString(
                widgetData.getString("daily_quote", null),
                "\"Open the app for today's quote.\"",
            )

        for (id in appWidgetIds) {
            val pendingIntent = WidgetSupport.launchAppPendingIntent(context, id + 3000)
            val views = RemoteViews(context.packageName, R.layout.widget_quote_banner)
            views.setTextViewText(R.id.tv_quote, quote)
            WidgetSupport.wireClicks(views, pendingIntent, R.id.tv_quote)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
