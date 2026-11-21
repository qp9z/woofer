import 'package:flutter/cupertino.dart';

import '../motion.dart';
import '../sheets/about_sheet.dart';
import '../theme/app_theme.dart';
import '../widgets/info_button.dart';
import '../widgets/tap_target.dart';
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
                            InfoButton(onTap: () => showAboutSheet(context)),
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
              onTap: () => showAboutSheet(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        // Only the mark is dimmed: dimming the text too took it to 2.8:1.
        Column(
          children: const [
            Opacity(
              opacity: 0.6,
              child: WooferMark(size: 34, tile: WooferTile.dark, bars: WooferBars.accent),
            ),
            SizedBox(height: 10),
            Text('Woofer 1.0 · made quiet',
                style: TextStyle(fontSize: AppType.label, color: AppColors.n500)),
          ],
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
  final String? value; // null: nothing to report (About shows the live version itself)
  final VoidCallback? onTap;
  const _Row({required this.icon, required this.label, this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    // At large text the value would crowd the label out, so it moves underneath.
    final stacked = value != null && largeText(context);
    const valueStyle = TextStyle(
        fontSize: AppType.body, fontWeight: FontWeight.w600, color: AppColors.a300);
    final row = Padding(
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 23, color: AppColors.n300),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: AppType.bodyStrong, color: AppColors.text)),
                    if (stacked) Text(value!, style: valueStyle),
                  ],
                ),
              ),
              if (value != null && !stacked) Text(value!, style: valueStyle),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                const Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.n600),
              ],
            ],
          ),
        );
    // Informational rows read as one item ("Audio format, MP3 · 192 kbps"), not
    // as a button; only a row with an action is a TapTarget.
    return onTap == null
        ? MergeSemantics(child: row)
        : TapTarget(onTap: onTap, child: row);
  }
}
