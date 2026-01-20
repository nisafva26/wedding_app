import 'package:flutter/material.dart';

class InsightContributionCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget icon;
  final Color backgroundColor;
  final Color textColor;

  const InsightContributionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.backgroundColor = const Color(0xFFDCFFE9), // Your mint green
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 14),
      width: 165, // Set fixed width for horizontal scrolling
      padding: const EdgeInsets.fromLTRB(19, 36, 19, 15),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Container
          SizedBox(height: 24, width: 24, child: icon),
          // const SizedBox(height: 36), // Large gap as per design
          Spacer(),
          Text(
            title,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'SFPRO',
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontFamily: 'SFPRO',
              fontWeight: FontWeight.w400,
              height: 1.38,
            ),
          ),
        ],
      ),
    );
  }
}
