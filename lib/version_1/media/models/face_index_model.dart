import 'package:cloud_firestore/cloud_firestore.dart';

class FaceIndexModel {
  final String faceId;
  final String clusterId;
  final String? thumbR2Key;
  final String? r2Key;
  final String? eventId;
  final String? mediaId;

  FaceIndexModel({
    required this.faceId,
    required this.clusterId,
    required this.thumbR2Key,
    required this.r2Key,
    required this.eventId,
    required this.mediaId,
  });

  factory FaceIndexModel.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return FaceIndexModel(
      faceId: doc.id,
      clusterId: (data['clusterId'] ?? '') as String,
      thumbR2Key: data['thumbR2Key'] as String?,
      r2Key: data['r2Key'] as String?,
      eventId: data['eventId'] as String?,
      mediaId: data['mediaId'] as String?,
    );
  }
}