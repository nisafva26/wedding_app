import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wedding_invite/version_1/outfit_inspo/data/outfit_data.dart';
import 'package:wedding_invite/version_1/outfit_inspo/screens/outfit_gallery.dart';
import 'package:wedding_invite/version_1/outfit_inspo/screens/outfit_inspo_screen.dart';
import 'package:wedding_invite/version_1/outfit_inspo/widgets/outfit_inspo_image_grid.dart';

enum OutfitEntryMode { general, eventOnly }

class OutfitDetailsSection extends StatefulWidget {
  final OutfitTab gender;
  final ScrollController scrollController;

  /// Only used to choose initial tab in general mode (optional)
  final String eventTitle;

  /// Invited tabs (used only when entryMode == general)
  final List<OutfitEventTab> allowedTabs;

  /// ✅ NEW
  final OutfitEntryMode entryMode;

  /// ✅ NEW (used when entryMode == eventOnly)
  final OutfitEventTab event;

  const OutfitDetailsSection({
    super.key,
    required this.gender,
    required this.scrollController,
    required this.eventTitle,
    required this.allowedTabs,
    this.entryMode = OutfitEntryMode.general,
    this.event = OutfitEventTab.mehendi,
  });

  @override
  State<OutfitDetailsSection> createState() => _OutfitDetailsSectionState();
}

class _OutfitDetailsSectionState extends State<OutfitDetailsSection> {
  late OutfitEventTab _tab;

  List<OutfitEventTab> get _effectiveTabs {
    if (widget.entryMode == OutfitEntryMode.eventOnly) {
      return [widget.event]; // ✅ only that event
    }
    return widget.allowedTabs; // ✅ invited tabs
  }

  @override
  void initState() {
    super.initState();
    _tab = _resolveInitialTab(
      title: widget.eventTitle,
      effectiveTabs: _effectiveTabs,
      entryMode: widget.entryMode,
      forcedEvent: widget.event,
    );
  }

  OutfitEventTab _resolveInitialTab({
    required String title,
    required List<OutfitEventTab> effectiveTabs,
    required OutfitEntryMode entryMode,
    required OutfitEventTab forcedEvent,
  }) {
    if (effectiveTabs.isEmpty) return OutfitEventTab.mehendi;

    // If eventOnly, always lock to event
    if (entryMode == OutfitEntryMode.eventOnly) return forcedEvent;

    // General mode: try to map title -> tab, else fallback to first invited
    final preferred = _mapTitleToTab(title);
    if (effectiveTabs.contains(preferred)) return preferred;

    return effectiveTabs.first;
  }

  OutfitEventTab _mapTitleToTab(String title) {
    final t = title.toLowerCase();
    if (t.contains('nikkah')) return OutfitEventTab.nikkah;
    if (t.contains('reception')) return OutfitEventTab.reception;
    return OutfitEventTab.mehendi;
  }

  @override
  void didUpdateWidget(covariant OutfitDetailsSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    final effectiveTabsChanged =
        oldWidget.entryMode != widget.entryMode ||
        oldWidget.event != widget.event ||
        oldWidget.allowedTabs != widget.allowedTabs;

    final titleChanged = oldWidget.eventTitle != widget.eventTitle;

    if (effectiveTabsChanged || titleChanged) {
      final next = _resolveInitialTab(
        title: widget.eventTitle,
        effectiveTabs: _effectiveTabs,
        entryMode: widget.entryMode,
        forcedEvent: widget.event,
      );

      // If current tab isn't in the new tabs list, or needs update
      if (!_effectiveTabs.contains(_tab) || _tab != next) {
        setState(() => _tab = next);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTabs = _effectiveTabs;

    if (effectiveTabs.isEmpty) {
      return const SizedBox.shrink();
    }

    final data = OutfitDetailsRegistry.forTab(_tab);

    log('selected tab : ${_tab}');

    return Container(
      width: double.infinity,
      color: data.pageBg,
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Always show tabs, but with effectiveTabs (1 tab in eventOnly)
          _TopOutfitTabs(
            tabs: effectiveTabs,
            tab: _tab,
            selectedColor: data.selectedTabColor,
            unselectedColor: data.unselectedTabColor,
            onChanged: (t) {
              // ✅ Block switching in eventOnly (even though only 1 tab)
              if (widget.entryMode == OutfitEntryMode.eventOnly) return;
              setState(() => _tab = t);
            },
          ),
          const SizedBox(height: 30),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 520),
            reverseDuration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
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
              final fade = CurvedAnimation(
                parent: anim,
                curve: Curves.easeOutCubic,
              );
              final scale = Tween<double>(begin: 0.985, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              );
              return FadeTransition(
                opacity: fade,
                child: ScaleTransition(scale: scale, child: child),
              );
            },
            child: RepaintBoundary(
              key: ValueKey(_tab),
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
    required this.tabs,
    required this.tab,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onChanged,
  });

  final List<OutfitEventTab> tabs;
  final OutfitEventTab tab;
  final Color selectedColor;
  final Color unselectedColor;
  final ValueChanged<OutfitEventTab> onChanged;

  @override
  Widget build(BuildContext context) {
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
            images: kIsWeb
                ? gender == OutfitTab.women
                      ? data.inspirationImageWebAssetsWomen
                      : gender == OutfitTab.men
                      ? data.inspirationImageWebAssetsMen
                      : data.inspirationImageWebAssetsKids
                : gender == OutfitTab.women
                ? data.inspirationImageAssetsWomen
                : gender == OutfitTab.men
                ? data.inspirationImageAssetsMen
                : data.inspirationImageAssetsKids,
            galleryId: 'mehendi_${gender.name}',
            onImageTap: (index) async {
              // 1. Scroll the background up slightly
              // You should pass the ScrollController from OutfitInspoScreen to here
              scrollController.animateTo(
                scrollController.offset - 520,
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
                      images: kIsWeb
                          ? gender == OutfitTab.women
                                ? data.inspirationImageWebAssetsWomen
                                : gender == OutfitTab.men
                                ? data.inspirationImageWebAssetsMen
                                : data.inspirationImageWebAssetsKids
                          : gender == OutfitTab.women
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
            : gender == OutfitTab.men
            ? data.introCardColorMen
            : data.introCardColorKid,
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
            : gender == OutfitTab.men
            ? data.weatherColorMen
            : data.weatherColorKid,
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
