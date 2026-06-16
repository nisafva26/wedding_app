import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:wedding_invite/version_1/media/controllers/people_gallery_provider.dart';
import 'package:wedding_invite/version_1/media/controllers/r2_signed_cache_url_provider.dart';
import 'package:wedding_invite/version_1/media/models/face_index_model.dart';
import 'package:wedding_invite/version_1/media/widgets/download_button.dart';

class ClusterDetailScreen extends ConsumerStatefulWidget {
  const ClusterDetailScreen({
    super.key,
    required this.weddingId,
    required this.clusterId,
  });

  final String weddingId;
  final String clusterId;

  @override
  ConsumerState<ClusterDetailScreen> createState() =>
      _ClusterDetailScreenState();
}

class _ClusterDetailScreenState extends ConsumerState<ClusterDetailScreen> {
  ProviderSubscription<AsyncValue<List<FaceIndexModel>>>? _sub;

  @override
  void initState() {
    super.initState();

    _sub = ref.listenManual<AsyncValue<List<FaceIndexModel>>>(
      clusterFacesStreamProvider((
        weddingId: widget.weddingId,
        clusterId: widget.clusterId,
      )),
      (prev, next) {
        next.whenData((faces) {
          final originalKeys = faces
              .map((f) => f.r2Key) // ✅ original image key
              .whereType<String>()
              .where((k) => k.isNotEmpty)
              .toSet()
              .toList();

          if (originalKeys.isEmpty) return;

          ref
              .read(r2SignedUrlCacheProvider.notifier)
              .ensureKeys(weddingId: widget.weddingId, r2Keys: originalKeys);
        });
      },
    );
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facesAsync = ref.watch(
      clusterFacesStreamProvider((
        weddingId: widget.weddingId,
        clusterId: widget.clusterId,
      )),
    );
    final urlCache = ref.watch(r2SignedUrlCacheProvider);

    double _heightFor(int index) {
      // premium stagger (repeatable pattern)
      const heights = [220.0, 280.0, 240.0, 320.0, 260.0, 300.0];
      return heights[index % heights.length];
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Photos')),
      body: facesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (faces) {
          if (faces.isEmpty) {
            return const Center(child: Text('No photos in this cluster.'));
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              shrinkWrap: true,
              // physics: const NeverScrollableScrollPhysics(),
              itemCount: faces.length,
              itemBuilder: (context, i) {
                final face = faces[i];

                // final id = (face.id ?? '').toString(); // if you have an id field
                final key = face.r2Key; // ✅ ORIGINAL photo key
                final url = key == null ? null : urlCache[key];

                final h = _heightFor(i); // your same height function

                return GestureDetector(
                  onTap: () async {
                    // optional: open full gallery viewer
                    // or just open single viewer
                    // if (url == null) return;
                    await Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        barrierColor: Colors.black.withOpacity(0.1),
                        transitionDuration: const Duration(milliseconds: 900),
                        reverseTransitionDuration: const Duration(
                          milliseconds: 900,
                        ),
                        pageBuilder: (context, animation, _) => FadeTransition(
                          opacity: animation,
                          child: Scaffold(
                            backgroundColor: Colors.black,
                            appBar: AppBar(backgroundColor: Colors.black),
                            body: Center(
                              child: InteractiveViewer(
                                child: Image.network(url!),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Material(
                    type: MaterialType.transparency,
                    child: _InspoTile(
                      radius: 18,
                      height: h,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // ---- Media ----
                          if (url == null)
                            Container(
                              color: const Color(0xFFEAEAEA),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else
                            Image.network(
                              url,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.low,
                              loadingBuilder: (c, w, p) => p == null
                                  ? w
                                  : Container(color: const Color(0xFFEAEAEA)),
                              errorBuilder: (_, __, ___) => const ColoredBox(
                                color: Color(0xFFEAEAEA),
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),

                          // ---- Download button (top-right) ----
                          if (url != null)
                            Positioned(
                              right: 6,
                              top: 8,
                              child: DownloadButton(
                                url: url,
                                isVideo: false,
                                fileName:
                                    "${widget.weddingId}_${face.r2Key ?? i}",
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _InspoTile extends StatelessWidget {
  final double radius;
  final double height;
  final Widget child;

  const _InspoTile({
    required this.radius,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(height: height, child: child),
    );
  }
}
