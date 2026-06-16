import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    required this.title,
    required this.dateText,
    required this.timeText,
    required this.venueText,
    required this.onTap,
    required this.bgColor,
    required this.textColor,
    required this.image,
  });

  final String title;
  final String? dateText;
  final String? timeText;
  final String venueText;
  final VoidCallback onTap;
  final Color bgColor;
  final Color textColor;
  final String image;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        height: 420,
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(22, 22, 18, 18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(19),
          // boxShadow: [
          //   BoxShadow(
          //     blurRadius: 18,
          //     offset: const Offset(0, 10),
          //     color: Colors.black.withOpacity(0.22),
          //   ),
          // ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title.toLowerCase() == 'nikah' || title.toLowerCase() == 'nikkah'
                ? Image.asset(image, height: 96)
                : SvgPicture.asset(image, height: 96),

            SizedBox(height: 18),

            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 36,
                fontFamily: 'Montage',
                height: 1.0,
                fontWeight: FontWeight.w500,
                // fontFamily: "YourSerifFont",
              ),
            ),

            SizedBox(height: 18),

            InfoRow(
              icon: Icons.calendar_month_rounded,
              text: dateText ?? "-",
              textColor: textColor,
            ),
            SizedBox(height: 10),
            InfoRow(
              icon: Icons.access_time_rounded,
              text: timeText == null ? "-" : "$timeText onwards",
              textColor: textColor,
            ),
            SizedBox(height: 10),
            InfoRow(
              icon: Icons.location_on_rounded,
              text: venueText.isEmpty ? "-" : venueText,
              textColor: textColor,
            ),

            const Spacer(),

            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFFF4D9E6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.icon,
    required this.text,
    required this.textColor,
  });
  final IconData icon;
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: textColor),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'SFPRO',
              color: textColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
