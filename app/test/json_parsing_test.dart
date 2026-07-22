import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/models/api_error.dart';
import 'package:woofer/models/media_format.dart';
import 'package:woofer/models/video_info.dart';
import 'package:woofer/services/api_exception.dart';

void main() {
  group('VideoInfo.fromJson', () {
    test('parses a full /extract payload', () {
      const raw = '''
      {
        "title": "Never Gonna Give You Up",
        "thumbnail": "https://img/thumb.jpg",
        "duration": 213.0,
        "uploader": "Rick Astley",
        "formats": [
          {"format_id":"137","ext":"mp4","resolution":"1920x1080","filesize":50000000,"has_audio":false,"has_video":true,"note":"1080p"},
          {"format_id":"140","ext":"m4a","resolution":"audio only","filesize":3000000,"has_audio":true,"has_video":false,"note":"audio"}
        ]
      }''';
      final info = VideoInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);

      expect(info.title, 'Never Gonna Give You Up');
      expect(info.thumbnail, 'https://img/thumb.jpg');
      expect(info.duration, 213.0);
      expect(info.uploader, 'Rick Astley');
      expect(info.formats, hasLength(2));

      final video = info.formats.first;
      expect(video.formatId, '137');
      expect(video.hasVideo, isTrue);
      expect(video.hasAudio, isFalse);
      expect(video.filesize, 50000000);
      expect(video.resolution, '1920x1080');
    });

    test('tolerates nulls and empty formats', () {
      const raw =
          '{"title":null,"thumbnail":null,"duration":null,"uploader":null,"formats":[]}';
      final info = VideoInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      expect(info.title, isNull);
      expect(info.duration, isNull);
      expect(info.formats, isEmpty);
    });

    test('duration given as int coerces to double', () {
      const raw = '{"formats":[],"duration":212}';
      final info = VideoInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      expect(info.duration, 212.0);
    });

    test('missing formats key defaults to empty list', () {
      const raw = '{"title":"x"}';
      final info = VideoInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      expect(info.formats, isEmpty);
    });
  });

  group('MediaFormat.fromJson', () {
    test('parses all fields', () {
      const raw =
          '{"format_id":"18","ext":"mp4","resolution":"640x360","filesize":8000000,"has_audio":true,"has_video":true,"note":"360p"}';
      final f = MediaFormat.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      expect(f.formatId, '18');
      expect(f.ext, 'mp4');
      expect(f.resolution, '640x360');
      expect(f.filesize, 8000000);
      expect(f.hasAudio, isTrue);
      expect(f.hasVideo, isTrue);
      expect(f.note, '360p');
    });

    test('null filesize / resolution / note allowed', () {
      const raw =
          '{"format_id":"251","ext":"webm","resolution":null,"filesize":null,"has_audio":true,"has_video":false,"note":null}';
      final f = MediaFormat.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      expect(f.filesize, isNull);
      expect(f.resolution, isNull);
      expect(f.note, isNull);
      expect(f.hasVideo, isFalse);
    });
  });

  group('ApiError / ApiException', () {
    test('parses the error scheme', () {
      const raw = '{"error_code":"PRIVATE","message":"Private video. Sign in to view."}';
      final err = ApiError.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      expect(err.errorCode, 'PRIVATE');
      expect(err.message, contains('Private'));
    });

    test('maps every known wire code to its enum', () {
      expect(ApiErrorCode.fromWire('PRIVATE'), ApiErrorCode.private);
      expect(ApiErrorCode.fromWire('UNAVAILABLE'), ApiErrorCode.unavailable);
      expect(ApiErrorCode.fromWire('UNSUPPORTED'), ApiErrorCode.unsupported);
      expect(ApiErrorCode.fromWire('INVALID_URL'), ApiErrorCode.invalidUrl);
      expect(ApiErrorCode.fromWire('TOO_LARGE'), ApiErrorCode.tooLarge);
      expect(ApiErrorCode.fromWire('RATE_LIMITED'), ApiErrorCode.rateLimited);
    });

    test('unrecognized code falls back to unknown but keeps rawCode', () {
      final e = ApiException.fromError(
        const ApiError(errorCode: 'WAT', message: 'nope'),
        statusCode: 500,
      );
      expect(e.code, ApiErrorCode.unknown);
      expect(e.rawCode, 'WAT');
      expect(e.statusCode, 500);
    });

    test('413 TOO_LARGE maps through fromError', () {
      const raw = '{"error_code":"TOO_LARGE","message":"Download is ~big bytes."}';
      final e = ApiException.fromError(
        ApiError.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        statusCode: 413,
      );
      expect(e.code, ApiErrorCode.tooLarge);
      expect(e.statusCode, 413);
    });
  });
}
