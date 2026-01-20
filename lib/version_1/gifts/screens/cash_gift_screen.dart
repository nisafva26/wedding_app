import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wedding_invite/version_1/gifts/widgets/aani_card.dart';
import 'package:wedding_invite/version_1/gifts/widgets/bank_details_card.dart';
import 'package:wedding_invite/version_1/gifts/widgets/double_moving_cards.dart';
import 'package:wedding_invite/version_1/gifts/widgets/insight_contribution_card.dart';
import 'package:wedding_invite/version_1/gifts/widgets/premium_sticky_button.dart';
import 'package:wedding_invite/version_1/gifts/widgets/slow_moving_cards.dart';
import 'package:wedding_invite/version_1/outfit_inspo/screens/outfit_inspo_screen.dart';

class CashGiftScreen extends StatefulWidget {
  const CashGiftScreen({super.key});

  @override
  State<CashGiftScreen> createState() => _CashGiftScreenState();
}

class _CashGiftScreenState extends State<CashGiftScreen>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
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
                    color: Color(0xff771549),
                    width: MediaQuery.sizeOf(context).width,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 16),
                        Icon(Icons.present_to_all, color: Colors.white),
                        SizedBox(height: 5),
                        Text(
                          'Cash Gift',
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
                              color: Color(0xffFFE0F0),
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
                                  'Not a yacht. We checked.',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontFamily: 'SFPRO',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 13),

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
                                backgroundColor: Color(0xffFFE0F0),
                                title: "Transfer \nany amount",
                                description:
                                    "Send whatever you’re comfortable with",
                                icon: SvgPicture.asset(
                                  'assets/images/coins.svg', // Your uploaded gift icon
                                  color: Colors.black,
                                ), // Replace with your coin asset
                              ),
                              InsightContributionCard(
                                backgroundColor: Color(0xffFFE0F0),
                                title: "Add\na note (optional)",
                                description:
                                    "Use your name in the reference so we know it’s from you.",
                                icon: SvgPicture.asset(
                                  'assets/images/clipboard.svg', // Your uploaded gift icon
                                  color: Colors.black,
                                ), // Replace with your stack asset
                              ),
                              InsightContributionCard(
                                backgroundColor: Color(0xffFFE0F0),
                                title: "You’re done",
                                description:
                                    "The “yacht fund” appreciates you ",

                                // Dark green theme
                                icon: SvgPicture.asset(
                                  color: Colors.black,
                                  'assets/images/anchor.svg', // Your uploaded gift icon
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 50),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 26),
                          child: Column(
                            children: [
                              _buildTabs(),
                              SizedBox(height: 24),

                              _tab == 0
                                  ? Column(
                                      children: [
                                        Text(
                                          'If bank transfer is easiest, add us as a beneficiary and send a cash gift anytime. \n\nIt will be received in our shared account.',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontFamily: 'SFPRO',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        SizedBox(height: 29),
                                        BankDetailsCard(
                                          payee:
                                              "Nizaj Salim Vaduthalaveetil Aboobacker\n& Momina Chaudhry Naseem Tajammul\nChaudhry",
                                          bankName: "WIO Bank PJSC",
                                          iban: "AE120860000006323712706",
                                          accountNo: "6323712706",
                                          swift: "WIOBAEADXXX",
                                          address:
                                              "Etihad Airways Centre 5th Floor, Abu\nDhabi, UAE",
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text:
                                                    'Instant UAE transfer via mobile number - no IBAN needed.\n\n',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                  fontFamily: 'SFPRO',
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    'Quick, simple, and secure.',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                  fontFamily: 'SFPRO',
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 29),
                                        AaniCard(
                                          name: 'Nizaj Salim',
                                          phoneNumber: '+971 55 9533 272',
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ),

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

  Widget _buildTabs() {
    return Row(
      children: ["Bank", "Aani"].asMap().entries.map((e) {
        final selected = _tab == e.key;

        return GestureDetector(
          onTap: () async {
            setState(() => _tab = e.key);

            // if (e.key == 0) {
            //   await _scrollTo(_detailsKey);
            // } else if (e.key == 1) {
            //   await _scrollTo(_outfitKey);
            // } else {
            //   await _scrollTo(_eventKey);
            // }
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Opacity(
              opacity: selected ? 1 : .3,
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Montage',
                  color: Color(0xff771549),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
