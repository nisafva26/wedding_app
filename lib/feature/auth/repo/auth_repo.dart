// lib/data/repos/auth_repo.dart
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;

  Future<void> sendOtp({
    required String phoneNumber,
    required VoidCallback onCodeSent,
    required VoidCallback onVerified,
    required Function(FirebaseAuthException) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        log('Auto verification completed: $credential');
        await _auth.signInWithCredential(credential);
        onVerified();
      },
      verificationFailed: (FirebaseAuthException e) {
        log('Verification Failed: ${e.code} - ${e.message}');
        onError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        log('Code Sent, ID: $verificationId');
        _verificationId = verificationId;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );
  }

  Future<void> verifyOtp(String otp) async {
    if (_verificationId == null) {
      throw Exception('Verification ID is missing. OTP was not sent successfully.');
    }
    
    log('Attempting to verify OTP for ID: $_verificationId with code $otp');
    
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );
    await _auth.signInWithCredential(credential);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
  
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // NOTE: For security, Firebase often requires re-authentication before deletion.
      await user.delete();
    }
  }
}