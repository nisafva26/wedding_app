import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wedding_invite/version_1/dashbaord/screens/user_dashborad_screen.dart';


class EmptyDelegate extends SliverPersistentHeaderDelegate {
  EmptyDelegate({
    required this.coupleTitle,
    required this.guestName,
    required this.isGuest,
    required this.onLogin,
  });

  final String coupleTitle;
  final String guestName;
  final bool isGuest;
  final VoidCallback onLogin;

  // Your content-driven height (tune these if your content changes)
  static const double _topHeaderHeight = 315;
  static const double _collapsedTextBlock = 200;

  static const double _contentHeight = _topHeaderHeight + _collapsedTextBlock;

  @override
  double get minExtent => _contentHeight;

  // ✅ Not full screen anymore — max = content height
  @override
  double get maxExtent => _contentHeight;

  @override
  bool shouldRebuild(covariant EmptyDelegate oldDelegate) {
    return oldDelegate.coupleTitle != coupleTitle ||
        oldDelegate.guestName != guestName ||
        oldDelegate.isGuest != isGuest;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    const green = Color(0xFF06471D);

    // Since maxExtent == minExtent, shrinkOffset won’t really drive layout.
    // But keeping t for any subtle opacity/spacing tweaks (it will remain 0).
    final t = 0.0;

    final hintOpacity = 1.0;

    return SizedBox(
      height: maxExtent,
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.white)),

          // Main content
          Positioned.fill(
            child: Column(
              children: [
                // Top floral header
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
                            tween: Tween<double>(begin: 50, end: 80),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              return ClipPath(
                                clipper: TopWaveClipper(),
                                child: Container(
                                  height: value,
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
                            text: 'Amongst\nus',
                            color: const Color(0xFF8B2B57),
                          ),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        right: 16,
                        child: SettingsMenu(isGuest: isGuest,onLogin: onLogin,),
                      ),
                    ],
                  ),
                ),

                // Content area (no Expanded now — fixed-height header)
                SizedBox(
                  height: _collapsedTextBlock,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
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
                                    'Guest',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: green,
                                      fontSize: 40.sp,
                                      fontFamily: 'Montage',
                                      height: 1.0,
                                    ),
                                  )
                                  .animate(delay: 100.ms)
                                  .fadeIn(duration: 600.ms)
                                  .slideY(begin: 0.2, end: 0),
                        ),
                        const SizedBox(height: 12),

                        Text(
                              // isGuest
                              //     ? "You're viewing as a Guest"
                              //     : "You're not on the guest list yet",
                              "You’ve not been invited for any event.",
                              style: const TextStyle(
                                color: green,
                                fontSize: 16,
                                fontFamily: 'SFPRO',
                              ),
                            )
                            .animate(delay: 200.ms)
                            .fadeIn()
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 18),

                        // if (isGuest)
                        //   Column(
                        //     children: [
                        //       const Text(
                        //         'Sign in to see your personalized invitation and RSVP details.',
                        //         textAlign: TextAlign.center,
                        //         style: TextStyle(
                        //           color: green,
                        //           fontSize: 14,
                        //           fontWeight: FontWeight.w500,
                        //         ),
                        //       ).animate(delay: 300.ms).fadeIn(),
                        //       const SizedBox(height: 20),
                        //       SizedBox(
                        //         width: 200,
                        //         child: ElevatedButton(
                        //           onPressed: onLogin,
                        //           style: ElevatedButton.styleFrom(
                        //             backgroundColor: const Color(0xFF8B2B57),
                        //             shape: RoundedRectangleBorder(
                        //               borderRadius: BorderRadius.circular(20),
                        //             ),
                        //           ),
                        //           child: const Text(
                        //             "Sign In",
                        //             style: TextStyle(
                        //               color: Colors.white,
                        //               fontFamily: 'Inter',
                        //               fontWeight: FontWeight.w500,
                        //             ),
                        //           ),
                        //         ),
                        //       ).animate(delay: 400.ms).fadeIn(),
                        //     ],
                        //   )
                        // else
                        //   Opacity(
                        //         opacity: hintOpacity,
                        //         child: const Text(
                        //           'We couldn’t find an RSVP linked to this number. Please contact the host.',
                        //           textAlign: TextAlign.center,
                        //           style: TextStyle(
                        //             color: green,
                        //             fontSize: 14,
                        //             fontWeight: FontWeight.w700,
                        //           ),
                        //         ),
                        //       )
                        //       .animate(delay: 300.ms)
                        //       .fadeIn()
                        //       .slideY(begin: 0.1, end: 0),

                        // Keep this if you still want a bit of breathing room
                        SizedBox(height: lerpDouble(12, 0, t)!),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class SettingsMenu extends StatelessWidget {
  const SettingsMenu({super.key, required this.isGuest, required this.onLogin});

  final bool isGuest;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SettingsAction>(
          tooltip: 'Settings',
          offset: const Offset(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          color: Colors.white,
          elevation: 8,
          onSelected: (value) async {
            switch (value) {
              case _SettingsAction.logout:
                final confirmed = await _confirmLogout(context);
                if (confirmed) {
                  await FirebaseAuth.instance.signOut();
                }
                break;

              case _SettingsAction.login:
                onLogin();
                break;
            }
          },
          itemBuilder: (context) {
            // Guest → Login only
            if (isGuest) {
              return [
                PopupMenuItem(
                  value: _SettingsAction.login,
                  child: Row(
                    children: const [
                      Icon(Icons.login, size: 18, color: Color(0xFF6D164B)),
                      SizedBox(width: 10),
                      Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            }

            // Logged in → Logout only
            return [
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
            ];
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
        // ✨ same subtle entrance animation
        .animate()
        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 420.ms,
          curve: Curves.easeOutBack,
        );
  }
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


enum _SettingsAction { logout , login }
