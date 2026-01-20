import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wedding_invite/version_1/dashbaord/models/wedding_rsvp_model.dart';
import 'package:wedding_invite/version_1/dashbaord/providers/firestore_provider.dart';
import 'package:wedding_invite/version_1/dashbaord/providers/user_provider.dart';

final goingEventsProvider = FutureProvider<List<WeddingEventModel>>((
  ref,
) async {
  final db = ref.watch(firestoreProvider);
  final weddingId = ref.watch(activeWeddingIdProvider);

  final rsvp = await ref.watch(userRsvpProvider.future);
  if (rsvp == null) return [];

  final ids = rsvp.goingEventIds;
  if (ids.isEmpty) return [];

  final refs = ids
      .map(
        (id) => db
            .collection('weddings')
            .doc(weddingId)
            .collection('events')
            .doc(id),
      )
      .toList();

  final snaps = await Future.wait(refs.map((ref) => ref.get()));

  final events = snaps
      .where((s) => s.exists)
      .map(
        (s) => WeddingEventModel.fromDoc(
          s,
        ),
      )
      .toList();

  // Optional: sort by date
  events.sort((a, b) {
    final ad = a.dateTime ?? DateTime(2100);
    final bd = b.dateTime ?? DateTime(2100);
    return ad.compareTo(bd);
  });

  return events;
});