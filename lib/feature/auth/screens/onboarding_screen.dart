// onboarding_screen.dart
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wedding_invite/feature/auth/repo/onboarding_provider.dart';
import 'package:wedding_invite/router/router_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const _bg = Color(0xFFE4EECA); // pale green
  static const _ink = Color(0xFF06471D); // dark green
  static const _button = Color(0xFF6D1E48); // burgundy

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Timeline (after the initial 2s image-only hold):
  // 0.00 → 0.55 : wave reveal + image collapses to header height
  // 0.25 → 0.70 : svg rotates in
  // 0.70 → 1.00 : centered hero block slides up to final position
  late final Animation<double> _revealT;
  late final Animation<double> _svgInT;
  late final Animation<double> _heroUpT;

  bool _showOnlyImage = true;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _revealT = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.00, 0.55, curve: Curves.easeInOutCubic),
    );

    _svgInT = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 0.70, curve: Curves.easeOutBack),
    );

    _heroUpT = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.70, 1.00, curve: Curves.easeInOutCubic),
    );

    _kickoff();
  }

  Future<void> _kickoff() async {
    // 1) Hold only image for 2 seconds
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    setState(() => _showOnlyImage = false);

    // 2) Run the main animation timeline
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;

    // Final “resting” layout values (your original proportions)
    final double finalTopImageHeight = size.height * 0.18;
    final double finalWaveOverlap = size.height * 0.06;

    return Scaffold(
      backgroundColor: OnboardingScreen._bg,
      body: Stack(
        children: [
          // ===== FULLSCREEN IMAGE (always exists) =====
          Positioned.fill(
            child: Image.asset(
              'assets/images/main_bg.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // ===== PHASE 1: Image-only HOLD overlay (so nothing else is visible) =====
          if (_showOnlyImage)
            Positioned.fill(child: Container(color: Colors.transparent)),

          // ===== PHASE 2+: Animated content =====
          if (!_showOnlyImage)
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                // Reveal progress 0..1
                final t = _revealT.value;

                // Animate the “image collapses to header height”
                final double animatedTopImageHeight = lerpDouble(
                  size.height,
                  finalTopImageHeight,
                  t,
                );

                // Animate how much wave overlaps the image (settles to final)
                final double animatedWaveOverlap = lerpDouble(
                  size.height * 0.10,
                  finalWaveOverlap,
                  t,
                );

                // Body starts offscreen then comes up (with wave)
                // When t=0, push body down; when t=1, body at normal position
                final double bodySlideY = lerpDouble(size.height * 0.55, 0, t);

                // Wave amplitude grows in
                final double waveAmp = lerpDouble(0, 15.0, t);

                // The centered hero block moves up to its final position later
                // When heroUpT=0: centered. When heroUpT=1: final top padding.
                final double heroUp = _heroUpT.value;
                final double centeredTop =
                    size.height * 0.40; // visually centered
                final double finalTop = 76.0; // your original spacing
                final double heroTopPadding = lerpDouble(
                  centeredTop,
                  finalTop,
                  heroUp,
                );

                // SVG rotate/slide in
                final double svgIn = _svgInT.value;
                final double svgRotation = lerpDouble(
                  -0.45,
                  0.0,
                  svgIn,
                ); // ~ -25deg to 0
                final double svgSlideY = lerpDouble(30, 0, svgIn);
                final double svgOpacity = svgIn.clamp(0.0, 1.0);

                return Stack(
                  children: [
                    // BODY with animated wave edge
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(0, bodySlideY),
                        child: Column(
                          children: [
                            SizedBox(
                              height:
                                  animatedTopImageHeight - animatedWaveOverlap,
                            ),
                            Expanded(
                              child: ClipPath(
                                clipper: _TopWaveClipperAnimated(
                                  waveHeight: waveAmp,
                                  yOffset: lerpDouble(40.0, 20.0, t),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  color: OnboardingScreen._bg,
                                  child: SafeArea(
                                    top: false,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 28,
                                      ),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            SizedBox(height: heroTopPadding),

                                            // Smiley badge
                                            Container(
                                              width: 54,
                                              height: 54,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: OnboardingScreen._ink,
                                                  width: 3,
                                                ),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.sentiment_satisfied_alt,
                                                  color: OnboardingScreen._ink,
                                                  size: 30,
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 26),

                                            // Headline
                                            Text(
                                              'Hello our\nfavorite people.',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 40,
                                                fontFamily: "Montage",
                                                height: 1.05,
                                                color: OnboardingScreen._ink,
                                                fontWeight: FontWeight.w400,
                                                letterSpacing: 0.2,
                                              ),
                                            ),

                                            const SizedBox(height: 18),

                                            // Ornamental divider (rotates in)
                                            Opacity(
                                              opacity: svgOpacity,
                                              child: Transform.translate(
                                                offset: Offset(0, svgSlideY),
                                                child: Transform.rotate(
                                                  angle: svgRotation * math.pi,
                                                  child: SvgPicture.asset(
                                                    'assets/images/onboarding_vector_1.svg',
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 30),

                                            // Rest content becomes visible after hero moves up
                                            // (We fade it in slightly as heroUp progresses)
                                            Opacity(
                                              opacity: Curves.easeIn.transform(
                                                heroUp,
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    "We can’t wait to celebrate with you.\n\n"
                                                    "We put together a little wedding app so\n"
                                                    "you don’t have to dig through messages.\n\n"
                                                    "Everything you need (and a few fun\n"
                                                    "surprises) will live here.",
                                                    textAlign: TextAlign.left,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      height: 1.75,
                                                      fontFamily: 'SFPRO',
                                                      color:
                                                          OnboardingScreen._ink,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 28),
                                                  Text(
                                                    'Momina & Nizaj',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 34,
                                                      height: 1.0,
                                                      color:
                                                          OnboardingScreen._ink,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 44),
                                                  const SizedBox(height: 72),
                                                ],
                                              ),
                                            ),

                                            // const Spacer(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // // Bottom half-circle "Next" button (stays, but you can also fade it in later if you want)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Opacity(
                        opacity: Curves.easeIn.transform(heroUp),
                        child: SizedBox(
                          height: 84,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                height: 5,
                                color: OnboardingScreen._button,
                              ),
                              _HalfCircleButton(
                                color: OnboardingScreen._button,
                                onTap: () async {
                                  log('ontap : tapped');

                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool(
                                    'has_seen_onboarding',
                                    true,
                                  );

                                  ref.invalidate(hasSeenOnboardingProvider);
                                  context.go('/login');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

class _HalfCircleButton extends StatelessWidget {
  const _HalfCircleButton({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 101,
        height: 84,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(999),
            topRight: Radius.circular(999),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.only(top: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_downward, color: Colors.white, size: 18),
              SizedBox(height: 2),
              Text(
                'Next',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'SFPRO',
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopWaveClipperAnimated extends CustomClipper<Path> {
  _TopWaveClipperAnimated({required this.waveHeight, required this.yOffset});

  final double waveHeight;
  final double yOffset;

  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, yOffset);

    path.quadraticBezierTo(
      size.width * 0.125,
      yOffset - waveHeight,
      size.width * 0.25,
      yOffset,
    );

    path.quadraticBezierTo(
      size.width * 0.375,
      yOffset + waveHeight,
      size.width * 0.50,
      yOffset,
    );

    path.quadraticBezierTo(
      size.width * 0.625,
      yOffset - waveHeight,
      size.width * 0.75,
      yOffset,
    );

    path.quadraticBezierTo(
      size.width * 0.875,
      yOffset + waveHeight,
      size.width,
      yOffset,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant _TopWaveClipperAnimated oldClipper) {
    return oldClipper.waveHeight != waveHeight || oldClipper.yOffset != yOffset;
  }
}
