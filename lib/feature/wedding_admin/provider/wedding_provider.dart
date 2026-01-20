import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wedding_invite/feature/guest_list/models/wedding_guest.dart';

import 'package:wedding_invite/feature/wedding_admin/domain/event_model.dart';
import 'package:wedding_invite/feature/wedding_admin/domain/wedding_model.dart';
import 'package:wedding_invite/router/router_provider.dart';
import 'package:wedding_invite/utils/phone_utils.dart'; // for authStateProvider

// ---------------- USER DOC ----------------

/// Stream of the logged-in user's profile document: users/{uid}
final currentUserDocProvider =
    StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return const Stream.empty();
      return FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots();
    });

// ---------------- HOSTED WEDDINGS ----------------

/// Weddings where this user is an admin/host.
/// Uses `weddings.admins` arrayContains uid (same as your old currentWedding).
final hostedWeddingsStreamProvider = StreamProvider.autoDispose<List<Wedding>>((
  ref,
) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return const Stream.empty();

  final query = FirebaseFirestore.instance
      .collection('weddings')
      .where('admins', arrayContains: user.uid);

  return query.snapshots().map(
    (snapshot) => snapshot.docs
        .map((doc) => Wedding.fromFirestore(doc.data(), doc.id))
        .toList(),
  );
});

/// Convenience helper: does this user host at least one wedding?
final hasHostedWeddingsProvider = Provider<bool>((ref) {
  final hosted = ref.watch(hostedWeddingsStreamProvider).asData?.value ?? [];
  return hosted.isNotEmpty;
});

/// What is the current user in this wedding?
enum UserWeddingRole { host, guest, none }

/// Stream a single wedding by id
final weddingByIdProvider = StreamProvider.family<Wedding?, String>((
  ref,
  weddingId,
) {
  return FirebaseFirestore.instance
      .collection('weddings')
      .doc(weddingId)
      .snapshots()
      .map(
        (doc) => doc.exists ? Wedding.fromFirestore(doc.data()!, doc.id) : null,
      );
});

final invitedWeddingsStreamProvider = StreamProvider.autoDispose<List<Wedding>>(
  (ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.phoneNumber == null) {
      return const Stream.empty();
    }

    // Use the same normalizePhone you used in upsertGuests()
    final normalizedPhone = normalizePhone(user.phoneNumber!);

    final guestIndexRef = FirebaseFirestore.instance
        .collection('guestIndex')
        .doc(normalizedPhone);

    // Listen to this phone's guestIndex doc
    return guestIndexRef.snapshots().asyncMap((snap) async {
      if (!snap.exists) return <Wedding>[];

      final data = snap.data() as Map<String, dynamic>;
      final weddingsMap =
          (data['weddings'] as Map<String, dynamic>?) ?? <String, dynamic>{};

      final ids = weddingsMap.keys.toList();
      if (ids.isEmpty) return <Wedding>[];

      // Firestore whereIn supports max 10 IDs per query.
      // Chunk if needed.
      final List<List<String>> chunks = [];
      for (var i = 0; i < ids.length; i += 10) {
        chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
      }

      final futures = chunks.map((chunk) {
        return FirebaseFirestore.instance
            .collection('weddings')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
      }).toList();

      final snapshots = await Future.wait(futures);
      final allDocs = snapshots.expand((s) => s.docs);

      return allDocs
          .map((doc) => Wedding.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  },
);

final hasInvitedWeddingsProvider = Provider<bool>((ref) {
  final invited = ref.watch(invitedWeddingsStreamProvider).asData?.value ?? [];
  return invited.isNotEmpty;
});

// ---------------- CURRENT WEDDING (ADMIN “ACTIVE”) ----------------

/// For places where you still want a *single* "current" wedding
/// (e.g. old Admin dashboard), we just pick the first hosted wedding.
final currentWeddingStreamProvider = StreamProvider.autoDispose<Wedding?>((
  ref,
) async* {
  final hostedAsync = ref.watch(hostedWeddingsStreamProvider);

  // Use `when` so we can still be a proper StreamProvider
  yield* hostedAsync.when<Stream<Wedding?>>(
    data: (list) async* {
      if (list.isEmpty) {
        yield null;
      } else {
        // You can later add logic for "last opened" etc.
        yield list.first;
      }
    },
    loading: () async* {
      // while loading, just emit null (UI can show spinner)
      yield null;
    },
    error: (_, __) async* {
      yield null;
    },
  );
});

// ---------------- EVENTS PER WEDDING ----------------

final eventsStreamProvider = StreamProvider.family
    .autoDispose<List<Event>, String?>((ref, weddingId) {
      if (weddingId == null || weddingId.isEmpty) {
        return Stream.value([]);
      }

      return FirebaseFirestore.instance
          .collection('weddings')
          .doc(weddingId)
          .collection('events')
          .orderBy('dateTime')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return Event.fromFirestore(data, doc.id);
            }).toList();
          });
    });

/// Stream all guests for a wedding (for Admin "Guests" tab)
final weddingGuestsProvider = StreamProvider.family<List<WeddingGuest>, String>(
  (ref, weddingId) {
    return FirebaseFirestore.instance
        .collection('weddings')
        .doc(weddingId)
        .collection('guests')
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((d) => WeddingGuest.fromDoc(weddingId, d))
              .toList();
        });
  },
);

final userWeddingRoleProvider =
    FutureProvider.family<UserWeddingRole, String>((ref, weddingId) async {
  final auth = FirebaseAuth.instance;
  final user = auth.currentUser;
  if (user == null) return UserWeddingRole.none;

  // 1) Check host
  final weddingSnap = await FirebaseFirestore.instance
      .collection('weddings')
      .doc(weddingId)
      .get();

  if (!weddingSnap.exists) return UserWeddingRole.none;
  final wData = weddingSnap.data()!;
  final admins =
      (wData['admins'] as List<dynamic>? ?? const []).cast<String>();
  if (admins.contains(user.uid)) return UserWeddingRole.host;

  // 2) Check guest via guestIndex (phone-based)
  final phone = user.phoneNumber;
  if (phone != null && phone.isNotEmpty) {
    // 👇 use the same normalizePhone you used in upsertGuests()
    final normalizedPhone = normalizePhone(phone);

    final guestIndexSnap = await FirebaseFirestore.instance
        .collection('guestIndex')
        .doc(normalizedPhone)
        .get();

    if (guestIndexSnap.exists) {
      final gData = guestIndexSnap.data()!;
      final weddingsMap =
          (gData['weddings'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      if (weddingsMap.containsKey(weddingId)) {
        return UserWeddingRole.guest;
      }
    }
  }

  return UserWeddingRole.none;
});


// Single wedding by id
final weddingByIdStreamProvider =
    StreamProvider.family<Wedding?, String>((ref, weddingId) {
  final docStream = FirebaseFirestore.instance
      .collection('weddings')
      .doc(weddingId)
      .snapshots();

  return docStream.map((snap) {
    if (!snap.exists) return null;
    return Wedding.fromFirestore(snap.data()!, snap.id);
  });
});


