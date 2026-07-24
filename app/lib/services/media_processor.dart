import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import 'api_exception.dart';

/// Runs ffmpeg [args]; returns `null` on success or a human-readable error on
/// failure. Injectable so the cleanup/error logic is testable without a device.
typedef FfmpegRun = Future<String?> Function(List<String> args);

/// On-device replacement for what the server's ffmpeg used to do: mux a
/// video-only stream with an audio stream into an MP4, and transcode audio to
/// MP3. Uses ffmpeg_kit_flutter.
///
/// Both operations clean up after themselves: a failed run never leaves a
/// half-written output behind, and a successful run deletes the (now redundant)
/// source files unless `deleteInputs: false`.
class MediaProcessor {
  MediaProcessor({FfmpegRun? runner, Directory? workDir})
      : _run = runner ?? _runFfmpeg,
        _dir = workDir ?? Directory.systemTemp;

  final FfmpegRun _run;
  final Directory _dir;

  /// Mux [video] (video-only) and [audio] into one file, returning its path. The
  /// container is chosen to fit the streams by *stream-copy* (no re-encode): MP4
  /// for the H.264+AAC case, WebM for YouTube's 4K VP9/AV1+Opus, MKV for anything
  /// else. A 4K on-device re-encode would be minutes of heat — copy is instant.
  Future<String> mergeVideoAudio(String video, String audio, {bool deleteInputs = true}) async {
    final out = _outPath('woofer_merged', mergeContainer(video, audio));
    await _process(
      args: mergeArgs(video, audio, out),
      output: out,
      inputs: [video, audio],
      deleteInputs: deleteInputs,
    );
    return out;
  }

  /// A container that accepts both input streams by copy, picked from their
  /// extensions (which reflect codecs): mp4 only when both are MP4-family, webm
  /// for the VP9/AV1 + Opus pair, else mkv (holds any combination).
  static String mergeContainer(String video, String audio) {
    final v = _ext(video), a = _ext(audio);
    const mp4V = {'mp4', 'm4v', 'mov'};
    const mp4A = {'m4a', 'mp4', 'aac'};
    if (mp4V.contains(v) && mp4A.contains(a)) return 'mp4';
    if (v == 'webm' && {'webm', 'opus', 'ogg'}.contains(a)) return 'webm';
    return 'mkv';
  }

  static String _ext(String path) {
    final i = path.lastIndexOf('.');
    return i < 0 ? '' : path.substring(i + 1).toLowerCase();
  }

  /// Transcode [input]'s audio to a [bitrateKbps]kbps MP3 (dropping any video
  /// track), returning its path.
  ///
  // MP3 needs libmp3lame — present in ffmpeg_kit_flutter_new (full-gpl). The
  // full-gpl binary also pulls in GPL codecs (x264 etc.) we don't invoke; the
  // LGPL `ffmpeg_kit_flutter_new_audio` variant also carries lame if licensing
  // matters. ponytail: only libmp3lame + built-in muxers are actually used here.
  Future<String> toMp3(String input, [int bitrateKbps = 192, bool deleteInputs = true]) async {
    final out = _outPath('woofer', 'mp3');
    await _process(
      args: mp3Args(input, out, bitrateKbps),
      output: out,
      inputs: [input],
      deleteInputs: deleteInputs,
    );
    return out;
  }

  Future<void> _process({
    required List<String> args,
    required String output,
    required List<String> inputs,
    required bool deleteInputs,
  }) async {
    String? error;
    try {
      error = await _run(args);
    } catch (e) {
      error = e.toString();
    }
    // ffmpeg can report success yet write nothing (e.g. a filtered-out stream).
    if (error == null && !await File(output).exists()) {
      error = 'ffmpeg reported success but produced no output.';
    }

    if (error != null) {
      // Never hand back a corrupt partial; leave inputs so the caller can retry.
      await _deleteQuietly(output);
      throw ApiException(code: ApiErrorCode.unknown, message: 'Media processing failed: $error');
    }

    if (deleteInputs) {
      for (final f in inputs) {
        await _deleteQuietly(f);
      }
    }
  }

  String _outPath(String prefix, String ext) =>
      '${_dir.path}/${prefix}_${DateTime.now().microsecondsSinceEpoch}.$ext';

  static Future<void> _deleteQuietly(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Args to mux one video track and one audio track into [out] by stream copy.
  /// `+faststart` is MP4-only (moov atom up front → plays before fully written);
  /// it's invalid for webm/mkv, so it's applied only when the output is MP4.
  static List<String> mergeArgs(String video, String audio, String out) => [
        '-y', // overwrite output if present
        '-i', video,
        '-i', audio,
        '-map', '0:v:0',
        '-map', '1:a:0',
        '-c', 'copy',
        if (_ext(out) == 'mp4') ...['-movflags', '+faststart'],
        out,
      ];

  /// Args to transcode [input] to a [kbps]kbps MP3, discarding video.
  static List<String> mp3Args(String input, String out, int kbps) => [
        '-y',
        '-i', input,
        '-vn', // no video
        '-c:a', 'libmp3lame',
        '-b:a', '${kbps}k',
        out,
      ];
}

/// Default runner: execute via ffmpeg_kit and reduce the session to null (ok) or
/// an error string. Uses argument-list execution so paths with spaces are safe.
Future<String?> _runFfmpeg(List<String> args) async {
  final session = await FFmpegKit.executeWithArguments(args);
  final rc = await session.getReturnCode();
  if (ReturnCode.isSuccess(rc)) return null;
  if (ReturnCode.isCancel(rc)) return 'cancelled';
  final detail = await session.getFailStackTrace() ?? await session.getOutput();
  final trimmed = detail?.trim();
  return (trimmed != null && trimmed.isNotEmpty) ? trimmed : 'ffmpeg exited with code ${rc?.getValue()}';
}
