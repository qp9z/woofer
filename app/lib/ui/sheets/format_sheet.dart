import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/media_format.dart';
import '../../models/media_format_order.dart';
import '../../models/video_info.dart';
import '../../state/download_controller.dart';
import '../format_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/fetch_button.dart';
import '../widgets/glass_sheet.dart';

/// Present the format/quality picker for [info]. Audio/Video segmented toggle,
/// the real extracted formats as selectable rows, and a Download confirm.
/// On confirm it selects the format and kicks off the download, then closes.
Future<void> showFormatSheet(
  BuildContext context,
  WidgetRef ref,
  VideoInfo info,
) {
  return GlassSheet.present<void>(
    context,
    builder: (_) => _FormatSheet(info: info, ref: ref),
  );
}

class _FormatSheet extends StatefulWidget {
  final VideoInfo info;
  final WidgetRef ref;
  const _FormatSheet({required this.info, required this.ref});

  @override
  State<_FormatSheet> createState() => _FormatSheetState();
}

class _FormatSheetState extends State<_FormatSheet> {
  late List<MediaFormat> _video;
  late List<MediaFormat> _audio;
  late bool _isVideo;
  MediaFormat? _selected;

  @override
  void initState() {
    super.initState();
    final formats = widget.info.formats;
    _video = orderVideoFormats(formats.where((f) => f.hasVideo));
    _audio = orderAudioFormats(formats.where((f) => f.hasAudio && !f.hasVideo));
    _isVideo = _video.isNotEmpty;
    _selected = _defaultForCurrentKind();
  }

  List<MediaFormat> get _list => _isVideo ? _video : _audio;

  MediaFormat? _defaultForCurrentKind() =>
      chooseDefaultFormat(_list, video: _isVideo);

  void _setKind(bool video) {
    if (_isVideo == video) return;
    setState(() {
      _isVideo = video;
      _selected = _defaultForCurrentKind();
    });
  }

  void _confirm() {
    final fmt = _selected;
    if (fmt == null) return;
    final ctrl = widget.ref.read(downloadControllerProvider.notifier);
    ctrl.selectFormat(fmt);
    ctrl.download();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final meta = [
      if (info.uploader != null && info.uploader!.isNotEmpty) info.uploader!,
      if (formatDuration(info.duration).isNotEmpty)
        formatDuration(info.duration),
    ].join(' · ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: SheetGrabber()),
        const SizedBox(height: AppSpacing.md),

        // Media header.
        Row(
          children: [
            _IconSquare(
              icon: _isVideo
                  ? CupertinoIcons.film
                  : CupertinoIcons.music_note_2,
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    info.title ?? 'Untitled',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppType.title,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
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
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  CupertinoIcons.xmark,
                  size: 22,
                  color: AppColors.n300,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Audio / Video segmented toggle.
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: CupertinoColors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: AppGlass.hairline(0.10),
          ),
          child: Row(
            children: [
              Expanded(
                child: _KindChip(
                  icon: CupertinoIcons.waveform,
                  label: 'Audio',
                  active: !_isVideo,
                  enabled: _audio.isNotEmpty,
                  onTap: () => _setKind(false),
                ),
              ),
              Expanded(
                child: _KindChip(
                  icon: CupertinoIcons.film,
                  label: 'Video',
                  active: _isVideo,
                  enabled: _video.isNotEmpty,
                  onTap: () => _setKind(true),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Quality list.
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'AVAILABLE QUALITIES',
            style: TextStyle(
              fontSize: AppType.label,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: AppColors.n500,
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 300,
          ), // taller rows need more room
          child: _list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    'No formats of this type were found.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppType.body,
                      color: AppColors.n500,
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final f = _list[i];
                    return _QualityRow(
                      label: formatLabel(f),
                      meta: formatSubtitle(f),
                      selected: f == _selected,
                      onTap: () => setState(() => _selected = f),
                    );
                  },
                ),
        ),
        const SizedBox(height: AppSpacing.md),

        FetchButton(
          label: _selected == null
              ? 'Download'
              : 'Download · ${formatLabel(_selected!)}',
          icon: CupertinoIcons.cloud_download,
          onPressed: _selected == null ? null : _confirm,
        ),
      ],
    );
  }
}

class _IconSquare extends StatelessWidget {
  final IconData icon;
  const _IconSquare({required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: CupertinoColors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: AppGlass.hairline(0.10),
    ),
    child: Icon(icon, size: 25, color: AppColors.a200),
  );
}

class _KindChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;
  const _KindChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.accentInk
        : (enabled ? AppColors.n300 : AppColors.n700);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: active
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFC3BAFF), AppColors.a500],
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                fontSize: AppType.bodyStrong,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QualityRow extends StatelessWidget {
  final String label;
  final String meta;
  final bool selected;
  final VoidCallback onTap;
  const _QualityRow({
    required this.label,
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          color: selected
              ? AppColors.a500.withValues(alpha: 0.16)
              : CupertinoColors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: selected
                ? AppColors.a400.withValues(alpha: 0.6)
                : CupertinoColors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: AppType.bodyStrong,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: const TextStyle(
                      fontSize: AppType.meta,
                      color: AppColors.n400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              size: 24,
              color: selected
                  ? AppColors.a400
                  : CupertinoColors.white.withValues(alpha: 0.22),
            ),
          ],
        ),
      ),
    );
  }
}
