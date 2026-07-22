// Enum values use the exact names the router contract asks for
// (DART_YOUTUBE / PYTHON_YTDLP), which trip the SCREAMING_SNAKE lint.
// ignore_for_file: constant_identifier_names

/// Which source a URL belongs to. `other` is the catch-all for anything
/// yt-dlp might still handle but we don't special-case.
enum SourcePlatform { youtube, instagram, tiktok, twitter, other }

/// Which extractor handles a URL:
/// - [DART_YOUTUBE]: youtube_explode_dart, pure Dart, fully on-device.
/// - [PYTHON_YTDLP]: yt-dlp, the fallback for everything else.
enum Extractor { DART_YOUTUBE, PYTHON_YTDLP }

/// Registered domains per platform. A host matches a domain when it equals it
/// or is a subdomain of it (`m.youtube.com` matches `youtube.com`).
const Map<SourcePlatform, List<String>> _domains = {
  SourcePlatform.youtube: ['youtube.com', 'youtu.be', 'youtube-nocookie.com'],
  SourcePlatform.instagram: ['instagram.com', 'instagr.am'],
  SourcePlatform.tiktok: ['tiktok.com'],
  SourcePlatform.twitter: ['twitter.com', 'x.com', 't.co'],
};

/// Host of [url], lowercased with a leading `www.` stripped. Returns `''` when
/// the URL is unparseable or hostless. Tolerates a missing scheme
/// (`youtube.com/watch?...`) by retrying with `https://` prepended.
String _host(String url) {
  final trimmed = url.trim();
  var uri = Uri.tryParse(trimmed);
  if (uri == null || uri.host.isEmpty) uri = Uri.tryParse('https://$trimmed');
  var host = (uri?.host ?? '').toLowerCase();
  if (host.startsWith('www.')) host = host.substring(4);
  return host;
}

/// Classify [url] by platform via its host. Unknown hosts → [SourcePlatform.other].
SourcePlatform detectPlatform(String url) {
  final host = _host(url);
  if (host.isEmpty) return SourcePlatform.other;
  for (final entry in _domains.entries) {
    for (final domain in entry.value) {
      if (host == domain || host.endsWith('.$domain')) return entry.key;
    }
  }
  return SourcePlatform.other;
}

/// Pick the extractor for [url]. Only YouTube has a pure-Dart path today;
/// everything else routes to yt-dlp.
Extractor routeFor(String url) => detectPlatform(url) == SourcePlatform.youtube
    ? Extractor.DART_YOUTUBE
    : Extractor.PYTHON_YTDLP;
