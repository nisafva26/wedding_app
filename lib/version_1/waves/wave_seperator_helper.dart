import 'package:flutter/material.dart';

class TopWaveSeparator extends StatelessWidget {
  const TopWaveSeparator({
    super.key,
    required this.topColor,
    required this.bottomColor,
    this.height = 44,
    this.amplitude = 80,
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
        painter: _TopWavePainter(
          topColor: topColor,
          bottomColor: bottomColor,
          amplitude: amplitude,
        ),
      ),
    );
  }
}

class BottomWaveSeparator extends StatelessWidget {
  const BottomWaveSeparator({
    super.key,
    required this.topColor,
    required this.bottomColor,
    this.height = 44,
    this.amplitude = 80,
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
        painter: _BottomWavePainter(
          topColor: topColor,
          bottomColor: bottomColor,
          amplitude: amplitude,
        ),
      ),
    );
  }
}


class _TopWavePainter extends CustomPainter {
  _TopWavePainter({
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

    // Base line for the wave
    final baseY = size.height * 0.62;
    final amp = amplitude.clamp(0.0, size.height * 0.35);

    // Top area (topColor) with a wavy bottom edge
    final p = Path();
    p.moveTo(0, 0);
    p.lineTo(0, baseY);

    final waveWidth = size.width / 3;

    for (int i = 0; i < 3; i++) {
      final startX = i * waveWidth;
      final midX = startX + waveWidth / 2;
      final endX = startX + waveWidth;

      // Crest
      p.quadraticBezierTo(
        startX + waveWidth * 0.25,
        baseY - amp,
        midX,
        baseY,
      );

      // Trough
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
  bool shouldRepaint(covariant _TopWavePainter oldDelegate) {
    return oldDelegate.topColor != topColor ||
        oldDelegate.bottomColor != bottomColor ||
        oldDelegate.amplitude != amplitude;
  }
}



class _BottomWavePainter extends CustomPainter {
  _BottomWavePainter({
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

    // Fill with top color first
    canvas.drawRect(Offset.zero & size, paintTop);

    // Base line for the wave (near top of this separator)
    final baseY = size.height * 0.38;
    final amp = amplitude.clamp(0.0, size.height * 0.35);

    // Bottom area (bottomColor) with a wavy TOP edge
    final p = Path();
    p.moveTo(0, size.height);
    p.lineTo(0, baseY);

    final waveWidth = size.width / 3;

    for (int i = 0; i < 3; i++) {
      final startX = i * waveWidth;
      final midX = startX + waveWidth / 2;
      final endX = startX + waveWidth;

      // Trough first (inverted feel)
      p.quadraticBezierTo(
        startX + waveWidth * 0.25,
        baseY + amp,
        midX,
        baseY,
      );

      // Crest next
      p.quadraticBezierTo(
        startX + waveWidth * 0.75,
        baseY - amp,
        endX,
        baseY,
      );
    }

    p.lineTo(size.width, size.height);
    p.close();

    canvas.drawPath(p, paintBottom);
  }

  @override
  bool shouldRepaint(covariant _BottomWavePainter oldDelegate) {
    return oldDelegate.topColor != topColor ||
        oldDelegate.bottomColor != bottomColor ||
        oldDelegate.amplitude != amplitude;
  }
}
