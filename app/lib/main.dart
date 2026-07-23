import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/screens/home_screen.dart';
import 'ui/theme/app_theme.dart';

void main() => runApp(const ProviderScope(child: WooferApp()));

class WooferApp extends StatelessWidget {
  const WooferApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'WOOFER.',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.of(Brightness.dark),
      home: const HomeScreen(),
    );
  }
}
