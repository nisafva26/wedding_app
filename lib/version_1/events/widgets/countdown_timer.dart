import 'dart:async';
import 'package:flutter/material.dart';

class ToGoCountdownPill extends StatefulWidget {
  const ToGoCountdownPill({
    super.key,
    required this.target,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final DateTime target;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  State<ToGoCountdownPill> createState() => _ToGoCountdownPillState();
}

class _ToGoCountdownPillState extends State<ToGoCountdownPill> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = widget.target.difference(now);

    final totalHours = diff.isNegative ? 0 : diff.inHours;
    final days = (totalHours ~/ 24);
    final hours = (totalHours % 24);

    return Container(
      height: 78,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: widget.primaryColor, // base glass
      ),
      child: Stack(
        children: [
          // back left darker slab (like screenshot)
          Positioned.fill(
            left: 0,
            right: 110,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: widget.primaryColor,
              ),
            ),
          ),

          // main pill content
          Row(
            children: [
              const SizedBox(width: 13),
              const Text(
                "To go",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'SFPRO',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 13),

              // days block
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: widget.secondaryColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      _BigValueBlock(value: days.toString(), label: "Days"),
                      // divider
                      Container(
                        width: 1,
                        height: 46,
                        margin: const EdgeInsets.symmetric(horizontal: 18),
                        color: Colors.white.withOpacity(0.35),
                      ),

                      // hours block
                      _BigValueBlock(value: hours.toString(), label: "Hours"),
                    ],
                  ),
                ),
              ),

              // const SizedBox(width: 22),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigValueBlock extends StatelessWidget {
  const _BigValueBlock({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            height: 0.95,
            fontFamily: 'SFPRO',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'SFPRO',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
