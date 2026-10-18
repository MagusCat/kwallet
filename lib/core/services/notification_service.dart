import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static const MethodChannel _channel = MethodChannel('com.kwallet.raccon/notifications');

  static bool _isAllowed(String type, Map<String, String>? settings) {
    if (settings == null) return false;
    if (settings['notifications_enabled'] != 'true') return false;

    return switch (type) {
      'habits' => settings['notify_habits'] != 'false',
      'finances' => settings['notify_finances'] != 'false',
      'pet' => settings['notify_pet'] != 'false',
      'day_start' => settings['notify_day_start'] != 'false',
      'day_end' => settings['notify_day_end'] != 'false',
      _ => true,
    };
  }

  static Future<bool> areNotificationsEnabled() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final ok = await _channel.invokeMethod<bool>('areNotificationsEnabled');
      return ok ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> requestNotificationPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final ok = await _channel.invokeMethod<bool>('requestNotificationPermission');
      return ok ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> openUrl(String url) async {
    if (kIsWeb || !Platform.isAndroid) {
      if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
        try {
          if (Platform.isLinux) {
            await Process.run('xdg-open', [url]);
            return true;
          } else if (Platform.isMacOS) {
            await Process.run('open', [url]);
            return true;
          } else if (Platform.isWindows) {
            await Process.run('cmd', ['/c', 'start', '', url]);
            return true;
          }
        } catch (_) {}
      }
      return false;
    }
    try {
      final ok = await _channel.invokeMethod<bool>('openUrl', {'url': url});
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static String _resolveChannel(String type) => switch (type) {
        'finances' => 'kwall_finances',
        'pet' => 'kwall_pet',
        'day_start' || 'day_end' => 'kwall_habits',
        _ => 'kwall_habits',
      };

  static Future<bool> showNotification({
    required int id,
    required String title,
    required String body,
    String type = 'habits',
    Map<String, String>? settings,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (!_isAllowed(type, settings)) return false;

    try {
      final ok = await _channel.invokeMethod<bool>('showNotification', {
        'id': id,
        'title': title,
        'body': body,
        'channelId': _resolveChannel(type),
      });
      return ok ?? true;
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('Error triggering system notification: $e');
      return false;
    }
  }

  static Future<bool> showPetVisualNotification({
    required String petName,
    required String visualIcon,
    Map<String, String>? settings,
  }) {
    return showNotification(
      id: 2001,
      title: petName,
      body: visualIcon,
      type: 'pet',
      settings: settings,
    );
  }

  static Future<bool> showDayStartNotification({
    required String petName,
    Map<String, String>? settings,
  }) {
    final pet = petName.trim().isEmpty ? 'Tu compañero' : petName.trim();
    return showNotification(
      id: 3001,
      title: '¡Buen día! Empieza con $pet ☀️',
      body: 'Inicia tu día registrando tus hábitos y trazando tu presupuesto de hoy.',
      type: 'day_start',
      settings: settings,
    );
  }

  static Future<bool> showDayEndNotification({
    required String petName,
    Map<String, String>? settings,
  }) {
    final pet = petName.trim().isEmpty ? 'Tu compañero' : petName.trim();
    return showNotification(
      id: 3002,
      title: '¡Fin de la jornada! 🌙',
      body: '$pet está listo para descansar. Registra tus movimientos del día y cierra con tranquilidad.',
      type: 'day_end',
      settings: settings,
    );
  }

  static Future<bool> checkAndTriggerDailyFlow({
    required String petName,
    required Map<String, String> settings,
    required Future<void> Function(String key, String value) onSaveSetting,
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final enabled = settings['notifications_enabled'] == 'true';
    if (!enabled) return false;

    final todayStr = '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';

    final startTimeRaw = settings['day_start_time'] ?? '08:00';
    final startParts = startTimeRaw.split(':').map((s) => int.tryParse(s) ?? 0).toList();
    final startHour = startParts.isNotEmpty ? startParts[0] : 8;
    final startMinute = startParts.length > 1 ? startParts[1] : 0;
    final startMinutes = startHour * 60 + startMinute;

    final endTimeRaw = settings['day_end_time'] ?? '21:00';
    final endParts = endTimeRaw.split(':').map((s) => int.tryParse(s) ?? 0).toList();
    final endHour = endParts.isNotEmpty ? endParts[0] : 21;
    final endMinute = endParts.length > 1 ? endParts[1] : 0;
    final endMinutes = endHour * 60 + endMinute;

    final currentMinutes = current.hour * 60 + current.minute;

    final notifyStart = settings['notify_day_start'] != 'false';
    final notifyEnd = settings['notify_day_end'] != 'false';

    final lastStart = settings['last_day_start_notified'];
    final lastEnd = settings['last_day_end_notified'];

    // Day start window: at or after start time and before end time
    if (notifyStart && lastStart != todayStr && currentMinutes >= startMinutes && currentMinutes < endMinutes) {
      await onSaveSetting('last_day_start_notified', todayStr);
      return showDayStartNotification(petName: petName, settings: settings);
    }

    // Day end window: at or after end time (or early night hours before 4am)
    if (notifyEnd && lastEnd != todayStr && (currentMinutes >= endMinutes || current.hour < 4)) {
      await onSaveSetting('last_day_end_notified', todayStr);
      return showDayEndNotification(petName: petName, settings: settings);
    }

    return false;
  }
}
