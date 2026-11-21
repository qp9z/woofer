import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:woofer/ui/screens/settings_tab.dart';

import 'support/app_harness.dart';

// PackageInfo.setMockInitialValues sets a process-wide singleton, so the test
// that uses it stays LAST: anything after it would see the mocked version.
void main() {
  testWidgets('Settings states where files go and what "best" means', (t) async {
    await pumpApp(t, const SettingsTab());

    expect(find.text('Downloads/woofer'), findsOneWidget);
    expect(find.text('Save location'), findsOneWidget);
    expect(
      find.textContaining('Every download starts on the best quality available'),
      findsOneWidget,
    );
    expect(find.textContaining('Audio-only picks are saved as MP3'), findsOneWidget);
    // Informational rows only: nothing here pretends to be a preference.
    expect(find.byIcon(CupertinoIcons.chevron_right), findsOneWidget); // About
  });

  testWidgets('the footer shows no version when it cannot be read', (t) async {
    await pumpApp(t, const SettingsTab());

    expect(find.text('Woofer · made quiet'), findsOneWidget);
    // The old footer hardcoded "Woofer 1.0"; no number may appear unless it was
    // really read from the installed package.
    expect(find.textContaining(RegExp(r'\d+\.\d+')), findsNothing);
  });

  testWidgets('the footer shows the installed version, not a hardcoded one', (
    t,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: 'Woofer',
      packageName: 'dev.koulei.woofer',
      version: '9.8.7',
      buildNumber: '3',
      buildSignature: '',
    );
    await pumpApp(t, const SettingsTab());

    expect(find.text('Woofer 9.8.7 · made quiet'), findsOneWidget);
  });
}
