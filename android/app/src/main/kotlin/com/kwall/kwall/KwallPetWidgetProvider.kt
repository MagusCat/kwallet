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
        const val KEY_PET_STYLE = "pet_style"
        const val KEY_THEME_PALETTE = "theme_palette"

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
            val petStyle = (prefs.getString(KEY_PET_STYLE, "classic") ?: "classic").lowercase()
            val themePalette = (prefs.getString(KEY_THEME_PALETTE, "forest") ?: "forest").lowercase()

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

            // Cat Avatar Sprite based on pet style
            val catDrawable = when (petStyle) {
                "ginger" -> R.drawable.ic_widget_cat_ginger
                "siamese" -> R.drawable.ic_widget_cat_siamese
                "calico" -> R.drawable.ic_widget_cat_calico
                "silver" -> R.drawable.ic_widget_cat_silver
                "snow" -> R.drawable.ic_widget_cat_snow
                "cream" -> R.drawable.ic_widget_cat_cream
                "ink" -> R.drawable.ic_widget_cat_ink
                else -> R.drawable.ic_widget_cat
            }
            views.setImageViewResource(R.id.widget_cat_avatar, catDrawable)

            // Dynamic theme colors and drawables
            val (accentColor, chipBgRes) = when (themePalette) {
                "plum" -> Pair(0xFFD9B7ED.toInt(), R.drawable.widget_chip_accent_plum)
                "rose" -> Pair(0xFFF1B3C7.toInt(), R.drawable.widget_chip_accent_rose)
                "gold" -> Pair(0xFFE9CB81.toInt(), R.drawable.widget_chip_accent_gold)
                else -> Pair(0xFFB2D39C.toInt(), R.drawable.widget_chip_accent_forest)
            }

            views.setTextViewText(R.id.widget_pet_name, petName.uppercase())
            views.setTextViewText(R.id.widget_pet_level, "Nv. $petLevel")
            views.setTextColor(R.id.widget_pet_level, accentColor)
            views.setInt(R.id.widget_pet_level, "setBackgroundResource", chipBgRes)

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
            views.setInt(R.id.widget_habit_icon, "setColorFilter", accentColor)

            // Flags for PendingIntents
            val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            // Launch App PendingIntent
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
                setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("route", "habits")
            }
            val pendingLaunch = PendingIntent.getActivity(context, 0, launchIntent, pendingIntentFlags)
            views.setOnClickPendingIntent(R.id.widget_root, pendingLaunch)
            views.setOnClickPendingIntent(R.id.widget_cat_stage, pendingLaunch)
            views.setOnClickPendingIntent(R.id.widget_habits_container, pendingLaunch)

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
