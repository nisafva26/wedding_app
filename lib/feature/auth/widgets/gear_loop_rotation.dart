import 'dart:math' as math;
import 'package:flutter/material.dart';

class SmoothGearOscillation extends StatefulWidget {
  const SmoothGearOscillation({
    super.key,
    required this.child,

    /// Time to move in one direction (not counting holds).
    this.moveDuration = const Duration(seconds: 3),

    /// Pause at each end (top and bottom).
    this.holdDuration = const Duration(milliseconds: 450),

    /// How many full rotations from one end to the other.
    /// 1.0 = 360deg
    this.turnsPerSide = 1.0,
  });

  final Widget child;
  final Duration moveDuration;
  final Duration holdDuration;
  final double turnsPerSide;

  @override
  State<SmoothGearOscillation> createState() => _SmoothGearOscillationState();
}

class _SmoothGearOscillationState extends State<SmoothGearOscillation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  Duration get _cycleDuration =>
      widget.moveDuration +
      widget.holdDuration +
      widget.moveDuration +
      widget.holdDuration;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _cycleDuration)..repeat();
  }

  @override
  void didUpdateWidget(covariant SmoothGearOscillation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moveDuration != widget.moveDuration ||
        oldWidget.holdDuration != widget.holdDuration) {
      _c.duration = _cycleDuration;
      if (!_c.isAnimating) _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Sine-ish ease that gives smooth accel/decel (velocity 0 at endpoints)
  double _easeInOutSine(double t) => 0.5 - 0.5 * math.cos(math.pi * t);

  @override
  Widget build(BuildContext context) {
    final maxAngle = widget.turnsPerSide * 2 * math.pi;

    final moveSec = widget.moveDuration.inMicroseconds / 1e6;
    final holdSec = widget.holdDuration.inMicroseconds / 1e6;
    final totalSec = _cycleDuration.inMicroseconds / 1e6;

    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final time = _c.value * totalSec;

        // Phase timeline:
        // [0 .. move]          : 0 -> 1 (CW)
        // [move .. move+hold]  : hold at 1
        // [.. +move]           : 1 -> 0 (CCW)
        // [.. +hold]           : hold at 0
        double progress; // 0..1
        if (time < moveSec) {
          final t = time / moveSec;
          progress = _easeInOutSine(t); // 0 -> 1
        } else if (time < moveSec + holdSec) {
          progress = 1.0;
        } else if (time < moveSec + holdSec + moveSec) {
          final t = (time - (moveSec + holdSec)) / moveSec;
          progress = 1.0 - _easeInOutSine(t); // 1 -> 0
        } else {
          progress = 0.0;
        }

        return Transform.rotate(
          angle: maxAngle * progress,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
