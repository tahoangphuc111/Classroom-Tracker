package com.phucta.classroom.widget

import android.content.Context
import android.content.Intent
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import com.phucta.classroom.data.model.ClassroomDateUtils
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.TimeZone

class ClassroomGlanceWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ClassroomGlanceWidget()

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        if (action == "com.phucta.classroom.action.UPDATE_WIDGET") {
            if (intent.`package` != null && intent.`package` != context.packageName) {
                return
            }
        }
        if (processAction(action)) {
            triggerWidgetUpdate(context)
        }
    }

    internal fun processAction(action: String?): Boolean {
        return when (action) {
            Intent.ACTION_TIMEZONE_CHANGED -> {
                TimeZone.setDefault(null)
                ClassroomDateUtils.clearCaches()
                true
            }
            Intent.ACTION_TIME_CHANGED, Intent.ACTION_DATE_CHANGED, "android.intent.action.TIME_SET", "com.phucta.classroom.action.UPDATE_WIDGET" -> {
                ClassroomDateUtils.clearCaches()
                true
            }
            else -> false
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
            } finally {
                pendingResult.finish()
            }
        }
    }
}
