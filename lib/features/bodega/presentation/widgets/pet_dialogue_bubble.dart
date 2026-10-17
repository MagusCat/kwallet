import 'package:flutter/material.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../view_models/home_view_model.dart';

class PetDialogueBubble extends StatefulWidget {
  final HomeViewModel controller;
  final bool isPurring;
  final bool isAnnoyed;
  final VoidCallback? onTap;

  const PetDialogueBubble({
    super.key,
    required this.controller,
    this.isPurring = false,
    this.isAnnoyed = false,
    this.onTap,
  });

  @override
  State<PetDialogueBubble> createState() => _PetDialogueBubbleState();
}

class _PetDialogueBubbleState extends State<PetDialogueBubble> {
  int _manualCycleIndex = 0;

  static const _cycleIcons = [
    (Icons.favorite_rounded, Color(0xFFF43F5E)),
    (Icons.auto_awesome_rounded, Color(0xFFF59E0B)),
    (Icons.pets_rounded, Color(0xFF466539)),
    (Icons.music_note_rounded, Color(0xFF8B5CF6)),
    (Icons.savings_rounded, Color(0xFF10B981)),
  ];

  ({IconData icon, Color color}) _computeEmotion() {
    if (widget.isAnnoyed) {
      return (icon: Icons.close_rounded, color: const Color(0xFFEF4444));
    }

    if (widget.isPurring) {
      return (icon: Icons.favorite_rounded, color: const Color(0xFFF43F5E));
    }

    if (_manualCycleIndex > 0) {
      final item = _cycleIcons[(_manualCycleIndex - 1) % _cycleIcons.length];
      return (icon: item.$1, color: item.$2);
    }

    final controller = widget.controller;
    final hour = DateTime.now().hour;
    final allHabitsDone = controller.totalHabitsToday > 0 &&
        controller.pendingHabitsCount == 0;

    if (hour >= 22 || hour < 6) {
      return (icon: Icons.bedtime_rounded, color: const Color(0xFF818CF8));
    }

    if (controller.limit > 0 && controller.spent > controller.limit) {
      return (icon: Icons.priority_high_rounded, color: const Color(0xFFF97316));
    }

    if (allHabitsDone) {
      return (icon: Icons.auto_awesome_rounded, color: const Color(0xFFF59E0B));
    }

    if (hour >= 6 && hour < 12) {
      return (icon: Icons.wb_sunny_rounded, color: const Color(0xFFFBBF24));
    }

    if (controller.completedHabitsToday > 0) {
      return (icon: Icons.pets_rounded, color: KwallTheme.accent);
    }

    return (icon: Icons.music_note_rounded, color: const Color(0xFF10B981));
  }

  void _cycleEmotion() {
    setState(() {
      _manualCycleIndex++;
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final emotion = _computeEmotion();

    return Center(
      child: GestureDetector(
        onTap: _cycleEmotion,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: KwallTheme.surfaceContainer.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: emotion.color.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: emotion.color.withValues(alpha: 0.15),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                emotion.icon,
                size: 18,
                color: emotion.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
