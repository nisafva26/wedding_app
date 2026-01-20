// lib/feature/wedding_admin/presentation/widgets/wedding_guest_timeline.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:wedding_invite/feature/wedding_admin/domain/event_model.dart';
import 'package:wedding_invite/feature/wedding_admin/domain/wedding_model.dart';
import 'package:wedding_invite/feature/wedding_admin/presentation/widgets/guest_event_card.dart';
import 'package:wedding_invite/feature/wedding_admin/provider/guest_event_provider.dart';
import 'package:wedding_invite/feature/wedding_admin/provider/wedding_provider.dart';

// For now we just reuse all events;
// later you can swap this to invitedEventsForGuestProvider.
class GuestTimelineSliver extends ConsumerWidget {
  final Wedding wedding;

  const GuestTimelineSliver({super.key, required this.wedding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitedAsync =
        ref.watch(guestInvitedEventsStreamProvider(wedding.id));
    final theme = Theme.of(context);

    return invitedAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: LinearProgressIndicator(),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Text(
            'Unable to load your events: $e',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.redAccent,
            ),
          ),
        ),
      ),
      data: (invites) {
        if (invites.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: Text(
                'You’re not invited to any specific events yet for this wedding.',
              ),
            ),
          );
        }

        return SliverList.builder(
          itemCount: invites.length,
          itemBuilder: (context, index) {
            final invite = invites[index];
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: GuestEventCard(invite: invite),
            );
          },
        );
      },
    );
  }
}


