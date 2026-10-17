import 'package:flutter/material.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../view_models/home_view_model.dart';

/// Burbuja de diálogo contextual e interactiva para la mascota de Kwall.
/// Responde a la hora del día, hábitos completados, presupuesto y cariño.
class PetDialogueBubble extends StatefulWidget {
  final HomeViewModel controller;
  final bool isPurring;
  final VoidCallback? onTap;

  const PetDialogueBubble({
    super.key,
    required this.controller,
    this.isPurring = false,
    this.onTap,
  });

  @override
  State<PetDialogueBubble> createState() => _PetDialogueBubbleState();
}

class _PetDialogueBubbleState extends State<PetDialogueBubble> {
  int _manualCycleIndex = 0;

  static const _playfulQuotes = [
    '¡Cada hábito cumplido me da energía! 🐾',
    '¡Prrr... estoy atento a tus progresos! ✨',
    '¡Cuidemos cada monedita juntos! 🪙',
    'Un paso a la vez, hoy también cuenta 🌱',
    '¡Vamos por ese siguiente nivel! 🚀',
  ];

  String _computeContextualMessage() {
    if (widget.isPurring) {
      return '¡Prrr... gracias por el cariño! 💖';
    }

    if (_manualCycleIndex > 0) {
      return _playfulQuotes[(_manualCycleIndex - 1) % _playfulQuotes.length];
    }

    final controller = widget.controller;
    final now = DateTime.now();
    final hour = now.hour;
    final allHabitsDone = controller.totalHabitsToday > 0 &&
        controller.pendingHabitsCount == 0;
    final completedHabits = controller.completedHabitsToday;

    // Horario nocturno de descanso
    if (hour >= 22 || hour < 6) {
      return 'Zzz... A descansar, mañana será un gran día 🌙';
    }

    // Alerta de presupuesto
    if (controller.limit > 0 && controller.spent > controller.limit) {
      return 'Ojo con el límite de gastos, cuidemos el bolsillo 🐾';
    }

    // Todos los hábitos completados
    if (allHabitsDone) {
      return '¡Todos los hábitos listos! Eres increíble 🎉';
    }

    // Mañana
    if (hour >= 6 && hour < 12) {
      if (completedHabits > 0) {
        return '¡Arrancaste la mañana con todo! ✨';
      }
      return '¡Buenos días! ¿Qué metas cumplimos hoy? ☀️';
    }

    // Tarde
    if (hour >= 12 && hour < 19) {
      if (completedHabits > 0) {
        return '¡Buen ritmo! Sigamos sumando hábitos 🐾';
      }
      return 'Buena tarde para avanzar tus hábitos pendientes 🌱';
    }

    // Noche temprana
    if (controller.pendingHabitsCount > 0) {
      return 'Aún queda tiempo para completar el día 🕯️';
    }
    return '¡Gran jornada hoy! Buen trabajo 🌟';
  }

  void _cycleDialogue() {
    setState(() {
      _manualCycleIndex++;
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final message = _computeContextualMessage();

    return GestureDetector(
      onTap: _cycleDialogue,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: KwallTheme.surfaceContainer.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: KwallTheme.accent.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 13,
              color: KwallTheme.accent,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: KwallTheme.textPrimary,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
