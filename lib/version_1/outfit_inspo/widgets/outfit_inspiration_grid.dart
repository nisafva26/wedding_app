import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class OutfitInspirationOffsetGrid extends StatelessWidget {
  const OutfitInspirationOffsetGrid({
    super.key,
    required this.images,
    this.gap = 14,
    this.radius = 16,
    this.tallHeight = 240,
    this.shortHeight = 210,
  });

  final List<String> images; // asset paths (or urls)
  final double gap;
  final double radius;
  final double tallHeight;
  final double shortHeight;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    // Split into 2 columns (left gets 0,2,4..; right gets 1,3,5..)
    final left = <String>[];
    final right = <String>[];
    for (int i = 0; i < images.length; i++) {
      (i % 2 == 0 ? left : right).add(images[i]);
    }

    // This is the magic: push the right column down so it “sits between”
    // the two left tiles (like your screenshot).
    final rightTopOffset = (tallHeight - shortHeight) / 2;

    double heightFor(int indexInColumn, {required bool isRight}) {
      // Keep a nice designer rhythm:
      // left column mostly tall, right column mostly short (like screenshot)
      if (isRight) {
        return shortHeight;
      }
      return tallHeight;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT column
        Expanded(
          child: Column(
            children: [
              for (int i = 0; i < left.length; i++) ...[
                _InspoTile(
                  radius: radius,
                  height: heightFor(i, isRight: false),
                  child: Image.network(left[i], fit: BoxFit.cover),
                ),
                if (i != left.length - 1) SizedBox(height: gap),
              ],
            ],
          ),
        ),

        SizedBox(width: gap),

        // RIGHT column (shifted down)
        Expanded(
          child: Column(
            children: [
              SizedBox(height: rightTopOffset),
              for (int i = 0; i < right.length; i++) ...[
                _InspoTile(
                  radius: radius,
                  height: heightFor(i, isRight: true),
                  child: Image.network(right[i], fit: BoxFit.cover),
                ),
                if (i != right.length - 1) SizedBox(height: gap),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InspoTile extends StatelessWidget {
  const _InspoTile({
    required this.child,
    required this.height,
    required this.radius,
  });

  final Widget child;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
