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

class _PetHeroCardState extends State<PetHeroCard> with SingleTickerProviderStateMixin {
  Timer? _walkTimer;
  Timer? _resumeWalkTimer;
  Timer? _affectionTimer;
  double _xPos = -0.3;
  bool _movingRight = true;
  PetActivity _currentActivity = PetActivity.walk;
  bool _isCelebrating = false;
  bool _isGrabbed = false;
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
    _startWalking();
  }

  void _startWalking() {
    _walkTimer?.cancel();
    _walkTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted || _isGrabbed) return;
      setState(() {
        if (_movingRight) {
          _xPos += 0.08;
          if (_xPos >= 0.45) {
            _xPos = 0.45;
            _movingRight = false;
            _currentActivity = PetActivity.curious;
          } else {
            _currentActivity = PetActivity.walk;
          }
        } else {
          _xPos -= 0.08;
          if (_xPos <= -0.45) {
            _xPos = -0.45;
            _movingRight = true;
            _currentActivity = PetActivity.idle;
          } else {
            _currentActivity = PetActivity.walk;
          }
        }
      });
    });
  }

  void _giveAffection() {
    HapticFeedback.lightImpact();
    _affectionTimer?.cancel();

    // Generate floating hearts around cat position
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
    final messages = [
      'Purrr... A $petName le encantan tus caricias y mimos.',
      '$petName ronronea feliz a tu lado. Te tiene mucho aprecio.',
      '¡Le diste cariño a tu mascota! Se siente llena de energía.',
    ];

    setState(() {
      _isCelebrating = true;
      _customAffectionMessage = messages[random.nextInt(messages.length)];
    });

    widget.controller.petCompanion(2);

    _affectionTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() {
          _isCelebrating = false;
          _customAffectionMessage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _walkTimer?.cancel();
    _resumeWalkTimer?.cancel();
    _affectionTimer?.cancel();
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
        : (isSleepingTime
            ? PetActivity.sleep
            : (_isCelebrating ? PetActivity.celebrate : _currentActivity));

    return LedgerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Nombre estilizado, boton de carino y nivel
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

          // Escenario animado interactivo: caminar, agarrar, soltar y acariciar
          LayoutBuilder(
            builder: (context, constraints) {
              final stageWidth = constraints.maxWidth;
              return Container(
                height: 140,
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
                    // Botón de dar cariño ubicado en la esquina superior del escenario
                    Positioned(
                      top: 10,
                      right: 12,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _giveAffection,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: KwallTheme.surfaceContainer.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: KwallTheme.accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.favorite_rounded,
                                size: 12,
                                color: KwallTheme.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Mimar',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: KwallTheme.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

                    // Sombra dinámica bajo la mascota (se reduce cuando se levanta al agarrarla)
                    AnimatedAlign(
                      duration: _isGrabbed ? Duration.zero : const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(isSleepingTime ? 0.0 : _xPos, 0.78),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: _isGrabbed ? 32 : 54,
                        height: _isGrabbed ? 4 : 8,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: _isGrabbed ? 0.12 : 0.28),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Mascota interactiva: se puede agarrar, mover y soltar libremente
                    AnimatedAlign(
                      duration: _isGrabbed ? Duration.zero : const Duration(milliseconds: 400),
                      curve: _isGrabbed ? Curves.linear : Curves.bounceOut,
                      alignment: Alignment(
                        isSleepingTime ? 0.0 : _xPos,
                        _isGrabbed ? 0.15 : 0.55,
                      ),
                      child: GestureDetector(
                        onTap: _giveAffection,
                        onPanStart: (details) {
                          HapticFeedback.mediumImpact();
                          _walkTimer?.cancel();
                          _resumeWalkTimer?.cancel();
                          setState(() {
                            _isGrabbed = true;
                          });
                        },
                        onPanUpdate: (details) {
                          if (stageWidth <= 0) return;
                          final deltaFactor = (details.delta.dx / (stageWidth * 0.5));
                          setState(() {
                            _xPos = (_xPos + deltaFactor).clamp(-0.55, 0.55);
                            if (details.delta.dx > 0.4) _movingRight = true;
                            if (details.delta.dx < -0.4) _movingRight = false;
                          });
                        },
                        onPanEnd: (details) {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _isGrabbed = false;
                          });
                          // Reanudar caminata tras breve pausa
                          _resumeWalkTimer = Timer(const Duration(milliseconds: 1000), () {
                            if (mounted) _startWalking();
                          });
                        },
                        onPanCancel: () {
                          setState(() {
                            _isGrabbed = false;
                          });
                          _startWalking();
                        },
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 160),
                          scale: _isGrabbed ? 1.08 : 1.0,
                          child: Transform.flip(
                            flipX: !_movingRight,
                            child: KittyCompanionWidget(
                              size: 92,
                              reward: controller.xp,
                              settings: controller.settings,
                              activity: effectiveActivity,
                              onPet: _giveAffection,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Partículas de corazón flotantes al darle cariño
                    if (_heartAnim.isAnimating && _hearts.isNotEmpty)
                      AnimatedAlign(
                        duration: Duration.zero,
                        alignment: Alignment(isSleepingTime ? 0.0 : _xPos, 0.4),
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

          // Burbuja de diálogo contextual de la mascota (sin emojis)
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
