package com.example.anime_waifu

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class WaifuWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.waifu_widget).apply {
                // Get data pushed from Flutter
                val title = widgetData.getString("waifu_name", "No Waifu Selected")
                setTextViewText(R.id.widget_title, title)
                
                val imagePath = widgetData.getString("waifu_image_path", null)
                if (imagePath != null) {
                    val imgFile = File(imagePath)
                    if (imgFile.exists()) {
                        val options = BitmapFactory.Options().apply {
                            inJustDecodeBounds = true
                        }
                        BitmapFactory.decodeFile(imgFile.absolutePath, options)
                        // Scale down to fit widget (max 400px)
                        val maxDim = 400
                        val scale = maxOf(1, maxOf(options.outWidth, options.outHeight) / maxDim)
                        val decodeOptions = BitmapFactory.Options().apply {
                            inSampleSize = scale
                        }
                        val bitmap = BitmapFactory.decodeFile(imgFile.absolutePath, decodeOptions)
                        setImageViewBitmap(R.id.widget_image, bitmap)
                    }
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
