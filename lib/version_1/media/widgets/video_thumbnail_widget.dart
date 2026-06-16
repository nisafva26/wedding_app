// Helper widget to handle the async thumbnail loading
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';



class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final double? height;

  const VideoThumbnailWidget({super.key, required this.videoUrl, this.height});

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  Uint8List? _thumbnailData;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    if (widget.videoUrl.isEmpty) return;
    
    try {
      final data = await VideoThumbnail.thumbnailData(
        video: widget.videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 256, 
        quality: 30, // Lower quality for faster generation
      );
      if (mounted) {
        setState(() {
          _thumbnailData = data;
        });
      }
    } catch (e) {
      debugPrint("Thumbnail error: $e");
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: const Color(0xFF2A2A2A),
        child: const Icon(Icons.videocam_off_outlined, color: Colors.white24),
      );
    }

    return Container(
      height: widget.height,
      width: double.infinity,
      color: const Color(0xFF1A1A1A), // Darker background looks more premium
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The Actual Thumbnail
          if (_thumbnailData != null)
            Image.memory(_thumbnailData!, fit: BoxFit.cover)
          else
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white30),
              ),
            ),

          // Play Button Overlay (Premium Look)
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}