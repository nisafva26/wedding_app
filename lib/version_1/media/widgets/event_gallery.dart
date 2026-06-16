import 'dart:developer';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:wedding_invite/version_1/media/controllers/event_media_stream.dart';
import 'package:wedding_invite/version_1/media/controllers/media_controller.dart';
import 'package:wedding_invite/version_1/media/controllers/signed_url_provider.dart';
import 'package:wedding_invite/version_1/media/screens/event_media_gallery_viewer.dart';
import 'package:wedding_invite/version_1/media/services/media_like_service.dart';
import 'package:wedding_invite/version_1/media/widgets/download_button.dart';
import 'package:wedding_invite/version_1/media/widgets/media_like_button.dart';
import 'package:wedding_invite/version_1/media/widgets/video_thumbnail_widget.dart';

// 1. Create a provider to hold the 'Stable Order' of IDs
// Add .autoDispose here
final galleryOrderProvider = StateProvider.autoDispose
    .family<List<String>, String>((ref, eventId) => []);

class EventRemoteGallery extends ConsumerWidget {
  final String weddingId;
  final String eventId;
  final VoidCallback onAddPressed;

  const EventRemoteGallery({
    super.key,
    required this.weddingId,
    required this.eventId,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMedia = ref.watch(
      eventMediaStreamProvider((weddingId: weddingId, eventId: eventId)),
    );

    // Access the stored order
    final stableIds = ref.watch(galleryOrderProvider(eventId));
    final urlCache = ref.watch(signedUrlCacheProvider);

    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // The actual delete logic

    return asyncMedia.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) {
        log(e.toString());
        return _EmptyPremiumState(
          icon: Icons.error_outline,
          title: 'Could not load gallery',
          subtitle: e.toString(),
          primaryText: 'Try again',
          onPrimary: () => ref.invalidate(
            eventMediaStreamProvider((weddingId: weddingId, eventId: eventId)),
          ),
        );
      },
      data: (mediaDocs) {
        // Ask cache controller to fetch missing signed urls (once per new docs)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(signedUrlCacheProvider.notifier)
              .ensureUrls(
                weddingId: weddingId,
                eventId: eventId,
                mediaDocs: mediaDocs,
              );
        });

        if (mediaDocs.isEmpty) {
          return _EmptyPremiumState(
            icon: Icons.photo_library_outlined,
            title: 'No uploads yet',
            subtitle: 'Be the first to share a photo or video from this event.',
            primaryText: 'Add media',
            onPrimary: onAddPressed,
          );
        }

        double _heightFor(int index) {
          // premium stagger (repeatable pattern)
          const heights = [220.0, 280.0, 240.0, 320.0, 260.0, 300.0];
          return heights[index % heights.length];
        }

        // --- LOGIC: INITIALIZE OR UPDATE THE STABLE ORDER ---
        if (stableIds.isEmpty && mediaDocs.isNotEmpty) {
          // This only runs the VERY FIRST time data arrives
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final sorted = [...mediaDocs];
            sorted.sort(
              (a, b) => (b['likeCount'] ?? 0).compareTo(a['likeCount'] ?? 0),
            );

            ref.read(galleryOrderProvider(eventId).notifier).state = sorted
                .map((m) => m['id'].toString())
                .toList();
          });
          return const Center(child: CircularProgressIndicator());
        }

        // --- LOGIC: MAP LIVE DATA TO STABLE ORDER ---
        // This ensures we show the LATEST data (new like counts)
        // but in the OLD positions (stable IDs).
        final displayList = stableIds
            .map((id) {
              return mediaDocs.firstWhere(
                (m) => m['id'] == id,
                orElse: () => {'id': id, 'deleted': true}, // Handle deletes
              );
            })
            .where((m) => m['deleted'] != true)
            .toList();

        // Also add any NEWLY uploaded images to the top that aren't in our stable list yet
        final newItems = mediaDocs
            .where((m) => !stableIds.contains(m['id']))
            .toList();
        final finalItems = [...newItems, ...displayList];

        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            shrinkWrap: true,
            // physics: const NeverScrollableScrollPhysics(),
            itemCount: finalItems.length,
            itemBuilder: (context, i) {
              // Sort only once per rebuild

              final m = finalItems[i];

              final id = (m['id'] ?? '').toString();
              final type = (m['type'] as String?) ?? 'image';
              final url = urlCache[id];

              final uploadedBy = (m['uploadedBy'] as Map?)
                  ?.cast<String, dynamic>();
              final uploaderName = (uploadedBy?['name'] as String?) ?? 'Guest';
              final uploaderUid = (uploadedBy?['uid'] as String?) ?? '';
              final isOwner = uploaderUid.isNotEmpty && uploaderUid == myUid;

              final h = _heightFor(i);

              final likeCount = (m['likeCount'] as int?) ?? 0;
              // Access the injected boolean here:
              final bool isLikedByMe = (m['isLikedByMe'] as bool?) ?? false;
              final uid = FirebaseAuth.instance.currentUser!.uid;

              final likeService = MediaLikeService(FirebaseFirestore.instance);
              // final heroTag =
              //     "event_${widget.eventId}_$id_$i"; // unique & stable

              return GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false,
                      barrierColor: Colors.black.withOpacity(0.1),
                      transitionDuration: const Duration(milliseconds: 900),
                      reverseTransitionDuration: const Duration(
                        milliseconds: 900,
                      ),
                      pageBuilder: (context, animation, _) => FadeTransition(
                        opacity: animation,
                        child: EventMediaGallery(
                          mediaDocs: finalItems, // List<Map<String,dynamic>>
                          signedUrls:
                              urlCache, // Map<String, String> (id -> url)
                          initialIndex: i,
                          galleryId: eventId, // ✅ stable
                          weddingId: weddingId,
                          eventId: eventId,

                          uid: uid,
                        ),
                      ),
                    ),
                  );
                },
                child: Material(
                  type: MaterialType.transparency,
                  child: Hero(
                    tag: '${eventId}_${id}',
                    child: _InspoTile(
                      radius: 18,
                      height: h,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // ---- Media ----
                          if (url == null)
                            Container(
                              color: const Color(0xFFEAEAEA),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else if (type == 'video')
                            VideoThumbnailWidget(videoUrl: url, height: h)
                          // MVP: premium placeholder (until thumbnails)
                          // Container(
                          //   decoration: const BoxDecoration(
                          //     gradient: LinearGradient(
                          //       colors: [Color(0xFF111111), Color(0xFF2A2A2A)],
                          //       begin: Alignment.topLeft,
                          //       end: Alignment.bottomRight,
                          //     ),
                          //   ),
                          //   child: const Center(
                          //     child: Icon(
                          //       Icons.play_circle_fill,
                          //       size: 54,
                          //       color: Colors.white,
                          //     ),
                          //   ),
                          // )
                          else
                            CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              cacheKey:
                                  'media_$id', // ✅ stable key (IMPORTANT for signed urls)

                              memCacheWidth: 800,
                              filterQuality: FilterQuality
                                  .low, // better perf in grids (high is costly)
                              placeholder: (context, _) =>
                                  Container(color: const Color(0xFFEAEAEA)),
                              errorWidget: (context, url, error) =>
                                  const ColoredBox(
                                    color: Color(0xFFEAEAEA),
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                              fadeInDuration: const Duration(milliseconds: 200),
                              fadeOutDuration: const Duration(
                                milliseconds: 200,
                              ),
                            ),

                          // Image.network(
                          //   url,
                          //   fit: BoxFit.cover,
                          //   filterQuality: FilterQuality.high,
                          //   loadingBuilder: (c, w, p) => p == null
                          //       ? w
                          //       : Container(
                          //           color: const Color(0xFFEAEAEA),
                          //           child: const Center(
                          //             child: CircularProgressIndicator(
                          //               strokeWidth: 2,
                          //             ),
                          //           ),
                          //         ),
                          //   errorBuilder: (_, __, ___) => const ColoredBox(
                          //     color: Color(0xFFEAEAEA),
                          //     child: Icon(Icons.broken_image_outlined),
                          //   ),
                          // ),

                          // ---- Top-left uploader chip ----
                          Positioned(
                            left: 8,
                            top: 8,
                            child: _GlassChip(
                              text: myUid == uploaderUid ? 'You' : uploaderName,
                            ),
                          ),

                          // ---- Bottom-left type chip ----
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: _GlassChip(
                              text: type == 'video' ? 'Video' : 'Photo',
                            ),
                          ),

                          // ---- Owner delete button (top-right) ----
                          if (isOwner)
                            Positioned(
                              top: 8,
                              right: 48,
                              child: _OwnerIconButton(
                                icon: Icons.delete_outline,
                                onTap: () async {
                                  await _showDeleteConfirmation(
                                    context,
                                    id,
                                    weddingId,
                                    eventId,
                                    mediaDocs,
                                  );
                                },
                              ),
                            ),

                          if (url != null)
                            Positioned(
                              right: 6,
                              top: 8,
                              child: DownloadButton(
                                url: url,
                                isVideo: type == 'video',
                                fileName: "${weddingId}_$id",
                              ),
                            ),

                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: MediaLikeButton(
                              // key: ValueKey('like_$id'),
                              key: ValueKey('grid_like_$id'),
                              weddingId: weddingId, // pass into gallery
                              eventId: eventId, // pass into gallery
                              mediaId: id,
                              uid: uid,
                              likeCount: likeCount,
                              // isLiked$: likeService.isLikedStream(
                              //   weddingId: weddingId,
                              //   eventId: eventId,
                              //   mediaId: id,
                              //   uid: uid,
                              // ),
                              isLikedByMe: isLikedByMe,
                              onToggle: () => likeService.toggleLike(
                                weddingId: weddingId,
                                eventId: eventId,
                                mediaId: id,
                                uid: uid,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

Future<void> _showDeleteConfirmation(
  BuildContext context,
  String id,
  String weddingId,
  String eventId,
  List<Map<String, dynamic>> mediaDocs,
) async {
  Future<void> handleDelete() async {
    // Show a non-intrusive loading state if needed
    await deleteEventMedia(
      context: context,
      weddingId: weddingId,
      eventId: eventId,
      mediaId: id,
    );

    // if (!mounted) return;

    // Handle graceful exit if gallery becomes empty
    if (mediaDocs.length <= 1) {
      Navigator.pop(context);
    }
  }

  // Use a blurred background for a premium feel
  final bool? shouldDelete = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent, // Transparent to allow blur to show
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Soft handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Remove Memory',
              style: TextStyle(
                fontFamily: 'Montage', // Your premium serif font
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B163B), // Using your brand plum color
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to delete this photo? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B163B), // Brand plum
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Bottom safety padding
          ],
        ),
      ),
    ),
  );

  if (shouldDelete == true) {
    await handleDelete();
  }
}

class _EmptyPremiumState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String primaryText;
  final VoidCallback onPrimary;

  const _EmptyPremiumState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryText,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 18,
                    color: Color(0x14000000),
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(icon, size: 30, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'SFPRO',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontFamily: 'SFPRO',
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onPrimary,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Color(0xff771549),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                primaryText,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'SFPRO',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspoTile extends StatelessWidget {
  final double radius;
  final double height;
  final Widget child;

  const _InspoTile({
    required this.radius,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(height: height, child: child),
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

class _OwnerIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _OwnerIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        // Matching the 8.0 blur from your GlassChip
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            // Premium glass color: very light white with low opacity
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
                icon,
                color: Colors.white,
                size: 18,
                // Subtle shadow on the icon itself for better contrast
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
