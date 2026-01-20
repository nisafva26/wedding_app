// lib/feature/wedding_admin/event_details/screens/event_details_screen.dart (REDESIGN)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wedding_invite/feature/guest_list/controllers/guest_provider.dart';
import 'package:wedding_invite/feature/wedding_admin/event_details/providers/event_guest_provider.dart';
import 'package:wedding_invite/feature/wedding_admin/event_details/screens/manage_event_guest_sheet.dart';
import 'package:wedding_invite/feature/wedding_admin/event_details/widgets/event_guest_tile.dart';
import 'package:wedding_invite/feature/wedding_admin/domain/event_model.dart';

// --- PREMIUM COLOR PALETTE ---
const _kColorAccentRose = Color(0xFFB48395); // Deep Blush/Rose Gold (for accents)
const _kColorTextPrimary = Color(0xFF4A3022); // Deep Brown (for main text)
const _kColorTextSecondary = Color(0xFF8F6C53); // Muted Brown
const _kColorBackground = Color(0xFFF7F4F0); // Soft Cream/Beige
const _kHeroColor = Color(0xFFB48395); // Using rose for the hero background

class EventDetailsScreen extends ConsumerWidget {
  final String weddingId;
  final Event event;

  const EventDetailsScreen({
    super.key,
    required this.weddingId,
    required this.event,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventGuestsAsync = ref.watch(
      eventGuestsStreamProvider(
        (weddingId: weddingId, eventId: event.id),
      ),
    );
    final masterGuestsAsync =
        ref.watch(weddingGuestsStreamProvider(weddingId));

    final formattedDate =
        DateFormat('EEE, dd MMM yyyy • h:mm a').format(event.dateTime);
    
    // Determine the event type label for the hero card
    final typeLabel = _labelForType(event.type);
    
    return Scaffold(
      backgroundColor: _kColorBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. STYLISH APP BAR / HEADER
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false, // Control back button explicitly
            backgroundColor: _kColorBackground,
            foregroundColor: _kColorTextPrimary,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded),
                onPressed: () { /* TODO: Navigate to Edit Event Screen */ },
              ),
            ],
            title: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                event.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _kColorTextPrimary,
                ),
              ),
            ),
          ),

          // 2. HERO CARD SECTION (Modified to be more integrated)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: _EventHeroCard(
                event: event,
                formattedDate: formattedDate,
                typeLabel: typeLabel,
              ),
            ),
          ),
          
          // 3. GUEST LIST SECTION HEADER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _GuestListHeader(
                eventGuestsAsync: eventGuestsAsync,
                masterGuestsAsync: masterGuestsAsync,
                event: event,
                weddingId: weddingId,
                ref: ref,
              ),
            ),
          ),

          // 4. GUEST LIST CONTENT
          eventGuestsAsync.when(
            data: (eventGuests) {
              if (eventGuests.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 16, 24, 40),
                    child: EmptyEventGuests(),
                  ),
                );
              }
              
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                sliver: SliverList.separated(
                  itemCount: eventGuests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final g = eventGuests[index];
                    return EventGuestTile(guest: g);
                  },
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: _kColorAccentRose),
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'Unable to load event guests: $e',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function definition for EventType
String _labelForType(EventType type) {
  switch (type) {
    case EventType.haldi:
      return 'Haldi ceremony';
    case EventType.mehendi:
      return 'Mehendi';
    case EventType.wedding:
      return 'Wedding';
    case EventType.reception:
      return 'Reception';
    case EventType.other:
    default:
      return 'Ceremony';
  }
}


// ---------- HERO CARD (SHRUNK & STYLED TO MATCH IMAGE) ----------

class _EventHeroCard extends StatelessWidget {
  final Event event;
  final String formattedDate;
  final String typeLabel;

  const _EventHeroCard({
    required this.event,
    required this.formattedDate,
    required this.typeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      // Reduced vertical padding to be more compact
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: _kHeroColor, // Solid color for simplicity
        boxShadow: [
          BoxShadow(
            color: _kHeroColor.withOpacity(0.4),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type Pill at the top
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withOpacity(0.2), // Lighter pill background
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  typeLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Event Name
          Text(
            event.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900, // Extra bold
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          
          // Date & Time
          Text(
            formattedDate,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.95),
            ),
          ),
          const SizedBox(height: 8),
          
          // Venue
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event.venue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
              ),
            ],
          ),
          
          // Theme Chip (if present)
          if (event.theme.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withOpacity(0.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.palette_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    event.theme,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------- GUEST LIST HEADER (Extracted for Cleanliness) ----------

class _GuestListHeader extends StatelessWidget {
  final AsyncValue eventGuestsAsync;
  final AsyncValue masterGuestsAsync;
  final Event event;
  final String weddingId;
  final WidgetRef ref;

  const _GuestListHeader({
    required this.eventGuestsAsync,
    required this.masterGuestsAsync,
    required this.event,
    required this.weddingId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalGuests = eventGuestsAsync.asData?.value.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Event guests',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: _kColorTextPrimary,
              ),
            ),
            const SizedBox(width: 10),
            if (totalGuests > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: _kColorAccentRose.withOpacity(0.15),
                ),
                child: Text(
                  '$totalGuests added',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _kColorAccentRose,
                  ),
                ),
              ),
            const Spacer(),
            TextButton.icon(
              onPressed: () async {
                final masterGuests = masterGuestsAsync.asData?.value ?? [];

                if (masterGuests.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Add guests to the master list first.',
                      ),
                    ),
                  );
                  return;
                }

                final existingEventGuests = eventGuestsAsync.asData?.value ?? [];

                final selectedInputs =
                    await showModalBottomSheet<List<EventGuestInput>>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) {
                    return ManageEventGuestsSheet(
                      eventName: event.name,
                      masterGuests: masterGuests,
                      existingEventGuests: existingEventGuests,
                    );
                  },
                );

                if (selectedInputs != null && selectedInputs.isNotEmpty) {
                  await ref
                      .read(eventGuestsControllerProvider)
                      .updateEventGuests(
                        weddingId: weddingId,
                        eventId: event.id,
                        selected: selectedInputs,
                      );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Updated ${event.name} guest list',
                        ),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.manage_accounts_rounded, size: 20),
              label: const Text('Manage'),
              style: TextButton.styleFrom(
                foregroundColor: _kColorTextSecondary,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Choose who is invited to this ceremony. This doesn’t affect other events.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _kColorTextSecondary.withOpacity(0.8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}