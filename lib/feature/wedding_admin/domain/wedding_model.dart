// Wedding model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wedding_invite/feature/wedding_admin/domain/event_model.dart';

class Wedding {
  final String id;
  final String adminUid;
  final String name;
  final DateTime dateStart;
  final DateTime dateEnd;
  final String venue;
  final List<Event> events; // Embedded event list (optional, but convenient)

  Wedding({
    required this.id,
    required this.adminUid,
    required this.name,
    required this.dateStart,
    required this.dateEnd,
    required this.venue,
    this.events = const [],
  });

  factory Wedding.fromFirestore(Map<String, dynamic> data, String id) {
    return Wedding(
      id: id,
      adminUid: data['adminUid'] as String? ?? '',
      name: data['name'] as String? ?? 'Unnamed Wedding',
      dateStart: (data['dateStart'] as Timestamp).toDate(),
      dateEnd: (data['dateEnd'] as Timestamp).toDate(),
      venue: data['venue'] as String? ?? 'TBD',
      // Events are typically loaded separately from a subcollection
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'adminUid': adminUid,
      'name': name,
      'dateStart': dateStart,
      'dateEnd': dateEnd,
      'venue': venue,
      // Firestore will auto-generate the ID
    };
  }
}

// // Event model
// enum EventType { haldi, mehendi, wedding, reception, other }

// class Event {
//   final String id;
//   final EventType type;
//   final String name; // e.g., "Sangeet Night"
//   final String theme;
//   final DateTime dateTime;
//   final String venue;

//   Event({
//     required this.id,
//     required this.type,
//     required this.name,
//     required this.theme,
//     required this.dateTime,
//     required this.venue,
//   });

//   // Factory/toFirestore methods for Event (similar to Wedding)
//   // ...
// }