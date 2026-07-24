import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_sheet.dart';
import '../widgets/woofer_mark.dart';

/// App & developer info — identity, Koulei Labs, contact links, legal. Static
/// brand content from the design handoff (THEME.md → App identity).
Future<void> showAboutSheet(BuildContext context) {
  return GlassSheet.present<void>(context, builder: (_) => const _AboutSheet());
}

Future<void> _open(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: SheetGrabber()),
            const SizedBox(height: AppSpacing.md),

            // Identity.
            const Center(
              child: Column(
                children: [
                  WooferMark(size: 84, tile: WooferTile.accent, bars: WooferBars.light),
                  SizedBox(height: AppSpacing.sm + 4),
                  _Wordmark(fontSize: 30),
                  SizedBox(height: 4),
                  Text('Version 1.0 (build 118) · made quiet',
                      style: TextStyle(fontSize: AppType.meta, color: AppColors.n400)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _SectionLabel('Developer'),
            const SizedBox(height: AppSpacing.sm),
            const _SoftRow(
              icon: CupertinoIcons.chevron_left_slash_chevron_right,
              title: 'Koulei Labs',
              subtitle: 'Independent studio · Est. 2025',
            ),
            const SizedBox(height: AppSpacing.lg),

            _SectionLabel('Contact'),
            const SizedBox(height: AppSpacing.sm),
            _LinkRow(
              icon: CupertinoIcons.mail,
              title: 'Email',
              subtitle: 'hello@woofer.app',
              onTap: () => _open('mailto:hello@woofer.app'),
            ),
            const SizedBox(height: 6),
            _LinkRow(
              icon: CupertinoIcons.globe,
              title: 'Website',
              subtitle: 'woofer.app',
              onTap: () => _open('https://woofer.app'),
            ),
            const SizedBox(height: 6),
            _LinkRow(
              icon: CupertinoIcons.at,
              title: 'Follow',
              subtitle: '@wooferapp',
              onTap: () => _open('https://x.com/wooferapp'),
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                Expanded(child: _LegalButton(label: 'Privacy', onTap: () => _open('https://woofer.app/privacy'))),
                const SizedBox(width: 6),
                Expanded(child: _LegalButton(label: 'Terms', onTap: () => _open('https://woofer.app/terms'))),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '© 2026 Koulei Labs. Not affiliated with any content platform.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: AppType.label, color: AppColors.n500),
            ),
          ],
        ),
      ),
    );
  }
}

/// "WOOFER." with the accent-colored period.
class _Wordmark extends StatelessWidget {
  final double fontSize;
  const _Wordmark({required this.fontSize});

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02 * fontSize,
            color: AppColors.text,
          ),
          children: const [
            TextSpan(text: 'WOOFER'),
            TextSpan(text: '.', style: TextStyle(color: AppColors.a300)),
          ],
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontSize: AppType.label,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
                color: AppColors.n500)),
      );
}

class _SoftRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SoftRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CupertinoColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: AppGlass.hairline(0.10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 23, color: AppColors.a200),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: AppType.bodyStrong,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: AppType.meta, color: AppColors.n400)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 23, color: AppColors.a200),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: AppType.bodyStrong,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(fontSize: AppType.meta, color: AppColors.n400)),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.arrow_up_right, size: 18, color: AppColors.n500),
            ],
          ),
        ),
      );
}

class _LegalButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LegalButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CupertinoColors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(13),
            border: AppGlass.hairline(0.10),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: AppType.body,
                  fontWeight: FontWeight.w600,
                  color: AppColors.n200)),
        ),
      );
}
