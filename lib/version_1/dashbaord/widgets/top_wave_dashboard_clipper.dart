// import 'dart:ui';

// import 'package:flutter/material.dart';

// class TopWaveClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     final path = Path();

//     // The height of the "dip" or "peak" (lower number = flatter wave)
//     double waveHeight = 15.0;
//     // The vertical starting position
//     double yOffset = 20.0;

//     path.moveTo(0, yOffset);

//     // Wave 1: Up
//     path.quadraticBezierTo(
//       size.width * 0.125,
//       yOffset - waveHeight,
//       size.width * 0.25,
//       yOffset,
//     );

//     // Wave 2: Down
//     path.quadraticBezierTo(
//       size.width * 0.375,
//       yOffset + waveHeight,
//       size.width * 0.50,
//       yOffset,
//     );

//     // Wave 3: Up
//     path.quadraticBezierTo(
//       size.width * 0.625,
//       yOffset - waveHeight,
//       size.width * 0.75,
//       yOffset,
//     );

//     // Wave 4: Down
//     path.quadraticBezierTo(
//       size.width * 0.875,
//       yOffset + waveHeight,
//       size.width,
//       yOffset,
//     );

//     // Close the bottom of the rectangle
//     path.lineTo(size.width, size.height);
//     path.lineTo(0, size.height);
//     path.close();

//     return path;
//   }

//   @override
//   bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
// }

// class IntroHeaderDelegate extends SliverPersistentHeaderDelegate {
//   IntroHeaderDelegate({
//     required this.coupleTitle,
//     required this.guestName,
//     required this.screenHeight,
//   });

//   final String coupleTitle;
//   final String guestName;
//   final double screenHeight;

//   // Collapsed height (no leaves, just header + text)
//   // Tune this if you want slightly tighter/looser.
//   static const double _topHeaderHeight = 315;
//   static const double _collapsedTextBlock = 180; // hello/name/chapter/hint area
//   static const double _min = _topHeaderHeight + _collapsedTextBlock;

//   @override
//   double get minExtent => _min;

//   // Full screen on first load
//   @override
//   double get maxExtent => screenHeight;

//   @override
//   bool shouldRebuild(covariant IntroHeaderDelegate oldDelegate) {
//     return oldDelegate.coupleTitle != coupleTitle ||
//         oldDelegate.guestName != guestName;
//   }

//   @override
//   Widget build(
//     BuildContext context,
//     double shrinkOffset,
//     bool overlapsContent,
//   ) {
//     const green = Color(0xFF06471D);

//     final viewportH = MediaQuery.of(context).size.height;

//     // We want the intro to start as full screen.
//     final max = viewportH;
//     final min = minExtent;

//     // 0 -> full, 1 -> collapsed
//     final t = ((shrinkOffset) / (max - min)).clamp(0.0, 1.0);

//     // Leaves disappear early (so the collapsed state is clean)
//     final leavesOpacity = (1.0 - (t * 1.35)).clamp(0.0, 1.0);
//     final leavesSlideDown = 22.0 * t;
//     final hintOpacity = (1.0 - (t * 1.2)).clamp(0.0, 1.0);

//     // Height of the header as it collapses
//     final currentHeight = lerpDouble(max, min, t)!;
//     bool isVisible = hintOpacity > 0.1;

//     return SizedBox(
//       height: currentHeight,
//       child: Stack(
//         children: [
//           Positioned.fill(child: Container(color: Colors.white)),

//           // Main content
//           Positioned.fill(
//             child: Column(
//               children: [
//                 // Top floral header (same as your current)
//                 SizedBox(
//                   height: _topHeaderHeight,
//                   child: Stack(
//                     children: [
//                       Positioned.fill(
//                         child: Image.asset(
//                           "assets/images/vector_header.png",
//                           alignment: Alignment.topCenter,
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                       Positioned.fill(
//                         child: Align(
//                           alignment: Alignment.bottomCenter,
//                           child: TweenAnimationBuilder<double>(
//                             // begin is the starting point (80), end is the final state (60)
//                             tween: Tween<double>(begin: 50, end: 80),
//                             duration: const Duration(
//                               milliseconds: 800,
//                             ), // Adjust speed here
//                             curve: Curves
//                                 .easeOutBack, // Optional: adds a nice "bounce" effect
//                             builder: (context, value, child) {
//                               return ClipPath(
//                                 clipper: TopWaveClipper(),
//                                 child: Container(
//                                   height:
//                                       value, // This will animate from 80 down to 60 automatically
//                                   color: Colors.white,
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       ),
//                       Align(
//                         alignment: Alignment.center,
//                         child: Padding(
//                           padding: const EdgeInsets.only(bottom: 18),
//                           child: _ScallopBadge(
//                             text: coupleTitle,
//                             color: const Color(0xFF8B2B57),
//                           ),
//                         ),
//                       ),

//                       Positioned(
//                         top: MediaQuery.of(context).padding.top + 10,
//                         right: 16,
//                         child: _SettingsMenu(),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Remaining area (collapses naturally)
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 18),
//                     child: Column(
//                       children: [
//                         const SizedBox(height: 10),
//                         // 1. "Hello"
//                         const Text(
//                               "Hello",
//                               style: TextStyle(
//                                 color: green,
//                                 fontSize: 14,
//                                 fontFamily: 'SFPRO',
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             )
//                             .animate()
//                             .fadeIn(duration: 600.ms)
//                             .slideY(begin: 0.2, end: 0),

//                         const SizedBox(height: 10),
//                         // 2. Guest Name (Delayed by 100ms)
//                         Text(
//                               guestName,
//                               textAlign: TextAlign.center,
//                               style: const TextStyle(
//                                 color: green,
//                                 fontSize: 44,
//                                 fontFamily: 'Montage',
//                                 height: 1.0,
//                               ),
//                             )
//                             .animate(delay: 100.ms)
//                             .fadeIn(duration: 600.ms)
//                             .slideY(begin: 0.2, end: 0),

//                         const SizedBox(height: 10),
//                         // 3. "We're so happy..." (Delayed by 200ms)
//                         const Text(
//                               "We’re so happy you’re here.",
//                               style: TextStyle(
//                                 color: green,
//                                 fontSize: 14,
//                                 fontFamily: 'SFPRO',
//                               ),
//                             )
//                             .animate(delay: 200.ms)
//                             .fadeIn(duration: 600.ms)
//                             .slideY(begin: 0.2, end: 0),

//                         const SizedBox(height: 24),
//                         // 4. Chapter Text (Delayed by 300ms)
//                         if (isVisible)
//                           Opacity(
//                                 opacity: hintOpacity,
//                                 child: Text.rich(
//                                   TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text: 'You’re in the ',
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                       ),
//                                       TextSpan(
//                                         text: 'pre-wedding ',
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.w700,
//                                         ),
//                                       ),
//                                       TextSpan(
//                                         text:
//                                             'chapter for now. \nThis will change as the celebrations begin',
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   textAlign: TextAlign.center,
//                                   style: TextStyle(
//                                     color: const Color(0xFF06471D),

//                                     fontSize: 14,

//                                     fontFamily: 'SFPRO',

//                                     fontWeight: FontWeight.w700,

//                                     // height: 1.71,
//                                   ),
//                                 ),
//                               )
//                               .animate(delay: 300.ms)
//                               .fadeIn(duration: 600.ms)
//                               .slideY(begin: 0.1, end: 0),

//                         SizedBox(height: lerpDouble(150, 0, t)!),

//                         // 5. Scroll Indicator (Delayed by 400ms)
//                         if (isVisible)
//                           Opacity(
//                             opacity: hintOpacity,
//                             child: Column(
//                               children: [
//                                 Text(
//                                   "Scroll to discover more",
//                                   style: TextStyle(fontSize: 13),
//                                 ),
//                                 const SizedBox(height: 8),
//                                 Icon(
//                                   Icons.keyboard_arrow_down_rounded,
//                                   size: 22,
//                                 ),
//                               ],
//                             ),
//                           ).animate(delay: 400.ms).fadeIn(duration: 600.ms),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // ---- LEAVES LAYER (plays entrance once + fades out on scroll) ----

//           // LEFT leaf 1
//           Positioned(
//             left: 0,
//             bottom: 60,
//             child: Transform.translate(
//               offset: Offset(0, leavesSlideDown),
//               child: Opacity(
//                 opacity: leavesOpacity,
//                 child:
//                     Image.asset(
//                           "assets/images/left_leaf_1.png",
//                           height: 288,
//                           fit: BoxFit.contain,
//                         )
//                         .animate()
//                         // entrance: from bottom-left inside
//                         .slideX(
//                           begin: -0.35,
//                           end: 0,
//                           duration: 650.ms,
//                           curve: Curves.easeOutCubic,
//                         )
//                         .slideY(
//                           begin: 0.25,
//                           end: 0,
//                           duration: 650.ms,
//                           curve: Curves.easeOutCubic,
//                         )
//                         .fadeIn(duration: 450.ms),
//               ),
//             ),
//           ),

//           // LEFT leaf 3
//           Positioned(
//             left: -40,
//             bottom: -30,
//             child:
//                 Transform.translate(
//                       offset: Offset(0, leavesSlideDown),
//                       child: Opacity(
//                         opacity: leavesOpacity,
//                         child: Image.asset(
//                           "assets/images/left_leaf_3.png",
//                           height: 99,
//                           fit: BoxFit.contain,
//                         ),
//                       ),
//                     )
//                     .animate()
//                     .slideX(
//                       begin: -0.45,
//                       end: 0,
//                       duration: 700.ms,
//                       curve: Curves.easeOutCubic,
//                     )
//                     .slideY(
//                       begin: 0.30,
//                       end: 0,
//                       duration: 700.ms,
//                       curve: Curves.easeOutCubic,
//                     )
//                     .fadeIn(duration: 450.ms),
//           ),

//           // LEFT leaf 2
//           Positioned(
//             left: -20,
//             bottom: -80,
//             child:
//                 Transform.translate(
//                       offset: Offset(0, leavesSlideDown),
//                       child: Opacity(
//                         opacity: leavesOpacity,
//                         child: Image.asset(
//                           "assets/images/left_leaf_2.png",
//                           height: 223,
//                           fit: BoxFit.contain,
//                         ),
//                       ),
//                     )
//                     .animate()
//                     .slideX(
//                       begin: -0.45,
//                       end: 0,
//                       duration: 700.ms,
//                       curve: Curves.easeOutCubic,
//                     )
//                     .slideY(
//                       begin: 0.30,
//                       end: 0,
//                       duration: 700.ms,
//                       curve: Curves.easeOutCubic,
//                     )
//                     .fadeIn(duration: 450.ms),
//           ),

//           // RIGHT leaf 1 (fix: animate from RIGHT)
//           Positioned(
//             right: 0,
//             bottom: 0,
//             child: Transform.translate(
//               offset: Offset(0, leavesSlideDown),
//               child: Opacity(
//                 opacity: leavesOpacity,
//                 child:
//                     Image.asset(
//                           "assets/images/right_leaf_1.png",
//                           height: 363,
//                           fit: BoxFit.contain,
//                         )
//                         .animate()
//                         // entrance: from bottom-right inside
//                         .slideX(
//                           begin: 0.35,
//                           end: 0,
//                           duration: 650.ms,
//                           curve: Curves.easeOutCubic,
//                         )
//                         .slideY(
//                           begin: 0.22,
//                           end: 0,
//                           duration: 650.ms,
//                           curve: Curves.easeOutCubic,
//                         )
//                         .fadeIn(duration: 450.ms),
//               ),
//             ),
//           ),

//           // RIGHT leaf 2
//           Positioned(
//             right: 0,
//             bottom: 0,
//             child: Transform.translate(
//               offset: Offset(0, leavesSlideDown),
//               child: Opacity(
//                 opacity: leavesOpacity,
//                 child:
//                     Image.asset(
//                           "assets/images/right_leaf_2.png",
//                           height: 99,
//                           fit: BoxFit.contain,
//                         )
//                         .animate()
//                         .slideX(
//                           begin: 0.45,
//                           end: 0,
//                           duration: 700.ms,
//                           curve: Curves.easeOutCubic,
//                         )
//                         .slideY(
//                           begin: 0.28,
//                           end: 0,
//                           duration: 700.ms,
//                           curve: Curves.easeOutCubic,
//                         )
//                         .fadeIn(duration: 450.ms),
//               ),
//             ),
//           ),

//           // RIGHT leaf 3
//           Positioned(
//             right: 70,
//             bottom: 0,
//             child: Transform.translate(
//               offset: Offset(0, leavesSlideDown),
//               child: Opacity(
//                 opacity: leavesOpacity,
//                 child:
//                     Image.asset(
//                           "assets/images/right_leaf_3.png",
//                           height: 99,
//                           fit: BoxFit.contain,
//                         )
//                         .animate()
//                         .slideX(
//                           begin: 0.45,
//                           end: 0,
//                           duration: 700.ms,
//                           curve: Curves.easeOutCubic,
//                         )
//                         .slideY(
//                           begin: 0.28,
//                           end: 0,
//                           duration: 700.ms,
//                           curve: Curves.easeOutCubic,
//                         )
//                         .fadeIn(duration: 450.ms),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SettingsMenu extends StatelessWidget {
//   const _SettingsMenu();

//   @override
//   Widget build(BuildContext context) {
//     return PopupMenuButton<_SettingsAction>(
//           tooltip: 'Settings',
//           offset: const Offset(0, 42),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//           color: Colors.white,
//           elevation: 8,
//           onSelected: (value) async {
//             if (value == _SettingsAction.logout) {
//               final confirmed = await _confirmLogout(context);
//               if (confirmed) {
//                 await FirebaseAuth.instance.signOut();
//               }
//             }
//           },
//           itemBuilder: (context) => [
//             PopupMenuItem(
//               value: _SettingsAction.logout,
//               child: Row(
//                 children: const [
//                   Icon(Icons.logout, size: 18, color: Colors.redAccent),
//                   SizedBox(width: 10),
//                   Text(
//                     'Logout',
//                     style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//           child: Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: Colors.black.withOpacity(0.25),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.settings, color: Colors.white, size: 22),
//           ),
//         )
//         // subtle entrance animation
//         .animate()
//         .fadeIn(duration: 350.ms, curve: Curves.easeOut)
//         .scale(
//           begin: const Offset(0.9, 0.9),
//           end: const Offset(1, 1),
//           duration: 420.ms,
//           curve: Curves.easeOutBack,
//         );
//   }

//   Future<bool> _confirmLogout(BuildContext context) async {
//     return await showDialog<bool>(
//           context: context,
//           builder: (context) {
//             return AlertDialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               title: const Text('Logout'),
//               content: const Text('Are you sure you want to logout?'),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, false),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.redAccent,
//                   ),
//                   onPressed: () => Navigator.pop(context, true),
//                   child: const Text(
//                     'Logout',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ) ??
//         false;
//   }
// }