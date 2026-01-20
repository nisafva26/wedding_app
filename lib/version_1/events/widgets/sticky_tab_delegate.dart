import 'package:flutter/material.dart';

class StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  StickyTabBarDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white, // Background color when pinned
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: child,
    );
  }

  @override
  double get maxExtent => 60.0; // Height of your tab bar
  @override
  double get minExtent => 60.0; 

  @override
  bool shouldRebuild(covariant StickyTabBarDelegate oldDelegate) => false;
}