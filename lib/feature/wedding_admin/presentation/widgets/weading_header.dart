// lib/feature/wedding_admin/presentation/widgets/wedding_header.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wedding_invite/feature/wedding_admin/domain/wedding_model.dart';

class WeddingHeader extends StatelessWidget {
  final Wedding wedding;

  const WeddingHeader({super.key, required this.wedding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final now = DateTime.now();
    final daysRemaining = wedding.dateStart.difference(now).inDays + 1;
    final isUpcoming = daysRemaining > 0;
    final formattedDate = DateFormat.yMMMMd().format(wedding.dateStart);

    const borderColor = Color(0xFFE3D3C5);

    return Stack(
      clipBehavior: Clip.none,
      children: [
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wedding Admin',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w600,
                            color:
                                Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          wedding.name,
                          style: theme
                              .textTheme.headlineSmall
                              ?.copyWith(
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
                            style: theme.textTheme.bodySmall
                                ?.copyWith(
                              color: Colors.white
                                  .withOpacity(0.86),
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
                          // TODO: settings
                        },
                        icon: Icon(
                          Icons.tune_rounded,
                          color:
                              Colors.white.withOpacity(0.9),
                          size: 22,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sign out',
                        onPressed: () =>
                            FirebaseAuth.instance.signOut(),
                        icon: Icon(
                          Icons.logout_rounded,
                          color:
                              Colors.white.withOpacity(0.9),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _HeroMetricPill(
                    label: isUpcoming ? 'Days to go' : 'Status',
                    value: isUpcoming
                        ? '$daysRemaining'
                        : 'Completed',
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14,
                        vertical: 8),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(999),
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
                      style: theme.textTheme.bodySmall
                          ?.copyWith(
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
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(
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
