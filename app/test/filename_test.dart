import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/services/filename.dart';

void main() {
  group('safeMediaFileName', () {
    test('keeps a normal title and the extension', () {
      expect(safeMediaFileName('My Favorite Song', 'mp3'), 'My Favorite Song.mp3');
      expect(safeMediaFileName('Clip', 'webm'), 'Clip.webm');
    });

    test('substitutes invalid filesystem characters with underscore', () {
      expect(
        safeMediaFileName(r'a/b\c:d*e?f"g<h>i|j', 'mp4'),
        'a_b_c_d_e_f_g_h_i_j.mp4',
      );
    });

    test('trims trailing dots and spaces that confuse the filesystem', () {
      expect(safeMediaFileName('Title...  ', 'mp4'), 'Title.mp4');
      expect(safeMediaFileName('Title. ', 'mp4'), 'Title.mp4');
    });

    test('falls back to a timestamped placeholder for a blank title', () {
      final name = safeMediaFileName(null, 'mp4');
      expect(name, startsWith('woofer_'));
      expect(name, endsWith('.mp4'));

      final blank = safeMediaFileName('   ', 'mp3');
      expect(blank, startsWith('woofer_'));
      expect(blank, endsWith('.mp3'));
    });

    test('preserves the extension for a very long title', () {
      final long = 'x' * 500;
      final name = safeMediaFileName(long, 'mp4');
      expect(name, endsWith('.mp4'));
      // The whole component must fit within Android's 255-byte limit.
      expect(utf8.encode(name).length, lessThanOrEqualTo(maxFileNameBytes));
    });

    test('truncates multi-byte titles without splitting a character', () {
      // Filled circles are 3 bytes each in UTF-8.
      final name = safeMediaFileName('●' * 200, 'mp4');
      expect(name, endsWith('.mp4'));
      expect(utf8.encode(name).length, lessThanOrEqualTo(maxFileNameBytes));
      // Every base character is a whole '●' — no torn multi-byte sequence.
      expect(name.replaceAll('●', ''), '.mp4');
    });

    test('handles a mix of multi-byte and ASCII beyond the budget', () {
      final name = safeMediaFileName('é' * 300, 'webm');
      expect(utf8.encode(name).length, lessThanOrEqualTo(maxFileNameBytes));
      expect(name, endsWith('.webm'));
      expect(name.replaceAll('é', ''), '.webm');
    });

    test('newlines and control characters are replaced', () {
      expect(safeMediaFileName('line\nbreak\t', 'mp4'), 'line_break.mp4');
    });

    test('Unicode title stays readable and within the byte budget', () {
      final name = safeMediaFileName('こんにちは世界の動画です', 'mp4');
      expect(name, endsWith('.mp4'));
      expect(utf8.encode(name).length, lessThanOrEqualTo(maxFileNameBytes));
    });
  });
}