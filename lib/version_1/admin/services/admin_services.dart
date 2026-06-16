import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> backfillMediaIndexAll(String weddingId) async {
  final fn = FirebaseFunctions.instanceFor(region: 'asia-south1')
      .httpsCallable('backfillMediaIndex');

  Map<String, dynamic>? cursor;
  int total = 0;

  while (true) {
    final res = await fn.call({
      'weddingId': weddingId,
      'batchSize': 200,
      if (cursor != null) 'cursor': cursor,
    });

    final data = Map<String, dynamic>.from(res.data as Map);
    final processed = (data['processed'] ?? 0) as int;
    final done = (data['done'] ?? false) as bool;
    total += processed;

    cursor = data['nextCursor'] == null
        ? null
        : Map<String, dynamic>.from(data['nextCursor'] as Map);

    print('processed=$processed total=$total done=$done');

    if (done || processed == 0) break;
  }
}




Future<Map<String, dynamic>> kickBackfill({
  required String weddingId,
  int limit = 200,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception("User not logged in");
  }

  // Ensure fresh auth token
  await user.getIdToken(true);

  final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final callable = functions.httpsCallable('kickIndexWeddingMedia');

  final res = await callable.call({
    "weddingId": weddingId,
    "limit": limit,
  });

  return Map<String, dynamic>.from(res.data as Map);
}