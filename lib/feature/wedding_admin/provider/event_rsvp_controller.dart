// event_rsvp_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventRsvpControllerProvider = Provider<EventRsvpController>((ref) {
  return EventRsvpController(FirebaseFirestore.instance);
});

class EventRsvpController {
  final FirebaseFirestore _db;
  EventRsvpController(this._db);

  Future<void> updateRsvp({
    required String weddingId,
    required String eventId,
    required String eventGuestId,
    required String status, // 'accepted' | 'declined'
  }) async {
    await _db
        .collection('weddings')
        .doc(weddingId)
        .collection('events')
        .doc(eventId)
        .collection('eventGuests')
        .doc(eventGuestId)
        .update({
      'status': status,
      'rsvpUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
