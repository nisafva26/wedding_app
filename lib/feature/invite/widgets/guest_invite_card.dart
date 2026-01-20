import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wedding_invite/feature/guest_list/models/wedding_guest.dart';
import 'package:wedding_invite/feature/wedding_admin/domain/event_model.dart';
import 'package:wedding_invite/feature/wedding_admin/event_details/providers/event_guest_provider.dart';

class GuestInviteCard extends ConsumerWidget {
  final String weddingId;
  final WeddingGuest guest;
  final List<Event> events;

  const GuestInviteCard({
    super.key,
    required this.weddingId,
    required this.guest,
    required this.events,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Build: which events is this guest invited to? (and status)
    final invitedEvents = <Event>[];
    final Map<String, String> statusByEvent = {};

    for (final event in events) {
      final asyncGuests = ref.watch(
        eventGuestsStreamProvider((weddingId: weddingId, eventId: event.id)),
      );

      final eventGuests = asyncGuests.asData?.value;
      if (eventGuests == null) continue;

      EventGuest? match;
      for (final eg in eventGuests) {
        if (eg.id == guest.id) {
          match = eg;
          break;
        }
      }

      if (match != null) {
        invitedEvents.add(event);
        statusByEvent[event.id] = match.status; // "pending"/"going"/"not_going"
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3D3C5), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDBB8A5).withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row: avatar + name + phone + count pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Initial avatar
                Container(
                  height: 40,
                  width: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFE2C6),
                    border: Border.all(
                      color: const Color(0xFFC06A78),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    guest.name.isNotEmpty ? guest.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Color(0xFF5C3C3C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guest.name.isEmpty ? 'Unnamed guest' : guest.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5C3C3C),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        guest.phone,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8A6A60),
                        ),
                      ),
                    ],
                  ),
                ),
                if (invitedEvents.isNotEmpty)
                  _EventsCountPill(count: invitedEvents.length),
              ],
            ),

            if (invitedEvents.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFEFE0D5)),
              const SizedBox(height: 8),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: invitedEvents.map((event) {
                    final status = statusByEvent[event.id] ?? 'pending';
                    final meta = _statusMeta(status);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _EventChip(
                        eventName: event.name,
                        statusLabel: meta.label,
                        statusColor: meta.color,
                        bgColor: meta.bgColor,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EventsCountPill extends StatelessWidget {
  final int count;

  const _EventsCountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E1D5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count event${count == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF5C3C3C),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventChip extends StatelessWidget {
  final String eventName;
  final String statusLabel;
  final Color statusColor;
  final Color bgColor;

  const _EventChip({
    required this.eventName,
    required this.statusLabel,
    required this.statusColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE3D3C5)),
      ),
      child: Row(
        children: [
          Text(
            eventName,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5C3C3C),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// maps "pending" / "going" / "not_going" to pretty colors
({String label, Color color, Color bgColor}) _statusMeta(String status) {
  switch (status) {
    case 'going':
    case 'confirmed':
      return (
        label: 'Going',
        color: const Color(0xFF2E7D32),
        bgColor: const Color(0xFFDFF5E0),
      );
    case 'not_going':
    case 'declined':
      return (
        label: 'Not going',
        color: const Color(0xFFD32F2F),
        bgColor: const Color(0xFFFCE1E1),
      );
    default:
      return (
        label: 'Pending',
        color: const Color(0xFFB26A00),
        bgColor: const Color(0xFFFCE8D8),
      );
  }
}
