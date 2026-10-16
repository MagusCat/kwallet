import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/kwall_theme.dart';

enum KittyMoodState {
  happy,
  zen,
  alert,
  boss,
  sleepy,
}

class KittyCompanionWidget extends StatefulWidget {
  final KittyMoodState mood;
  final double size;
  final VoidCallback? onPet;
  final String? customDialogue;

  const KittyCompanionWidget({
    super.key,
    this.mood = KittyMoodState.happy,
    this.size = 130,
    this.onPet,
    this.customDialogue,
  });

  @override
  State<KittyCompanionWidget> createState() => _KittyCompanionWidgetState();
}

class _KittyCompanionWidgetState extends State<KittyCompanionWidget>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _blinkController;
  late AnimationController _petBounceController;

  bool _isPetting = false;
  String? _temporarySpeech;

  @override
  void initState() {
    super.initState();

    // Subtle breathing & tail wagging
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Periodic blinking
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Bouncing on pet
    _petBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _idleController.dispose();
    _blinkController.dispose();
    _petBounceController.dispose();
    super.dispose();
  }

  void _handlePet() {
    setState(() {
      _isPetting = true;
      final speeches = [
        '*PURR*',
        'MEOW! +5 EXP',
        'RONRONEO INTENSO',
        '¡BUEN GATO!',
        '¡BÓVEDA PROTEGIDA!'
      ];
      _temporarySpeech = speeches[math.Random().nextInt(speeches.length)];
    });

    _petBounceController.forward(from: 0.0);
    widget.onPet?.call();

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _isPetting = false;
          _temporarySpeech = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final speechText = _temporarySpeech ?? widget.customDialogue;

    return GestureDetector(
      onTap: _handlePet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speech Bubble HUD
          if (speechText != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: KwallTheme.surfaceCardHighlight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isPetting ? KwallTheme.neonGreen : KwallTheme.borderBright,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isPetting ? KwallTheme.neonGreen : Colors.black)
                        .withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isPetting)
                    const Icon(
                      Icons.favorite_rounded,
                      size: 13,
                      color: KwallTheme.plasmaPink,
                    ),
                  if (_isPetting) const SizedBox(width: 4),
                  Text(
                    speechText,
                    style: KwallTheme.gameFont.copyWith(
                      color: _isPetting ? KwallTheme.neonGreen : KwallTheme.textBright,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ).animate().scale(duration: 180.ms, curve: Curves.easeOutBack),

          // Vector Kitty Companion Canvas
          AnimatedBuilder(
            animation: Listenable.merge([
              _idleController,
              _blinkController,
              _petBounceController,
            ]),
            builder: (context, child) {
              final idleProgress = _idleController.value;
              final blinkProgress = _blinkController.value;
              final bounceProgress = _petBounceController.value;

              // Hop when pet
              final bounceOffset = math.sin(bounceProgress * math.pi) * -8;

              return Transform.translate(
                offset: Offset(0, bounceOffset),
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: _KittyPainter(
                      mood: widget.mood,
                      idleProgress: idleProgress,
                      blinkProgress: blinkProgress,
                      isPetting: _isPetting,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _KittyPainter extends CustomPainter {
  final KittyMoodState mood;
  final double idleProgress; // 0.0 to 1.0 (breathing)
  final double blinkProgress; // 0.0 to 1.0 (blinking)
  final bool isPetting;

  _KittyPainter({
    required this.mood,
    required this.idleProgress,
    required this.blinkProgress,
    required this.isPetting,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    final breathe = math.sin(idleProgress * math.pi) * 2.0;

    // Paints
    final bodyPaint = Paint()
      ..color = const Color(0xFF1E2433)
      ..style = PaintingStyle.fill;

    final bodyHighlight = Paint()
      ..color = const Color(0xFF2C354B)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = const Color(0xFF0F121C)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final earInnerPaint = Paint()
      ..color = isPetting ? const Color(0xFFFF70A6) : const Color(0xFF3E4866)
      ..style = PaintingStyle.fill;

    final eyeGlowPaint = Paint()
      ..color = _getEyeColor()
      ..style = PaintingStyle.fill;

    final darkEyePaint = Paint()
      ..color = const Color(0xFF0A0C14)
      ..style = PaintingStyle.fill;

    // 1. Draw Tail (Curved Animated Bezier)
    final tailPath = Path();
    final tailWag = math.sin(idleProgress * 2 * math.pi) * (isPetting ? 14 : 7);
    tailPath.moveTo(w * 0.72, h * 0.78);
    tailPath.cubicTo(
      w * 0.88 + tailWag,
      h * 0.75,
      w * 0.95 + tailWag * 1.3,
      h * 0.50,
      w * 0.85 + tailWag,
      h * 0.40,
    );

    final tailOutline = Paint()
      ..color = const Color(0xFF0F121C)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final tailFill = Paint()
      ..color = const Color(0xFF1E2433)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(tailPath, tailOutline);
    canvas.drawPath(tailPath, tailFill);

    // 2. Draw Body
    final bodyRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + 14 + breathe * 0.5),
      width: w * 0.62,
      height: h * 0.44,
    );
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.22));
    canvas.drawRRect(bodyRRect, bodyPaint);
    canvas.drawRRect(bodyRRect, outlinePaint);

    // Belly patch
    final bellyRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + 18 + breathe * 0.5),
      width: w * 0.38,
      height: h * 0.28,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bellyRect, Radius.circular(w * 0.14)),
      bodyHighlight,
    );

    // 3. Draw Left & Right Ears (Sharp Geometric Cat Ears)
    final earTwitch = isPetting ? 3.0 : (mood == KittyMoodState.alert ? 2.0 : 0.0);

    // Left Ear
    final leftEarPath = Path()
      ..moveTo(w * 0.24, center.dy - 6 + breathe)
      ..lineTo(w * 0.20 - earTwitch, h * 0.14 - breathe * 0.5)
      ..lineTo(w * 0.42, center.dy - 12 + breathe)
      ..close();
    canvas.drawPath(leftEarPath, bodyPaint);
    canvas.drawPath(leftEarPath, outlinePaint);

    final leftEarInner = Path()
      ..moveTo(w * 0.26, center.dy - 6 + breathe)
      ..lineTo(w * 0.23 - earTwitch, h * 0.20 - breathe * 0.5)
      ..lineTo(w * 0.38, center.dy - 10 + breathe)
      ..close();
    canvas.drawPath(leftEarInner, earInnerPaint);

    // Right Ear
    final rightEarPath = Path()
      ..moveTo(w * 0.58, center.dy - 12 + breathe)
      ..lineTo(w * 0.80 + earTwitch, h * 0.14 - breathe * 0.5)
      ..lineTo(w * 0.76, center.dy - 6 + breathe)
      ..close();
    canvas.drawPath(rightEarPath, bodyPaint);
    canvas.drawPath(rightEarPath, outlinePaint);

    final rightEarInner = Path()
      ..moveTo(w * 0.62, center.dy - 10 + breathe)
      ..lineTo(w * 0.77 + earTwitch, h * 0.20 - breathe * 0.5)
      ..lineTo(w * 0.74, center.dy - 6 + breathe)
      ..close();
    canvas.drawPath(rightEarInner, earInnerPaint);

    // 4. Draw Cat Head
    final headRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - 4 + breathe),
      width: w * 0.66,
      height: h * 0.52,
    );
    final headRRect = RRect.fromRectAndRadius(headRect, Radius.circular(w * 0.24));
    canvas.drawRRect(headRRect, bodyPaint);
    canvas.drawRRect(headRRect, outlinePaint);

    // 5. Draw Eyes & Facial Expressions
    final headCenterY = center.dy - 4 + breathe;
    final leftEyeCenter = Offset(w * 0.38, headCenterY - 2);
    final rightEyeCenter = Offset(w * 0.62, headCenterY - 2);

    // Determine blink: true for short interval (e.g. 0.92 to 1.0)
    final isBlinking = (blinkProgress > 0.92 && blinkProgress < 0.98) && !isPetting;

    if (mood == KittyMoodState.sleepy && !isPetting) {
      // Sleeping eyes (- -)
      _drawSleepingEye(canvas, leftEyeCenter, w * 0.08);
      _drawSleepingEye(canvas, rightEyeCenter, w * 0.08);

      // Draw floating Zzz
      _drawZzz(canvas, Offset(w * 0.74, h * 0.22 - idleProgress * 8));
    } else if (isPetting || mood == KittyMoodState.happy) {
      // Happy eyes (^ ^)
      _drawHappyEye(canvas, leftEyeCenter, w * 0.08, _getEyeColor());
      _drawHappyEye(canvas, rightEyeCenter, w * 0.08, _getEyeColor());
    } else if (isBlinking) {
      // Blinking slit
      _drawSleepingEye(canvas, leftEyeCenter, w * 0.08);
      _drawSleepingEye(canvas, rightEyeCenter, w * 0.08);
    } else if (mood == KittyMoodState.boss) {
      // Boss Cat Cyber Visor / Shades!
      final visorRect = Rect.fromCenter(
        center: Offset(center.dx, headCenterY - 2),
        width: w * 0.44,
        height: h * 0.14,
      );
      final visorPaint = Paint()..color = const Color(0xFF0F121C);
      final visorBorder = Paint()
        ..color = KwallTheme.cyberGold
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      final visorShine = Paint()
        ..color = KwallTheme.neonGreen.withValues(alpha: 0.8)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(RRect.fromRectAndRadius(visorRect, const Radius.circular(4)), visorPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(visorRect, const Radius.circular(4)), visorBorder);
      canvas.drawLine(
        Offset(center.dx - w * 0.16, headCenterY - 4),
        Offset(center.dx + w * 0.16, headCenterY),
        visorShine,
      );
    } else if (mood == KittyMoodState.alert) {
      // Alert / Big Dilated Eyes with exclamation mark
      final eyeRadius = w * 0.09;
      canvas.drawCircle(leftEyeCenter, eyeRadius, eyeGlowPaint);
      canvas.drawCircle(leftEyeCenter, eyeRadius * 0.75, darkEyePaint);
      canvas.drawCircle(leftEyeCenter + const Offset(-2, -2), eyeRadius * 0.3, Paint()..color = Colors.white);

      canvas.drawCircle(rightEyeCenter, eyeRadius, eyeGlowPaint);
      canvas.drawCircle(rightEyeCenter, eyeRadius * 0.75, darkEyePaint);
      canvas.drawCircle(rightEyeCenter + const Offset(-2, -2), eyeRadius * 0.3, Paint()..color = Colors.white);

      // Warning alert pip over head
      _drawAlertPip(canvas, Offset(center.dx, h * 0.12 + breathe));
    } else {
      // Normal Zen / Gamer Eyes
      final eyeRadius = w * 0.075;
      canvas.drawCircle(leftEyeCenter, eyeRadius, eyeGlowPaint);
      canvas.drawCircle(leftEyeCenter, eyeRadius * 0.55, darkEyePaint);
      canvas.drawCircle(leftEyeCenter + const Offset(-1.5, -1.5), eyeRadius * 0.25, Paint()..color = Colors.white);

      canvas.drawCircle(rightEyeCenter, eyeRadius, eyeGlowPaint);
      canvas.drawCircle(rightEyeCenter, eyeRadius * 0.55, darkEyePaint);
      canvas.drawCircle(rightEyeCenter + const Offset(-1.5, -1.5), eyeRadius * 0.25, Paint()..color = Colors.white);
    }

    // 6. Draw Nose & Mouth
    final noseCenter = Offset(center.dx, headCenterY + 7);
    final nosePath = Path()
      ..moveTo(noseCenter.dx - 3, noseCenter.dy)
      ..lineTo(noseCenter.dx + 3, noseCenter.dy)
      ..lineTo(noseCenter.dx, noseCenter.dy + 3)
      ..close();
    canvas.drawPath(
      nosePath,
      Paint()..color = isPetting ? const Color(0xFFFF70A6) : KwallTheme.neonGreen,
    );

    // Cute W-mouth (Cat mouth curve)
    final mouthPaint = Paint()
      ..color = const Color(0xFF0F121C)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final mouthPath = Path();
    mouthPath.moveTo(noseCenter.dx - 6, noseCenter.dy + 6);
    mouthPath.quadraticBezierTo(noseCenter.dx - 3, noseCenter.dy + 9, noseCenter.dx, noseCenter.dy + 5);
    mouthPath.quadraticBezierTo(noseCenter.dx + 3, noseCenter.dy + 9, noseCenter.dx + 6, noseCenter.dy + 6);
    canvas.drawPath(mouthPath, mouthPaint);

    // 7. Whiskers (3 on each cheek)
    final whiskerPaint = Paint()
      ..color = const Color(0xFF4C5777)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Left Whiskers
    canvas.drawLine(Offset(w * 0.22, headCenterY + 4), Offset(w * 0.08, headCenterY + 2), whiskerPaint);
    canvas.drawLine(Offset(w * 0.22, headCenterY + 8), Offset(w * 0.06, headCenterY + 9), whiskerPaint);
    canvas.drawLine(Offset(w * 0.22, headCenterY + 12), Offset(w * 0.10, headCenterY + 16), whiskerPaint);

    // Right Whiskers
    canvas.drawLine(Offset(w * 0.78, headCenterY + 4), Offset(w * 0.92, headCenterY + 2), whiskerPaint);
    canvas.drawLine(Offset(w * 0.78, headCenterY + 8), Offset(w * 0.94, headCenterY + 9), whiskerPaint);
    canvas.drawLine(Offset(w * 0.78, headCenterY + 12), Offset(w * 0.90, headCenterY + 16), whiskerPaint);

    // 8. Paws resting in front
    final pawPaint = Paint()..color = const Color(0xFF283044);
    final leftPawRect = Rect.fromCenter(center: Offset(w * 0.38, h * 0.88), width: w * 0.16, height: h * 0.12);
    final rightPawRect = Rect.fromCenter(center: Offset(w * 0.62, h * 0.88), width: w * 0.16, height: h * 0.12);
    canvas.drawRRect(RRect.fromRectAndRadius(leftPawRect, const Radius.circular(8)), pawPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(leftPawRect, const Radius.circular(8)), outlinePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rightPawRect, const Radius.circular(8)), pawPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rightPawRect, const Radius.circular(8)), outlinePaint);
  }

  void _drawHappyEye(Canvas canvas, Offset center, double size, Color color) {
    final eyePaint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(center.dx - size, center.dy + 2);
    path.quadraticBezierTo(center.dx, center.dy - size * 0.9, center.dx + size, center.dy + 2);
    canvas.drawPath(path, eyePaint);
  }

  void _drawSleepingEye(Canvas canvas, Offset center, double size) {
    final eyePaint = Paint()
      ..color = const Color(0xFF4C5777)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(center.dx - size, center.dy), Offset(center.dx + size, center.dy), eyePaint);
  }

  void _drawAlertPip(Canvas canvas, Offset center) {
    final pipPaint = Paint()
      ..color = KwallTheme.plasmaPink
      ..style = PaintingStyle.fill;

    // Diamond pip
    final diamond = Path()
      ..moveTo(center.dx, center.dy - 7)
      ..lineTo(center.dx + 5, center.dy)
      ..lineTo(center.dx, center.dy + 7)
      ..lineTo(center.dx - 5, center.dy)
      ..close();
    canvas.drawPath(diamond, pipPaint);
  }

  void _drawZzz(Canvas canvas, Offset pos) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Zzz...',
        style: TextStyle(
          color: KwallTheme.electricCyan,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, pos);
  }

  Color _getEyeColor() {
    switch (mood) {
      case KittyMoodState.happy:
        return KwallTheme.neonGreen;
      case KittyMoodState.alert:
        return KwallTheme.plasmaPink;
      case KittyMoodState.boss:
        return KwallTheme.cyberGold;
      case KittyMoodState.zen:
      case KittyMoodState.sleepy:
        return KwallTheme.electricCyan;
    }
  }

  @override
  bool shouldRepaint(covariant _KittyPainter oldDelegate) {
    return oldDelegate.idleProgress != idleProgress ||
        oldDelegate.blinkProgress != blinkProgress ||
        oldDelegate.mood != mood ||
        oldDelegate.isPetting != isPetting;
  }
}
