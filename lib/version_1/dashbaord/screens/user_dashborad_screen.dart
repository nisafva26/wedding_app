import 'dart:developer';
import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:wedding_invite/feature/auth/widgets/gear_loop_rotation.dart';
import 'package:wedding_invite/notifications/notification_service.dart';
import 'package:wedding_invite/router/router_provider.dart';
import 'package:wedding_invite/version_1/admin/screens/admin_notification_screen.dart';
import 'package:wedding_invite/version_1/admin/screens/admin_screen.dart';
import 'package:wedding_invite/version_1/dashbaord/models/wedding_rsvp_model.dart';
import 'package:wedding_invite/version_1/dashbaord/providers/event_gallery_preview_provider.dart';
import 'package:wedding_invite/version_1/dashbaord/providers/event_provider.dart';
import 'package:wedding_invite/version_1/dashbaord/providers/firestore_provider.dart';
import 'package:wedding_invite/version_1/dashbaord/providers/user_provider.dart';
import 'package:wedding_invite/version_1/dashbaord/screens/outfit-inspiration_screen.dart';
import 'package:wedding_invite/version_1/dashbaord/widgets/dashboard_empty_widget.dart';
import 'package:wedding_invite/version_1/dashbaord/widgets/event_card.dart';
import 'package:wedding_invite/version_1/dashbaord/widgets/event_gallery_album_card.dart';
import 'package:wedding_invite/version_1/dashbaord/widgets/expandable_section.dart';
import 'package:wedding_invite/version_1/dashbaord/widgets/flip.dart';
import 'package:wedding_invite/version_1/dashbaord/widgets/gift_card.dart';
import 'package:wedding_invite/version_1/dashbaord/widgets/staggered_slide_entrance.dart';
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
  GlobalKey _galleryKey = GlobalKey();

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
    getfcmToken();
  }

  void getfcmToken() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.instance.syncFcmTokenToUserDoc();
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
    final isGuest = ref.watch(isGuestProvider); // Or your auth check logic

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
            ],
          ),
        ),
        error: (e, _) => _ErrorState(message: e.toString()),
        data: (rsvp) {
          if (rsvp == null) {
            return EmptyState(
              title: "You’re not on the guest list (yet).",
              subtitle:
                  "We couldn’t find an RSVP linked to this number. Please check the phone number or contact the host.",
              isGuest: isGuest,
              onLogin: () {
                ref.read(isGuestProvider.notifier).state = false;
              },
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
              SliverPersistentHeader(
                pinned: false,
                floating: false,
                delegate: _IntroHeaderDelegate(
                  coupleTitle: "Momina\n&\nNizaj",
                  guestName: guestName,
                  screenHeight: MediaQuery.sizeOf(context).height,
                  scrollController: _scrollController,
                ),
              ),
              // SliverToBoxAdapter(child: SizedBox(height: 50)),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: Offset(0, -30.h),
                  child: Column(
                    children: [
                      // --- SECTION 3 (Bottom Layer / Drawn First) ---
                      ClipPath(
                        clipper: TestClipper(clipTop: true, clipBottom: true),
                        child: Container(
                          key: _eventsKey,
                          child: buildGalleryContent(context, ref, eventsAsync),
                        ),
                      ),

                      // .animate()
                      // .fadeIn(duration: 600.ms, delay: 0.ms) // Starts last
                      // .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                      Transform.translate(
                        offset: Offset(0, -34.h),
                        child: ClipPath(
                          clipper: TestClipper(clipTop: true, clipBottom: true),

                          child: StaggeredSlideEntrance(
                            delay: Duration(milliseconds: 200),
                            child: Container(
                              key: _galleryKey,
                              child: buildEventsContent(eventsAsync),
                            ),
                          ),
                        ),
                      ),

                      // --- SECTION 2 (Middle Layer) ---
                      Transform.translate(
                        offset: Offset(0, -68.h),
                        child: ClipPath(
                          clipper: TestClipper(clipTop: true, clipBottom: true),

                          child: StaggeredSlideEntrance(
                            delay: Duration(milliseconds: 400),
                            child: Container(
                              key: _outfitKey,
                              child: buildOutfitWidget(context),
                            ),
                          ),
                        ),
                      ),

                      // --- SECTION 1 (Top Layer / Drawn Last) ---
                      Transform.translate(
                        offset: Offset(0, -102.h),
                        child: ClipPath(
                          clipper: TestClipper(clipTop: true, clipBottom: true),
                          child: StaggeredSlideEntrance(
                            delay: Duration(milliseconds: 600),
                            child: Container(
                              key: _giftsKey,
                              child: buildGiftWidget(context),
                            ),
                          ),
                        ),
                        // .animate()
                        // .fadeIn(
                        //   duration: 600.ms,
                        //   delay: 600.ms,
                        // ) // Starts immediately
                        // .slideY(
                        //   begin: 0.2,
                        //   end: 0,
                        //   curve: Curves.easeOutCubic,
                        // ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PremiumExpandableSection buildGiftWidget(BuildContext context) {
    return PremiumExpandableSection(
      initiallyExpanded: false,
      sectionColor: Colors.green,
      previousSectionColor: const Color(0xFFECFFF3), // Matches Outfits
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // 1. Your Presence (Static message - no arrow)
                  GiftCard(
                    color: const Color(0xffDE5656), // Matching Coral
                    icon: 'assets/images/heart.json',
                    heroTag: 'gift-money',
                    title: "Your Presence",
                    description:
                        "Your presence is the greatest gift, all we want is to celebrate with you!",
                    showArrow: false,
                    onTap: () {}, // Decorative only
                  ),
                  const SizedBox(height: 14),

                  // 2. Gift Fund (Interactive)
                  GiftCard(
                    color: const Color(0xff045622), // Matching Emerald
                    icon: 'assets/images/gift.json',
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
                    color: const Color(0xff771549), // Matching Plum
                    icon: 'assets/images/cash.json',
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
            // SizedBox(height: 20),
            // Align(
            //   alignment: Alignment.bottomRight,
            //   child: InkWell(
            //     borderRadius: BorderRadius.circular(999),
            //     onTap: () {},
            //     child: Container(
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 18,
            //         vertical: 12,
            //       ),
            //       decoration: BoxDecoration(
            //         color: const Color(0xFFDE5656),
            //         borderRadius: BorderRadius.only(
            //           topLeft: Radius.circular(100),
            //           bottomLeft: Radius.circular(100),
            //         ),
            //         // boxShadow: [
            //         //   BoxShadow(
            //         //     blurRadius: 14,
            //         //     offset: const Offset(0, 10),
            //         //     color: Colors.black.withOpacity(0.18),
            //         //   ),
            //         // ],
            //       ),
            //       child: const Row(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           Text(
            //             "View All",
            //             style: TextStyle(
            //               fontFamily: 'SFPRO',
            //               color: Colors.white,
            //               fontWeight: FontWeight.w700,
            //             ),
            //           ),
            //           SizedBox(width: 8),
            //           Icon(
            //             Icons.arrow_forward_rounded,
            //             size: 18,
            //             color: Colors.white,
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            SizedBox(height: 30),
          ],
        ),
      ),
      onExpansionChanged: (isExpanded) {
        _scrollToSection(_giftsKey, isExpanded);
      },
    );
  }

  PremiumExpandableSection buildOutfitWidget(BuildContext context) {
    return PremiumExpandableSection(
      nextSectionColor: Colors.green,
      previousSectionColor: const Color(0xFFF7E7EF), // Matches Events
      currentSectionColor: const Color(0xFFECFFF3), // Mint Green
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
    );
  }

  PremiumExpandableSection buildEventsContent(
    AsyncValue<List<WeddingEventModel>> eventsAsync,
  ) {
    return PremiumExpandableSection(
      title: "Your events",
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
            "View your events",
            textAlign: TextAlign.left,
            style: TextStyle(color: Color(0xFF06471D), fontFamily: 'SFPRO'),
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
              error: (e, _) => _ErrorInline(message: e.toString()),
              data: (events) => ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: events.length,
                separatorBuilder: (_, __) => SizedBox(width: 14.w),
                itemBuilder: (context, i) {
                  final ev = events[i];
                  final theme = _EventTheme.fromType(ev.title.toLowerCase());

                  log('title : ${ev.title} - countdown : ${ev.countdownText}');

                  return SizedBox(
                    width: MediaQuery.of(context).size.width.w * 0.82.w,
                    child: FlipOnAppear(
                      enabled: i == 0,
                      child: OpenContainer(
                        transitionType: ContainerTransitionType.fadeThrough,
                        transitionDuration: const Duration(milliseconds: 700),
                        closedElevation: 0,
                        openElevation: 0,
                        closedColor: Colors.transparent,
                        openColor: theme.cardBg,

                        middleColor: theme.cardBg, // buttery morph
                        closedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            19.r,
                          ), // MUST match card
                        ),
                        openShape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        closedBuilder: (context, open) {
                          return EventCard(
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
                                : ev.formattedTime,
                            venueText: ev.venue,
                            onTap: open, // ✅ container transform open
                          );
                        },
                        openBuilder: (context, close) {
                          final content = EventContentRegistry.forTitle(
                            ev.title,
                          );
                          return EventDetailsScreenV1(
                            eventTitle: ev.title,
                            timeText: ev.formattedTime,
                            venue: ev.venue,
                            dateTime: ev.dateTime!,
                            description:
                                "Traditionally, the ladies apply mehendi and yes, you can add a little mehendi for the bride and groom too.",
                            detailsHeadline:
                                "A cozy mehendi night\nwith our closest people.",
                            locationTitle: ev.venue ?? "Levant Park",
                            locationSubtitle:
                                "AlRuwayyah 3 - After Dubai Government Workshop.\nUAE, Dubai",
                            locationImageUrl:
                                "https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=1400",
                            headerBgColor: theme.cardBg,
                            accentGold: const Color(0xFFE2A56A),
                            onBack: close, // ✅ closes the container transform
                            content: content,
                            eventIcon: theme.image,
                            textColor: theme.titleColor,
                            eventId: ev.id,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 10),
          // Align(
          //   alignment: Alignment.centerRight,
          //   child: _ViewAllButton(onTap: () {}),
          // ),
        ],
      ),
    );
  }

  PremiumExpandableSection buildGalleryContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<WeddingEventModel>> eventsAsync,
  ) {
    final weddingId = ref.watch(activeWeddingIdProvider);

    return PremiumExpandableSection(
      title: "Memories Feed",
      titleColor: Color(0xff482C77),
      sectionColor: Colors.white,
      nextSectionColor: Colors.white,
      iconColor: Color(0xff482C77),
      previousSectionColor: const Color(0xFFF7E7EF),
      currentSectionColor: const Color(
        0xFFF3EEFF,
      ), // the lilac background you showed

      // countText: eventsAsync.maybeWhen(
      //   data: (e) => "${e.length}",
      //   orElse: () => "0",
      // ),
      initiallyExpanded: true,
      collapsedPreview: const Row(
        children: [
          Text(
            "Watch the memories roll in as guests upload.",
            style: TextStyle(color: Color(0xFF3D2B7A), fontFamily: 'SFPRO'),
          ),
        ],
      ),
      expandedContent: Container(
        color: const Color(0xFFF3EEFF),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 10.h),
        child: eventsAsync.when(
          loading: () => const _GallerySkeletonRow(),
          error: (e, _) => Text('Error: $e'),
          data: (events) {
            if (events.isEmpty) {
              return const _EmptyGalleryState();
            }

            // 2-column grid “Albums”
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              padding: EdgeInsets.only(top: 0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14.w,
                mainAxisSpacing: 14.h,
                childAspectRatio: 0.73, // tuned for your design
              ),
              itemBuilder: (context, i) {
                final ev = events[i];
                final theme = _EventTheme.fromType(ev.title.toLowerCase());

                final previewAsync = ref.watch(
                  eventGalleryPreviewProvider(ev.id),
                );

                return previewAsync.when(
                  loading: () => _AlbumLoadingCard(
                    title: ev.title,
                    bg: theme.cardBg,
                    fg: theme.titleColor,
                  ),
                  error: (_, __) => EventGalleryAlbumCard(
                    weddingId: weddingId,
                    eventId: ev.id,
                    title: ev.title,
                    bgColor: theme.cardBg,
                    textColor: theme.titleColor,
                    image: theme.image,
                    imageCount: 0,
                    videoCount: 0,
                    previewUrls: const [],
                  ),
                  data: (p) => EventGalleryAlbumCard(
                    weddingId: weddingId,
                    eventId: ev.id,
                    title: ev.title,
                    bgColor: theme.cardBg,
                    textColor: theme.titleColor,
                    imageCount: p.imageCount,
                    videoCount: p.videoCount,
                    image: theme.image,
                    previewUrls: p.previewUrls,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// --- tiny placeholders ---
class _GallerySkeletonRow extends StatelessWidget {
  const _GallerySkeletonRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Row(
        children: [
          Expanded(child: _SkeletonBox()),
          const SizedBox(width: 14),
          Expanded(child: _SkeletonBox()),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}

class _EmptyGalleryState extends StatelessWidget {
  const _EmptyGalleryState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: const Text(
        "No event galleries yet. Once guests start uploading, you’ll see them here.",
        style: TextStyle(
          fontFamily: 'SFPRO',
          color: Colors.black54,
          height: 1.35,
        ),
      ),
    );
  }
}

class _AlbumLoadingCard extends StatelessWidget {
  final String title;
  final Color bg;
  final Color fg;

  const _AlbumLoadingCard({
    required this.title,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          title,
          style: TextStyle(
            color: fg,
            fontFamily: 'Montage',
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class ScallopBadge extends StatelessWidget {
  const ScallopBadge({required this.text, required this.color});
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

class TopWaveClipper extends CustomClipper<Path> {
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
    required this.scrollController,
  });

  final String coupleTitle;
  final String guestName;
  final double screenHeight;
  final ScrollController scrollController;

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
      child: ClipPath(
        clipper: const InverseTestClipper(
          clipBottom: true,
          waveHeight: 20, // MUST match the widget below
          amplitude: 15, // MUST match the widget below
        ),
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
                            child: TweenAnimationBuilder<double>(
                              // begin is the starting point (80), end is the final state (60)
                              tween: Tween<double>(begin: 50, end: 80),
                              duration: const Duration(
                                milliseconds: 800,
                              ), // Adjust speed here
                              curve: Curves
                                  .easeOutBack, // Optional: adds a nice "bounce" effect
                              builder: (context, value, child) {
                                return ClipPath(
                                  clipper: TopWaveClipper(),
                                  child: Container(
                                    height:
                                        value, // This will animate from 80 down to 60 automatically
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: ScallopBadge(
                              text: coupleTitle,
                              color: const Color(0xFF8B2B57),
                            ),
                          ),
                        ),

                        Positioned(
                          top: MediaQuery.of(context).padding.top + 10,
                          right: 16,
                          child: SettingsMenu(),
                        ),
                      ],
                    ),
                  ),

                  // Remaining area (collapses naturally)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      child: Column(
                        children: [
                          SizedBox(height: 10.sp),
                          // 1. "Hello"
                          Text(
                                "Hello",
                                style: TextStyle(
                                  color: green,
                                  fontSize: 14.sp,
                                  fontFamily: 'SFPRO',
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: 0.2, end: 0),

                          SizedBox(height: 10.h),
                          // 2. Guest Name (Delayed by 100ms)
                          FittedBox(
                            child:
                                Text(
                                      guestName,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: green,
                                        fontSize: 44.sp,
                                        fontFamily: 'Montage',
                                        height: 1.0,
                                      ),
                                    )
                                    .animate(delay: 100.ms)
                                    .fadeIn(duration: 600.ms)
                                    .slideY(begin: 0.2, end: 0),
                          ),

                          const SizedBox(height: 10),
                          // 3. "We're so happy..." (Delayed by 200ms)
                          Text(
                                "We’re so happy you’re here!",
                                style: TextStyle(
                                  color: green,
                                  fontSize: 14.sp,
                                  fontFamily: 'SFPRO',
                                ),
                              )
                              .animate(delay: 200.ms)
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: 0.2, end: 0),

                          SizedBox(height: 24.h),

                          // 4. Chapter Text (Delayed by 300ms)
                          // if (isVisible)
                          //   Opacity(
                          //         opacity: hintOpacity,
                          //         child: Text.rich(
                          //           TextSpan(
                          //             children: [
                          //               TextSpan(
                          //                 text: 'You’re in the ',
                          //                 style: TextStyle(
                          //                   fontWeight: FontWeight.w500,
                          //                 ),
                          //               ),
                          //               TextSpan(
                          //                 text: 'pre-wedding ',
                          //                 style: TextStyle(
                          //                   fontWeight: FontWeight.w700,
                          //                 ),
                          //               ),
                          //               TextSpan(
                          //                 text:
                          //                     'chapter for now. \nThis will change as the celebrations begin',
                          //                 style: TextStyle(
                          //                   fontWeight: FontWeight.w500,
                          //                 ),
                          //               ),
                          //             ],
                          //           ),
                          //           textAlign: TextAlign.center,
                          //           style: TextStyle(
                          //             color: const Color(0xFF06471D),

                          //             fontSize: 14.sp,

                          //             fontFamily: 'SFPRO',

                          //             fontWeight: FontWeight.w700,

                          //             // height: 1.71,
                          //           ),
                          //         ),
                          //       )
                          //       .animate(delay: 300.ms)
                          //       .fadeIn(duration: 600.ms)
                          //       .slideY(begin: 0.1, end: 0),
                          SizedBox(height: lerpDouble(200.h, 0, t)!),

                          // 5. Scroll Indicator (Delayed by 400ms)
                          // 5. Scroll Indicator (tappable)
                          if (isVisible)
                            Opacity(
                              opacity: hintOpacity,
                              child: Material(
                                color: Colors.transparent,
                                surfaceTintColor: Colors.transparent,
                                child: InkWell(
                                  splashColor: Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    // scroll to just below the full intro (nice first reveal)
                                    final target = (screenHeight - minExtent)
                                        .clamp(0.0, 999999.0);

                                    if (scrollController.hasClients) {
                                      scrollController.animateTo(
                                        target,
                                        duration: const Duration(
                                          milliseconds: 900,
                                        ),
                                        curve: Curves.easeOutCubic,
                                      );
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          "Scroll to discover more",
                                          style: TextStyle(fontSize: 13.sp),
                                        ),
                                        const SizedBox(height: 8),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ).animate(delay: 400.ms).fadeIn(duration: 600.ms),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---- LEAVES LAYER (plays entrance once + fades out on scroll) ----

            // LEFT leaf 1
            Positioned(
              left: 0.w,
              bottom: 60.h,
              child: Transform.translate(
                offset: Offset(0, leavesSlideDown.h), // ✅ scale translate too
                child: Opacity(
                  opacity: leavesOpacity,
                  child:
                      Image.asset(
                            "assets/images/left_leaf_1.png",
                            height: 288.h, // ✅ responsive height
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
              left: (-40).w,
              bottom: (-30).h,
              child:
                  Transform.translate(
                        offset: Offset(0, leavesSlideDown.h),
                        child: Opacity(
                          opacity: leavesOpacity,
                          child: Image.asset(
                            "assets/images/left_leaf_3.png",
                            height: 99.h,
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
              left: (-20).w,
              bottom: (-80).h,
              child:
                  Transform.translate(
                        offset: Offset(0, leavesSlideDown.h),
                        child: Opacity(
                          opacity: leavesOpacity,
                          child: Image.asset(
                            "assets/images/left_leaf_2.png",
                            height: 223.h,
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
              right: 0.w,
              bottom: 0.h,
              child: Transform.translate(
                offset: Offset(0, leavesSlideDown.h),
                child: Opacity(
                  opacity: leavesOpacity,
                  child:
                      Image.asset(
                            "assets/images/right_leaf_1.png",
                            height: 363.h,
                            fit: BoxFit.contain,
                          )
                          .animate()
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
              right: 0.w,
              bottom: 0.h,
              child: Transform.translate(
                offset: Offset(0, leavesSlideDown.h),
                child: Opacity(
                  opacity: leavesOpacity,
                  child:
                      Image.asset(
                            "assets/images/right_leaf_2.png",
                            height: 99.h,
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
              right: 70.w,
              bottom: 0.h,
              child: Transform.translate(
                offset: Offset(0, leavesSlideDown.h),
                child: Opacity(
                  opacity: leavesOpacity,
                  child:
                      Image.asset(
                            "assets/images/right_leaf_3.png",
                            height: 99.h,
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
      ),
    );
  }
}

const Set<String> kAdminPhoneNumbers = {
  '+971585343223',
  '+916282745946',
  '+971559533272',
  '+971561012727',
  '+916282745945'
};

class SettingsMenu extends StatelessWidget {
  const SettingsMenu({super.key});

  bool _isAdminUser() {
    final user = FirebaseAuth.instance.currentUser;
    final phone = user?.phoneNumber;
    if (phone == null) return false;
    return kAdminPhoneNumbers.contains(phone);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdminUser();

    return PopupMenuButton<_SettingsAction>(
          tooltip: 'Settings',
          offset: const Offset(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          color: Colors.white,
          elevation: 10,
          onSelected: (value) async {
            switch (value) {
              case _SettingsAction.admin:
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminHomeScreen(
                      weddingId: 'u7MmJS2IEIjOGax9E6md',
                      weddingName: 'Momina & Nizaj',
                    ),
                  ),
                );
                break;

              case _SettingsAction.logout:
                final confirmed = await _confirmLogout(context);
                if (confirmed) {
                  await FirebaseAuth.instance.signOut();
                }
                break;
            }
          },
          itemBuilder: (context) {
            final items = <PopupMenuEntry<_SettingsAction>>[];

            if (isAdmin) {
              items.add(
                PopupMenuItem(
                  value: _SettingsAction.admin,
                  child: Row(
                    children: const [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 18,
                        color: Colors.black87,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
              items.add(const PopupMenuDivider());
            }

            items.add(
              PopupMenuItem(
                value: _SettingsAction.logout,
                child: Row(
                  children: const [
                    Icon(Icons.logout, size: 18, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );

            return items;
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.settings, color: Colors.white, size: 22),
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 420.ms,
          curve: Curves.easeOutBack,
        );
  }

  Future<bool> _confirmLogout(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

enum _SettingsAction { logout, admin }

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

class BottomTripleWaveClipper extends CustomClipper<Path> {
  const BottomTripleWaveClipper({
    this.amplitude = 22, // wave height
    this.baseline = 24, // how far up from bottom the wave sits
  });

  final double amplitude;
  final double baseline;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    final y = h - baseline;

    final path = Path()..lineTo(0, y);

    // 3 waves across the width => 6 quadratic segments (up/down)
    final seg = w / 6;

    path.quadraticBezierTo(seg * 1, y - amplitude, seg * 2, y);
    path.quadraticBezierTo(seg * 3, y + amplitude, seg * 4, y);
    path.quadraticBezierTo(seg * 5, y - amplitude, seg * 6, y);

    // close shape
    path.lineTo(w, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant BottomTripleWaveClipper oldClipper) {
    return oldClipper.amplitude != amplitude || oldClipper.baseline != baseline;
  }
}

class InverseTestClipper extends CustomClipper<Path> {
  final bool clipTop;
  final bool clipBottom;
  final double waveHeight;
  final double amplitude;

  const InverseTestClipper({
    this.clipTop = false,
    this.clipBottom = true,
    this.waveHeight = 20,
    this.amplitude = 15,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final segmentWidth = size.width / 3;

    // Start at top-left
    path.moveTo(0, 0);

    // Top edge
    if (clipTop) {
      path.lineTo(0, waveHeight);
      for (int i = 0; i < 3; i++) {
        final startX = i * segmentWidth;
        path.quadraticBezierTo(
          startX + segmentWidth / 4,
          waveHeight + amplitude, // Start by going down
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

    // Right edge down
    path.lineTo(size.width, size.height - (clipBottom ? waveHeight : 0));

    // ---- BOTTOM (Inverted Pattern) ----
    if (clipBottom) {
      final baseY = size.height - waveHeight;

      // Draw from right to left
      for (int i = 2; i >= 0; i--) {
        final startX = i * segmentWidth;

        // To make the LEFT-most wave go down, the RIGHT-most wave
        // in this reverse loop must follow the pattern.
        path.quadraticBezierTo(
          startX + 3 * segmentWidth / 4,
          baseY - amplitude, // Peak up
          startX + segmentWidth / 2,
          baseY,
        );

        path.quadraticBezierTo(
          startX + segmentWidth / 4,
          baseY + amplitude, // Dip down (This hits the left side)
          startX,
          baseY,
        );
      }
    } else {
      path.lineTo(0, size.height);
    }

    path.lineTo(0, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant InverseTestClipper oldClipper) {
    return oldClipper.clipTop != clipTop ||
        oldClipper.clipBottom != clipBottom ||
        oldClipper.waveHeight != waveHeight ||
        oldClipper.amplitude != amplitude;
  }
}
