import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:wedding_invite/version_1/dashbaord/screens/invite_editor_screen.dart';
import 'package:wedding_invite/version_1/dashbaord/screens/user_dashborad_screen.dart';
import 'package:wedding_invite/version_1/dashbaord/widgets/empty_delegate.dart';
import 'package:wedding_invite/version_1/dashbaord/widgets/expandable_section.dart';

final cards = const [
  "assets/images/card_1.png",
  "assets/images/card_2.png",
  "assets/images/card_3.png",
];

class EmptyState extends StatefulWidget {
  const EmptyState({
    required this.title,
    required this.subtitle,
    required this.isGuest,
    required this.onLogin,
  });
  final String title;
  final String subtitle;
  final bool isGuest;
  final VoidCallback onLogin;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> {
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: false,
          floating: false,
          delegate: EmptyDelegate(
            coupleTitle: "Momina\n&\nNizaj",
            guestName: '',
            // screenHeight: MediaQuery.sizeOf(context).height,
            isGuest: widget.isGuest,
            onLogin: widget.onLogin,
          ),
        ),
        SliverToBoxAdapter(
          child: ClipPath(
            clipper: TestClipper(clipTop: true, clipBottom: true),
            child: Container(
              // key: _eventsKey,
              child: PremiumExpandableSection(
                title: "Design invites",
                sectionColor: Colors.white,
                nextSectionColor: const Color(0xFFECFFF3),
                previousSectionColor: Colors.white, // Color of TopHeader
                currentSectionColor: const Color(0xFFF7E7EF), // Pink
                countText: '',
                initiallyExpanded: true, // Keep events open by default
                collapsedPreview: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text(
                      "Select a template",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Color(0xFF06471D),
                        fontFamily: 'SFPRO',
                      ),
                    ),
                  ],
                ),
                onExpansionChanged: (expanded) {
                  // log('key :$_eventsKey  ; expanded ? $expanded');

                  // _scrollToSection(_eventsKey, expanded);
                  // _scrollToEvents();
                },
                expandedContent: Column(
                  children: [
                    SizedBox(
                      height: 388, // adjust based on your card aspect ratio
                      child: ListView.builder(
                        // controller: PageController(viewportFraction: 0.82),
                        itemCount: cards.length,
                        scrollDirection: Axis.horizontal,

                        itemBuilder: (context, index) {
                          return AnimatedPadding(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            padding: EdgeInsets.only(
                              left: index == 0 ? 24 : 12,
                              right: 12,
                              top: 10,
                              bottom: 10,
                            ),
                            child: SizedBox(
                              width: 310,
                              height: 388,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      opaque:
                                          false, // Essential for the blur to work
                                      barrierColor: Colors.black.withOpacity(
                                        0.1,
                                      ),
                                      transitionDuration: const Duration(
                                        milliseconds: 800,
                                      ),
                                      reverseTransitionDuration: const Duration(
                                        milliseconds: 800,
                                      ),
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) => InviteEditorScreenSliver(
                                            cardAsset: cards[index],
                                            heroTag: "invite_card_$index",
                                            onBack: () =>
                                                Navigator.pop(context),
                                          ),
                                      transitionsBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            return FadeTransition(
                                              opacity: CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeInOut,
                                              ),
                                              child: child,
                                            );
                                          },
                                    ),
                                  );
                                },
                                child: Hero(
                                  tag: "invite_card_$index",
                                  child: Material(
                                    type: MaterialType.transparency,
                                    child: Stack(
                                      children: [
                                        // Card image
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          child: Image.asset(
                                            cards[index],
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        // Your Text Overlay Layer
                                        Positioned.fill(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  "Save the Date",
                                                  style: TextStyle(
                                                    fontFamily: 'Montage',
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                  ),
                                                ),
                                                const SizedBox(height: 18),
                                                const Text(
                                                  "Jane\n&\nJoe",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: 'Montage',
                                                    fontSize: 29,
                                                    height: 1.1,
                                                  ),
                                                ),
                                                const SizedBox(height: 18),
                                                Text(
                                                  _formattedToday(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Edit button
                                        Positioned(
                                          right: 16,
                                          bottom: 16,
                                          child: _EditPillButton(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                PageRouteBuilder(
                                                  opaque:
                                                      false, // Essential for the blur to work
                                                  barrierColor: Colors.black
                                                      .withOpacity(0.1),
                                                  transitionDuration:
                                                      const Duration(
                                                        milliseconds: 800,
                                                      ),
                                                  reverseTransitionDuration:
                                                      const Duration(
                                                        milliseconds: 800,
                                                      ),
                                                  pageBuilder:
                                                      (
                                                        context,
                                                        animation,
                                                        secondaryAnimation,
                                                      ) => InviteEditorScreenSliver(
                                                        cardAsset: cards[index],
                                                        heroTag:
                                                            "invite_card_$index",
                                                        onBack: () =>
                                                            Navigator.pop(
                                                              context,
                                                            ),
                                                      ),
                                                  transitionsBuilder:
                                                      (
                                                        context,
                                                        animation,
                                                        secondaryAnimation,
                                                        child,
                                                      ) {
                                                        return FadeTransition(
                                                          opacity:
                                                              CurvedAnimation(
                                                                parent:
                                                                    animation,
                                                                curve: Curves
                                                                    .easeInOut,
                                                              ),
                                                          child: child,
                                                        );
                                                      },
                                                ),
                                              );
                                            },
                                          ), // Handled by parent InkWell
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // SizedBox(
                            //   width: 310,
                            //   height: 388,
                            //   child: OpenContainer(
                            //     transitionType:
                            //         ContainerTransitionType.fadeThrough,
                            //     transitionDuration: const Duration(
                            //       milliseconds: 700,
                            //     ),
                            //     closedElevation: 0,
                            //     openElevation: 0,
                            //     closedColor: Colors.transparent,
                            //     openColor: const Color(
                            //       0xFFF7E7EF,
                            //     ), // match editor bg
                            //     middleColor: Colors.transparent,

                            //     // IMPORTANT: closed shape must match your card clip radius
                            //     closedShape: RoundedRectangleBorder(
                            //       borderRadius: BorderRadius.circular(16),
                            //     ),
                            //     openShape: const RoundedRectangleBorder(
                            //       borderRadius:
                            //           BorderRadius.zero, // full screen
                            //     ),

                            //     closedBuilder: (context, openContainer) {
                            //       return Stack(
                            //         children: [
                            //           // Card image
                            //           ClipRRect(
                            //             borderRadius: BorderRadius.circular(
                            //               22,
                            //             ),
                            //             child: Image.asset(
                            //               cards[index],
                            //               width: double.infinity,
                            //               height: double.infinity,
                            //               fit: BoxFit.cover,
                            //             ),
                            //           ),

                            //           // Center template text overlay
                            //           Positioned.fill(
                            //             child: Padding(
                            //               padding: const EdgeInsets.symmetric(
                            //                 horizontal: 24,
                            //               ),
                            //               child: Column(
                            //                 mainAxisAlignment:
                            //                     MainAxisAlignment.center,
                            //                 children: [
                            //                   const Text(
                            //                     "Save the Date",
                            //                     style: TextStyle(
                            //                       fontFamily: 'Montage',
                            //                       color: Colors.white,
                            //                       fontSize: 20,
                            //                       fontWeight: FontWeight.w400,
                            //                     ),
                            //                   ),
                            //                   const SizedBox(height: 18),
                            //                   const Text(
                            //                     "Jane\n&\nJoe",
                            //                     textAlign: TextAlign.center,
                            //                     style: TextStyle(
                            //                       color: Colors.white,
                            //                       fontFamily: 'Montage',
                            //                       fontSize: 29,
                            //                       height: 1.1,
                            //                       fontWeight: FontWeight.w400,
                            //                     ),
                            //                   ),
                            //                   const SizedBox(height: 18),
                            //                   Text(
                            //                     _formattedToday(),
                            //                     style: const TextStyle(
                            //                       color: Colors.white,
                            //                       fontSize: 14,
                            //                       fontWeight: FontWeight.w500,
                            //                       letterSpacing: 1.1,
                            //                     ),
                            //                   ),
                            //                 ],
                            //               ),
                            //             ),
                            //           ),

                            //           // Edit button (optional) — you can call openContainer() too
                            //           Positioned(
                            //             right: 16,
                            //             bottom: 16,
                            //             child: _EditPillButton(
                            //               onTap:
                            //                   openContainer, // ✅ open with pencil too
                            //             ),
                            //           ),

                            //           // Tap anywhere on card opens
                            //           Positioned.fill(
                            //             child: Material(
                            //               color: Colors.transparent,
                            //               child: InkWell(
                            //                 onTap: openContainer, // ✅ open
                            //                 splashColor: Colors.white
                            //                     .withOpacity(0.08),
                            //                 highlightColor: Colors.white
                            //                     .withOpacity(0.05),
                            //               ),
                            //             ),
                            //           ),
                            //         ],
                            //       );
                            //     },

                            //     openBuilder: (context, close) =>
                            //         InviteEditorScreenSliver(
                            //           cardAsset: cards[index],
                            //           heroTag: "invite_card_$index",
                            //           onBack: close,
                            //         ),
                            //   ),
                            // ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _formattedToday() {
  final now = DateTime.now();
  return "${now.day.toString().padLeft(2, '0')}."
      "${now.month.toString().padLeft(2, '0')}."
      "${now.year}";
}

class _EditPillButton extends StatelessWidget {
  const _EditPillButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 44,
          width: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: const Icon(Icons.edit, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

void _openEditor(BuildContext context, int index) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false, // This is the magic line
      barrierColor: Colors.transparent,
      pageBuilder: (context, _, __) => InviteEditorScreenSliver(
        cardAsset: cards[index],
        heroTag: "invite_card_$index",
        onBack: () => Navigator.pop(context),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // This mimics the fade-through feel
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}
