import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wedding_invite/version_1/media/controllers/media_controller.dart';
import 'package:wedding_invite/version_1/media/models/media_models.dart';
import 'package:wedding_invite/version_1/media/screens/face_enrollment_page.dart';
import 'package:wedding_invite/version_1/media/screens/people_custers_screen.dart';
import 'package:wedding_invite/version_1/media/services/pick_media_services.dart';
import 'package:wedding_invite/version_1/media/widgets/event_gallery.dart';

class EventGalleryPage extends ConsumerStatefulWidget {
  final String weddingId;
  final String eventId;

  const EventGalleryPage({
    super.key,
    required this.weddingId,
    required this.eventId,
  });

  @override
  ConsumerState<EventGalleryPage> createState() => _EventGalleryPageState();
}

class _EventGalleryPageState extends ConsumerState<EventGalleryPage> {
  void _openPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: 42,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add to event gallery',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SFPRO',
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose photos or a video from your gallery.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontFamily: 'SFPRO',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _PickerActionTile(
                icon: Icons.photo_library_outlined,
                title: 'Select Photos',
                subtitle: 'Pick multiple photos',
                onTap: () async {
                  Navigator.pop(context);
                  final items = await MediaPickerService.pickPhotos();
                  ref.read(selectedMediaProvider.notifier).addAll(items);
                  ref
                      .read(uploadStateProvider.notifier)
                      .markAllIdle(ref.read(selectedMediaProvider));
                },
              ),
              const SizedBox(height: 10),
              _PickerActionTile(
                icon: Icons.videocam_outlined,
                title: 'Select Video',
                subtitle: 'Pick a single video (for now)',
                onTap: () async {
                  Navigator.pop(context);
                  final items = await MediaPickerService.pickVideo();
                  ref.read(selectedMediaProvider.notifier).addAll(items);
                  ref
                      .read(uploadStateProvider.notifier)
                      .markAllIdle(ref.read(selectedMediaProvider));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _autoDismissTrayWhenDone({
    required List<LocalMediaItem> selected,
    required Map<String, UploadItemState> uploadMap,
  }) {
    if (selected.isEmpty) return;

    final allDone = selected.every(
      (it) => uploadMap[it.id]?.status == UploadStatus.done,
    );

    if (!allDone) return;

    // Run after frame to avoid setState/provider changes during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // ✅ success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploaded to event ✅'),
          duration: Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // ✅ hide tray by clearing selection
      ref.read(selectedMediaProvider.notifier).clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedMediaProvider);
    final uploadMap = ref.watch(uploadStateProvider);
    final uploader = ref.read(uploadStateProvider.notifier);

    final total = selected.length;
    final done = selected
        .where((it) => uploadMap[it.id]?.status == UploadStatus.done)
        .length;

    _autoDismissTrayWhenDone(selected: selected, uploadMap: uploadMap);

    final anyUploading = uploadMap.values.any(
      (s) =>
          s.status == UploadStatus.preparing ||
          s.status == UploadStatus.uploading ||
          s.status == UploadStatus.confirming,
    );

    // FAB lift when tray is visible (prevents overlap)
    final fabBottomPadding = selected.isNotEmpty ? 140.0 : 18.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        title: const Text(
          'Event Gallery',
          style: TextStyle(
            fontFamily: 'Montage',
            fontWeight: FontWeight.w800,
            color: Color(0xff771549),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.6,
        actions: [
          TextButton(
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) =>
              //         FaceEnrollmentPage(weddingId: widget.weddingId),
              //   ),
              // );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                     PeopleClustersScreen(weddingId: widget.weddingId),
                ),
              );

          

              
            },
            child: const Text(
              'My photos',
              style: TextStyle(
                color: Color(0xff771549),
                fontWeight: FontWeight.w800,
                fontFamily: 'Montage',
              ),
            ),
          ),
          if (anyUploading)
            TextButton(
              onPressed: () => uploader.cancelAll(),
              child: const Text(
                'Cancel all',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'SFPRO',
                ),
              ),
            )
          else if (selected.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(selectedMediaProvider.notifier).clear(),
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'SFPRO',
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(10),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              color: Colors.black.withOpacity(0.06),
            ),
          ),
        ),
      ),

      // appBar: AppBar(
      //   backgroundColor: const Color(0xFFF7F3EE),
      //   elevation: 0,
      //   toolbarHeight: 66,
      //   centerTitle: true,
      //   leading: Padding(
      //     padding: const EdgeInsets.only(left: 10),
      //     child: IconButton(
      //       icon: const Icon(Icons.arrow_back_ios_new_rounded),
      //       onPressed: () => Navigator.pop(context),
      //     ),
      //   ),
      //   title: const Padding(
      //     padding: EdgeInsets.only(top: 4),
      //     child: Text(
      //       'Event Gallery',
      //       style: TextStyle(
      //         fontFamily: 'Montage',
      //         fontSize: 26,
      //         fontWeight: FontWeight.w500,
      //         letterSpacing: -0.2,
      //         color: Color(0xFF7A1E4A), // your maroon
      //       ),
      //     ),
      //   ),
      //   bottom: PreferredSize(
      //     preferredSize: const Size.fromHeight(10),
      //     child: Padding(
      //       padding: const EdgeInsets.only(bottom: 8),
      //       child: Container(
      //         height: 1,
      //         margin: const EdgeInsets.symmetric(horizontal: 18),
      //         color: Colors.black.withOpacity(0.06),
      //       ),
      //     ),
      //   ),
      // ),
      floatingActionButton: selected.isEmpty
          ? Padding(
              padding: EdgeInsets.only(bottom: fabBottomPadding),
              child: FloatingActionButton.extended(
                onPressed: anyUploading ? null : _openPickerSheet,
                backgroundColor: const Color(0xff771549),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add media',
                  style: TextStyle(fontFamily: 'SFPRO'),
                ),
              ),
            )
          : SizedBox(),

      body: Stack(
        children: [
          // ✅ Always show the remote gallery (no tabs)
          Positioned.fill(
            child: Column(
              children: [
                // Padding(
                //   padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                //   child: _PremiumHeaderCard(
                //     title: 'Shared moments',
                //     subtitle: total == 0
                //         ? 'Add photos/videos from your phone. Everyone invited can view them here.'
                //         : anyUploading
                //         ? 'Uploading… keep the app open.'
                //         : 'Ready to upload. Everyone invited can view once uploaded.',
                //     rightPill: total == 0 ? null : '$done / $total',
                //   ),
                // ),
                Expanded(
                  child: EventRemoteGallery(
                    weddingId: widget.weddingId,
                    eventId: widget.eventId,
                    onAddPressed: _openPickerSheet,
                  ),
                ),
                // const SizedBox(height: 18), // breathing room behind tray
              ],
            ),
          ),

          // ✅ Bottom Upload Queue Tray (appears only when selected not empty)
          if (selected.isNotEmpty)
            Positioned(
              left: 14,
              right: 14,
              bottom: 18,
              child: _UploadQueueTray(
                items: selected,
                uploadMap: uploadMap,
                anyUploading: anyUploading,
                onRemove: (id) =>
                    ref.read(selectedMediaProvider.notifier).remove(id),
                onCancel: (id) => uploader.cancelItem(id),
                onRetry: (id) => uploader.retryOne(
                  weddingId: widget.weddingId,
                  eventId: widget.eventId,
                  localId: id,
                ),
                onUpload: () async {
                  await uploader.uploadAll(
                    weddingId: widget.weddingId,
                    eventId: widget.eventId,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// ---------------------------
/// UI PIECES
/// ---------------------------

class _PremiumHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? rightPill;

  const _PremiumHeaderCard({
    required this.title,
    required this.subtitle,
    this.rightPill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            color: Color(0x14000000),
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F1EC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.collections_outlined, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Montage',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.black54,
                    height: 1.35,
                    fontFamily: 'SFPRO',
                  ),
                ),
              ],
            ),
          ),
          if (rightPill != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                rightPill!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'SFPRO',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Premium frosted + bold bottom tray:
/// - Shows selected items
/// - Per-item progress (uploadMap)
/// - Full-width black Upload button
class _UploadQueueTray extends StatelessWidget {
  final List<LocalMediaItem> items;
  final Map<String, UploadItemState> uploadMap;
  final bool anyUploading;

  final void Function(String id) onRemove;
  final void Function(String id) onCancel;
  final void Function(String id) onRetry;
  final VoidCallback onUpload;

  const _UploadQueueTray({
    required this.items,
    required this.uploadMap,
    required this.anyUploading,
    required this.onRemove,
    required this.onCancel,
    required this.onRetry,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.length;
    final done = items
        .where((it) => uploadMap[it.id]?.status == UploadStatus.done)
        .length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row
              Row(
                children: [
                  const Text(
                    'Selected',
                    style: TextStyle(
                      fontFamily: 'SFPRO',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      anyUploading ? '$done / $total' : '$total',
                      style: const TextStyle(
                        fontFamily: 'SFPRO',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!anyUploading)
                    TextButton(
                      onPressed: () {
                        // Clear all by removing one by one (keeps notifier clean if you don’t have clear())
                        for (final it in List<LocalMediaItem>.from(items)) {
                          onRemove(it.id);
                        }
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontFamily: 'SFPRO',
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // Horizontal queue preview
              SizedBox(
                height: 74,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final it = items[i];
                    final st = uploadMap[it.id] ?? UploadItemState.idle();
                    return _QueueThumb(
                      item: it,
                      state: st,
                      disabled: anyUploading,
                      onRemove: () => onRemove(it.id),
                      onCancel: () => onCancel(it.id),
                      onRetry: () => onRetry(it.id),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Full-width CTA
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: anyUploading ? null : onUpload,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Color(0xff771549),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black.withOpacity(0.15),
                    disabledForegroundColor: Colors.black.withOpacity(0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    anyUploading ? 'Uploading…' : 'Upload to event',
                    style: const TextStyle(
                      fontFamily: 'SFPRO',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                anyUploading
                    ? 'Please keep the app open while uploads finish.'
                    : 'Uploads will be visible to everyone invited.',
                style: TextStyle(
                  fontFamily: 'SFPRO',
                  fontSize: 12.5,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueThumb extends StatelessWidget {
  final LocalMediaItem item;
  final UploadItemState state;
  final bool disabled;
  final VoidCallback onRemove;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  const _QueueThumb({
    required this.item,
    required this.state,
    required this.disabled,
    required this.onRemove,
    required this.onCancel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == LocalMediaType.video;

    final showProgress =
        state.status == UploadStatus.preparing ||
        state.status == UploadStatus.uploading ||
        state.status == UploadStatus.confirming;

    final isDone = state.status == UploadStatus.done;
    final isFailed = state.status == UploadStatus.failed;
    final isCanceled = state.status == UploadStatus.canceled;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: isVideo
                ? Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF111111), Color(0xFF2A2A2A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Image.file(
                    File(item.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFFEAEAEA),
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),

          // Remove
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: disabled ? null : onRemove,
              child: Opacity(
                opacity: disabled ? 0.35 : 1,
                child: Container(
                  height: 22,
                  width: 22,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),

          // Done
          if (isDone)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
            ),

          // Progress overlay
          if (showProgress)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.35),
                child: Center(
                  child: SizedBox(
                    height: 36,
                    width: 36,
                    child: CircularProgressIndicator(
                      value: state.status == UploadStatus.confirming
                          ? 1
                          : state.progress.clamp(0.0, 1.0),
                      strokeWidth: 4,
                      backgroundColor: Colors.white.withOpacity(0.18),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Failed / canceled quick actions
          if (isFailed || isCanceled)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.45),
                child: Center(
                  child: GestureDetector(
                    onTap: onRetry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          fontFamily: 'SFPRO',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Cancel tap while uploading (small affordance)
          if (showProgress)
            Positioned(
              left: 6,
              top: 6,
              child: GestureDetector(
                onTap: onCancel,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'SFPRO',
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PickerActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'SFPRO',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontFamily: 'SFPRO',
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
