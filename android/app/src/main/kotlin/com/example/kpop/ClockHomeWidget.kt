package com.example.kpop

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class ClockHomeWidget : AppWidgetProvider() {

    companion object {
        private val handler = Handler(Looper.getMainLooper())
        private var runnable: Runnable? = null
        private const val TAG = "ClockWidget"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        startTicking(context, appWidgetManager, appWidgetIds)
    }

    override fun onDisabled(context: Context) {
        runnable?.let { handler.removeCallbacks(it) }
        runnable = null
    }

    private fun startTicking(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        runnable?.let { handler.removeCallbacks(it) }

        runnable = object : Runnable {
            override fun run() {
                val prefs = HomeWidgetPlugin.getData(context)
                val sdfTime = SimpleDateFormat("hh:mm:ss a", Locale.getDefault())
                val sdfDate = SimpleDateFormat("dd/MM/yyyy (EEEE)", Locale.getDefault())

                for (appWidgetId in appWidgetIds) {
                    val views = RemoteViews(context.packageName, R.layout.clock_widget)

                    // Update date & time
                    views.setTextViewText(R.id.clockTimeText, sdfTime.format(Date()).uppercase())
                    views.setTextViewText(R.id.clockDateText, sdfDate.format(Date()))

                    // --- UPDATED: Load latest exported image using pending_k_widget_id ---
                    val pendingId = prefs.getString("pending_k_widget_id", null)
                    val imagePath = pendingId?.let { prefs.getString("clock_image_$it", null) }

                    Log.d(TAG, "widgetId=$appWidgetId pendingId=$pendingId imagePath=$imagePath")

                    if (!imagePath.isNullOrEmpty()) {
                        val imgFile = File(imagePath)
                        if (imgFile.exists()) {
                            val bitmap = BitmapFactory.decodeFile(imgFile.absolutePath)
                            if (bitmap != null) {
                                val scaledBitmap = Bitmap.createScaledBitmap(bitmap, 200, 200, true)
                                views.setImageViewBitmap(R.id.clockImage, scaledBitmap)
                            } else {
                                Log.w(TAG, "Failed to decode bitmap from $imagePath")
                                views.setImageViewResource(R.id.clockImage, R.drawable.ic_placeholder)
                            }
                        } else {
                            Log.w(TAG, "Image file does not exist: $imagePath")
                            views.setImageViewResource(R.id.clockImage, R.drawable.ic_placeholder)
                        }
                    } else {
                        Log.d(TAG, "No imagePath for widgetId=$appWidgetId")
                        views.setImageViewResource(R.id.clockImage, R.drawable.ic_placeholder)
                    }

                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }

                handler.postDelayed(this, 1000)
            }
        }

        handler.post(runnable!!)
    }
}