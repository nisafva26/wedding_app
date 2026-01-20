import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class OutfitInspirationsSection extends StatefulWidget {
  const OutfitInspirationsSection({
    super.key,
    required this.onWomenTap,
    required this.onMenTap,
    required this.onKidsTap,
    required this.onViewAllTap,
  });

  final VoidCallback onWomenTap;
  final VoidCallback onMenTap;
  final VoidCallback onKidsTap;
  final VoidCallback onViewAllTap;

  @override
  State<OutfitInspirationsSection> createState() =>
      _OutfitInspirationsSectionState();
}

class _OutfitInspirationsSectionState extends State<OutfitInspirationsSection>
    with TickerProviderStateMixin {
  bool _played = false;

  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _slideTitle;
  late final Animation<double> _slideWomen;
  late final Animation<double> _slideMen;
  late final Animation<double> _slideKids;
  late final Animation<double> _slideButton;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

    // Stagger: title first, then cards, then button
    _slideTitle = Tween<double>(begin: 26, end: 0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.00, 0.40, curve: Curves.easeOutCubic),
      ),
    );
    _slideWomen = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.10, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _slideMen = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.20, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _slideKids = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.30, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _slideButton = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.45, 1.00, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _playOnce() {
    if (_played) return;
    _played = true;
    _c.forward();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('outfit_inspirations_section'),
      onVisibilityChanged: (info) {
        // Trigger when at least 25% is visible
        if (info.visibleFraction >= 0.25) {
          _playOnce();
        }
      },
      child: Container(
        color: const Color(0xFFECFFF3), // mint background
        // padding: const EdgeInsets.fromLTRB(20, 64, 20, 26),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),

        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final opacity = _fade.value.clamp(0.0, 1.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transform.translate(
                //   offset: Offset(0, _slideTitle.value),
                //   child: Opacity(
                //     opacity: opacity,
                //     child: const Text(
                //       "Outfit\ninspirations",
                //       style: TextStyle(
                //         fontSize: 40,
                //         fontFamily: 'Montage',
                //         height: 1.02,
                //         fontWeight: FontWeight.w500,
                //         color: Color(0xFF06471D),
                //         // fontFamily: "YourSerifFont",
                //       ),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 18),

                // Row 1: Women (left) + Men (right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Transform.translate(
                        offset: Offset(0, _slideWomen.value),
                        child: Opacity(
                          opacity: opacity,
                          child: _OutfitTile(
                            imageAsset: "assets/images/outfit_women.png",
                            bgImage: 'assets/images/outfit_women_vector.png',
                            label: "Women",
                            labelColor: const Color(0xFF6F2041),
                            borderColor: const Color(0xFF6F2041),
                            onTap: widget.onWomenTap,
                            shape: _OutfitShape.scallopTall,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 86,
                        ), // match your layout offset
                        child: Transform.translate(
                          offset: Offset(0, _slideMen.value),
                          child: Opacity(
                            opacity: opacity,
                            child: _OutfitTile(
                              imageAsset: "assets/images/outfit_men.png",
                              label: "Men",
                              bgImage: 'assets/images/outfit_men_vector.png',
                              labelColor: const Color(0xFF7A5A2E),
                              borderColor: const Color(0xFF7A5A2E),
                              onTap: widget.onMenTap,
                              shape: _OutfitShape.scallopTall,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Kids (bottom-left)
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.52,
                    child: Transform.translate(
                      offset: Offset(0, _slideKids.value),
                      child: Opacity(
                        opacity: opacity,
                        child: _OutfitTile(
                          imageAsset: "assets/images/outfit_kid.png",
                          bgImage: 'assets/images/outfit_kid_vector.png',
                          label: "Kids",
                          labelColor: const Color(0xFF1F4D35),
                          borderColor: const Color(0xFF1F4D35),
                          onTap: widget.onKidsTap,
                          shape: _OutfitShape.flower,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // View All (bottom-right)
                Align(
                  alignment: Alignment.centerRight,
                  child: Transform.translate(
                    offset: Offset(0, _slideButton.value),
                    child: Opacity(
                      opacity: opacity,
                      child: _GreenViewAllButton(onTap: widget.onViewAllTap),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _OutfitShape { scallopTall, wavyRect, flower }

class _OutfitTile extends StatelessWidget {
  const _OutfitTile({
    required this.imageAsset,
    required this.bgImage,
    required this.label,
    required this.labelColor,
    required this.borderColor,
    required this.onTap,
    required this.shape,
  });

  final String imageAsset;
  final String label;
  final Color labelColor;
  final Color borderColor;
  final VoidCallback onTap;
  final _OutfitShape shape;
  final String bgImage;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(bgImage),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  decoration: BoxDecoration(
                    // border: Border.all(color: borderColor.withOpacity(0.75), width: 6),
                  ),
                  child: Image.asset(imageAsset, fit: BoxFit.contain),
                ),
              ),
            ],
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontFamily: 'Montage',
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  // fontFamily: "YourSerifFont",
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 22, color: labelColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _GreenViewAllButton extends StatelessWidget {
  const _GreenViewAllButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F4D35),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 10),
              color: Colors.black.withOpacity(0.16),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "View All",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
