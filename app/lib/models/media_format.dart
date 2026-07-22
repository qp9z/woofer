/// One downloadable format. Source-agnostic: [formatId] is a YouTube itag, a
/// yt-dlp format id, or any stable per-source identifier.
class MediaFormat {
  final String formatId;
  final String? ext;
  final String? resolution;
  final int? filesize;
  final bool hasAudio;
  final bool hasVideo;
  final String? note;

  const MediaFormat({
    required this.formatId,
    this.ext,
    this.resolution,
    this.filesize,
    required this.hasAudio,
    required this.hasVideo,
    this.note,
  });

  /// A video-only stream (no audio track) must be muxed with an audio stream
  /// before it's playable — that merge is an ffmpeg step, not a plain save.
  bool get needsMerge => hasVideo && !hasAudio;

  factory MediaFormat.fromJson(Map<String, dynamic> json) => MediaFormat(
        formatId: json['format_id'] as String,
        ext: json['ext'] as String?,
        resolution: json['resolution'] as String?,
        filesize: (json['filesize'] as num?)?.toInt(),
        hasAudio: json['has_audio'] as bool? ?? false,
        hasVideo: json['has_video'] as bool? ?? false,
        note: json['note'] as String?,
      );
}
