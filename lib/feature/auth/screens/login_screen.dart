// lib/screens/auth/login_screen.dart
import 'dart:developer';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:wedding_invite/feature/auth/controller/auth_notifier.dart';
import 'package:wedding_invite/feature/auth/widgets/continue_button.dart';
import 'package:wedding_invite/feature/auth/widgets/country_selection_sheet.dart';
import 'package:wedding_invite/feature/auth/widgets/skip_login_modal.dart';

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
      final locale = PlatformDispatcher.instance.locale;
      final countryCode = locale.countryCode;

      final defaultCountry = CountryService().getAll().firstWhere(
        (c) =>
            c.countryCode.toUpperCase() == (countryCode?.toUpperCase() ?? 'IN'),
        orElse: () => Country(
          phoneCode: '91',
          countryCode: 'IN',
          e164Sc: 0,
          geographic: true,
          level: 1,
          name: 'India',
          example: '9876543210',
          displayName: 'India',
          displayNameNoCountryCode: 'India',
          e164Key: '',
        ),
      );

      setState(() {
        selectedCountry = defaultCountry;
        countryPhoneCode = defaultCountry.phoneCode;
        countryPhoneLength = defaultCountry.example.length;
      });
    }
  }

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
                padding: const EdgeInsets.symmetric(
                  // horizontal: 20,
                  vertical: 0,
                ).copyWith(top: 60),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          'assets/images/Vector.png',
                          width: MediaQuery.sizeOf(context).width,
                          // fit: BoxFit.fitHeight,

                          // height: MediaQuery.sizeOf(context).height*.7,
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

                    SizedBox(height: 30),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
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
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        key: const ValueKey("PhoneView"),
        children: [
          const Text(
            "Let's get you in",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontFamily: 'Montage',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Pop in your phone number to unlock your wedding info.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              fontSize: 20,
              height: 1.4,
              fontFamily: 'SFPRO',
            ),
          ),
          const SizedBox(height: 20),
          const Icon(
            Icons.more_horiz,
            color: Colors.white,
            size: 40,
          ), // Or your divider image
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Mobile number",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),

          // TextField(
          //   controller: phoneController,
          //   keyboardType: TextInputType.phone,
          //   style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          //   decoration: InputDecoration(
          //     filled: true,
          //     fillColor: Colors.white,
          //     contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          //   ),
          // ),
          Row(
            children: [
              // Country Picker Box
              GestureDetector(
                onTap: () async {
                  //   final selected = await showModalBottomSheet<Country>(
                  //     context: context,
                  //     isScrollControlled: true,
                  //     builder: (_) => Padding(
                  //       padding: EdgeInsets.only(
                  //         bottom: MediaQuery.of(context).viewInsets.bottom,
                  //       ),
                  //       child: CountrySelectorSheet(selected: selectedCountry),
                  //     ),
                  //   );

                  //   if (selected != null) {
                  //     setState(() {
                  //       selectedCountry = selected;
                  //       countryPhoneLength = selected.example.length;
                  //       countryPhoneCode = selected.phoneCode;
                  //     });
                  //   }
                  showCountryPicker(
                    context: context,
                    showPhoneCode: true,
                    onSelect: (selected) {
                      setState(() {
                        selectedCountry = selected;
                        countryPhoneLength = selected.example.length;
                        countryPhoneCode = selected.phoneCode;
                      });
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: _primaryRose.withOpacity(.6)),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Text(
                        selectedCountry!.flagEmoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+${selectedCountry!.phoneCode}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: _darkAccent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: _darkAccent),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Phone Number Input
              Expanded(
                child: TextField(
                  
                  controller: phoneController,
                  // focusNode: phoneFocusNode,
                  // keyboardType: TextInputType.none,
                  style: const TextStyle(color: _darkAccent),
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _primaryRose.withOpacity(.6),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: _primaryRose,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 16,
                    ),
                    hintText: selectedCountry!.example,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              ),
            ],
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
        const Text(
          "Verify OTP",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontFamily: 'Montage',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Code sent to ${phoneController.text}",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 15,
            fontFamily: 'SFPRO',
          ),
        ),
        const SizedBox(height: 30),
        Pinput(
          length: 6,
          controller: otpController,
          keyboardType: TextInputType.number,
          defaultPinTheme: PinTheme(
            width: 50,
            height: 50,
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
              fontFamily: 'SFPRO',
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildPhoneNumberInput(AuthState authState) {
    if (selectedCountry == null) {
      return const Center(
        child: CircularProgressIndicator(),
      ); // Defensive check
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 70),
        Text(
          "Enter your\nmobile number",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: _darkAccent,
            height: 50 / 40,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Please enter your phone number then we will send OTP to verify you.",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: _darkAccent.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 30),

        /// Input row
        Row(
          children: [
            // Country Picker Box
            GestureDetector(
              onTap: () async {
                final selected = await showModalBottomSheet<Country>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: CountrySelectorSheet(selected: selectedCountry),
                  ),
                );

                if (selected != null) {
                  setState(() {
                    selectedCountry = selected;
                    countryPhoneLength = selected.example.length;
                    countryPhoneCode = selected.phoneCode;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: _primaryRose.withOpacity(.6)),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Text(
                      selectedCountry!.flagEmoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+${selectedCountry!.phoneCode}',
                      style: const TextStyle(fontSize: 16, color: _darkAccent),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: _darkAccent),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Phone Number Input
            Expanded(
              child: TextField(
                controller: phoneController,
                focusNode: phoneFocusNode,
                keyboardType: TextInputType.none,
                style: const TextStyle(color: _darkAccent),
                decoration: InputDecoration(
                  labelStyle: TextStyle(
                    color: _darkAccent.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _primaryRose.withOpacity(.6),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primaryRose, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 16,
                  ),
                  hintText: selectedCountry!.example,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 43),
        ContinueButtonWithLoading(
          isLoading: authState == AuthState.sendingOtp,
          onPressed: _onContinuePressed,
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            showGuestGateSheet(context, ref);
          },
          child: const Text(
            'Continue without login',
            style: TextStyle(color: _primaryRose),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildOTPInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 70),
        Text(
          "Enter your\npasscode",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: _darkAccent,
            height: 50 / 40,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Check your SMS inbox, we have sent the code at \n+$countryPhoneCode${phoneController.text}",
          style: TextStyle(fontSize: 16, color: _darkAccent.withOpacity(0.7)),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Pinput(
            length: 6,
            autofocus: true,
            controller: otpController,
            focusNode: otpFocusNode,
            keyboardType: TextInputType.none,
            defaultPinTheme: PinTheme(
              height: 64,
              textStyle: const TextStyle(
                fontSize: 40,
                color: _darkAccent,
                fontWeight: FontWeight.w500,
              ),
              decoration: BoxDecoration(
                color: _background.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _primaryRose.withOpacity(0.5)),
              ),
            ),
            focusedPinTheme: PinTheme(
              height: 64,
              textStyle: const TextStyle(
                fontSize: 40,
                color: _darkAccent,
                fontWeight: FontWeight.w500,
              ),
              decoration: BoxDecoration(
                color: _background.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _primaryRose, width: 2),
              ),
            ),
            submittedPinTheme: PinTheme(
              height: 64,
              textStyle: const TextStyle(
                fontSize: 40,
                color: _darkAccent,
                fontWeight: FontWeight.w500,
              ),
              decoration: BoxDecoration(
                color: _background.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _primaryRose.withOpacity(0.5)),
              ),
            ),
            onCompleted: (value) {
              _onContinuePressed();
            },
          ),
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            TextButton(
              onPressed: () {},
              child: Text(
                "Did not receive code?",
                style: TextStyle(fontSize: 14, color: _darkAccent),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text(
                "Resend Code",
                style: TextStyle(
                  fontSize: 14,
                  color: _primaryRose,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildCustomNumberPad() {
    List<String> keys = [
      "1",
      "2",
      "3",
      "4",
      "5",
      "6",
      "7",
      "8",
      "9",
      ".",
      "0",
      "⌫",
    ];
    final authState = ref.watch(authProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15).copyWith(top: 0),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8).copyWith(bottom: 18),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 150 / 78,
        ),
        itemCount: keys.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _onKeyPressed(keys[index], authState),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _primaryRose.withOpacity(0.1),
              ),
              alignment: Alignment.center,
              child: Text(
                keys[index],
                style: const TextStyle(
                  fontSize: 24,
                  color: _darkAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onKeyPressed(String value, AuthState authState) {
    SystemSound.play(SystemSoundType.click);

    setState(() {
      if (authState == AuthState.idle ||
          authState == AuthState.sendingOtp ||
          authState == AuthState.error) {
        // User is entering phone number
        if (value == "⌫") {
          if (phoneController.text.isNotEmpty) {
            phoneController.text = phoneController.text.substring(
              0,
              phoneController.text.length - 1,
            );
          }
        } else if (value != '.' &&
            phoneController.text.length < countryPhoneLength) {
          // Restrict length and prevent '.'
          phoneController.text += value;
        }
      } else if (authState == AuthState.otpSent) {
        // User is entering OTP
        if (value == "⌫") {
          if (otpController.text.isNotEmpty) {
            otpController.text = otpController.text.substring(
              0,
              otpController.text.length - 1,
            );
          }
        } else if (value != '.' && otpController.text.length < 6) {
          // Restrict length and prevent '.'
          otpController.text += value;
        }
      }
    });
  }
}
