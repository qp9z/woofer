import 'package:flutter/cupertino.dart';

import 'ui/gallery/glass_gallery.dart';
import 'ui/theme/app_theme.dart';

void main() => runApp(const WooferApp());

class WooferApp extends StatelessWidget {
  const WooferApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'woofer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.of(Brightness.dark),
      // Until real screens land, the app opens on the UI-kit gallery.
      home: const GlassGalleryScreen(),
    );
  }
}
