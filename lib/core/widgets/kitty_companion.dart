import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/kwall_theme.dart';

class KittyCompanionWidget extends StatefulWidget {
  final String coatColor; // 'orange', 'tuxedo', 'white', 'grey', 'calico'
  final String mood; // 'happy', 'zen', 'sleepy', 'alert'
  final String name;
  final double size;
  final VoidCallback? onPet;

  const KittyCompanionWidget({
    super.key,
    this.coatColor = 'orange',
    this.mood = 'happy',
    this.name = 'Mishi',
    this.size = 110,
    this.onPet,
  });

  @override
  State<KittyCompanionWidget> createState() => _KittyCompanionWidgetState();
}

class _KittyCompanionWidgetState extends State<KittyCompanionWidget>
    with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late AnimationController _blinkController;
  late AnimationController _petController;

  bool _isPetting = false;
  String? _dialogue;

  @override
  void initState() {
    super.initState();

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _petController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _blinkController.dispose();
    _petController.dispose();
    super.dispose();
  }

  void _handlePet() {
    setState(() {
      _isPetting = true;
      final dialogues = ['¡Miau!', 'Prrr~', '♥ Ronroneo', '¡Hola!', 'Purrr...'];
      _dialogue = dialogues[math.Random().nextInt(dialogues.length)];
    });

    _petController.forward(from: 0.0);
    widget.onPet?.call();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isPetting = false;
          _dialogue = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handlePet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speech Bubble (Expressive M3 pill)
          if (_dialogue != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: KwallTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: KwallTheme.accent.withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: Text(
                _dialogue!,
                style: KwallTheme.fontBody.copyWith(
                  color: KwallTheme.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          AnimatedBuilder(
            animation: Listenable.merge([
              _breatheController,
              _blinkController,
              _petController,
            ]),
            builder: (context, child) {
              final breathe = _breatheController.value;
              final blink = _blinkController.value;
              final pet = _petController.value;
              final hopOffset = math.sin(pet * math.pi) * -8;

              return Transform.translate(
                offset: Offset(0, hopOffset),
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: _NormalKittyPainter(
                      coatColor: widget.coatColor,
                      mood: widget.mood,
                      breatheProgress: breathe,
                      blinkProgress: blink,
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

class _NormalKittyPainter extends CustomPainter {
  final String coatColor;
  final String mood;
  final double breatheProgress;
  final double blinkProgress;
  final bool isPetting;

  _NormalKittyPainter({
    required this.coatColor,
    required this.mood,
    required this.breatheProgress,
    required this.blinkProgress,
    required this.isPetting,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    final breathe = math.sin(breatheProgress * math.pi) * 1.8;

    // Palette per coat
    final colors = _getPalette(coatColor);
    final basePaint = Paint()..color = colors.base;
    final highlightPaint = Paint()..color = colors.highlight;
    final earInnerPaint = Paint()..color = const Color(0xFFFFB1C1);
    final outlinePaint = Paint()
      ..color = colors.outline
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 1. Natural Curved Tail
    final tailWag = math.sin(breatheProgress * 2 * math.pi) * (isPetting ? 10 : 5);
    final tailPath = Path();
    tailPath.moveTo(w * 0.70, h * 0.78);
    tailPath.cubicTo(
      w * 0.86 + tailWag,
      h * 0.74,
      w * 0.94 + tailWag * 1.2,
      h * 0.52,
      w * 0.84 + tailWag,
      h * 0.42,
    );

    final tailStroke = Paint()
      ..color = colors.base
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final tailOutline = Paint()
      ..color = colors.outline
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(tailPath, tailOutline);
    canvas.drawPath(tailPath, tailStroke);

    // 2. Chibi Body (Soft rounded ellipse)
    final bodyCenter = Offset(center.dx, center.dy + 15 + breathe * 0.4);
    final bodyRect = Rect.fromCenter(
      center: bodyCenter,
      width: w * 0.64,
      height: h * 0.46,
    );
    canvas.drawOval(bodyRect, basePaint);
    canvas.drawOval(bodyRect, outlinePaint);

    // Chest patch (white / cream belly)
    final chestRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + 18 + breathe * 0.4),
      width: w * 0.40,
      height: h * 0.30,
    );
    canvas.drawOval(chestRect, highlightPaint);

    // 3. Ears (Soft triangular cat ears)
    final earY = center.dy - 6 + breathe;

    // Left Ear
    final leftEarPath = Path()
      ..moveTo(w * 0.25, earY)
      ..lineTo(w * 0.22, h * 0.16)
      ..lineTo(w * 0.43, earY - 6)
      ..close();
    canvas.drawPath(leftEarPath, basePaint);
    canvas.drawPath(leftEarPath, outlinePaint);

    final leftEarInner = Path()
      ..moveTo(w * 0.28, earY - 2)
      ..lineTo(w * 0.25, h * 0.23)
      ..lineTo(w * 0.39, earY - 6)
      ..close();
    canvas.drawPath(leftEarInner, earInnerPaint);

    // Right Ear
    final rightEarPath = Path()
      ..moveTo(w * 0.57, earY - 6)
      ..lineTo(w * 0.78, h * 0.16)
      ..lineTo(w * 0.75, earY)
      ..close();
    canvas.drawPath(rightEarPath, basePaint);
    canvas.drawPath(rightEarPath, outlinePaint);

    final rightEarInner = Path()
      ..moveTo(w * 0.61, earY - 6)
      ..lineTo(w * 0.75, h * 0.23)
      ..lineTo(w * 0.72, earY - 2)
      ..close();
    canvas.drawPath(rightEarInner, earInnerPaint);

    // 4. Head (Soft round oval)
    final headCenter = Offset(center.dx, center.dy - 3 + breathe);
    final headRect = Rect.fromCenter(
      center: headCenter,
      width: w * 0.70,
      height: h * 0.54,
    );
    canvas.drawOval(headRect, basePaint);
    canvas.drawOval(headRect, outlinePaint);

    // Tabby stripes if orange or grey
    if (coatColor == 'orange' || coatColor == 'grey') {
      final stripePaint = Paint()
        ..color = colors.stripe
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(center.dx, headCenter.dy - 16), Offset(center.dx, headCenter.dy - 8), stripePaint);
      canvas.drawLine(Offset(center.dx - 6, headCenter.dy - 14), Offset(center.dx - 4, headCenter.dy - 8), stripePaint);
      canvas.drawLine(Offset(center.dx + 6, headCenter.dy - 14), Offset(center.dx + 4, headCenter.dy - 8), stripePaint);
    }

    // 5. Eyes & Expression
    final leftEye = Offset(headCenter.dx - w * 0.14, headCenter.dy - 1);
    final rightEye = Offset(headCenter.dx + w * 0.14, headCenter.dy - 1);

    final isBlinking = blinkProgress > 0.93 && blinkProgress < 0.98 && !isPetting;

    if (mood == 'sleepy' || (isBlinking && !isPetting)) {
      // Sleeping curved lines (- -)
      _drawClosedEye(canvas, leftEye, w * 0.07, colors.outline);
      _drawClosedEye(canvas, rightEye, w * 0.07, colors.outline);
    } else if (isPetting || mood == 'happy') {
      // Happy smiling curved eyes (^ ^)
      _drawHappyEye(canvas, leftEye, w * 0.07, colors.eyeColor);
      _drawHappyEye(canvas, rightEye, w * 0.07, colors.eyeColor);

      // Blushing cute cheeks
      final blushPaint = Paint()..color = const Color(0xFFFF94A6).withValues(alpha: 0.55);
      canvas.drawCircle(Offset(leftEye.dx - 4, leftEye.dy + 9), 5.5, blushPaint);
      canvas.drawCircle(Offset(rightEye.dx + 4, rightEye.dy + 9), 5.5, blushPaint);
    } else {
      // Normal friendly round cute eyes with spark
      final eyeR = w * 0.07;
      final eyePaint = Paint()..color = const Color(0xFF1E232E);
      final glintPaint = Paint()..color = Colors.white;

      canvas.drawCircle(leftEye, eyeR, eyePaint);
      canvas.drawCircle(rightEye, eyeR, eyePaint);

      // Cute white catchlights
      canvas.drawCircle(leftEye + const Offset(-1.8, -1.8), eyeR * 0.40, glintPaint);
      canvas.drawCircle(leftEye + const Offset(1.8, 1.8), eyeR * 0.18, glintPaint);

      canvas.drawCircle(rightEye + const Offset(-1.8, -1.8), eyeR * 0.40, glintPaint);
      canvas.drawCircle(rightEye + const Offset(1.8, 1.8), eyeR * 0.18, glintPaint);
    }

    // 6. Nose & Sweet Smile (ω mouth)
    final noseCenter = Offset(headCenter.dx, headCenter.dy + 6);
    final nosePaint = Paint()..color = const Color(0xFFFF8FA3);
    final nosePath = Path()
      ..moveTo(noseCenter.dx - 2.5, noseCenter.dy - 1)
      ..lineTo(noseCenter.dx + 2.5, noseCenter.dy - 1)
      ..lineTo(noseCenter.dx, noseCenter.dy + 2)
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    final mouthPaint = Paint()
      ..color = colors.outline
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final mouthPath = Path();
    mouthPath.moveTo(noseCenter.dx - 5, noseCenter.dy + 5);
    mouthPath.quadraticBezierTo(noseCenter.dx - 2.5, noseCenter.dy + 8, noseCenter.dx, noseCenter.dy + 4);
    mouthPath.quadraticBezierTo(noseCenter.dx + 2.5, noseCenter.dy + 8, noseCenter.dx + 5, noseCenter.dy + 5);
    canvas.drawPath(mouthPath, mouthPaint);

    // 7. Whiskers
    final whiskerPaint = Paint()
      ..color = colors.outline.withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Left Whiskers
    canvas.drawLine(Offset(headCenter.dx - w * 0.18, headCenter.dy + 4), Offset(headCenter.dx - w * 0.34, headCenter.dy + 2), whiskerPaint);
    canvas.drawLine(Offset(headCenter.dx - w * 0.18, headCenter.dy + 7), Offset(headCenter.dx - w * 0.35, headCenter.dy + 8), whiskerPaint);

    // Right Whiskers
    canvas.drawLine(Offset(headCenter.dx + w * 0.18, headCenter.dy + 4), Offset(headCenter.dx + w * 0.34, headCenter.dy + 2), whiskerPaint);
    canvas.drawLine(Offset(headCenter.dx + w * 0.18, headCenter.dy + 7), Offset(headCenter.dx + w * 0.35, headCenter.dy + 8), whiskerPaint);

    // 8. Paws
    final pawPaint = Paint()..color = colors.highlight;
    final leftPaw = Rect.fromCenter(center: Offset(center.dx - w * 0.14, h * 0.88), width: w * 0.15, height: h * 0.11);
    final rightPaw = Rect.fromCenter(center: Offset(center.dx + w * 0.14, h * 0.88), width: w * 0.15, height: h * 0.11);

    canvas.drawOval(leftPaw, pawPaint);
    canvas.drawOval(leftPaw, outlinePaint);
    canvas.drawOval(rightPaw, pawPaint);
    canvas.drawOval(rightPaw, outlinePaint);
  }

  void _drawHappyEye(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(center.dx - size, center.dy + 1);
    path.quadraticBezierTo(center.dx, center.dy - size * 0.8, center.dx + size, center.dy + 1);
    canvas.drawPath(path, paint);
  }

  void _drawClosedEye(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - size, center.dy), Offset(center.dx + size, center.dy), paint);
  }

  _KittyColorPalette _getPalette(String coat) {
    switch (coat) {
      case 'tuxedo':
        return _KittyColorPalette(
          base: const Color(0xFF232730),
          highlight: const Color(0xFFF8FAFC),
          outline: const Color(0xFF14171E),
          stripe: const Color(0xFF1A1C22),
          eyeColor: const Color(0xFF10B981),
        );
      case 'white':
        return _KittyColorPalette(
          base: const Color(0xFFF1F5F9),
          highlight: const Color(0xFFFFFFFF),
          outline: const Color(0xFFCBD5E1),
          stripe: const Color(0xFFE2E8F0),
          eyeColor: const Color(0xFF38BDF8),
        );
      case 'grey':
        return _KittyColorPalette(
          base: const Color(0xFF64748B),
          highlight: const Color(0xFFE2E8F0),
          outline: const Color(0xFF334155),
          stripe: const Color(0xFF475569),
          eyeColor: const Color(0xFFF59E0B),
        );
      case 'calico':
        return _KittyColorPalette(
          base: const Color(0xFFF8FAFC),
          highlight: const Color(0xFFF97316),
          outline: const Color(0xFF334155),
          stripe: const Color(0xFF1E293B),
          eyeColor: const Color(0xFF10B981),
        );
      case 'orange':
      default:
        return _KittyColorPalette(
          base: const Color(0xFFFB923C), // Warm ginger orange
          highlight: const Color(0xFFFFF7ED), // Cream chest
          outline: const Color(0xFFC2410C),
          stripe: const Color(0xFFEA580C),
          eyeColor: const Color(0xFF10B981),
        );
    }
  }

  @override
  bool shouldRepaint(covariant _NormalKittyPainter old) {
    return old.breatheProgress != breatheProgress ||
        old.blinkProgress != blinkProgress ||
        old.coatColor != coatColor ||
        old.mood != mood ||
        old.isPetting != isPetting;
  }
}

class _KittyColorPalette {
  final Color base;
  final Color highlight;
  final Color outline;
  final Color stripe;
  final Color eyeColor;

  _KittyColorPalette({
    required this.base,
    required this.highlight,
    required this.outline,
    required this.stripe,
    required this.eyeColor,
  });
}
