package com.kwall.kwall

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

class KwallPetWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        const val PREFS_NAME = "kwall_widget_data"
        const val KEY_PET_NAME = "pet_name"
        const val KEY_PET_LEVEL = "pet_level"
        const val KEY_PET_XP = "pet_xp"
        const val KEY_PET_XP_IN_LEVEL = "pet_xp_in_level"
        const val KEY_COMPLETED_HABITS = "completed_habits"
        const val KEY_TOTAL_HABITS = "total_habits"
        const val KEY_PENDING_HABITS = "pending_habits"
        const val KEY_STATUS_MESSAGE = "status_message"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val petName = prefs.getString(KEY_PET_NAME, "Mishi") ?: "Mishi"
            val petLevel = prefs.getInt(KEY_PET_LEVEL, 1)
            val xpInLevel = prefs.getInt(KEY_PET_XP_IN_LEVEL, 0)
            val completedHabits = prefs.getInt(KEY_COMPLETED_HABITS, 0)
            val totalHabits = prefs.getInt(KEY_TOTAL_HABITS, 0)
            val pendingHabits = prefs.getInt(KEY_PENDING_HABITS, 0)
            val customMessage = prefs.getString(KEY_STATUS_MESSAGE, null)

            val statusMessage = if (!customMessage.isNullOrBlank()) {
                customMessage
            } else if (pendingHabits > 0) {
                "Tienes $pendingHabits ${if (pendingHabits == 1) "hábito pendiente" else "hábitos pendientes"} hoy 🐾"
            } else if (totalHabits > 0) {
                "¡Todos los hábitos completados! ✨"
            } else {
                "¡Todo al día y organizado! 🐾"
            }

            val views = RemoteViews(context.packageName, R.layout.kwall_pet_widget)
            views.setTextViewText(R.id.widget_pet_name, petName)
            views.setTextViewText(R.id.widget_pet_level, "Niv. $petLevel")
            views.setTextViewText(R.id.widget_pet_status, statusMessage)
            views.setProgressBar(R.id.widget_pet_xp_progress, 100, xpInLevel.coerceIn(0, 100), false)
            views.setTextViewText(R.id.widget_pet_xp_text, "$xpInLevel / 100 XP")

            val habitsSummary = if (totalHabits == 0) {
                "Sin hábitos asignados"
            } else if (pendingHabits == 0) {
                "¡$completedHabits/$totalHabits completados! 🎉"
            } else {
                "$completedHabits/$totalHabits hechos ($pendingHabits pend.)"
            }
            views.setTextViewText(R.id.widget_habits_summary, habitsSummary)

            // Intent to launch MainActivity with route extra
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "habits")
            }

            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            val pendingIntent = PendingIntent.getActivity(context, 0, intent, flags)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_habits_container, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, KwallPetWidgetProvider::class.java)
            val ids = appWidgetManager.getAppWidgetIds(component)
            if (ids != null && ids.isNotEmpty()) {
                for (id in ids) {
                    updateAppWidget(context, appWidgetManager, id)
                }
            }
        }
    }
}
