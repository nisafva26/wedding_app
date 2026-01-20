import 'dart:async';
import 'package:flutter/material.dart';

class SlowMovingCards extends StatefulWidget {
  const SlowMovingCards({super.key});

  @override
  State<SlowMovingCards> createState() => _SlowMovingCardsState();
}

class _SlowMovingCardsState extends State<SlowMovingCards> {
  final ScrollController _controller = ScrollController();
  late Timer _timer;

  static const double _speed = 0.3; // smaller = slower
  static const double _cardWidth = 220;
  static const double _gap = 16;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_controller.hasClients) return;

      _controller.jumpTo(
        _controller.offset + _speed,
      );

      if (_controller.offset >=
          _controller.position.maxScrollExtent - 1) {
        _controller.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 20, // duplicate items for seamless loop
        separatorBuilder: (_, __) => const SizedBox(width: _gap),
        itemBuilder: (_, __) => _RedCard(width: _cardWidth),
      ),
    );
  }
}

class _RedCard extends StatelessWidget {
  const _RedCard({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
