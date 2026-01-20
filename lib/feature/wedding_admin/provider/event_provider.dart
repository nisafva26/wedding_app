import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wedding_invite/feature/wedding_admin/domain/event_model.dart';

class EventsController {
  final FirebaseFirestore _db;

  EventsController(this._db);

  CollectionReference<Map<String, dynamic>> _eventsCol(String weddingId) {
    return _db
        .collection('weddings')
        .doc(weddingId)
        .collection('events');
  }

  Future<void> addEvent(Event event) async {
    // If id is empty, generate one
    final col = _eventsCol(event.weddingId);
    final docRef =
        event.id.isEmpty ? col.doc() : col.doc(event.id);

    final toSave = event.copyWith(id: docRef.id);
    await docRef.set(toSave.toMap());
  }

  Future<void> updateEvent(Event event) async {
    if (event.id.isEmpty) {
      throw ArgumentError('Event id cannot be empty for update');
    }
    final docRef = _eventsCol(event.weddingId).doc(event.id);
    await docRef.update(event.toMap());
  }

  Future<void> deleteEvent({
    required String weddingId,
    required String eventId,
  }) async {
    await _eventsCol(weddingId).doc(eventId).delete();
  }
}

final eventsControllerProvider = Provider<EventsController>((ref) {
  return EventsController(FirebaseFirestore.instance);
});
