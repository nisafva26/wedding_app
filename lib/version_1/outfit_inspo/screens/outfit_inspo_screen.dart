import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wedding_invite/version_1/events/screens/event_details_screen_v1.dart';
import 'package:wedding_invite/version_1/outfit_inspo/screens/outfit_inspo_details_section.dart';

enum OutfitTab { men, women, kids }

String _tabLabel(OutfitTab t) => switch (t) {
  OutfitTab.men => "Men",
  OutfitTab.women => "Women",
  OutfitTab.kids => "Kids",
};

String _tabImageAsset(OutfitTab t) => switch (t) {
  OutfitTab.men => "assets/images/men_detail.png",
  OutfitTab.women => "assets/images/women_detail.png",
  OutfitTab.kids => "assets/images/men_detail.png",
};

class OutfitInspoScreen extends StatefulWidget {
  const OutfitInspoScreen({
    super.key,
    this.initialTab = OutfitTab.women,
    required this.heroTag, required this.eventTitle,
  });

  final OutfitTab initialTab;
  final String heroTag;
  final String eventTitle;

  @override
  State<OutfitInspoScreen> createState() => _OutfitInspoScreenState();
}

class _OutfitInspoScreenState extends State<OutfitInspoScreen> {
  late AnimationController _sheetController;
  late final ScrollController _scrollController;

  late OutfitTab _outfitTab; // ✅ no default here

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // ✅ take from previous screen
    _outfitTab = widget.initialTab;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // backgroundColor: widget.headerBgColor,
      backgroundColor: Color(0xffECFFF3),
      body: CustomScrollView(
        controller: _scrollController, // ✅ important
        physics: const BouncingScrollPhysics(),

        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // --- Animated hero image with bottom wave clip ---
                ClipPath(
                  clipper: TripleWaveBottomClipper(
                    waveHeight: 24,
                    amplitude: 18,
                  ),
                  child: Hero(
                    tag: widget.heroTag,
                    flightShuttleBuilder:
                        (
                          flightContext,
                          animation,
                          flightDirection,
                          fromHeroContext,
                          toHeroContext,
                        ) {
                          // Keeps it smooth and prevents weird “square” flashes
                          return FadeTransition(
                            opacity: CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            ),
                            child: toHeroContext.widget,
                          );
                        },
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 520),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        transitionBuilder: (child, anim) {
                          final fade = CurvedAnimation(
                            parent: anim,
                            curve: Curves.easeOut,
                          );
                          final scale = Tween<double>(begin: 1.03, end: 1.0)
                              .animate(
                                CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOutCubic,
                                ),
                              );
                          return FadeTransition(
                            opacity: fade,
                            child: ScaleTransition(scale: scale, child: child),
                          );
                        },
                        child: Image.asset(
                          _tabImageAsset(_outfitTab),
                          key: ValueKey(_outfitTab),
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                  ),
                ),

                // --- Top Back Button + Tabs ---
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: IconButton(
                            onPressed: () async {
                              _sheetController.reverse();

                              // 2. Wait for the slide-down to finish (600ms matching the duration above)
                              await Future.delayed(300.ms);
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 38),

                        // Tabs row overlayed at mid like screenshot
                        _OutfitOverlayTabs(
                          selected: _outfitTab,
                          onChanged: (t) => setState(() => _outfitTab = t),
                        ),

                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. THE WAVY SHEET (SCROLLABLE)
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                      width: double.infinity,
                      // padding: const EdgeInsets.fromLTRB(24, 80, 24, 60),
                      child: OutfitDetailsSection(gender: _outfitTab,scrollController: _scrollController,eventTitle: widget.eventTitle,),
                    )
                    .animate(onInit: (c) => _sheetController = c)
                    .fadeIn(duration: 400.ms, delay: 300.ms)
                    .slideY(
                      begin: 0.5,
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

class _OutfitOverlayTabs extends StatelessWidget {
  const _OutfitOverlayTabs({required this.selected, required this.onChanged});

  final OutfitTab selected;
  final ValueChanged<OutfitTab> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(OutfitTab t, {required Alignment align}) {
      final isSelected = t == selected;

      return Align(
        alignment: align,
        child: GestureDetector(
          onTap: () => onChanged(t),
          behavior: HitTestBehavior.opaque,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontFamily: 'Montage',
              fontSize: isSelected ? 40 : 20,
              color: Colors.white.withOpacity(isSelected ? 1.0 : 0.55),
              height: 1.0,
            ),
            child: Text(_tabLabel(t)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 70,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Stack(
          children: [
            tab(OutfitTab.men, align: Alignment.centerLeft),
            tab(OutfitTab.women, align: Alignment.center),
            tab(OutfitTab.kids, align: Alignment.centerRight),
          ],
        ),
      ),
    );
  }
}

class TripleWaveBottomClipper extends CustomClipper<Path> {
  TripleWaveBottomClipper({this.waveHeight = 40, this.amplitude = 25});

  final double waveHeight; // how far up from bottom the wave sits
  final double amplitude; // wave depth

  @override
  Path getClip(Size size) {
    final path = Path();

    final baseY = size.height - waveHeight;
    final amp = amplitude.clamp(0.0, waveHeight);

    // Start top-left
    path.moveTo(0, 0);
    // Down to start of wave line
    path.lineTo(0, baseY);

    final segmentWidth = size.width / 3;

    for (int i = 0; i < 3; i++) {
      final startX = i * segmentWidth;

      // crest (downwards)
      path.quadraticBezierTo(
        startX + segmentWidth / 4,
        baseY + amp,
        startX + segmentWidth / 2,
        baseY,
      );

      // trough (upwards)
      path.quadraticBezierTo(
        startX + 3 * segmentWidth / 4,
        baseY - amp,
        startX + segmentWidth,
        baseY,
      );
    }

    // Finish rectangle to top-right
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant TripleWaveBottomClipper oldClipper) {
    return oldClipper.waveHeight != waveHeight ||
        oldClipper.amplitude != amplitude;
  }
}
