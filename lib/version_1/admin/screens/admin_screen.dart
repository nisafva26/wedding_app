import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wedding_invite/version_1/admin/screens/admin_notification_screen.dart';
import 'package:wedding_invite/version_1/admin/services/admin_services.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({
    super.key,
    required this.weddingId,
    required this.weddingName,
  });

  final String weddingId;
  final String weddingName;

  // Premium Palette from your design
  static const Color primaryDeep = Color(0xFF6B1139); // Deep Burgundy
  static const Color accentGold = Color(0xFFB0773B); // Muted Gold
  static const Color background = Color(0xFFFCF8F2); // Off-white cream
  static const Color cardBg = Colors.white;
  static const Color textMain = Color(0xFF2E2A27);

  @override
  Widget build(BuildContext context) {
    final weddingRef = FirebaseFirestore.instance
        .collection('weddings')
        .doc(weddingId);
    final eventsStream = weddingRef.collection('events').snapshots();
    final rsvpsStream = weddingRef.collection('rsvps').snapshots();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: textMain),
        title: Text(
          'ADMIN PANEL',
          style: TextStyle(
            color: textMain,
            letterSpacing: 1.2,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: eventsStream,
        builder: (context, eventsSnap) {
          if (!eventsSnap.hasData)
            return const Center(child: CircularProgressIndicator());

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: rsvpsStream,
            builder: (context, rsvpsSnap) {
              if (!rsvpsSnap.hasData)
                return const Center(child: CircularProgressIndicator());

              final stats = computeStats(
                events: eventsSnap.data!.docs,
                rsvps: rsvpsSnap.data!.docs,
              );

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(weddingName),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Text("QUICK OVERVIEW", style: _sectionStyle),
                    ),
                    _buildOverviewGrid(stats),

                    const Padding(
                      padding: EdgeInsets.only(left: 20, top: 30, bottom: 15),
                      child: Text("EVENT SNAPSHOT", style: _sectionStyle),
                    ),
                    _buildHorizontalEvents(stats.eventCards),

                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                      ).copyWith(top: 30, bottom: 15),
                      child: Text("MANAGEMENT", style: _sectionStyle),
                    ),
                    _ActionTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Broadcast Message',
                      subtitle: 'Send RSVP reminders or updates',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminNotificationsScreen(
                              weddingId: 'u7MmJS2IEIjOGax9E6md',
                            ),
                          ),
                        );
                      },
                    ),
                    // _ActionTile(
                    //   icon: Icons.notifications_active_outlined,
                    //   title: 'Backfill media',
                    //   subtitle: '',
                    //   onTap: () {
                    //     backfillMediaIndexAll(weddingId);
                    //   },
                    // ),

                    _ActionTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'kick backfill',
                      subtitle: '',
                      onTap: () {
                        kickBackfill(weddingId: weddingId);
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  static const _sectionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.0,
    fontFamily: 'SFPRO',
    color: Colors.black45,
  );

  Widget _buildHeader(String name) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryDeep,
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: NetworkImage(
            'https://www.transparenttextures.com/patterns/paper-fibers.png',
          ),
          opacity: 0.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wedding Management',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontFamily: 'SPRO',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,

              fontWeight: FontWeight.bold,
              fontFamily: 'Montage', // Use your custom premium font here
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid(ComputedStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Submissions',
              value: '${stats.totalRsvps}',
              icon: Icons.description_outlined,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _StatCard(
              label: 'Total Guests',
              value: '${stats.totalAttendingGuests}',
              icon: Icons.people_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalEvents(List<EventCardStats> events) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        physics: const BouncingScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final e = events[index];
          return Container(
            width: 220,
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryDeep.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e.title.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: primaryDeep,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.guestCount}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontFamily: 'SFPRO',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Confirmed Guests',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                        fontFamily: 'SFPRO',
                      ),
                    ),
                  ],
                ),
                // Text(
                //   '${e.goingRsvps} Groups',
                //   style: const TextStyle(
                //     fontSize: 12,
                //     fontFamily: 'SFPRO',
                //     fontWeight: FontWeight.w600,
                //     color: accentGold,
                //   ),
                // ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminHomeScreen.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AdminHomeScreen.accentGold),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'SFPRO',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontFamily: 'SFPRO',
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        tileColor: AdminHomeScreen.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        leading: CircleAvatar(
          backgroundColor: AdminHomeScreen.primaryDeep.withOpacity(0.1),
          child: Icon(icon, color: AdminHomeScreen.primaryDeep),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            fontFamily: 'SFPRO',
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, fontFamily: 'SFPRO'),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.black26,
        ),
      ),
    );
  }
}

// ---------------- Stats Logic (your exact web logic) ----------------

class ComputedStats {
  final int totalRsvps;
  final int totalAttendingRsvps;
  final int totalAttendingGuests;
  final List<EventCardStats> eventCards;
  final Map<String, String> eventNameById;

  ComputedStats({
    required this.totalRsvps,
    required this.totalAttendingRsvps,
    required this.totalAttendingGuests,
    required this.eventCards,
    required this.eventNameById,
  });
}

class EventCardStats {
  final String eventId;
  final String title;
  final int goingRsvps;
  final int guestCount;

  EventCardStats({
    required this.eventId,
    required this.title,
    required this.goingRsvps,
    required this.guestCount,
  });
}

ComputedStats computeStats({
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> events,
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> rsvps,
}) {
  final eventNameById = {
    for (var e in events) e.id: (e.data()['name'] ?? e.id).toString(),
  };

  int totalAttendingGuests = 0;
  int totalAttendingRsvps = 0;

  final perEventGoingRsvps = <String, int>{};
  final perEventGuestCount = <String, int>{};

  for (final r in rsvps) {
    final d = r.data();
    final headCount = (d['headCount'] is int) ? d['headCount'] as int : 1;

    final responses =
        (d['eventResponses'] as Map?)?.cast<String, dynamic>() ?? {};
    final goingEventIds = responses.entries
        .where((e) => e.value == 'going')
        .map((e) => e.key)
        .toList();

    if (goingEventIds.isNotEmpty) {
      totalAttendingRsvps += 1;
      totalAttendingGuests += headCount;
    }

    for (final id in goingEventIds) {
      perEventGoingRsvps[id] = (perEventGoingRsvps[id] ?? 0) + 1;
      perEventGuestCount[id] = (perEventGuestCount[id] ?? 0) + headCount;
    }
  }

  final eventCards = events.map((e) {
    final title = eventNameById[e.id] ?? e.id;
    return EventCardStats(
      eventId: e.id,
      title: title,
      goingRsvps: perEventGoingRsvps[e.id] ?? 0,
      guestCount: perEventGuestCount[e.id] ?? 0,
    );
  }).toList();

  return ComputedStats(
    totalRsvps: rsvps.length,
    totalAttendingRsvps: totalAttendingRsvps,
    totalAttendingGuests: totalAttendingGuests,
    eventCards: eventCards,
    eventNameById: eventNameById,
  );
}
