import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class GearShiftRotation extends StatefulWidget {
  const GearShiftRotation({
    super.key,
    required this.child,
    this.clockwiseDuration = const Duration(seconds: 3),
    this.anticlockwiseDuration = const Duration(seconds: 3),
  });

  final Widget child;
  final Duration clockwiseDuration;
  final Duration anticlockwiseDuration;

  @override
  State<GearShiftRotation> createState() => _GearShiftRotationState();
}

class _GearShiftRotationState extends State<GearShiftRotation>
    with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _gearCtrl;

  // holds the accumulated angle (radians)
  double _baseAngle = 0.0;

  // direction: +1 clockwise, -1 anticlockwise
  int _dir = 1;

  // gear "kick" angle (spring settles back to 0)
  late Animation<double> _gearKick;

  @override
  void initState() {
    super.initState();

    // Continuous spin controller (we drive angle manually using tickers)
    _spinCtrl = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() {});
      });

    // Gear shift controller (spring)
    _gearCtrl = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() {});
      });

    _gearKick = _gearCtrl; // value is radians offset

    _startClockwise();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _gearCtrl.dispose();
    super.dispose();
  }

  // --- Spin helpers ---
  void _startClockwise() async {
    _dir = 1;
    await _spinFor(widget.clockwiseDuration);
    if (!mounted) return;
    await _shiftGearAndReverse();
    if (!mounted) return;
    await _spinFor(widget.anticlockwiseDuration);
  }

  Future<void> _spinFor(Duration duration) async {
    final double start = _spinCtrl.value;
    final double end = start + _dir * 2 * math.pi; // one full turn each segment (adjust if you want faster)
    _spinCtrl.animateTo(
      end,
      duration: duration,
      curve: Curves.linear,
    );
    await Future.delayed(duration);
  }

  // --- Gear shift physics ---
  Future<void> _shiftGearAndReverse() async {
    // 1) Capture current angle into base so there's no jump
    _baseAngle += _spinCtrl.value;
    _spinCtrl.value = 0;

    // 2) "Decel to stop" feel: do a quick ease-out to reduce angular velocity
    // (visual trick: small forward drift then stop)
    await _spinCtrl.animateTo(
      _dir * 0.12, // tiny drift forward
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );

    // 3) Backlash / overshoot using a spring: kick opposite then settle
    _gearCtrl.value = 0;

    // This kick magnitude controls the "gear tooth backlash"
    final double kick = -_dir * 0.35; // radians (~20°). increase for stronger gear effect

    final spring = SpringDescription(
      mass: 1.0,
      stiffness: 280.0,
      damping: 16.0,
    );

    // We simulate: start at 0, velocity in opposite direction, target 0, but we first jump to kick.
    _gearCtrl.value = kick;

    final sim = SpringSimulation(
      spring,
      kick, // start
      0.0,  // end (settle)
      _dir * 6.0, // initial velocity (controls snap). tweak 4..10
    );

    // Animate spring to settle at 0
    _gearCtrl.animateWith(sim);

    // Let the spring play a bit
    await Future.delayed(const Duration(milliseconds: 520));

    // 4) Reverse direction after the backlash starts settling
    _dir = -1;

    // reset spin controller for next segment
    _spinCtrl.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    // total angle = accumulated base + current spin + gear kick
    final angle = _baseAngle + _spinCtrl.value + _gearKick.value;

    return Transform.rotate(
      angle: angle,
      child: widget.child,
    );
  }
}
