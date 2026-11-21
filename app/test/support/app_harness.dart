import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/models/media_format.dart';
import 'package:woofer/models/video_info.dart';
import 'package:woofer/services/history_service.dart';
import 'package:woofer/state/download_controller.dart';
import 'package:woofer/state/download_state.dart';
import 'package:woofer/state/share_intent.dart';
import 'package:woofer/ui/theme/app_theme.dart';

/// Pump [home] inside the app theme with the providers that would otherwise hit
/// sqflite / the platform. With [reduce] (default) the system "Remove
/// animations" setting is on, so the aurora, sheen and stripe freeze and
/// `pumpAndSettle` is safe; pass `reduce: false` to keep the loops running.
Future<void> pumpApp(
  WidgetTester t,
  Widget home, {
  List<Override> overrides = const [],
  List<HistoryEntry> history = const [],
  bool reduce = true,
  Size size = const Size(412, 892), // a phone, not flutter_test's 800x600
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  if (reduce) {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  }
  addTearDown(t.platformDispatcher.clearAllTestValues);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        historyListProvider.overrideWith((ref) async => history),
        sharedUrlProvider.overrideWith((ref) => const Stream.empty()),
        ...overrides,
      ],
      child: CupertinoApp(theme: AppTheme.of(Brightness.dark), home: home),
    ),
  );
  if (reduce) {
    await t.pumpAndSettle();
  } else {
    await t.pump();
  }
}

/// A controller pinned to one state, so a screen can be shown mid-download.
class FixedDownload extends DownloadController {
  FixedDownload(this.s);
  final DownloadState s;
  @override
  DownloadState build() => s;
}

const sampleMp4 = MediaFormat(
  formatId: '137',
  ext: 'mp4',
  resolution: '1080p',
  hasAudio: false,
  hasVideo: true,
);

const sampleInfo = VideoInfo(
  title: 'A Very Good Clip',
  uploader: 'Someone',
  duration: 187,
  formats: [
    sampleMp4,
    MediaFormat(formatId: '140', ext: 'm4a', hasAudio: true, hasVideo: false),
  ],
);

final sampleEntries = [
  HistoryEntry(
    id: 1,
    title: 'First Clip',
    sourceUrl: 'https://youtu.be/a',
    filePath: 'content://media/1',
    format: '1920x1080',
    size: 1 << 20,
  ),
  HistoryEntry(
    id: 2,
    title: 'Second Clip',
    sourceUrl: 'https://youtu.be/b',
    filePath: 'content://media/2',
    format: 'medium',
    size: 1 << 19,
  ),
];

Override downloadState(DownloadState s) =>
    downloadControllerProvider.overrideWith(() => FixedDownload(s));
