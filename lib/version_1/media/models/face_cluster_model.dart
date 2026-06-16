import 'package:cloud_firestore/cloud_firestore.dart';

class FaceClusterModel {
  final String clusterId;
  final int faceCount;
  final String? previewThumbR2Key;

  FaceClusterModel({
    required this.clusterId,
    required this.faceCount,
    required this.previewThumbR2Key,
  });

  factory FaceClusterModel.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return FaceClusterModel(
      clusterId: doc.id,
      faceCount: (data['faceCount'] ?? 0) as int,
      previewThumbR2Key: data['previewThumbR2Key'] as String?,
    );
  }
}