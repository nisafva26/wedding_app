import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wedding_invite/version_1/media/controllers/people_gallery_provider.dart';
import 'package:wedding_invite/version_1/media/controllers/r2_signed_cache_url_provider.dart';
import 'package:wedding_invite/version_1/media/models/face_cluster_model.dart';
import 'package:wedding_invite/version_1/media/screens/cluster_details_screen.dart';



class PeopleClustersScreen extends ConsumerWidget {
  const PeopleClustersScreen({
    super.key,
    required this.weddingId,
  });

  final String weddingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clustersAsync = ref.watch(faceClustersStreamProvider(weddingId));
    final urlCache = ref.watch(r2SignedUrlCacheProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('People'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: clustersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
          data: (clusters) {
            // Ensure signed URLs for previews
            final previewKeys = clusters
                .map((c) => c.previewThumbR2Key)
                .whereType<String>()
                .toList();
        
            // Trigger in microtask so we don’t call during build sync
            Future.microtask(() {
              ref.read(r2SignedUrlCacheProvider.notifier).ensureKeys(
                    weddingId: weddingId,
                    r2Keys: previewKeys,
                  );
            });
        
            if (clusters.isEmpty) {
              return const Center(child: Text('No people clusters yet.'));
            }
        
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: clusters.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final FaceClusterModel c = clusters[index];
                final url = urlCache[c.previewThumbR2Key ?? ''];
        
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClusterDetailScreen(
                          weddingId: weddingId,
                          clusterId: c.clusterId,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (url != null && url.isNotEmpty)
                          Image.network(url, fit: BoxFit.cover)
                        else
                          Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(Icons.person, size: 30),
                            ),
                          ),
                        // Positioned(
                        //   bottom: 0,
                        //   right: 0,
                        //   child: Container(
                        //     padding: const EdgeInsets.symmetric(
                        //       horizontal: 8,
                        //       vertical: 4,
                        //     ),
                        //     decoration: BoxDecoration(
                        //       color: Colors.black.withOpacity(0.55),
                        //       borderRadius: BorderRadius.circular(999),
                        //     ),
                        //     child: Text(
                        //       '${c.faceCount}',
                        //       style: const TextStyle(
                        //         color: Colors.white,
                        //         fontSize: 12,
                        //         fontWeight: FontWeight.w600,
                        //       ),
                        //     ),
                        //   ),
                        // )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}