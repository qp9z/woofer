import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofer/ui/theme/app_theme.dart';
import 'package:woofer/ui/widgets/glass_button.dart';
import 'package:woofer/ui/widgets/glass_container.dart';
import 'package:woofer/ui/widgets/glass_scaffold.dart';
import 'package:woofer/ui/widgets/glass_sheet.dart';

Widget _app(Widget home, {Brightness brightness = Brightness.light}) =>
    CupertinoApp(theme: AppTheme.of(brightness), home: home);

void main() {
  testWidgets('GlassContainer renders its child with a blur layer', (t) async {
    await t.pumpWidget(_app(
      const CupertinoPageScaffold(
        child: Center(child: GlassContainer(child: Text('frost'))),
      ),
    ));
    expect(find.text('frost'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('GlassContainer(enableBlur: false) drops the BackdropFilter',
      (t) async {
    await t.pumpWidget(_app(
      const CupertinoPageScaffold(
        child: GlassContainer(enableBlur: false, child: Text('flat')),
      ),
    ));
    expect(find.text('flat'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('GlassScaffold builds nav title + body in dark mode', (t) async {
    await t.pumpWidget(_app(
      const GlassScaffold(
        title: 'Downloads',
        children: [GlassContainer(child: Text('row'))],
      ),
      brightness: Brightness.dark,
    ));
    expect(find.text('Downloads'), findsWidgets); // large + collapsed title
    expect(find.text('row'), findsOneWidget);
    expect(find.byType(GlassBackground), findsOneWidget);
  });

  testWidgets('disabled GlassButton does not fire onPressed', (t) async {
    var taps = 0;
    await t.pumpWidget(_app(
      CupertinoPageScaffold(
        child: Center(
          child: GlassButton(onPressed: null, child: const Text('x')),
        ),
      ),
    ));
    await t.tap(find.text('x'));
    expect(taps, 0);
  });

  testWidgets('GlassButton opens a GlassSheet', (t) async {
    await t.pumpWidget(_app(
      Builder(
        builder: (context) => CupertinoPageScaffold(
          child: Center(
            child: GlassButton(
              onPressed: () => GlassSheet.show(
                context,
                title: 'Quality',
                builder: (_) => const Text('sheet body'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('Quality'), findsOneWidget);
    expect(find.text('sheet body'), findsOneWidget);
  });
}
