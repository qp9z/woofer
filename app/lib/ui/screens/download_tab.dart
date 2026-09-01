import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show Clipboard;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/video_info.dart';
import '../../state/download_controller.dart';
import '../../state/download_state.dart';
import '../../state/share_intent.dart';
import '../format_utils.dart';
import '../sheets/about_sheet.dart';
import '../sheets/format_sheet.dart';
import '../theme/app_theme.dart';
import '../widgets/fetch_button.dart';
import '../widgets/wordmark.dart';

/// The Download (home) tab: paste/share a link, Fetch, then pick a format in the
/// sheet. Shows the detected-media card, live download progress, and errors.
class DownloadTab extends ConsumerStatefulWidget {
  const DownloadTab({super.key});

  @override
  ConsumerState<DownloadTab> createState() => _DownloadTabState();
}

class _DownloadTabState extends ConsumerState<DownloadTab> {
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
      setState(() {}); // reveal the clear button / accent border
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(downloadControllerProvider);

    // A shared link mirrors into the field so it can be edited/re-fetched.
    ref.listen(sharedUrlProvider, (_, next) {
      final url = next.valueOrNull;
      if (url != null) {
        _url.text = url;
        setState(() {});
      }
    });

    final loading = state is Loading;
    final busy = loading || state is Downloading || state is Processing;
    final hasText = _url.text.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        4,
        20,
        100,
      ), // clear the floating nav pill
      physics: const BouncingScrollPhysics(),
      children: [
              // Title row.
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

        const _CaptionLabel('Video link'),
        const SizedBox(height: 10),
        _UrlField(
          controller: _url,
          active: hasText,
          onChanged: () => setState(() {}),
          onPaste: _paste,
          onClear: () {
            _url.clear();
            setState(() {});
          },
          onSubmit: _fetch,
        ),
        const SizedBox(height: 10),
        FetchButton(
          label: 'Fetch',
          icon: CupertinoIcons.arrow_down_circle,
          loading: loading,
          onPressed: busy ? null : _fetch,
        ),

        // Detected media (formats resolved, sheet may be closed).
        if (state is FormatsReady) ...[
          const SizedBox(height: AppSpacing.md),
          _DetectedCard(
            info: state.info,
            sourceUrl: _url.text,
            onOptions: () => showFormatSheet(context, ref, state.info),
          ),
        ],

        // Active download.
        if (state is Downloading || state is Processing) ...[
          const SizedBox(height: AppSpacing.lg),
          const _CaptionLabel('Now downloading', dim: true),
          const SizedBox(height: AppSpacing.sm),
          _ActiveCard(state: state),
        ],

        // Error.
        if (state is Failed) ...[
          const SizedBox(height: AppSpacing.md),
          _ErrorCard(
            state: state,
            onRetry: () =>
                ref.read(downloadControllerProvider.notifier).retry(),
          ),
        ],

        // Empty hint.
        if (state is Idle && !hasText) ...[
          const SizedBox(height: AppSpacing.md),
          const _Hint(),
        ],
      ],
    );
  }
}

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

/// Uppercase section label with letter-spacing (VIDEO LINK / NOW DOWNLOADING).
class _CaptionLabel extends StatelessWidget {
  final String text;
  final bool dim;
  const _CaptionLabel(this.text, {this.dim = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: AppType.label,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.0,
        color: dim ? AppColors.n500 : AppColors.n400,
      ),
    ),
  );
}

/// Frosted URL input: text field + clear (when non-empty) + inline Paste. The
/// border warms to accent once there's text.
class _UrlField extends StatelessWidget {
  final TextEditingController controller;
  final bool active;
  final VoidCallback onChanged;
  final VoidCallback onPaste;
  final VoidCallback onClear;
  final VoidCallback onSubmit;
  const _UrlField({
    required this.controller,
    required this.active,
    required this.onChanged,
    required this.onPaste,
    required this.onClear,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 5, 5, 5),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: active ? AppColors.a500 : AppColors.n800,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: 'https://…',
              keyboardType: TextInputType.url,
              autocorrect: false,
              textInputAction: TextInputAction.go,
              onChanged: (_) => onChanged(),
              onSubmitted: (_) => onSubmit(),
              maxLines: 1,
              decoration: const BoxDecoration(),
              padding: const EdgeInsets.symmetric(vertical: 13),
              style: const TextStyle(
                fontSize: AppType.body,
                color: AppColors.text,
              ),
              placeholderStyle: const TextStyle(
                fontSize: AppType.body,
                color: AppColors.n600,
              ),
            ),
          ),
          if (active)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClear,
              child: const Padding(
                // Padded out to a comfortable tap target around a small glyph.
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Icon(
                  CupertinoIcons.clear_circled_solid,
                  size: 20,
                  color: AppColors.n400,
                ),
              ),
            ),
          const SizedBox(width: 2),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPaste,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: CupertinoColors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: AppGlass.hairline(0.10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    CupertinoIcons.doc_on_clipboard,
                    size: 18,
                    color: AppColors.a200,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Paste',
                    style: TextStyle(
                      fontSize: AppType.body,
                      fontWeight: FontWeight.w600,
                      color: AppColors.a200,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-thumbnail detected-media card: 16:9 preview with source badge, duration,
/// play glyph, then title/meta + Options (reopens the format sheet).
class _DetectedCard extends StatelessWidget {
  final VideoInfo info;
  final String sourceUrl;
  final VoidCallback onOptions;
  const _DetectedCard({
    required this.info,
    required this.sourceUrl,
    required this.onOptions,
  });

  bool get _hasVideo => info.formats.any((f) => f.hasVideo);

  @override
  Widget build(BuildContext context) {
    final duration = formatDuration(info.duration);
    final meta =
        _sourceLabel(sourceUrl) + (duration.isEmpty ? '' : ' · $duration');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOptions,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: AppGlass.hairline(0.10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Thumb(url: info.thumbnail, hasVideo: _hasVideo),
                  // Source badge.
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _Badge(
                      child: Text(
                        _sourceLabel(sourceUrl),
                        style: const TextStyle(
                          fontSize: AppType.label,
                          fontWeight: FontWeight.w600,
                          color: AppColors.a200,
                        ),
                      ),
                    ),
                  ),
                  // Duration.
                  if (duration.isNotEmpty)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF060710,
                          ).withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          duration,
                          style: const TextStyle(
                            fontSize: AppType.label,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                    ),
                  // Play.
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CupertinoColors.white.withValues(alpha: 0.12),
                        border: AppGlass.hairline(0.16),
                      ),
                      child: const Icon(
                        CupertinoIcons.play_fill,
                        size: 17,
                        color: AppColors.a200,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          info.title ?? 'Detected media',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: AppType.bodyStrong,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: AppType.meta,
                            color: AppColors.n400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(13),
                      border: AppGlass.hairline(0.10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          CupertinoIcons.slider_horizontal_3,
                          size: 18,
                          color: AppColors.a200,
                        ),
                        SizedBox(width: 7),
                        Text(
                          'Options',
                          style: TextStyle(
                            fontSize: AppType.body,
                            fontWeight: FontWeight.w600,
                            color: AppColors.a200,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _sourceLabel(String url) {
    try {
      final host = Uri.parse(url.trim()).host;
      if (host.isEmpty) return 'Link';
      return host.startsWith('www.') ? host.substring(4) : host;
    } catch (_) {
      return 'Link';
    }
  }
}

class _Thumb extends StatelessWidget {
  final String? url;
  final bool hasVideo;
  const _Thumb({required this.url, required this.hasVideo});

  @override
  Widget build(BuildContext context) {
    final placeholder = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF343961), Color(0xFF20223A)],
        ),
      ),
      child: Center(
        child: Icon(
          hasVideo ? CupertinoIcons.film : CupertinoIcons.waveform,
          size: 46,
          color: AppColors.a300.withValues(alpha: 0.4),
        ),
      ),
    );
    if (url == null) return placeholder;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (ctx, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}

class _Badge extends StatelessWidget {
  final Widget child;
  const _Badge({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: CupertinoColors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(9),
      border: AppGlass.hairline(0.16),
    ),
    child: child,
  );
}

/// Live download / processing card with progress bar and cancel.
class _ActiveCard extends ConsumerWidget {
  final DownloadState state;
  const _ActiveCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (title, icon, progress, status) = switch (state) {
      Downloading d => (
        formatLabel(d.format),
        d.format.hasVideo ? CupertinoIcons.film : CupertinoIcons.waveform,
        d.progress,
        d.total > 0
            ? '${((d.progress ?? 0) * 100).toStringAsFixed(0)}% · ${formatBytes(d.received)} of ${formatBytes(d.total)}'
            : '${formatBytes(d.received)} downloaded',
      ),
      Processing p => (
        formatLabel(p.format),
        p.format.hasVideo ? CupertinoIcons.film : CupertinoIcons.waveform,
        null,
        p.label,
      ),
      _ => ('', CupertinoIcons.waveform, null, ''),
    };

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: AppGlass.hairline(0.10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.a200),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppType.body,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    ref.read(downloadControllerProvider.notifier).cancel(),
                child: const Padding(
                  padding: EdgeInsets.only(left: 12, top: 4, bottom: 4),
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 20,
                    color: AppColors.n400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ProgressBar(progress: progress),
          const SizedBox(height: 9),
          Text(
            status,
            style: const TextStyle(
              fontSize: AppType.label,
              color: AppColors.n400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double? progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: CupertinoColors.white.withValues(alpha: 0.14),
              ),
            ),
            if (progress != null)
              LayoutBuilder(
                builder: (_, c) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: c.maxWidth * progress!.clamp(0.0, 1.0),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFC3BAFF), AppColors.a500],
                    ),
                  ),
                ),
              )
            else
              const _IndeterminateStripe(),
          ],
        ),
      ),
    );
  }
}

/// A gently pulsing bar for the indeterminate (processing) phase.
class _IndeterminateStripe extends StatefulWidget {
  const _IndeterminateStripe();

  @override
  State<_IndeterminateStripe> createState() => _IndeterminateStripeState();
}

class _IndeterminateStripeState extends State<_IndeterminateStripe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.4, end: 1.0).animate(_c),
    child: const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFC3BAFF), AppColors.a500]),
      ),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final Failed state;
  final VoidCallback onRetry;
  const _ErrorCard({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final red = CupertinoColors.systemRed.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: red.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.exclamationmark_triangle, size: 22, color: red),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  describeError(state.code),
                  style: const TextStyle(
                    fontSize: AppType.bodyStrong,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.message,
                  style: const TextStyle(
                    fontSize: AppType.meta,
                    height: 1.35,
                    color: AppColors.n400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRetry,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Text(
                'Try again',
                style: TextStyle(
                  fontSize: AppType.body,
                  fontWeight: FontWeight.w600,
                  color: red,
                ),
              ),
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
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Tip: share a link straight from YouTube and Woofer will pick it up.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: AppType.meta,
          height: 1.5,
          color: AppColors.n500,
        ),
      ),
    ),
  );
}
