import 'package:cloud_firestore/cloud_firestore.dart';

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
  final DateTime? dateTime;
  final String venue;

  WeddingEventModel({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.venue,
  });

  factory WeddingEventModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['dateTime'];
    return WeddingEventModel(
      id: doc.id,
      title: (data['title'] ?? data['name'] ?? 'Event') as String,
      dateTime: ts is Timestamp ? ts.toDate() : null,
      venue: (data['venue'] ?? '') as String,
    );
  }
}
