import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WeddingDashboardScreen extends StatelessWidget {
  const WeddingDashboardScreen({super.key});

  static const bg = Color(0xFFFFFBF7);
  static const wine = Color(0xFF5A0715);
  static const textDark = Color(0xFF241217);
  static const textSoft = Color(0xFF8A7770);
  static const border = Color(0xFFEFE2DA);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to continue")),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('weddings')
              .where('admins', arrayContains: uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: wine),
              );
            }

            if (snapshot.hasError) {
              log('snapshot : $snapshot');
              return Center(
                child: Text(
                  "Something went wrong",
                  style: TextStyle(color: textDark),
                ),
              );
            }

            final weddings =
                snapshot.data?.docs
                    .map((doc) => WeddingDashboardModel.fromDoc(doc))
                    .toList() ??
                [];

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    onCreateTap: () {
                      // TODO: Navigate to create wedding screen
                      context.push('/create-wedding');
                    },
                  ),
                ),

                if (weddings.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      onCreateTap: () {
                        // TODO: Navigate to create wedding screen

                        context.push('/create-wedding');
                      },
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 10),
                      child: Text(
                        "Your weddings",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                    sliver: SliverList.separated(
                      itemCount: weddings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final wedding = weddings[index];

                        return _WeddingCard(
                          wedding: wedding,
                          onTap: () {
                            context.push('/wedding/${wedding.id}');
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: wine,
        foregroundColor: Colors.white,
        elevation: 8,
        onPressed: () {
          // TODO: Navigate to create wedding screen
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "Create",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onCreateTap;

  const _Header({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Wedding Studio",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.1,
                    color: WeddingDashboardScreen.textDark,
                  ),
                ),
              ),
              _TopIcon(icon: Icons.notifications_none_rounded, onTap: () {}),
              const SizedBox(width: 10),
              _TopIcon(icon: Icons.person_outline_rounded, onTap: () {}),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Manage your wedding pages, events and guest experience.",
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: WeddingDashboardScreen.textSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onCreateTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: WeddingDashboardScreen.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.035),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      color: WeddingDashboardScreen.wine.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: WeddingDashboardScreen.wine,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create new wedding",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: WeddingDashboardScreen.textDark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Add couple name, venue and events.",
                          style: TextStyle(
                            fontSize: 13.5,
                            color: WeddingDashboardScreen.textSoft,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: WeddingDashboardScreen.textSoft,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: WeddingDashboardScreen.border),
          ),
          child: Icon(icon, color: WeddingDashboardScreen.wine),
        ),
      ),
    );
  }
}

class _WeddingCard extends StatelessWidget {
  final WeddingDashboardModel wedding;
  final VoidCallback onTap;

  const _WeddingCard({required this.wedding, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateText = _formatDateRange(wedding.dateStart, wedding.dateEnd);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: WeddingDashboardScreen.border),
          ),
          child: Row(
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: WeddingDashboardScreen.wine.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: WeddingDashboardScreen.wine,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wedding.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: WeddingDashboardScreen.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: WeddingDashboardScreen.textSoft,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dateText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: WeddingDashboardScreen.textSoft,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: WeddingDashboardScreen.textSoft,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            wedding.venue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: WeddingDashboardScreen.textSoft,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: WeddingDashboardScreen.wine,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return "Date not added";

    if (start != null && end == null) {
      return _formatDate(start);
    }

    if (start == null && end != null) {
      return _formatDate(end);
    }

    final sameDay =
        start!.year == end!.year &&
        start.month == end.month &&
        start.day == end.day;

    if (sameDay) return _formatDate(start);

    return "${_formatDate(start)} - ${_formatDate(end!)}";
  }

  String _formatDate(DateTime date) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;

  const _EmptyState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              color: WeddingDashboardScreen.wine.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 42,
              color: WeddingDashboardScreen.wine,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            "No weddings yet",
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: WeddingDashboardScreen.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Create your first wedding page and start adding events, venues and invitation details.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.45,
              color: WeddingDashboardScreen.textSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onCreateTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: WeddingDashboardScreen.wine,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              "Create Wedding",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class WeddingDashboardModel {
  final String id;
  final String name;
  final String venue;
  final DateTime? dateStart;
  final DateTime? dateEnd;
  final List<String> admins;

  WeddingDashboardModel({
    required this.id,
    required this.name,
    required this.venue,
    required this.dateStart,
    required this.dateEnd,
    required this.admins,
  });

  factory WeddingDashboardModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return WeddingDashboardModel(
      id: doc.id,
      name: data['name'] ?? 'Untitled Wedding',
      venue: data['venue'] ?? 'Venue not added',
      dateStart: _toDate(data['dateStart']),
      dateEnd: _toDate(data['dateEnd']),
      admins: List<String>.from(data['admins'] ?? []),
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
