import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show Clipboard;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/download_controller.dart';
import '../../state/download_state.dart';
import '../../state/share_intent.dart';
import '../format_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_scaffold.dart';
import 'formats_screen.dart';
import 'history_screen.dart';

/// Entry point: paste (or share in) a link, then Fetch.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _url = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _fetch() {
    final url = _url.text.trim();
    if (url.isEmpty) return;
    FocusScope.of(context).unfocus();
    ref.read(downloadControllerProvider.notifier).extract(url);
  }

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _url.text = text;
      _url.selection = TextSelection.collapsed(offset: text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(downloadControllerProvider);
    // Errors here are non-fatal (e.g. no share plugin on a test host).
    final sharedUrl = ref.watch(sharedUrlProvider).valueOrNull;

    // A shared link mirrors into the field so it can be edited/re-fetched.
    ref.listen(sharedUrlProvider, (_, next) {
      final url = next.valueOrNull;
      if (url != null) _url.text = url;
    });

    // Formats resolved -> slide to the picker (standard iOS push).
    ref.listen<DownloadState>(downloadControllerProvider, (prev, next) {
      if (next is FormatsReady && prev is! FormatsReady) {
        Navigator.of(context).push(
          CupertinoPageRoute(builder: (_) => FormatsScreen(info: next.info)),
        );
      }
    });

    final loading = state is Loading;

    return GlassScaffold(
      title: 'Downloader',
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: () => Navigator.of(context).push(
          CupertinoPageRoute(builder: (_) => const HistoryScreen()),
        ),
        child: const Icon(CupertinoIcons.clock, size: 22),
      ),
      children: [
        const SizedBox(height: AppSpacing.sm),
        _Caption('Video link'),
        const SizedBox(height: AppSpacing.sm),
        _UrlField(controller: _url, onPaste: _paste, onSubmit: _fetch),
        const SizedBox(height: AppSpacing.md),
        GlassButton.primary(
          expand: true,
          icon: loading ? null : CupertinoIcons.arrow_down_circle,
          onPressed: loading ? null : _fetch,
          child: loading
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : const Text('Fetch'),
        ),
        if (sharedUrl != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _SharedBanner(url: sharedUrl),
        ],
        if (state is Failed) ...[
          const SizedBox(height: AppSpacing.lg),
          _ErrorCard(state: state),
        ],
        const SizedBox(height: AppSpacing.xxl),
        const _Hint(),
      ],
    );
  }
}

/// Uppercase section label, iOS grouped-list style.
class _Caption extends StatelessWidget {
  final String text;
  const _Caption(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: AppSpacing.xs),
        child: Text(
          text.toUpperCase(),
          // [FINE-TUNE] caption size/tracking
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      );
}

/// Frosted text field + inline paste button. The button is a plain
/// CupertinoButton, not a GlassButton — nesting blurs inside the field's
/// glass would cost a second BackdropFilter for no visual gain.
class _UrlField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPaste;
  final VoidCallback onSubmit;
  const _UrlField({required this.controller, required this.onPaste, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      // [FINE-TUNE] field padding / height
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.sm, AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: 'https://…',
              keyboardType: TextInputType.url,
              autocorrect: false,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => onSubmit(),
              maxLines: 1,
              // Strip the field's own chrome; the glass panel is the chrome.
              decoration: const BoxDecoration(),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 4),
              style: TextStyle(
                fontSize: 17,
                letterSpacing: -0.2,
                color: CupertinoColors.label.resolveFrom(context),
              ),
              placeholderStyle: TextStyle(
                fontSize: 17,
                letterSpacing: -0.2,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            minimumSize: Size.zero,
            onPressed: onPaste,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.doc_on_clipboard,
                    size: 17, color: AppColors.accent.resolveFrom(context)),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Paste',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the app was opened from another app's share sheet.
class _SharedBanner extends StatelessWidget {
  final String url;
  const _SharedBanner({required this.url});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent.resolveFrom(context);
    return GlassContainer(
      // [FINE-TUNE] accent tint strength for the shared-link banner
      tint: accent.withValues(alpha: 0.16),
      child: Row(
        children: [
          Icon(CupertinoIcons.square_arrow_down, size: 20, color: accent),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Shared with woofer',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    letterSpacing: -0.2,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline error panel for a failed extract.
class _ErrorCard extends StatelessWidget {
  final Failed state;
  const _ErrorCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final red = CupertinoColors.systemRed.resolveFrom(context);
    return GlassContainer(
      // [FINE-TUNE] error tint
      tint: red.withValues(alpha: 0.14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.exclamationmark_triangle, size: 20, color: red),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  describeError(state.code),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          'Tip: share a link straight from YouTube\nand woofer will pick it up.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
          ),
        ),
      );
}
