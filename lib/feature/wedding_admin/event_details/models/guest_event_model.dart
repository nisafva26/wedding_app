import 'package:wedding_invite/feature/wedding_admin/domain/event_model.dart';

class GuestEventInvite {
  final String weddingId;
  final String eventId;
  final String eventGuestId;
  final Event event;
  final String status; // 'pending' | 'accepted' | 'declined'

  GuestEventInvite({
    required this.weddingId,
    required this.eventId,
    required this.eventGuestId,
    required this.event,
    required this.status,
  });
}