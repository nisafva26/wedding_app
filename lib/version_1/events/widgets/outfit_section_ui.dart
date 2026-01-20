import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wedding_invite/version_1/events/data/event_details_modal.dart';
import 'package:wedding_invite/version_1/outfit_inspo/data/outfit_data.dart';
import 'package:wedding_invite/version_1/outfit_inspo/screens/outfit_inspo_screen.dart';

class OutfitSectionUI extends StatelessWidget {
  const OutfitSectionUI({
    required this.data,
    required this.onViewAll,
    required this.onCategoryTap,
    required this.eventType,
    required this.color,
  });

  final OutfitInspirationSection data;
  final VoidCallback onViewAll;
  final void Function(String title) onCategoryTap;
  final OutfitEventTab eventType;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final outfit = OutfitDetailsRegistry.forTab(eventType);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Outfit Inspirations',
          style: const TextStyle(
            fontSize: 20,
            color: Colors.black,
            fontFamily: 'SFPRO',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 26),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 23, 22, 22),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                outfit.introHeadline,
                style: const TextStyle(
                  fontSize: 20,
                  // height: 1.15,
                  color: Colors.black,
                  fontFamily: 'SFPRO',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 60),
              Text(
                outfit.introSubBold,
                style: const TextStyle(
                  fontFamily: 'SFPRO',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (outfit.introBody.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  outfit.introBody,
                  style: const TextStyle(
                    fontSize: 14,
                    // height: 1.35,
                    color: Colors.black,
                    fontFamily: 'SFPRO',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                 const SizedBox(height: 16),
              ],

             

              _ImageCarousel(urls: outfit.inspirationImageAssetsWomen),
              const SizedBox(height: 30),

              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onViewAll,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "View All",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF06471D),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: Color(0xFF06471D),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 26),

        // 3 category cards row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: data.categories.map((c) {
            return Expanded(
              child: GestureDetector(
                onTap: () => onCategoryTap(c.title),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _OutfitCategoryMiniCard(card: c),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.urls});
  final List<String> urls;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  late final PageController _pc;
  late final Timer _timer;

  int _i = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController();

    // AUTO SCROLL
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || widget.urls.isEmpty) return;

      final next = (_i + 1) % widget.urls.length;

      _pc.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AspectRatio(
            aspectRatio: 340 / 360,
            child: PageView.builder(
              controller: _pc,

              itemCount: widget.urls.length,
              onPageChanged: (v) => setState(() => _i = v),
              itemBuilder: (_, index) =>
                  Image.network(widget.urls[index], fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.urls.length, (idx) {
                final active = idx == _i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(active ? 0.95 : 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutfitCategoryMiniCard extends StatelessWidget {
  const _OutfitCategoryMiniCard({required this.card});
  final OutfitCategoryCard card;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          height: 165,
          child: Image.asset(card.imageUrl, fit: BoxFit.contain),
        ),
        const SizedBox(height: 10),
        Text(
          "${card.title} →",
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Montage',
            color: card.title == "Women"
                ? const Color(0xFF6B1842)
                : card.title == "Men"
                ? const Color(0xFF7A4A1A)
                : const Color(0xFF0B5E2A),
          ),
        ),
      ],
    );
  }
}
