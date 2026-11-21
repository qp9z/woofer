import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/models/media_format.dart';
import 'package:woofer/models/video_info.dart';
import 'package:woofer/state/download_controller.dart';
import 'package:woofer/state/download_state.dart';
import 'package:woofer/state/share_intent.dart';
import 'package:woofer/ui/screens/home_shell.dart';
import 'package:woofer/ui/screens/library_tab.dart';
import 'package:woofer/ui/sheets/format_sheet.dart';
import 'package:woofer/ui/theme/app_theme.dart';

Widget _app(Widget home, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: CupertinoApp(theme: AppTheme.of(Brightness.dark), home: home),
    );

const _info = VideoInfo(
  title: 'A Very Good Clip',
  uploader: 'Someone',
  duration: 187,
  formats: [
    MediaFormat(
      formatId: '18',
      ext: 'mp4',
      resolution: '360p',
      filesize: 2 * 1024 * 1024,
      hasAudio: true,
      hasVideo: true,
    ),
    MediaFormat(
      formatId: '137',
      ext: 'mp4',
      resolution: '1080p',
      filesize: 5 * 1024 * 1024,
      hasAudio: false,
      hasVideo: true,
    ),
    MediaFormat(formatId: '140', ext: 'm4a', hasAudio: true, hasVideo: false),
  ],
);

class _RecordingDownloadController extends DownloadController {
  bool downloadCalled = false;

  @override
  DownloadState build() => const FormatsReady(_info);

  @override
  Future<void> download() async {
    downloadCalled = true;
  }
}

void main() {
  testWidgets('format sheet lists real formats with an Audio/Video toggle', (
    t,
  ) async {
    await t.pumpWidget(
      _app(
        Consumer(
          builder: (context, ref, _) => CupertinoButton(
            onPressed: () => showFormatSheet(context, ref, _info),
            child: const Text('open'),
          ),
        ),
      ),
    );
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

  testWidgets('untouched Download confirms the advertised best video', (
    t,
  ) async {
    late _RecordingDownloadController controller;
    await t.pumpWidget(
      _app(
        Consumer(
          builder: (context, ref, _) {
            controller =
                ref.read(downloadControllerProvider.notifier)
                    as _RecordingDownloadController;
            return CupertinoButton(
              onPressed: () => showFormatSheet(context, ref, _info),
              child: const Text('open default test'),
            );
          },
        ),
        overrides: [
          downloadControllerProvider.overrideWith(
            _RecordingDownloadController.new,
          ),
        ],
      ),
    );
    await t.tap(find.text('open default test'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));

    expect(find.text('Download · 1080p · MP4'), findsOneWidget);
    await t.tap(find.text('Download · 1080p · MP4'));
    await t.pump();

    final state = controller.state as FormatsReady;
    expect(state.selected?.formatId, '137');
    expect(controller.downloadCalled, isTrue);
  });

  testWidgets('Library tab renders the empty state', (t) async {
    await t.pumpWidget(
      _app(
        const LibraryTab(),
        overrides: [historyListProvider.overrideWith((ref) async => [])],
      ),
    );
    await t.pumpAndSettle();

    expect(find.text('Nothing here yet.'), findsOneWidget);
  });

  // Riverpod 3 pauses listeners of offstage widgets. The Download tab sits in an
  // IndexedStack, so a link shared while Library is showing must still be routed:
  // the shell keeps the subscription alive and brings Download forward.
  testWidgets('a link shared while another tab is showing lands on Download', (
    t,
  ) async {
    final shares = StreamController<String>();
    addTearDown(shares.close);
    await t.pumpWidget(
      _app(
        const HomeShell(),
        overrides: [
          historyListProvider.overrideWith((ref) async => []),
          sharedUrlProvider.overrideWith((ref) => shares.stream),
        ],
      ),
    );
    await t.pump();

    // Library in front: Download is now offstage.
    await t.tap(find.byIcon(CupertinoIcons.list_bullet));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Nothing here yet.'), findsOneWidget);
    expect(find.text('VIDEO LINK'), findsNothing);

    shares.add('https://youtu.be/abc123');
    // Fixed pumps: the aurora animates forever, so pumpAndSettle would hang.
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Nothing here yet.'), findsNothing);
    expect(find.text('VIDEO LINK'), findsOneWidget);
    expect(
      find.widgetWithText(CupertinoTextField, 'https://youtu.be/abc123'),
      findsOneWidget,
    );
  });
}
