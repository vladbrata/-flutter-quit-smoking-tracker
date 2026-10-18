import 'package:flutter/material.dart';

/// Un widget grafic vectorial care desenează o pereche de plămâni stilizați
/// ce se umplu treptat de jos în sus pe baza parametrului [progress] (0.0 -> 1.0).
class LungsProgressWidget extends StatelessWidget {
  final double progress;
  final double size;
  final bool showPercentage;

  const LungsProgressWidget({
    super.key,
    required this.progress,
    this.size = 72,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: clampedProgress),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _LungsPainter(progress: animatedValue),
              ),
              if (showPercentage)
                Positioned(
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      "${(animatedValue * 100).toInt()}%",
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LungsPainter extends CustomPainter {
  final double progress;

  _LungsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Construim Path-ul pentru plămânul stâng (față de privitor)
    final Path leftLung = Path();
    // Vârf (apex)
    leftLung.moveTo(w * 0.32, h * 0.22);
    // Curbă exterioară (coaste)
    leftLung.cubicTo(
      w * 0.16, h * 0.24,
      w * 0.08, h * 0.40,
      w * 0.08, h * 0.60,
    );
    leftLung.cubicTo(
      w * 0.08, h * 0.74,
      w * 0.14, h * 0.88,
      w * 0.22, h * 0.90,
    );
    // Baza inferioară (diafragmă)
    leftLung.cubicTo(
      w * 0.28, h * 0.91,
      w * 0.36, h * 0.84,
      w * 0.42, h * 0.78,
    );
    // Margine mediană internă (incizură cardiacă)
    leftLung.cubicTo(
      w * 0.40, h * 0.62,
      w * 0.36, h * 0.48,
      w * 0.44, h * 0.34,
    );
    leftLung.close();

    // Construim Path-ul pentru plămânul drept (față de privitor)
    final Path rightLung = Path();
    // Vârf (apex)
    rightLung.moveTo(w * 0.68, h * 0.22);
    // Curbă exterioară (coaste)
    rightLung.cubicTo(
      w * 0.84, h * 0.24,
      w * 0.92, h * 0.40,
      w * 0.92, h * 0.60,
    );
    rightLung.cubicTo(
      w * 0.92, h * 0.74,
      w * 0.86, h * 0.88,
      w * 0.78, h * 0.90,
    );
    // Baza inferioară (diafragmă)
    rightLung.cubicTo(
      w * 0.72, h * 0.91,
      w * 0.64, h * 0.84,
      w * 0.58, h * 0.78,
    );
    // Margine mediană internă
    rightLung.cubicTo(
      w * 0.60, h * 0.62,
      w * 0.64, h * 0.48,
      w * 0.56, h * 0.34,
    );
    rightLung.close();

    // Trahee superioară
    final RRect tracheaRRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.44, h * 0.08, w * 0.56, h * 0.34),
      const Radius.circular(3),
    );
    final Path tracheaPath = Path()..addRRect(tracheaRRect);

    // Unim toate componentele într-un singur contur pulmonar
    Path fullLungsPath = Path.combine(PathOperation.union, leftLung, rightLung);
    fullLungsPath = Path.combine(PathOperation.union, fullLungsPath, tracheaPath);

    // 1. DESENARE FUNDAL (Plămâni neregulați/goliți)
    final Paint bgPaint = Paint()
      ..color = const Color(0xFF182024)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fullLungsPath, bgPaint);

    // Contur fin discret pentru fundal
    final Paint bgBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(fullLungsPath, bgBorderPaint);

    // 2. DESENARE RAMIFICAȚII BRONȘICE (STARE GOALĂ)
    _drawBronchialTree(
      canvas,
      w,
      h,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    // 3. UMPLEREA CU OXIGEN / PROGRESUL DE SĂNĂTATE (Clipped)
    if (progress > 0.0) {
      canvas.save();
      canvas.clipPath(fullLungsPath);

      // Calculăm înălțimea lichidului/aerului vindecător (de jos în sus)
      final double fillHeight = h * progress;
      final double topY = h - fillHeight;

      // Gradient energizant sănătate: Verde Smarald -> Cyan Luminos -> Turcoaz
      final Rect fillRect = Rect.fromLTRB(0, topY, w, h);
      final Paint fillPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xFF00796B), // Deep teal la bază
            Color(0xFF00BFA5), // Teal vibrant
            Color(0xFF00E5FF), // Cyan luminos sus
            Color(0xFF69F0AE), // Mint fresh pe menisc
          ],
          stops: [0.0, 0.4, 0.85, 1.0],
        ).createShader(fillRect);

      canvas.drawRect(fillRect, fillPaint);

      // Linia superioară a nivelului de umplere (menisc strălucitor)
      final Paint meniscusPaint = Paint()
        ..color = const Color(0xFFE0F7FA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);
      canvas.drawLine(
        Offset(0, topY),
        Offset(w, topY),
        meniscusPaint,
      );

      // Redesenăm ramificațiile bronșice luminate în zona plină
      _drawBronchialTree(
        canvas,
        w,
        h,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );

      canvas.restore();

      // Efect de strălucire exterioară a plămânilor proporțional cu progresul
      final Paint glowBorder = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.25 + 0.35 * progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawPath(fullLungsPath, glowBorder);
    }
  }

  void _drawBronchialTree(Canvas canvas, double w, double h, Paint branchPaint) {
    // Inele trahee
    for (double yFrac = 0.12; yFrac <= 0.26; yFrac += 0.05) {
      canvas.drawLine(
        Offset(w * 0.46, h * yFrac),
        Offset(w * 0.54, h * yFrac),
        branchPaint..strokeWidth = 1.0,
      );
    }

    // Trunchi trahee
    canvas.drawLine(
      Offset(w * 0.50, h * 0.10),
      Offset(w * 0.50, h * 0.30),
      branchPaint..strokeWidth = 1.8,
    );

    // Bronhia principală stângă
    canvas.drawLine(
      Offset(w * 0.50, h * 0.30),
      Offset(w * 0.36, h * 0.44),
      branchPaint..strokeWidth = 1.5,
    );
    // Ramuri stânga
    canvas.drawLine(
      Offset(w * 0.36, h * 0.44),
      Offset(w * 0.24, h * 0.56),
      branchPaint..strokeWidth = 1.2,
    );
    canvas.drawLine(
      Offset(w * 0.36, h * 0.44),
      Offset(w * 0.34, h * 0.66),
      branchPaint..strokeWidth = 1.2,
    );
    canvas.drawLine(
      Offset(w * 0.36, h * 0.44),
      Offset(w * 0.28, h * 0.34),
      branchPaint..strokeWidth = 1.0,
    );

    // Bronhia principală dreaptă
    canvas.drawLine(
      Offset(w * 0.50, h * 0.30),
      Offset(w * 0.64, h * 0.44),
      branchPaint..strokeWidth = 1.5,
    );
    // Ramuri dreapta
    canvas.drawLine(
      Offset(w * 0.64, h * 0.44),
      Offset(w * 0.76, h * 0.56),
      branchPaint..strokeWidth = 1.2,
    );
    canvas.drawLine(
      Offset(w * 0.64, h * 0.44),
      Offset(w * 0.66, h * 0.66),
      branchPaint..strokeWidth = 1.2,
    );
    canvas.drawLine(
      Offset(w * 0.64, h * 0.44),
      Offset(w * 0.72, h * 0.34),
      branchPaint..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant _LungsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
