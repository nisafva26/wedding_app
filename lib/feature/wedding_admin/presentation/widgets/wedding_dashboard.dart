import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:wedding_invite/feature/wedding_admin/domain/event_model.dart';
import 'package:wedding_invite/feature/wedding_admin/domain/wedding_model.dart';
import 'package:wedding_invite/feature/wedding_admin/presentation/widgets/event_timeline_card.dart';
import 'package:wedding_invite/feature/wedding_admin/provider/wedding_provider.dart';

class WeddingDashboard extends ConsumerWidget {
  final Wedding wedding;
  const WeddingDashboard({super.key, required this.wedding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsStreamProvider(wedding.id));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final now = DateTime.now();
    final daysRemaining = wedding.dateStart.difference(now).inDays + 1;
    final formattedDate = DateFormat.yMMMMd().format(wedding.dateStart);
    final isUpcoming = daysRemaining > 0;

    final Widget eventsSliver = eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: _EmptyEventsCard(
                onAddEvent: () => context.push('/add-event/${wedding.id}'),
              ),
            ),
          );
        }

        final sorted = [...events]..sort(
            (a, b) => a.dateTime.compareTo(b.dateTime),
          );

        return SliverList.builder(
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final event = sorted[index];
            final isFirst = index == 0;
            final previousDate =
                isFirst ? null : sorted[index - 1].dateTime;
            final showDateHeader = isFirst ||
                !isSameDay(previousDate!, event.dateTime);

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showDateHeader)
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 6),
                      child: _DayHeader(dateTime: event.dateTime),
                    ),
                  EventTimelineCard(event: event),
                ],
              ),
            );
          },
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: LinearProgressIndicator(),
        ),
      ),
      error: (err, stack) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Text(
            'Unable to load events: $err',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.red.shade600,
            ),
          ),
        ),
      ),
    );

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Padded hero
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _WeddingHeroHeader(
              wedding: wedding,
              isUpcoming: isUpcoming,
              daysRemaining: daysRemaining,
              formattedDate: formattedDate,
            ),
          ),
        ),

        // Quick row: title + add btn
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wedding timeline',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Plan each ceremony with clarity.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.secondary.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.push('/add-event/${wedding.id}'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add event'),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    textStyle: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Events
        eventsSliver,

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ---------------- HERO HEADER ----------------

class _WeddingHeroHeader extends StatelessWidget {
  final Wedding wedding;
  final bool isUpcoming;
  final int daysRemaining;
  final String formattedDate;

  const _WeddingHeroHeader({
    required this.wedding,
    required this.isUpcoming,
    required this.daysRemaining,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const borderColor = Color(0xFFE3D3C5);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main card
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                colors.primary.withOpacity(0.96),
                const Color(0xFFFFE3DA),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: title + actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wedding Admin',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          wedding.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if ((wedding.venue ?? '').isNotEmpty)
                          Text(
                            wedding.venue ?? '',
                            style:
                                theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.86),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: () {
                          // TODO: go to settings
                        },
                        icon: Icon(
                          Icons.tune_rounded,
                          color: Colors.white.withOpacity(0.9),
                          size: 22,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sign out',
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        icon: Icon(
                          Icons.logout_rounded,
                          color: Colors.white.withOpacity(0.9),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Metrics row
              Row(
                children: [
                  _HeroMetricPill(
                    label: isUpcoming ? 'Days to go' : 'Status',
                    value: isUpcoming ? '$daysRemaining' : 'Completed',
                    icon: isUpcoming
                        ? Icons.favorite_rounded
                        : Icons.check_circle_rounded,
                    isLight: true,
                  ),
                  const SizedBox(width: 12),
                  _HeroMetricPill(
                    label: 'Wedding date',
                    value: formattedDate,
                    icon: Icons.event_rounded,
                    isLight: true,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Glass pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: borderColor.withOpacity(0.65),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Curating the perfect celebration flow',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Decorative overlay circle
        Positioned(
          right: -30,
          top: -20,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.14),
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 6,
          child: Icon(
            Icons.favorite_border_rounded,
            size: 36,
            color: Colors.white.withOpacity(0.35),
          ),
        ),
      ],
    );
  }
}

class _HeroMetricPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLight;

  const _HeroMetricPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final textColor = isLight ? Colors.white : colors.secondary;
    final iconBg = isLight
        ? Colors.white.withOpacity(0.22)
        : colors.primary.withOpacity(0.08);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.white.withOpacity(0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isLight
              ? null
              : Border.all(color: const Color(0xFFE3D3C5)),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBg,
              ),
              child: Icon(
                icon,
                size: 16,
                color: isLight ? Colors.white : colors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- DAY HEADER ----------------

class _DayHeader extends StatelessWidget {
  final DateTime dateTime;
  const _DayHeader({required this.dateTime});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final label = DateFormat('EEEE, d MMM').format(dateTime);

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.secondary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

// ---------------- EMPTY STATE ----------------

class _EmptyEventsCard extends StatelessWidget {
  final VoidCallback onAddEvent;
  const _EmptyEventsCard({required this.onAddEvent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const borderColor = Color(0xFFE3D3C5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withOpacity(0.10),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No events yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add Haldi, Mehendi, Wedding, Reception and more to start your official timeline.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.secondary.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onAddEvent,
            child: const Text('Add'),
          )
        ],
      ),
    );
  }
}
