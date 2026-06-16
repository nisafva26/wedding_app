import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wedding_invite/version_1/media/controllers/event_media_stream.dart';
import 'package:wedding_invite/version_1/media/controllers/signed_url_provider.dart';
import 'package:wedding_invite/version_1/media/screens/event_gallery_page.dart';

// Assuming these are your provider paths
// import 'package:wedding_invite/providers/media_provider.dart';

class EventGalleryCTACard extends ConsumerWidget {
  final String weddingId;
  final String eventId;

  const EventGalleryCTACard({
    super.key,
    required this.weddingId,
    required this.eventId,
  });

  void _openGallery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EventGalleryPage(weddingId: weddingId, eventId: eventId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching the stream of media documents
    final asyncMedia = ref.watch(
      eventMediaStreamProvider((weddingId: weddingId, eventId: eventId)),
    );
    // Watching the signed URL cache
    final urlCache = ref.watch(signedUrlCacheProvider);

    return asyncMedia.when(
      data: (mediaDocs) {
        // 🔥 TRIGGER URL FETCHING HERE
        // This ensures that even before the user clicks "View Gallery",
        // the cache starts filling up for the photostack.
        if (mediaDocs.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(signedUrlCacheProvider.notifier)
                .ensureUrls(
                  weddingId: weddingId,
                  eventId: eventId,
                  mediaDocs: mediaDocs,
                );
          });
        }
        final hasMedia = mediaDocs.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(top: 18),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Shared Moments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (hasMedia) _buildPhotoStack(mediaDocs, urlCache),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                hasMedia
                    ? 'View photos and videos shared by everyone invited.'
                    : 'Add photos and videos from your phone. Everyone invited can view them in this event.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),
              _buildPremiumButton(context, hasMedia),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildPhotoStack(
    List<dynamic> mediaDocs,
    Map<String, String> urlCache,
  ) {
    // Filter for images only and take the first 3
    final images = mediaDocs
        .where((m) => (m['type'] ?? 'image') == 'image')
        .take(3)
        .toList();

    if (images.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: 75,
      height: 34,
      child: Stack(
        children: List.generate(images.length, (index) {
          final id = images[index]['id'].toString();
          final url = urlCache[id];

          return Positioned(
            right: index * 18.0, // Overlap effect
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Colors.grey[100],
                backgroundImage: url != null ? NetworkImage(url) : null,
                child: url == null ? const Icon(Icons.person, size: 15) : null,
              ),
            ),
          );
        }).reversed.toList(), // Reversed so first image is on top
      ),
    );
  }

  Widget _buildPremiumButton(BuildContext context, bool hasMedia) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => _openGallery(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF121212), // Deep Onyx
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasMedia
                  ? Icons.grid_view_rounded
                  : Icons.add_photo_alternate_outlined,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              hasMedia ? 'View Gallery' : 'Add photos & videos',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
