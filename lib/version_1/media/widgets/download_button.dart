import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DownloadButton extends StatefulWidget {
  final String url;
  final bool isVideo;
  final String fileName;

  const DownloadButton({
    required this.url,
    required this.isVideo,
    required this.fileName,
  });

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  bool _downloading = false;
  double _progress = 0;

  Future<void> _requestPermissions() async {
    if (kIsWeb) return;

    if (Platform.isIOS) {
      var status = await Permission.photosAddOnly.status;

      if (status.isPermanentlyDenied) {
        // The user must go to settings manually now
        await openAppSettings();
        return;
      }

      if (!status.isGranted) {
        status = await Permission.photosAddOnly.request();
      }

      if (!status.isGranted) {
        throw Exception("Photos permission denied");
      }
    }
  }

  // Future<void> _requestPermissions() async {
  //   if (kIsWeb) return;

  //   // iOS needs Photos permission to save to library
  //   if (Platform.isIOS) {
  //     final status = await Permission.photosAddOnly.request();
  //     log('status : $status');
  //     if (!status.isGranted) {
  //       throw Exception("Photos permission denied");
  //     }
  //   }

  //   // Android: Gal handles modern storage; no runtime permission needed on many devices.
  //   // Still safe to request for older versions:
  //   if (Platform.isAndroid) {
  //     final status = await Permission.storage.request();
  //     // If denied, still try—some Android versions won't require this.
  //     // Don't hard fail on Android.
  //   }
  // }

  String _inferExtension() {
    final u = widget.url.toLowerCase();

    if (widget.isVideo) {
      if (u.contains(".mov")) return "mov";
      if (u.contains(".webm")) return "webm";
      return "mp4";
    } else {
      if (u.contains(".png")) return "png";
      if (u.contains(".webp")) return "webp";
      return "jpg";
    }
  }

  Future<void> _downloadAndSave() async {
    if (_downloading) return;

    setState(() {
      _downloading = true;
      _progress = 0;
    });

    try {
      await _requestPermissions();

      final ext = _inferExtension();
      final tempDir = await getTemporaryDirectory();
      final path = "${tempDir.path}/${widget.fileName}.$ext";

      await Dio().download(
        widget.url,
        path,
        onReceiveProgress: (received, total) {
          if (!mounted) return;
          if (total <= 0) return;
          setState(() => _progress = received / total);
        },
        options: Options(
          // helps some servers/CDNs
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

      if (widget.isVideo) {
        await Gal.putVideo(path);
      } else {
        await Gal.putImage(path);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: const Color(0xff771549),
          // behavior: SnackBarBehavior.floating,
          content: Text("Saved to gallery"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xff771549),
          behavior: SnackBarBehavior.floating,
          content: Text("Download failed: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
          _progress = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _downloadAndSave,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 38,
            height: 38,
            // decoration: BoxDecoration(
            //   color: Colors.black.withOpacity(0.35),
            //   shape: BoxShape.circle,
            //   border: Border.all(color: Colors.white.withOpacity(0.18)),
            // ),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: _downloading
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: (_progress > 0 && _progress < 1)
                              ? _progress
                              : null,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : const Icon(Icons.download, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}
