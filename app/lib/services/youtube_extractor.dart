import 'dart:async';
import 'dart:io';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/media_format.dart';
import '../models/video_info.dart';
import 'api_exception.dart';

typedef ProgressCallback = void Function(int received, int total);

/// On-device YouTube extraction and download via youtube_explode_dart.
///
/// [extractInfo] maps a video's streams onto our source-agnostic [VideoInfo] /
/// [MediaFormat] models; [download] streams one chosen format to a temp file.
/// All failures are normalized to [ApiException] with a mapped [ApiErrorCode].
class YoutubeExtractor {
  YoutubeExtractor([YoutubeExplode? yt]) : _yt = yt ?? YoutubeExplode();

  final YoutubeExplode _yt;

  // ponytail: single-video cache. extractInfo already fetched the manifest, so
  // we keep its streams keyed by itag to hand back to download() — no second
  // round trip. Fine for the one-video-at-a-time flow; a new extract replaces it.
  final Map<String, StreamInfo> _streams = {};

  /// Resolve [url] to a [VideoInfo] with one [MediaFormat] per usable stream:
  /// muxed (video+audio), video-only (needs a merge), and audio-only.
  Future<VideoInfo> extractInfo(String url) async {
    try {
      final video = await _yt.videos.get(url);
      final manifest = await _yt.videos.streamsClient.getManifest(url);

      // Highest resolution first, then audio tracks by size (a proxy for quality).
      final videos = [...manifest.videoOnly, ...manifest.muxed]
        ..sort((a, b) => b.videoResolution.height.compareTo(a.videoResolution.height));
      final audios = manifest.audioOnly.toList()
        ..sort((a, b) => b.size.totalBytes.compareTo(a.size.totalBytes));

      final ordered = <StreamInfo>[...videos, ...audios];
      _streams
        ..clear()
        ..addEntries(ordered.map((s) => MapEntry(s.tag.toString(), s)));

      return VideoInfo(
        title: video.title,
        thumbnail: video.thumbnails.highResUrl,
        duration: video.duration?.inSeconds.toDouble(),
        uploader: video.author,
        formats: ordered.map(_toFormat).toList(),
      );
    } catch (e) {
      throw mapYoutubeError(e);
    }
  }

  /// The youtube_explode stream for a [MediaFormat.formatId] from the last
  /// [extractInfo], or null if unknown. The bridge from a selected format to a
  /// downloadable stream.
  StreamInfo? streamFor(String formatId) => _streams[formatId];

  /// Stream [stream]'s bytes to a temp file and return its path. Reports
  /// progress via [onProgress]. Throws [ApiException] on failure.
  Future<String> download(StreamInfo stream, {ProgressCallback? onProgress, String? dir}) async {
    final target = File('${dir ?? Directory.systemTemp.path}'
        '/woofer_${DateTime.now().millisecondsSinceEpoch}.${stream.container.name}');
    try {
      await writeStreamToFile(
        _yt.videos.streamsClient.get(stream),
        stream.size.totalBytes,
        target,
        onProgress,
      );
      return target.path;
    } catch (e) {
      try {
        if (await target.exists()) await target.delete();
      } catch (_) {}
      throw mapYoutubeError(e);
    }
  }

  void close() => _yt.close();

  MediaFormat _toFormat(StreamInfo s) {
    final size = s.size.totalBytes;
    return MediaFormat(
      formatId: s.tag.toString(),
      ext: s.container.name,
      resolution: s is VideoStreamInfo ? s.qualityLabel : null,
      filesize: size > 0 ? size : null,
      hasVideo: s is VideoStreamInfo,
      hasAudio: s is AudioStreamInfo,
      note: s is VideoStreamInfo && s is! AudioStreamInfo ? 'no audio — will merge' : null,
    );
  }
}

/// Pipe [source] into [dest], reporting cumulative bytes against [totalBytes]
/// after each chunk. Kept free of youtube_explode types so it's unit-testable.
Future<void> writeStreamToFile(
    Stream<List<int>> source, int totalBytes, File dest, ProgressCallback? onProgress) async {
  final sink = dest.openWrite();
  var received = 0;
  try {
    await for (final chunk in source) {
      sink.add(chunk);
      received += chunk.length;
      onProgress?.call(received, totalBytes);
    }
    await sink.flush();
  } finally {
    await sink.close();
  }
}

/// Normalize any error from youtube_explode (or dart:io) to an [ApiException].
/// Order matters: the subtypes are checked before their supertypes.
ApiException mapYoutubeError(Object error) {
  if (error is ApiException) return error;
  // VideoId.fromString throws ArgumentError on a link it can't parse.
  if (error is ArgumentError) {
    return const ApiException(code: ApiErrorCode.invalidUrl, message: "That doesn't look like a valid video link.");
  }
  if (error is RequestLimitExceededException) {
    return const ApiException(code: ApiErrorCode.rateLimited, message: 'YouTube is rate-limiting requests. Try again shortly.');
  }
  // Covers VideoUnavailable, VideoRequiresPurchase, and restriction/live cases —
  // youtube_explode doesn't reliably distinguish private from removed, so all
  // map to `unavailable` and carry their own message.
  if (error is VideoUnplayableException) {
    return ApiException(code: ApiErrorCode.unavailable, message: error.message);
  }
  if (error is TransientFailureException || error is FatalFailureException) {
    return const ApiException(code: ApiErrorCode.network, message: 'Could not reach YouTube. Check your connection.');
  }
  if (error is SocketException || error is TimeoutException || error is HttpException) {
    return const ApiException(code: ApiErrorCode.network, message: 'Network problem. Check your connection.');
  }
  if (error is YoutubeExplodeException) {
    return ApiException(code: ApiErrorCode.unknown, message: error.message);
  }
  return ApiException(code: ApiErrorCode.unknown, message: error.toString());
}
