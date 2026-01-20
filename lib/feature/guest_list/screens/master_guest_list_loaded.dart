// lib/feature/guest_list/screens/master_guest_list_loaded.dart (ULTIMATE PREMIUM UI)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wedding_invite/feature/guest_list/controllers/guest_provider.dart';
import 'package:wedding_invite/feature/guest_list/models/wedding_guest.dart';
import 'package:wedding_invite/feature/guest_list/screens/contact_picker_sheet.dart';
import 'package:wedding_invite/utils/phone_utils.dart';


// --- ULTIMATE PREMIUM COLOR PALETTE ---
const _kColorRoseGold = Color(0xFFC990A3); // Brighter, Richer Accent
const _kColorCreamBg = Color(0xFFFBF8F6); // Soft, light background
const _kColorTextDeep = Color(0xFF332018); // Deep Espresso Brown
const _kColorTextMuted = Color(0xFF7A6A63); // Muted Secondary Brown
const _kBorderColor = Color(0xFFEEE5E0);
const _kColorSuccess = Color(0xFF68A342); 


class MasterGuestListLoaded extends ConsumerWidget {
  final String weddingId;
  final String weddingName;

  const MasterGuestListLoaded({
    required this.weddingId,
    required this.weddingName,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final guestsAsync = ref.watch(weddingGuestsStreamProvider(weddingId));

    final totalGuests = guestsAsync.asData?.value.length ?? 0;

    return Scaffold(
      backgroundColor: _kColorCreamBg,
      body: SafeArea(
        bottom: false,
        child: guestsAsync.when(
          data: (guests) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // 1. HEADER (Master List Title & Overview Card)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: _MasterListHeader(
                      weddingName: weddingName,
                      totalGuests: totalGuests,
                    ),
                  ),
                ),

                // 2. LIST CONTENT
                if (guests.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: EmptyGuestList()),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100), 
                    sliver: SliverList.separated(
                      itemCount: guests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final g = guests[index];
                        return _MasterGuestTile(guest: g); 
                      },
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: _kColorRoseGold),
          ),
          error: (e, _) => Center(
            child: Text(
              'Unable to load guests: $e',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.red.shade600,
              ),
            ),
          ),
        ),
      ),
      
      // 3. PERSISTENT BOTTOM BAR
      bottomNavigationBar: _BottomContactBar(
        guestsAsync: guestsAsync,
        weddingId: weddingId,
        ref: ref,
      ),
    );
  }
}

// ---------- 1. MASTER LIST HEADER (Refined Component) ----------

class _MasterListHeader extends StatelessWidget {
  final String weddingName;
  final int totalGuests;

  const _MasterListHeader({
    required this.weddingName,
    required this.totalGuests,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title block
        Text(
          'Guest List',
          style: t.headlineLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: _kColorTextDeep,
            letterSpacing: -0.8,
          ),
        ),
        Text(
          'For $weddingName',
          style: t.titleMedium?.copyWith(
            color: _kColorTextMuted.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 32),

        // Overview Card (High Contrast, Elevated Look)
        Container(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: _kColorRoseGold,
            boxShadow: [
              BoxShadow(
                color: _kColorRoseGold.withOpacity(0.5),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Guests',
                    style: t.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$totalGuests',
                    style: t.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.supervised_user_circle_rounded,
                size: 60,
                color: Colors.white70,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Master List Subtitle
        Text(
          'Master Guest List',
          style: t.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: _kColorTextDeep,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'This list is synced with your phone contacts and includes everyone invited to the wedding.',
          style: t.bodyLarge?.copyWith(
            color: _kColorTextMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ---------- 2. PERSISTENT BOTTOM BAR (Updated Colors) ----------

class _BottomContactBar extends StatelessWidget {
  final AsyncValue<List<WeddingGuest>> guestsAsync;
  final String weddingId;
  final WidgetRef ref;

  const _BottomContactBar({
    required this.guestsAsync,
    required this.weddingId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: _kColorCreamBg,
        boxShadow: [
           BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final guests = guestsAsync.asData?.value ?? [];
            final selectedInputs = await showModalBottomSheet<List<GuestInput>>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return ContactPickerSheet(existingGuests: guests);
              },
            );

            if (selectedInputs != null && selectedInputs.isNotEmpty) {
              await ref
                  .read(weddingGuestsControllerProvider)
                  .upsertGuests(weddingId: weddingId, guests: selectedInputs);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Updated guest list with ${selectedInputs.length} contact(s)',
                    ),
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 24),
          label: Text(
            'Add New Guests from Contacts',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kColorRoseGold,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0, 
          ),
        ),
      ),
    );
  }
}


// ---------- 3. MASTER GUEST TILE (Ultimate Look) ----------

class _MasterGuestTile extends StatelessWidget {
  final WeddingGuest guest;

  const _MasterGuestTile({required this.guest});

  String _initialsFromName(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts[0].characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;

    final initials = _initialsFromName(guest.name);
    final phone = normalizePhone(guest.phone);
    final hasEmail = guest.email != null && guest.email!.trim().isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorderColor),
        boxShadow: [
          BoxShadow(
            color: _kColorRoseGold.withOpacity(0.08), // Soft shadow from accent
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // AVATAR
          Container(
            width: 48, // Slightly larger avatar
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kColorRoseGold.withOpacity(0.15),
            ),
            child: Center(
              child: Text(
                initials,
                style: t.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _kColorRoseGold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // GUEST DETAILS
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
                    color: _kColorTextDeep,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      size: 14,
                      color: _kColorTextMuted.withOpacity(0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: t.bodySmall?.copyWith(
                        color: _kColorTextMuted.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
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
                          color: _kColorTextMuted.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            guest.email!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall?.copyWith(
                              color: _kColorTextMuted.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // 'ADDED' STATUS PILL
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: _kColorSuccess.withOpacity(0.1),
              border: Border.all(color: _kColorSuccess.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                  color: _kColorSuccess,
                ),
                const SizedBox(width: 6),
                Text(
                  'Added',
                  style: t.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _kColorSuccess,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- 4. EMPTY GUEST LIST (Refined Colors) ----------

class EmptyGuestList extends StatelessWidget {
  const EmptyGuestList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.contact_mail_rounded,
              size: 56,
              color: _kColorRoseGold.withOpacity(0.8),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Guest List is Empty',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: _kColorTextDeep,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the "Add New Guests from Contacts" button below to pull guests from your phone and start planning!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: _kColorTextMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}