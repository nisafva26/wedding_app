// lib/screens/auth/login_screen.dart
import 'dart:developer';
import 'dart:ui';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:pinput/pinput.dart';
import 'package:wedding_invite/feature/auth/controller/auth_notifier.dart';
import 'package:wedding_invite/router/router_provider.dart';

// Placeholder for the modal
const Color _maroonColor = Color(0xFF801540);
// Theme colors
const Color _primaryRose = Color(0xFFC06A78);
const Color _darkAccent = Color(0xFF5C3C3C);
const Color _background = Color(0xFFFFF8F3);

final justLoggedInProvider = StateProvider<bool>((ref) => false);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  TextEditingController phoneController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  String? phoneNumber;
  int countryPhoneLength = 10;
  String countryPhoneCode = '91';
  Country? selectedCountry;

  late FocusNode phoneFocusNode;
  late FocusNode otpFocusNode;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    phoneFocusNode = FocusNode();
    otpFocusNode = FocusNode();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(phoneFocusNode);
      }
    });
  }

  void _onContinuePressed() {
    final authNotifier = ref.read(authProvider.notifier);
    final authState = ref.read(authProvider);

    if (authState == AuthState.idle || authState == AuthState.error) {
      log(
        'Phone number to send: +$countryPhoneCode${phoneController.text.trim()}',
      );
      if (phoneController.text.length == countryPhoneLength) {
        authNotifier.sendOTP(
          '+$countryPhoneCode${phoneController.text.trim()}',
          ref,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid phone number")),
        );
      }
    } else if (authState == AuthState.otpSent ||
        authState == AuthState.otpError) {
      authNotifier.verifyOTP(otpController.text, ref);
    }
  }

  void _setDefaultCountryFromLocale() {
    if (selectedCountry == null) {
      // We ignore the device locale entirely to prevent UK/IN misdetection
      final defaultCountry = CountryService().getAll().firstWhere(
        (c) => c.countryCode.toUpperCase() == 'AE',
        orElse: () => Country(
          phoneCode: '971',
          countryCode: 'AE',
          e164Sc: 0,
          geographic: true,
          level: 1,
          name: 'United Arab Emirates',
          example: '501234567',
          displayName: 'United Arab Emirates',
          displayNameNoCountryCode: 'United Arab Emirates',
          e164Key: '',
        ),
      );

      setState(() {
        selectedCountry = defaultCountry;
        countryPhoneCode = defaultCountry.phoneCode;
        // This ensures the UI allows exactly 9 digits for UAE mobile numbers
        countryPhoneLength = defaultCountry.example.length;
      });
    }
  }

  // void _setDefaultCountryFromLocale() {
  //   if (selectedCountry == null) {
  //     final locale = PlatformDispatcher.instance.locale;
  //     final countryCode = locale.countryCode;

  //     final defaultCountry = CountryService().getAll().firstWhere(
  //       (c) =>
  //           c.countryCode.toUpperCase() == (countryCode?.toUpperCase() ?? 'IN'),
  //       orElse: () => Country(
  //         phoneCode: '91',
  //         countryCode: 'IN',
  //         e164Sc: 0,
  //         geographic: true,
  //         level: 1,
  //         name: 'India',
  //         example: '9876543210',
  //         displayName: 'India',
  //         displayNameNoCountryCode: 'India',
  //         e164Key: '',
  //       ),
  //     );

  //     setState(() {
  //       selectedCountry = defaultCountry;
  //       countryPhoneCode = defaultCountry.phoneCode;
  //       countryPhoneLength = defaultCountry.example.length;
  //     });
  //   }
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setDefaultCountryFromLocale();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next == AuthState.authenticated) {
        log('====Authenticated, navigating to /success');
        ref.read(justLoggedInProvider.notifier).state = true;
        context.go('/success');
      } else if (next == AuthState.otpError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid OTP. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
        // Reset state so user can re-enter OTP
        ref.read(authProvider.notifier).state = AuthState.otpSent;
      } else if (next == AuthState.otpSent) {
        Fluttertoast.showToast(msg: "OTP sent successfully.");
      } else if (next == AuthState.verifying) {
        Fluttertoast.showToast(msg: "Verifying OTP...");
      }
    });

    return Scaffold(
      backgroundColor: _background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
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
                  // colorFilter: const ColorFilter.mode(
                  //   Color(0xffA41862),
                  //   BlendMode.srcIn,
                  // ),
                ),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  // horizontal: 20,
                  vertical: 0,
                ).copyWith(top: 60.h),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                              'assets/images/pattern_vector.png',
                              width: MediaQuery.sizeOf(context).width,
                              // height: MediaQuery.sizeOf(context).height/1.2,
                              // fit: BoxFit.fitWidth,

                              // height: MediaQuery.sizeOf(context).height*.7,
                            )
                            .animate()
                            .fadeIn(
                              duration: 500.ms,
                              curve: Curves.easeOutCubic,
                            )
                            .slideY(
                              begin: 0.25, // comes from bottom
                              end: 0,
                              duration: 600.ms,
                              curve: Curves.easeOutCubic,
                            ),
                        IntrinsicHeight(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (widget, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: widget,
                              );
                            },
                            child:
                                (authState == AuthState.otpSent ||
                                    authState == AuthState.otpError ||
                                    authState == AuthState.verifying)
                                ? _buildOtpContent()
                                : _buildPhoneContent(),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 58.w,
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
                                      ? const SizedBox(
                                          width: 50,
                                          child: LoadingIndicator(
                                            indicatorType: Indicator
                                                .ballScaleMultiple, // Soft pulsing circles
                                            colors: [
                                              const Color(
                                                0xFF06471D,
                                              ), // Your deep green
                                              const Color(
                                                0xFF8B2B57,
                                              ), // Your badge pink
                                            ],
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          "Confirm",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: 10.h),

                              SizedBox(
                                width: double.infinity,
                                height: 58,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ), // The blur intensity
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        // White with low opacity (0.1 to 0.2) creates the glass look
                                        color: Colors.white.withOpacity(0.15),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(
                                            0.3,
                                          ), // Soft white border
                                          width: 1.5,
                                        ),
                                      ),
                                      child: OutlinedButton(
                                        onPressed: () {
                                          ref
                                                  .read(
                                                    isGuestProvider.notifier,
                                                  )
                                                  .state =
                                              true;
                                          context.go('/home');
                                        },
                                        style: OutlinedButton.styleFrom(
                                          // Remove standard border/side since we defined it in the Container
                                          side: BorderSide.none,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Text(
                                              "Skip login",
                                              style: TextStyle(
                                                color: Colors
                                                    .white, // White text for contrast
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // --- THE UPDATED SKIP BUTTON ---
                              // SizedBox(
                              //   width: double.infinity,
                              //   height: 58,
                              //   child: OutlinedButton(
                              //     onPressed: () {
                              //       ref.read(isGuestProvider.notifier).state =
                              //           true;

                              //       context.go('/home');
                              //     },
                              //     style: OutlinedButton.styleFrom(
                              //       side: const BorderSide(
                              //         color: Colors.white54,
                              //         width: 1.5,
                              //       ),
                              //       shape: RoundedRectangleBorder(
                              //         borderRadius: BorderRadius.circular(30),
                              //       ),
                              //     ),
                              //     child: Row(
                              //       mainAxisAlignment: MainAxisAlignment.center,
                              //       children: const [
                              //         Text(
                              //           "Skip login",
                              //           style: TextStyle(
                              //             color: _maroonColor,
                              //             fontSize: 16,
                              //             fontWeight: FontWeight.w500,
                              //           ),
                              //         ),
                              //         SizedBox(width: 8),
                              //         Icon(
                              //           Icons.arrow_forward_ios,
                              //           color: Colors.white,
                              //           size: 14,
                              //         ),
                              //       ],
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(
                          duration: 500.ms,
                          curve: Curves.easeOutCubic,
                          delay: Duration(milliseconds: 800),
                        )
                        .slideY(
                          begin: 0.25, // comes from bottom
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutCubic,
                        ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Phone UI Content ---
  Widget _buildPhoneContent() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        key: const ValueKey("PhoneView"),
        children: [
          Text(
                "Let's get you in",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 35.sp,
                  fontFamily: 'Montage',
                ),
              )
              .animate()
              .fadeIn(
                duration: 500.ms,
                curve: Curves.easeOutCubic,
                delay: Duration(milliseconds: 600),
              )
              .slideY(
                begin: 0.25, // comes from bottom
                end: 0,
                duration: 600.ms,
                curve: Curves.easeOutCubic,
              ),
          SizedBox(height: 12.h),
          Text(
                "Pop in your phone number to unlock your wedding info.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 18.sp,
                  // height: 1.4,
                  fontFamily: 'SFPRO',
                ),
              )
              .animate()
              .fadeIn(
                duration: 500.ms,
                curve: Curves.easeOutCubic,
                delay: Duration(milliseconds: 800),
              )
              .slideY(
                begin: 0.25, // comes from bottom
                end: 0,
                duration: 600.ms,
                curve: Curves.easeOutCubic,
              ),
          SizedBox(height: 20.h),
          SvgPicture.asset(
            'assets/images/onboarding_vector_1.svg',
            color: Colors.white,
          ), // Or your divider image
          SizedBox(height: 20.h),
          Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Mobile number",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.h,
                    fontFamily: "Inter",
                  ),
                ),
              )
              .animate()
              .fadeIn(
                duration: 500.ms,
                curve: Curves.easeOutCubic,
                delay: Duration(milliseconds: 900),
              )
              .slideY(
                begin: 0.25, // comes from bottom
                end: 0,
                duration: 600.ms,
                curve: Curves.easeOutCubic,
              ),
          SizedBox(height: 8.h),

          Row(
                children: [
                  // Country Picker Box
                  GestureDetector(
                    onTap: () async {
                      showCountryPicker(
                        context: context,
                        showPhoneCode: true,
                        onSelect: (selected) {
                          log('selected : $selected');
                          setState(() {
                            selectedCountry = selected;
                            countryPhoneLength = selected.example.length;
                            countryPhoneCode = selected.phoneCode;
                          });
                        },
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 14.w,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: _primaryRose.withOpacity(.6)),
                        borderRadius: BorderRadius.circular(100),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Text(
                            selectedCountry!.flagEmoji,
                            style: TextStyle(fontSize: 18.sp),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '+${selectedCountry!.phoneCode}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: _darkAccent,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          const Icon(Icons.arrow_drop_down, color: _darkAccent),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Phone Number Input
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      // focusNode: phoneFocusNode,
                      // keyboardType: TextInputType.none,
                      style: const TextStyle(color: _darkAccent),
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        labelStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(
                            color: _primaryRose.withOpacity(.6),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: const BorderSide(
                            color: _primaryRose,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 13.w,
                          horizontal: 16.w,
                        ),
                        hintText: selectedCountry!.example,
                        hintStyle: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(
                duration: 500.ms,
                curve: Curves.easeOutCubic,
                delay: Duration(milliseconds: 900),
              )
              .slideY(
                begin: 0.25, // comes from bottom
                end: 0,
                duration: 600.ms,
                curve: Curves.easeOutCubic,
              ),
        ],
      ),
    );
  }

  // --- OTP UI Content ---
  Widget _buildOtpContent() {
    return Column(
      key: const ValueKey("OtpView"),
      children: [
        Text(
          "Verify OTP",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 40.sp,
            fontFamily: 'Montage',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Code sent to ${phoneController.text}",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 15.sp,
            fontFamily: 'SFPRO',
          ),
        ),
        SizedBox(height: 30.sp),
        Pinput(
          length: 6,
          controller: otpController,
          keyboardType: TextInputType.number,
          defaultPinTheme: PinTheme(
            width: 50.w,
            height: 50.w,
            textStyle: TextStyle(
              fontSize: 20.sp,
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
              fontFamily: 'SFPRO',
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
