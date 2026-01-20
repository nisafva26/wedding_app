// lib/feature/auth/controller/auth_notifier.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:wedding_invite/feature/auth/repo/auth_repo.dart';


enum AuthState {
  idle,
  sendingOtp,
  otpSent,
  verifying,
  authenticated,
  error,
  otpError,
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  AuthNotifier(this._repo) : super(AuthState.idle);

  Future<void> sendOTP(String phone, WidgetRef ref) async {
    state = AuthState.sendingOtp;
    await _repo.sendOtp(
      phoneNumber: phone,
      onCodeSent: () => state = AuthState.otpSent,
      onVerified: () => state = AuthState.authenticated,
      onError: (e) {
        log('verification failed: check ${e.code} - ${e.message}');
        log('error : ${e.toString()}');
        state = AuthState.error;
      },
    );
  }

  Future<void> verifyOTP(String otp, WidgetRef ref) async {
    state = AuthState.verifying;
    try {
      await _repo.verifyOtp(otp);
      state = AuthState.authenticated;
    } catch (e) {
      log('verify error: $e');
      state = AuthState.otpError;
    }
  }

  Future<void> logout(WidgetRef ref, BuildContext router) async {
    try {
      await _repo.logout();
      state = AuthState.idle;
      // Navigate to the root/login screen
      router.go('/'); 
    } catch (e) {
      log('logout failed: $e');
    }
  }
}

// Providers
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);