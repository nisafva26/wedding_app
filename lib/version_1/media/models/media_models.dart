enum LocalMediaType { image, video }

enum UploadStatus { idle, preparing, uploading, confirming, done, failed, canceled }

class LocalMediaItem {
  final String id;
  final String path;
  final LocalMediaType type;
  final int sizeBytes;
  final String name;

  const LocalMediaItem({
    required this.id,
    required this.path,
    required this.type,
    required this.sizeBytes,
    required this.name,
  });
}

/// Upload UI state per item
class UploadItemState {
  final UploadStatus status;
  final double progress; // 0..1
  final String? error;

  const UploadItemState({
    required this.status,
    required this.progress,
    this.error,
  });

  factory UploadItemState.idle() =>
      const UploadItemState(status: UploadStatus.idle, progress: 0);

  UploadItemState copyWith({
    UploadStatus? status,
    double? progress,
    String? error,
  }) {
    return UploadItemState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error,
    );
  }
}

/// R2 session returned from callable
class UploadSession {
  final String localId;
  final String mediaId;
  final String r2Key;
  final String uploadUrl;
  final Map<String, dynamic> headers;

  UploadSession({
    required this.localId,
    required this.mediaId,
    required this.r2Key,
    required this.uploadUrl,
    required this.headers,
  });

  factory UploadSession.fromJson(Map<String, dynamic> json) {
    return UploadSession(
      localId: json['localId'],
      mediaId: json['mediaId'],
      r2Key: json['r2Key'],
      uploadUrl: json['uploadUrl'],
      headers: Map<String, dynamic>.from(json['headers'] ?? {}),
    );
  }
}
