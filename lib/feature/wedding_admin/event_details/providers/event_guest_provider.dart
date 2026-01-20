import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wedding_invite/utils/phone_utils.dart';

// for WeddingGuest + GuestInput

final _firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

class EventGuest {
  final String id; // same as master guest id
  final String weddingId;
  final String eventId;
  final String name;
  final String phone;
  final String? email;

  final String status;           // "pending" | "going" | "not_going"
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? rsvpUpdatedAt;

  const EventGuest({
    required this.id,
    required this.weddingId,
    required this.eventId,
    required this.name,
    required this.phone,
    this.email,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
    this.rsvpUpdatedAt,
  });

  factory EventGuest.fromDoc({
    required String weddingId,
    required String eventId,
    required DocumentSnapshot<Map<String, dynamic>> doc,
  }) {
    final data = doc.data() ?? {};
    return EventGuest(
      id: doc.id,
      weddingId: weddingId,
      eventId: eventId,
      name: (data['name'] as String?)?.trim() ?? '',
      phone: (data['phone'] as String?)?.trim() ?? '',
      email: (data['email'] as String?)?.trim(),
      status: (data['status'] as String?) ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      rsvpUpdatedAt: (data['rsvpUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }
}


/// Riverpod family key using a Dart record
typedef EventGuestsKey = ({String weddingId, String eventId});

final eventGuestsStreamProvider =
    StreamProvider.family<List<EventGuest>, EventGuestsKey>((ref, key) async* {
  final db = ref.read(_firestoreProvider);

  final snapshots = db
      .collection('weddings')
      .doc(key.weddingId)
      .collection('events')
      .doc(key.eventId)
      .collection('eventGuests')
      .orderBy('name')
      .snapshots();

  yield* snapshots.map(
    (snap) => snap.docs
        .map((d) => EventGuest.fromDoc(
              weddingId: key.weddingId,
              eventId: key.eventId,
              doc: d,
            ))
        .toList(),
  );
});

/// Input for assigning guests to an event
class EventGuestInput {
  final String guestId; // master guest id
  final String name;
  final String phone;
  final String? email;

  EventGuestInput({
    required this.guestId,
    required this.name,
    required this.phone,
    this.email,
  });
}

class EventGuestsController {
  final FirebaseFirestore _db;
  EventGuestsController(this._db);

  /// Replace event guest list with provided selection.
  /// Handles add / update / delete in one batch.
 Future<void> updateEventGuests({
  required String weddingId,
  required String eventId,
  required List<EventGuestInput> selected,
}) async {
  final coll = _db
      .collection('weddings')
      .doc(weddingId)
      .collection('events')
      .doc(eventId)
      .collection('eventGuests');

  // Existing eventGuests (who are already linked to this event)
  final existingSnap = await coll.get();
  final existingIds = existingSnap.docs.map((d) => d.id).toSet();

  final newIds = selected.map((e) => e.guestId).toSet();
  final toDelete = existingIds.difference(newIds);

  final batch = _db.batch();

  for (final g in selected) {
    final normalizedPhone = normalizePhone(g.phone);
    final docRef = coll.doc(g.guestId);

    final isNew = !existingIds.contains(g.guestId);

    batch.set(
      docRef,
      {
        'name': g.name.trim(),
        'phone': normalizedPhone,
        'email': g.email?.trim(),
        // Only set status + createdAt when we first add them to this event
        if (isNew) 'status': 'pending',
        if (isNew) 'rsvpUpdatedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
        if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // Remove guests that were previously in this event but are no longer selected
  for (final id in toDelete) {
    batch.delete(coll.doc(id));
  }

  await batch.commit();
}

}

final eventGuestsControllerProvider =
    Provider<EventGuestsController>((ref) {
  final db = ref.read(_firestoreProvider);
  return EventGuestsController(db);
});
