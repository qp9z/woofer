import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/services/api_exception.dart';
import 'package:woofer/state/download_state.dart';
import 'package:woofer/ui/screens/home_shell.dart';

import 'support/app_harness.dart';

/// Every screen has to survive the worst case a real phone can produce: the
/// narrowest common width, landscape, and Android's largest font size (200%).
/// A RenderFlex overflow fails the test on its own; takeException catches the
/// rest.
typedef _Scenario = (String, Future<void> Function(WidgetTester t, Size size));

Future<void> _shell(WidgetTester t, Size size) async {
  await pumpApp(t, const HomeShell(), history: sampleEntries, size: size);
}

final _scenarios = <_Scenario>[
  ('Download, idle', (t, s) => _shell(t, s)),
  ('Library', (t, s) async {
    await _shell(t, s);
    await t.tap(find.byIcon(CupertinoIcons.list_bullet));
    await t.pumpAndSettle();
  }),
  ('Settings', (t, s) async {
    await _shell(t, s);
    await t.tap(find.byIcon(CupertinoIcons.gear_alt));
    await t.pumpAndSettle();
  }),
  for (final (name, state) in <(String, DownloadState)>[
    ('downloading', const Downloading(format: sampleMp4, received: 5, total: 10)),
    ('downloading, size unknown', const Downloading(format: sampleMp4, received: 5, total: -1)),
    ('processing', const Processing(sampleMp4, 'Merging video and audio…')),
    ('formats ready', const FormatsReady(sampleInfo)),
    ('failed', const Failed(ApiErrorCode.network, 'No connection. Check your network and try again.')),
  ])
    ('Download, $name', (t, s) async {
      await pumpApp(
        t,
        const HomeShell(),
        overrides: [downloadState(state)],
        size: s,
      );
    }),
  ('format sheet', (t, s) async {
    await pumpApp(
      t,
      const HomeShell(),
      overrides: [downloadState(const FormatsReady(sampleInfo))],
      size: s,
    );
    await t.ensureVisible(find.text('Options'));
    await t.tap(find.text('Options'));
    await t.pumpAndSettle();
  }),
  ('About sheet', (t, s) async {
    await _shell(t, s);
    await t.tap(find.bySemanticsLabel('About Woofer'));
    await t.pumpAndSettle();
  }),
  ('Library actions sheet', (t, s) async {
    await _shell(t, s);
    await t.tap(find.byIcon(CupertinoIcons.list_bullet));
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('More actions for First Clip'));
    await t.pumpAndSettle();
  }),
];

void main() {
  const sizes = <String, Size>{
    'narrow 320x568': Size(320, 568),
    'landscape 800x360': Size(800, 360),
  };

  for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
    for (final scale in const [1.0, 2.0]) {
      for (final (name, body) in _scenarios) {
        testWidgets('$name fits at $sizeName, text ×$scale', (t) async {
          t.platformDispatcher.textScaleFactorTestValue = scale;
          // No explicit assertion: flutter_test fails the test on any uncaught
          // framework error (a RenderFlex overflow) and prints the widget chain.
          await body(t, size);
        });
      }
    }
  }

  // TapTarget loosens its child's constraints; the Audio/Video pill must still
  // fill its half of the toggle instead of shrinking to its label.
  testWidgets('the Audio/Video pills fill their halves of the toggle', (t) async {
    await pumpApp(
      t,
      const HomeShell(),
      overrides: [downloadState(const FormatsReady(sampleInfo))],
    );
    await t.tap(find.text('Options'));
    await t.pumpAndSettle();
    final pill = find.ancestor(
      of: find.text('Video'),
      matching: find.byType(AnimatedContainer),
    );
    // 412 wide, minus sheet padding and the toggle's own: roughly 170 per half.
    expect(t.getSize(pill).width, greaterThan(150));
  });
}
