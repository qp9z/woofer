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

  /// Mux [video] (video-only) and [audio] into a single MP4, returning its path.
  ///
  // ponytail: stream-copy (`-c copy`), no re-encode — correct and fast for the
  // common H.264 + AAC(m4a) case our extractors pick. A VP9/Opus pair won't fit
  // an MP4 by copy; add a re-encode fallback if you start offering those formats.
  Future<String> mergeVideoAudio(String video, String audio, {bool deleteInputs = true}) async {
    final out = _outPath('woofer_merged', 'mp4');
    await _process(
      args: mergeArgs(video, audio, out),
      output: out,
      inputs: [video, audio],
      deleteInputs: deleteInputs,
    );
    return out;
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

  /// Args to mux one video track and one audio track into MP4 by stream copy.
  static List<String> mergeArgs(String video, String audio, String out) => [
        '-y', // overwrite output if present
        '-i', video,
        '-i', audio,
        '-map', '0:v:0',
        '-map', '1:a:0',
        '-c', 'copy',
        '-movflags', '+faststart', // moov atom up front → plays before fully written
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
