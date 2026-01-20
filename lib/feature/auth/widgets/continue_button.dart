// lib/widgets/auth/continue_button.dart
import 'package:flutter/material.dart';

// Theme colors
const Color _primaryRose = Color(0xFFC06A78);

class ContinueButtonWithLoading extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const ContinueButtonWithLoading({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: isLoading ? () {} : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _primaryRose,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}