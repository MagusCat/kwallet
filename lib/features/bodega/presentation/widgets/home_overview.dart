import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../../../core/widgets/juice_widgets.dart';
import '../../../../core/widgets/kitty_companion.dart';
import '../../view_models/home_view_model.dart';

class HomeOverview extends StatefulWidget {
  final HomeViewModel controller;
  final ValueChanged<String> onTransaction;

  const HomeOverview({
    super.key,
    required this.controller,
    required this.onTransaction,
  });

  @override
  State<HomeOverview> createState() => _HomeOverviewState();
}

class _HomeOverviewState extends State<HomeOverview> {
  int _petPets = 0;
  String? _petReactionMessage;

  String _getContextualMessage() {
    if (_petReactionMessage != null) return _petReactionMessage!;
    final now = DateTime.now();
    if (now.hour >= 22 || now.hour < 6) {
      return 'Zzz... Hora de descansar y recargar energías 🌙';
    }
    final pendingHabits = widget.controller.pendingHabitsCount;
    final pendingTasks = widget.controller.pendingTasks.length;

    if (pendingHabits > 0) {
      return '¡Tienes $pendingHabits ${pendingHabits == 1 ? "hábito pendiente" : "hábitos pendientes"} hoy! 🐾';
    }
    if (pendingTasks > 0) {
      return 'Tienes $pendingTasks ${pendingTasks == 1 ? "tarea pendiente" : "tareas pendientes"} en tus listas 📝';
    }
    return '¡Todo en orden hoy! Sigue a tu propio ritmo ✨';
  }

  void _petCompanion() {
    HapticFeedback.selectionClick();
    setState(() {
      _petPets++;
      _petReactionMessage = [
        '¡Miau! Gracias por la caricia ❤️',
        '¡Sigue sumando hábitos y ganemos XP! 🐾',
        '¡Ronroneo de felicidad! ✨',
      ][_petPets % 3];
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final controller = widget.controller;
    final mirror = controller.settings['mirror_currency'] ?? '';
    final rate = double.tryParse(controller.settings['mirror_rate'] ?? '') ?? 0;
    final petName = controller.settings['pet_name'] ?? 'Mishi';
    final level = controller.xp ~/ 100 + 1;
    final xpInCurrentLevel = controller.xp % 100;
    final xpProgress = (xpInCurrentLevel / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Bienvenido',
                style: KwallTheme.fontTitle.copyWith(fontSize: 26),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: KwallTheme.accentLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: KwallTheme.accent,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Nv. $level · $xpInCurrentLevel/100',
                    style: TextStyle(
                      color: KwallTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ================= HERO CARD (Balance + Virtual Pet + Speech + XP) =================
        LedgerPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo total',
                          style: TextStyle(color: KwallTheme.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            KwallTheme.formatCurrency(
                              controller.balance,
                              controller.currency,
                            ),
                            style: KwallTheme.fontDisplay.copyWith(fontSize: 34),
                          ),
                        ),
                        if (mirror.isNotEmpty && rate > 0)
                          Text(
                            '≈ ${KwallTheme.formatCurrency(controller.balance * rate, mirror)}',
                            style: TextStyle(color: KwallTheme.textSecondary),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: KwallTheme.incomeGreen,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Libre ${KwallTheme.formatCurrency(controller.available, controller.currency)}',
                                style: TextStyle(
                                  color: KwallTheme.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Companion Virtual Pet
                  GestureDetector(
                    onTap: _petCompanion,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        KittyCompanionWidget(
                          size: 96,
                          reward: controller.xp,
                          settings: controller.settings,
                          activity: now.hour >= 22 || now.hour < 6
                              ? PetActivity.sleep
                              : (_petPets > 0
                                  ? PetActivity.celebrate
                                  : PetActivity.idle),
                          onPet: _petCompanion,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: KwallTheme.accentLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app_rounded,
                                size: 10,
                                color: KwallTheme.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                petName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: KwallTheme.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Speech bubble con sugerencias dinámicas de la mascota
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: KwallTheme.surfaceContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: KwallTheme.border.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 14,
                      color: KwallTheme.accent,
                    ),
                    const SizedBox(width: 8),
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
              // Nivel y barra de progreso XP
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
        ),
        const SizedBox(height: 16),

        CommitmentAlert(
          balance: controller.balance,
          committed: controller.committed,
          currency: controller.currency,
        ),

        // Quick Accounting buttons (Gasto, Ingreso, Transferir)
        Row(
          children: [
            Expanded(
              child: JuiceButton(
                icon: Icons.north_east_rounded,
                label: 'Gasto',
                filled: true,
                onPressed: () => widget.onTransaction('expense'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: JuiceButton(
                icon: Icons.south_west_rounded,
                label: 'Ingreso',
                onPressed: () => widget.onTransaction('income'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: JuiceButton(
                icon: Icons.swap_horiz_rounded,
                label: 'Transferir',
                onPressed: () => widget.onTransaction('transfer'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
