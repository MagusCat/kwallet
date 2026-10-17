import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/kwall_theme.dart';

class JuiceButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  const JuiceButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.filled = false,
  });
  @override
  State<JuiceButton> createState() => _JuiceButtonState();
}

class _JuiceButtonState extends State<JuiceButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final color = widget.filled ? KwallTheme.onAccent : KwallTheme.accent;
    return AnimatedScale(
      scale: _pressed && !reduced ? .95 : 1,
      duration: Duration(milliseconds: reduced ? 0 : 110),
      curve: Curves.easeOutCubic,
      child: Material(
        color: widget.filled ? KwallTheme.accent : KwallTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: KwallTheme.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onHighlightChanged: (value) => setState(() => _pressed = value),
          onTap: widget.onPressed == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  widget.onPressed!();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: color, size: 26),
                const SizedBox(height: 7),
                Text(
                  widget.label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CircularMeter extends StatelessWidget {
  final double value;
  final IconData icon;
  final Color? color;
  final double size;
  const CircularMeter({
    super.key,
    required this.value,
    required this.icon,
    this.color,
    this.size = 64,
  });
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    widthFactor: 1,
    heightFactor: 1,
    child: SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: Duration(
          milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 450,
        ),
        curve: Curves.easeOutCubic,
        builder: (_, amount, child) => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: amount,
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                color: color ?? KwallTheme.accent,
                backgroundColor: KwallTheme.surfaceContainer,
              ),
            ),
            Icon(icon, color: color ?? KwallTheme.accent, size: size * .38),
          ],
        ),
      ),
    ),
  );
}
