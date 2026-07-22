import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_list_tile.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_sheet.dart';

/// Visual gallery of the glass UI kit. Flip the nav switch to check both
/// light and dark backgrounds. Pure UI — no app logic.
class GlassGalleryScreen extends StatefulWidget {
  const GlassGalleryScreen({super.key});

  @override
  State<GlassGalleryScreen> createState() => _GlassGalleryScreenState();
}

class _GlassGalleryScreenState extends State<GlassGalleryScreen> {
  Brightness _brightness = Brightness.dark;

  bool get _isDark => _brightness == Brightness.dark;

  void _toggle(bool dark) =>
      setState(() => _brightness = dark ? Brightness.dark : Brightness.light);

  @override
  Widget build(BuildContext context) {
    // Local theme override so the whole gallery adapts when toggled.
    return CupertinoTheme(
      data: AppTheme.of(_brightness),
      child: GlassScaffold(
        title: 'Glass Kit',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
                size: 18),
            const SizedBox(width: AppSpacing.sm),
            CupertinoSwitch(value: _isDark, onChanged: _toggle),
          ],
        ),
        children: [
          _section('GlassContainer'),
          const GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Frosted panel',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                SizedBox(height: AppSpacing.xs),
                Text('Blur, translucent tint, hairline border, soft shadow.',
                    style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
          _gap,

          _section('GlassButton'),
          GlassButton.primary(
            expand: true,
            icon: CupertinoIcons.cloud_download,
            onPressed: () {},
            child: const Text('Download'),
          ),
          _gap,
          Row(
            children: [
              GlassButton(
                icon: CupertinoIcons.share,
                onPressed: () {},
                child: const Text('Share'),
              ),
              const SizedBox(width: AppSpacing.md),
              const GlassButton(onPressed: null, child: Text('Disabled')),
            ],
          ),
          _gap,

          _section('GlassListTile · GlassListSection'),
          GlassListSection(
            tiles: [
              GlassListTile(
                leading: const Icon(CupertinoIcons.film),
                title: const Text('1080p · MP4'),
                subtitle: const Text('Video + audio · 48.2 MB'),
                onTap: () {},
              ),
              GlassListTile(
                leading: const Icon(CupertinoIcons.music_note),
                title: const Text('Audio only · MP3'),
                subtitle: const Text('192 kbps · 6.1 MB'),
                onTap: () {},
              ),
              GlassListTile(
                leading: const Icon(CupertinoIcons.settings),
                title: const Text('More formats'),
                onTap: () {},
              ),
            ],
          ),
          _gap,

          _section('GlassSheet'),
          GlassButton(
            expand: true,
            icon: CupertinoIcons.rectangle_stack,
            onPressed: () => _openSheet(context),
            child: const Text('Open sheet'),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _openSheet(BuildContext context) {
    GlassSheet.show(
      context,
      title: 'Choose quality',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassListSection(
            tiles: [
              GlassListTile(
                leading: const Icon(CupertinoIcons.film),
                title: const Text('1080p'),
                onTap: () => Navigator.pop(sheetContext),
              ),
              GlassListTile(
                leading: const Icon(CupertinoIcons.film),
                title: const Text('720p'),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GlassButton.primary(
            expand: true,
            onPressed: () => Navigator.pop(sheetContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  static const Widget _gap = SizedBox(height: AppSpacing.md);

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.md, 0, AppSpacing.sm),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      );
}
