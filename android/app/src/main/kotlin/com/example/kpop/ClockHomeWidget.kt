package com.example.kpop

import android.app.PendingIntent
import android.content.Intent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
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

                    // Save widget ID for Flutter
                    prefs.edit().putInt("widgetId", appWidgetId).apply()

                    val views = RemoteViews(context.packageName, R.layout.clock_widget)

                    // Update time/date
                    views.setTextViewText(
                        R.id.clockTimeText,
                        sdfTime.format(Date()).uppercase()
                    )
                    views.setTextViewText(
                        R.id.clockDateText,
                        sdfDate.format(Date())
                    )

                    // Load image safely
                    val imagePath = prefs.getString("clock_image_$appWidgetId", null)
                    Log.d(TAG, "widgetId=$appWidgetId imagePath=$imagePath")

                    if (!imagePath.isNullOrEmpty()) {
                        val file = File(imagePath)
                        if (file.exists()) {
                            val bitmap = decodeSampledBitmap(file.absolutePath, 600, 600)
                            views.setImageViewBitmap(R.id.clockImage, bitmap)
                        } else {
                            views.setImageViewResource(
                                R.id.clockImage,
                                R.drawable.ic_placeholder
                            )
                        }
                    } else {
                        views.setImageViewResource(
                            R.id.clockImage,
                            R.drawable.ic_placeholder
                        )
                    }

                    // Open app when widget tapped
                    val intent = Intent(context, MainActivity::class.java)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK

                    val pendingIntent = PendingIntent.getActivity(
                        context,
                        appWidgetId,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )

                    views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }

                handler.postDelayed(this, 1000)
            }
        }

        handler.post(runnable!!)
    }

    // -------------------------------
    // Helper: Scale large images safely
    // -------------------------------
    private fun decodeSampledBitmap(path: String, reqWidth: Int, reqHeight: Int) =
        BitmapFactory.decodeFile(path, BitmapFactory.Options().apply {
            inJustDecodeBounds = true
            BitmapFactory.decodeFile(path, this)

            inSampleSize = calculateInSampleSize(this, reqWidth, reqHeight)
            inJustDecodeBounds = false
        })

    private fun calculateInSampleSize(
        options: BitmapFactory.Options,
        reqWidth: Int,
        reqHeight: Int
    ): Int {
        val (height: Int, width: Int) = options.outHeight to options.outWidth
        var inSampleSize = 1

        if (height > reqHeight || width > reqWidth) {
            val halfHeight: Int = height / 2
            val halfWidth: Int = width / 2

            while ((halfHeight / inSampleSize) >= reqHeight &&
                (halfWidth / inSampleSize) >= reqWidth
            ) {
                inSampleSize *= 2
            }
        }
        return inSampleSize
    }
}