

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MediaLikeButton extends StatefulWidget {
  final String weddingId;
  final String eventId;
  final String mediaId;
  final String uid;
  final int likeCount;
  final VoidCallback onToggle;
  final bool isLikedByMe; // Source of truth from the parent stream

  const MediaLikeButton({
    super.key,
    required this.weddingId,
    required this.eventId,
    required this.mediaId,
    required this.uid,
    required this.likeCount,
    required this.onToggle,
    required this.isLikedByMe,
  });

  @override
  State<MediaLikeButton> createState() => _MediaLikeButtonState();
}

class _MediaLikeButtonState extends State<MediaLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // Optimistic UI state
  bool? _localLiked;
  int? _localLikeCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(MediaLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Sync logic: If the parent's data (from Firestore) now matches our 
    // optimistic guess, we clear the local variables to let the parent rule.
    if (_localLiked == widget.isLikedByMe) {
      _localLiked = null;
    }
    
    if (oldWidget.likeCount != widget.likeCount) {
      _localLikeCount = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(bool currentLiked) {
    // Instant feedback
    _controller.forward(from: 0.0);

    setState(() {
      _localLiked = !currentLiked;
      _localLikeCount = (widget.likeCount) + (_localLiked! ? 1 : -1);
      if (_localLikeCount! < 0) _localLikeCount = 0;
    });

    // Fire and forget the network call
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    // Source logic: Local state takes priority for instant response, 
    // otherwise fallback to the Firestore data from the widget.
    final bool isLiked = _localLiked ?? widget.isLikedByMe;
    final int displayCount = _localLikeCount ?? widget.likeCount;

    return GestureDetector(
      onTap: () => _handleTap(isLiked),
      behavior: HitTestBehavior.opaque,
      child: Material(
         type: MaterialType.transparency,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated number transition
            IntrinsicWidth(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Text(
                  displayCount.toString(),
                  key: ValueKey('count_${widget.mediaId}_$displayCount'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontFamily: 'SFPRO',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Scaling heart container
            SizedBox(
              width: 38,
              height: 38,
              child: Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          isLiked
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}












// import 'dart:developer';
// import 'dart:ui';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';

// class MediaLikeButton extends StatefulWidget {
//   final String weddingId;
//   final String eventId;
//   final String mediaId;
//   final String uid;
//   final int likeCount;
//   final VoidCallback onToggle;
//   final Stream<bool> isLiked$;

//   const MediaLikeButton({
//     super.key,
//     required this.weddingId,
//     required this.eventId,
//     required this.mediaId,
//     required this.uid,
//     required this.likeCount,
//     required this.onToggle,
//     required this.isLiked$,
//   });

//   @override
//   State<MediaLikeButton> createState() => _MediaLikeButtonState();
// }

// class _MediaLikeButtonState extends State<MediaLikeButton>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _scaleAnimation;

//   bool? _localLiked;
//   int? _localLikeCount;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 120),
//       vsync: this,
//     );
//     // Subtle scale up and back down
//     _scaleAnimation = TweenSequence<double>([
//       TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
//       TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
//     ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
//   }

//   // THIS IS THE CRITICAL ADDITION
//   @override
//   void didUpdateWidget(MediaLikeButton oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // If the actual likeCount from the server changed, 
//     // it means our optimistic update is no longer needed.
//     if (oldWidget.likeCount != widget.likeCount) {
//       _localLikeCount = null;
//       // _localLiked = false;
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   void _handleTap(bool currentLiked) {
//     _controller.forward(from: 0.0);

//     setState(() {
//       _localLiked = !currentLiked;
//       // Optimistically update count
//       _localLikeCount = (widget.likeCount) + (_localLiked! ? 1 : -1);
//       // Ensure we don't go below 0
//       if (_localLikeCount! < 0) _localLikeCount = 0;
//     });

//     widget.onToggle();
//   }

//   @override
//   Widget build(BuildContext context) {

//     // log('isliked : ${widget.isLiked$}');
//     return StreamBuilder<bool>(
//       stream: widget.isLiked$,
//       builder: (context, snap) {
//         log('local liked : ${_localLiked} ; snap data : ${snap.data}');
//         final bool isLiked = _localLiked ?? (snap.data ?? false);
//         final int displayCount = _localLikeCount ?? widget.likeCount;

//         // Reset local state when the stream matches our optimistic state
//         if (snap.hasData && _localLiked == snap.data) {
//           _localLiked = null;
//           _localLikeCount = null;
//         }

//         return GestureDetector(
//           onTap: () => _handleTap(isLiked),
//           behavior: HitTestBehavior.opaque,
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Constrain the text area so it doesn't move when numbers change
//               IntrinsicWidth(
//                 child: AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 150),
//                   transitionBuilder: (child, animation) =>
//                       FadeTransition(opacity: animation, child: child),
//                   child: Text(
//                     displayCount.toString(),
//                     key: ValueKey(displayCount),
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.95),
//                       fontFamily: 'SFPRO',
//                       fontSize: 12,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 4),
//               // Fixed size container prevents the "shifting" on X-axis
//               SizedBox(
//                 width: 38,
//                 height: 38,
//                 child: Center(
//                   child: ScaleTransition(
//                     scale: _scaleAnimation,
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(99),
//                       child: BackdropFilter(
//                         filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
//                         child: Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: Colors.white.withOpacity(0.12),
//                             border: Border.all(
//                               color: Colors.white.withOpacity(0.2),
//                               width: 1,
//                             ),
//                           ),
//                           child: Icon(
//                             isLiked
//                                 ? CupertinoIcons.heart_fill
//                                 : CupertinoIcons.heart,
//                             color: Colors.white,
//                             size: 20,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
