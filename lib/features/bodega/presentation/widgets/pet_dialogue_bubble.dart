import 'package:flutter/material.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../view_models/home_view_model.dart';

/// Burbuja de expresión visual para la mascota de Kwall.
/// No utiliza textos ni iconos emoji; se comunica exclusivamente con caritas felinas y gestos.
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

  static const _playfulFaces = [
    '(=^･ω･^=)',
    '(=^-ω-^=)',
    '(=^‥^=)',
    '(=`･ω･´=)',
    '( =①ω①= )',
    '(=^･ｪ･^=)',
  ];

  String _computeContextualExpression() {
    if (widget.isPurring) {
      return '(=^-ω-^=) ♡';
    }

    if (_manualCycleIndex > 0) {
      return _playfulFaces[(_manualCycleIndex - 1) % _playfulFaces.length];
    }

    final controller = widget.controller;
    final now = DateTime.now();
    final hour = now.hour;
    final allHabitsDone = controller.totalHabitsToday > 0 &&
        controller.pendingHabitsCount == 0;
    final completedHabits = controller.completedHabitsToday;

    // Horario nocturno de descanso
    if (hour >= 22 || hour < 6) {
      return '(=-ω-=) zZ';
    }

    // Alerta de presupuesto
    if (controller.limit > 0 && controller.spent > controller.limit) {
      return '( =①ω①= ) !';
    }

    // Todos los hábitos completados
    if (allHabitsDone) {
      return '(=^o^=) /';
    }

    // Mañana
    if (hour >= 6 && hour < 12) {
      if (completedHabits > 0) {
        return '(=`･ω･´=)';
      }
      return '(=^‥^=)';
    }

    // Tarde
    if (hour >= 12 && hour < 19) {
      if (completedHabits > 0) {
        return '(=^･ω･^=)';
      }
      return '(=^･ｪ･^=)';
    }

    // Noche temprana
    if (controller.pendingHabitsCount > 0) {
      return '(=^･_･^=)';
    }
    return '(=^-ω-^=)';
  }

  void _cycleFace() {
    setState(() {
      _manualCycleIndex++;
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final face = _computeContextualExpression();

    return Center(
      child: GestureDetector(
        onTap: _cycleFace,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: KwallTheme.surfaceContainer.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: KwallTheme.accent.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            face,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              letterSpacing: 0.8,
              color: KwallTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
