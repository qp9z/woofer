import 'dart:io';

/// Fetches a video's thumbnail so it can be embedded as MP3 cover art.
///
/// Best-effort by contract: every failure returns null, because artwork must
/// never cost someone their download. Uses dart:io's HttpClient rather than
/// pulling in a package — this is one GET.
///
/// Note this runs in Dart, not the Chaquopy interpreter, so it needs none of the
/// `bindProcessToNetwork` handling that Python's sockets do.
class CoverFetcher {
  const CoverFetcher();

  static const Duration _timeout = Duration(seconds: 15);

  /// Download [url] into [dir]; returns the file path, or null if there's no
  /// usable image.
  Future<String?> fetch(String? url, String dir) async {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) return null;

    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final response = await client.getUrl(uri).then((r) => r.close()).timeout(_timeout);
      if (response.statusCode != 200) return null;
      final file = File('$dir/cover${_imageExt(uri.path)}');
      await response.pipe(file.openWrite()).timeout(_timeout);
      // A zero-byte file would make ffmpeg fail the whole transcode.
      return await file.length() > 0 ? file.path : null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// ffmpeg probes the content anyway, so this is only for a sane filename.
  static String _imageExt(String path) {
    final i = path.lastIndexOf('.');
    if (i < 0) return '.jpg';
    final ext = path.substring(i).toLowerCase();
    return const {'.jpg', '.jpeg', '.png', '.webp'}.contains(ext) ? ext : '.jpg';
  }
}
