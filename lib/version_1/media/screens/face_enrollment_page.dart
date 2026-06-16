import 'dart:io';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wedding_invite/version_1/media/controllers/enrollment_controller.dart';

import 'package:wedding_invite/version_1/media/models/media_models.dart';
import 'package:wedding_invite/version_1/media/models/user_enrollment_model.dart';
import 'package:wedding_invite/version_1/media/services/pick_media_services.dart';
import 'package:wedding_invite/version_1/media/controllers/media_controller.dart';

class FaceEnrollmentPage extends ConsumerStatefulWidget {
  final String weddingId;

  const FaceEnrollmentPage({super.key, required this.weddingId});

  @override
  ConsumerState<FaceEnrollmentPage> createState() => _FaceEnrollmentPageState();
}

class _FaceEnrollmentPageState extends ConsumerState<FaceEnrollmentPage> {
  static const int minPhotos = 3;
  static const int maxPhotos = 5;

  void _openEnrollPickerSheet() {
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
                  'Enable “Photos of You”',
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
                  'Upload 3–5 clear selfies. We’ll automatically find your photos in the wedding gallery.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontFamily: 'SFPRO',
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _PickerActionTile(
                icon: Icons.camera_alt_outlined,
                title: 'Take Photo',
                subtitle: 'Use your camera (recommended)',
                onTap: () async {
                  Navigator.pop(context);
                  final items =
                      await MediaPickerService.capturePhoto(); // ✅ add this method
                  if (items.isEmpty) return;
                  ref.read(selectedMediaProvider.notifier).addAll(items);
                  ref
                      .read(uploadStateProvider.notifier)
                      .markAllIdle(ref.read(selectedMediaProvider));
                },
              ),
              const SizedBox(height: 10),
              _PickerActionTile(
                icon: Icons.photo_library_outlined,
                title: 'Select Photos',
                subtitle: 'Pick 3–5 selfies from gallery',
                onTap: () async {
                  Navigator.pop(context);
                  final items = await MediaPickerService.pickPhotos();
                  if (items.isEmpty) return;
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

  void _autoDismissWhenDone({
    required List<LocalMediaItem> selected,
    required Map<String, UploadItemState> uploadMap,
  }) {
    if (selected.isEmpty) return;

    final allDone = selected.every(
      (it) => uploadMap[it.id]?.status == UploadStatus.done,
    );
    if (!allDone) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enrollment uploaded ✅ Finding your photos…'),
          duration: Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
        ),
      );

      ref.read(selectedMediaProvider.notifier).clear();
      Navigator.pop(context); // close screen
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref
        .watch(selectedMediaProvider)
        .where((it) => it.type == LocalMediaType.image)
        .toList();

    final uploadMap = ref.watch(enrollmentUploadStateProvider);
    final uploader = ref.read(enrollmentUploadStateProvider.notifier);

    // hard limit 5
    if (selected.length > maxPhotos) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final extra = selected.length - maxPhotos;
        // remove extras from end
        for (int i = 0; i < extra; i++) {
          ref.read(selectedMediaProvider.notifier).remove(selected.last.id);
        }
      });
    }

    final total = selected.length;
    final done = selected
        .where((it) => uploadMap[it.id]?.status == UploadStatus.done)
        .length;

    _autoDismissWhenDone(selected: selected, uploadMap: uploadMap);

    final anyUploading = uploadMap.values.any(
      (s) =>
          s.status == UploadStatus.preparing ||
          s.status == UploadStatus.uploading ||
          s.status == UploadStatus.confirming,
    );

    final canUpload = !anyUploading && total >= minPhotos;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Photos of You',
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
          if (anyUploading)
            SizedBox()
          // TextButton(
          //   onPressed: () => uploader.cancelAll(),
          //   child: const Text(
          //     'Cancel all',
          //     style: TextStyle(
          //       color: Colors.black,
          //       fontWeight: FontWeight.w800,
          //       fontFamily: 'SFPRO',
          //     ),
          //   ),
          // )
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

      floatingActionButton: selected.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: FloatingActionButton.extended(
                onPressed: anyUploading ? null : _openEnrollPickerSheet,
                backgroundColor: const Color(0xff771549),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add selfies',
                  style: TextStyle(fontFamily: 'SFPRO'),
                ),
              ),
            )
          : const SizedBox(),

      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 140),
              children: [
                _PremiumInfoCard(
                  title: 'Enable auto-tagging',
                  subtitle:
                      'Upload 3–5 clear selfies.\nWe’ll automatically find photos where you appear — including future uploads.',
                  bullets: const [
                    'Good lighting',
                    'Front-facing, no sunglasses',
                    'One person per photo',
                  ],
                  pill: total == 0 ? null : '$done / $total',
                ),
                const SizedBox(height: 14),

                // selected grid preview
                if (selected.isEmpty)
                  _EmptyEnrollState(onTap: _openEnrollPickerSheet)
                else
                  _SelectedGrid(
                    items: selected,
                    uploadMap: uploadMap,
                    onRemove: (id) =>
                        ref.read(selectedMediaProvider.notifier).remove(id),
                  ),

                const SizedBox(height: 18),
                Text(
                  total < minPhotos
                      ? 'Add at least $minPhotos selfies to continue.'
                      : 'Looks good. Upload to start matching.',
                  style: TextStyle(
                    fontFamily: 'SFPRO',
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),

          // Bottom tray (re-using your premium tray feel)
          if (selected.isNotEmpty)
            Positioned(
              left: 14,
              right: 14,
              bottom: 18,
              child: _EnrollUploadTray(
                total: total,
                done: done,
                anyUploading: anyUploading,
                canUpload: canUpload,
                onAddMore: _openEnrollPickerSheet,
                onUpload: () async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please login again.')),
                    );
                    return;
                  }

                  // ✅ Use your existing uploader but pass enrollment context
                  await uploader.uploadAllEnrollment(
                    weddingId: widget.weddingId,

                    // 👈 special event bucket or same event, your choice
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
/// UI Pieces
/// ---------------------------

class _PremiumInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> bullets;
  final String? pill;

  const _PremiumInfoCard({
    required this.title,
    required this.subtitle,
    required this.bullets,
    this.pill,
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
            child: const Icon(Icons.face_retouching_natural, size: 20),
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
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.8,
                    color: Colors.black54,
                    height: 1.35,
                    fontFamily: 'SFPRO',
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: bullets
                      .map(
                        (b) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            b,
                            style: const TextStyle(
                              fontFamily: 'SFPRO',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          if (pill != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                pill!,
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

class _EmptyEnrollState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyEnrollState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Icon(
              Icons.add_a_photo_outlined,
              size: 34,
              color: Colors.black.withOpacity(0.65),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add your selfies',
              style: TextStyle(
                fontFamily: 'SFPRO',
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap to take a photo or select from gallery.',
              style: TextStyle(
                fontFamily: 'SFPRO',
                fontSize: 12.5,
                color: Colors.black.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _SelectedGrid extends StatelessWidget {
  final List<LocalMediaItem> items;
  final Map<String, UploadItemState> uploadMap;
  final void Function(String id) onRemove;

  const _SelectedGrid({
    required this.items,
    required this.uploadMap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, i) {
        final it = items[i];
        final st = uploadMap[it.id] ?? UploadItemState.idle();

        final showProgress =
            st.status == UploadStatus.preparing ||
            st.status == UploadStatus.uploading ||
            st.status == UploadStatus.confirming;

        final isDone = st.status == UploadStatus.done;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.file(
                  File(it.path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0xFFEAEAEA),
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => onRemove(it.id),
                  child: Container(
                    height: 22,
                    width: 22,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (isDone)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (showProgress)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.35),
                    child: Center(
                      child: SizedBox(
                        height: 36,
                        width: 36,
                        child: CircularProgressIndicator(
                          value: st.status == UploadStatus.confirming
                              ? 1
                              : st.progress.clamp(0.0, 1.0),
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
            ],
          ),
        );
      },
    );
  }
}

class _EnrollUploadTray extends StatelessWidget {
  final int total;
  final int done;
  final bool anyUploading;
  final bool canUpload;
  final VoidCallback onAddMore;
  final VoidCallback onUpload;

  const _EnrollUploadTray({
    required this.total,
    required this.done,
    required this.anyUploading,
    required this.canUpload,
    required this.onAddMore,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
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
              Row(
                children: [
                  const Text(
                    'Selfies',
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
                      anyUploading ? '$done / $total' : '$total / 5',
                      style: const TextStyle(
                        fontFamily: 'SFPRO',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: anyUploading ? null : onAddMore,
                    child: const Text(
                      'Add more',
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
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: canUpload ? onUpload : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xff771549),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black.withOpacity(0.15),
                    disabledForegroundColor: Colors.black.withOpacity(0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    anyUploading
                        ? 'Uploading…'
                        : canUpload
                        ? 'Enable Photos of You'
                        : 'Add 3–5 selfies to continue',
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
                    ? 'Keep the app open. We’re enrolling your face.'
                    : 'We only use these to find your photos in this wedding.',
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
