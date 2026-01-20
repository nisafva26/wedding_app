import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wedding_invite/version_1/gifts/widgets/double_moving_cards.dart';
import 'package:wedding_invite/version_1/gifts/widgets/insight_contribution_card.dart';
import 'package:wedding_invite/version_1/gifts/widgets/premium_sticky_button.dart';
import 'package:wedding_invite/version_1/gifts/widgets/slow_moving_cards.dart';
import 'package:wedding_invite/version_1/outfit_inspo/screens/outfit_inspo_screen.dart';

class GiftScreen extends StatefulWidget {
  const GiftScreen({super.key});

  @override
  State<GiftScreen> createState() => _GiftScreenState();
}

class _GiftScreenState extends State<GiftScreen> {
  late AnimationController _sheetController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      // This stays fixed while the content above scrolls
      bottomNavigationBar: PremiumStickyButton(
        text: "Contribute to gift fund",
        onTap: () async {
          final uri = Uri.parse(
            'https://app.groupgift.yougotagift.com/en-ae/contribute/guest/47bb4d0c-8ebb-47e8-95af-c3ef26d3bb18/f8c8964e-bd30-457b-bf43-1545406ea7c5',
          );

          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication, // 👈 opens browser
            );
          } else {
            debugPrint('Could not launch $uri');
          }
        },
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // --- Animated hero image with bottom wave clip ---
                ClipPath(
                  clipper: TripleWaveBottomClipper(
                    waveHeight: 24,
                    amplitude: 18,
                  ),
                  child: Container(
                    height: 300,
                    color: Color(0xff045622),
                    width: MediaQuery.sizeOf(context).width,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 16),
                        Icon(Icons.present_to_all, color: Colors.white),
                        SizedBox(height: 5),
                        Text(
                          'Gift Fund',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontFamily: 'Montage',
                            fontWeight: FontWeight.w400,
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Totally optional. Your presence is more than enough.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            height: 1.43,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- Top Back Button + Tabs ---
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: IconButton(
                            onPressed: () async {
                              _sheetController.reverse();

                              // // 2. Wait for the slide-down to finish (600ms matching the duration above)
                              await Future.delayed(300.ms);
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 38),

                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child:
                Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 35),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 26),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(22, 23, 10, 26),
                            decoration: BoxDecoration(
                              color: Color(0xffDCFFE9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'One gift, shared together.  Everyone can add a little.',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    // height: 1,
                                    color: Colors.black,
                                    fontFamily: 'SFPRO',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 53),
                                Text(
                                  'Contribute together, we’ll choose something we’ll use.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    // height: 1,
                                    color: Colors.black,
                                    fontFamily: 'SFPRO',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 50),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 26),
                          child: Row(
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'We’re using YOUGotaGift\n',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 24,
                                        fontFamily: 'SFPRO',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'a simple way to gift digitally.',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontFamily: 'SFPRO',
                                        fontWeight: FontWeight.w500,
                                        height: 1.71,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Spacer(),
                              Image.asset('assets/images/you_got_gift.png'),
                            ],
                          ),
                        ),
                        SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 26),
                          child: Image.asset('assets/images/happy_you.png'),
                        ),
                        SizedBox(height: 46),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 26),
                          child: Text(
                            'How does it work?',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'SFPRO',
                              fontWeight: FontWeight.w500,
                              height: 1.50,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Example of how to use it in your horizontal list
                        Container(
                          height: 197,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              InsightContributionCard(
                                title: "Chip in",
                                description:
                                    "Add any amount you’re comfortable with",
                                icon: SvgPicture.asset(
                                  'assets/images/coins.svg', // Your uploaded gift icon
                                  color: Colors.black,
                                ), // Replace with your coin asset
                              ),
                              InsightContributionCard(
                                title: "It adds up",
                                description:
                                    "All contributions pool into one total in one account.",
                                icon: SvgPicture.asset(
                                  'assets/images/coins_stack.svg', // Your uploaded gift icon
                                  color: Colors.black,
                                ), // Replace with your stack asset
                              ),
                              InsightContributionCard(
                                title: "Gift",
                                description: "We'll choose from our registry.",

                                // Dark green theme
                                icon: SvgPicture.asset(
                                  color: Colors.black,
                                  'assets/images/shopping_bag_icon.svg', // Your uploaded gift icon
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 50),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 26),
                          child: Text(
                            'Popular gift cards',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'SFPRO',
                              fontWeight: FontWeight.w500,
                              height: 1.50,
                            ),
                          ),
                        ),
                        SizedBox(height: 22),
                        SlowMovingGiftCardsDoubleRow(),
                        SizedBox(height: 300),
                      ],
                    )
                    .animate(
                      onInit: (controller) => _sheetController = controller,
                      // delay: 500.ms,
                    ) // Start the animation chain
                    .fadeIn(
                      duration: 800.ms,
                      delay: 300.ms,
                    ) // Fade in after 300ms
                    .slideY(
                      begin: 0.5, // Start from 50% of its height lower
                      end: 0,
                      duration: 800.ms,
                      curve: Curves.easeOutCubic,
                    ),
          ),
        ],
      ),
    );
  }
}
