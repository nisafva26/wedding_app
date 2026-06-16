import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:wedding_invite/version_1/media/controllers/media_controller.dart';
import 'package:wedding_invite/version_1/media/models/media_models.dart';

final enrollmentUploadStateProvider =
    StateNotifierProvider<EnrollmentUploadController, Map<String, UploadItemState>>(
  (ref) => EnrollmentUploadController(ref),
);



final selectedEnrollmentMediaProvider =
    StateNotifierProvider<SelectedMediaController, List<LocalMediaItem>>(
  (ref) => SelectedMediaController(),
);

class EnrollmentUploadController extends StateNotifier<Map<String, UploadItemState>> {
  EnrollmentUploadController(this.ref) : super({});

  final Ref ref;
  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};
  bool _isUploadingBatch = false;

  UploadItemState _get(String localId) => state[localId] ?? UploadItemState.idle();

  void _set(String localId, UploadItemState s) => state = {...state, localId: s};

  void markAllIdle(List<LocalMediaItem> items) {
    final m = {...state};
    for (final it in items) {
      m[it.id] = UploadItemState.idle();
    }
    state = m;
  }

  Future<void> uploadAllEnrollment({required String weddingId}) async {
    if (_isUploadingBatch) return;
    _isUploadingBatch = true;

    try {
      final items = ref.read(selectedEnrollmentMediaProvider);
      if (items.isEmpty) return;

      // ✅ enrollment should be image-only
      final imageItems = items.where((e) => e.type == LocalMediaType.image).toList();

      for (final it in imageItems) {
        _set(it.id, _get(it.id).copyWith(status: UploadStatus.preparing, progress: 0, error: null));
      }

      final create = FirebaseFunctions.instance.httpsCallable('createEnrollmentUploadSessions');

      final payloadFiles = imageItems.map((it) {
        return {
          'localId': it.id,
          'mimeType': _mimeFromItem(it),
          'sizeBytes': it.sizeBytes,
          'name': it.name,
        };
      }).toList();

      final res = await create.call({
        'weddingId': weddingId,
        'files': payloadFiles,
      });

      final result = Map<String, dynamic>.from(res.data as Map);
      final sessionsRaw = List<Map<String, dynamic>>.from(
        (result['sessions'] as List).map((e) => Map<String, dynamic>.from(e)),
      );

      final sessions = sessionsRaw.map(UploadSession.fromJson).toList();
      final sessionsByLocalId = {for (final s in sessions) s.localId: s};

      const maxParallel = 3;

      Future<void> runOne(LocalMediaItem it) async {
        final session = sessionsByLocalId[it.id];
        if (session == null) {
          _set(it.id, _get(it.id).copyWith(status: UploadStatus.failed, error: "No session returned"));
          return;
        }

        final cancelToken = CancelToken();
        _cancelTokens[it.id] = cancelToken;

        try {
          _set(it.id, _get(it.id).copyWith(status: UploadStatus.uploading, progress: 0, error: null));

          final file = File(it.path);
          final length = await file.length();

          await _dio.put(
            session.uploadUrl,
            data: file.openRead(),
            options: Options(
              headers: {...session.headers, 'Content-Length': length},
              followRedirects: false,
              validateStatus: (code) => (code ?? 0) >= 200 && (code ?? 0) < 300,
            ),
            cancelToken: cancelToken,
            onSendProgress: (sent, total) {
              if (total <= 0) return;
              _set(it.id, _get(it.id).copyWith(progress: (sent / total).clamp(0.0, 1.0)));
            },
          );

          _set(it.id, _get(it.id).copyWith(status: UploadStatus.confirming, progress: 1));

          final confirm = FirebaseFunctions.instance.httpsCallable('confirmEnrollmentUpload');

          await confirm.call({
            'weddingId': weddingId,
            'mediaId': session.mediaId,
            'r2Key': session.r2Key,
            'mimeType': _mimeFromItem(it),
            'sizeBytes': it.sizeBytes,
            'originalName': it.name,
          });

          _set(it.id, _get(it.id).copyWith(status: UploadStatus.done, progress: 1, error: null));
        } on DioException catch (e) {
          if (CancelToken.isCancel(e)) {
            _set(it.id, _get(it.id).copyWith(status: UploadStatus.canceled, progress: 0));
          } else {
            _set(it.id, _get(it.id).copyWith(status: UploadStatus.failed, error: e.message ?? "Upload failed"));
          }
        } catch (e) {
          _set(it.id, _get(it.id).copyWith(status: UploadStatus.failed, error: e.toString()));
        } finally {
          _cancelTokens.remove(it.id);
        }
      }

      final pending = List<LocalMediaItem>.from(imageItems);
      final running = <Future<void>>[];

      while (pending.isNotEmpty) {
        while (running.length < maxParallel && pending.isNotEmpty) {
          final it = pending.removeAt(0);
          final f = runOne(it);
          running.add(f);
          f.whenComplete(() => running.remove(f));
        }
        if (running.isNotEmpty) await Future.any(running);
      }

      await Future.wait(running);

      // ✅ after uploads, trigger finalize (optional auto)
      final allDone = imageItems.every((it) => state[it.id]?.status == UploadStatus.done);
      if (allDone && imageItems.length >= 3) {
        final finalize = FirebaseFunctions.instance.httpsCallable('finalizeEnrollment');
        await finalize.call({'weddingId': weddingId});
      }
    } finally {
      _isUploadingBatch = false;
    }
  }

  // ✅ retry should also use enrollment functions
  Future<void> retryOneEnrollment({required String weddingId, required String localId}) async {
    final items = ref.read(selectedEnrollmentMediaProvider);
    final it = items.firstWhere((e) => e.id == localId);

    _set(it.id, UploadItemState(status: UploadStatus.preparing, progress: 0, error: null));

    final create = FirebaseFunctions.instance.httpsCallable('createEnrollmentUploadSessions');
    final res = await create.call({
      'weddingId': weddingId,
      'files': [
        {
          'localId': it.id,
          'mimeType': _mimeFromItem(it),
          'sizeBytes': it.sizeBytes,
          'name': it.name,
        },
      ],
    });

    final result = Map<String, dynamic>.from(res.data as Map);
    final sessionsRaw = List<Map<String, dynamic>>.from(
      (result['sessions'] as List).map((e) => Map<String, dynamic>.from(e)),
    );
    final session = UploadSession.fromJson(sessionsRaw.first);

    final cancelToken = CancelToken();
    _cancelTokens[it.id] = cancelToken;

    try {
      _set(it.id, UploadItemState(status: UploadStatus.uploading, progress: 0));

      final file = File(it.path);
      final length = await file.length();

      await _dio.put(
        session.uploadUrl,
        data: file.openRead(),
        options: Options(
          headers: {...session.headers, 'Content-Length': length},
          followRedirects: false,
          validateStatus: (code) => (code ?? 0) >= 200 && (code ?? 0) < 300,
        ),
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          if (total <= 0) return;
          _set(it.id, _get(it.id).copyWith(progress: (sent / total).clamp(0.0, 1.0)));
        },
      );

      _set(it.id, _get(it.id).copyWith(status: UploadStatus.confirming, progress: 1));

      final confirm = FirebaseFunctions.instance.httpsCallable('confirmEnrollmentUpload');
      await confirm.call({
        'weddingId': weddingId,
        'mediaId': session.mediaId,
        'r2Key': session.r2Key,
        'mimeType': _mimeFromItem(it),
        'sizeBytes': it.sizeBytes,
        'originalName': it.name,
      });

      _set(it.id, _get(it.id).copyWith(status: UploadStatus.done, progress: 1));

    } finally {
      _cancelTokens.remove(it.id);
    }
  }

  String _mimeFromItem(LocalMediaItem it) => 'image/jpeg';
}