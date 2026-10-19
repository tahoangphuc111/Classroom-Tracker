package com.phucta.classroom.widget

import android.content.Context
import android.content.Intent
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.TimeZone

class ClassroomGlanceWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ClassroomGlanceWidget()

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            Intent.ACTION_TIMEZONE_CHANGED -> {
                // Clear JVM's cached default timezone so java.util.TimeZone.getDefault() reads the new system timezone
                TimeZone.setDefault(null)
                triggerWidgetUpdate(context)
            }
            Intent.ACTION_TIME_CHANGED, Intent.ACTION_DATE_CHANGED -> {
                triggerWidgetUpdate(context)
            }
        }
    }

    private fun triggerWidgetUpdate(context: Context) {
        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val manager = GlanceAppWidgetManager(context)
                val glanceIds = manager.getGlanceIds(ClassroomGlanceWidget::class.java)
                glanceIds.forEach { glanceId ->
                    ClassroomGlanceWidget().update(context, glanceId)
                }
            } catch (_: Exception) {
                // Ignore transient errors during rapid system broadcast dispatch
            } finally {
                pendingResult.finish()
            }
        }
    }
}
