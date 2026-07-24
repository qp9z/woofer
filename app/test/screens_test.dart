import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/models/media_format.dart';
import 'package:woofer/models/video_info.dart';
import 'package:woofer/state/download_controller.dart';
import 'package:woofer/ui/screens/library_tab.dart';
import 'package:woofer/ui/sheets/format_sheet.dart';
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
  testWidgets('format sheet lists real formats with an Audio/Video toggle', (t) async {
    await t.pumpWidget(_app(
      Consumer(
        builder: (context, ref, _) => CupertinoButton(
          onPressed: () => showFormatSheet(context, ref, _info),
          child: const Text('open'),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pump(); // start the sheet route
    await t.pump(const Duration(milliseconds: 400)); // slide it in

    expect(find.text('A Very Good Clip'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
    // Video is the default kind; its row and the confirm label reflect it.
    expect(find.text('1080p · MP4'), findsOneWidget);
    expect(find.text('Download · 1080p · MP4'), findsOneWidget);
    // Note: don't pumpAndSettle — the confirm button's sheen loops forever.
  });

  testWidgets('Library tab renders the empty state', (t) async {
    await t.pumpWidget(_app(
      const LibraryTab(),
      overrides: [historyListProvider.overrideWith((ref) async => [])],
    ));
    await t.pumpAndSettle();

    expect(find.text('Nothing here yet.'), findsOneWidget);
  });
}
