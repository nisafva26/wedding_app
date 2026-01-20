import 'package:flutter/material.dart';

class PremiumStickyButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData icon;
  final Color backgroundColor;

  const PremiumStickyButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon = Icons
        .credit_card_outlined, // Matches the credit card icon in your image
    this.backgroundColor = const Color(0xFF06471D), // Your deep green
  });

  @override
  Widget build(BuildContext context) {
    // Using a SafeArea ensures the button doesn't hit the bottom gesture bar on iOS
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 12.0,
        ).copyWith(top: 20),
        child: Material(
          color: backgroundColor,
          // Pill shape
          borderRadius: BorderRadius.circular(100),
          elevation: 2,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(100),
            child: Container(
              height: 48, // Matches the tall, premium height in your image
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 1.50,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
