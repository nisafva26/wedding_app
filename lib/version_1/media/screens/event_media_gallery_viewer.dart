import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import 'package:wedding_invite/version_1/media/services/media_like_service.dart';
import 'package:wedding_invite/version_1/media/widgets/download_button.dart';
import 'package:wedding_invite/version_1/media/widgets/media_like_button.dart';

class EventMediaGallery extends StatefulWidget {
  final List<Map<String, dynamic>>
  mediaDocs; // each contains id, type, uploadedBy...
  final Map<String, String> signedUrls; // mediaId -> signed url
  final int initialIndex;
  final String galleryId;
  final String weddingId;
  final String eventId;

  final String uid;

  const EventMediaGallery({
    super.key,
    required this.mediaDocs,
    required this.signedUrls,
    required this.initialIndex,
    required this.galleryId,
    required this.weddingId,
    required this.eventId,

    required this.uid,
  });

  @override
  State<EventMediaGallery> createState() => _EventMediaGalleryState();
}

class _EventMediaGalleryState extends State<EventMediaGallery> {
  late final PageController _pageController;
  late final ValueNotifier<int> _currentPageNotifier;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.initialIndex,
      viewportFraction: 0.88, // ✅ same peek effect
    );
    _currentPageNotifier = ValueNotifier(widget.initialIndex);

    _pageController.addListener(() {
      final next = _pageController.page?.round() ?? 0;
      if (_currentPageNotifier.value != next) {
        _currentPageNotifier.value = next;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final likeService = MediaLikeService(FirebaseFirestore.instance);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Blur + tinted overlay (same vibe)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: const Color(0xE6000000)),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Swipable hero items
                  Center(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.70,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: widget.mediaDocs.length,
                        clipBehavior: Clip.none,
                        itemBuilder: (context, index) {
                          final m = widget.mediaDocs[index];
                          final id = (m['id'] ?? '').toString();
                          final type = (m['type'] as String?) ?? 'image';

                          final uploadedBy = (m['uploadedBy'] as Map?)
                              ?.cast<String, dynamic>();
                          final uploaderName =
                              (uploadedBy?['name'] as String?) ?? 'Guest';

                          final heroTag = "${widget.galleryId}_${id}";
                          final url = widget.signedUrls[id];

                          // GET THE SPECIFIC LIKE COUNT FOR THIS IMAGE
                          final currentLikeCount =
                              (m['likeCount'] as int?) ?? 0;

                              final bool isLikedByMe = (m['isLikedByMe'] as bool?) ?? false;

                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: Hero(
                              tag: heroTag,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (url == null)
                                      const _MediaSkeleton()
                                    else if (type == 'video')
                                      ValueListenableBuilder<int>(
                                        valueListenable: _currentPageNotifier,
                                        builder: (context, current, _) {
                                          return _VideoViewer(
                                            url: url,
                                            isActive:
                                                current ==
                                                index, // ✅ autoplay only for current page
                                          );
                                        },
                                      )
                                    else
                                      Image.network(url, fit: BoxFit.cover),

                                    // Top-left uploader chip
                                    Positioned(
                                      left: 12,
                                      top: 12,
                                      child: _GlassChip(text: uploaderName),
                                    ),

                                    // Bottom-left type chip
                                    Positioned(
                                      left: 12,
                                      bottom: 12,
                                      child: _GlassChip(
                                        text: type == 'video'
                                            ? 'Video'
                                            : 'Photo',
                                      ),
                                    ),

                                    if (url != null)
                                      Positioned(
                                        right: 6,
                                        top: 6,
                                        child: DownloadButton(
                                          url: url,
                                          isVideo: type == 'video',
                                          fileName: "${widget.galleryId}_$id",
                                        ),
                                      ),

                                    Positioned(
                                      right: 8,
                                      bottom: 8,
                                      child: MediaLikeButton(
                                        // key: ValueKey('like_$id'),
                                        key: ValueKey('grid_like_$id'),
                                        weddingId: widget
                                            .weddingId, // pass into gallery
                                        eventId:
                                            widget.eventId, // pass into gallery
                                        mediaId: id,
                                        uid: widget.uid,
                                        likeCount: currentLikeCount,
                                        // isLiked$: likeService.isLikedStream(
                                        //   weddingId: widget.weddingId,
                                        //   eventId: widget.eventId,
                                        //   mediaId: id,
                                        //   uid: widget.uid,
                                        // ),
                                        isLikedByMe: isLikedByMe,
                                        onToggle: () => likeService.toggleLike(
                                          weddingId: widget.weddingId,
                                          eventId: widget.eventId,
                                          mediaId: id,
                                          uid: widget.uid,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Footer UI (same style as your outfit gallery)
                  Align(
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _NavButton(
                                    icon: Icons.chevron_left,
                                    onTap: () => _pageController.previousPage(
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      curve: Curves.easeInOut,
                                    ),
                                  ),
                                  ValueListenableBuilder<int>(
                                    valueListenable: _currentPageNotifier,
                                    builder: (context, value, _) => RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontFamily: 'SFPRO',
                                        ),
                                        children: [
                                          TextSpan(
                                            text: "${value + 1} ",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const TextSpan(
                                            text: "of ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                          TextSpan(
                                            text: "${widget.mediaDocs.length}",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  _NavButton(
                                    icon: Icons.chevron_right,
                                    onTap: () => _pageController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      curve: Curves.easeInOut,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Column(
                                children: [
                                  Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.8),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Close",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                      fontFamily: 'SFPRO',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 400.ms)
                      .slideY(begin: 0.3, end: 0, duration: 800.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaSkeleton extends StatelessWidget {
  const _MediaSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final String text;
  const _GlassChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: Colors.white.withOpacity(0.1), // Very light
            child: Text(
              text,
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _VideoViewer extends StatefulWidget {
  final String url;

  /// ✅ NEW: pass from gallery: currentIndex == index
  final bool isActive;

  /// ✅ NEW: whether to autoplay when active
  final bool autoplay;

  /// ✅ NEW: muted autoplay feels like Instagram (no sudden audio)
  final bool muted;

  const _VideoViewer({
    required this.url,
    required this.isActive,
    this.autoplay = true,
    this.muted = false,
  });

  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
  VideoPlayerController? _controller;

  bool _tapLoading = false; // user pressed play / autoplay waiting to start
  bool _showSlowNetwork = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = c;

    await c.initialize();
    if (!mounted) return;

    if (widget.muted) {
      await c.setVolume(0);
    }

    // ✅ Autoplay if this page is active
    if (widget.autoplay && widget.isActive) {
      await _startPlaybackWithLoader();
    }

    setState(() {});
  }

  @override
  void didUpdateWidget(covariant _VideoViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    // ✅ Became active => autoplay
    if (!oldWidget.isActive && widget.isActive && widget.autoplay) {
      _startPlaybackWithLoader();
    }

    // ✅ Became inactive => pause + reset (Instagram-like)
    if (oldWidget.isActive && !widget.isActive) {
      c.pause();
      c.seekTo(Duration.zero);
      if (mounted) {
        setState(() {
          _tapLoading = false;
          _showSlowNetwork = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startPlaybackWithLoader() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    // already playing? ignore
    if (c.value.isPlaying) return;

    // Show immediate loading feedback
    if (mounted) {
      setState(() {
        _tapLoading = true;
        _showSlowNetwork = false;
      });
    }

    // Try play
    await c.play();

    // Remove loading once it actually starts
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final v = c.value;
      if (v.isPlaying || (!v.isBuffering && v.position > Duration.zero)) {
        setState(() => _tapLoading = false);
      }
    });

    // Slow network hint
    Future.delayed(const Duration(seconds: 8), () {
      if (!mounted) return;
      final v = c.value;
      if (!v.isPlaying && (v.isBuffering || _tapLoading)) {
        setState(() => _showSlowNetwork = true);
      }
    });
  }

  Future<void> _togglePlay() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    // If already playing -> pause instantly
    if (c.value.isPlaying) {
      await c.pause();
      if (mounted) setState(() {});
      return;
    }

    // If user manually plays and you want audio, you can do:
    // if (!widget.muted) await c.setVolume(1);

    await _startPlaybackWithLoader();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const _MediaSkeleton();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: c.value.size.width,
            height: c.value.size.height,
            child: VideoPlayer(c),
          ),
        ),

        // Buffering overlay (based on actual player state)
        ValueListenableBuilder(
          valueListenable: c,
          builder: (context, VideoPlayerValue v, _) {
            final buffering = v.isBuffering;
            final show = buffering || _tapLoading;

            if (!show) return const SizedBox.shrink();

            return Container(
              color: Colors.black.withOpacity(0.18),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_showSlowNetwork)
                      Text(
                        "Network is slow…",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontFamily: 'SFPRO',
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        // Play/Pause button (disable spam taps while buffering/tapLoading)
        Center(
          child: ValueListenableBuilder(
            valueListenable: c,
            builder: (context, VideoPlayerValue v, _) {
              final disabled = v.isBuffering || _tapLoading;

              return GestureDetector(
                onTap: disabled ? null : _togglePlay,
                child: Opacity(
                  opacity: disabled ? 0.4 : 1,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                    child: Icon(
                      v.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Progress bar (minimal)
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: ValueListenableBuilder(
              valueListenable: c,
              builder: (context, VideoPlayerValue v, _) {
                final dur = v.duration.inMilliseconds;
                final pos = v.position.inMilliseconds;
                final progress = (dur <= 0) ? 0.0 : (pos / dur).clamp(0.0, 1.0);

                return Container(
                  height: 6,
                  color: Colors.white.withOpacity(0.18),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(color: Colors.white.withOpacity(0.85)),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// class _VideoViewer extends StatefulWidget {
//   final String url;
//   const _VideoViewer({required this.url});

//   @override
//   State<_VideoViewer> createState() => _VideoViewerState();
// }

// class _VideoViewerState extends State<_VideoViewer> {
//   VideoPlayerController? _controller;

//   bool _tapLoading = false; // user pressed play, waiting to start
//   bool _showSlowNetwork = false;

//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }

//   Future<void> _init() async {
//     final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
//     _controller = c;
//     await c.initialize();
//     if (!mounted) return;

//     // optional: keep it ready, but not autoplay
//     setState(() {});
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }

//   Future<void> _togglePlay() async {
//     final c = _controller;
//     if (c == null || !c.value.isInitialized) return;

//     // If already playing -> pause instantly
//     if (c.value.isPlaying) {
//       await c.pause();
//       if (mounted) setState(() {});
//       return;
//     }

//     // Start play: show immediate loading feedback
//     setState(() {
//       _tapLoading = true;
//       _showSlowNetwork = false;
//     });

//     // Try play
//     await c.play();

//     // If playback starts quickly, remove loading
//     // Otherwise keep loader and show slow-network after timeout
//     Future.delayed(const Duration(milliseconds: 700), () {
//       if (!mounted) return;
//       final v = c.value;
//       if (v.isPlaying || (!v.isBuffering && v.position > Duration.zero)) {
//         setState(() => _tapLoading = false);
//       }
//     });

//     Future.delayed(const Duration(seconds: 8), () {
//       if (!mounted) return;
//       final v = c.value;
//       if (!v.isPlaying && (v.isBuffering || _tapLoading)) {
//         setState(() {
//           _showSlowNetwork = true;
//         });
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final c = _controller;
//     if (c == null || !c.value.isInitialized) {
//       return const _MediaSkeleton();
//     }

//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         FittedBox(
//           fit: BoxFit.contain,
//           child: SizedBox(
//             width: c.value.size.width,
//             height: c.value.size.height,
//             child: VideoPlayer(c),
//           ),
//         ),

//         // Buffering overlay (based on actual player state)
//         ValueListenableBuilder(
//           valueListenable: c,
//           builder: (context, VideoPlayerValue v, _) {
//             final buffering = v.isBuffering;
//             final show = buffering || _tapLoading;

//             if (!show) return const SizedBox.shrink();

//             return Container(
//               color: Colors.black.withOpacity(0.18),
//               child: Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: Colors.black.withOpacity(0.35),
//                         shape: BoxShape.circle,
//                         border: Border.all(
//                           color: Colors.white.withOpacity(0.18),
//                         ),
//                       ),
//                       child: const SizedBox(
//                         height: 22,
//                         width: 22,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),

//         // Play/Pause button (disable spam taps while buffering/tapLoading)
//         Center(
//           child: ValueListenableBuilder(
//             valueListenable: c,
//             builder: (context, VideoPlayerValue v, _) {
//               final disabled = v.isBuffering || _tapLoading;

//               return GestureDetector(
//                 onTap: disabled ? null : _togglePlay,
//                 child: Opacity(
//                   opacity: disabled ? 0.4 : 1,
//                   child: Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.35),
//                       shape: BoxShape.circle,
//                       border: Border.all(color: Colors.white.withOpacity(0.18)),
//                     ),
//                     child: Icon(
//                       v.isPlaying ? Icons.pause : Icons.play_arrow,
//                       color: Colors.white,
//                       size: 28,
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),

//         // Progress bar (minimal)
//         Positioned(
//           left: 12,
//           right: 12,
//           bottom: 12,
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(99),
//             child: ValueListenableBuilder(
//               valueListenable: c,
//               builder: (context, VideoPlayerValue v, _) {
//                 final dur = v.duration.inMilliseconds;
//                 final pos = v.position.inMilliseconds;
//                 final progress = (dur <= 0) ? 0.0 : (pos / dur).clamp(0.0, 1.0);

//                 return Container(
//                   height: 6,
//                   color: Colors.white.withOpacity(0.18),
//                   child: Align(
//                     alignment: Alignment.centerLeft,
//                     child: FractionallySizedBox(
//                       widthFactor: progress,
//                       child: Container(color: Colors.white.withOpacity(0.85)),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _VideoViewer extends StatefulWidget {
//   final String url;
//   const _VideoViewer({required this.url});

//   @override
//   State<_VideoViewer> createState() => _VideoViewerState();
// }

// class _VideoViewerState extends State<_VideoViewer> {
//   VideoPlayerController? _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
//       ..initialize().then((_) {
//         if (mounted) setState(() {});
//       });
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final c = _controller;
//     if (c == null || !c.value.isInitialized) {
//       return const _MediaSkeleton();
//     }

//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         FittedBox(
//           fit: BoxFit.contain,
//           child: SizedBox(
//             width: c.value.size.width,
//             height: c.value.size.height,
//             child: VideoPlayer(c),
//           ),
//         ),
//         Center(
//           child: GestureDetector(
//             onTap: () {
//               setState(() {
//                 c.value.isPlaying ? c.pause() : c.play();
//               });
//             },
//             child: Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: Colors.black.withOpacity(0.35),
//                 shape: BoxShape.circle,
//                 border: Border.all(color: Colors.white.withOpacity(0.18)),
//               ),
//               child: Icon(
//                 c.value.isPlaying ? Icons.pause : Icons.play_arrow,
//                 color: Colors.white,
//                 size: 28,
//               ),
//             ),
//           ),
//         ),
//         // Progress bar (minimal)
//         Positioned(
//           left: 12,
//           right: 12,
//           bottom: 12,
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(99),
//             child: ValueListenableBuilder(
//               valueListenable: c,
//               builder: (context, VideoPlayerValue v, _) {
//                 final dur = v.duration.inMilliseconds;
//                 final pos = v.position.inMilliseconds;
//                 final progress = (dur <= 0) ? 0.0 : (pos / dur).clamp(0.0, 1.0);

//                 return Container(
//                   height: 6,
//                   color: Colors.white.withOpacity(0.18),
//                   child: Align(
//                     alignment: Alignment.centerLeft,
//                     child: FractionallySizedBox(
//                       widthFactor: progress,
//                       child: Container(color: Colors.white.withOpacity(0.85)),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
