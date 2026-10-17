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

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_PET_AFFECTION) {
            handlePetAffection(context)
        }
    }

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
        const val ACTION_PET_AFFECTION = "com.kwall.kwall.ACTION_PET_AFFECTION"
        const val PREFS_NAME = "kwall_widget_data"
        const val KEY_PET_NAME = "pet_name"
        const val KEY_PET_LEVEL = "pet_level"
        const val KEY_PET_XP = "pet_xp"
        const val KEY_PET_XP_IN_LEVEL = "pet_xp_in_level"
        const val KEY_COMPLETED_HABITS = "completed_habits"
        const val KEY_TOTAL_HABITS = "total_habits"
        const val KEY_PENDING_HABITS = "pending_habits"
        const val KEY_STATUS_MESSAGE = "status_message"
        const val KEY_PENDING_AFFECTION_XP = "pending_affection_xp"

        private fun handlePetAffection(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val currentTotalXp = prefs.getInt(KEY_PET_XP, 0)
            val petName = prefs.getString(KEY_PET_NAME, "Mishi") ?: "Mishi"
            val newTotalXp = currentTotalXp + 5
            val newLevel = (newTotalXp / 100) + 1
            val newXpInLevel = newTotalXp % 100
            val pendingAffection = prefs.getInt(KEY_PENDING_AFFECTION_XP, 0) + 5

            val affectionMessages = arrayOf(
                "$petName ronronea feliz... Le encantan tus caricias (+5 XP)",
                "$petName frota su cabeza con carino (+5 XP)",
                "Purrr... $petName se siente muy querido y contento (+5 XP)"
            )
            val msg = affectionMessages[(System.currentTimeMillis() % affectionMessages.size).toInt()]

            prefs.edit()
                .putInt(KEY_PET_XP, newTotalXp)
                .putInt(KEY_PET_LEVEL, newLevel)
                .putInt(KEY_PET_XP_IN_LEVEL, newXpInLevel)
                .putInt(KEY_PENDING_AFFECTION_XP, pendingAffection)
                .putString(KEY_STATUS_MESSAGE, msg)
                .apply()

            updateAllWidgets(context)
        }

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
                "Tienes $pendingHabits ${if (pendingHabits == 1) "habito pendiente" else "habitos pendientes"} hoy."
            } else if (totalHabits > 0) {
                "Todos tus habitos completados hoy."
            } else {
                "Todo al dia y organizado."
            }

            val views = RemoteViews(context.packageName, R.layout.kwall_pet_widget)
            views.setTextViewText(R.id.widget_pet_name, petName)
            views.setTextViewText(R.id.widget_pet_level, "Nivel $petLevel")
            views.setTextViewText(R.id.widget_pet_status, statusMessage)
            views.setProgressBar(R.id.widget_pet_xp_progress, 100, xpInLevel.coerceIn(0, 100), false)
            views.setTextViewText(R.id.widget_pet_xp_text, "$xpInLevel / 100 XP")

            val habitsSummary = if (totalHabits == 0) {
                "Sin habitos asignados"
            } else if (pendingHabits == 0) {
                "$completedHabits de $totalHabits listos"
            } else {
                "$completedHabits de $totalHabits ($pendingHabits pend.)"
            }
            views.setTextViewText(R.id.widget_habits_summary, habitsSummary)

            // Flags for PendingIntents
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            // Launch App PendingIntent
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "habits")
            }
            val pendingLaunch = PendingIntent.getActivity(context, 0, launchIntent, flags)
            views.setOnClickPendingIntent(R.id.widget_root, pendingLaunch)
            views.setOnClickPendingIntent(R.id.widget_habits_container, pendingLaunch)

            // Pet Affection PendingIntent (broadcast directly to this provider)
            val affectionIntent = Intent(context, KwallPetWidgetProvider::class.java).apply {
                action = ACTION_PET_AFFECTION
            }
            val pendingAffection = PendingIntent.getBroadcast(context, 101, affectionIntent, flags)
            views.setOnClickPendingIntent(R.id.widget_pet_affection_btn, pendingAffection)

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
