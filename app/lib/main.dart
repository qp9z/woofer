import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/screens/home_shell.dart';
import 'ui/screens/splash_screen.dart';
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
      home: const _Boot(),
    );
  }
}

/// Holds the animated splash briefly, then cross-fades into the shell.
class _Boot extends StatefulWidget {
  const _Boot();

  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  bool _ready = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen.hold, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        child: _ready ? const HomeShell() : const SplashScreen(),
      );
}
