import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class OutfitInspirationMasonryGrid extends StatelessWidget {
  const OutfitInspirationMasonryGrid({
    super.key,
    required this.images,
    required this.galleryId, // Unique ID for this specific grid
    this.gap = 14,
    this.radius = 8,
    this.onImageTap, // Callback to trigger the scroll + navigation
  });

  final List<String> images;
  final String galleryId;
  final double gap;
  final double radius;
  final Function(int index)? onImageTap;
  

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: gap,
      crossAxisSpacing: gap,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final h = _heightFor(index);
        final tag = "${galleryId}_${images[index]}_$index";

        return GestureDetector(
          onTap: () => onImageTap?.call(index),
          child: Hero(
            tag: tag,
            child: _InspoTile(
              radius: radius,
              height: h,
              child: Image.network(
                images[index],
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  double _heightFor(int i) {
    const a = 240.0;
    const b = 210.0;
    const c = 260.0;
    switch (i % 6) {
      case 0: return a;
      case 1: return b;
      case 2: return a;
      case 3: return a;
      case 4: return b;
      default: return c;
    }
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