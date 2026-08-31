import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/history_service.dart';
import '../../state/download_controller.dart';
import '../format_utils.dart';
import '../sheets/about_sheet.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_sheet.dart';
import '../widgets/wordmark.dart';

enum _LibFilter { all, audio, video }

/// Library tab: completed downloads with All/Audio/Video filter chips. Tap a row
/// to open; long-press for share/remove.
class LibraryTab extends ConsumerStatefulWidget {
  const LibraryTab({super.key});

  @override
  ConsumerState<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends ConsumerState<LibraryTab> {
  _LibFilter _filter = _LibFilter.all;

  bool _matches(HistoryEntry e) => switch (_filter) {
        _LibFilter.all => true,
        _LibFilter.video => formatIsVideo(e.format),
        _LibFilter.audio => !formatIsVideo(e.format),
      };

  @override
    Widget build(BuildContext context) {
      final entries = ref.watch(historyListProvider);

      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        physics: const BouncingScrollPhysics(),
        children: [
                  // Title row matching DownloadTab.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Wordmark(fontSize: AppType.display, height: 0.95),
                        ),
                      ),
                      _InfoCircle(onTap: () => showAboutSheet(context)),
                    ],
                  ),
          const SizedBox(height: AppSpacing.md),
          Row(
          children: [
            for (final f in _LibFilter.values) ...[
              _Chip(
                label: switch (f) {
                  _LibFilter.all => 'All',
                  _LibFilter.audio => 'Audio',
                  _LibFilter.video => 'Video',
                },
                active: _filter == f,
                onTap: () => setState(() => _filter = f),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        entries.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xxl),
            child: Center(child: CupertinoActivityIndicator()),
          ),
          error: (e, _) => Text('Could not load your library.\n$e',
              style: const TextStyle(color: AppColors.n400)),
          data: (rows) {
            final filtered = rows.where(_matches).toList();
            if (filtered.isEmpty) return const _Empty();
            return Column(
              children: [
                for (final entry in filtered)
                  _LibraryRow(
                    entry: entry,
                    onTap: () => _open(context, ref, entry),
                    onActions: () => _openActions(context, ref, entry),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Hand the saved uri to the system viewer, and say so when nothing can open
  /// it — a row whose file the user deleted from Downloads lands here, and a
  /// tap that does nothing at all reads as a broken app.
  static Future<void> _open(BuildContext context, WidgetRef ref, HistoryEntry entry) => _guard(
        context,
        ref.read(storageServiceProvider).openFile(entry.filePath),
        "Couldn't open this file. It may have been moved or deleted.",
      );

  static Future<void> _guard(BuildContext context, Future<bool> action, String failure) async {
    if (await action) return;
    if (!context.mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: Text(failure),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(c), child: const Text('OK')),
        ],
      ),
    );
  }

  static Future<void> _openActions(BuildContext context, WidgetRef ref, HistoryEntry entry) {
    final storage = ref.read(storageServiceProvider);
    return GlassSheet.show<void>(
      context,
      title: entry.title ?? 'Download',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassButton(
            expand: true,
            enableBlur: false,
            icon: CupertinoIcons.folder_open,
            onPressed: () {
              Navigator.pop(sheetContext);
              _open(context, ref, entry);
            },
            child: const Text('Open'),
          ),
          const SizedBox(height: AppSpacing.sm),
          GlassButton(
            expand: true,
            enableBlur: false,
            icon: CupertinoIcons.share,
            onPressed: () {
              Navigator.pop(sheetContext);
              _guard(context, storage.shareFile(entry.filePath), "Couldn't share this file.");
            },
            child: const Text('Share'),
          ),
          const SizedBox(height: AppSpacing.sm),
          GlassButton(
            expand: true,
            enableBlur: false,
            tint: CupertinoColors.systemRed.resolveFrom(context).withValues(alpha: 0.18),
            icon: CupertinoIcons.delete,
            onPressed: () async {
              Navigator.pop(sheetContext);
              final id = entry.id;
              if (id == null) return;
              final history = await ref.read(historyServiceProvider.future);
              await history.delete(id);
              ref.invalidate(historyListProvider);
            },
            child: const Text('Remove from library'),
          ),
        ],
      ),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onActions;
  const _LibraryRow({required this.entry, required this.onTap, required this.onActions});

  @override
  Widget build(BuildContext context) {
    final video = formatIsVideo(entry.format);
    final meta = [
      if (entry.format != null && entry.format!.isNotEmpty) entry.format!,
      formatBytes(entry.size),
      formatDate(entry.createdAt),
    ].join(' · ');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onActions,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2F3350), Color(0xFF20223A)],
                ),
              ),
              child: Icon(video ? CupertinoIcons.film : CupertinoIcons.waveform,
                  size: 24, color: AppColors.a300),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.title ?? 'Untitled',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: AppType.bodyStrong,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text)),
                  const SizedBox(height: 2),
                  Text(meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: AppType.meta, color: AppColors.n500)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onActions,
              child: const Padding(
                padding: EdgeInsets.all(6),
                // Not a play button: it opens the Open/Share/Remove sheet. A play
                // glyph here promised playback and delivered a menu.
                child: Icon(CupertinoIcons.ellipsis_circle, size: 28, color: AppColors.n400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: active ? AppColors.a500.withValues(alpha: 0.16) : null,
            border: Border.all(color: active ? AppColors.a500 : AppColors.n800),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: AppType.body,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.a300 : AppColors.n500)),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(
          child: Text('Nothing here yet.',
              style: TextStyle(fontSize: AppType.body, color: AppColors.n500)),
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
