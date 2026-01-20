import 'package:flutter/material.dart';

class WaveSeparator extends StatelessWidget {
  const WaveSeparator({
    super.key,
    required this.topColor,
    required this.bottomColor,
    this.height = 44,
    this.amplitude = 80, // wave height
  });

  final Color topColor;
  final Color bottomColor;
  final double height;
  final double amplitude;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _ThreeWaveSeparatorPainter(
          topColor: topColor,
          bottomColor: bottomColor,
          amplitude: amplitude,
        ),
      ),
    );
  }
}

class _ThreeWaveSeparatorPainter extends CustomPainter {
  _ThreeWaveSeparatorPainter({
    required this.topColor,
    required this.bottomColor,
    required this.amplitude,
  });

  final Color topColor;
  final Color bottomColor;
  final double amplitude;

  @override
  void paint(Canvas canvas, Size size) {
    final paintTop = Paint()
      ..color = topColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final paintBottom = Paint()
      ..color = bottomColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Fill with bottom color first
    canvas.drawRect(Offset.zero & size, paintBottom);

    // Base line for the wave (where wave sits)
    final baseY = size.height * 0.62;
    final amp = amplitude.clamp(0.0, size.height * 0.35);

    // Build the top shape with a 3-wave bottom edge
    final p = Path();
    p.moveTo(0, 0);
    p.lineTo(0, baseY);

    final waveWidth = size.width / 3;

    // Each "wave" uses 2 quadratic curves:
    // crest then trough (or vice versa) -> one full wave cycle
    for (int i = 0; i < 3; i++) {
      final startX = i * waveWidth;
      final midX = startX + waveWidth / 2;
      final endX = startX + waveWidth;

      // Crest (up)
      p.quadraticBezierTo(
        startX + waveWidth * 0.25,
        baseY - amp,
        midX,
        baseY,
      );

      // Trough (down)
      p.quadraticBezierTo(
        startX + waveWidth * 0.75,
        baseY + amp,
        endX,
        baseY,
      );
    }

    p.lineTo(size.width, 0);
    p.close();

    canvas.drawPath(p, paintTop);
  }

  @override
  bool shouldRepaint(covariant _ThreeWaveSeparatorPainter oldDelegate) {
    return oldDelegate.topColor != topColor ||
        oldDelegate.bottomColor != bottomColor ||
        oldDelegate.amplitude != amplitude;
  }
}



class WavyTop extends StatelessWidget {
  final Color color;
  const WavyTop({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: CustomPaint(
        painter: _SingleWavePainter(color: color),
      ),
    );
  }
}

class _SingleWavePainter extends CustomPainter {
  final Color color;
  _SingleWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    final baseY = size.height * 0.5;

    path.moveTo(0, size.height); 
    path.lineTo(0, baseY);

    final waveWidth = size.width / 3;
    for (int i = 0; i < 3; i++) {
      final startX = i * waveWidth;
      path.quadraticBezierTo(startX + waveWidth * 0.25, baseY - 15, startX + waveWidth * 0.5, baseY);
      path.quadraticBezierTo(startX + waveWidth * 0.75, baseY + 15, startX + waveWidth, baseY);
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
