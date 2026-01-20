import 'dart:ui';

import 'package:flutter/material.dart';

class EventsStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String countText;

  EventsStickyHeaderDelegate({required this.countText});

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    final t = (shrinkOffset / maxExtent).clamp(0.0, 1.0);

    return Container(
      color: Color.lerp(
        const Color(0xFFF7E7EF),
        Colors.white,
        t,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            "Events",
            style: TextStyle(
              fontSize: lerpDouble(32, 20, t),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(countText),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 88;

  @override
  double get minExtent => 64;

  @override
  bool shouldRebuild(_) => true;
}
