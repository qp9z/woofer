import 'media_format.dart';

/// Result of `POST /extract`, mirroring the backend `ExtractResponse`.
class VideoInfo {
  final String? title;
  final String? thumbnail;
  final double? duration; // seconds
  final String? uploader;
  final List<MediaFormat> formats;

  const VideoInfo({
    this.title,
    this.thumbnail,
    this.duration,
    this.uploader,
    this.formats = const [],
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) => VideoInfo(
        title: json['title'] as String?,
        thumbnail: json['thumbnail'] as String?,
        duration: (json['duration'] as num?)?.toDouble(),
        uploader: json['uploader'] as String?,
        formats: (json['formats'] as List<dynamic>? ?? const [])
            .map((e) => MediaFormat.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
