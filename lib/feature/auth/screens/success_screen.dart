// lib/screens/auth/success_screen.dart
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wedding_invite/feature/auth/screens/login_screen.dart';

class SuccessScreen extends ConsumerStatefulWidget {
  const SuccessScreen({super.key});

  @override
  ConsumerState<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends ConsumerState<SuccessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePostLogin();
    });
  }

  String _normalizePhone(String phone) {
    // Keep +, remove spaces and hyphens
    return phone.replaceAll(RegExp(r'\s|-'), '');
  }

  Future<void> _handlePostLogin() async {
    log('inside handle post login');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        log('SuccessScreen: no Firebase user, returning to /');
        if (mounted) context.go('/');
        return;
      }

      final uid = user.uid;
      final phone = user.phoneNumber;

      if (phone == null) {
        log('SuccessScreen: user has no phoneNumber');
      }

      final usersRef =
          FirebaseFirestore.instance.collection('users').doc(uid);
      final existingSnap = await usersRef.get();

      // 1) Check guestIndex by phone
      Map<String, dynamic> invitedWeddings = {};
      String accountType = 'user'; // default

      if (phone != null) {
        final normalized = _normalizePhone(phone);
        final guestIndexRef = FirebaseFirestore.instance
            .collection('guestIndex')
            .doc(normalized);
        final guestIndexSnap = await guestIndexRef.get();

        if (guestIndexSnap.exists) {
          final data = guestIndexSnap.data();
          invitedWeddings =
              Map<String, dynamic>.from(data?['weddings'] ?? {});
          if (invitedWeddings.isNotEmpty) {
            accountType = 'guest';
          }
          log('SuccessScreen: guestIndex hit, invited to ${invitedWeddings.keys.toList()}');
        } else {
          log('SuccessScreen: no guestIndex doc for $normalized');
        }
      }

      // Preserve existing adminWeddingIds if any
      List<dynamic> adminWeddingIds = [];
      if (existingSnap.exists) {
        final data = existingSnap.data();
        if (data != null && data['adminWeddingIds'] is List) {
          adminWeddingIds = List<dynamic>.from(data['adminWeddingIds']);
        }
      }

      // 2) Upsert user document
      await usersRef.set(
        {
          'uid': uid,
          'phoneNumber': phone,
          'email': user.email,
          'photoUrl': user.photoURL,
          'accountType': accountType, // 'user' or 'guest' (admin later)
          'invitedWeddings': invitedWeddings,
          'adminWeddingIds': adminWeddingIds,
          'updatedAt': FieldValue.serverTimestamp(),
          if (!existingSnap.exists) 'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Re-read to check name
      final finalSnap = await usersRef.get();
      final finalData = finalSnap.data() ?? {};
      final name = (finalData['name'] as String?)?.trim();

      ref.read(justLoggedInProvider.notifier).state = false;

      if (!mounted) return;

      context.go('/home');

      // if (name == null || name.isEmpty) {
      //   // No name yet → go to UserDetails to collect only name
      //   context.go('/user-details');
      // } else {
      //   // Name exists → go straight to home
      //   context.go('/home');
      // }
    } catch (e, st) {
      log('SuccessScreen _handlePostLogin error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong. Please try again.')),
      );
      context.go('/'); // fall back to login
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simple loading screen with your pastel theme
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
