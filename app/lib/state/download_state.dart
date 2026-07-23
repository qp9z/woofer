import '../models/media_format.dart';
import '../models/video_info.dart';
import '../services/api_exception.dart';

/// Plain, immutable states for the download flow. Widgets switch on the
/// concrete type. No Riverpod here on purpose — import this to build UI.
sealed class DownloadState {
  const DownloadState();
}

/// Nothing entered yet.
class Idle extends DownloadState {
  const Idle();
}

/// Resolving a URL via `api.extract`.
class Loading extends DownloadState {
  const Loading();
}

/// Extraction succeeded: pick a format from [info.formats].
class FormatsReady extends DownloadState {
  final VideoInfo info;
  final MediaFormat? selected;
  const FormatsReady(this.info, {this.selected});

  List<MediaFormat> get formats => info.formats;

  FormatsReady select(MediaFormat format) => FormatsReady(info, selected: format);
}

/// Streaming the file. [total] is -1 when the server sends no length, in which
/// case [progress] is null (show an indeterminate bar).
class Downloading extends DownloadState {
  final MediaFormat format;
  final int received;
  final int total;
  const Downloading({required this.format, required this.received, required this.total});

  double? get progress => total > 0 ? received / total : null;
}

/// Post-download work on-device: merging a video-only stream with audio, or
/// transcoding to MP3. [label] describes which, for the UI. Indeterminate —
/// ffmpeg gives no reliable percentage here, so show a spinner.
class Processing extends DownloadState {
  final MediaFormat format;
  final String label;
  const Processing(this.format, this.label);
}

/// Saved to public Downloads and recorded in history.
class Done extends DownloadState {
  final String path; // public Downloads path
  final String? uri; // content:// (API 29+) or file://
  const Done({required this.path, this.uri});
}

/// Any failure — extraction, download, or save. [code] is the API error code;
/// save/permission failures reuse [ApiErrorCode.unknown] with a message.
// ponytail: storage/permission errors fold into `unknown`; add a dedicated
// code if the UI needs to distinguish "grant permission" from a real failure.
class Failed extends DownloadState {
  final ApiErrorCode code;
  final String message;
  const Failed(this.code, this.message);
}
