import 'dart:io';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:wedding_invite/version_1/media/models/media_models.dart';

class MediaPickerService {
  MediaPickerService._();

  static final ImagePicker _picker = ImagePicker();

  static String _id() =>
      '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';

  static Future<List<LocalMediaItem>> pickPhotos() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return [];

    return files.map((x) {
      final f = File(x.path);
      return LocalMediaItem(
        id: _id(),
        path: x.path,
        type: LocalMediaType.image,
        sizeBytes: f.existsSync() ? f.lengthSync() : 0,
        name: x.name,
      );
    }).toList();
  }

  static Future<List<LocalMediaItem>> pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return [];

    final f = File(file.path);
    return [
      LocalMediaItem(
        id: _id(),
        path: file.path,
        type: LocalMediaType.video,
        sizeBytes: f.existsSync() ? f.lengthSync() : 0,
        name: file.name,
      ),
    ];
  }

    /// ✅ Capture a selfie/photo using camera (for enrollment)
  /// Returns 1 image item (or empty list if cancelled)
  static Future<List<LocalMediaItem>> capturePhoto({
    CameraDevice preferredCameraDevice = CameraDevice.front,
    int imageQuality = 85,
  }) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: preferredCameraDevice,
      imageQuality: imageQuality,
    );

    if (file == null) return [];

    final f = File(file.path);
    return [
      LocalMediaItem(
        id: _id(),
        path: file.path,
        type: LocalMediaType.image,
        sizeBytes: f.existsSync() ? f.lengthSync() : 0,
        name: file.name,
      ),
    ];
  }

}
