/// One downloadable format. Source-agnostic: [formatId] is a YouTube itag, a
/// yt-dlp format id, or any stable per-source identifier.
class MediaFormat {
  final String formatId;
  final String? ext;
  final String? resolution;
  final int? filesize;
  final int? width;
  final int? height;
  final double? fps;
  final double? totalBitrate;
  final double? videoBitrate;
  final double? audioBitrate;
  final double? sampleRate;
  final int? audioChannels;
  final String? videoCodec;
  final String? audioCodec;
  final bool hasAudio;
  final bool hasVideo;
  final String? note;

  const MediaFormat({
    required this.formatId,
    this.ext,
    this.resolution,
    this.filesize,
    this.width,
    this.height,
    this.fps,
    this.totalBitrate,
    this.videoBitrate,
    this.audioBitrate,
    this.sampleRate,
    this.audioChannels,
    this.videoCodec,
    this.audioCodec,
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
    width: (json['width'] as num?)?.toInt(),
    height: (json['height'] as num?)?.toInt(),
    fps: (json['fps'] as num?)?.toDouble(),
    totalBitrate: (json['tbr'] as num?)?.toDouble(),
    videoBitrate: (json['vbr'] as num?)?.toDouble(),
    audioBitrate: (json['abr'] as num?)?.toDouble(),
    sampleRate: (json['asr'] as num?)?.toDouble(),
    audioChannels: (json['audio_channels'] as num?)?.toInt(),
    videoCodec: json['vcodec'] as String?,
    audioCodec: json['acodec'] as String?,
    hasAudio: json['has_audio'] as bool? ?? false,
    hasVideo: json['has_video'] as bool? ?? false,
    note: json['note'] as String?,
  );
}
