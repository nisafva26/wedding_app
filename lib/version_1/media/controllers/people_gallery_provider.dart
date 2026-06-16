import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wedding_invite/version_1/media/models/face_cluster_model.dart';
import 'package:wedding_invite/version_1/media/models/face_index_model.dart';



final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final faceClustersStreamProvider =
    StreamProvider.family<List<FaceClusterModel>, String>((ref, weddingId) {
  final db = ref.watch(firestoreProvider);

  return db
      .collection('weddings')
      .doc(weddingId)
      .collection('faceClusters')
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(FaceClusterModel.fromDoc).toList());
});

final clusterFacesStreamProvider = StreamProvider.family<
    List<FaceIndexModel>,
    ({String weddingId, String clusterId})>((ref, args) {
  final db = ref.watch(firestoreProvider);

  return db
      .collection('weddings')
      .doc(args.weddingId)
      .collection('faceIndex')
      .where('clusterId', isEqualTo: args.clusterId)
      .snapshots()
      .map((snap) => snap.docs.map(FaceIndexModel.fromDoc).toList());
});