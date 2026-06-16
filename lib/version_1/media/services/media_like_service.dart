import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

class MediaLikeService {
  MediaLikeService(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _mediaRef({
    required String weddingId,
    required String eventId,
    required String mediaId,
  }) {
    return _db
        .collection('weddings')
        .doc(weddingId)
        .collection('events')
        .doc(eventId)
        .collection('media')
        .doc(mediaId);
  }

  DocumentReference<Map<String, dynamic>> _likeRef({
    required String weddingId,
    required String eventId,
    required String mediaId,
    required String uid,
  }) {
    return _mediaRef(weddingId: weddingId, eventId: eventId, mediaId: mediaId)
        .collection('likes')
        .doc(uid);
  }

  /// Stream: whether current user liked this media
  Stream<bool> isLikedStream({
    required String weddingId,
    required String eventId,
    required String mediaId,
    required String uid,
  }) {
    return _likeRef(
      weddingId: weddingId,
      eventId: eventId,
      mediaId: mediaId,
      uid: uid,
    ).snapshots().map((snap) => snap.exists);
  }

  /// Toggle like/unlike atomically
  Future<void> toggleLike({
    required String weddingId,
    required String eventId,
    required String mediaId,
    required String uid,
  }) async {
    final mediaRef =
        _mediaRef(weddingId: weddingId, eventId: eventId, mediaId: mediaId);
    final likeRef = _likeRef(
      weddingId: weddingId,
      eventId: eventId,
      mediaId: mediaId,
      uid: uid,
    );

    await _db.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);

      if (likeSnap.exists) {

        log('===like exisit===');
        // Unlike
        tx.delete(likeRef);
        tx.set(
          mediaRef,
          {'likeCount': FieldValue.increment(-1)},
          SetOptions(merge: true),
        );
      } else {
         log('===like doesnt exisit===');
        // Like
        tx.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        tx.set(
          mediaRef,
          {'likeCount': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      }
    });
  }
}
