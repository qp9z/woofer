import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/services/platform_router.dart';

void main() {
  group('detectPlatform', () {
    final cases = <String, SourcePlatform>{
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ': SourcePlatform.youtube,
      'https://youtu.be/dQw4w9WgXcQ': SourcePlatform.youtube,
      'https://m.youtube.com/watch?v=abc': SourcePlatform.youtube,
      'https://music.youtube.com/watch?v=abc': SourcePlatform.youtube,
      'https://www.youtube-nocookie.com/embed/abc': SourcePlatform.youtube,
      'youtube.com/watch?v=noscheme': SourcePlatform.youtube, // missing scheme
      'https://www.instagram.com/reel/xyz/': SourcePlatform.instagram,
      'https://instagr.am/p/xyz/': SourcePlatform.instagram,
      'https://www.tiktok.com/@user/video/123': SourcePlatform.tiktok,
      'https://vm.tiktok.com/ZMabc/': SourcePlatform.tiktok,
      'https://twitter.com/user/status/123': SourcePlatform.twitter,
      'https://x.com/user/status/123': SourcePlatform.twitter,
      'https://mobile.twitter.com/user/status/123': SourcePlatform.twitter,
      'https://t.co/abc123': SourcePlatform.twitter,
      'https://vimeo.com/123456': SourcePlatform.other,
      'https://example.com/video.mp4': SourcePlatform.other,
      'not a url at all': SourcePlatform.other,
      '': SourcePlatform.other,
    };

    cases.forEach((url, expected) {
      test('"$url" → $expected', () => expect(detectPlatform(url), expected));
    });

    test('host match is not fooled by lookalike domains', () {
      // notyoutube.com must NOT match youtube.com.
      expect(detectPlatform('https://notyoutube.com/watch'), SourcePlatform.other);
      // youtube.com.evil.com is a subdomain of evil.com, not youtube.com.
      expect(detectPlatform('https://youtube.com.evil.com/x'), SourcePlatform.other);
    });

    test('detection is case-insensitive on the host', () {
      expect(detectPlatform('HTTPS://WWW.YouTube.COM/watch?v=x'), SourcePlatform.youtube);
    });
  });

  group('routeFor', () {
    test('YouTube goes to the pure-Dart extractor', () {
      expect(routeFor('https://youtu.be/x'), Extractor.DART_YOUTUBE);
    });

    test('everything else falls back to yt-dlp', () {
      for (final url in const [
        'https://www.instagram.com/reel/x/',
        'https://www.tiktok.com/@u/video/1',
        'https://x.com/u/status/1',
        'https://vimeo.com/1',
      ]) {
        expect(routeFor(url), Extractor.PYTHON_YTDLP, reason: url);
      }
    });
  });
}
