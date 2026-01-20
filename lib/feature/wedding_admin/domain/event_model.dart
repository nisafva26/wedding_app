import 'package:cloud_firestore/cloud_firestore.dart';

enum EventType {
  haldi,
  mehendi,
  wedding,
  reception,
  other,
}

extension EventTypeX on EventType {
  String get asString {
    switch (this) {
      case EventType.haldi:
        return 'haldi';
      case EventType.mehendi:
        return 'mehendi';
      case EventType.wedding:
        return 'wedding';
      case EventType.reception:
        return 'reception';
      case EventType.other:
      default:
        return 'other';
    }
  }

  static EventType fromString(String value) {
    switch (value) {
      case 'haldi':
        return EventType.haldi;
      case 'mehendi':
        return EventType.mehendi;
      case 'wedding':
        return EventType.wedding;
      case 'reception':
        return EventType.reception;
      case 'other':
      default:
        return EventType.other;
    }
  }
}

class Event {
  final String id;
  final String weddingId;
  final EventType type;
  final String name; // e.g., "Sangeet Night"
  final String theme;
  final DateTime dateTime;
  final String venue;

  Event({
    required this.id,
    required this.weddingId,
    required this.type,
    required this.name,
    required this.theme,
    required this.dateTime,
    required this.venue,
  });

  Event copyWith({
    String? id,
    String? weddingId,
    EventType? type,
    String? name,
    String? theme,
    DateTime? dateTime,
    String? venue,
  }) {
    return Event(
      id: id ?? this.id,
      weddingId: weddingId ?? this.weddingId,
      type: type ?? this.type,
      name: name ?? this.name,
      theme: theme ?? this.theme,
      dateTime: dateTime ?? this.dateTime,
      venue: venue ?? this.venue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weddingId': weddingId,
      'type': type.asString,
      'name': name,
      'theme': theme,
      'dateTime': Timestamp.fromDate(dateTime),
      'venue': venue,
    };
  }

  factory Event.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return Event(
      id: id,
      weddingId: data['weddingId'] as String? ?? '',
      type: EventTypeX.fromString(data['type'] as String? ?? 'other'),
      name: data['name'] as String? ?? '',
      theme: data['theme'] as String? ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      venue: data['venue'] as String? ?? '',
    );
  }
}
