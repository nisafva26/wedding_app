import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final r2SignedUrlCacheProvider =
    StateNotifierProvider<R2SignedUrlCacheController, Map<String, String>>(
  (ref) => R2SignedUrlCacheController(ref),
);

class R2SignedUrlCacheController extends StateNotifier<Map<String, String>> {
  R2SignedUrlCacheController(this.ref) : super({});
  final Ref ref;

  final _callable = FirebaseFunctions.instance.httpsCallable('getR2SignedUrls');

  /// Ensure signed URLs exist in cache for these R2 keys.
  Future<void> ensureKeys({
    required String weddingId,
    required List<String> r2Keys,
  }) async {
    // de-dupe + only missing
    final unique = r2Keys.where((k) => k.isNotEmpty).toSet().toList();
    final missing = unique.where((k) => !state.containsKey(k)).toList();
    if (missing.isEmpty) return;

    // chunking (safe batch size)
    const chunkSize = 40;
    final next = {...state};

    for (var i = 0; i < missing.length; i += chunkSize) {
      final chunk = missing.sublist(i, (i + chunkSize).clamp(0, missing.length));

      final res = await _callable.call({
        'weddingId': weddingId,
        'items': chunk.map((k) => {'key': k}).toList(),
      });

      final data = Map<String, dynamic>.from(res.data as Map);
      final urls = List<Map<String, dynamic>>.from(
        (data['urls'] as List).map((e) => Map<String, dynamic>.from(e)),
      );

      for (final u in urls) {
        final key = u['key']?.toString();
        final url = u['url']?.toString();
        if (key != null && url != null) {
          next[key] = url;
        }
      }
    }

    state = next;
  }

  String? urlForKey(String? r2Key) {
    if (r2Key == null) return null;
    return state[r2Key];
  }

  void clear() => state = {};
}