import 'package:flutter/material.dart';
import 'package:wedding_invite/feature/guest_list/models/wedding_guest.dart';
import 'package:wedding_invite/utils/phone_utils.dart';

class GuestOverviewCard extends StatelessWidget {
  final String weddingName;
  final int totalGuests;

  const GuestOverviewCard({
    required this.weddingName,
    required this.totalGuests,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            colors.primary.withOpacity(0.9),
            colors.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          // soft decorative circle
          Positioned(
            right: -20,
            top: -10,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.18),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.18),
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Master guest list',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weddingName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        MetricPill(
                          label: 'Total guests',
                          value: '$totalGuests',
                        ),
                        const SizedBox(width: 8),
                        MetricPill(
                          label: 'Source',
                          value: 'Phone contacts',
                          icon: Icons.smartphone_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const MetricPill({
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class GuestTile extends StatelessWidget {
  final WeddingGuest guest;

  const GuestTile({required this.guest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final initials = _initialsFromName(guest.name);
    final phone = normalizePhone(guest.phone);

    return Stack(
      children: [
        // decorative soft circle
        Positioned(
          right: -18,
          bottom: -16,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withOpacity(0.08),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                const Color(0xFFFFECEF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withOpacity(0.7),
                      colors.primary.withOpacity(0.35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // main text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guest.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.secondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      phone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.secondary.withOpacity(0.75),
                      ),
                    ),
                    if (guest.email != null &&
                        guest.email!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        guest.email!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.secondary.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // trailing badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: colors.primary.withOpacity(0.12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Added',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _initialsFromName(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts[0].characters.first + parts[1].characters.first)
        .toUpperCase();
  }
}

class EmptyGuestList extends StatelessWidget {
  const EmptyGuestList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 42,
              color: colors.primary.withOpacity(0.8),
            ),
            const SizedBox(height: 12),
            Text(
              'No guests yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start by adding people from your phone contacts. You can refine per event later.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.secondary.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
