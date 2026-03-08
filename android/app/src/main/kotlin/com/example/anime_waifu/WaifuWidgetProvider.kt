package com.example.anime_waifu

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

open class WaifuWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = getRemoteViews(context, widgetId)
            
            // Re-bind Action Widget Buttons
            try {
                // Determine if this specific RemoteViews instance contains the action buttons
                // by checking if the layout binds successfully without crashing
                
                // Talk Action
                val talkIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context, Uri.parse("waifu://action/talk")
                )
                views.setOnClickPendingIntent(R.id.btn_action_talk, talkIntent)

                // Routine Action
                val routineIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context, Uri.parse("waifu://action/routine")
                )
                views.setOnClickPendingIntent(R.id.btn_action_morning, routineIntent)

                // Quests Launcher Action
                val questsIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("waifu://launch/quests")
                )
                views.setOnClickPendingIntent(R.id.btn_action_quests, questsIntent)
            } catch (e: Exception) {
                // Ignore if layout doesn't have these buttons
            }

            // Update Affection Data
            val affectionLevel = widgetData.getString("affection_level", "Stranger")
            val affectionPoints = widgetData.getInt("affection_points", 0)
            val affectionProgress = widgetData.getInt("affection_progress", 0)
            try {
                views.setTextViewText(R.id.widget_affection_level, affectionLevel)
                views.setTextViewText(R.id.widget_affection_points, "\$affectionPoints pts")
                views.setProgressBar(R.id.widget_affection_progress, 100, affectionProgress, false)
                
                // Clicking affection opens the app
                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java, Uri.parse("waifu://launch/main")
                )
                views.setOnClickPendingIntent(R.id.widget_root, launchIntent)
            } catch (e: Exception) {}

            // Update Quote Data
            val quoteData = widgetData.getString("daily_quote", "Your waifu loves you.")
            try {
                views.setTextViewText(R.id.widget_quote_text, quoteData)
                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java, Uri.parse("waifu://launch/main")
                )
                views.setOnClickPendingIntent(R.id.widget_root, launchIntent)
            } catch (e: Exception) {}

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun getRemoteViews(context: Context, widgetId: Int): RemoteViews {
        // Since we have multiple widget layouts, we need to inspect the widget info to know which one this is.
        val manager = AppWidgetManager.getInstance(context)
        val info = manager.getAppWidgetInfo(widgetId)
        val layoutId = info?.initialLayout ?: R.layout.waifu_quote_widget
        return RemoteViews(context.packageName, layoutId)
    }
}
