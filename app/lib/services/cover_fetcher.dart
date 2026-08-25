import 'dart:io';

/// Fetches a video's thumbnail so it can be embedded as MP3 cover art.
///
/// Best-effort by contract: every failure returns null, because artwork must
/// never cost someone their download. Uses dart:io's HttpClient rather than
/// pulling in a package — this is one GET. Added guards keep it honest: a
/// response larger than [maxBytes] (a thumbnail is a few hundred KB) or with a
/// clearly non-image content type is rejected, so a hijacked redirect or a
/// misbehaving CDN can't silently download a multi-GB "cover" or a bogus HTML
/// page into the scratch dir.
///
/// Note this runs in Dart, not the Chaquopy interpreter, so it needs none of the
/// `bindProcessToNetwork` handling that Python's sockets do.
class CoverFetcher {
  const CoverFetcher({this.maxBytes = _defaultMaxBytes});

  /// Longest accepted artwork. Generous — a 4K video's thumbnail is still well
  /// under this — but bounded so a runaway response stops downloading.
  final int maxBytes;

  static const int _defaultMaxBytes = 5 * 1024 * 1024; // 5 MB
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
      // Clearly non-image content (a bot page, a JSON error) isn't worth writing.
      // Loose on purpose: only reject when a type is present and unmistakably
      // not an image, since some CDNs serve webp as application/octet-stream.
      if (_rejectsContentType(response)) return null;

      final file = File('$dir/cover${_imageExt(uri.path)}');
      final sink = file.openWrite();
      var received = 0;
      var overLimit = false;
      try {
        await for (final chunk in response) {
          received += chunk.length;
          if (received > maxBytes) {
            overLimit = true;
            break;
          }
          sink.add(chunk);
        }
        await sink.close();
      } catch (_) {
        try { await sink.close(); } catch (_) {}
        await _deleteQuietly(file);
        return null;
      }
      if (overLimit) {
        await _deleteQuietly(file);
        return null;
      }
      // A zero-byte file would make ffmpeg fail the whole transcode.
      return received > 0 ? file.path : null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// Whether the response advertises a content type that is clearly not an
  /// image. Absent/unknown types are allowed through (can't tell, and artwork is
  /// best-effort); octet-stream is allowed (generic binary, commonly wraps webp).
  static bool _rejectsContentType(HttpClientResponse response) {
    final raw = response.headers.value(HttpHeaders.contentTypeHeader);
    if (raw == null || raw.trim().isEmpty) return false;
    final primary = raw.split(';').first.trim().toLowerCase();
    if (primary.startsWith('image/')) return false;
    if (primary == 'application/octet-stream') return false;
    return true;
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// ffmpeg probes the content anyway, so this is only for a sane filename.
  static String _imageExt(String path) {
    final i = path.lastIndexOf('.');
    if (i < 0) return '.jpg';
    final ext = path.substring(i).toLowerCase();
    return const {'.jpg', '.jpeg', '.png', '.webp'}.contains(ext) ? ext : '.jpg';
  }
}