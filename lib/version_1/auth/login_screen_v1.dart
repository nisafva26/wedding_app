import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:wedding_invite/feature/auth/controller/auth_notifier.dart';

// Match colors from UI
const Color _maroonColor = Color(0xFF801540);

class LoginScreenV1 extends ConsumerStatefulWidget {
  const LoginScreenV1({super.key});

  @override
  _LoginScreenV1State createState() => _LoginScreenV1State();
}

class _LoginScreenV1State extends ConsumerState<LoginScreenV1> {
  final TextEditingController phoneController = TextEditingController(
    text: "+971",
  );
  final TextEditingController otpController = TextEditingController();

  void _onContinuePressed() {
    final authNotifier = ref.read(authProvider.notifier);
    final authState = ref.read(authProvider);

    if (authState == AuthState.otpSent || authState == AuthState.otpError) {
      // Logic for OTP verification
      if (otpController.text.length == 6) {
        authNotifier.verifyOTP(otpController.text, ref);
      }
    } else {
      // Logic for sending OTP
      if (phoneController.text.isNotEmpty) {
        authNotifier.sendOTP(phoneController.text.trim(), ref);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen for state changes (Navigation & Toasts)
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next == AuthState.authenticated) {
        context.go('/success');
      } else if (next == AuthState.otpError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid OTP"),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    // Check if we are currently in OTP mode
    bool isOtpMode =
        authState == AuthState.otpSent ||
        authState == AuthState.otpError ||
        authState == AuthState.verifying;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Full Screen Background Pattern
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/main_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            child: SvgPicture.asset(
              'assets/images/login_bg_vector.svg',
              fit: BoxFit.cover,
              colorFilter: const ColorFilter.mode(
                Color(0xffA41862),
                BlendMode.srcIn,
              ),
            ),
          ),

          // 2. Content
          SafeArea(
            child: SingleChildScrollView(
              // padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // const SizedBox(height: 30),

                  // 3. The Scalloped Container using your Vector image
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // The Scalloped Image as Background
                      Image.asset(
                        'assets/images/Vector.png',
                        width: MediaQuery.sizeOf(context).width,
                        fit: BoxFit.fitHeight,

                        // height: MediaQuery.sizeOf(context).height*.7,
                      ),

                      // Text & Inputs sitting inside the Vector
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 80,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: isOtpMode
                              ? _buildOtpContent()
                              : _buildPhoneContent(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 4. Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed:
                          (authState == AuthState.sendingOtp ||
                              authState == AuthState.verifying)
                          ? null
                          : _onContinuePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _maroonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child:
                          (authState == AuthState.sendingOtp ||
                              authState == AuthState.verifying)
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Confirm",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Phone UI Content ---
  Widget _buildPhoneContent() {
    return Column(
      key: const ValueKey("PhoneView"),
      children: [
        const Text(
          "Let's get you in",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontFamily: 'Serif',
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Pop in your phone number to unlock your wedding info.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 20),
        const Icon(
          Icons.more_horiz,
          color: Colors.white,
          size: 40,
        ), // Or your divider image
        const SizedBox(height: 30),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Mobile number",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // --- OTP UI Content ---
  Widget _buildOtpContent() {
    return Column(
      key: const ValueKey("OtpView"),
      children: [
        const Text(
          "Verify OTP",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontFamily: 'Serif',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Code sent to ${phoneController.text}",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15),
        ),
        const SizedBox(height: 30),
        Pinput(
          length: 6,
          controller: otpController,
          keyboardType: TextInputType.number,
          defaultPinTheme: PinTheme(
            width: 45,
            height: 45,
            textStyle: const TextStyle(
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onCompleted: (pin) => _onContinuePressed(),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () =>
              ref.read(authProvider.notifier).state = AuthState.idle,
          child: const Text(
            "Edit Number",
            style: TextStyle(
              color: Colors.white,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
