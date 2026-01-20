import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wedding_invite/feature/guest_list/models/wedding_guest.dart';
import 'package:wedding_invite/utils/phone_utils.dart';

final _firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final weddingGuestsStreamProvider =
    StreamProvider.family<List<WeddingGuest>, String>((ref, weddingId) async* {
      final snapshots = ref
          .read(_firestoreProvider)
          .collection('weddings')
          .doc(weddingId)
          .collection('guests')
          .orderBy('name')
          .snapshots();

      yield* snapshots.map(
        (snap) =>
            snap.docs.map((d) => WeddingGuest.fromDoc(weddingId, d)).toList(),
      );
    });

class GuestInput {
  final String name;
  final String phone;
  final String? email;
  final String? sourceContactId;

  GuestInput({
    required this.name,
    required this.phone,
    this.email,
    this.sourceContactId,
  });
}

class WeddingGuestsController {
  final FirebaseFirestore _db;
  WeddingGuestsController(this._db);

  Future<void> upsertGuests({
    required String weddingId,
    required List<GuestInput> guests,
  }) async {
    final batch = _db.batch();
    final guestsColl = _db
        .collection('weddings')
        .doc(weddingId)
        .collection('guests');

    final guestIndexColl = _db.collection('guestIndex');

    for (final g in guests) {
      final normalizedPhone = normalizePhone(g.phone);
      // Use sourceContactId if present, otherwise let Firestore create an id
      final docRef = g.sourceContactId != null
          ? guestsColl.doc(g.sourceContactId)
          : guestsColl.doc();

      // Check if this guest already exists
      final snap = await docRef.get();
      final isNew = !snap.exists;

      batch.set(docRef, {
        'name': g.name.trim(),
        'phone': g.phone.trim(), // here you can plug your normalizePhone()
        'email': g.email?.trim(),
        'sourceContactId': g.sourceContactId,
        if (isNew) 'masterInviteSent': false,
        if (isNew) 'masterInviteSentAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
        if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2) Upsert into global guestIndex by phone
      final guestIndexRef = guestIndexColl.doc(normalizedPhone);
      final guestIndexSnap = await guestIndexRef.get();

      Map<String, dynamic> weddingsMap = {};
      if (guestIndexSnap.exists) {
        final data = guestIndexSnap.data();
        if (data != null && data['weddings'] is Map) {
          weddingsMap = Map<String, dynamic>.from(
            data['weddings'] as Map<String, dynamic>,
          );
        }
      }

      // For this phone, set/overwrite entry for this weddingId
      weddingsMap[weddingId] = {
        'guestId': docRef.id, // the guest doc id we just used
        'name': g.name.trim(),
        'email': g.email?.trim(),
        // you can also add things like side/group if you want
      };

      batch.set(guestIndexRef, {
        'phone': normalizedPhone,
        'weddings': weddingsMap,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!guestIndexSnap.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }
}

final weddingGuestsControllerProvider = Provider<WeddingGuestsController>((
  ref,
) {
  final db = ref.read(_firestoreProvider);
  return WeddingGuestsController(db);
});
