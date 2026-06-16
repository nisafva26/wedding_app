import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      // height: 78,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        color: widget.primaryColor, // base glass
      ),
      child: Stack(
        children: [
          // back left darker slab (like screenshot)
          Positioned.fill(
            left: 0,
            right: 110.w,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: widget.primaryColor,
              ),
            ),
          ),

          // main pill content
          Row(
            children: [
               SizedBox(width: 13.w),
               Text(
                "To go",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontFamily: 'SFPRO',
                  fontWeight: FontWeight.w500,
                ),
              ),
               SizedBox(width: 13.w),

              // days block
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  color: widget.secondaryColor,
                ),
                child: Padding(
                  padding:  EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 14.w,
                  ),
                  child: Row(
                    children: [
                      _BigValueBlock(value: days.toString(), label: "Days"),
                      // divider
                      Container(
                        width: 1,
                        height: 46.h,
                        margin:  EdgeInsets.symmetric(horizontal: 18.w),
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
          style:  TextStyle(
            color: Colors.white,
            fontSize: 30.sp,
            height: 0.95,
            fontFamily: 'SFPRO',
            fontWeight: FontWeight.w400,
          ),
        ),
         SizedBox(height: 2.h),
        Text(
          label,
          style:  TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
            fontFamily: 'SFPRO',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
