import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/ui/format_utils.dart';

void main() {
  test('formatBytes scales and rounds', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(1024), '1.0 KB');
    expect(formatBytes(1536), '1.5 KB');
    expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
    // >= 100 drops the decimal so rows stay narrow.
    expect(formatBytes(150 * 1024 * 1024), '150 MB');
  });

  test('formatBytes has a dash for unknown/zero', () {
    expect(formatBytes(null), '—');
    expect(formatBytes(0), '—');
  });

  test('formatDuration pads and adds hours only when needed', () {
    expect(formatDuration(187), '3:07');
    expect(formatDuration(3727), '1:02:07');
    expect(formatDuration(null), '');
  });

  test('formatDate is day-month-year', () {
    expect(formatDate(DateTime(2026, 7, 22)), '22 Jul 2026');
  });

  test('formatIsVideo sniffs a resolution or mp4 as video', () {
    expect(formatIsVideo('1080p'), isTrue);
    expect(formatIsVideo('720p · MP4'), isTrue);
    // What yt-dlp actually reports, and so what history actually stores.
    expect(formatIsVideo('1920x1080'), isTrue);
    expect(formatIsVideo('192x144'), isTrue);
    expect(formatIsVideo('192×144'), isTrue);
    expect(formatIsVideo('MP3 · 192 kbps'), isFalse);
    expect(formatIsVideo('audio only'), isFalse);
    expect(formatIsVideo('medium'), isFalse);
    expect(formatIsVideo(null), isFalse);
  });
}
