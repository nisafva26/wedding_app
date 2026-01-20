// // event_details_screen_v1.dart
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class EventDetailsScreenV1 extends StatelessWidget {
//   const EventDetailsScreenV1({
//     super.key,
//     required this.eventTitle,
//     required this.venue,
//     required this.dateTime,
//     this.description,
//     this.dressCodeTitle,
//     this.dressCodeNotes,
//     this.heroImageAsset, // optional: if you want a floral/event image
//     this.onDirectionsTap,
//     this.onImGoingTap,
//     this.onNotGoingTap,
//   });

//   final String eventTitle;
//   final String venue;
//   final DateTime dateTime;

//   final String? description;

//   // Optional “Dress code / Outfit” section
//   final String? dressCodeTitle;
//   final String? dressCodeNotes;

//   // Optional image (can be a floral header)
//   final String? heroImageAsset;

//   // Actions
//   final VoidCallback? onDirectionsTap;
//   final VoidCallback? onImGoingTap;
//   final VoidCallback? onNotGoingTap;

//   static const _bg = Color(0xFFF6F0EA);
//   static const _pink = Color(0xFFF7E7EF);
//   static const _mint = Color(0xFFEAF7F0);
//   static const _green = Color(0xFF1F4D35);
//   static const _maroon = Color(0xFF6F2041);

//   @override
//   Widget build(BuildContext context) {
//     final dateText = DateFormat("dd MMM yyyy").format(dateTime);
//     final timeText = DateFormat("h:mm a").format(dateTime);

//     return Scaffold(
//       backgroundColor: _bg,
//       body: CustomScrollView(
//         slivers: [
//           SliverAppBar(
//             pinned: true,
//             backgroundColor: _bg,
//             elevation: 0,
//             leading: IconButton(
//               onPressed: () => Navigator.of(context).pop(),
//               icon: const Icon(Icons.arrow_back_rounded, color: _green),
//             ),
//             title: const Text(
//               "Event details",
//               style: TextStyle(
//                 color: _green,
//                 fontWeight: FontWeight.w700,
//                 fontFamily: 'Montage',
//               ),
//             ),
//             centerTitle: true,
//             expandedHeight: heroImageAsset == null ? 30 : 240,
//             flexibleSpace: FlexibleSpaceBar(background: Column(children: [
            
                 
//                 ],
//               )),
//           ),

//           // Main content
//           SliverToBoxAdapter(
//             child: Container(
//               color: Colors.white,
//               padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Big title
//                   Text(
//                     eventTitle,
//                     style: const TextStyle(
//                       color: _green,
//                       fontSize: 40,
//                       fontFamily: 'Montage',
//                       height: 1.0,
//                       fontWeight: FontWeight.w500,
//                       // Use your serif font here if you have it
//                       // fontFamily: "YourSerif",
//                     ),
//                   ),
//                   const SizedBox(height: 14),

//                   // Quick info row (date/time/location)
//                   _InfoPills(
//                     dateText: dateText,
//                     timeText: "$timeText onwards",
//                     venueText: venue,
//                     onDirectionsTap: onDirectionsTap,
//                   ),

//                   const SizedBox(height: 18),

//                   // Description card
//                   if ((description ?? "").trim().isNotEmpty)
//                     _SectionCard(
//                       title: "About",
//                       child: Text(
//                         description!,
//                         style: TextStyle(
//                           color: Colors.black.withOpacity(0.75),
//                           height: 1.45,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     )
//                   else
//                     _SectionCard(
//                       title: "About",
//                       child: Text(
//                         "We’re so happy you’re joining us. Here are the event details and everything you need in one place.",
//                         style: TextStyle(
//                           color: Colors.black.withOpacity(0.72),
//                           height: 1.45,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),

//                   const SizedBox(height: 14),

//                   // Venue card
//                   _SectionCard(
//                     title: "Venue",
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           venue,
//                           style: const TextStyle(
//                             color: _green,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w800,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: OutlinedButton.icon(
//                                 onPressed: onDirectionsTap,
//                                 style: OutlinedButton.styleFrom(
//                                   side: BorderSide(
//                                     color: _green.withOpacity(0.25),
//                                   ),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(999),
//                                   ),
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 14,
//                                     vertical: 12,
//                                   ),
//                                 ),
//                                 icon: const Icon(
//                                   Icons.near_me_rounded,
//                                   color: _green,
//                                   size: 18,
//                                 ),
//                                 label: const Text(
//                                   "Directions",
//                                   style: TextStyle(
//                                     color: _green,
//                                     fontWeight: FontWeight.w800,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: OutlinedButton.icon(
//                                 onPressed: () async {
//                                   // Optional: copy venue text
//                                   await _copyToClipboard(context, venue);
//                                 },
//                                 style: OutlinedButton.styleFrom(
//                                   side: BorderSide(
//                                     color: _green.withOpacity(0.25),
//                                   ),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(999),
//                                   ),
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 14,
//                                     vertical: 12,
//                                   ),
//                                 ),
//                                 icon: const Icon(
//                                   Icons.copy_rounded,
//                                   color: _green,
//                                   size: 18,
//                                 ),
//                                 label: const Text(
//                                   "Copy",
//                                   style: TextStyle(
//                                     color: _green,
//                                     fontWeight: FontWeight.w800,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 14),

//                   // Dress code / Outfit inspirations (optional)
//                   if ((dressCodeTitle ?? "").trim().isNotEmpty ||
//                       (dressCodeNotes ?? "").trim().isNotEmpty)
//                     _SectionCard(
//                       title: "Outfit",
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           if ((dressCodeTitle ?? "").trim().isNotEmpty)
//                             Text(
//                               dressCodeTitle!,
//                               style: const TextStyle(
//                                 color: _maroon,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w900,
//                               ),
//                             ),
//                           if ((dressCodeTitle ?? "").trim().isNotEmpty)
//                             const SizedBox(height: 8),
//                           if ((dressCodeNotes ?? "").trim().isNotEmpty)
//                             Text(
//                               dressCodeNotes!,
//                               style: TextStyle(
//                                 color: Colors.black.withOpacity(0.72),
//                                 height: 1.45,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           const SizedBox(height: 12),
//                           Container(
//                             padding: const EdgeInsets.all(14),
//                             decoration: BoxDecoration(
//                               color: _mint,
//                               borderRadius: BorderRadius.circular(18),
//                             ),
//                             child: Row(
//                               children: [
//                                 const Icon(Icons.style_rounded, color: _green),
//                                 const SizedBox(width: 10),
//                                 Expanded(
//                                   child: Text(
//                                     "Need inspiration? Check the Outfit section on the home page.",
//                                     style: TextStyle(
//                                       color: _green.withOpacity(0.92),
//                                       fontWeight: FontWeight.w700,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                   const SizedBox(height: 24),

//                   // // Wave into mint section for CTA area
//                   // const WaveSeparator(
//                   //   topColor: _pink,
//                   //   bottomColor: _mint,
//                   //   height: 44,
//                   //   amplitude: 10,
//                   // ),
//                 ],
//               ),
//             ),
//           ),

//           const SliverToBoxAdapter(child: SizedBox(height: 24)),
//         ],
//       ),
//     );
//   }

//   static Future<void> _copyToClipboard(
//     BuildContext context,
//     String text,
//   ) async {
//     // Avoid importing services everywhere; you can move this util to your own helper file
//     // ignore: avoid_web_libraries_in_flutter
//     // (For mobile, use Clipboard from services.dart)
//     // If you want, I’ll give you mobile-safe clipboard helper.
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text("Copied")));
//   }
// }

// /// ------------------------
// /// Reusable UI bits
// /// ------------------------

// class _InfoPills extends StatelessWidget {
//   const _InfoPills({
//     required this.dateText,
//     required this.timeText,
//     required this.venueText,
//     required this.onDirectionsTap,
//   });

//   final String dateText;
//   final String timeText;
//   final String venueText;
//   final VoidCallback? onDirectionsTap;

//   static const _green = Color(0xFF1F4D35);
//   static const _maroon = Color(0xFF6F2041);

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         _PillRow(
//           icon: Icons.calendar_month_rounded,
//           text: dateText,
//           color: _green,
//         ),
//         const SizedBox(height: 10),
//         _PillRow(
//           icon: Icons.access_time_rounded,
//           text: timeText,
//           color: _green,
//         ),
//         const SizedBox(height: 10),
//         InkWell(
//           borderRadius: BorderRadius.circular(18),
//           onTap: onDirectionsTap,
//           child: _PillRow(
//             icon: Icons.location_on_rounded,
//             text: venueText,
//             color: _green,
//             trailing: const Icon(
//               Icons.near_me_rounded,
//               color: _green,
//               size: 18,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _PillRow extends StatelessWidget {
//   const _PillRow({
//     required this.icon,
//     required this.text,
//     required this.color,
//     this.trailing,
//   });

//   final IconData icon;
//   final String text;
//   final Color color;
//   final Widget? trailing;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//       // decoration: BoxDecoration(
//       //   color: Colors.white.withOpacity(0.72),
//       //   borderRadius: BorderRadius.circular(18),
//       //   border: Border.all(color: Colors.black.withOpacity(0.06)),
//       // ),
//       child: Row(
//         children: [
//           Icon(icon, size: 18, color: color),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               text,
//               style: TextStyle(
//                 fontFamily: 'SFPRO',
//                 color: Colors.black.withOpacity(0.72),
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ),
//           if (trailing != null) trailing!,
//         ],
//       ),
//     );
//   }
// }

// class _SectionCard extends StatelessWidget {
//   const _SectionCard({required this.title, required this.child});

//   final String title;
//   final Widget child;

//   static const _green = Color(0xFF1F4D35);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.78),
//         borderRadius: BorderRadius.circular(22),
//         border: Border.all(color: Colors.black.withOpacity(0.06)),
//         boxShadow: [
//           BoxShadow(
//             blurRadius: 18,
//             offset: const Offset(0, 12),
//             color: Colors.black.withOpacity(0.08),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(
//               color: _green,
//               fontSize: 16,
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//           const SizedBox(height: 10),
//           child,
//         ],
//       ),
//     );
//   }
// }
