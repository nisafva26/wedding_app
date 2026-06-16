import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final signedUrlCacheProvider =
    StateNotifierProvider<SignedUrlCacheController, Map<String, String>>(
      (ref) => SignedUrlCacheController(ref),
    );

class SignedUrlCacheController extends StateNotifier<Map<String, String>> {
  SignedUrlCacheController(this.ref) : super({});
  final Ref ref;

  final _callable = FirebaseFunctions.instance.httpsCallable(
    'getEventMediaSignedUrls',
  );

  /// Fetch signed URLs for items that are missing in cache.
  Future<void> ensureUrls({
    required String weddingId,
    required String eventId,
    required List<Map<String, dynamic>> mediaDocs,
  }) async {
    final missing = <Map<String, dynamic>>[];

    for (final m in mediaDocs) {
      final id = m['id'] as String;
      final r2Key = m['r2Key'];
      if (r2Key == null) continue;

      if (!state.containsKey(id)) {
        missing.add({'mediaId': id, 'r2Key': r2Key, 'mimeType': m['mimeType']});
      }
      if (missing.length >= 40) break; // batch size limit
    }

    if (missing.isEmpty) return;

    final res = await _callable.call({
      'weddingId': weddingId,
      'eventId': eventId,
      'items': missing,
    });

    final data = Map<String, dynamic>.from(res.data as Map);
    final urls = List<Map<String, dynamic>>.from(
      (data['urls'] as List).map((e) => Map<String, dynamic>.from(e)),
    );

    final next = {...state};
    for (final u in urls) {
      final mediaId = u['mediaId'];
      final url = u['url'];
      if (mediaId != null && url != null) {
        next[mediaId.toString()] = url.toString();
      }
    }
    state = next;
  }

  void clear() => state = {};
}
