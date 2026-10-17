import 'dart:async';
import 'dart:math' as math;
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

class _PetHeroCardState extends State<PetHeroCard>
    with SingleTickerProviderStateMixin {
  Timer? _roamTimer;
  Timer? _walkStepTimer;
  Timer? _resumeRoamTimer;
  Timer? _affectionTimer;
  Timer? _annoyedTimer;

  double _xPos = 0.0;
  double _yPos = 0.55; // 0.55 is ground level
  double _targetX = 0.0;
  bool _movingRight = true;
  PetActivity _currentActivity = PetActivity.idle;
  bool _isCelebrating = false;
  bool _isGrabbed = false;
  bool _isAnnoyed = false;
  String? _customAffectionMessage;

  // Floating hearts for affection
  late final AnimationController _heartAnim;
  final List<({double x, double delay, double scale, Color color})> _hearts = [];

  @override
  void initState() {
    super.initState();
    _heartAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(() {
        if (mounted) setState(() {});
      });
    _scheduleNextRoam();
  }

  void _scheduleNextRoam() {
    _roamTimer?.cancel();
    _walkStepTimer?.cancel();
    if (!mounted || _isGrabbed || _isAnnoyed || _isCelebrating) return;

    final random = math.Random();
    final delay = 3500 + random.nextInt(3500);

    _roamTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted || _isGrabbed || _isAnnoyed || _isCelebrating) return;

      final now = DateTime.now();
      if (now.hour >= 22 || now.hour < 6) {
        setState(() {
          _currentActivity = PetActivity.sleep;
        });
        _scheduleNextRoam();
        return;
      }

      // Pick next activity: walk, idle, curious (play), sleep, relax
      final choice = random.nextDouble();
      if (choice < 0.45) {
        // Walk across the area
        _startAutonomousWalk();
      } else if (choice < 0.70) {
        // Curious / Play
        setState(() {
          _currentActivity = PetActivity.curious;
        });
        _scheduleNextRoam();
      } else if (choice < 0.88) {
        // Relax / rest
        setState(() {
          _currentActivity = PetActivity.relax;
        });
        _scheduleNextRoam();
      } else {
        // Sit idle
        setState(() {
          _currentActivity = PetActivity.idle;
        });
        _scheduleNextRoam();
      }
    });
  }

  void _startAutonomousWalk() {
    final random = math.Random();
    _targetX = (random.nextDouble() * 1.2) - 0.6; // between -0.6 and 0.6
    final movingRight = _targetX > _xPos;

    setState(() {
      _currentActivity = PetActivity.walk;
      _movingRight = movingRight;
    });

    _walkStepTimer?.cancel();
    _walkStepTimer = Timer.periodic(const Duration(milliseconds: 180), (timer) {
      if (!mounted || _isGrabbed || _isAnnoyed || _isCelebrating) {
        timer.cancel();
        return;
      }

      final diff = _targetX - _xPos;
      if (diff.abs() < 0.05) {
        timer.cancel();
        setState(() {
          _xPos = _targetX;
          _currentActivity = random.nextBool() ? PetActivity.idle : PetActivity.curious;
        });
        _scheduleNextRoam();
      } else {
        final step = diff > 0 ? 0.04 : -0.04;
        setState(() {
          _xPos = (_xPos + step).clamp(-0.65, 0.65);
        });
      }
    });
  }

  Future<void> _giveAffection() async {
    HapticFeedback.lightImpact();
    _affectionTimer?.cancel();
    _annoyedTimer?.cancel();

    // Floating hearts
    _hearts.clear();
    final random = math.Random();
    final colors = [
      const Color(0xFFF1B3C7),
      const Color(0xFFFFA726),
      const Color(0xFFFFCC80),
      const Color(0xFFE57373),
    ];
    for (int i = 0; i < 5; i++) {
      _hearts.add((
        x: (random.nextDouble() - 0.5) * 60,
        delay: i * 0.12,
        scale: 0.7 + random.nextDouble() * 0.5,
        color: colors[i % colors.length],
      ));
    }
    _heartAnim.forward(from: 0.0);

    final petName = widget.controller.settings['pet_name'] ?? 'Mishi';
    final awarded = await widget.controller.petCompanion(2);

    final messagesEarned = [
      '¡Miau! A $petName le encantan tus mimos (+2 XP)',
      'Purrr... $petName ronronea muy feliz a tu lado (+2 XP)',
      '¡Le diste cariño a $petName! Energía al máximo (+2 XP)',
    ];

    final messagesAlreadyClaimed = [
      'Purrr... A $petName le gustan tus caricias. (Mimos de hoy completados)',
      '$petName ronronea contento a tu lado. (Vuelve mañana por más XP)',
      'A $petName le agrada mucho tu compañía hoy.',
    ];

    setState(() {
      _isCelebrating = true;
      _isAnnoyed = false;
      _customAffectionMessage = awarded
          ? messagesEarned[random.nextInt(messagesEarned.length)]
          : messagesAlreadyClaimed[random.nextInt(messagesAlreadyClaimed.length)];
    });

    _affectionTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() {
          _isCelebrating = false;
          _customAffectionMessage = null;
        });
        _scheduleNextRoam();
      }
    });
  }

  void _handlePetDropped(bool wasMoved) {
    HapticFeedback.mediumImpact();
    _roamTimer?.cancel();
    _walkStepTimer?.cancel();
    _resumeRoamTimer?.cancel();
    _annoyedTimer?.cancel();

    setState(() {
      _isGrabbed = false;
      _yPos = 0.55; // return to ground level
      if (wasMoved) {
        _isAnnoyed = true;
        _isCelebrating = false;
        final petName = widget.controller.settings['pet_name'] ?? 'Mishi';
        final annoyedMessages = [
          '¡Miau! No sueltes a $petName así de golpe...',
          '¿Por qué tiras a $petName? ¡Bájame con cuidado!',
          '¡Hmph! A un gato se le baja con delicadeza.',
          '¡Oye! Casi caigo de panza. Ten más cuidado.',
        ];
        final random = math.Random();
        _customAffectionMessage =
            annoyedMessages[random.nextInt(annoyedMessages.length)];
      }
    });

    _annoyedTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _isAnnoyed = false;
          _customAffectionMessage = null;
        });
        _scheduleNextRoam();
      }
    });
  }

  @override
  void dispose() {
    _roamTimer?.cancel();
    _walkStepTimer?.cancel();
    _resumeRoamTimer?.cancel();
    _affectionTimer?.cancel();
    _annoyedTimer?.cancel();
    _heartAnim.dispose();
    super.dispose();
  }

  String _getContextualMessage() {
    if (_customAffectionMessage != null) {
      return _customAffectionMessage!;
    }
    final now = DateTime.now();
    if (now.hour >= 22 || now.hour < 6) {
      return 'Zzz... Hora de descansar y recargar energías.';
    }
    final pendingHabits = widget.controller.pendingHabitsCount;
    final pendingTasks = widget.controller.pendingTasks.length;

    if (pendingHabits > 0) {
      return 'Tienes $pendingHabits ${pendingHabits == 1 ? "hábito pendiente" : "hábitos pendientes"} hoy.';
    }
    if (pendingTasks > 0) {
      return 'Tienes $pendingTasks ${pendingTasks == 1 ? "tarea pendiente" : "tareas pendientes"} en tus listas.';
    }
    return '¡Todo al día y organizado! Sigue a tu propio ritmo.';
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

    final effectiveActivity = _isGrabbed
        ? PetActivity.grabbed
        : (_isCelebrating
            ? PetActivity.celebrate
            : (_isAnnoyed
                ? PetActivity.curious
                : (isSleepingTime ? PetActivity.sleep : _currentActivity)));

    // Shadow dynamics: shrink and fade when lifted above ground
    final liftRatio = ((0.55 - _yPos) / 1.1).clamp(0.0, 1.0);
    final shadowWidth = 54.0 - (liftRatio * 28.0);
    final shadowHeight = 8.0 - (liftRatio * 4.0);
    final shadowOpacity = (0.28 - (liftRatio * 0.18)).clamp(0.06, 0.28);

    return LedgerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Nombre estilizado de la mascota y chip de nivel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge de nombre
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    const SizedBox(width: 7),
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

              // Chip de Nivel
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Nv. $level',
                      style: TextStyle(
                        fontSize: 11,
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

          // Escenario interactivo: caminar, agarrar 2D, mover fluido y soltar
          LayoutBuilder(
            builder: (context, constraints) {
              final stageWidth = constraints.maxWidth;
              const stageHeight = 140.0;
              return Container(
                height: stageHeight,
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
                  clipBehavior: Clip.none,
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

                    // Sombra dinámica bajo la mascota (refleja posición X e intensidad de elevación)
                    AnimatedAlign(
                      duration: _isGrabbed
                          ? Duration.zero
                          : const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(_xPos, 0.78),
                      child: Container(
                        width: shadowWidth,
                        height: shadowHeight,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: shadowOpacity),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Mascota interactiva: movimiento 2D fluido, reacción al soltar y mimos
                    AnimatedAlign(
                      duration: _isGrabbed
                          ? Duration.zero
                          : const Duration(milliseconds: 450),
                      curve: _isGrabbed ? Curves.linear : Curves.bounceOut,
                      alignment: Alignment(_xPos, _yPos),
                      child: GestureDetector(
                        onTap: _giveAffection,
                        onPanStart: (details) {
                          HapticFeedback.lightImpact();
                          _roamTimer?.cancel();
                          _walkStepTimer?.cancel();
                          _resumeRoamTimer?.cancel();
                          _annoyedTimer?.cancel();
                          setState(() {
                            _isGrabbed = true;
                            _isAnnoyed = false;
                          });
                        },
                        onPanUpdate: (details) {
                          if (stageWidth <= 0) return;
                          final dx = details.delta.dx / (stageWidth * 0.45);
                          final dy = details.delta.dy / 60.0;
                          setState(() {
                            _xPos = (_xPos + dx).clamp(-0.72, 0.72);
                            _yPos = (_yPos + dy).clamp(-0.65, 0.55);
                            if (details.delta.dx > 0.3) _movingRight = true;
                            if (details.delta.dx < -0.3) _movingRight = false;
                          });
                        },
                        onPanEnd: (details) {
                          final wasLifted = _yPos < 0.35 || details.velocity.pixelsPerSecond.distance > 80;
                          _handlePetDropped(wasLifted);
                        },
                        onPanCancel: () {
                          _handlePetDropped(false);
                        },
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 160),
                          scale: _isGrabbed ? 1.10 : 1.0,
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              Transform.flip(
                                flipX: !_movingRight,
                                child: KittyCompanionWidget(
                                  size: 92,
                                  reward: controller.xp,
                                  settings: controller.settings,
                                  activity: effectiveActivity,
                                  onPet: _giveAffection,
                                ),
                              ),

                              // Indicador de enojo al ser soltado bruscamente (sin emojis)
                              if (_isAnnoyed)
                                Positioned(
                                  top: -8,
                                  right: _movingRight ? -6 : null,
                                  left: _movingRight ? null : -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: KwallTheme.expenseRed.withValues(alpha: 0.9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.priority_high_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Partículas de corazón flotantes al darle cariño
                    if (_heartAnim.isAnimating && _hearts.isNotEmpty)
                      AnimatedAlign(
                        duration: Duration.zero,
                        alignment: Alignment(_xPos, _yPos - 0.2),
                        child: SizedBox(
                          width: 100,
                          height: 120,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              for (final h in _hearts)
                                Builder(
                                  builder: (context) {
                                    final t = (_heartAnim.value - h.delay).clamp(0.0, 1.0);
                                    if (t <= 0.0) return const SizedBox.shrink();
                                    final yProgress = Curves.easeOutCubic.transform(t);
                                    final opacity = (1.0 - t).clamp(0.0, 1.0);
                                    return Positioned(
                                      bottom: yProgress * 65 + 30,
                                      left: 50 + h.x - 10,
                                      child: Opacity(
                                        opacity: opacity,
                                        child: Transform.scale(
                                          scale: h.scale * (0.8 + 0.4 * yProgress),
                                          child: Icon(
                                            Icons.favorite_rounded,
                                            size: 18,
                                            color: h.color,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Diálogo contextual de la mascota (sin emojis)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: KwallTheme.surfaceContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isAnnoyed
                    ? KwallTheme.expenseRed.withValues(alpha: 0.4)
                    : KwallTheme.border.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isAnnoyed
                      ? Icons.announcement_rounded
                      : Icons.chat_bubble_outline_rounded,
                  size: 15,
                  color: _isAnnoyed ? KwallTheme.expenseRed : KwallTheme.accent,
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
