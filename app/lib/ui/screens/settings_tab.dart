import 'package:flutter/cupertino.dart';

import '../sheets/about_sheet.dart';
import '../theme/app_theme.dart';
import '../widgets/woofer_mark.dart';
import '../widgets/wordmark.dart';

/// Settings tab. Informational rows reflecting the app's real behaviour — the
/// downloader has no preferences store yet, so these show the fixed defaults
/// (audio transcodes to MP3 192k, files land in Downloads, dark theme).
// ponytail: static values, honest to what the app does. Wire real preferences
// when a settings store exists — don't fake toggles that do nothing.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      physics: const BouncingScrollPhysics(),
      children: [
              // Title row matching DownloadTab.
              Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(
                              child: Wordmark(fontSize: AppType.display, height: 0.95),
                            ),
                            _InfoCircle(onTap: () => showAboutSheet(context)),
                          ],
                        ),
        const SizedBox(height: AppSpacing.md),
        _Group(
          name: 'Downloads',
          rows: [
            _Row(icon: CupertinoIcons.music_note_2, label: 'Audio format', value: 'MP3 · 192 kbps'),
            _Row(icon: CupertinoIcons.film, label: 'Video quality', value: 'Best available'),
            _Row(icon: CupertinoIcons.folder, label: 'Save location', value: 'Downloads'),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _Group(
          name: 'App',
          rows: [
            _Row(icon: CupertinoIcons.moon, label: 'Theme', value: 'Dark'),
            _Row(
              icon: CupertinoIcons.info_circle,
              label: 'About Woofer',
              value: 'v1.0',
              onTap: () => showAboutSheet(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Opacity(
          opacity: 0.6,
          child: Column(
            children: const [
              WooferMark(size: 34, tile: WooferTile.dark, bars: WooferBars.accent),
              SizedBox(height: 10),
              Text('Woofer 1.0 · made quiet',
                  style: TextStyle(fontSize: AppType.label, color: AppColors.n500)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  final String name;
  final List<_Row> rows;
  const _Group({required this.name, required this.rows});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.sm),
            child: Text(name.toUpperCase(),
                style: const TextStyle(
                    fontSize: AppType.label,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: AppColors.n500)),
          ),
          ...rows,
        ],
      );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _Row({required this.icon, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 23, color: AppColors.n300),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(fontSize: AppType.bodyStrong, color: AppColors.text))),
              Text(value,
                  style: const TextStyle(
                      fontSize: AppType.body,
                      fontWeight: FontWeight.w600,
                      color: AppColors.a300)),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                const Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.n600),
              ],
            ],
          ),
        ),
      );
}

/// Copied from DownloadTab for consistent header.
class _InfoCircle extends StatelessWidget {
  final VoidCallback onTap;
  const _InfoCircle({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: AppTouch.min,
          height: AppTouch.min,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CupertinoColors.white.withValues(alpha: 0.05),
            border: AppGlass.hairline(0.10),
          ),
          child: const Icon(CupertinoIcons.info, size: 24, color: AppColors.a200),
        ),
      );
}
