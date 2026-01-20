import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wedding_invite/feature/auth/controller/auth_notifier.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// For now: single wedding hardcode (fast ship)
const kActiveWeddingId = "u7MmJS2IEIjOGax9E6md";
final activeWeddingIdProvider = Provider<String>((ref) => kActiveWeddingId);

// You MUST expose the logged in user's phone somewhere.
// Replace this with your actual auth provider/state.
// final loggedInPhoneProvider = Provider<String?>((ref) {
//  return ref.watch(authProvider).;
//   // return null;
// });
