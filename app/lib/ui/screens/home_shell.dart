import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/download_controller.dart';
import '../../state/download_state.dart';
import '../sheets/format_sheet.dart';
import '../theme/app_theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/woofer_mark.dart';
import 'download_tab.dart';
import 'library_tab.dart';
import 'settings_tab.dart';

/// The app shell: drifting aurora canvas, three tabs behind a floating nav pill,
/// and a toast. Watches the download flow to open the format sheet when a link
/// resolves and to confirm a save.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

enum _Tab { download, library, settings }

class _HomeShellState extends ConsumerState<HomeShell> {
  _Tab _tab = _Tab.download;
  String? _toast;
  Timer? _toastTimer;
  bool _sheetOpen = false;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showToast(String msg) {
    _toastTimer?.cancel();
    setState(() => _toast = msg);
    _toastTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _openFormatSheet() async {
    final state = ref.read(downloadControllerProvider);
    if (state is! FormatsReady || _sheetOpen) return;
    _sheetOpen = true;
    await showFormatSheet(context, ref, state.info);
    _sheetOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    // Link resolved -> open the format sheet (after this frame, not mid-build).
    ref.listen<DownloadState>(downloadControllerProvider, (prev, next) {
      if (next is FormatsReady && prev is! FormatsReady) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _openFormatSheet());
      } else if (next is Done && prev is! Done) {
        _showToast('Saved to your phone.');
        ref.read(downloadControllerProvider.notifier).reset();
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: AppColors.ground,
      child: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  if (_tab != _Tab.download) _Header(tab: _tab, onGear: () => _select(_Tab.settings)),
                  Expanded(
                    child: IndexedStack(
                      index: _tab.index,
                      children: const [DownloadTab(), LibraryTab(), SettingsTab()],
                    ),
                  ),
                ],
              ),
              if (_toast != null)
                Positioned(left: 20, right: 20, bottom: 104, child: _Toast(message: _toast!)),
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Center(child: _NavPill(current: _tab, onSelect: _select)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _select(_Tab t) => setState(() => _tab = t);
}

/// Header for the non-home tabs: mark + uppercase title + gear.
class _Header extends StatelessWidget {
  final _Tab tab;
  final VoidCallback onGear;
  const _Header({required this.tab, required this.onGear});

  @override
  Widget build(BuildContext context) {
    final title = tab == _Tab.library ? 'Library' : 'Settings';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        children: [
          const WooferMark(size: 30, tile: WooferTile.accent, bars: WooferBars.light),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: AppType.header,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.text,
            ),
          ),
          const Spacer(),
          if (tab != _Tab.settings)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onGear,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(CupertinoIcons.gear_alt, size: 26, color: AppColors.n400),
              ),
            ),
        ],
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  final String message;
  const _Toast({required this.message});

  @override
  Widget build(BuildContext context) {
    return _FadeIn(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2036).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: AppGlass.hairline(0.16),
          boxShadow: AppGlass.softShadow(Brightness.dark),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.check_mark_circled, size: 22, color: AppColors.a200),
            const SizedBox(width: 11),
            Expanded(
              child: Text(message,
                  style: const TextStyle(fontSize: AppType.body, color: AppColors.text)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating iOS-26 nav pill: three glass tabs; the active one expands into a
/// filled gradient capsule with its label.
class _NavPill extends StatelessWidget {
  final _Tab current;
  final ValueChanged<_Tab> onSelect;
  const _NavPill({required this.current, required this.onSelect});

  static const _defs = [
    (_Tab.download, 'Download', CupertinoIcons.arrow_down_circle),
    (_Tab.library, 'Library', CupertinoIcons.list_bullet),
    (_Tab.settings, 'Settings', CupertinoIcons.gear_alt),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E34).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.navPill),
        border: AppGlass.hairline(0.16),
        boxShadow: AppGlass.softShadow(Brightness.dark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (tab, label, icon) in _defs)
            _NavItem(
              label: label,
              icon: icon,
              active: current == tab,
              onTap: () => onSelect(tab),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accentInk : AppColors.textDim;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: active
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFC3BAFF), AppColors.a500])
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            if (active) ...[
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: AppType.body,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      color: color)),
            ],
          ],
        ),
      ),
    );
  }
}

class _FadeIn extends StatefulWidget {
  final Widget child;
  const _FadeIn({required this.child});

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 260))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _c,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut)),
          child: widget.child,
        ),
      );
}
