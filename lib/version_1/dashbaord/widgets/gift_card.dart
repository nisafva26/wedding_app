import 'package:flutter/material.dart';

class GiftCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String heroTag;
  final String description;
  final bool showArrow;
  final VoidCallback onTap;

  const GiftCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.showArrow = false, required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(29, 20, 16, 34),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.05),
          //     blurRadius: 10,
          //     offset: const Offset(0, 4),
          //   ),
          // ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top-Left Icon
                    Icon(icon, color: Colors.white, size: 36),
                
                    // Top-Right Arrow (Only if interactive)
                    if (showArrow)
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 24,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Hero(
              tag: heroTag,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'SFPRO',
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.4,
                fontFamily: 'SFPRO',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
