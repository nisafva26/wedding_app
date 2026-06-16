import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RsvpModel {
  final String id;
  final String phone;
  final String name;
  final Map<String, String> eventResponses;

  RsvpModel({
    required this.id,
    required this.phone,
    required this.name,
    required this.eventResponses,
  });

  factory RsvpModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final raw = (data['eventResponses'] as Map?) ?? {};
    return RsvpModel(
      id: doc.id,
      phone: (data['phone'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      eventResponses: raw.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }

  List<String> get goingEventIds => eventResponses.entries
      .where((e) => e.value == 'going')
      .map((e) => e.key)
      .toList();
}

class WeddingEventModel {
  final String id;
  final String title;
  final DateTime? dateTime; // Used for Countdown Math
  final String rawDateTimeString; // Used for "Wall Time" Display
  final String venue;

  WeddingEventModel({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.rawDateTimeString,
    required this.venue,
  });

  factory WeddingEventModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final dateData = data['dateTime'] as String?; // e.g., "2026-02-11T17:00:00+05:30"

    return WeddingEventModel(
      id: doc.id,
      title: (data['title'] ?? data['name'] ?? 'Event') as String,
      // 1. Parse for Math (Keeps +05:30 for accurate countdown)
      dateTime: dateData != null ? DateTime.parse(dateData) : null,
      // 2. Keep the raw string so we can extract the "5:00 PM" exactly
      rawDateTimeString: dateData ?? "",
      venue: (data['venue'] ?? '') as String,
    );
  }

  // FIXED GETTER: Shows "5:00 PM" no matter where the user is
  String get formattedTime {
    if (rawDateTimeString.isEmpty) return "TBA";

    try {
      // We take "2026-02-11T17:00:00+05:30" and cut it to "2026-02-11T17:00:00"
      // This removes the offset so Flutter stops trying to be "helpful"
      String wallTimeStr = rawDateTimeString.split('+')[0]; 
      DateTime wallTime = DateTime.parse(wallTimeStr);
      
      return DateFormat('h:mm a').format(wallTime); // Result: 5:00 PM
    } catch (e) {
      return "TBA";
    }
  }

  // COUNTDOWN GETTER: Still accurate because it uses the full 'dateTime'
  String get countdownText {
    if (dateTime == null) return "";
    final now = DateTime.now();
    final diff = dateTime!.difference(now);

    if (diff.isNegative) return "Started";
    if (diff.inDays > 0) return "${diff.inDays}d ${diff.inHours % 24}h to go";
    return "${diff.inHours}h ${diff.inMinutes % 60}m to go";
  }
}

// class WeddingEventModel {
//   final String id;
//   final String title;
//   final DateTime? dateTime;
//   final String venue;

//   WeddingEventModel({
//     required this.id,
//     required this.title,
//     required this.dateTime,
//     required this.venue,
//   });

//   factory WeddingEventModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
//     final data = doc.data() ?? {};
//     final ts = data['dateTime'];
//     return WeddingEventModel(
//       id: doc.id,
//       title: (data['title'] ?? data['name'] ?? 'Event') as String,
//       dateTime: ts is Timestamp ? ts.toDate() : null,
//       venue: (data['venue'] ?? '') as String,
//     );
//   }
// }
