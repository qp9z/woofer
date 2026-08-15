import 'media_format.dart';

/// Returns a new list ranked best-first, independent of yt-dlp's input order.
/// Missing quality metadata always follows known metadata at the same tier.
List<MediaFormat> orderVideoFormats(Iterable<MediaFormat> formats) =>
    formats.toList()..sort(_compareVideo);

/// Returns a new list ranked best-first, independent of yt-dlp's input order.
List<MediaFormat> orderAudioFormats(Iterable<MediaFormat> formats) =>
    formats.toList()..sort(_compareAudio);

/// The fixed default advertised by Settings: the best available format for the
/// selected media kind. This is deliberately separate from list position so a
/// future display-order change cannot silently change download behaviour.
MediaFormat? chooseDefaultFormat(
  Iterable<MediaFormat> formats, {
  required bool video,
}) {
  final ranked = video
      ? orderVideoFormats(formats.where((format) => format.hasVideo))
      : orderAudioFormats(
          formats.where((format) => format.hasAudio && !format.hasVideo),
        );
  return ranked.isEmpty ? null : ranked.first;
}

int _compareVideo(MediaFormat a, MediaFormat b) => _firstNonZero([
  _compareOptionalNum(_videoHeight(a), _videoHeight(b)),
  _compareOptionalNum(a.width, b.width),
  _compareOptionalNum(a.fps, b.fps),
  _compareOptionalNum(
    a.videoBitrate ?? a.totalBitrate,
    b.videoBitrate ?? b.totalBitrate,
  ),
  _compareOptionalNum(a.filesize, b.filesize),
  _compareText(a.videoCodec, b.videoCodec),
  _compareText(a.ext, b.ext),
  _compareText(a.note, b.note),
  _compareFormatId(a.formatId, b.formatId),
]);

int _compareAudio(MediaFormat a, MediaFormat b) => _firstNonZero([
  _compareOptionalNum(
    a.audioBitrate ?? a.totalBitrate,
    b.audioBitrate ?? b.totalBitrate,
  ),
  _compareOptionalNum(a.sampleRate, b.sampleRate),
  _compareOptionalNum(a.audioChannels, b.audioChannels),
  _compareOptionalNum(a.filesize, b.filesize),
  _compareText(a.audioCodec, b.audioCodec),
  _compareText(a.ext, b.ext),
  _compareText(a.note, b.note),
  _compareFormatId(a.formatId, b.formatId),
]);

num? _videoHeight(MediaFormat format) {
  if (format.height != null) return format.height;
  final resolution = format.resolution;
  if (resolution == null) return null;
  final dimensions = RegExp(
    r'\d+\s*[x×]\s*(\d+)',
    caseSensitive: false,
  ).firstMatch(resolution);
  if (dimensions != null) return int.tryParse(dimensions.group(1)!);
  final vertical = RegExp(
    r'(\d+)p\b',
    caseSensitive: false,
  ).firstMatch(resolution);
  return vertical == null ? null : int.tryParse(vertical.group(1)!);
}

int _compareOptionalNum(num? a, num? b) {
  if (a == null) return b == null ? 0 : 1;
  if (b == null) return -1;
  return b.compareTo(a);
}

int _compareText(String? a, String? b) {
  final left = a?.trim().toLowerCase();
  final right = b?.trim().toLowerCase();
  if (left == null || left.isEmpty) {
    return right == null || right.isEmpty ? 0 : 1;
  }
  if (right == null || right.isEmpty) return -1;
  return left.compareTo(right);
}

int _compareFormatId(String a, String b) {
  final left = int.tryParse(a);
  final right = int.tryParse(b);
  if (left != null && right != null) return left.compareTo(right);
  return a.compareTo(b);
}

int _firstNonZero(List<int> comparisons) =>
    comparisons.firstWhere((value) => value != 0, orElse: () => 0);
