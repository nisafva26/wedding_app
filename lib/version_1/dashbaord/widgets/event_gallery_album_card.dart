import 'dart:developer';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wedding_invite/version_1/media/screens/event_gallery_page.dart';

class EventGalleryAlbumCard extends StatelessWidget {
  final String weddingId;
  final String eventId;
  final String title;

  final Color bgColor;
  final Color textColor;

  final int imageCount;
  final int videoCount;
  final String image;

  /// Only image preview URLs (skip videos). If empty -> we show NOTHING (no placeholders).
  final List<String> previewUrls;

  const EventGalleryAlbumCard({
    super.key,
    required this.weddingId,
    required this.eventId,
    required this.title,
    required this.bgColor,
    required this.textColor,
    required this.imageCount,
    required this.videoCount,
    required this.previewUrls,
    required this.image,
  });

  void _openGallery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EventGalleryPage(weddingId: weddingId, eventId: eventId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = imageCount + videoCount;
    final hasPreviews = previewUrls
        .where((e) => e.trim().isNotEmpty)
        .isNotEmpty;

    // log('preview urls : $previewUrls - event : $title');

    // Premium shadow
    final shadowColor = Colors.black.withOpacity(0.10);

    return InkWell(
      borderRadius: BorderRadius.circular(22.r),
      onTap: () => _openGallery(context),
      child: Container(
        width: 0.44.sw,
        padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 18.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title.toLowerCase() == 'nikah' ||
                        title.toLowerCase() == 'nikkah'
                    ? Image.asset(image, height: 67.h)
                    : SvgPicture.asset(image, height: 67.h),

                // SizedBox(width: 10.w),
                Spacer(),
                _ArrowButton(fg: textColor, onTap: () => _openGallery(context)),
              ],
            ),
            SizedBox(height: 16.h),

            SizedBox(
              height: 32.h, // reserve consistent space for title
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 22.sp,
                      fontFamily: 'Montage',
                      height: 1.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // ── Title row: title + arrow button ──
            // Expanded(
            //   child: Text(
            //     title,
            //     maxLines: 1,
            //     overflow: TextOverflow.ellipsis,
            //     style: TextStyle(
            //       color: textColor,
            //       fontSize: 22.sp,
            //       fontFamily: 'Montage',
            //       height: 1.0,
            //       fontWeight: FontWeight.w500,
            //     ),
            //   ),
            // ),
            SizedBox(height: 14.h),

            // ── Preview circles (ONLY if we have previews) ──
            if (hasPreviews) ...[
              _PreviewStack(
                urls: previewUrls,
                ringColor: Colors.white.withOpacity(0.22),
                fallbackBg: Colors.white.withOpacity(0.10),
                fg: textColor,
              ),
              SizedBox(height: 12.h),
            ],
            Spacer(),

            // ── Counts row (photo + video) ──
            Row(
              children: [
                _CountChip(
                  icon: Icons.image_outlined,
                  text: '$imageCount',
                  fg: textColor,
                ),
                SizedBox(width: 10.w),
                _CountChip(
                  icon: Icons.videocam_outlined,
                  text: '$videoCount',
                  fg: textColor,
                ),
                const Spacer(),
                // Right side: total or empty label
                // Text(
                //   total == 0 ? 'Empty' : '$total',
                //   style: TextStyle(
                //     color: textColor.withOpacity(0.85),
                //     fontFamily: 'SFPRO',
                //     fontSize: 12.sp,
                //     fontWeight: FontWeight.w800,
                //     letterSpacing: 0.2,
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────
/// Arrow button (top-right)
/// ─────────────────────────────────────────
class _ArrowButton extends StatelessWidget {
  final Color fg;
  final VoidCallback onTap;

  const _ArrowButton({required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: SizedBox(
        width: 38.r,
        height: 38.r,
        child: Icon(
          Icons.arrow_forward_rounded,
          size: 18.sp,
          color: fg.withOpacity(0.95),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────
/// Preview stack rules:
/// - show up to 4 circles
/// - if >4, show 3 circles + "+N"
/// - NO placeholders / ghost circles
/// ─────────────────────────────────────────
class _PreviewStack extends StatelessWidget {
  final List<String> urls;
  final Color ringColor;
  final Color fallbackBg;
  final Color fg;

  const _PreviewStack({
    required this.urls,
    required this.ringColor,
    required this.fallbackBg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final list = urls.where((e) => e.trim().isNotEmpty).toList();
    final count = list.length;

    final double size = 34.r;
    final double overlap = 22.r;

    // This widget should only be used when count > 0,
    // but still safe-guard:
    if (count == 0) return const SizedBox.shrink();

    final bool showMore = count > 4;
    final int visible = showMore ? 3 : count.clamp(1, 4);

    final double totalWidth =
        size + (visible - 1) * overlap + (showMore ? overlap : 0);

    return SizedBox(
      height: size,
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < visible; i++)
            Positioned(
              left: i * overlap,
              child: _CircleImage(
                size: size,
                ringColor: ringColor,
                fallbackBg: fallbackBg,
                url: list[i],
              ),
            ),
          if (showMore)
            Positioned(
              left: visible * overlap,
              child: _MoreBubble(
                size: size,
                ringColor: ringColor,
                bg: fallbackBg,
                text: '+${count - visible}',
                fg: fg,
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleImage extends StatelessWidget {
  final double size;
  final Color ringColor;
  final Color fallbackBg;
  final String url;

  const _CircleImage({
    required this.size,
    required this.ringColor,
    required this.fallbackBg,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 2),
        color: fallbackBg,
      ),
      child: ClipOval(

        child: CachedNetworkImage(imageUrl: url,fit: BoxFit.cover,),
        // child: Image.network(
        //   url,
        //   fit: BoxFit.cover,
        //   errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        // ),
      ),
    );
  }
}

class _MoreBubble extends StatelessWidget {
  final double size;
  final Color ringColor;
  final Color bg;
  final String text;
  final Color fg;

  const _MoreBubble({
    required this.size,
    required this.ringColor,
    required this.bg,
    required this.text,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 2),
        color: bg,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg.withOpacity(0.92),
          fontFamily: 'SFPRO',
          fontSize: 12.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────
/// Chips (frosted)
/// ─────────────────────────────────────────
class _CountChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color fg;

  const _CountChip({required this.icon, required this.text, required this.fg});

  @override
  Widget build(BuildContext context) {
    return _FrostPill(
      radius: 999.r,
      bgOpacity: 0.10,
      borderOpacity: 0.14,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: fg.withOpacity(0.95)),
            SizedBox(width: 6.w),
            Text(
              text,
              style: TextStyle(
                color: fg.withOpacity(0.95),
                fontFamily: 'SFPRO',
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────
/// Frosted primitive (icon/chips)
/// ─────────────────────────────────────────
class _FrostPill extends StatelessWidget {
  final Widget child;
  final double radius;
  final double bgOpacity;
  final double borderOpacity;

  const _FrostPill({
    required this.child,
    required this.radius,
    required this.bgOpacity,
    required this.borderOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(bgOpacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(borderOpacity)),
          ),
          child: child,
        ),
      ),
    );
  }
}
