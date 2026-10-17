import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WidgetSyncService {
  static const MethodChannel _channel = MethodChannel('com.kwall.kwall/widget');

  static Future<bool> syncWidget({
    required String petName,
    required int xp,
    required int completedHabits,
    required int totalHabits,
    required int pendingHabits,
    String? statusMessage,
    String? petStyle,
    String? themePalette,
    String? widgetBgMode,
    int? widgetBgColor,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }

    try {
      final level = xp ~/ 100 + 1;
      final xpInLevel = xp % 100;

      final result = await _channel.invokeMethod<bool>('updateWidgetData', {
        'pet_name': petName,
        'pet_level': level,
        'pet_xp': xp,
        'pet_xp_in_level': xpInLevel,
        'completed_habits': completedHabits,
        'total_habits': totalHabits,
        'pending_habits': pendingHabits,
        'status_message': statusMessage,
        'pet_style': petStyle ?? 'classic',
        'theme_palette': themePalette ?? 'forest',
        'widget_bg_mode': widgetBgMode ?? 'default',
        'widget_bg_color': ?widgetBgColor,
      });
      return result ?? true;
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('Widget sync failed: $e');
      return false;
    }
  }

  static Future<String?> getLaunchRoute() async {
    if (kIsWeb || !Platform.isAndroid) {
      return null;
    }
    try {
      return await _channel.invokeMethod<String>('getLaunchRoute');
    } on MissingPluginException {
      return null;
    } catch (e) {
      debugPrint('Widget launch route failed: $e');
      return null;
    }
  }

  static Future<int> consumePendingAffection() async {
    if (kIsWeb || !Platform.isAndroid) {
      return 0;
    }
    try {
      final points = await _channel.invokeMethod<int>('consumePendingAffection');
      return points ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
