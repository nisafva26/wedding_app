import 'package:cloud_firestore/cloud_firestore.dart';

class WeddingGuest {
  final String id;
  final String weddingId;
  final String name;
  final String phone;
  final String? email;
  final String? sourceContactId; // device contact id
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final bool masterInviteSent;
  final DateTime? masterInviteSentAt;

  const WeddingGuest({
    required this.id,
    required this.weddingId,
    required this.name,
    required this.phone,
    this.email,
    this.sourceContactId,
    this.createdAt,
    this.updatedAt,

    this.masterInviteSent = false,
    this.masterInviteSentAt,
  });

  factory WeddingGuest.fromDoc(
    String weddingId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return WeddingGuest(
      id: doc.id,
      weddingId: weddingId,
      name: (data['name'] as String?)?.trim() ?? '',
      phone: (data['phone'] as String?)?.trim() ?? '',
      email: (data['email'] as String?)?.trim(),
      sourceContactId: data['sourceContactId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      masterInviteSent: data['masterInviteSent'] as bool? ?? false,
      masterInviteSentAt: (data['masterInviteSentAt'] as Timestamp?)?.toDate(),
    );
  }
}
