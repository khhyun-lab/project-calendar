package com.example.today_schedule

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WidgetProvider4x6 : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout_4x6)
            val imagePath = widgetData.getString("filename_widget_4x6", null)
            if (imagePath != null) {
                views.setImageViewUri(R.id.widget_image, Uri.parse(imagePath))
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

