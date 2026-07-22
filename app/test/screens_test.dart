import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/models/media_format.dart';
import 'package:woofer/models/video_info.dart';
import 'package:woofer/state/download_controller.dart';
import 'package:woofer/ui/screens/formats_screen.dart';
import 'package:woofer/ui/screens/history_screen.dart';
import 'package:woofer/ui/theme/app_theme.dart';

Widget _app(Widget home, {List<Override> overrides = const []}) => ProviderScope(
      overrides: overrides,
      child: CupertinoApp(theme: AppTheme.of(Brightness.dark), home: home),
    );

const _info = VideoInfo(
  title: 'A Very Good Clip',
  uploader: 'Someone',
  duration: 187,
  formats: [
    MediaFormat(
        formatId: '137',
        ext: 'mp4',
        resolution: '1080p',
        filesize: 5 * 1024 * 1024,
        hasAudio: false,
        hasVideo: true),
    MediaFormat(formatId: '140', ext: 'm4a', hasAudio: true, hasVideo: false),
  ],
);

void main() {
  testWidgets('FormatsScreen shows the header and one row per format', (t) async {
    await t.pumpWidget(_app(const FormatsScreen(info: _info)));

    expect(find.text('A Very Good Clip'), findsOneWidget);
    expect(find.text('Someone · 3:07'), findsOneWidget);
    expect(find.text('2 AVAILABLE'), findsOneWidget);

    expect(find.text('1080p · MP4'), findsOneWidget);
    expect(find.text('5.0 MB'), findsOneWidget);
    expect(find.text('Audio · M4A'), findsOneWidget);

    // Capability badges come from has_video / has_audio.
    expect(find.text('VIDEO'), findsOneWidget);
    expect(find.text('AUDIO'), findsOneWidget);
  });

  testWidgets('HistoryScreen renders the empty state', (t) async {
    await t.pumpWidget(_app(
      const HistoryScreen(),
      overrides: [historyListProvider.overrideWith((ref) async => [])],
    ));
    await t.pumpAndSettle();

    expect(find.text('No downloads yet'), findsOneWidget);
  });
}
