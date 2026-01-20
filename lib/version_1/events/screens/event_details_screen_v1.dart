import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:wedding_invite/version_1/events/data/event_details_modal.dart';
import 'package:wedding_invite/version_1/events/widgets/countdown_timer.dart';
import 'package:wedding_invite/version_1/events/widgets/event_details_ui.dart';
import 'package:wedding_invite/version_1/events/widgets/event_flow_section_ui.dart';
import 'package:wedding_invite/version_1/events/widgets/outfit_section_ui.dart';
import 'package:wedding_invite/version_1/outfit_inspo/data/outfit_data.dart';
import 'package:wedding_invite/version_1/outfit_inspo/screens/outfit_inspo_screen.dart';

class EventDetailsScreenV1 extends StatefulWidget {
  const EventDetailsScreenV1({
    super.key,
    required this.eventTitle,
    required this.venue,
    required this.dateTime,
    required this.description,
    required this.detailsHeadline,
    required this.locationTitle,
    required this.locationSubtitle,
    required this.locationImageUrl,
    required this.headerBgColor,
    required this.accentGold,
    required this.onBack,
    required this.content,
    required this.eventIcon,
    required this.textColor,
  });

  final String eventTitle,
      description,
      detailsHeadline,
      locationTitle,
      locationSubtitle,
      locationImageUrl;
  final String? venue;
  final DateTime dateTime;
  final Color headerBgColor, accentGold;
  final VoidCallback onBack;
  final EventDetailsContent content;
  final String eventIcon;
  final Color textColor;

  @override
  State<EventDetailsScreenV1> createState() => _EventDetailsScreenV1State();
}

class _EventDetailsScreenV1State extends State<EventDetailsScreenV1>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _sheetController;
  late AnimationController _tabController;

  late final ScrollController _scrollController;

  final _detailsKey = GlobalKey();
  final _outfitKey = GlobalKey();
  final _eventKey = GlobalKey();

  static const double _scrollTopPadding = 0; // tweak if needed

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
    _scrollController = ScrollController();
  }

  Future<void> _scrollTo(GlobalKey key) async {
    // Wait for tab color update / layout
    await Future.delayed(const Duration(milliseconds: 20));

    final ctx = key.currentContext;
    if (ctx == null) return;

    await Scrollable.ensureVisible(
      ctx,
      alignment: 0.0, // top of viewport
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
    );

    // Optional: small nudge up so it looks premium (because ensureVisible can land slightly low)
    final target = (_scrollController.offset - _scrollTopPadding).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if ((_scrollController.offset - target).abs() > 2) {
      await _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Route _outfitInspoRoute({
    required OutfitTab initialTab,
    required String heroTag,
    required String eventTitle,
  }) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      reverseTransitionDuration: const Duration(milliseconds: 520),
      pageBuilder: (_, __, ___) => OutfitInspoScreen(
        initialTab: initialTab,
        heroTag: heroTag,
        eventTitle: eventTitle,
      ),
      opaque: true,
      barrierColor: Colors.black.withOpacity(0.02),
      transitionsBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
        final scale = Tween<double>(begin: 0.985, end: 1.0).animate(curved);
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curved);

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: ScaleTransition(scale: scale, child: child),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    log('datetime : ${widget.dateTime}');
    log('title : ${widget.eventTitle}');

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController, // ✅ important
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. THE HEADER SECTION
          SliverToBoxAdapter(
            child: Container(
              color: widget.content.details.mainColor,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, topPad, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopNav(widget.textColor),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        widget.eventTitle.toLowerCase() == 'nikah' ||
                                widget.eventTitle.toLowerCase() == 'nikkah'
                            ? Image.asset(widget.eventIcon)
                            : SvgPicture.asset(
                                widget.eventIcon,
                                color: Colors.white,
                              ),
                        Spacer(),

                        ToGoCountdownPill(
                          target: widget.dateTime,
                          primaryColor: widget.content.details.timePrimaryColor,
                          secondaryColor:
                              widget.content.details.timeSecondaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.eventTitle,
                      style: TextStyle(
                        fontSize: 52,
                        color: Colors.white,
                        fontFamily: 'Montage',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _infoRow(
                      Icons.calendar_today_outlined,
                      DateFormat("dd MMM yyyy").format(widget.dateTime),
                      Colors.white,
                    ),
                    _infoRow(
                      Icons.access_time,
                      "${DateFormat("h a").format(widget.dateTime)} onwards",
                      Colors.white,
                    ),
                    _infoRow(
                      Icons.location_on_outlined,
                      widget.venue ?? "",
                      Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. THE ANIMATED PINNED SECTION
          // We wrap the following slivers in a MainAxisGroup to animate them together
          SliverMainAxisGroup(
            slivers: [
              // THE PINNED TAB BAR
              SliverPersistentHeader(
                pinned: true,
                delegate: _WavyTabDelegate(
                  mainColor: widget.content.details.mainColor,
                  tabWidget: _buildTabs()
                      .animate(
                        onInit: (controller) => _tabController = controller,
                        // delay: 500.ms,
                      ) // Start the animation chain
                      .fadeIn(
                        duration: 400.ms,
                        delay: 100.ms,
                      ) // Fade in after 300ms
                      .slideY(
                        begin: 0.5, // Start from 50% of its height lower
                        end: 0,
                        duration: 800.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ),
              ),

              // THE WHITE CONTENT AREA
              SliverToBoxAdapter(
                child:
                    Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 15),
                              // DETAILS
                              KeyedSubtree(
                                key: _detailsKey,
                                child: DetailsSectionUI(
                                  data: widget.content.details,
                                  onDirectionsTap: () {},
                                  color: widget.content.details.detailsColor,
                                  title: widget.eventTitle.toLowerCase(),
                                ),
                              ),
                              const SizedBox(height: 63),
                              // OUTFIT
                              KeyedSubtree(
                                key: _outfitKey,
                                child: OutfitSectionUI(
                                  data: widget.content.outfit,
                                  onCategoryTap: (title) {
                                    log('title : $title');
                                    final tag =
                                        "outfit-hero-${title.toLowerCase()}";
                                    Navigator.of(context).push(
                                      _outfitInspoRoute(
                                        initialTab:
                                            title.toLowerCase() == 'women'
                                            ? OutfitTab.women
                                            : title.toLowerCase() == 'men'
                                            ? OutfitTab.men
                                            : OutfitTab.kids,
                                        heroTag: tag,
                                        eventTitle: widget.eventTitle
                                            .toLowerCase(),
                                      ),
                                    );
                                  },
                                  onViewAll: () {},
                                  eventType:
                                      widget.eventTitle.toLowerCase() ==
                                          'mehendi'
                                      ? OutfitEventTab.mehendi
                                      : OutfitEventTab.reception,
                                  color:
                                      widget.content.details.outfitSectionColor,
                                ),
                              ),
                              const SizedBox(height: 60),
                              // EVENT FLOW
                              KeyedSubtree(
                                key: _eventKey,
                                
                                child: EventFlowSectionUI(
                                  data: widget.content.flow,
                                  color: widget.content.details.detailsColor,
                                ),
                              ),
                              const SizedBox(
                                height: 100,
                              ), // Bottom padding for scroll room
                            ],
                          ),
                        )
                        .animate(
                          onInit: (controller) => _sheetController = controller,
                          // delay: 500.ms,
                        ) // Start the animation chain
                        .fadeIn(
                          duration: 400.ms,
                          delay: 300.ms,
                        ) // Fade in after 300ms
                        .slideY(
                          begin: 0.5, // Start from 50% of its height lower
                          end: 0,
                          duration: 800.ms,
                          curve: Curves.easeOutCubic,
                        ),
              ),
            ],
          ),

          // // 2. THE WAVY SHEET (SCROLLABLE)
          // SliverToBoxAdapter(
          //   child: Stack(
          //     children: [
          //       // This ensures the background color behind the waves matches the header
          //       Container(height: 100, color: widget.content.details.mainColor),
          //       ClipPath(
          //             clipper: TripleWaveClipper(),
          //             child: Container(
          //               width: double.infinity,
          //               color: Colors.white,
          //               padding: const EdgeInsets.fromLTRB(24, 80, 24, 60),
          //               child: Column(
          //                 crossAxisAlignment: CrossAxisAlignment.start,
          //                 children: [
          //                   _buildTabs(),
          //                   const SizedBox(height: 30),
          //                   // DETAILS anchor
          //                   KeyedSubtree(
          //                     key: _detailsKey,
          //                     child: DetailsSectionUI(
          //                       data: widget.content.details,
          //                       onDirectionsTap: () {},
          //                     ),
          //                   ),

          //                   const SizedBox(height: 63),

          //                   // OUTFIT anchor
          //                   KeyedSubtree(
          //                     key: _outfitKey,
          //                     child: OutfitSectionUI(
          //                       data: widget.content.outfit,
          //                       onCategoryTap: (title) {
          //                         log('title : $title');
          //                         final tag =
          //                             "outfit-hero-${title.toLowerCase()}";
          //                         Navigator.of(context).push(
          //                           _outfitInspoRoute(
          //                             initialTab: title.toLowerCase() == 'women'
          //                                 ? OutfitTab.women
          //                                 : title.toLowerCase() == 'men'
          //                                 ? OutfitTab.men
          //                                 : OutfitTab.kids,
          //                             heroTag: tag,
          //                             eventTitle: widget.eventTitle
          //                                 .toLowerCase(),
          //                           ),
          //                         );
          //                       },
          //                       onViewAll: () {},
          //                       eventType:
          //                           widget.eventTitle.toLowerCase() == 'mehendi'
          //                           ? OutfitEventTab.mehendi
          //                           : widget.eventTitle.toLowerCase() ==
          //                                 'nikkah'
          //                           ? OutfitEventTab.nikkah
          //                           : OutfitEventTab.reception,
          //                     ),
          //                   ),

          //                   const SizedBox(height: 60),

          //                   // EVENT FLOW anchor
          //                   KeyedSubtree(
          //                     key: _eventKey,
          //                     child: EventFlowSectionUI(
          //                       data: widget.content.flow,
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             ),
          //           )
          //           .animate(
          //             onInit: (controller) => _sheetController = controller,
          //             // delay: 500.ms,
          //           ) // Start the animation chain
          //           .fadeIn(
          //             duration: 400.ms,
          //             delay: 300.ms,
          //           ) // Fade in after 300ms
          //           .slideY(
          //             begin: 0.5, // Start from 50% of its height lower
          //             end: 0,
          //             duration: 800.ms,
          //             curve: Curves.easeOutCubic,
          //           ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildTopNav(Color color) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: color),
      onPressed: () async {
        // 1. Play the sheet animation backwards (slides down)
        _tabController.reverse();
        _sheetController.reverse();

        // 2. Wait for the slide-down to finish (600ms matching the duration above)
        await Future.delayed(500.ms);

        // 3. Finally trigger the OpenContainer's close callback
        widget.onBack();
      },
    );
  }

  Widget _infoRow(IconData icon, String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: ["Details", "Outfit", "Event"].asMap().entries.map((e) {
        final selected = _tab == e.key;

        return GestureDetector(
          onTap: () async {
            setState(() => _tab = e.key);

            if (e.key == 0) {
              await _scrollTo(_detailsKey);
            } else if (e.key == 1) {
              await _scrollTo(_outfitKey);
            } else {
              await _scrollTo(_eventKey);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              e.value,
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'Montage',
                color: selected
                    ? widget.content.details.mainColor
                    : Colors.black12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBF2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.detailsHeadline,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A0E2E),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.description,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "About the location",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            widget.locationImageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.locationTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          widget.locationSubtitle,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

class TripleWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, 40);
    double x = 0;
    double y = 40;
    double amplitude = 25;
    double segmentWidth = size.width / 3;

    for (int i = 0; i < 3; i++) {
      path.relativeQuadraticBezierTo(
        segmentWidth / 4,
        -amplitude,
        segmentWidth / 2,
        0,
      );
      path.relativeQuadraticBezierTo(
        segmentWidth / 4,
        amplitude,
        segmentWidth / 2,
        0,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// --- Helper UI Components ---

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }
}

class _CountdownPill extends StatelessWidget {
  final int days, hours;
  const _CountdownPill({required this.days, required this.hours});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text(
            "To go ",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          _timeUnit(days.toString(), "Days"),
          Container(
            width: 1,
            height: 20,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          _timeUnit(hours.toString(), "Hours"),
        ],
      ),
    );
  }

  Widget _timeUnit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

class _WavyTabDelegate extends SliverPersistentHeaderDelegate {
  final Color mainColor;
  final Widget tabWidget;

  _WavyTabDelegate({required this.mainColor, required this.tabWidget});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // shrinkOffset represents how much the user has scrolled this specific header.
    // We use it to fade the wave background out as it pins.
    double waveHeight = 80.0;

    return Stack(
      children: [
        // Background purple color that shows behind the wave
        Container(height: waveHeight, color: mainColor),

        // The White Sheet with Waves
        ClipPath(
          clipper: TripleWaveClipper(),
          child: Container(
            width: double.infinity,
            color: Colors.white,
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 15),
            child: tabWidget,
          ),
        ),
      ],
    );
  }

  @override
  double get maxExtent => 130.0; // Height when fully expanded (wave + tabs)
  @override
  double get minExtent => 130.0; // Height when pinned at the top

  @override
  bool shouldRebuild(covariant _WavyTabDelegate oldDelegate) => true;
}
