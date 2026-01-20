import 'dart:developer';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wedding_invite/feature/guest_list/controllers/guest_provider.dart';
import 'package:wedding_invite/feature/guest_list/models/wedding_guest.dart';
import 'package:wedding_invite/feature/invite/widgets/guest_invite_card.dart';

import 'package:wedding_invite/feature/wedding_admin/domain/wedding_model.dart';
import 'package:wedding_invite/feature/wedding_admin/domain/event_model.dart';
import 'package:wedding_invite/feature/wedding_admin/provider/wedding_provider.dart';
// where your providers live
// currentWeddingStreamProvider
// eventsStreamProvider
// eventGuestsStreamProvider
// weddingGuestsStreamProvider

class InviteOverviewScreen extends ConsumerWidget {
  const InviteOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weddingAsync = ref.watch(currentWeddingStreamProvider);

    return weddingAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) =>
          Scaffold(body: Center(child: Text('Error loading wedding\n$e'))),
      data: (wedding) {
        if (wedding == null) {
          return const Scaffold(
            body: Center(child: Text('No wedding found for this admin')),
          );
        }

        final weddingId = wedding.id;
        final eventsAsync = ref.watch(eventsStreamProvider(weddingId));
        final guestsAsync = ref.watch(weddingGuestsStreamProvider(weddingId));

        return eventsAsync.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, st) =>
              Scaffold(body: Center(child: Text('Error loading events\n$e'))),
          data: (events) {
            return guestsAsync.when(
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Scaffold(
                body: Center(child: Text('Error loading guests\n$e')),
              ),
              data: (guests) {
                return _InviteOverviewScaffold(
                  wedding: wedding,
                  events: events,
                  guests: guests,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _InviteOverviewScaffold extends StatefulWidget {
  final Wedding wedding;
  final List<Event> events;
  final List<WeddingGuest> guests;

  const _InviteOverviewScaffold({
    required this.wedding,
    required this.events,
    required this.guests,
  });

  @override
  State<_InviteOverviewScaffold> createState() =>
      _InviteOverviewScaffoldState();
}

class _InviteOverviewScaffoldState extends State<_InviteOverviewScaffold> {
  bool _sending = false;

  Future<void> _sendInvites() async {
    log('weeding id : ${widget.wedding.id}');
    if (_sending) return;
    setState(() => _sending = true);

    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('sendWeddingInvites');


      final result = await callable.call({'weddingId': widget.wedding.id});

      final data = Map<String, dynamic>.from(result.data as Map);
      final sent = data['sent'] ?? 0;
      final total = data['totalCandidates'] ?? 0;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Sent $sent invites (out of $total guests ready)'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      log('error : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Failed to send invites: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final guests = widget.guests;
    final events = widget.events;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.wedding.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF5C3C3C),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Guest invitations & RSVPs',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF8A6A60),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SUMMARY CARD
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF1E5), Color(0xFFFFE2D1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEDC6B3).withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFE3D3C5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Guest Invites',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF5C3C3C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${guests.length} guests • ${events.length} events',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF8A6A60),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _sending ? null : _sendInvites,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFC06A78),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          icon: _sending
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            _sending ? 'Sending...' : 'Send invites',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // GUEST LIST
            Expanded(
              child: guests.isEmpty
                  ? Center(
                      child: Text(
                        'No guests added yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8A6A60),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: guests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final guest = guests[index];
                        return GuestInviteCard(
                          weddingId: widget.wedding.id,
                          guest: guest,
                          events: events,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
