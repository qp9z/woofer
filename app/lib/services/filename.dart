import 'dart:convert';

/// The longest a single filename *component* may be on the filesystems Android
/// ships on (ext4/f2fs, and FUSE-backed emulated storage reachable via
/// MediaStore) is 255 *bytes*, so a UTF-8 title can only be ~63 emoji. We
/// reserve this whole budget for the file's own name; the path lives in our
/// private Downloads directory and is unaffected.
const int maxFileNameBytes = 255;

/// Build a file name for a downloaded media file that MediaStore and the
/// underlying filesystem will actually accept:
///
///  - substitutes characters the filesystem or Android treats specially;
///  - trims trailing dots and spaces (both are effectively ignored by
///    Windows-style names and can make a saved and a tapped row not match);
///  - truncates multi-byte titles to fit [maxFileNameBytes] without splitting
///    a Unicode character in half, preserving the extension;
///  - fills a blank title with a timestamped placeholder.
String safeMediaFileName(String? title, String ext) {
  final raw = (title == null || title.trim().isEmpty)
      ? 'woofer_${DateTime.now().millisecondsSinceEpoch}'
      : title.trim();
  final sanitized = raw
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f\x7f]'), '_')
      .replaceAll(RegExp(r'^\.+'), '') // leading dots are fine, but be tidy
      .replaceAll(RegExp(r'[.\s]+$'), ''); // trailing dot/space: ambiguous
  final dotExt = '.${ext.toLowerCase()}';
  final budget = maxFileNameBytes - dotExt.length;
  final base = budget > 0 ? _truncateBytes(sanitized, budget) : '';
  return '$base$dotExt';
}

/// Truncate [text] to fit within [maxBytes] of UTF-8, never splitting a
/// multi-byte character. Returns the longest prefix whose encoding is at most
/// [maxBytes] bytes long.
String _truncateBytes(String text, int maxBytes) {
  var total = 0;
  final kept = <int>[];
  for (final rune in text.runes) {
    final byteLen = utf8.encode(String.fromCharCode(rune)).length;
    if (total + byteLen > maxBytes) break;
    total += byteLen;
    kept.add(rune);
  }
  return String.fromCharCodes(kept);
}