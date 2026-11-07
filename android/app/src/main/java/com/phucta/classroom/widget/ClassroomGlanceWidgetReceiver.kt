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

object ClassroomWidgetUpdateHelper {
    fun processAction(action: String?): Boolean {
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

    fun triggerWidgetUpdate(receiver: GlanceAppWidgetReceiver, context: Context) {
        val pendingResult = receiver.goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val manager = GlanceAppWidgetManager(context)
                val targetWidget = receiver.glanceAppWidget
                try {
                    val glanceIds = manager.getGlanceIds(targetWidget.javaClass)
                    glanceIds.forEach { glanceId ->
                        targetWidget.update(context, glanceId)
                    }
                } catch (_: Exception) {}
            } catch (_: Exception) {
            } finally {
                pendingResult.finish()
            }
        }
    }

    fun handleReceive(receiver: GlanceAppWidgetReceiver, context: Context, intent: Intent) {
        val action = intent.action
        if (action == "com.phucta.classroom.action.UPDATE_WIDGET") {
            if (intent.`package` != null && intent.`package` != context.packageName) {
                return
            }
        }
        if (processAction(action)) {
            triggerWidgetUpdate(receiver, context)
        }
    }
}

class ClassroomGlanceWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ClassroomGlanceWidget()

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        ClassroomWidgetUpdateHelper.handleReceive(this, context, intent)
    }

    internal fun processAction(action: String?): Boolean = ClassroomWidgetUpdateHelper.processAction(action)
}

class ClassroomSmallWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ClassroomSmallGlanceWidget()

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        ClassroomWidgetUpdateHelper.handleReceive(this, context, intent)
    }

    internal fun processAction(action: String?): Boolean = ClassroomWidgetUpdateHelper.processAction(action)
}

class ClassroomMediumWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ClassroomMediumGlanceWidget()

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        ClassroomWidgetUpdateHelper.handleReceive(this, context, intent)
    }

    internal fun processAction(action: String?): Boolean = ClassroomWidgetUpdateHelper.processAction(action)
}

class ClassroomLargeWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ClassroomLargeGlanceWidget()

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        ClassroomWidgetUpdateHelper.handleReceive(this, context, intent)
    }

    internal fun processAction(action: String?): Boolean = ClassroomWidgetUpdateHelper.processAction(action)
}
