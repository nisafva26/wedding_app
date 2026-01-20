// lib/feature/wedding_admin/presentation/wedding_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:wedding_invite/feature/wedding_admin/domain/wedding_model.dart';
import 'package:wedding_invite/feature/wedding_admin/presentation/widgets/weading_header.dart'; // Assuming this widget is updated
import 'package:wedding_invite/feature/wedding_admin/presentation/widgets/wedding_host_timeline.dart';
import 'package:wedding_invite/feature/wedding_admin/presentation/widgets/wedding_guest_timeline.dart';
import 'package:wedding_invite/feature/wedding_admin/provider/wedding_provider.dart';

// --- PREMIUM COLOR PALETTE ---
const _kColorBackground = Color(0xFFF7F4F0); // Soft Cream/Beige
const _kColorAccentRose = Color(0xFFB48395); // Deep Blush/Rose Gold
const _kColorTextPrimary = Color(0xFF4A3022); // Deep Brown

class WeddingDetailsScreen extends ConsumerWidget {
  final String weddingId;

  const WeddingDetailsScreen({super.key, required this.weddingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weddingAsync = ref.watch(weddingByIdStreamProvider(weddingId));
    final roleAsync = ref.watch(userWeddingRoleProvider(weddingId));

    return Scaffold(
      backgroundColor: _kColorBackground,
      body: weddingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _kColorAccentRose)),
        error: (e, _) => Center(child: Text('Error: Unable to load wedding: $e')),
        data: (wedding) {
          if (wedding == null) {
            return const Center(child: Text('Wedding not found.'));
          }

          return roleAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: _kColorAccentRose)),
            error: (e, _) => Center(child: Text('Error: Unable to load role: $e')),
            data: (role) {
              return _WeddingDetailsBody(wedding: wedding, role: role);
            },
          );
        },
      ),
    );
  }
}

class _WeddingDetailsBody extends StatelessWidget {
  final Wedding wedding;
  final UserWeddingRole role;

  const _WeddingDetailsBody({required this.wedding, required this.role});

  @override
  Widget build(BuildContext context) {
    final isHost = role == UserWeddingRole.host;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. IMMERSIVE SLIVER APP BAR
        _WeddingSliverHeader(wedding: wedding),

        // 2. HOST TOOLS (Only for Host role)
        if (isHost) _HostToolsSection(wedding: wedding),
        if (isHost) const SliverToBoxAdapter(child: SizedBox(height: 32)),

        // 3. TIMELINE HEADER
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(
              children: [
                Text(
                  isHost ? 'Event Timeline' : 'Your Invitations',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _kColorTextPrimary,
                  ),
                ),
                const Spacer(),
                if (isHost)
                  TextButton.icon(
                    onPressed: () => context.push('/add-event/${wedding.id}'),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text('Add New Event'),
                    style: TextButton.styleFrom(
                      foregroundColor: _kColorAccentRose,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 4. TIMELINE CONTENT
        if (isHost)
          HostTimelineSliver(wedding: wedding)
        else
          GuestTimelineSliver(wedding: wedding),

        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }
}

// =================== NEW: IMMERSIVE HEADER ===================

class _WeddingSliverHeader extends StatelessWidget {
  final Wedding wedding;
  const _WeddingSliverHeader({required this.wedding});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final formattedDate = DateFormat('MMMM d, yyyy').format(wedding.dateStart);

    return SliverAppBar(
      pinned: true,
      expandedHeight: 220.0, // Large expanded height for visual impact
      backgroundColor: _kColorBackground,
      foregroundColor: _kColorTextPrimary,
      surfaceTintColor: Colors.transparent, // Ensures clean transition
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: () { /* Share functionality */ },
        ),
        IconButton(
          icon: const Icon(Icons.edit_rounded),
          onPressed: () { /* Edit Wedding Details */ },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Text(
          wedding.name,
          style: t.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: _kColorTextPrimary,
            letterSpacing: -0.2,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image Placeholder (replace with actual image loading)
            Container(
              decoration: BoxDecoration(
                color: _kColorAccentRose.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Text(
                      wedding.name,
                      style: t.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: _kColorTextPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Starting $formattedDate',
                      style: t.titleMedium?.copyWith(
                        color: _kColorTextPrimary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Gradient Overlay for text visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _kColorBackground.withOpacity(0.1),
                    _kColorBackground.withOpacity(0.6),
                    _kColorBackground,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================== NEW: HOST TOOLS SECTION ===================

class _HostToolsSection extends StatelessWidget {
  final Wedding wedding;
  const _HostToolsSection({required this.wedding});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Planning Dashboard',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _kColorTextPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            // Host tools Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.8,
              children: [
                _ToolCard(
                  title: 'Guest List',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFFD6A5B5),
                  onTap: () => context.push('/wedding/${wedding.id}/guests'),
                ),
                _ToolCard(
                  title: 'Budget Tracker',
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFFA5C9D6),
                  onTap: () => context.push('/wedding/${wedding.id}/budget'),
                ),
                _ToolCard(
                  title: 'Vendor Manager',
                  icon: Icons.work_outline_rounded,
                  color: const Color(0xFFC9D6A5),
                  onTap: () => context.push('/wedding/${wedding.id}/vendors'),
                ),
                _ToolCard(
                  title: 'Website Builder',
                  icon: Icons.language_rounded,
                  color: const Color(0xFFD6C3A5),
                  onTap: () => context.push('/wedding/${wedding.id}/website'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              icon,
              color: color.darken(0.3), // Simple darken logic for premium look
              size: 32,
            ),
            Text(
              title,
              style: t.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: _kColorTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}