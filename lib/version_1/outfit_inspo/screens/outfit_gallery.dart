import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EventOutfitGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String galleryId;

  const EventOutfitGallery({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.galleryId,
  });

  @override
  State<EventOutfitGallery> createState() => _EventOutfitGalleryState();
}

class _EventOutfitGalleryState extends State<EventOutfitGallery> {
  late PageController _pageController;
  late ValueNotifier<int> _currentPageNotifier;

  @override
  void initState() {
    super.initState();
    // viewportFraction < 1.0 creates the "peek" effect for side images
    _pageController = PageController(
      initialPage: widget.initialIndex,
      viewportFraction: 0.88,
    );
    _currentPageNotifier = ValueNotifier(widget.initialIndex);

    _pageController.addListener(() {
      final next = _pageController.page?.round() ?? 0;
      if (_currentPageNotifier.value != next) {
        _currentPageNotifier.value = next;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Match your brown overlay
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ), // Blur: 50 from Figma
              child: Container(
                // Hex #331717 at 90% Opacity
                color: const Color(0xE6331717),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. The Swipable Hero Images with Viewport Peek
                Center(
                  child: SizedBox(
                    height:
                        MediaQuery.of(context).size.height *
                        0.65, // Adjust height to match UI
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.images.length,
                      clipBehavior:
                          Clip.none, // Allows images to bleed into margins
                      itemBuilder: (context, index) {
                        final heroTag =
                            "${widget.galleryId}_${widget.images[index]}_$index";

                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            // Optional: subtle scale effect for the active item
                            return child!;
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: Hero(
                              tag: heroTag,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.network(
                                        widget.images[index],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    // The download button seen in the screenshot
                                    Positioned(
                                      bottom: 20,
                                      right: 20,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.file_download_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // 2. Footer UI
                Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Navigation Controls
                          // The Navigation Pill Container
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              // A dark, slightly transparent brown to match the theme
                              color: Color(0xff4b3836),
                              borderRadius: BorderRadius.circular(
                                100,
                              ), // Pill shape
                            ),

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Left Navigation Button
                                _NavButton(
                                  icon: Icons.chevron_left,
                                  onTap: () => _pageController.previousPage(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  ),
                                ),

                                // Page Indicator Text
                                ValueListenableBuilder<int>(
                                  valueListenable: _currentPageNotifier,
                                  builder: (context, value, _) => RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFamily:
                                            'SFPRO', // Use your project font
                                      ),
                                      children: [
                                        TextSpan(
                                          text: "${value + 1} ",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: "of ",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                        TextSpan(
                                          text: "${widget.images.length}",
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Right Navigation Button
                                _NavButton(
                                  icon: Icons.chevron_right,
                                  onTap: () => _pageController.nextPage(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Close Button
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Column(
                              children: [
                                Container(
                                  height: 60,
                                  width: 60,
                                  // padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.8),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Close",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                    fontFamily: 'SFPRO',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // const SizedBox(height: 30),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(
                      duration: 600.ms,
                      delay: 400.ms,
                    ) // Soft entry after the Hero flight starts
                    .slideY(
                      begin: 0.3,
                      end: 0,
                      duration: 800.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
