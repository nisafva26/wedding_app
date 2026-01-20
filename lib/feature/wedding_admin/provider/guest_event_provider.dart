import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wedding_invite/feature/wedding_admin/domain/event_model.dart';
import 'package:wedding_invite/feature/wedding_admin/event_details/models/guest_event_model.dart';
import 'package:wedding_invite/utils/phone_utils.dart';

final userPhoneProvider = FutureProvider<String?>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;

  final snap = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();

  final data = snap.data() ?? {};
  final rawPhone = data['phoneNumber'] as String?;
  if (rawPhone == null || rawPhone.trim().isEmpty) return null;

  return normalizePhone(rawPhone); // your existing helper
});

// final invitedEventsForGuestStreamProvider = StreamProvider.autoDispose
//     .family<List<Event>, String>((ref, weddingId) {
//       final phoneAsync = ref.watch(userPhoneProvider);

//       log('indie invited event stream');

//       return phoneAsync.when(
//         // Phone loaded
//         data: (phone) {
//           if (phone == null) {
//             log('phone is null');
//             return Stream.value(<Event>[]);
//           }
//           log('phone not null');


//           final eventsCol = FirebaseFirestore.instance
//               .collection('weddings')
//               .doc(weddingId)
//               .collection('events');

//           // Listen to events; for each snapshot, filter by eventGuests
//           return eventsCol.snapshots().asyncMap((eventsSnap) async {
//             final List<Event> invited = [];

//             log('events snap : $eventsSnap');

//             for (final eDoc in eventsSnap.docs) {
//               final guestSnap = await eDoc.reference
//                   .collection('eventGuests')
//                   .where('phone', isEqualTo: phone)
//                   .limit(1)
//                   .get();

//               if (guestSnap.docs.isNotEmpty) {
//                 invited.add(Event.fromFirestore(eDoc.data(), eDoc.id));
//               }
//             }

//             invited.sort((a, b) => a.dateTime.compareTo(b.dateTime));
//             return invited;
//           });
//         },

//         // While phone is loading
//         loading: () => Stream.value(<Event>[]),

//         // On error just return empty
//         error: (_, __) => Stream.value(<Event>[]),
//       );
//     });



final guestInvitedEventsStreamProvider =
    StreamProvider.autoDispose.family<List<GuestEventInvite>, String>(
  (ref, weddingId) {
    final phoneAsync = ref.watch(userPhoneProvider);

    return phoneAsync.when(
      data: (phone) {
        if (phone == null) return Stream.value([]);

        final eventsColl = FirebaseFirestore.instance
            .collection('weddings')
            .doc(weddingId)
            .collection('events');

        // MAIN OUTPUT STREAM CONTROLLER
        final controller = StreamController<List<GuestEventInvite>>();

        // We will store all stream subscriptions here
        final List<StreamSubscription> subs = [];

        // Start by listening to events list
        final eventsSub = eventsColl.snapshots().listen((eventsSnap) {
          // Clear old subscriptions
          for (final s in subs) {
            s.cancel();
          }
          subs.clear();

          if (eventsSnap.docs.isEmpty) {
            controller.add([]);
            return;
          }

          // Local buffer of results
          final Map<String, GuestEventInvite?> buffer = {};

          for (final eDoc in eventsSnap.docs) {
            final event = Event.fromFirestore(eDoc.data(), eDoc.id);

            // Stream eventGuests for this event
            final sub = eDoc.reference
                .collection('eventGuests')
                .where('phone', isEqualTo: phone)
                .snapshots()
                .listen((guestSnap) {
              if (guestSnap.docs.isEmpty) {
                buffer[eDoc.id] = null;
              } else {
                final g = guestSnap.docs.first.data();
                buffer[eDoc.id] = GuestEventInvite(
                  weddingId: weddingId,
                  eventId: eDoc.id,
                  eventGuestId: guestSnap.docs.first.id,
                  event: event,
                  status: g['status'] ?? 'pending',
                );
              }

              // Emit updated list
              final list = buffer.values
                  .where((e) => e != null)
                  .cast<GuestEventInvite>()
                  .toList()
                ..sort(
                  (a, b) => a.event.dateTime.compareTo(b.event.dateTime),
                );

              controller.add(list);
            });

            subs.add(sub);
          }
        });

        // Dispose all listeners when provider is destroyed
        ref.onDispose(() {
          eventsSub.cancel();
          for (final s in subs) {
            s.cancel();
          }
          controller.close();
        });

        return controller.stream;
      },
      loading: () => Stream.value([]),
      error: (_, __) => Stream.value([]),
    );
  },
);

