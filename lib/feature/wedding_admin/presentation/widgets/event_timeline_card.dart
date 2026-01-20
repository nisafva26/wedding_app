// lib/feature/wedding_admin/presentation/widgets/event_timeline_card.dart (FINAL PREMIUM DESIGN)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wedding_invite/feature/wedding_admin/domain/event_model.dart';

// --- PREMIUM COLOR PALETTE ---
const _kColorAccentRose = Color(0xFFB48395); // Deep Blush/Rose Gold
const _kColorTextPrimary = Color(0xFF4A3022); // Deep Brown
const _kColorTextSecondary = Color(0xFF8F6C53); // Muted Brown
const _kBorderColor = Color(0xFFE5D5C7); // Light border

class EventTimelineCard extends StatelessWidget {
  final Event event;
  const EventTimelineCard({required this.event});

  // Helper functions (same as before)
  IconData _iconForType(EventType type) {
    switch (type) {
      case EventType.haldi:
        return Icons.color_lens_rounded;
      case EventType.mehendi:
        return Icons.local_florist_rounded;
      case EventType.wedding:
        return Icons.people_alt_rounded;
      case EventType.reception:
        return Icons.celebration_rounded;
      case EventType.other:
      default:
        return Icons.event_note_rounded;
    }
  }

  String _labelForType(EventType type) {
    switch (type) {
      case EventType.haldi:
        return 'HALDI';
      case EventType.mehendi:
        return 'MEHENDI';
      case EventType.wedding:
        return 'THE WEDDING';
      case EventType.reception:
        return 'RECEPTION';
      case EventType.other:
      default:
        return 'EVENT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;

    final timeOnly = DateFormat('h:mm').format(event.dateTime);
    final meridiem = DateFormat('a').format(event.dateTime);
    final typeLabel = _labelForType(event.type);
    final typeIcon = _iconForType(event.type);
    final hasTheme = event.theme.trim().isNotEmpty;
    final hasVenue = event.venue.trim().isNotEmpty;

    return InkWell(
      onTap: () {
        context.push(
          '/wedding/${event.weddingId}/event/${event.id}',
          extra: event,
        );
      },
      borderRadius: BorderRadius.circular(24), // Cleaner, slightly smaller radius
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kBorderColor.withOpacity(0.8)),
          boxShadow: [
            BoxShadow(
              color: _kColorTextPrimary.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8), // More compact shadow
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ROW 1: Type Pill and Action Arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TypePill(
                  label: typeLabel,
                  icon: typeIcon,
                  color: _kColorAccentRose,
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: _kColorTextSecondary,
                ),
              ],
            ),
            
            const SizedBox(height: 12),

            // ROW 2: TIME, EVENT NAME, VENUE (Horizontal flow for density)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // TIME BLOCK (Compact & Integrated)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeOnly,
                      style: t.headlineSmall?.copyWith( // Prominent Time
                        fontWeight: FontWeight.w900,
                        color: _kColorTextPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      meridiem,
                      style: t.bodySmall?.copyWith( // PM/AM
                        fontWeight: FontWeight.w700,
                        color: _kColorTextSecondary.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // VERTICAL DIVIDER (Visual separation)
                Container(
                  width: 1,
                  height: 40, // Height matching the time block
                  color: _kBorderColor,
                ),
                const SizedBox(width: 16),

                // EVENT NAME & VENUE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: _kColorTextPrimary,
                        ),
                      ),
                      if (hasVenue)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: _kColorTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.venue,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.bodyMedium?.copyWith(
                                  color: _kColorTextSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // ROW 3: Theme Chip (Moved to bottom right for visibility)
            if (hasTheme)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _ThemeChip(
                    label: event.theme,
                    color: _kColorTextSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =================== REFINED SUB-COMPONENTS ===================

class _TypePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _TypePill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label, // Label already capitalized by helper
            style: t.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final Color color;
  const _ThemeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _kBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.palette_rounded, size: 14, color: _kColorTextSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: t.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: _kColorTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}