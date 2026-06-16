import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:wedding_invite/version_1/media/models/media_models.dart';
import 'package:wedding_invite/version_1/media/models/user_enrollment_model.dart';

final selectedMediaProvider =
    StateNotifierProvider<SelectedMediaController, List<LocalMediaItem>>(
      (ref) => SelectedMediaController(),
    );

class SelectedMediaController extends StateNotifier<List<LocalMediaItem>> {
  SelectedMediaController() : super([]);

  void addAll(List<LocalMediaItem> items) {
    final existing = state.map((e) => e.path).toSet();
    final filtered = items.where((e) => !existing.contains(e.path)).toList();
    state = [...state, ...filtered];
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  void clear() => state = [];
}

/// Upload controller state: map localItemId -> UploadItemState
final uploadStateProvider =
    StateNotifierProvider<UploadController, Map<String, UploadItemState>>(
      (ref) => UploadController(ref),
    );

class UploadController extends StateNotifier<Map<String, UploadItemState>> {
  UploadController(this.ref) : super({});

  final Ref ref;

  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};
  bool _isUploadingBatch = false;

  bool get isUploadingBatch => _isUploadingBatch;

  UploadItemState _get(String localId) =>
      state[localId] ?? UploadItemState.idle();

  void _set(String localId, UploadItemState s) {
    state = {...state, localId: s};
  }

  void markAllIdle(List<LocalMediaItem> items) {
    final m = {...state};
    for (final it in items) {
      m[it.id] = UploadItemState.idle();
    }
    state = m;
  }

  void cancelItem(String localId) {
    _cancelTokens[localId]?.cancel("canceled");
    _set(
      localId,
      _get(localId).copyWith(status: UploadStatus.canceled, progress: 0),
    );
  }

  void cancelAll() {
    for (final t in _cancelTokens.values) {
      t.cancel("canceled");
    }
    _cancelTokens.clear();
    state = {
      for (final e in state.entries)
        e.key: e.value.copyWith(status: UploadStatus.canceled, progress: 0),
    };
  }

  Future<void> uploadAll({
    required String weddingId,
    required String eventId,
  
  }) async {
    if (_isUploadingBatch) return;
    _isUploadingBatch = true;

    try {
      final items = ref.read(selectedMediaProvider);
      if (items.isEmpty) return;

      // 1) mark preparing
      for (final it in items) {
        _set(
          it.id,
          _get(
            it.id,
          ).copyWith(status: UploadStatus.preparing, progress: 0, error: null),
        );
      }

      // 2) call create sessions
      final callable = FirebaseFunctions.instance.httpsCallable(
        'createEventMediaUploadSessions',
      );

      final payloadFiles = items.map((it) {
        return {
          'localId': it.id,
          'mimeType': _mimeFromItem(it),
          'sizeBytes': it.sizeBytes,
          'name': it.name,

         
        };
      }).toList();

      final res = await callable.call({
        'weddingId': weddingId,
        'eventId': eventId,
        'files': payloadFiles,
      });

      final result = Map<String, dynamic>.from(res.data as Map);
      final sessionsRaw = List<Map<String, dynamic>>.from(
        (result['sessions'] as List).map((e) => Map<String, dynamic>.from(e)),
      );

      final sessions = sessionsRaw.map(UploadSession.fromJson).toList();
      final sessionsByLocalId = {for (final s in sessions) s.localId: s};

      // 3) upload in parallel (limit concurrency to avoid phone/network choking)
      const maxParallel = 3;
      final queue = <Future<void>>[];

      Future<void> runOne(LocalMediaItem it) async {
        final session = sessionsByLocalId[it.id];
        if (session == null) {
          _set(
            it.id,
            _get(it.id).copyWith(
              status: UploadStatus.failed,
              error: "No session returned",
            ),
          );
          return;
        }

        final cancelToken = CancelToken();
        _cancelTokens[it.id] = cancelToken;

        try {
          // Uploading
          _set(
            it.id,
            _get(it.id).copyWith(
              status: UploadStatus.uploading,
              progress: 0,
              error: null,
            ),
          );

          final file = File(it.path);
          final length = await file.length();

          await _dio.put(
            session.uploadUrl,
            data: file.openRead(),
            options: Options(
              headers: {...session.headers, 'Content-Length': length},
              // Important: don't follow redirects (signed URL can be strict)
              followRedirects: false,
              validateStatus: (code) => (code ?? 0) >= 200 && (code ?? 0) < 300,
            ),
            cancelToken: cancelToken,
            onSendProgress: (sent, total) {
              if (total <= 0) return;
              final p = (sent / total).clamp(0.0, 1.0);
              _set(it.id, _get(it.id).copyWith(progress: p));
            },
          );

          // Confirming
          _set(
            it.id,
            _get(it.id).copyWith(status: UploadStatus.confirming, progress: 1),
          );

          final confirm = FirebaseFunctions.instance.httpsCallable(
            'confirmEventMediaUpload',
          );

          await confirm.call({
            'weddingId': weddingId,
            'eventId': eventId,
            'mediaId': session.mediaId,
            'r2Key': session.r2Key,
            'mimeType': _mimeFromItem(it),
            'sizeBytes': it.sizeBytes,
            'originalName': it.name,

            
          });

          _set(
            it.id,
            _get(
              it.id,
            ).copyWith(status: UploadStatus.done, progress: 1, error: null),
          );
        } on DioException catch (e) {
          if (CancelToken.isCancel(e)) {
            _set(
              it.id,
              _get(it.id).copyWith(
                status: UploadStatus.canceled,
                progress: 0,
                error: null,
              ),
            );
          } else {
            _set(
              it.id,
              _get(it.id).copyWith(
                status: UploadStatus.failed,
                error: e.message ?? "Upload failed",
              ),
            );
          }
        } catch (e) {
          _set(
            it.id,
            _get(
              it.id,
            ).copyWith(status: UploadStatus.failed, error: e.toString()),
          );
        } finally {
          _cancelTokens.remove(it.id);
        }
      }

      // Simple concurrency limiter
      final pending = List<LocalMediaItem>.from(items);
      final running = <Future<void>>[];

      while (pending.isNotEmpty) {
        while (running.length < maxParallel && pending.isNotEmpty) {
          final it = pending.removeAt(0);
          final f = runOne(it);
          running.add(f);
          f.whenComplete(() => running.remove(f));
        }
        // wait a bit until something completes
        if (running.isNotEmpty) {
          await Future.any(running);
        }
      }

      // wait remaining
      await Future.wait(running);

      // Optional: remove successfully uploaded items from selection
      // (premium UX: keep done items visible with checkmark)
    } finally {
      _isUploadingBatch = false;
    }
  }

  Future<void> retryOne({
    required String weddingId,
    required String eventId,
    required String localId,
  
  }) async {
    final items = ref.read(selectedMediaProvider);
    final it = items.firstWhere(
      (e) => e.id == localId,
      orElse: () => throw Exception("Item not found"),
    );
    // simplest retry: upload only this one by calling uploadAll with list reduced
    // We'll do a quick single-item session flow:

    _set(
      it.id,
      UploadItemState(status: UploadStatus.preparing, progress: 0, error: null),
    );

    final callable = FirebaseFunctions.instance.httpsCallable(
      'createEventMediaUploadSessions',
    );
    final res = await callable.call({
      'weddingId': weddingId,
      'eventId': eventId,
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
      _set(
        it.id,
        UploadItemState(
          status: UploadStatus.uploading,
          progress: 0,
          error: null,
        ),
      );

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
          _set(
            it.id,
            _get(it.id).copyWith(progress: (sent / total).clamp(0.0, 1.0)),
          );
        },
      );

      _set(
        it.id,
        _get(it.id).copyWith(status: UploadStatus.confirming, progress: 1),
      );

      final confirm = FirebaseFunctions.instance.httpsCallable(
        'confirmEventMediaUpload',
      );
      await confirm.call({
        'weddingId': weddingId,
        'eventId': eventId,
        'mediaId': session.mediaId,
        'r2Key': session.r2Key,
        'mimeType': _mimeFromItem(it),
        'sizeBytes': it.sizeBytes,
        'originalName': it.name,
      });

      _set(
        it.id,
        _get(
          it.id,
        ).copyWith(status: UploadStatus.done, progress: 1, error: null),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        _set(
          it.id,
          UploadItemState(status: UploadStatus.canceled, progress: 0),
        );
      } else {
        _set(
          it.id,
          UploadItemState(
            status: UploadStatus.failed,
            progress: 0,
            error: e.message,
          ),
        );
      }
    } catch (e) {
      _set(
        it.id,
        UploadItemState(
          status: UploadStatus.failed,
          progress: 0,
          error: e.toString(),
        ),
      );
    } finally {
      _cancelTokens.remove(it.id);
    }
  }

  String _mimeFromItem(LocalMediaItem it) {
    // You can improve later by detecting from extension with mime package.
    // For now use safe defaults:
    if (it.type == LocalMediaType.video) return 'video/mp4';
    return 'image/jpeg';
  }
}

Future<void> deleteEventMedia({
  required BuildContext context,
  required String weddingId,
  required String eventId,
  required String mediaId,
}) async {
  try {
    final fn = FirebaseFunctions.instance.httpsCallable('deleteEventMedia');
    await fn.call({
      'weddingId': weddingId,
      'eventId': eventId,
      'mediaId': mediaId,
    });
  } on FirebaseFunctionsException catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.message ?? 'Delete failed')));
    rethrow;
  } catch (_) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Delete failed')));
    rethrow;
  }
}
