import 'dart:developer';
import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:wedding_invite/feature/auth/widgets/gear_loop_rotation.dart';
import 'package:wedding_invite/version_1/dashbaord/models/wedding_rsvp_model.dart';
import 'package:wedding_invite/version_1/dashbaord/providers/event_provider.dart';
import 'package:wedding_invite/version_1/dashbaord/providers/user_provider.dart';
import 'package:wedding_invite/version_1/dashbaord/screens/event_details_user_v1.dart'
    hide WaveSeparator;
import 'package:wedding_invite/version_1/dashbaord/screens/outfit-inspiration_screen.dart';
import 'package:wedding_invite/version_1/dashbaord/widgets/event_sticky_header.dart';
import 'package:wedding_invite/version_1/dashbaord/widgets/expandable_section.dart';
import 'package:wedding_invite/version_1/dashbaord/widgets/flip.dart';
import 'package:wedding_invite/version_1/dashbaord/widgets/gift_card.dart';
import 'package:wedding_invite/version_1/dashbaord/widgets/staggered_slide_entrance.dart';
import 'package:wedding_invite/version_1/dashbaord/widgets/wave_seperator.dart';
import 'package:wedding_invite/version_1/events/data/event_details_modal.dart';
import 'package:wedding_invite/version_1/events/screens/event_details_screen_v1.dart';
import 'package:wedding_invite/version_1/gifts/screens/cash_gift_screen.dart';
import 'package:wedding_invite/version_1/gifts/screens/gift_screen.dart';
import 'package:wedding_invite/version_1/outfit_inspo/screens/outfit_inspo_screen.dart';

class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() =>
      _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen> {
  bool _userEnsured = false;
  ProviderSubscription<AsyncValue<RsvpModel?>>? _rsvpSub;
  final ScrollController _scrollController = ScrollController();
  // final GlobalKey _eventsKey = GlobalKey();

  // 1. Define GlobalKeys for each section
  final GlobalKey _eventsKey = GlobalKey();
  final GlobalKey _outfitKey = GlobalKey();
  final GlobalKey _giftsKey = GlobalKey();

  double contHeight = 300;

  // NEW: 0..1 progress based on scroll offset
  final ValueNotifier<double> _introProgress = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);

    // ✅ listen in initState using listenManual
    _rsvpSub = ref.listenManual<AsyncValue<RsvpModel?>>(userRsvpProvider, (
      prev,
      next,
    ) {
      if (_userEnsured) return;

      next.whenData((rsvp) {
        if (rsvp == null) return;

        _userEnsured = true;

        // Trigger write WITHOUT watching it in UI
        ref.read(ensureWeddingUserDocProvider.future);
      });
    });
  }

  void _handleScroll() {
    // Tune this range to match how long you want the intro to “collapse”.
    // 0..240px feels premium + similar to your mock.
    const collapseRange = 240.0;
    final v = (_scrollController.hasClients ? _scrollController.offset : 0.0);
    final p = (v / collapseRange).clamp(0.0, 1.0);
    _introProgress.value = p;
  }

  void _scrollToSection(GlobalKey key, bool isExpanded) {
    if (isExpanded) {
      // 1. Wait a tiny bit for the expansion to begin and layout to shift
      Future.delayed(const Duration(milliseconds: 150), () {
        final context = key.currentContext;
        if (context == null) return;

        // 2. Find the RenderBox of the section
        final RenderBox box = context.findRenderObject() as RenderBox;

        // 3. Find the offset of this box relative to the Viewport
        final RenderAbstractViewport viewport = RenderAbstractViewport.of(box);
        final RevealedOffset offsetToReveal = viewport.getOffsetToReveal(
          box,
          0.0,
        );

        // 4. Animate to that exact position
        _scrollController.animateTo(
          offsetToReveal.offset.clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ),
          duration: const Duration(seconds: 1),
          curve: Curves.easeOutCubic,
        );
      });
    } else {
      log('in else condition');
      _scrollController.animateTo(
        _scrollController
            .offset, // Just keep the current position but animate the layout change
        duration: const Duration(seconds: 1),
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

  Route _outfitInspoRouteGift({
    required OutfitTab initialTab,
    required String heroTag,
    required String eventTitle,
  }) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 900),
      reverseTransitionDuration: const Duration(milliseconds: 520),
      pageBuilder: (_, __, ___) => GiftScreen(),
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

  Route _outfitInspoRouteCashGift({
    required OutfitTab initialTab,
    required String heroTag,
    required String eventTitle,
  }) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 900),
      reverseTransitionDuration: const Duration(milliseconds: 520),
      pageBuilder: (_, __, ___) => CashGiftScreen(),
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

  Widget _buildAnimatedSection({
    required int delay,
    required double topPadding,
    required Color color,
    required String text,
    required CustomClipper<Path> clipper,
    Color textColor = Colors.black,
  }) {
    return TweenAnimationBuilder<double>(
      // Animates from 1.0 (down) to 0.0 (final position)
      tween: Tween(begin: 1.0, end: 0.0),
      curve: Curves.easeOutQuart,
      duration: const Duration(milliseconds: 800),
      // This adds the delay before the animation starts
      key: ValueKey(text),
      builder: (context, value, child) {
        return Padding(
          padding: EdgeInsets.only(
            top: topPadding + (value * 50), // Slides up by 50 pixels
          ),
          child: Opacity(
            opacity: 1.0 - value, // Fades in
            child: child,
          ),
        );
      },
      // We put the heavy ClipPath here so it doesn't rebuild every frame
      child: ClipPath(
        clipper: clipper,
        child: Container(
          height: 200,
          color: color,
          child: Center(
            child: Text(text, style: TextStyle(color: textColor)),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rsvpSub?.close();
    _scrollController.removeListener(_handleScroll);
    _introProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rsvpAsync = ref.watch(userRsvpProvider);
    final eventsAsync = ref.watch(goingEventsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: rsvpAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100,
                child: LoadingIndicator(
                  indicatorType:
                      Indicator.ballScaleMultiple, // Soft pulsing circles
                  colors: [
                    const Color(0xFF06471D), // Your deep green
                    const Color(0xFF8B2B57), // Your badge pink
                    const Color(0xFF06471D).withOpacity(0.5),
                  ],
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(height: 20),
              // Adding a themed text to make it feel premium
              // Text(
              //   "Setting the stage for your arrival...",
              //   style: TextStyle(
              //     color: const Color(0xFF06471D).withOpacity(0.7),
              //     fontFamily: 'SFPRO',
              //     fontSize: 14,
              //     letterSpacing: 0.5,
              //     fontWeight: FontWeight.w500,
              //   ),
              // ).animate().fadeIn(duration: 600.ms),
            ],
          ),
        ),
        error: (e, _) => _ErrorState(message: e.toString()),
        data: (rsvp) {
          if (rsvp == null) {
            return const _EmptyState(
              title: "You’re not on the guest list (yet).",
              subtitle:
                  "We couldn’t find an RSVP linked to this number. Please check the phone number or contact the host.",
            );
          }

          final guestName = rsvp.name.isEmpty ? "Guest" : rsvp.name;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              /// ---------------- HEADER ----------------
              // SliverToBoxAdapter(
              //   child: _TopHeader(
              //     coupleTitle: "Momina\n&\nNizaj",
              //     guestName: guestName,
              //   ),
              // ),
              // SliverFillRemaining(
              //   hasScrollBody: false,
              //   child: _DashboardIntroFullScreen(
              //     coupleTitle: "Momina\n&\nNizaj",
              //     guestName: guestName,
              //     introProgress: _introProgress,
              //   ),
              // ),
              // SliverPersistentHeader(
              //   pinned: false,
              //   floating: false,
              //   delegate: _IntroHeaderDelegate(
              //     coupleTitle: "Momina\n&\nNizaj",
              //     guestName: guestName,
              //     screenHeight: MediaQuery.sizeOf(context).height,
              //   ),
              // ),
              // SliverToBoxAdapter(
              //   child: Stack(
              //     children: [
              //       // --- SECTION 3 (Bottom Layer / Drawn First) ---
              //       Padding(
              //             padding: const EdgeInsets.only(top: 320),
              //             child: ClipPath(
              //               clipper: TestClipper(
              //                 clipTop: true,
              //                 clipBottom: true,
              //               ),
              //               child: Container(
              //                 height: 200,
              //                 color: const Color(0xffe1f8e9),
              //                 child: const Center(child: Text("Section 3")),
              //               ),
              //             ),
              //           )
              //           .animate()
              //           .fadeIn(duration: 600.ms, delay: 800.ms) // Starts last
              //           .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

              //       // --- SECTION 2 (Middle Layer) ---
              //       Padding(
              //             padding: const EdgeInsets.only(top: 160),
              //             child: ClipPath(
              //               clipper: TestClipper(
              //                 clipTop: true,
              //                 clipBottom: true,
              //               ),
              //               child: Container(
              //                 height: 200,
              //                 color: const Color(0xfff8e1f0),
              //                 child: const Center(child: Text("Section 2")),
              //               ),
              //             ),
              //           )
              //           .animate()
              //           .fadeIn(
              //             duration: 600.ms,
              //             delay: 400.ms,
              //           ) // Starts second
              //           .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

              //       // --- SECTION 1 (Top Layer / Drawn Last) ---
              //       ClipPath(
              //             clipper: TestClipper(clipTop: true, clipBottom: true),
              //             child: Container(
              //               height: 200,
              //               color: const Color(0xff045622),
              //               child: const Center(
              //                 child: Text(
              //                   "Section 1",
              //                   style: TextStyle(color: Colors.white),
              //                 ),
              //               ),
              //             ),
              //           )
              //           .animate()
              //           .fadeIn(
              //             duration: 600.ms,
              //             delay: 0.ms,
              //           ) // Starts immediately
              //           .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
              //     ],
              //   ),
              // ),
              // SliverToBoxAdapter(
              //   child: Stack(
              //     children: [
              //       // --- SECTION 1 (Top Layer) ---
              //       ClipPath(
              //         clipper: TestClipper(clipTop: true, clipBottom: true),
              //         child: Container(
              //           height: 200,
              //           color: const Color(0xff045622),
              //           child: const Center(
              //             child: Text(
              //               "Section 1",
              //               style: TextStyle(color: Colors.white),
              //             ),
              //           ),
              //         ),
              //       ),

              //       // --- SECTION 2 (Middle Layer) ---
              //       Padding(
              //         padding: const EdgeInsets.only(
              //           top: 160,
              //         ), // Section1 Height - waveHeight
              //         child: ClipPath(
              //           clipper: TestClipper(clipTop: true, clipBottom: true),
              //           child: Container(
              //             height: 200,
              //             color: const Color(0xfff8e1f0),
              //             child: const Center(child: Text("Section 2")),
              //           ),
              //         ),
              //       ),
              //       // --- SECTION 3 (Bottom Layer) ---
              //       // Positioned at the bottom, so it sits behind everything
              //       Padding(
              //         padding: const EdgeInsets.only(
              //           top: 320,
              //         ), // (Section1 Height + Section2 Height) - (2 * waveHeight)
              //         child: ClipPath(
              //           clipper: TestClipper(clipTop: true, clipBottom: true),
              //           child: Container(
              //             height: 200,
              //             color: const Color(0xffe1f8e9),
              //             child: const Center(child: Text("Section 3")),
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // SliverToBoxAdapter(
              //   child: Stack(
              //     children: [
              //       _buildAnimatedSection(
              //         delay: 0, // Starts first
              //         topPadding: 0,
              //         color: const Color(0xff045622),
              //         text: "Section 1",
              //         textColor: Colors.white,
              //         clipper: TestClipper(clipTop: true, clipBottom: true),
              //       ),
              //       _buildAnimatedSection(
              //         delay: 300, // Starts second
              //         topPadding: 160,
              //         color: const Color(0xfff8e1f0),
              //         text: "Section 2",
              //         clipper: TestClipper(clipTop: true, clipBottom: true),
              //       ),
              //       // SECTION 3
              //       _buildAnimatedSection(
              //         delay: 600, // Starts last
              //         topPadding: 320,
              //         color: const Color(0xffe1f8e9),
              //         text: "Section 3",
              //         clipper: TestClipper(clipTop: true, clipBottom: true),
              //       ),

              //       // SECTION 2

              //       // SECTION 1
              //     ],
              //   ),
              // ),

              /// --- EVENTS SECTION ---
              ///
              // SliverToBoxAdapter(
              //   child: Column(
              //     children: [
              //       // SECTION 1: Green (Only clip bottom)
              //       ClipPath(
              //         clipper: TestClipper(clipTop: true, clipBottom: true),
              //         child: Container(
              //           height: 200,
              //           color: const Color(0xff045622),
              //           child: const Center(
              //             child: Text(
              //               "Section 1",
              //               style: TextStyle(color: Colors.white),
              //             ),
              //           ),
              //         ),
              //       ),

              //       // // GAP FILLER: Pull the next item UP by the waveHeight
              //       // const SizedBox(height: -20),

              //       // SECTION 2: Pink (Clip top AND bottom)
              //       ClipPath(
              //         clipper: TestClipper(clipTop: true, clipBottom: true),
              //         child: Container(
              //           height: 200,
              //           color: const Color(0xfff8e1f0),
              //           child: const Center(child: Text("Section 2")),
              //         ),
              //       ),

              //       // const SizedBox(height: -20),

              //       // SECTION 3: Light Green (Clip top, maybe not bottom)
              //       ClipPath(
              //         clipper: TestClipper(clipTop: true, clipBottom: true),
              //         child: Container(
              //           height: 200,
              //           color: const Color(0xffe1f8e9),
              //           child: const Center(child: Text("Section 3")),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              SliverToBoxAdapter(
                child: StaggeredSlideEntrance(
                  delay: Duration(milliseconds: 0),

                  child: Container(
                    key: _eventsKey,
                    color: const Color(0xFFF7E7EF),
                    child: PremiumExpandableSection(
                      title: "Events",
                      sectionColor: Colors.white,
                      nextSectionColor: const Color(0xFFECFFF3),
                      previousSectionColor: Colors.white, // Color of TopHeader
                      currentSectionColor: const Color(0xFFF7E7EF), // Pink
                      countText: eventsAsync.maybeWhen(
                        data: (e) => "${e.length}",
                        orElse: () => "0",
                      ),
                      initiallyExpanded: false, // Keep events open by default
                      collapsedPreview: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Text(
                            "View the events you are invited to",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Color(0xFF06471D),
                              fontFamily: 'SFPRO',
                            ),
                          ),
                        ],
                      ),
                      onExpansionChanged: (expanded) {
                        log('key :$_eventsKey  ; expanded ? $expanded');

                        _scrollToSection(_eventsKey, expanded);
                        // _scrollToEvents();
                      },
                      expandedContent: Column(
                        children: [
                          // Your existing Events Horizontal ListView code here
                          Container(
                            height: 420,
                            color: const Color(0xFFF7E7EF),
                            child: eventsAsync.when(
                              loading: () => const _EventCardSkeleton(),
                              error: (e, _) =>
                                  _ErrorInline(message: e.toString()),
                              data: (events) => ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                itemCount: events.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 14),
                                itemBuilder: (context, i) {
                                  final ev = events[i];
                                  final theme = _EventTheme.fromType(
                                    ev.title.toLowerCase(),
                                  );

                                  return SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.82,
                                    child: FlipOnAppear(
                                      enabled: i == 0,
                                      child: OpenContainer(
                                        transitionType:
                                            ContainerTransitionType.fadeThrough,
                                        transitionDuration: const Duration(
                                          milliseconds: 700,
                                        ),
                                        closedElevation: 0,
                                        openElevation: 0,
                                        closedColor: Colors.transparent,
                                        openColor: theme.cardBg,

                                        middleColor:
                                            theme.cardBg, // buttery morph
                                        closedShape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            19,
                                          ), // MUST match card
                                        ),
                                        openShape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        closedBuilder: (context, open) {
                                          return _EventCard(
                                            title: ev.title,
                                            bgColor: theme.cardBg,
                                            textColor: theme.titleColor,
                                            image: theme.image,
                                            dateText: ev.dateTime == null
                                                ? null
                                                : DateFormat(
                                                    "dd MMM yyyy",
                                                  ).format(ev.dateTime!),
                                            timeText: ev.dateTime == null
                                                ? null
                                                : DateFormat(
                                                    "h:mm a",
                                                  ).format(ev.dateTime!),
                                            venueText: ev.venue,
                                            onTap:
                                                open, // ✅ container transform open
                                          );
                                        },
                                        openBuilder: (context, close) {
                                          final content =
                                              EventContentRegistry.forTitle(
                                                ev.title,
                                              );
                                          return EventDetailsScreenV1(
                                            eventTitle: ev.title,
                                            venue: ev.venue,
                                            dateTime: ev.dateTime!,
                                            description:
                                                "Traditionally, the ladies apply mehendi and yes, you can add a little mehendi for the bride and groom too.",
                                            detailsHeadline:
                                                "A cozy mehendi night\nwith our closest people.",
                                            locationTitle:
                                                ev.venue ?? "Levant Park",
                                            locationSubtitle:
                                                "AlRuwayyah 3 - After Dubai Government Workshop.\nUAE, Dubai",
                                            locationImageUrl:
                                                "https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=1400",
                                            headerBgColor: theme.cardBg,
                                            accentGold: const Color(0xFFE2A56A),
                                            onBack:
                                                close, // ✅ closes the container transform
                                            content: content,
                                            eventIcon: theme.image,
                                            textColor: theme.titleColor,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _ViewAllButton(onTap: () {}),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              /// --- OUTFIT INSPIRATIONS SECTION ---
              SliverToBoxAdapter(
                child: StaggeredSlideEntrance(
                  delay: Duration(milliseconds: 0),
                  // delay: const Duration(milliseconds: 0),
                  child: Container(
                    key: _outfitKey,
                    color: const Color(0xFFECFFF3),
                    child: PremiumExpandableSection(
                      nextSectionColor: Colors.green,
                      previousSectionColor: const Color(
                        0xFFF7E7EF,
                      ), // Matches Events
                      currentSectionColor: const Color(
                        0xFFECFFF3,
                      ), // Mint Green
                      sectionColor: const Color(0xFFECFFF3), // Mint
                      title: "Outfit inspirations",
                      collapsedPreview: Row(
                        children: [
                          const Text("Explore styles for Men, Women & Kids"),
                          const Spacer(),
                          // Small thumbnails could go here
                        ],
                      ),
                      onExpansionChanged: (expanded) {
                        _scrollToSection(_outfitKey, expanded);
                      },

                      expandedContent: OutfitInspirationsSection(
                        onWomenTap: () {
                          const tag = "outfit-hero-women";
                          Navigator.of(context).push(
                            _outfitInspoRoute(
                              initialTab: OutfitTab.women,
                              heroTag: tag,
                              eventTitle: 'mehendi',
                            ),
                          );
                        },
                        onMenTap: () {
                          const tag = "outfit-hero-men";
                          Navigator.of(context).push(
                            _outfitInspoRoute(
                              initialTab: OutfitTab.men,
                              heroTag: tag,
                              eventTitle: 'mehendi',
                            ),
                          );
                        },
                        onKidsTap: () {
                          const tag = "outfit-hero-kid";
                          Navigator.of(context).push(
                            _outfitInspoRoute(
                              initialTab: OutfitTab.kids,
                              heroTag: tag,
                              eventTitle: 'mehendi',
                            ),
                          );
                        },
                        onViewAllTap: () {
                          const tag = "outfit-hero-women";
                          Navigator.of(context).push(
                            _outfitInspoRoute(
                              initialTab: OutfitTab.women,
                              heroTag: tag,
                              eventTitle: 'mehendi',
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              /// --- OUTFIT INSPIRATIONS SECTION ---
              SliverToBoxAdapter(
                child: StaggeredSlideEntrance(
                  delay: Duration(milliseconds: 0),
                  child: Container(
                    color: Color(0xffFFFCE5),
                    key: _giftsKey,
                    child: PremiumExpandableSection(
                      initiallyExpanded: true,
                      sectionColor: Colors.green,
                      previousSectionColor: const Color(
                        0xFFECFFF3,
                      ), // Matches Outfits
                      currentSectionColor: Color(0xffFFFCE5), // Solid Green
                      nextSectionColor: Colors.white,
                      title: "Gift Registry",
                      titleColor: Color(0xffDE5656),

                      collapsedPreview: Row(
                        children: [
                          const Text(""),
                          const Spacer(),
                          // Small thumbnails could go here
                        ],
                      ),

                      expandedContent: Container(
                        color: const Color(0xffFFFCE5),
                        // padding: const EdgeInsets.symmetric(
                        //   horizontal: 24,
                        //   vertical: 16,
                        // ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              child: Column(
                                children: [
                                  // 1. Your Presence (Static message - no arrow)
                                  GiftCard(
                                    color: const Color(
                                      0xffDE5656,
                                    ), // Matching Coral
                                    icon: Icons.favorite,
                                    heroTag: 'gift-money',
                                    title: "Your Presence",
                                    description:
                                        "Honestly, your presence is the best gift. Come celebrate with us, that's all we want.",
                                    showArrow: false,
                                    onTap: () {}, // Decorative only
                                  ),
                                  const SizedBox(height: 14),

                                  // 2. Gift Fund (Interactive)
                                  GiftCard(
                                    color: const Color(
                                      0xff045622,
                                    ), // Matching Emerald
                                    icon: Icons.redeem_outlined,
                                    title: "Gift Fund",
                                    heroTag: 'gift-fund',
                                    description:
                                        "If you'd like to gift something, you can add to our fund. We'll put it towards something we'll use and love.",
                                    showArrow: true,
                                    onTap: () {
                                      // TODO: Navigate to Gift Fund Details

                                      Navigator.of(context).push(
                                        _outfitInspoRouteGift(
                                          initialTab: OutfitTab.women,
                                          heroTag: 'gift-fund',
                                          eventTitle: 'mehendi',
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // 3. Cash Gift (Interactive)
                                  GiftCard(
                                    color: const Color(
                                      0xff771549,
                                    ), // Matching Plum
                                    icon: Icons.account_balance_wallet_outlined,
                                    title: "Cash Gift",
                                    heroTag: 'gift-card',
                                    description:
                                        "If a cash gift feels easiest, you can transfer it here. It'll go towards wedding/home things we're setting up.",
                                    showArrow: true,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        _outfitInspoRouteCashGift(
                                          initialTab: OutfitTab.women,
                                          heroTag: 'gift-fund',
                                          eventTitle: 'mehendi',
                                        ),
                                      );
                                      // TODO: Navigate to Cash Gift Details
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () {},
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDE5656),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(100),
                                      bottomLeft: Radius.circular(100),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 14,
                                        offset: const Offset(0, 10),
                                        color: Colors.black.withOpacity(0.18),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "View All",
                                        style: TextStyle(
                                          fontFamily: 'SFPRO',
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 200),
                          ],
                        ),
                      ),
                      onExpansionChanged: (isExpanded) {
                        _scrollToSection(_giftsKey, isExpanded);
                      },
                    ),
                  ),
                ),
              ),

              // / ---------------- EVENTS ----------------
              // /
              // SliverToBoxAdapter(
              //   child: Container(
              //     key: _eventsKey,
              //     color: const Color(0xFFF7E7EF),
              //     padding: const EdgeInsets.fromLTRB(0, 44, 0, 0),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         eventsAsync.when(
              //           loading: () =>
              //               _EventsHeader(countText: "…", onArrowTap: () {}),
              //           error: (_, __) =>
              //               _EventsHeader(countText: "!", onArrowTap: () {}),
              //           data: (events) => _EventsHeader(
              //             countText: "${events.length}",
              //             onArrowTap: _scrollToEvents,
              //           ),
              //         ),

              //         const SizedBox(height: 33),

              //         eventsAsync.when(
              //           loading: () => const _EventCardSkeleton(),
              //           error: (e, _) => _ErrorInline(message: e.toString()),
              //           data: (events) {
              //             if (events.isEmpty) {
              //               return const _EmptyInline(
              //                 title: "No events marked as going.",
              //                 subtitle:
              //                     "If you already RSVP’d, it may not be updated yet.",
              //               );
              //             }

              //             return Column(
              //               children: [
              //                 SizedBox(
              //                   height: 420,

              //                   child: ListView.separated(
              //                     scrollDirection: Axis.horizontal,
              //                     padding: const EdgeInsets.only(
              //                       left: 20,
              //                       right: 8,
              //                     ),
              //                     itemCount: events.length,
              //                     separatorBuilder: (_, __) =>
              //                         const SizedBox(width: 14),
              //                     itemBuilder: (context, i) {
              //                       final ev = events[i];
              //                       final theme = _EventTheme.fromType(
              //                         ev.title.toLowerCase(),
              //                       );

              //                       return SizedBox(
              //                         width:
              //                             MediaQuery.of(context).size.width *
              //                             0.82,
              //                         child: FlipOnAppear(
              //                           enabled: i == 0, // 👌 premium touch
              //                           child: _EventCard(
              //                             title: ev.title,
              //                             bgColor: theme.cardBg,
              //                             textColor: theme.titleColor,
              //                             image: theme.image,
              //                             dateText: ev.dateTime == null
              //                                 ? null
              //                                 : DateFormat(
              //                                     "dd MMM yyyy",
              //                                   ).format(ev.dateTime!),
              //                             timeText: ev.dateTime == null
              //                                 ? null
              //                                 : DateFormat(
              //                                     "h:mm a",
              //                                   ).format(ev.dateTime!),
              //                             venueText: ev.venue,
              //                             onTap: () {
              //                               Navigator.push(
              //                                 context,
              //                                 MaterialPageRoute(
              //                                   builder: (_) =>
              //                                       EventDetailsScreenV1(
              //                                         eventTitle: ev.title,
              //                                         venue: ev.venue,
              //                                         dateTime: ev.dateTime!,
              //                                         description:
              //                                             '', // if you have
              //                                         dressCodeTitle:
              //                                             '', // if you have
              //                                         dressCodeNotes:
              //                                             '', // if you have
              //                                         heroImageAsset: null,
              //                                         onDirectionsTap: () {},
              //                                         onImGoingTap: () {},
              //                                         onNotGoingTap: () {},
              //                                       ),
              //                                 ),
              //                               );
              //                             },
              //                           ),
              //                         ),
              //                       );
              //                     },
              //                   ),
              //                 ),

              //                 const SizedBox(height: 18),

              //                 Align(
              //                   alignment: Alignment.centerRight,
              //                   child: _ViewAllButton(onTap: () {}),
              //                 ),

              //                 const SizedBox(height: 25),

              //                 const WaveSeparator(
              //                   topColor: Color(0xFFF7E7EF),
              //                   bottomColor: Color(0xFFEAF7F0),
              //                 ),
              //               ],
              //             );
              //           },
              //         ),
              //       ],
              //     ),
              //   ),
              // ),

              // /// ---------------- OUTFIT INSPIRATIONS ----------------
              // SliverToBoxAdapter(
              //   child: OutfitInspirationsSection(
              //     onWomenTap: () {},
              //     onMenTap: () {},
              //     onKidsTap: () {},
              //     onViewAllTap: () {},
              //   ),
              // ),
            ],
          );
        },
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.coupleTitle, required this.guestName});

  final String coupleTitle;
  final String guestName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Floral image area
        SizedBox(
          height: 315,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  alignment: Alignment.topCenter,
                  "assets/images/vector_header.png", // <-- your exact header image
                  fit: BoxFit.cover,
                ),
              ),

              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ClipPath(
                    clipper: _TopWaveClipper(),
                    child: Container(height: 80, color: Colors.white),
                  ),
                ),
              ),

              // Scallop badge
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _ScallopBadge(
                    text: coupleTitle,
                    color: const Color(0xFF8B2B57),
                  ),
                ),
              ),
            ],
          ),
        ),

        // White greeting section
        Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                children: [
                  Text(
                    "Hello",
                    style: TextStyle(
                      color: const Color(0xFF06471D),
                      fontSize: 14,
                      fontFamily: 'SFPRO',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    guestName,
                    style: const TextStyle(
                      color: Color(0xFF06471D),
                      fontSize: 40,

                      fontFamily: 'Montage',

                      fontWeight: FontWeight.w400,
                      // If you're using a serif font:
                      // fontFamily: "YourSerifFont",
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "We’re so happy you’re here.",
                    style: TextStyle(
                      color: const Color(0xFF06471D),
                      fontSize: 14,
                      fontFamily: 'SFPRO',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
            .slideY(
              begin: 0.25, // comes from bottom
              end: 0,
              duration: 600.ms,
              curve: Curves.easeOutCubic,
            ),

        // Wavy white -> pink transition
        // const _WavyDivider(color: Colors.white, invert: false),
        // const WaveSeparator(
        //   topColor: Colors.white,
        //   bottomColor: Color(0xFFF7E7EF),
        // ),
      ],
    );
  }
}

class _WavyDivider extends StatelessWidget {
  const _WavyDivider({required this.color, required this.invert});

  final Color color;
  final bool invert;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(invert: invert),
      child: Container(height: 42, color: color),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  _WaveClipper({required this.invert});
  final bool invert;

  @override
  Path getClip(Size size) {
    final path = Path();
    if (!invert) {
      // wave at bottom edge
      path.lineTo(0, size.height - 16);
      path.quadraticBezierTo(
        size.width * 0.25,
        size.height,
        size.width * 0.5,
        size.height - 14,
      );
      path.quadraticBezierTo(
        size.width * 0.75,
        size.height - 28,
        size.width,
        size.height - 10,
      );
      path.lineTo(size.width, 0);
      path.close();
    } else {
      // wave at top edge (if you ever need it)
      path.moveTo(0, 16);
      path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 14);
      path.quadraticBezierTo(size.width * 0.75, 28, size.width, 10);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
    }
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _EventsHeader extends StatelessWidget {
  final String countText;
  final VoidCallback onArrowTap;

  const _EventsHeader({required this.countText, required this.onArrowTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 28, left: 20),
      child: Row(
        children: [
          const Text(
            "Events",
            style: TextStyle(
              color: Color(0xFF06471D),
              fontSize: 40,
              fontFamily: 'Montage',
              height: 1.0,
              fontWeight: FontWeight.w500,
              // fontFamily: "YourSerifFont",
            ),
          ),
          const Spacer(),
          Text(
            countText,
            style: const TextStyle(
              color: Color(0xFF1F4D35),
              fontSize: 18,
              fontFamily: 'SFPRO',
              fontWeight: FontWeight.w700,
            ),
          ),
          GestureDetector(
            onTap: onArrowTap,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (_, value, child) {
                return Transform.rotate(
                  angle: value * 3.14, // half rotation
                  child: Opacity(opacity: 1 - (value * 0.3), child: child),
                );
              },
              child: const Icon(Icons.keyboard_arrow_down),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.title,
    required this.dateText,
    required this.timeText,
    required this.venueText,
    required this.onTap,
    required this.bgColor,
    required this.textColor,
    required this.image,
  });

  final String title;
  final String? dateText;
  final String? timeText;
  final String venueText;
  final VoidCallback onTap;
  final Color bgColor;
  final Color textColor;
  final String image;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        height: 420,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 22, 18, 18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
          // boxShadow: [
          //   BoxShadow(
          //     blurRadius: 18,
          //     offset: const Offset(0, 10),
          //     color: Colors.black.withOpacity(0.22),
          //   ),
          // ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title.toLowerCase() == 'nikah' || title.toLowerCase() == 'nikkah'
                ? Image.asset(image)
                : SvgPicture.asset(image),

            const SizedBox(height: 18),

            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 36,
                fontFamily: 'Montage',
                height: 1.0,
                fontWeight: FontWeight.w500,
                // fontFamily: "YourSerifFont",
              ),
            ),

            const SizedBox(height: 18),

            InfoRow(
              icon: Icons.calendar_month_rounded,
              text: dateText ?? "-",
              textColor: textColor,
            ),
            const SizedBox(height: 10),
            InfoRow(
              icon: Icons.access_time_rounded,
              text: timeText == null ? "-" : "$timeText onwards",
              textColor: textColor,
            ),
            const SizedBox(height: 10),
            InfoRow(
              icon: Icons.location_on_rounded,
              text: venueText.isEmpty ? "-" : venueText,
              textColor: textColor,
            ),

            const Spacer(),

            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFFF4D9E6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.icon,
    required this.text,
    required this.textColor,
  });
  final IconData icon;
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'SFPRO',
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  const _ViewAllButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF6F2041),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(100),
            bottomLeft: Radius.circular(100),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              offset: const Offset(0, 10),
              color: Colors.black.withOpacity(0.18),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "View All",
              style: TextStyle(
                fontFamily: 'SFPRO',
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

class _ScallopBadge extends StatelessWidget {
  const _ScallopBadge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      width: 170,
      // padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
      // decoration: BoxDecoration(
      //   image: DecorationImage(image: AssetImage('assets/images/flower.png')),
      // ),
      child: Stack(
        children: [
          SmoothGearOscillation(
            moveDuration: const Duration(seconds: 3),
            holdDuration: const Duration(milliseconds: 450),
            turnsPerSide: .4,
            child: Image.asset('assets/images/flower.png'),
          ),
          Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF4D9E6),
                fontFamily: 'Montage',
                fontSize: 27,
                height: 1.05,
                fontWeight: FontWeight.w400,
                // fontFamily: "YourSerifFont",
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScallopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // Simple scallop-like shape (premium enough + stable)
    final path = Path();
    final r = 18.0;

    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(r),
      ),
    );

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}

class _ErrorInline extends StatelessWidget {
  const _ErrorInline({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withOpacity(0.6),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventTheme {
  final bool isDark;
  final Color cardBg;
  final Color titleColor;
  final Color metaColor;
  final Color primary;

  final Color attendSelectedBg;
  final Color attendSelectedFg;

  final IconData illustrationIcon;
  final Color illustrationColor;
  final String image;
  final String time;

  const _EventTheme({
    required this.isDark,
    required this.cardBg,
    required this.titleColor,
    required this.metaColor,
    required this.primary,
    required this.attendSelectedBg,
    required this.attendSelectedFg,
    required this.illustrationIcon,
    required this.illustrationColor,
    required this.image,
    required this.time,
  });

  factory _EventTheme.fromType(String type) {
    // screenshot palette
    const plum = Color(0xFF771549);
    const green = Color(0xff045622);
    const beige = Color(0xFF5F3406);
    const brown = Color(0xFF6B4A1F);

    switch (type) {
      case 'mehendi':
        return _EventTheme(
          isDark: true,
          cardBg: plum,
          titleColor: Colors.white,
          metaColor: Colors.white.withOpacity(0.72),
          primary: plum,
          attendSelectedBg: Colors.white,
          attendSelectedFg: plum,
          illustrationIcon: Icons.back_hand_outlined,
          illustrationColor: const Color(0xFFE7C3B8),
          image: 'assets/images/mehendi.svg',
          time: '5 pm',
        );

      case 'nikah':
      case 'nikkah':
        return _EventTheme(
          isDark: false,
          cardBg: beige,
          titleColor: Colors.white,
          metaColor: Colors.white.withOpacity(0.72),
          primary: brown,
          attendSelectedBg: brown,
          attendSelectedFg: Colors.white,
          illustrationIcon: Icons.volunteer_activism_outlined,
          illustrationColor: brown.withOpacity(0.75),
          image: 'assets/images/nikkah_layer.png',
          time: '3 pm',
        );

      case 'reception':
      default:
        return _EventTheme(
          isDark: true,
          cardBg: green,
          titleColor: Colors.white,
          metaColor: Colors.white.withOpacity(0.72),
          primary: green,
          attendSelectedBg: Colors.white,
          attendSelectedFg: green,
          illustrationIcon: Icons.celebration_outlined,
          illustrationColor: Colors.white.withOpacity(0.6),
          image: 'assets/images/reception.svg',
          time: '6 pm',
        );
    }
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: Colors.black.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}

class _EventCardSkeleton extends StatelessWidget {
  const _EventCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF6F2041).withOpacity(0.55),
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}

class _TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // The height of the "dip" or "peak" (lower number = flatter wave)
    double waveHeight = 15.0;
    // The vertical starting position
    double yOffset = 20.0;

    path.moveTo(0, yOffset);

    // Wave 1: Up
    path.quadraticBezierTo(
      size.width * 0.125,
      yOffset - waveHeight,
      size.width * 0.25,
      yOffset,
    );

    // Wave 2: Down
    path.quadraticBezierTo(
      size.width * 0.375,
      yOffset + waveHeight,
      size.width * 0.50,
      yOffset,
    );

    // Wave 3: Up
    path.quadraticBezierTo(
      size.width * 0.625,
      yOffset - waveHeight,
      size.width * 0.75,
      yOffset,
    );

    // Wave 4: Down
    path.quadraticBezierTo(
      size.width * 0.875,
      yOffset + waveHeight,
      size.width,
      yOffset,
    );

    // Close the bottom of the rectangle
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _IntroHeaderDelegate extends SliverPersistentHeaderDelegate {
  _IntroHeaderDelegate({
    required this.coupleTitle,
    required this.guestName,
    required this.screenHeight,
  });

  final String coupleTitle;
  final String guestName;
  final double screenHeight;

  // Collapsed height (no leaves, just header + text)
  // Tune this if you want slightly tighter/looser.
  static const double _topHeaderHeight = 315;
  static const double _collapsedTextBlock = 180; // hello/name/chapter/hint area
  static const double _min = _topHeaderHeight + _collapsedTextBlock;

  @override
  double get minExtent => _min;

  // Full screen on first load
  @override
  double get maxExtent => screenHeight;

  @override
  bool shouldRebuild(covariant _IntroHeaderDelegate oldDelegate) {
    return oldDelegate.coupleTitle != coupleTitle ||
        oldDelegate.guestName != guestName;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    const green = Color(0xFF06471D);

    final viewportH = MediaQuery.of(context).size.height;

    // We want the intro to start as full screen.
    final max = viewportH;
    final min = minExtent;

    // 0 -> full, 1 -> collapsed
    final t = ((shrinkOffset) / (max - min)).clamp(0.0, 1.0);

    // Leaves disappear early (so the collapsed state is clean)
    final leavesOpacity = (1.0 - (t * 1.35)).clamp(0.0, 1.0);
    final leavesSlideDown = 22.0 * t;
    final hintOpacity = (1.0 - (t * 1.2)).clamp(0.0, 1.0);

    // Height of the header as it collapses
    final currentHeight = lerpDouble(max, min, t)!;
    bool isVisible = hintOpacity > 0.1;

    return SizedBox(
      height: currentHeight,
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.white)),

          // Main content
          Positioned.fill(
            child: Column(
              children: [
                // Top floral header (same as your current)
                SizedBox(
                  height: _topHeaderHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          "assets/images/vector_header.png",
                          alignment: Alignment.topCenter,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: ClipPath(
                            clipper: _TopWaveClipper(),
                            child: Container(height: 80, color: Colors.white),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _ScallopBadge(
                            text: coupleTitle,
                            color: const Color(0xFF8B2B57),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Remaining area (collapses naturally)
                Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          // mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),
                            const Text(
                              "Hello",
                              style: TextStyle(
                                color: green,
                                fontSize: 14,
                                fontFamily: 'SFPRO',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              guestName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: green,
                                fontSize: 44,
                                fontFamily: 'Montage',
                                fontWeight: FontWeight.w400,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "We’re so happy you’re here.",
                              style: TextStyle(
                                color: green,
                                fontSize: 14,
                                fontFamily: 'SFPRO',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (isVisible)
                              Opacity(
                                opacity: hintOpacity,
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'You’re in the ',
                                        style: TextStyle(
                                          color: const Color(0xFF06471D),
                                          fontSize: 14,
                                          fontFamily: 'SFPRO',
                                          fontWeight: FontWeight.w500,
                                          height: 1.71,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'pre-wedding ',
                                        style: TextStyle(
                                          color: const Color(0xFF06471D),
                                          fontSize: 14,
                                          fontFamily: 'SFPRO',
                                          fontWeight: FontWeight.w700,
                                          height: 1.71,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            'chapter for now. \nThis will change as the celebrations begin',
                                        style: TextStyle(
                                          color: const Color(0xFF06471D),
                                          fontSize: 14,
                                          fontFamily: 'SFPRO',
                                          fontWeight: FontWeight.w500,
                                          height: 1.71,
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            SizedBox(height: lerpDouble(150, 0, t)!),

                            // fades while collapsing
                            if (isVisible)
                              Opacity(
                                opacity: hintOpacity,
                                child: Column(
                                  children: [
                                    Text(
                                      "Scroll to discover more",
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.68),
                                        fontSize: 13,
                                        fontFamily: 'SFPRO',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 22,
                                      color: Colors.black.withOpacity(0.55),
                                    ),
                                  ],
                                ),
                              ),

                            // Space reserved only when leaves are visible.
                            // When leavesOpacity -> 0, this effectively disappears.
                            // SizedBox(height: lerpDouble(110, 0, t)!), // 👈 key
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: 0.2, // Starts slightly lower (20% of its height)
                      end: 0, // Ends at its natural position
                      duration: 800.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ],
            ),
          ),

          // ---- LEAVES LAYER (plays entrance once + fades out on scroll) ----

          // LEFT leaf 1
          Positioned(
            left: 0,
            bottom: 60,
            child: Transform.translate(
              offset: Offset(0, leavesSlideDown),
              child: Opacity(
                opacity: leavesOpacity,
                child:
                    Image.asset(
                          "assets/images/left_leaf_1.png",
                          height: 288,
                          fit: BoxFit.contain,
                        )
                        .animate()
                        // entrance: from bottom-left inside
                        .slideX(
                          begin: -0.35,
                          end: 0,
                          duration: 650.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .slideY(
                          begin: 0.25,
                          end: 0,
                          duration: 650.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .fadeIn(duration: 450.ms),
              ),
            ),
          ),

          // LEFT leaf 3
          Positioned(
            left: -40,
            bottom: -30,
            child:
                Transform.translate(
                      offset: Offset(0, leavesSlideDown),
                      child: Opacity(
                        opacity: leavesOpacity,
                        child: Image.asset(
                          "assets/images/left_leaf_3.png",
                          height: 99,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                    .animate()
                    .slideX(
                      begin: -0.45,
                      end: 0,
                      duration: 700.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .slideY(
                      begin: 0.30,
                      end: 0,
                      duration: 700.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .fadeIn(duration: 450.ms),
          ),

          // LEFT leaf 2
          Positioned(
            left: -20,
            bottom: -80,
            child:
                Transform.translate(
                      offset: Offset(0, leavesSlideDown),
                      child: Opacity(
                        opacity: leavesOpacity,
                        child: Image.asset(
                          "assets/images/left_leaf_2.png",
                          height: 223,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                    .animate()
                    .slideX(
                      begin: -0.45,
                      end: 0,
                      duration: 700.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .slideY(
                      begin: 0.30,
                      end: 0,
                      duration: 700.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .fadeIn(duration: 450.ms),
          ),

          // RIGHT leaf 1 (fix: animate from RIGHT)
          Positioned(
            right: 0,
            bottom: 0,
            child: Transform.translate(
              offset: Offset(0, leavesSlideDown),
              child: Opacity(
                opacity: leavesOpacity,
                child:
                    Image.asset(
                          "assets/images/right_leaf_1.png",
                          height: 363,
                          fit: BoxFit.contain,
                        )
                        .animate()
                        // entrance: from bottom-right inside
                        .slideX(
                          begin: 0.35,
                          end: 0,
                          duration: 650.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .slideY(
                          begin: 0.22,
                          end: 0,
                          duration: 650.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .fadeIn(duration: 450.ms),
              ),
            ),
          ),

          // RIGHT leaf 2
          Positioned(
            right: 0,
            bottom: 0,
            child: Transform.translate(
              offset: Offset(0, leavesSlideDown),
              child: Opacity(
                opacity: leavesOpacity,
                child:
                    Image.asset(
                          "assets/images/right_leaf_2.png",
                          height: 99,
                          fit: BoxFit.contain,
                        )
                        .animate()
                        .slideX(
                          begin: 0.45,
                          end: 0,
                          duration: 700.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .slideY(
                          begin: 0.28,
                          end: 0,
                          duration: 700.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .fadeIn(duration: 450.ms),
              ),
            ),
          ),

          // RIGHT leaf 3
          Positioned(
            right: 70,
            bottom: 0,
            child: Transform.translate(
              offset: Offset(0, leavesSlideDown),
              child: Opacity(
                opacity: leavesOpacity,
                child:
                    Image.asset(
                          "assets/images/right_leaf_3.png",
                          height: 99,
                          fit: BoxFit.contain,
                        )
                        .animate()
                        .slideX(
                          begin: 0.45,
                          end: 0,
                          duration: 700.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .slideY(
                          begin: 0.28,
                          end: 0,
                          duration: 700.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .fadeIn(duration: 450.ms),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardIntroFullScreen extends StatelessWidget {
  const _DashboardIntroFullScreen({
    required this.coupleTitle,
    required this.guestName,
    required this.introProgress,
  });

  final String coupleTitle;
  final String guestName;
  final ValueNotifier<double> introProgress;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF06471D);

    return ValueListenableBuilder<double>(
      valueListenable: introProgress,
      builder: (context, p, _) {
        // Leaves/hint fade out as user scrolls down
        final leavesOpacity = (1.0 - (p * 1.15)).clamp(0.0, 1.0);
        final leavesTranslateY = 22 * p;
        final hintOpacity = (1.0 - (p * 1.4)).clamp(0.0, 1.0);

        return Stack(
              children: [
                // Full-screen base (white)
                Positioned.fill(child: Container(color: Colors.white)),

                // Main content column
                Positioned.fill(
                  child: Column(
                    children: [
                      // Top floral header (fixed height like before)
                      SizedBox(
                        height: 315,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                "assets/images/vector_header.png",
                                alignment: Alignment.topCenter,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: ClipPath(
                                  clipper: _TopWaveClipper(),
                                  child: Container(
                                    height: 80,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: _ScallopBadge(
                                  text: coupleTitle,
                                  color: const Color(0xFF8B2B57),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Center area (takes remaining space)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // const SizedBox(height: 10),
                            const Text(
                              "Hello",
                              style: TextStyle(
                                color: green,
                                fontSize: 14,
                                fontFamily: 'SFPRO',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              guestName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: green,
                                fontSize: 44,
                                fontFamily: 'Montage',
                                fontWeight: FontWeight.w400,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "We’re so happy you’re here.",
                              style: TextStyle(
                                color: green,
                                fontSize: 14,
                                fontFamily: 'SFPRO',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "You’re in the pre-wedding chapter for now.\n"
                              "This will change as the celebrations begin",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: green.withOpacity(0.95),
                                fontSize: 15,
                                fontFamily: 'SFPRO',
                                fontWeight: FontWeight.w600,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 26),

                            // Scroll hint (sits above leaves)
                            Opacity(
                              opacity: hintOpacity,
                              child: Column(
                                children: [
                                  Text(
                                    "Scroll to discover more",
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.68),
                                      fontSize: 13,
                                      fontFamily: 'SFPRO',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 22,
                                    color: Colors.black.withOpacity(0.55),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 0), // room above leaves
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 110,

                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Transform.translate(
                      offset: Offset(0, leavesTranslateY),
                      child: Opacity(
                        opacity: leavesOpacity,
                        child: Container(
                          child: Image.asset(
                            "assets/images/left_leaf_1.png",
                            height: 288,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -50,

                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Transform.translate(
                      offset: Offset(0, leavesTranslateY),
                      child: Opacity(
                        opacity: leavesOpacity,
                        child: Container(
                          child: Image.asset(
                            "assets/images/left_leaf_2.png",
                            height: 223,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,

                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Transform.translate(
                      offset: Offset(0, leavesTranslateY),
                      child: Opacity(
                        opacity: leavesOpacity,
                        child: Container(
                          child: Image.asset(
                            "assets/images/right_leaf_1.png",
                            height: 363,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,

                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Transform.translate(
                      offset: Offset(0, leavesTranslateY),
                      child: Opacity(
                        opacity: leavesOpacity,
                        child: Container(
                          child: Image.asset(
                            "assets/images/right_leaf_2.png",
                            height: 99,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
            // Initial entrance (premium)
            .animate()
            .fadeIn(duration: 450.ms, curve: Curves.easeOutCubic)
            .slideY(
              begin: 0.02,
              end: 0,
              duration: 650.ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }
}

class TestClipper extends CustomClipper<Path> {
  final bool clipTop;
  final bool clipBottom;
  final double waveHeight;
  final double amplitude;

  TestClipper({
    this.clipTop = true,
    this.clipBottom = true,
    this.waveHeight = 20,
    this.amplitude = 15,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final segmentWidth = size.width / 3;

    // Start at top-left (adjusted for top wave)
    path.moveTo(0, clipTop ? waveHeight : 0);

    // --- TOP WAVE ---
    if (clipTop) {
      for (int i = 0; i < 3; i++) {
        final startX = i * segmentWidth;
        path.quadraticBezierTo(
          startX + segmentWidth / 4,
          waveHeight + amplitude,
          startX + segmentWidth / 2,
          waveHeight,
        );
        path.quadraticBezierTo(
          startX + 3 * segmentWidth / 4,
          waveHeight - amplitude,
          startX + segmentWidth,
          waveHeight,
        );
      }
    } else {
      path.lineTo(size.width, 0);
    }

    // Line down to bottom-right
    path.lineTo(
      size.width,
      clipBottom ? size.height - waveHeight : size.height,
    );

    // --- BOTTOM WAVE ---
    if (clipBottom) {
      final baseY = size.height - waveHeight;
      // We draw from right to left to close the path correctly
      for (int i = 2; i >= 0; i--) {
        final startX = i * segmentWidth;
        path.quadraticBezierTo(
          startX + 3 * segmentWidth / 4,
          baseY - amplitude,
          startX + segmentWidth / 2,
          baseY,
        );
        path.quadraticBezierTo(
          startX + segmentWidth / 4,
          baseY + amplitude,
          startX,
          baseY,
        );
      }
    } else {
      path.lineTo(0, size.height);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
