import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/download_controller.dart';
import '../../state/download_state.dart';
import '../format_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_scaffold.dart';

/// Live download progress, then the success / failure outcome.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(downloadControllerProvider);

    return GlassScaffold(
      title: 'Downloading',
      children: [
        const SizedBox(height: AppSpacing.sm),
        // Cross-fade between phases instead of a hard swap — iOS-subtle.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          child: switch (state) {
            Downloading() => _ProgressCard(key: const ValueKey('busy'), state: state),
            // Merging / transcoding after the bytes are down.
            Processing() => _ProcessingCard(key: const ValueKey('processing'), state: state),
            Done() => _DoneCard(key: const ValueKey('done'), state: state),
            Failed() => _FailedCard(key: const ValueKey('failed'), state: state),
            // Cancelled: the controller has fallen back to format selection.
            _ => const _IdleCard(key: ValueKey('idle')),
          },
        ),
      ],
    );
  }
}

class _ProgressCard extends ConsumerWidget {
  final Downloading state;
  const _ProgressCard({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = state.progress;
    final pct = progress == null ? null : (progress * 100).clamp(0, 100).toStringAsFixed(0);

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  state.format.resolution ?? (state.format.hasVideo ? 'Video' : 'Audio'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
              if (pct != null)
                Text(
                  '$pct%',
                  // [FINE-TUNE] percentage type scale
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    height: 1,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                )
              else
                const CupertinoActivityIndicator(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Bar(progress: progress),
          const SizedBox(height: AppSpacing.sm + 4),
          Text(
            state.total > 0
                ? '${formatBytes(state.received)} of ${formatBytes(state.total)}'
                : '${formatBytes(state.received)} downloaded',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassButton(
            expand: true,
            enableBlur: false, // inside a glass card already — one blur is enough
            icon: CupertinoIcons.xmark,
            onPressed: () {
              ref.read(downloadControllerProvider.notifier).cancel();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Merge / transcode phase: no percentage from ffmpeg, so a spinner + label.
class _ProcessingCard extends StatelessWidget {
  final Processing state;
  const _ProcessingCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) => GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(radius: 15),
            const SizedBox(height: AppSpacing.md),
            Text(
              state.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              'Almost done — finishing on your device',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      );
}

/// Capsule progress bar. Indeterminate (null) renders as a dim track — the
/// spinner above carries the "working" signal.
class _Bar extends StatelessWidget {
  final double? progress;
  const _Bar({required this.progress});

  @override
  Widget build(BuildContext context) {
    const height = 10.0; // [FINE-TUNE] bar thickness
    final radius = BorderRadius.circular(height / 2);

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: CupertinoColors.white.withValues(alpha: 0.18),
                borderRadius: radius,
              ),
            ),
          ),
          if (progress != null)
            LayoutBuilder(
              builder: (_, constraints) => AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                width: constraints.maxWidth * progress!.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  // [FINE-TUNE] progress gradient
                  gradient: LinearGradient(
                    colors: [AppColors.accent.resolveFrom(context), AppColors.blobB],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DoneCard extends ConsumerWidget {
  final Done state;
  const _DoneCard({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final green = CupertinoColors.systemGreen.resolveFrom(context);
    final target = state.uri ?? state.path;
    final storage = ref.read(storageServiceProvider);

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.checkmark_circle_fill, size: 56, color: green),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Saved to Downloads',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            state.path,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  enableBlur: false,
                  icon: CupertinoIcons.folder_open,
                  onPressed: () => storage.openFile(target),
                  child: const Text('Open'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: GlassButton(
                  enableBlur: false,
                  icon: CupertinoIcons.share,
                  onPressed: () => storage.shareFile(target),
                  child: const Text('Share'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          GlassButton.primary(
            expand: true,
            enableBlur: false,
            onPressed: () {
              ref.read(downloadControllerProvider.notifier).reset();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _FailedCard extends ConsumerWidget {
  final Failed state;
  const _FailedCard({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final red = CupertinoColors.systemRed.resolveFrom(context);

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 52, color: red),
          const SizedBox(height: AppSpacing.md),
          Text(
            describeError(state.code),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            state.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassButton.primary(
            expand: true,
            enableBlur: false,
            icon: CupertinoIcons.arrow_counterclockwise,
            onPressed: () {
              // Back to the format list; the picked format is still selected.
              ref.read(downloadControllerProvider.notifier).download();
            },
            child: const Text('Try again'),
          ),
          const SizedBox(height: AppSpacing.sm),
          CupertinoButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Choose another format'),
          ),
        ],
      ),
    );
  }
}

/// Reached after a cancel: the controller is back on format selection.
class _IdleCard extends StatelessWidget {
  const _IdleCard({super.key});

  @override
  Widget build(BuildContext context) => GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.stop_circle,
              size: 44,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            Text(
              'Download cancelled',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ],
        ),
      );
}
