import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wedding_invite/version_1/dashbaord/models/wedding_rsvp_model.dart';
import 'package:wedding_invite/version_1/dashbaord/providers/firestore_provider.dart';

final userRsvpProvider = FutureProvider<RsvpModel?>((ref) async {
  final db = ref.watch(firestoreProvider);
  final weddingId = ref.watch(activeWeddingIdProvider);
  final phone = FirebaseAuth.instance.currentUser?.phoneNumber;

  log('current phone : ${phone}');

  if (phone == null || phone.trim().isEmpty) return null;

  final snap = await db
      .collection('weddings')
      .doc(weddingId)
      .collection('rsvps')
      .where('phone', isEqualTo: phone.trim())
      .limit(1)
      .get();

  if (snap.docs.isEmpty) return null;

  return RsvpModel.fromDoc(snap.docs.first);
});

final ensureWeddingUserDocProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(firestoreProvider);
  final weddingId = ref.watch(activeWeddingIdProvider);

  final user = FirebaseAuth.instance.currentUser;
  final uid = user?.uid;
  final phone = user?.phoneNumber;

  if (uid == null || phone == null || phone.trim().isEmpty) return;

  // First: confirm RSVP exists
  final rsvp = await ref.watch(userRsvpProvider.future);
  if (rsvp == null) return;

  // Create/update user doc
  final userRef = db.collection('users').doc(uid);

  await db.runTransaction((tx) async {
    final snap = await tx.get(userRef);

    final payload = <String, dynamic>{
      "uid": uid,
      "phone": phone.trim(),
      "name": rsvp.name,
      "activeWeddingId": weddingId,
      "rsvpDocId": rsvp.id,
      "updatedAt": FieldValue.serverTimestamp(),
    };

    if (!snap.exists) {
      tx.set(userRef, {...payload, "createdAt": FieldValue.serverTimestamp()});
    } else {
      tx.set(userRef, payload, SetOptions(merge: true));
    }
  });

  // Optional: also store a mapping for quick lookup later
  // users/{uid}/weddings/{weddingId} => {rsvpDocId, joinedAt, ...}
});
