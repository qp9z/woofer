import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/media_format.dart';
import '../../models/video_info.dart';
import '../../state/download_controller.dart';
import '../../state/download_state.dart';
import '../format_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_list_tile.dart';
import '../widgets/glass_scaffold.dart';
import 'progress_screen.dart';

/// Pick a format. [info] is passed in rather than read from state so this
/// screen keeps rendering while the controller moves on to Downloading.
class FormatsScreen extends ConsumerWidget {
  final VideoInfo info;
  const FormatsScreen({super.key, required this.info});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(downloadControllerProvider);
    final selected = state is FormatsReady ? state.selected : null;

    // Download started -> slide to progress.
    ref.listen<DownloadState>(downloadControllerProvider, (prev, next) {
      if (next is Downloading && prev is! Downloading) {
        Navigator.of(context).push(
          CupertinoPageRoute(builder: (_) => const ProgressScreen()),
        );
      }
    });

    final formats = info.formats;

    return GlassScaffold(
      title: 'Formats',
      children: [
        _HeaderCard(info: info),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Text(
            '${formats.length} AVAILABLE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
        if (formats.isEmpty)
          const GlassContainer(
            child: Text('No downloadable formats were returned for this link.'),
          )
        else
          // One GlassContainer for the whole list: a single blur, not one per row.
          GlassListSection(
            tiles: [
              for (final f in formats)
                GlassListTile(
                  leading: Icon(
                    f.hasVideo ? CupertinoIcons.film : CupertinoIcons.music_note_2,
                    color: f == selected ? AppColors.accent.resolveFrom(context) : null,
                  ),
                  title: Text(_label(f)),
                  subtitle: Text(_subtitle(f)),
                  trailing: _Badges(format: f, selected: f == selected),
                  onTap: () {
                    final ctrl = ref.read(downloadControllerProvider.notifier);
                    ctrl.selectFormat(f);
                    ctrl.download();
                  },
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            'Tap a format to start downloading.',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ),
        ),
      ],
    );
  }

  static String _label(MediaFormat f) {
    final res = f.resolution ?? (f.hasVideo ? 'Video' : 'Audio');
    return f.ext == null ? res : '$res · ${f.ext!.toUpperCase()}';
  }

  static String _subtitle(MediaFormat f) {
    final parts = <String>[formatBytes(f.filesize)];
    if (f.note != null && f.note!.isNotEmpty) parts.add(f.note!);
    return parts.join(' · ');
  }
}

/// Thumbnail + title + uploader/duration.
class _HeaderCard extends StatelessWidget {
  final VideoInfo info;
  const _HeaderCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final duration = formatDuration(info.duration);
    final meta = [
      if (info.uploader != null && info.uploader!.isNotEmpty) info.uploader!,
      if (duration.isNotEmpty) duration,
    ].join(' · ');

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumbnail(url: info.thumbnail),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  info.title ?? 'Untitled',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  // [FINE-TUNE] title size / line height
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    letterSpacing: -0.3,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs + 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? url;
  const _Thumbnail({this.url});

  // [FINE-TUNE] thumbnail size / aspect
  static const double _w = 108;
  static const double _h = 68;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: _w,
      height: _h,
      color: CupertinoColors.white.withValues(alpha: 0.10),
      alignment: Alignment.center,
      child: Icon(
        CupertinoIcons.play_rectangle,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: url == null
          ? placeholder
          : Image.network(
              url!,
              width: _w,
              height: _h,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
              loadingBuilder: (ctx, child, progress) =>
                  progress == null ? child : placeholder,
            ),
    );
  }
}

/// video/audio capability chips + a check on the selected row.
class _Badges extends StatelessWidget {
  final MediaFormat format;
  final bool selected;
  const _Badges({required this.format, required this.selected});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent.resolveFrom(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (format.hasVideo) const _Chip(label: 'VIDEO'),
        if (format.hasVideo && format.hasAudio) const SizedBox(width: AppSpacing.xs),
        if (format.hasAudio) const _Chip(label: 'AUDIO'),
        const SizedBox(width: AppSpacing.sm),
        Icon(
          selected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.chevron_right,
          size: selected ? 20 : 16,
          color: selected ? accent : CupertinoColors.tertiaryLabel.resolveFrom(context),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        // [FINE-TUNE] chip fill / border opacity
        color: CupertinoColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CupertinoColors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }
}
