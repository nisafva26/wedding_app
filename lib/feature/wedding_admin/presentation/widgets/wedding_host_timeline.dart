// lib/feature/wedding_admin/presentation/widgets/wedding_host_timeline.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:wedding_invite/feature/wedding_admin/domain/event_model.dart';
import 'package:wedding_invite/feature/wedding_admin/domain/wedding_model.dart';
import 'package:wedding_invite/feature/wedding_admin/presentation/widgets/event_timeline_card.dart';
import 'package:wedding_invite/feature/wedding_admin/provider/wedding_provider.dart';

const _kColorBackground = Color(0xFFF7F4F0); // Soft Cream/Beige
const _kColorAccentRose = Color(0xFFB48395); // Deep Blush/Rose Gold
const _kColorTextPrimary = Color(0xFF4A3022); // Deep Brown
const _kColorTextSecondary = Color(0xFF8F6C53);

class HostTimelineSliver extends ConsumerWidget {
  final Wedding wedding;

  const HostTimelineSliver({super.key, required this.wedding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsStreamProvider(wedding.id));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return eventsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: LinearProgressIndicator(),
        ),
      ),
      error: (err, stack) => SliverToBoxAdapter(
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Text(
            'Unable to load events: $err',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.red.shade600,
            ),
          ),
        ),
      ),
      data: (events) {
        if (events.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: _EmptyEventsCard(
                onAddEvent: () =>
                    context.push('/add-event/${wedding.id}'),
              ),
            ),
          );
        }

        final sorted = [...events]
          ..sort(
            (a, b) => a.dateTime.compareTo(b.dateTime),
          );

        return SliverList.builder(
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final event = sorted[index];
            final isFirst = index == 0;
            final previousDate = isFirst ? null : sorted[index - 1].dateTime;
            final showDateHeader = isFirst || !isSameDay(previousDate!, event.dateTime);

            // Use 24 for horizontal padding consistency
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0).copyWith(left: 8),
              child: IntrinsicHeight(
                child: Row(
                  // crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Timeline rail, marker, and TIME DISPLAY (NEW!)
                    // SizedBox(
                    //   width: 75, // Increased width to fit time
                    //   child: Column(
                    //     mainAxisAlignment: MainAxisAlignment.start,
                    //     children: [
                    //       // Leading line (if not the first item)
                    //       Expanded(
                    //         child: Container(
                    //           margin: EdgeInsets.only(left: 6),
                    //           width: 2,
                    //           color: index > 0 && !showDateHeader ? _kColorAccentRose.withOpacity(0.4) : Colors.transparent,
                    //         ),
                    //       ),
                    //       // Time Marker Row
                    //       Row(
                    //         crossAxisAlignment: CrossAxisAlignment.center,
                    //         children: [
                    //           // Timeline Dot
                    //           Container(
                    //             width: 12,
                    //             height: 12,
                    //             decoration: BoxDecoration(
                    //               shape: BoxShape.circle,
                    //               color: _kColorAccentRose,
                    //               border: Border.all(color: _kColorBackground, width: 2),
                    //             ),
                    //           ),
                    //           const SizedBox(width: 8),
                    //           // Event Time (Condensed)
                    //           Column(
                    //             crossAxisAlignment: CrossAxisAlignment.start,
                    //             children: [
                    //               Text(
                    //                 DateFormat('h:mm').format(event.dateTime),
                    //                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    //                   fontWeight: FontWeight.w800,
                    //                   color: _kColorTextPrimary,
                    //                   letterSpacing: -0.2,
                    //                 ),
                    //               ),
                    //               Text(
                    //                 DateFormat('a').format(event.dateTime),
                    //                 style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    //                   fontWeight: FontWeight.w700,
                    //                   color: _kColorTextSecondary.withOpacity(0.8),
                    //                   letterSpacing: 0.5,
                    //                 ),
                    //               ),
                    //             ],
                    //           ),
                    //         ],
                    //       ),
                    //       // Trailing line (if not the last item)
                    //       Expanded(
                    //         child: Container(
                    //           margin: EdgeInsets.only(left: 6),
                    //           width: 2,
                    //           color: index < sorted.length - 1 ? _kColorAccentRose.withOpacity(0.4) : Colors.transparent,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDateHeader)
                            Padding(
                              padding: const EdgeInsets.only(top: 16, bottom: 8),
                              child: _DayHeader(dateTime: event.dateTime),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24), // Increased space between cards
                            child: EventTimelineCard(event: event), // Updated card will be much smaller
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }
}

// --- _DayHeader Update ---
class _DayHeader extends StatelessWidget {
  final DateTime dateTime;
  const _DayHeader({required this.dateTime});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final dayLabel = DateFormat('EEEE, d').format(dateTime);
    final monthYearLabel = DateFormat('MMM yyyy').format(dateTime).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dayLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: _kColorTextPrimary,
            letterSpacing: 0.2,
          ),
        ),
        Text(
          monthYearLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: _kColorTextPrimary.withOpacity(0.6),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ... _EmptyEventsCard Update (just updating styles) ...
class _EmptyEventsCard extends StatelessWidget {
  final VoidCallback onAddEvent;
  const _EmptyEventsCard({required this.onAddEvent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const borderColor = Color(0xFFE3D3C5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28), // Larger radius
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: _kColorTextPrimary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kColorAccentRose.withOpacity(0.15),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: _kColorAccentRose,
              size: 26,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No events created yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _kColorTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Start building your official timeline by adding Haldi, Mehendi, Receptions, and more.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _kColorTextPrimary.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: onAddEvent,
            style: FilledButton.styleFrom(
              backgroundColor: _kColorAccentRose,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text('Add Event'),
          )
        ],
      ),
    );
  }
}
