package com.kwall.kwall

import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val WIDGET_CHANNEL = "com.kwall.kwall/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidgetData" -> {
                    val args = call.arguments as? Map<*, *>
                    if (args != null) {
                        val prefs = getSharedPreferences(KwallPetWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
                        val editor = prefs.edit()

                        (args["pet_name"] as? String)?.let { editor.putString(KwallPetWidgetProvider.KEY_PET_NAME, it) }
                        (args["pet_level"] as? Number)?.let { editor.putInt(KwallPetWidgetProvider.KEY_PET_LEVEL, it.toInt()) }
                        (args["pet_xp"] as? Number)?.let { editor.putInt(KwallPetWidgetProvider.KEY_PET_XP, it.toInt()) }
                        (args["pet_xp_in_level"] as? Number)?.let { editor.putInt(KwallPetWidgetProvider.KEY_PET_XP_IN_LEVEL, it.toInt()) }
                        (args["completed_habits"] as? Number)?.let { editor.putInt(KwallPetWidgetProvider.KEY_COMPLETED_HABITS, it.toInt()) }
                        (args["total_habits"] as? Number)?.let { editor.putInt(KwallPetWidgetProvider.KEY_TOTAL_HABITS, it.toInt()) }
                        (args["pending_habits"] as? Number)?.let { editor.putInt(KwallPetWidgetProvider.KEY_PENDING_HABITS, it.toInt()) }
                        (args["status_message"] as? String)?.let { editor.putString(KwallPetWidgetProvider.KEY_STATUS_MESSAGE, it) }
                        (args["pet_style"] as? String)?.let { editor.putString(KwallPetWidgetProvider.KEY_PET_STYLE, it) }
                        (args["theme_palette"] as? String)?.let { editor.putString(KwallPetWidgetProvider.KEY_THEME_PALETTE, it) }
                        (args["widget_bg_mode"] as? String)?.let { editor.putString(KwallPetWidgetProvider.KEY_WIDGET_BG_MODE, it) }
                        (args["widget_bg_color"] as? Number)?.let { editor.putInt(KwallPetWidgetProvider.KEY_WIDGET_BG_COLOR, it.toInt()) }

                        editor.apply()
                        KwallPetWidgetProvider.updateAllWidgets(applicationContext)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Arguments must be a map", null)
                    }
                }
                "getLaunchRoute" -> {
                    val route = intent?.getStringExtra("route")
                    intent?.removeExtra("route")
                    result.success(route)
                }
                "consumePendingAffection" -> {
                    result.success(0)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
