import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../../../core/widgets/kitty_companion.dart';
import '../../view_models/home_view_model.dart';

class PetHeroCard extends StatefulWidget {
  final HomeViewModel controller;

  const PetHeroCard({super.key, required this.controller});

  @override
  State<PetHeroCard> createState() => _PetHeroCardState();
}

class _PetHeroCardState extends State<PetHeroCard> {
  Timer? _walkTimer;
  Timer? _petTimer;
  double _xPos = -0.3;
  bool _movingRight = true;
  PetActivity _currentActivity = PetActivity.walk;
  bool _isCelebrating = false;

  @override
  void initState() {
    super.initState();
    _startWalking();
  }

  void _startWalking() {
    _walkTimer?.cancel();
    _walkTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) return;
      setState(() {
        if (_movingRight) {
          _xPos += 0.09;
          if (_xPos >= 0.45) {
            _xPos = 0.45;
            _movingRight = false;
            _currentActivity = PetActivity.idle;
          } else {
            _currentActivity = PetActivity.walk;
          }
        } else {
          _xPos -= 0.09;
          if (_xPos <= -0.45) {
            _xPos = -0.45;
            _movingRight = true;
            _currentActivity = PetActivity.curious;
          } else {
            _currentActivity = PetActivity.walk;
          }
        }
      });
    });
  }

  void _onPet() {
    HapticFeedback.lightImpact();
    _petTimer?.cancel();
    setState(() {
      _isCelebrating = true;
    });
    _petTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _isCelebrating = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _walkTimer?.cancel();
    _petTimer?.cancel();
    super.dispose();
  }

  String _getContextualMessage() {
    final now = DateTime.now();
    if (now.hour >= 22 || now.hour < 6) {
      return 'Zzz... Hora de descansar y recargar energías 🌙';
    }
    final pendingHabits = widget.controller.pendingHabitsCount;
    final pendingTasks = widget.controller.pendingTasks.length;

    if (pendingHabits > 0) {
      return 'Tienes $pendingHabits ${pendingHabits == 1 ? "hábito pendiente" : "hábitos pendientes"} hoy 🐾';
    }
    if (pendingTasks > 0) {
      return 'Tienes $pendingTasks ${pendingTasks == 1 ? "tarea pendiente" : "tareas pendientes"} en tus listas 📝';
    }
    return '¡Todo al día y organizado! Sigue a tu propio ritmo ✨';
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final petName = controller.settings['pet_name'] ?? 'Mishi';
    final level = controller.xp ~/ 100 + 1;
    final xpInCurrentLevel = controller.xp % 100;
    final xpProgress = (xpInCurrentLevel / 100).clamp(0.0, 1.0);
    final now = DateTime.now();
    final isSleepingTime = now.hour >= 22 || now.hour < 6;

    final effectiveActivity = isSleepingTime
        ? PetActivity.sleep
        : (_isCelebrating ? PetActivity.celebrate : _currentActivity);

    return LedgerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Nombre estilizado y nivel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge de nombre súper estilizado (sin icono de tocar)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: KwallTheme.surfaceContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: KwallTheme.accent.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pets_rounded,
                      size: 14,
                      color: KwallTheme.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      petName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: KwallTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Chip de Nivel y XP
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: KwallTheme.accentLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: KwallTheme.accent,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Nv. $level',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: KwallTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Escenario animado donde la mascota camina libremente
          Container(
            height: 130,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  KwallTheme.surfaceContainer.withValues(alpha: 0.2),
                  KwallTheme.accentLight.withValues(alpha: 0.35),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: KwallTheme.border.withValues(alpha: 0.3),
              ),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Línea de suelo sutil
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 18,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: KwallTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Mascota caminando de lado a lado con animación fluida
                AnimatedAlign(
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeInOut,
                  alignment: Alignment(
                    isSleepingTime ? 0.0 : _xPos,
                    0.5,
                  ),
                  child: GestureDetector(
                    onTap: _onPet,
                    child: Transform.flip(
                      flipX: !_movingRight,
                      child: KittyCompanionWidget(
                        size: 92,
                        reward: controller.xp,
                        settings: controller.settings,
                        activity: effectiveActivity,
                        onPet: _onPet,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Burbuja de diálogo contextual de la mascota
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: KwallTheme.surfaceContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: KwallTheme.border.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 15,
                  color: KwallTheme.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getContextualMessage(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: KwallTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Barra de progreso XP hacia el siguiente nivel
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: xpProgress,
              minHeight: 6,
              backgroundColor: KwallTheme.border.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(KwallTheme.accent),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nv. $level',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: KwallTheme.accent,
                ),
              ),
              Text(
                '${100 - xpInCurrentLevel} XP para subir',
                style: TextStyle(
                  fontSize: 11,
                  color: KwallTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
