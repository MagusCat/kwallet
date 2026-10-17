import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static const MethodChannel _channel = MethodChannel('com.kwall.kwall/notifications');

  static bool _isAllowed(String type, Map<String, String>? settings) {
    if (settings == null) return true;
    if (settings['notifications_enabled'] == 'false') return false;

    return switch (type) {
      'habits' => settings['notify_habits'] != 'false',
      'finances' => settings['notify_finances'] != 'false',
      'pet' => settings['notify_pet'] != 'false',
      _ => true,
    };
  }

  static String _resolveChannel(String type) => switch (type) {
        'finances' => 'kwall_finances',
        'pet' => 'kwall_pet',
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
}
