import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class StaggeredSlideEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const StaggeredSlideEntrance({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  State<StaggeredSlideEntrance> createState() => _StaggeredSlideEntranceState();
}

class _StaggeredSlideEntranceState extends State<StaggeredSlideEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _hasStarted = false; // Prevents re-triggering when scrolling back up

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));
  }

  void _triggerAnimation() {
    if (_hasStarted) return;
    _hasStarted = true;

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      // Ensure each key is unique by using the widget's identity
      key: Key('staggered_${identityHashCode(widget)}'),
      onVisibilityChanged: (info) {
        // Start animation only when it enters the viewport
        if (info.visibleFraction > 0.1) {
          _triggerAnimation();
        }
      },
      child: SlideTransition(
        position: _offsetAnimation,
        child: RepaintBoundary(
          child: widget.child,
        ),
      ),
    );
  }
}