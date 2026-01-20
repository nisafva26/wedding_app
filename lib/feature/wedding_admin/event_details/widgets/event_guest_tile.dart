// lib/feature/wedding_admin/event_details/widgets/event_guest_tile.dart (REFINED)

import 'package:flutter/material.dart';
import 'package:wedding_invite/feature/wedding_admin/event_details/providers/event_guest_provider.dart';
import 'package:wedding_invite/utils/phone_utils.dart';

// --- PREMIUM COLOR PALETTE & RSVP COLORS ---
const _kColorAccentRose = Color(0xFFB48395);
const _kColorTextPrimary = Color(0xFF4A3022);
const _kColorTextSecondary = Color(0xFF8F6C53);
const _kBorderColor = Color(0xFFE5D5C7);

const _kColorAccepted = Color(0xFF7CB342);
const _kColorPending = Color(0xFFFFA726);
const _kColorDeclined = Color(0xFFE53935);

// --- RSVP HELPER FUNCTIONS (adapted for String status) ---

Color _getRsvpColor(String status) {
  final s = status.toLowerCase();
  if (s.contains('accepted') || s.contains('yes')) {
    return _kColorAccepted;
  } else if (s.contains('declined') || s.contains('no')) {
    return _kColorDeclined;
  }
  return _kColorPending;
}

IconData _getRsvpIcon(String status) {
  final s = status.toLowerCase();
  if (s.contains('accepted') || s.contains('yes')) {
    return Icons.check_circle_rounded;
  } else if (s.contains('declined') || s.contains('no')) {
    return Icons.cancel_rounded;
  }
  return Icons.pending_rounded;
}


class EventGuestTile extends StatelessWidget {
  final EventGuest guest;

  const EventGuestTile({required this.guest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;

    final initials = _initialsFromName(guest.name);
    final phone = normalizePhone(guest.phone);
    final hasEmail = guest.email != null && guest.email!.trim().isNotEmpty;
    final rsvpColor = _getRsvpColor(guest.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorderColor.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: _kColorTextPrimary.withOpacity(0.04), // Subtle shadow
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. AVATAR (Clean, subtle background)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Use a solid, subtle accent color background
              color: _kColorAccentRose.withOpacity(0.12),
            ),
            child: Center(
              child: Text(
                initials,
                style: t.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _kColorAccentRose,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 2. GUEST DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guest.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _kColorTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      size: 14,
                      color: _kColorTextSecondary.withOpacity(0.75),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: t.bodySmall?.copyWith(
                        color: _kColorTextSecondary.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
                if (hasEmail)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.email_rounded,
                          size: 14,
                          color: _kColorTextSecondary.withOpacity(0.55),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            guest.email!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall?.copyWith(
                              color: _kColorTextSecondary.withOpacity(0.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 3. RSVP STATUS (Clear, Color-Coded Pill)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: rsvpColor.withOpacity(0.12), // Subtle color background
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getRsvpIcon(guest.status),
                  size: 16,
                  color: rsvpColor,
                ),
                const SizedBox(width: 6),
                Text(
                  guest.status,
                  style: t.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: rsvpColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Initials logic (retained)
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

class EmptyEventGuests extends StatelessWidget {
  const EmptyEventGuests();

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
              Icons.event_busy_rounded,
              size: 40,
              color: _kColorAccentRose.withOpacity(0.8), // Use accent color
            ),
            const SizedBox(height: 12),
            Text(
              'No one added yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: _kColorTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Use the Manage button above to pick guests from your master list for this ceremony.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _kColorTextSecondary.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}