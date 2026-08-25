import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/video_info.dart';
import 'api_exception.dart';

/// Extraction/download via yt-dlp running on-device (Chaquopy), reached over the
/// `ytdlp` [MethodChannel]. The single extractor for every site. The native side
/// emits our exact snake_case JSON shape, so [VideoInfo.fromJson] parses it unchanged.
///
/// The channel contract:
///  - `extract_info(url)`      → JSON `{"ok":true,"data":<VideoInfo>}` or `{"ok":false,"code","message"}`
///  - `download(url,format_id,dir?)` → JSON `{"ok":true,"path":"…"}` or an error envelope
///  - native → Dart `onProgress({received,total})` fires during a download
class YtdlpExtractor {
  YtdlpExtractor({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('ytdlp') {
    _channel.setMethodCallHandler(_onNativeCall);
  }

  final MethodChannel _channel;
  // One download at a time; the active callback receives native progress pings.
  void Function(int received, int total)? _onProgress;

  /// Resolve [url] to a [VideoInfo]. Throws [ApiException] on any failure.
  Future<VideoInfo> extractInfo(String url) async {
    final envelope = await _invoke('extract_info', {'url': url});
    try {
      final rawData = envelope['data'];
      if (rawData is! Map) throw const FormatException('data is not a map');
      return VideoInfo.fromJson(Map<String, dynamic>.from(rawData));
    } catch (_) {
      throw _invalidResponse();
    }
  }

  /// Download the [formatId] stream of [url] to a temp file and return its path.
  /// Reports progress via [onProgress]. Throws [ApiException] on failure.
  ///
  // ponytail: downloads a single yt-dlp format only. A merged selection
  // (video-only + audio) needs ffmpeg, which yt-dlp can't find on Android — that
  // merge is the ffmpeg_kit step, handled by the caller, not here.
  Future<String> download(
    String url,
    String formatId, {
    void Function(int received, int total)? onProgress,
    String? dir,
  }) async {
    _onProgress = onProgress;
    try {
      final envelope = await _invoke('download', {
        'url': url,
        'format_id': formatId,
        'dir': ?dir,
      });
      final path = envelope['path'];
      if (path is! String || path.isEmpty) throw _invalidResponse();
      return path;
    } finally {
      _onProgress = null;
    }
  }

  /// Abort the transfer in flight. yt-dlp only lets us interrupt from its progress
  /// hook, so this sets a flag the hook raises on — the pending [download] then
  /// completes with a `CANCELLED` envelope instead of running to the last byte.
  /// A no-op when nothing is downloading.
  Future<void> cancel() async {
    try {
      await _channel.invokeMethod<bool>('cancel_download');
    } on PlatformException {
      // nothing to cancel
    } on MissingPluginException {
      // off-device (tests)
    }
  }

  /// Re-bind the process to the current active network. Needed after a Wi-Fi
  /// ↔ cellular switch so Python's C sockets pick up the new network.
  Future<void> rebindNetwork() async {
    try {
      await _channel.invokeMethod<bool>('rebind_network');
    } on PlatformException {
      // nothing to rebind
    } on MissingPluginException {
      // off-device (tests)
    }
  }

  /// Invoke [method], decode the JSON envelope, and translate every failure mode
  /// (error envelope, PlatformException, missing plugin) into an [ApiException].
  Future<Map<String, dynamic>> _invoke(
    String method,
    Map<String, dynamic> args,
  ) async {
    final String raw;
    try {
      final res = await _channel.invokeMethod<String>(method, args);
      if (res == null) {
        throw const ApiException(
          code: ApiErrorCode.unknown,
          message: 'Empty response from yt-dlp.',
        );
      }
      raw = res;
    } on MissingPluginException {
      throw const ApiException(
        code: ApiErrorCode.unknown,
        message: 'The yt-dlp backend is unavailable on this build.',
      );
    } on PlatformException catch (e) {
      throw ApiException(
        code: ytdlpErrorCode(e.code),
        message: e.message ?? 'yt-dlp failed.',
      );
    }

    final Map<String, dynamic> map;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException('envelope is not a map');
      map = Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw _invalidResponse();
    }
    if (map['ok'] == true) return map;
    final rawCode = map['code'];
    final rawMessage = map['message'];
    throw ApiException(
      code: ytdlpErrorCode(rawCode is String ? rawCode : null),
      message: rawMessage is String ? rawMessage : 'yt-dlp failed.',
    );
  }

  Future<dynamic> _onNativeCall(MethodCall call) async {
    if (call.method == 'onProgress') {
      final args = call.arguments;
      if (args is! Map) return null;
      final received = args['received'];
      final total = args['total'];
      if (received is num && total is num) {
        _onProgress?.call(received.toInt(), total.toInt());
      }
    }
    return null;
  }
}

ApiException _invalidResponse() => const ApiException(
  code: ApiErrorCode.unknown,
  message:
      'The media extractor returned an invalid response. Please try again.',
  rawCode: 'MALFORMED_RESPONSE',
);

/// Map a yt-dlp classification token to an [ApiErrorCode]. Shares the backend's
/// wire vocabulary via [ApiErrorCode.fromWire]; only the two on-device-only
/// tokens (NETWORK, GEO) need special-casing.
ApiErrorCode ytdlpErrorCode(String? code) => switch (code) {
  'NETWORK' => ApiErrorCode.network,
  'GEO' => ApiErrorCode.unavailable,
  'NO_VIDEO' => ApiErrorCode.noVideo,
  'BOT_CHECK' => ApiErrorCode.botCheck,
  _ => ApiErrorCode.fromWire(code),
};
