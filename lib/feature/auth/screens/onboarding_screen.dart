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

  // Main reveal timeline:
  // 0.00 – 0.45  Image collapses + wave reveal + body slides in
  // 0.25 – 0.45  Badge pops in (stagger)
  // 0.40 – 0.65  Headline slides/fades in (stagger)
  // 0.55 – 0.80  Ornament rotates in (stagger)
  // 0.75 – 1.00  Body text fades in (stagger)
  // 0.85 – 1.00  CTA lifts in last (stagger)

  late final Animation<double> _revealT;
  late final Animation<double> _badgeInT;
  late final Animation<double> _headlineInT;
  late final Animation<double> _svgInT;
  late final Animation<double> _bodyFadeT;
  late final Animation<double> _ctaInT;

  bool _showOnlyImage = true;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _revealT = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.00, 0.45, curve: Curves.easeInOutCubic),
    );

    _badgeInT = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 0.45, curve: Curves.easeOutBack),
    );

    _headlineInT = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.40, 0.65, curve: Curves.easeOutCubic),
    );

    _svgInT = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.55, 0.80, curve: Curves.easeOutBack),
    );

    _bodyFadeT = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.75, 1.00, curve: Curves.easeIn),
    );

    _ctaInT = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.85, 1.00, curve: Curves.easeOutCubic),
    );

    _kickoff();
  }

  Future<void> _kickoff() async {
    // Hold only the image briefly (so nothing else flashes in)
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    setState(() => _showOnlyImage = false);

    // Run the staggered timeline
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

    // Final “resting” layout values (kept from your proportions)
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

          // ===== PHASE 1: Image-only HOLD overlay =====
          if (_showOnlyImage) const Positioned.fill(child: SizedBox.expand()),

          // ===== PHASE 2+: Animated content =====
          if (!_showOnlyImage)
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                // Base reveal progress
                final t = _revealT.value;

                // Animate the “image collapses to header height”
                final double animatedTopImageHeight = lerpDouble(
                  size.height,
                  finalTopImageHeight,
                  t,
                );

                // Animate how much wave overlaps the image
                final double animatedWaveOverlap = lerpDouble(
                  size.height * 0.10,
                  finalWaveOverlap,
                  t,
                );

                // Body starts offscreen then comes up (with wave)
                final double bodySlideY = lerpDouble(size.height * 0.55, 0, t);

                // Wave amplitude grows in (subtle)
                final double waveAmp = lerpDouble(0, 14.0, t);

                // Badge pop in
                final double badgeT = _badgeInT.value;
                final double badgeScale = lerpDouble(0.85, 1.0, badgeT);
                final double badgeOpacity = badgeT.clamp(0.0, 1.0);

                // Headline slide/fade in
                final double headT = _headlineInT.value;
                final double headOpacity = headT.clamp(0.0, 1.0);
                final double headSlideY = lerpDouble(16, 0, headT);

                // SVG rotate/slide in
                final double svgT = _svgInT.value;
                final double svgRotation = lerpDouble(-0.42, 0.0, svgT);
                final double svgSlideY = lerpDouble(22, 0, svgT);
                final double svgOpacity = svgT.clamp(0.0, 1.0);

                // Body text fades in (no slide -> feels premium)
                final double bodyOpacity = _bodyFadeT.value.clamp(0.0, 1.0);

                // CTA comes last (slight lift)
                final double ctaT = _ctaInT.value;
                final double ctaOpacity = ctaT.clamp(0.0, 1.0);
                final double ctaLiftY = lerpDouble(20, 0, ctaT);

                // Layout positioning for the hero stack
                // Keep your original "centered then settle" vibe, but remove jitter:
                final double centeredTop = size.height * 0.38;
                final double finalTop = 56.0;
                // Tie heroTop to revealT so it doesn't fight other elements
                final double heroTopPadding = lerpDouble(
                  centeredTop,
                  finalTop,
                  t,
                );

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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(height: heroTopPadding),

                                            // Smiley badge (staggered)
                                            Opacity(
                                              opacity: badgeOpacity,
                                              child: Transform.scale(
                                                scale: badgeScale,
                                                child: Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color:
                                                          OnboardingScreen._ink,
                                                      width: 3,
                                                    ),
                                                  ),
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons
                                                          .sentiment_satisfied_alt,
                                                      color:
                                                          OnboardingScreen._ink,
                                                      size: 30,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 26),

                                            // Headline (staggered)
                                            Opacity(
                                              opacity: headOpacity,
                                              child: Transform.translate(
                                                offset: Offset(0, headSlideY),
                                                child: Text(
                                                  'Hello our\nfavorite people.',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 30,
                                                    fontFamily: "Montage",
                                                    height: 1.05,
                                                    color:
                                                        OnboardingScreen._ink,
                                                    fontWeight: FontWeight.w400,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 18),

                                            // Ornamental divider (staggered rotate-in)
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

                                            // Body content (staggered fade in)
                                            Opacity(
                                              opacity: bodyOpacity,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 20,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "We can’t wait to celebrate with you!\n\n"
                                                      "We’ve put together a little wedding app so\n"
                                                      "you don’t have to dig through messages.\n\n"
                                                      "Everything you need (and a few fun\n"
                                                      "surprises) will live here.",
                                                      textAlign: TextAlign.left,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        // height: 1.75,
                                                        fontFamily: 'SFPRO',
                                                        color: OnboardingScreen
                                                            ._ink,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    SizedBox(height: 40),

                                                    Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Image.asset(
                                                        'assets/images/signature.png',
                                                      ),
                                                    ),
                                                    // SizedBox(height: 44),
                                                    // SizedBox(height: 72),
                                                  ],
                                                ),
                                              ),
                                            ),
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

                    // Bottom half-circle "Next" button (staggered last)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Opacity(
                        opacity: ctaOpacity,
                        child: Transform.translate(
                          offset: Offset(0, ctaLiftY),
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
