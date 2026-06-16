import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// final eventMediaStreamProvider = StreamProvider.family<List<Map<String, dynamic>>, ({String weddingId, String eventId})>(
//   (ref, args) {
//     return FirebaseFirestore.instance
//         .collection('weddings')
//         .doc(args.weddingId)
//         .collection('events')
//         .doc(args.eventId)
//         .collection('media')
//         // .orderBy('likeCount', descending: true)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
//   },
// );

final eventMediaStreamProvider =
    StreamProvider.family<
      List<Map<String, dynamic>>,
      ({String weddingId, String eventId})
    >((ref, args) {
      final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // 1. Listen to the media collection
      return FirebaseFirestore.instance
          .collection('weddings')
          .doc(args.weddingId)
          .collection('events')
          .doc(args.eventId)
          .collection('media')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((snap) async {
            // 2. For every photo, check if the current user exists in the 'likes' sub-collection
            final docsWithLikes = await Future.wait(
              snap.docs.map((doc) async {
                final data = doc.data();

                // Check if user liked this specific media
                final likeSnap = await doc.reference
                    .collection('likes')
                    .doc(myUid)
                    .get();

                return {
                  'id': doc.id,
                  ...data,
                  'isLikedByMe': likeSnap.exists, // <--- WE INJECT THIS HERE
                };
              }),
            );

            return docsWithLikes;
          });
    });

// final eventMediaStreamProvider = StreamProvider.family<
//     List<Map<String, dynamic>>,
//     ({String weddingId, String eventId, bool sortByLikes})>(
//   (ref, args) {
//     final base = FirebaseFirestore.instance
//         .collection('weddings')
//         .doc(args.weddingId)
//         .collection('events')
//         .doc(args.eventId)
//         .collection('media');

//     final query = args.sortByLikes
//         ? base.orderBy('likeCount', descending: true).orderBy('createdAt', descending: true)
//         : base.orderBy('createdAt', descending: true);

//     return query.snapshots().map(
//           (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
//         );
//   },
// );
