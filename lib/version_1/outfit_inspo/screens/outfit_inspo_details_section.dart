import 'package:flutter/material.dart';
import 'package:wedding_invite/version_1/outfit_inspo/data/outfit_data.dart';
import 'package:wedding_invite/version_1/outfit_inspo/screens/outfit_gallery.dart';
import 'package:wedding_invite/version_1/outfit_inspo/screens/outfit_inspo_screen.dart';
import 'package:wedding_invite/version_1/outfit_inspo/widgets/outfit_inspo_image_grid.dart';

class OutfitDetailsSection extends StatefulWidget {
  final OutfitTab gender;
  final ScrollController scrollController;
  final String eventTitle;
  const OutfitDetailsSection({
    super.key,
    required this.gender,
    required this.scrollController,
    required this.eventTitle,
  });

  @override
  State<OutfitDetailsSection> createState() => _OutfitDetailsSectionState();
}

class _OutfitDetailsSectionState extends State<OutfitDetailsSection> {
  late OutfitEventTab _tab; // Change to late

  @override
  void initState() {
    super.initState();
    // Map the string title to the enum
    _tab = _mapTitleToTab(widget.eventTitle);
  }

  // Logic to determine initial tab based on event title
  OutfitEventTab _mapTitleToTab(String title) {
    final t = title.toLowerCase();
    if (t.contains('nikkah')) return OutfitEventTab.nikkah;
    if (t.contains('reception')) return OutfitEventTab.reception;
    // Default fallback
    return OutfitEventTab.mehendi;
  }

  // Optional: Handle case where eventTitle might change while widget is alive
  @override
  void didUpdateWidget(OutfitDetailsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventTitle != widget.eventTitle) {
      setState(() {
        _tab = _mapTitleToTab(widget.eventTitle);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = OutfitDetailsRegistry.forTab(_tab);

    return Container(
      width: double.infinity,
      color: data.pageBg,
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopOutfitTabs(
            tab: _tab,
            selectedColor: data.selectedTabColor,
            unselectedColor: data.unselectedTabColor,
            onChanged: (t) => setState(() => _tab = t),
          ),
          const SizedBox(height: 30),

          // ✅ animated content swap
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 520),
            reverseDuration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,

            // 🔥 IMPORTANT: don't let the outgoing child re-layout your scroll
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },

            transitionBuilder: (child, anim) {
              // anim goes 0->1 for incoming, 1->0 for outgoing
              final fade = CurvedAnimation(
                parent: anim,
                curve: Curves.easeOutCubic,
              );

              // subtle scale only (no slide = less jank)
              final scale = Tween<double>(begin: 0.985, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              );

              return FadeTransition(
                opacity: fade,
                child: ScaleTransition(scale: scale, child: child),
              );
            },

            child: RepaintBoundary(
              key: ValueKey(_tab), // keep this
              child: _OutfitTabBody(
                data: data,
                gender: widget.gender,
                scrollController: widget.scrollController,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopOutfitTabs extends StatelessWidget {
  const _TopOutfitTabs({
    required this.tab,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onChanged,
  });

  final OutfitEventTab tab;
  final Color selectedColor;
  final Color unselectedColor;
  final ValueChanged<OutfitEventTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = OutfitEventTab.values;

    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Row(
        children: tabs.map((t) {
          final selected = t == tab;

          return GestureDetector(
            onTap: () => onChanged(t),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 26),
              child: Text(
                outfitTabLabel(t),
                style: TextStyle(
                  fontFamily: 'Montage',
                  fontSize: 22,
                  color: selected ? selectedColor : unselectedColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OutfitTabBody extends StatelessWidget {
  const _OutfitTabBody({
    super.key,
    required this.data,
    required this.gender,
    required this.scrollController,
  });

  final OutfitDetailsContent data;
  final OutfitTab gender;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IntroCard(data: data, gender: gender),
        const SizedBox(height: 18),
        _WeatherCard(data: data.weather, gender: gender),
        const SizedBox(height: 38),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            data.colorsTitle,
            style: const TextStyle(
              fontFamily: 'Montage',
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: Color(0xFF06471D),
            ),
          ),
        ),
        const SizedBox(height: 17),
        _ColorChipsRow(colors: data.colors),
        const SizedBox(height: 45),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            data.inspirationsTitle,
            style: const TextStyle(
              fontFamily: 'Montage',
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: Color(0xFF06471D),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: // In _OutfitTabBody builder:
          OutfitInspirationMasonryGrid(
            images: gender == OutfitTab.women
                ? data.inspirationImageAssetsWomen
                : gender == OutfitTab.men
                ? data.inspirationImageAssetsMen
                : data.inspirationImageAssetsKids,
            galleryId: 'mehendi_${gender.name}',
            onImageTap: (index) async {
              // 1. Scroll the background up slightly
              // You should pass the ScrollController from OutfitInspoScreen to here
              scrollController?.animateTo(
                scrollController!.offset - 520,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
              );

              // 2. Push Gallery
              await Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  barrierColor: Colors.black.withOpacity(0.1),
                  transitionDuration: const Duration(milliseconds: 900),
                  reverseTransitionDuration: const Duration(milliseconds: 900),
                  pageBuilder: (context, animation, _) => FadeTransition(
                    opacity: animation,
                    child: EventOutfitGallery(
                      images: gender == OutfitTab.women
                          ? data.inspirationImageAssetsWomen
                          : gender == OutfitTab.men
                          ? data.inspirationImageAssetsMen
                          : data.inspirationImageAssetsKids,
                      initialIndex: index,
                      galleryId: 'mehendi_${gender.name}', // Must match the tag
                    ),
                  ),
                ),
              );

              // 3. SCROLL DOWN: When gallery closes, move background back to original spot
              scrollController.animateTo(
                scrollController.offset + 520,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.data, required this.gender});
  final OutfitDetailsContent data;
  final OutfitTab gender;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(right: 24, left: 24),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: gender == OutfitTab.women
            ? data.introCardColor
            : data.introCardColorMen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.introHeadline,
            style: const TextStyle(
              fontFamily: 'SFPRO',
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 50),
          Text(
            data.introSubBold,
            style: const TextStyle(
              fontFamily: 'SFPRO',
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (data.introBody.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              data.introBody,
              style: const TextStyle(
                fontFamily: 'SFPRO',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.data, required this.gender});
  final WeatherCardData data;
  final OutfitTab gender;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(right: 24, left: 24),
      padding: const EdgeInsets.fromLTRB(21, 29, 21, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        // gradient: LinearGradient(
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        //   colors: data.gradient,
        // ),
        color: gender == OutfitTab.women
            ? data.weatherColorWomen
            : data.weatherColorMen,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: TextStyle(
                    fontFamily: 'SFPRO',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.6,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.temperature,
                  style: const TextStyle(
                    fontFamily: 'SFPRO',
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 19),
                Text(
                  data.note,
                  style: TextStyle(
                    fontFamily: 'SFPRO',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                    color: Colors.white.withOpacity(0.88),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Icon(data.icon, color: Colors.white.withOpacity(0.92), size: 34),
        ],
      ),
    );
  }
}

class _ColorChipsRow extends StatelessWidget {
  const _ColorChipsRow({required this.colors});
  final List<ColorChipData> colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: 24),
        itemCount: colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (_, i) {
          final c = colors[i];
          return Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.color,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                c.name,
                style: const TextStyle(
                  fontFamily: 'SFPRO',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// class _MasonryGrid extends StatelessWidget {
//   const _MasonryGrid({required this.images});
//   final List<String> images;

//   @override
//   Widget build(BuildContext context) {
//     // simple masonry: left column = [0,2], right column = [1,3]
//     final left = <String>[];
//     final right = <String>[];
//     for (int i = 0; i < images.length; i++) {
//       (i % 2 == 0 ? left : right).add(images[i]);
//     }

//     Widget tile(String path, {double h = 220}) {
//       return Container(
//         height: h,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(14),
//         ),
//         clipBehavior: Clip.antiAlias,
//         child: Image.network(path, fit: BoxFit.cover),
//       );
//     }

//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Expanded(
//           child: Column(
//             children: [
//               if (left.isNotEmpty) tile(left[0], h: 240),
//               if (left.length > 1) ...[
//                 const SizedBox(height: 14),
//                 tile(left[1], h: 210),
//               ],
//             ],
//           ),
//         ),
//         const SizedBox(width: 14),
//         Expanded(
//           child: Column(
//             children: [
//               if (right.isNotEmpty) tile(right[0], h: 210),
//               if (right.length > 1) ...[
//                 const SizedBox(height: 14),
//                 tile(right[1], h: 240),
//               ],
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
