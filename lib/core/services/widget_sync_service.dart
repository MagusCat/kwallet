import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Servicio de sincronización entre Flutter y el Widget nativo de Android.
class WidgetSyncService {
  static const MethodChannel _channel = MethodChannel('com.kwall.kwall/widget');

  /// Sincroniza el estado de la mascota y los hábitos con el widget de Android.
  static Future<bool> syncWidget({
    required String petName,
    required int xp,
    required int completedHabits,
    required int totalHabits,
    required int pendingHabits,
    String? statusMessage,
    String? petStyle,
    String? themePalette,
  }) async {
    // Solo se ejecuta en Android real / emulador
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
        'status_message': ?statusMessage,
        'pet_style': petStyle ?? 'classic',
        'theme_palette': themePalette ?? 'forest',
      });
      return result ?? true;
    } on MissingPluginException {
      // Ignorar en pruebas unitarias o entornos sin el handler nativo montado
      return false;
    } catch (e) {
      debugPrint('No se pudo sincronizar el widget de Android: $e');
      return false;
    }
  }

  /// Consulta si la app fue abierta desde el widget de Android solicitando una ruta específica.
  static Future<String?> getLaunchRoute() async {
    if (kIsWeb || !Platform.isAndroid) {
      return null;
    }
    try {
      return await _channel.invokeMethod<String>('getLaunchRoute');
    } on MissingPluginException {
      return null;
    } catch (e) {
      debugPrint('Error al consultar ruta de inicio del widget: $e');
      return null;
    }
  }

  /// Consulta y consume los puntos de carino acumulados en el widget de Android.
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
