import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wedding_invite/feature/auth/widgets/gear_loop_rotation.dart';
import 'package:wedding_invite/feature/auth/widgets/gear_shift_rotation.dart';
import 'package:wedding_invite/router/router_provider.dart';

class RsvpIntroScreen extends ConsumerStatefulWidget {
  const RsvpIntroScreen({super.key});

  @override
  ConsumerState<RsvpIntroScreen> createState() => _RsvpIntroScreenState();
}

class _RsvpIntroScreenState extends ConsumerState<RsvpIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  late final Animation<double> _bgX;
  late final Animation<double> _nameY;
  late final Animation<double> _nameFade;
  late final Animation<double> _btnY;
  late final Animation<double> _btnFade;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _bgX = Tween<double>(begin: -0.22, end: 0.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _nameY = Tween<double>(begin: 0.22, end: 0.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.20, 0.80, curve: Curves.easeOutExpo),
      ),
    );

    _nameFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.28, 0.75, curve: Curves.easeOut),
      ),
    );

    _btnY = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _btnFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.60, 1.0, curve: Curves.easeOut),
      ),
    );

    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This is the background of the browser window itself
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Center(
        child: Container(
          // Constrain width to 450px for laptop, but allow it to be smaller for mobile
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          // ClipRect ensures that the sliding background image doesn't bleed
          // outside the 450px wide "mobile" container on laptop.
          child: ClipRect(child: _buildResponsiveContent()),
        ),
      ),
    );
  }

  Widget _buildResponsiveContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // We use 'constraints' from LayoutBuilder instead of MediaQuery
        // so that the UI sizes itself relative to our 450px box.
        final localWidth = constraints.maxWidth;
        final localHeight = constraints.maxHeight;

        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Stack(
              children: [
                // 1. BACKGROUND PAN
                // Positioned.fill(
                //   child: Transform.translate(
                //     offset: Offset(localWidth * _bgX.value, 0),
                //     child: Image.asset(
                //       'assets/images/new_bg.png',
                //       fit: BoxFit.cover,
                //     ),
                //   ),
                // ),
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/new_bg.png',
                    fit: BoxFit.cover,
                    // -1 is far left, 0 is center, 1 is far right
                    alignment: Alignment(-_bgX.value, 0),
                  ),
                ),

                // 2. NAME CLOUD + TEXTS
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: Opacity(
                      opacity: _nameFade.value,
                      child: Transform.translate(
                        offset: Offset(0, localHeight * _nameY.value),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Stack(
                                children: [
                                  //  Image.asset('assets/images/paper.png'),
                                  SmoothGearOscillation(
                                    moveDuration: const Duration(seconds: 3),
                                    holdDuration: const Duration(
                                      milliseconds: 450,
                                    ),
                                    turnsPerSide: .4,
                                    child: SvgPicture.asset(
                                      'assets/images/name_layer.svg',
                                      width: localWidth * 0.85,
                                      colorFilter: const ColorFilter.mode(
                                        Color(0xffAF3467),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Text content inside the cloud
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: localWidth * 0.12,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    // Text(
                                    //   'RSVP',
                                    //   textAlign: TextAlign.center,
                                    //   style: TextStyle(
                                    //     fontSize: 54,
                                    //     fontFamily: 'Montage',
                                    //     height: 1.0,
                                    //     fontWeight: FontWeight.w400,
                                    //     color: Colors.white,
                                    //   ),
                                    // ),
                                    // SizedBox(height: 10),
                                    // Text(
                                    //   'WEDDING INVITATION OF',
                                    //   textAlign: TextAlign.center,
                                    //   style: TextStyle(
                                    //     fontSize: 12,
                                    //     letterSpacing: 2.2,
                                    //     fontWeight: FontWeight.w500,
                                    //     color: Colors.white,
                                    //   ),
                                    // ),
                                    // SizedBox(height: 35),
                                    Text(
                                      'Momina',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 38,
                                        fontFamily: 'Montage',
                                        height: 1.05,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      '&',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'Montage',
                                        height: 1.0,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Nizaj',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Montage',
                                        fontSize: 38,
                                        height: 1.05,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. BUTTON WAVE + TEXT
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Opacity(
                    opacity: _btnFade.value,
                    child: Transform.translate(
                      offset: Offset(0, localHeight * 0.12 * _btnY.value),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          SvgPicture.asset(
                            'assets/images/button_layer.svg',
                            width: localWidth,
                            fit: BoxFit.fitWidth,
                            colorFilter: const ColorFilter.mode(
                              Color(0xffF5D9BB),
                              BlendMode.srcIn,
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () async{
                                    final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool(
                                    'has_seen_init',
                                    true,
                                  );
                                  ref.invalidate(hasSeenInitProvider);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF771549),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Optional: Ensure status bar area is clear on real mobile devices
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(child: SizedBox.shrink()),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
