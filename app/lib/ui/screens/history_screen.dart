import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/history_service.dart';
import '../../state/download_controller.dart';
import '../format_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_list_tile.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_sheet.dart';

/// Past downloads, newest first. Tap to open; ellipsis for share/delete.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(historyListProvider);

    return GlassScaffold(
      title: 'History',
      trailing: entries.valueOrNull?.isNotEmpty == true
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () => _confirmClear(context, ref),
              child: const Icon(CupertinoIcons.delete, size: 20),
            )
          : null,
      children: [
        entries.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xxl),
            child: Center(child: CupertinoActivityIndicator()),
          ),
          error: (e, _) => GlassContainer(
            child: Text('Could not load history.\n$e'),
          ),
          data: (rows) => rows.isEmpty
              ? const _EmptyState()
              : GlassListSection(
                  tiles: [
                    for (final entry in rows)
                      GlassListTile(
                        leading: _Thumb(url: entry.thumbnail),
                        title: Text(
                          entry.title ?? 'Untitled',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_meta(entry)),
                        trailing: _MoreButton(entry: entry),
                        onTap: () => ref
                            .read(storageServiceProvider)
                            .openFile(entry.filePath),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  static String _meta(HistoryEntry e) => [
        if (e.format != null && e.format!.isNotEmpty) e.format!,
        formatBytes(e.size),
        formatDate(e.createdAt),
      ].join(' · ');

  static Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This only removes the list. Your files stay in Downloads.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final history = await ref.read(historyServiceProvider.future);
    await history.clear();
    ref.invalidate(historyListProvider);
  }
}

/// Ellipsis -> frosted action sheet (open / share / delete).
class _MoreButton extends ConsumerWidget {
  final HistoryEntry entry;
  const _MoreButton({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: () => _openActions(context, ref),
      child: Icon(
        CupertinoIcons.ellipsis_circle,
        size: 22,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    );
  }

  Future<void> _openActions(BuildContext context, WidgetRef ref) async {
    final storage = ref.read(storageServiceProvider);

    await GlassSheet.show<void>(
      context,
      title: entry.title ?? 'Download',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassButton(
            expand: true,
            enableBlur: false, // the sheet already provides the blur
            icon: CupertinoIcons.folder_open,
            onPressed: () {
              Navigator.pop(sheetContext);
              storage.openFile(entry.filePath);
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
              storage.shareFile(entry.filePath);
            },
            child: const Text('Share'),
          ),
          const SizedBox(height: AppSpacing.sm),
          GlassButton(
            expand: true,
            enableBlur: false,
            // [FINE-TUNE] destructive tint strength
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
            child: const Text('Remove from history'),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? url;
  const _Thumb({this.url});

  // [FINE-TUNE] history thumbnail size
  static const double _w = 56;
  static const double _h = 40;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: _w,
      height: _h,
      color: CupertinoColors.white.withValues(alpha: 0.10),
      alignment: Alignment.center,
      child: Icon(
        CupertinoIcons.play_rectangle,
        size: 18,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => GlassContainer(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.tray,
              size: 44,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            Text(
              'No downloads yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Anything you download will show up here.',
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
