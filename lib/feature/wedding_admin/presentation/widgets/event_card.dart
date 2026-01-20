import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wedding_invite/feature/wedding_admin/domain/event_model.dart';

class AppColors {
  static const primary = Color(0xFFC06A78);
  static const accent = Color(0xFF5C3C3C);
  static const gold = Color(0xFFC59C6E);
  static const background = Color(0xFFFFF8F3);
  static const cardBorder = Color(0xFFE6D4C2);
}


class WeddingEventCard extends StatelessWidget {
  final Event event;

  const WeddingEventCard({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final date =
        DateFormat('EEE, dd MMM • h:mm a').format(event.dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// --- Top Row ---
          Row(
            children: [
              _EventIcon(type: event.type),
              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.accent,
                size: 28,
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// --- Date ---
          Text(
            date,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.accent.withOpacity(0.75),
            ),
          ),

          const SizedBox(height: 10),

          /// --- Location ---
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 16,
                color: AppColors.accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.venue,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// --- Theme Tag ---
          if (event.theme.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                event.theme,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}


class _EventIcon extends StatelessWidget {
  final EventType type;

  const _EventIcon({required this.type});

  IconData getIcon() {
    switch (type) {
      case EventType.haldi:
        return Icons.wb_sunny_rounded;
      case EventType.mehendi:
        return Icons.spa_rounded;
      case EventType.wedding:
        return Icons.favorite_rounded;
      case EventType.reception:
        return Icons.wine_bar_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        getIcon(),
        color: AppColors.accent,
        size: 20,
      ),
    );
  }
}
