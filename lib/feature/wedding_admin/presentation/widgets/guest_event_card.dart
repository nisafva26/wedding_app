// guest_event_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wedding_invite/feature/wedding_admin/event_details/models/guest_event_model.dart';
import 'package:wedding_invite/feature/wedding_admin/provider/event_rsvp_controller.dart';



class GuestEventCard extends ConsumerStatefulWidget {
  final GuestEventInvite invite;

  const GuestEventCard({super.key, required this.invite});

  @override
  ConsumerState<GuestEventCard> createState() => _GuestEventCardState();
}

class _GuestEventCardState extends ConsumerState<GuestEventCard> {
  bool _isUpdating = false;

  Future<void> _setStatus(String status) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      await ref.read(eventRsvpControllerProvider).updateRsvp(
            weddingId: widget.invite.weddingId,
            eventId: widget.invite.eventId,
            eventGuestId: widget.invite.eventGuestId,
            status: status,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update RSVP: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final event = widget.invite.event;
    final status = widget.invite.status;

    final dateLabel =
        DateFormat('EEE, d MMM • h:mm a').format(event.dateTime);

    Color statusColor;
    String statusText;

    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        statusText = 'You’re going';
        break;
      case 'declined':
        statusColor = Colors.redAccent;
        statusText = 'Not attending';
        break;
      default:
        statusColor = Colors.orangeAccent;
        statusText = 'RSVP pending';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3D3C5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: name + tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon bubble
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withOpacity(0.08),
                ),
                child: Icon(
                  Icons.event_rounded,
                  color: colors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3F2719),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: t.bodySmall?.copyWith(
                        color: const Color(0xFF8F6C53),
                      ),
                    ),
                    if ((event.venue).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.venue,
                        style: t.bodySmall?.copyWith(
                          color: const Color(0xFFB08C70),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Status pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: statusColor.withOpacity(0.08),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status == 'accepted'
                          ? Icons.check_circle_rounded
                          : status == 'declined'
                              ? Icons.cancel_rounded
                              : Icons.hourglass_bottom_rounded,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: t.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              if (_isUpdating)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Action buttons
          if (status == 'pending') ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isUpdating ? null : () => _setStatus('declined'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text('Not attending'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _isUpdating ? null : () => _setStatus('accepted'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text('I’ll be there'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isUpdating
                    ? null
                    : () {
                        // allow changing mind
                        _setStatus(
                          status == 'accepted' ? 'declined' : 'accepted',
                        );
                      },
                child: const Text('Change response'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
