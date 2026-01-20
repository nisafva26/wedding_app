import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Assuming these imports remain the same
import 'package:wedding_invite/feature/wedding_admin/domain/wedding_model.dart';
import 'package:wedding_invite/feature/wedding_admin/provider/wedding_provider.dart';

// --- PREMIUM COLOR PALETTE & STYLES ---
const _kColorBackground = Color(0xFFF7F4F0); // Soft Cream/Beige
const _kColorAccentRose = Color(0xFFB48395); // Deep Blush/Rose Gold
const _kColorTextPrimary = Color(0xFF4A3022); // Deep Brown
const _kColorTextSecondary = Color(0xFF8F6C53); // Muted Brown

// =================== ADMIN HOME SCREEN (MAIN) ===================

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers
    final userDocAsync = ref.watch(currentUserDocProvider);
    final hostedAsync = ref.watch(hostedWeddingsStreamProvider);
    final invitedAsync = ref.watch(invitedWeddingsStreamProvider);

    // Apply the premium theme color
    return Scaffold(
      backgroundColor: _kColorBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Simulate a refresh delay
            await Future.delayed(const Duration(milliseconds: 300));
            // Trigger actual data refresh if needed
            ref.invalidate(hostedWeddingsStreamProvider);
            ref.invalidate(invitedWeddingsStreamProvider);
          },
          color: _kColorAccentRose,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // TOP BAR (Slightly larger padding for a grander feel)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: _HomeTopBar(
                    onLogout: () => FirebaseAuth.instance.signOut(),
                    userDocAsync: userDocAsync,
                  ),
                ),
              ),

              // HERO SECTION
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: _HeroGreeting(userDocAsync: userDocAsync),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // HOSTING SECTION
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: hostedAsync.when(
                    loading: () => const _ShimmerWeddingList(),
                    error: (e, _) => _ErrorMessage(message: e.toString()),
                    data: (hosted) => _WeddingSection(
                      title: "Your Events",
                      subtitle: "Weddings you're hosting",
                      icon: Icons.auto_stories_rounded, // New, more sophisticated icon
                      role: WeddingRole.host,
                      weddings: hosted,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // INVITED SECTION
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: invitedAsync.when(
                    loading: () => const _ShimmerWeddingList(),
                    error: (e, _) => _ErrorMessage(message: e.toString()),
                    data: (invited) => _WeddingSection(
                      title: "Your Invitations",
                      subtitle: "Weddings you're invited to",
                      icon: Icons.mail_outline_rounded,
                      role: WeddingRole.guest,
                      weddings: invited,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),

              // PRIMARY CTA (Elevated to stand out)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: _CreateWeddingCallout(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
        ),
      ),
    );
  }
}

// =================== TOP BAR (Premiumized) ===================

class _HomeTopBar extends StatelessWidget {
  final VoidCallback onLogout;
  final AsyncValue userDocAsync;

  const _HomeTopBar({
    required this.onLogout,
    required this.userDocAsync,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const borderColor = Color(0xFFE4D6C7);

    String initials = '';
    String displayName = 'there';

    userDocAsync.whenData((doc) {
      final data = (doc?.data() as Map<String, dynamic>?) ?? {};
      final name = (data['name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) {
        displayName = name.split(' ').first;
        initials = name[0].toUpperCase();
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24), // Larger radius
          border: Border.all(color: borderColor.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: _kColorTextPrimary.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The Wedding Studio', // Slightly more formal title
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900, // Extra bold
                    color: _kColorTextPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Welcome, $displayName',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _kColorTextSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Avatar (Premium style)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kColorAccentRose.withOpacity(0.15),
                border: Border.all(color: _kColorAccentRose.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  initials.isNotEmpty ? initials : '✨',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _kColorAccentRose,
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Account',
              onSelected: (value) {
                if (value == 'logout') onLogout();
                if (value == 'profile') {
                  context.push('/profile');
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'profile',
                  child: Text('Profile & Settings'),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Text('Sign Out'),
                ),
              ],
              icon: Icon(
                Icons.more_horiz_rounded, // A more elegant icon choice
                color: _kColorTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================== HERO (Premiumized) ===================

class _HeroGreeting extends StatelessWidget {
  final AsyncValue userDocAsync;

  const _HeroGreeting({required this.userDocAsync});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    String firstName = 'dear';
    userDocAsync.whenData((doc) {
      final data = (doc?.data() as Map<String, dynamic>?) ?? {};
      final name = (data['name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) {
        firstName = name.split(' ').first;
      }
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28), // Increased padding
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30), // Larger, softer corners
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF7F2), // Lighter, almost white start
            Color(0xFFFDE8E0) // Soft, warm end
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _kColorAccentRose.withOpacity(0.2), // Accent-colored shadow
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $firstName',
                  style: t.headlineSmall?.copyWith( // Bolder, slightly larger
                    fontWeight: FontWeight.w900,
                    color: _kColorTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your bespoke wedding overview awaits. Let’s make magic happen.',
                  style: t.bodyLarge?.copyWith(
                    color: _kColorTextSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Icon Box (More defined)
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kColorAccentRose,
              boxShadow: [
                BoxShadow(
                  color: _kColorAccentRose.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.diamond_outlined, // A more luxurious icon
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =================== SECTIONS (Premiumized) ===================

enum WeddingRole { host, guest }

class _WeddingSection extends StatelessWidget {
  final String title;
  final String subtitle; // Added subtitle for better hierarchy
  final IconData icon;
  final WeddingRole role;
  final List<Wedding> weddings;

  const _WeddingSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.role,
    required this.weddings,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final hasWeddings = weddings.isNotEmpty;
    final count = weddings.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header (More structured)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: t.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: _kColorTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: t.bodyMedium?.copyWith(
                      color: _kColorTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (hasWeddings)
              TextButton(
                onPressed: () {
                  // TODO: wire up "view all" route
                  // context.push('/all-weddings?role=${role.name}');
                },
                child: Text(
                  'View all ($count)',
                  style: t.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _kColorAccentRose,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        // Wedding Card / Empty State
        if (!hasWeddings)
          role == WeddingRole.host
              ? const _EmptyHostingCard()
              : const _EmptyInvitedCard()
        else
          _WeddingCard(
            wedding: weddings.first, // show just the closest / first one
            role: role,
          ),
      ],
    );
  }
}

class _WeddingCard extends StatelessWidget {
  final Wedding wedding;
  final WeddingRole role;

  const _WeddingCard({
    required this.wedding,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final now = DateTime.now();
    final daysToGo = wedding.dateStart.difference(now).inDays;
    final isUpcoming = daysToGo >= 0;
    final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(wedding.dateStart); // Richer date format

    const hostColor = Color(0xFFB48395); // Rose Gold
    const guestColor = Color(0xFF8F6C53); // Rich Brown

    final pillText = role == WeddingRole.host ? 'HOSTING' : 'GUEST';
    final pillIcon =
        role == WeddingRole.host ? Icons.diamond_outlined : Icons.celebration_rounded;
    final accentColor = role == WeddingRole.host ? hostColor : guestColor;

    final subtitle = isUpcoming
        ? 'Scheduled for $formattedDate'
        : 'Held on $formattedDate';

    return InkWell(
      borderRadius: BorderRadius.circular(28), // Larger radius
      onTap: () {
        context.push('/wedding/${wedding.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5D5C7)),
          boxShadow: [
            BoxShadow(
              color: _kColorTextPrimary.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            // Icon/Image Placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.1),
                    accentColor.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.favorite_rounded,
                color: accentColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wedding.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleLarge?.copyWith( // Bolder, more prominent title
                      fontWeight: FontWeight.w900,
                      color: _kColorTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if ((wedding.venue ?? '').isNotEmpty)
                    Text(
                      wedding.venue!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium?.copyWith(
                        color: _kColorTextSecondary,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: t.bodySmall?.copyWith(
                      color: const Color(0xFFB08C70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Pill and Day Count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: accentColor.withOpacity(0.15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(pillIcon, size: 14, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        pillText,
                        style: t.labelSmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (isUpcoming)
                  Text(
                    daysToGo == 0 ? 'TODAY' : '${daysToGo} DAYS',
                    style: t.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: _kColorAccentRose,
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// =================== EMPTY STATES (Premiumized) ===================

class _EmptyHostingCard extends StatelessWidget {
  const _EmptyHostingCard();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE3D3C5)),
        boxShadow: [
          BoxShadow(
            color: _kColorTextPrimary.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.auto_stories_outlined,
              color: _kColorAccentRose, size: 32),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Events Under Your Care',
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _kColorTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap “Create Wedding” below to begin planning your next grand celebration.',
                  style: t.bodySmall?.copyWith(
                    color: _kColorTextSecondary,
                    height: 1.4,
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

class _EmptyInvitedCard extends StatelessWidget {
  const _EmptyInvitedCard();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const invitationColor = Color(0xFF8F6C53);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE3D3C5)),
        boxShadow: [
          BoxShadow(
            color: _kColorTextPrimary.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_email_unread_rounded,
              color: invitationColor, size: 30),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Awaiting Your RSVP',
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _kColorTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Invitations will appear here once your contact details are added to a guest list.',
                  style: t.bodySmall?.copyWith(
                    color: _kColorTextSecondary,
                    height: 1.4,
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

// =================== CREATE WEDDING CTA (Premiumized) ===================

class _CreateWeddingCallout extends StatelessWidget {
  const _CreateWeddingCallout();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [_kColorAccentRose, Color(0xFF9E6E7E)], // Richer gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _kColorAccentRose.withOpacity(0.5), // Stronger shadow
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Begin Your Legacy',
                  style: t.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Launch a new planning space for your own celebration or for a client.',
                  style: t.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _kColorAccentRose,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: () => context.push('/create-wedding'),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
            label: Text(
              'Create Now',
              style: t.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// =================== SMALL HELPERS (Keep the shimmer/error styles clean) ===================

class _ErrorMessage extends StatelessWidget {
  final String message;
  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        'Error loading data: $message',
        style: TextStyle(
          color: Colors.red.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ShimmerWeddingList extends StatelessWidget {
  const _ShimmerWeddingList();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90, // Match the height of the new card
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.grey.shade200.withOpacity(0.8),
      ),
      // In a real app, use a dedicated shimmer package for better effect
    );
  }
}