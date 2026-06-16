import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wedding_invite/version_1/dashbaord/providers/firestore_provider.dart';
import 'package:wedding_invite/version_1/media/controllers/signed_url_provider.dart';

class EventGalleryPreview {
  final int imageCount;
  final int videoCount;
  final List<String> previewUrls; // 3–4 urls for stacked circles
  final bool isLoadingUrls;

  const EventGalleryPreview({
    required this.imageCount,
    required this.videoCount,
    required this.previewUrls,
    required this.isLoadingUrls,
  });

  int get total => imageCount + videoCount;
}

final eventGalleryPreviewProvider =
    StreamProvider.family<EventGalleryPreview, String>((ref, eventId) {
      final db = ref.watch(firestoreProvider);
      final weddingId = ref.watch(activeWeddingIdProvider);

      final mediaCol = db
          .collection('weddings')
          .doc(weddingId)
          .collection('events')
          .doc(eventId)
          .collection('media');

      // Watch signed-url cache so UI updates when ensureUrls() completes
      final cache = ref.watch(signedUrlCacheProvider);
      final cacheCtrl = ref.read(signedUrlCacheProvider.notifier);

      return mediaCol
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots()
          .asyncMap((snap) async {
            int img = 0, vid = 0;

            // Convert docs to maps (make sure every map has `id`)
            final mediaDocs = <Map<String, dynamic>>[];
            for (final d in snap.docs) {
              final m = d.data();
              m['id'] ??=
                  d.id; // safety: your docs already have id, but just in case
              mediaDocs.add(m);

              final type = (m['type'] as String?) ?? 'image';
              if (type == 'video') {
                vid++;
              } else {
                img++;
              }
            }

            log('photos $img - videos : $vid');

            // ✅ Only images should be used for preview
            final imageDocs = mediaDocs.where((m) {
              final type = (m['type'] as String?) ?? 'image';
              return type != 'video';
            }).toList();

            // Ask for signed urls for first 4 items (for preview stack)
            // (ensureUrls will internally skip ones already cached)
            await cacheCtrl.ensureUrls(
              weddingId: weddingId,
              eventId: eventId,
              mediaDocs: imageDocs,
            );

            // Build previewUrls from cache for first 4
            final preview = <String>[];
            for (final m in imageDocs) {
              if (preview.length >= 4) break;
              final id = (m['id'] as String?) ?? '';
              final url = cache[id];
              if (url != null && url.isNotEmpty) preview.add(url);
            }

            // ✅ Determine loading only based on image preview items
            final previewTargets = imageDocs.take(4).toList();
            final missingPreviewCount = previewTargets.where((m) {
              final id = (m['id'] as String?) ?? '';
              return id.isNotEmpty && !cache.containsKey(id);
            }).length;

            return EventGalleryPreview(
              imageCount: img,
              videoCount: vid,
              previewUrls: preview,
              isLoadingUrls: missingPreviewCount > 0 && mediaDocs.isNotEmpty,
            );
          });
    });
