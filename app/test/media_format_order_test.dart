import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/models/media_format.dart';
import 'package:woofer/models/media_format_order.dart';

void main() {
  MediaFormat video(
    String id, {
    String? resolution,
    int? width,
    int? height,
    double? fps,
    double? bitrate,
    int? filesize,
    String? note,
  }) => MediaFormat(
    formatId: id,
    ext: 'mp4',
    resolution: resolution,
    width: width,
    height: height,
    fps: fps,
    videoBitrate: bitrate,
    filesize: filesize,
    note: note,
    hasAudio: false,
    hasVideo: true,
  );

  MediaFormat audio(
    String id, {
    double? bitrate,
    double? sampleRate,
    int? channels,
    int? filesize,
    String? note,
  }) => MediaFormat(
    formatId: id,
    ext: 'm4a',
    audioBitrate: bitrate,
    sampleRate: sampleRate,
    audioChannels: channels,
    filesize: filesize,
    note: note,
    hasAudio: true,
    hasVideo: false,
  );

  test('video order is resolution, width, FPS, bitrate, then size', () {
    final ordered = orderVideoFormats([
      video('720', height: 720, fps: 60, bitrate: 3000),
      video('1080-low-fps', height: 1080, fps: 30, bitrate: 5000),
      video('1080', height: 1080, fps: 60, bitrate: 4000),
      video('1080-wide', height: 1080, width: 2560, fps: 60, bitrate: 4000),
    ]);

    expect(ordered.map((format) => format.formatId), [
      '1080-wide',
      '1080',
      '1080-low-fps',
      '720',
    ]);
  });

  test('resolution text is used when explicit dimensions are missing', () {
    final ordered = orderVideoFormats([
      video('360', resolution: '640x360'),
      video('1080', resolution: '1080p'),
      video('720', resolution: '1280×720'),
    ]);

    expect(ordered.map((format) => format.formatId), ['1080', '720', '360']);
  });

  test('audio order is bitrate, sample rate, channels, then size', () {
    final ordered = orderAudioFormats([
      audio('128', bitrate: 128, sampleRate: 48000, channels: 2),
      audio('192-low-rate', bitrate: 192, sampleRate: 44100, channels: 2),
      audio('192', bitrate: 192, sampleRate: 48000, channels: 2),
      audio('192-surround', bitrate: 192, sampleRate: 48000, channels: 6),
    ]);

    expect(ordered.map((format) => format.formatId), [
      '192-surround',
      '192',
      '192-low-rate',
      '128',
    ]);
  });

  test('known metadata precedes missing filesize, resolution and bitrate', () {
    expect(
      orderVideoFormats([
        video('unknown'),
        video('known', resolution: '720p'),
      ]).first.formatId,
      'known',
    );
    expect(
      orderVideoFormats([
        video('unknown-size', height: 720),
        video('known-size', height: 720, filesize: 10),
      ]).first.formatId,
      'known-size',
    );
    expect(
      orderAudioFormats([
        audio('unknown'),
        audio('known', bitrate: 128),
      ]).first.formatId,
      'known',
    );
  });

  test('missing notes are safe and format id breaks complete ties', () {
    final forward = orderAudioFormats([audio('10'), audio('2')]);
    final reverse = orderAudioFormats([audio('2'), audio('10')]);

    expect(forward.map((format) => format.formatId), ['2', '10']);
    expect(reverse.map((format) => format.formatId), ['2', '10']);
  });

  test('default video is explicitly the best available candidate', () {
    final selected = chooseDefaultFormat([
      video('low', height: 360),
      video('best', height: 2160),
    ], video: true);

    expect(selected?.formatId, 'best');
  });

  test('default audio is explicitly the highest-quality candidate', () {
    final selected = chooseDefaultFormat([
      audio('low', bitrate: 96),
      audio('best', bitrate: 256),
    ], video: false);

    expect(selected?.formatId, 'best');
  });
}
