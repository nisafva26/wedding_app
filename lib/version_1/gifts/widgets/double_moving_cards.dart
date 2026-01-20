import 'dart:async';
import 'package:flutter/material.dart';

class SlowMovingGiftCardsDoubleRow extends StatelessWidget {
  const SlowMovingGiftCardsDoubleRow({super.key});

  static const _top = [
    'assets/images/gift_1.jpg',
    'assets/images/gift_2.png',
    'assets/images/gift_3.png',
  ];

  static const _bottom = [
    'assets/images/gift_4.png',
    'assets/images/gift_5.png',
    'assets/images/gift_6.png',
  ];

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 320,
      child: Column(
        children: [
          _AutoScrollGiftRow(images: _top, direction: _ScrollDir.left),
          SizedBox(height: 18),
          _AutoScrollGiftRow(images: _bottom, direction: _ScrollDir.right),
        ],
      ),
    );
  }
}

enum _ScrollDir { left, right }

class _AutoScrollGiftRow extends StatefulWidget {
  const _AutoScrollGiftRow({required this.images, required this.direction});

  final List<String> images;
  final _ScrollDir direction;

  @override
  State<_AutoScrollGiftRow> createState() => _AutoScrollGiftRowState();
}

class _AutoScrollGiftRowState extends State<_AutoScrollGiftRow> {
  final ScrollController _c = ScrollController();
  Timer? _t;

  // tweak if needed
  static const double _speed = 0.35; // smaller = slower
  static const double _cardW = 178;
  static const double _cardH = 114;
  static const double _gap = 18;
  static const double _radius = 14;

  static const int _repeatFactor =
      8; // 3 images * 8 = 24 items for smooth looping

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_c.hasClients) return;

      // Start from mid for right-moving row so it feels continuous.
      if (widget.direction == _ScrollDir.right) {
        _c.jumpTo(_c.position.maxScrollExtent / 2);
      }

      _t = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (!_c.hasClients) return;

        final delta = widget.direction == _ScrollDir.left ? _speed : -_speed;

        final next = _c.offset + delta;

        // Wrap seamlessly
        if (next >= _c.position.maxScrollExtent - 1) {
          _c.jumpTo(0);
        } else if (next <= 0) {
          _c.jumpTo(_c.position.maxScrollExtent - 2);
        } else {
          _c.jumpTo(next);
        }
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.images.length * _repeatFactor;

    return SizedBox(
      height: _cardH,
      child: ListView.separated(
        controller: _c,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: _gap),
        itemBuilder: (_, index) {
          final imagePath = widget.images[index % widget.images.length];
          return _GiftCard(
            imagePath: imagePath,
            width: _cardW,
            height: _cardH,
            radius: _radius,
          );
        },
      ),
    );
  }
}

class _GiftCard extends StatelessWidget {
  const _GiftCard({
    required this.imagePath,
    required this.width,
    required this.height,
    required this.radius,
  });

  final String imagePath;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.85),
          ),
          shadows: [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 9.28,
              offset: Offset(0, 3.71),
              spreadRadius: 0,
            ),
          ],
        ),
        width: width,
        height: height,
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
