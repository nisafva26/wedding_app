import 'dart:math' as math;
import 'package:flutter/material.dart';

class FlipOnAppear extends StatefulWidget {
  const FlipOnAppear({
    required this.child,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 650),
  });

  final Widget child;
  final bool enabled;
  final Duration duration;

  @override
  State<FlipOnAppear> createState() => FlipOnAppearState();
}

class FlipOnAppearState extends State<FlipOnAppear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

    if (widget.enabled) {
      // small delay so it feels intentional
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (_, child) {
        // rotateY from -10deg to 0deg (subtle, premium)
        final angle = (-10 * (1 - _t.value)) * (math.pi / 180);

        // a tiny translate + scale for depth feel
        final translate = 10 * (1 - _t.value);
        final scale = 0.985 + (_t.value * 0.015);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015) // perspective
            ..translate(translate)
            ..rotateY(angle)
            ..scale(scale),
          child: child,
        );
      },
    );
  }
}
