# P3 plan: WOOFER product & UX (accessibility, history v2, stale entries, settings copy, loading/cancel UX)

## Context

P3 in `PROJECT_TODO.md` has six items. I read every screen, widget and service they touch. These are the findings, all confirmed in code on `main` @ `00c0fb7`:

- **Accessibility: there is no `Semantics` and no reduced-motion handling anywhere in `lib/`.**
  - Icon-only gesture controls have no label: the ⓘ About button (copied three times as `_InfoCircle`), inactive nav tabs, the URL clear ✕, the Cancel ✕, the Library ⋯ button and the format-sheet close ✕.
  - Tap targets under 44 px:

    | Control | Size |
    |---|---|
    | Cancel ✕ | ≈32×28 |
    | Library ⋯ | 40 |
    | Format-sheet ✕ | 38 |
    | URL clear | 40 |
    | Paste | ≈42 |
    | "Try again" | ≈40 |
    | Library filter chips | ≈42 |

  - Four infinite animations ignore the system "Remove animations" setting: the aurora (14 s), the Fetch sheen (3.4 s), the equalizer mark on the splash (1.1 s) and the indeterminate progress stripe.
- **Text scaling (computed, not yet observed):** at 200% text size on a 320 px-wide phone, the three Library filter chips (~390 px) can't fit in one row (~280 px).
- **Contrast** (WCAG AA = 4.5, computed against the real surfaces):
  - Every text token passes on the app's surfaces except `n600`, used for the URL placeholder (3.0–3.5).
  - The Settings footer text is dimmed by `Opacity(0.6)` down to 2.8.
  - Over the brightest point of the drifting aurora blobs, every token drops. That is the brand design and stays (documented, not changed).
- **History:** it stores only a display label (`format`), and audio vs video is guessed from it by regex (`formatIsVideo`). The MIME type, file extension and yt-dlp format id are never stored, so open/share always passes `*/*`. The schema is version 1 with no `onUpgrade`.
- **Stale entries:** opening a deleted file shows "Couldn't open…" with only an OK button. You can't remove the stale row from there, there's no clear-library action, and "Remove from library" never says whether the file gets deleted.
- **Settings:**
  - "Video quality: Best available" doesn't say you can pick per download.
  - "Save location: Downloads" is imprecise (it's `Download/woofer`).
  - The footer hardcodes "Woofer 1.0", a second version string that drifts.
- **Loading and cancel UX:**
  - While a download runs, Fetch is just greyed out, with no reason given.
  - A link shared while busy is dropped silently.
  - Cancelling returns to `FormatsReady`, and `HomeShell` then **re-opens the format sheet**: the user cancels and a sheet pops up.
  - Unknown-size downloads say only "12 MB downloaded".
- **Visual QA on a real device** needs the phone, which is still unauthorized in ADB. It stays open as a manual checklist.

**Outcome:** every P3 item done and tested except the device-only QA. The changes are mechanical and verifiable by tests, and no design tokens are invented.

## Decisions baked in

- **"Remove from library" never deletes the file.** The library is an index. Deleting a MediaStore item on API 30+ needs a system consent dialog, and the user may have moved the file. Every removal message says the file stays in Downloads.
- **Full system text scaling is supported, up to 200% (Android's max), with no clamping.** Overflows get fixed in the layout. Fonts are never shrunk.
- **Contrast fixes use existing tokens only:** placeholder `n600`→`n500`, and the footer text loses its `Opacity`. The aurora blobs are left untouched.
- **Reduced motion means "freeze on a rest frame".** No new animations are added.
- **No new dependencies.**

## Rules for the executor (Sonnet, medium effort): read before starting

1. **Branch:** `git checkout main`, `git pull`, then `git checkout -b p3-ux`. Make **one local commit per step** below, ending with the attribution line from the system reminder. **Do not push.** The user approves pushes.
2. **Before every commit, from `app/`:** `flutter analyze` must report "No issues" and `flutter test` must be all green. Run commands in the Bash tool (Git Bash).
3. **Never use `pumpAndSettle()`** unless the test turned on reduced motion (helper in Step 2). The aurora, sheen and stripe animate forever otherwise.
4. **Any test that shows a toast** must end with `await t.pump(const Duration(seconds: 3));`, or flutter_test fails on the toast's pending 2.6 s `Timer`.
5. **Design tokens only:** `AppColors`, `AppType`, `AppSpacing`, `AppRadius`, `AppTouch` in `lib/ui/theme/app_theme.dart`. No raw font sizes or colours in widgets.
6. **Every new tappable control uses `TapTarget`** (Step 1). Never a bare `GestureDetector`.
7. **Riverpod 3 pauses listeners of offstage widgets.** Any `ref.listen` that must always fire belongs in `HomeShell`, never in a tab. Read `YtdlpExtractor` only via `ytdlpExtractorProvider`.
8. **Mutation-check every guard test:** temporarily break the code it protects, see the test fail, then restore with `git checkout -- <file>` and confirm `git diff` is empty.
9. **If a step's test fails for a reason this plan didn't foresee,** fix the code, not the test assertion. If that's impossible, stop and report.

---

## Step 1: shared accessibility primitives

**New `lib/ui/motion.dart`:**
```dart
import 'package:flutter/widgets.dart';

/// True when the user turned on Android's "Remove animations" (MediaQuery
/// disableAnimations). Infinite decorative loops must freeze when this is set.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;
```

**New `lib/ui/widgets/tap_target.dart`.** It is the only way to make something tappable. It provides button semantics, a ≥44 px target (`AppTouch.min`), and an optional label for icon-only controls:
```dart
class TapTarget extends StatelessWidget {
  const TapTarget({super.key, required this.onTap, required this.child,
      this.label, this.selected, this.onLongPress, this.minSize = AppTouch.min});
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final String? label;      // REQUIRED for icon-only controls
  final bool? selected;     // chips / tabs / radio rows
  final double minSize;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: onTap != null,
        selected: selected,
        label: label,
        excludeSemantics: label != null, // a given label replaces child text
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
            child: Center(widthFactor: 1, heightFactor: 1, child: child),
          ),
        ),
      );
}
```

**New `lib/ui/widgets/info_button.dart`:** `InfoButton({required VoidCallback onTap})`. It has the exact visuals of today's `_InfoCircle` (44×44 circle, `AppGlass.hairline(0.10)`, `CupertinoIcons.info`) wrapped in `TapTarget(label: 'About Woofer')`.
- Delete the three private `_InfoCircle` classes in `download_tab.dart`, `library_tab.dart` and `settings_tab.dart`, and use `InfoButton`.

Commit: `a11y: TapTarget, reduceMotion and a shared InfoButton`.

## Step 2: reduced motion for the four infinite animations

The same pattern applies in each widget:
- create the controller **without** `..repeat()`;
- decide in `didChangeDependencies()`:
  ```dart
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
      _c.value = <rest>;
    } else if (!_c.isAnimating) {
      _c.repeat(/* same args as today */);
    }
  }
  ```

| Widget | File | Rest frame |
|---|---|---|
| `_AuroraBackgroundState` | `widgets/aurora_background.dart` | `0.0` |
| `_FetchButtonState._sheen` | `widgets/fetch_button.dart` | `1.0` (puts the sheen off-screen) |
| `_IndeterminateStripeState` | `screens/download_tab.dart` | `1.0` (solid bar); keep `repeat(reverse: true)` otherwise |
| `_WooferMarkState` | `widgets/woofer_mark.dart` | No controller at all (static painter) |

For `WooferMark`, compute `wantsMotion = widget.animated && !reduceMotion(context)` in `didChangeDependencies` **and** `didUpdateWidget`, then start or dispose the lazy controller. Move today's `initState` start into that logic (`initState` can't read `MediaQuery`).

**Test, new `test/accessibility_test.dart`.** It starts with a shared helper that later steps reuse:
```dart
Future<void> pumpApp(WidgetTester t, Widget home,
    {List<Override> overrides = const [], bool reduce = true}) async {
  if (reduce) {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  }
  addTearDown(t.platformDispatcher.clearAllTestValues);
  await t.pumpWidget(ProviderScope(
    overrides: [
      historyListProvider.overrideWith((ref) async => []),
      sharedUrlProvider.overrideWith((ref) => const Stream.empty()),
      ...overrides,
    ],
    child: CupertinoApp(theme: AppTheme.of(Brightness.dark), home: home),
  ));
  if (reduce) await t.pumpAndSettle(); else await t.pump();
}
```
- **"with Remove animations on, the whole shell settles":** `pumpApp(t, const HomeShell())` completes. `pumpAndSettle` would time out if any loop still ran.
- **Control, "without it, the shell keeps animating":** `pumpApp(t, const HomeShell(), reduce: false)`, then `expect(t.binding.hasScheduledFrame, isTrue)`.
- **"SplashScreen settles under reduced motion"** (it covers the equalizer).
- Mutation-check: re-add `..repeat()` to the aurora and the first test must time out.

Commit: `a11y: freeze infinite animations when Remove animations is on`.

## Step 3: labels and 44 px targets on every control

Replace each bare `GestureDetector` with `TapTarget`, keeping the existing visuals as the `child`:

| Control (file) | Label / selected |
|---|---|
| Nav items `_NavItem` (`home_shell.dart`) | `label: label`, `selected: active` |
| URL clear ✕ (`download_tab.dart`) | `'Clear link'` |
| Paste (`download_tab.dart`) | none (text "Paste"); target becomes ≥44 |
| `_DetectedCard` (`download_tab.dart`) | `'Choose a format'` |
| Cancel ✕ in `_ActiveCard` (`download_tab.dart`) | `'Cancel download'` |
| "Try again" in `_ErrorCard` (`download_tab.dart`) | none (text) |
| `_LibraryRow` (`library_tab.dart`): row tap + `onLongPress` | none (title text) |
| Library ⋯ button | `'More actions for ${entry.title ?? 'this download'}'` |
| `_Chip` filter (`library_tab.dart`) | `selected: active` |
| Format-sheet close ✕ (`format_sheet.dart`) | `'Close'` |
| `_KindChip` (`format_sheet.dart`) | `selected: active`; `onTap: enabled ? onTap : null` |
| `_QualityRow` (`format_sheet.dart`) | `selected: selected` |
| `_LinkRow`, `_LegalButton` (`about_sheet.dart`) | none (text) |
| Settings About row (`settings_tab.dart`) | none (text) |

Two more changes:
- `FetchButton` and `GlassButton` keep their own press animation. Only wrap their outer `GestureDetector` in `Semantics(button: true, enabled: _enabled, child: …)`.
- Settings **informational** rows (no `onTap`): wrap in `MergeSemantics` so TalkBack reads "Audio format, MP3 · 192 kbps" as one non-button item. Use `TapTarget` only for the About row.

**Tests, added to `test/accessibility_test.dart`.** Use `final handle = t.ensureSemantics();` and dispose it at the end. For each screen below, assert both `meetsGuideline(labeledTapTargetGuideline)` and `meetsGuideline(iOSTapTargetGuideline)`. The 44 px threshold matches `AppTouch.min`. Screens:
1. `HomeShell` on each tab (tap `find.byIcon(...)` of each nav icon, `pumpAndSettle`).
2. Library with two `HistoryEntry` rows (override `historyListProvider`).
3. Download in `Downloading(total: -1)`, `Processing`, `FormatsReady` (with `thumbnail: null`, which avoids `Image.network`) and `Failed`. Override the controller with:
   ```dart
   class _Fixed extends DownloadController {
     _Fixed(this.s);
     final DownloadState s;
     @override
     DownloadState build() => s;
   }
   // downloadControllerProvider.overrideWith(() => _Fixed(state))
   ```
4. The format sheet (tap the detected card).
5. The About sheet (tap `find.bySemanticsLabel('About Woofer')`).
6. The Library actions sheet (tap the ⋯).

Mutation-check: drop the Cancel ✕ label and `labeledTapTargetGuideline` must fail.

**Guideline hits you may see, and the only accepted fixes:**
- The URL `CupertinoTextField` has only a placeholder. If it's flagged, wrap it in `Semantics(label: 'Video link', child: …)`.
- A modal barrier: Flutter labels these itself. If one is flagged, stop and report; do not suppress it.
- Never weaken an assertion or exclude a screen to make a guideline pass.

Commit: `a11y: screen-reader labels and 44 px targets on every control`.

## Step 4: large text, narrow phones, landscape

**Test, new `test/layout_test.dart`, reusing `pumpApp`.** Generate one `testWidgets` per combination with nested `for` loops:
- sizes `Size(320, 568)` (narrow) and `Size(800, 360)` (landscape);
- text scale `1.0` and `2.0`;
- the same screens as Step 3.

Setup per test:
```dart
t.view.physicalSize = size;
t.view.devicePixelRatio = 1.0;
addTearDown(t.view.reset);
t.platformDispatcher.textScaleFactorTestValue = scale;
```
After pumping, assert `expect(t.takeException(), isNull)`. A RenderFlex overflow also fails the test by itself.

**Then fix every overflow the test reports:**
- **Known:** in `library_tab.dart`, replace the filter-chip `Row` with `Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [...])` and drop the manual `SizedBox` spacers.
- **For anything else, in order of preference:**
  1. wrap the text in `Flexible` / `Expanded` with `maxLines` and `overflow: TextOverflow.ellipsis`;
  2. let a `Row` become a `Wrap`;
  3. let content scroll.

  Never lower a font size or bypass `AppType`. Likely candidates: the `_KindChip` label (`Flexible` + ellipsis) and the Settings row value (`Flexible` + ellipsis, `textAlign: TextAlign.end`).

Commit: `a11y: layouts hold at 200% text, 320 px width and landscape`.

## Step 5: contrast

- `download_tab.dart` URL `placeholderStyle`: `AppColors.n600` → `AppColors.n500`.
- `settings_tab.dart` footer: move `Opacity(0.6)` so it wraps **only** the `WooferMark`, not the text.
- **New `test/contrast_test.dart`:** a ~15-line WCAG helper (sRGB → relative luminance → `(L1+0.05)/(L2+0.05)`).
  - Assert each body-text token (`text`, `textDim`, `n400`, `n500`, `a200`, `a300`) is ≥ 4.5 against `AppColors.auroraA` and against glass (5% white over `auroraA`).
  - Assert `n600` is < 4.5. The test documents why it must not be used for text.
  - **Do not** use flutter's `textContrastGuideline`: it samples pixels, and the drifting blobs make it non-deterministic.

Commit: `a11y: placeholder and footer text meet WCAG AA`.

## Step 6: history schema v2 (explicit kind, MIME, extension, format id)

**`lib/services/history_service.dart`:**
- Add `enum MediaKind { video, audio }`.
- Move the regex from `format_utils.formatIsVideo` here as a public `MediaKind kindFromLegacyLabel(String? label)`, using the same regex. Delete `formatIsVideo` from `format_utils.dart`, and move its test cases from `test/format_utils_test.dart` to `test/history_service_test.dart` (renamed). This keeps services from importing UI code.
- `HistoryEntry` gains `MediaKind kind`, `String? mimeType`, `String? ext` and `String? formatId`.
  - Constructor: `MediaKind? kind` with initializer `kind = kind ?? kindFromLegacyLabel(format)`. Existing call sites and tests keep compiling.
  - `toMap` / `fromMap` use columns `kind` (`kind.name`), `mime_type`, `ext`, `format_id`.
  - `fromMap`: `MediaKind.values.asNameMap()[m['kind']] ?? kindFromLegacyLabel(m['format'] as String?)`.
- `_createTableSql` adds `kind TEXT, mime_type TEXT, ext TEXT, format_id TEXT`.
- Add `static const int schemaVersion = 2;`. `open()` uses `version: schemaVersion`, `onCreate`, and `onUpgrade: (db, from, _) => migrate(db, from)`.
- `@visibleForTesting static Future<void> migrate(Database db, int from)`. If `from < 2`:
  - run `ALTER TABLE history ADD COLUMN …` for each of the 4 columns;
  - then backfill `kind` for every row from `kindFromLegacyLabel(format)`;
  - sqflite already wraps `onUpgrade` in a transaction.

**`lib/state/download_controller.dart`:**
- `_recordHistory(...)` gains `required String mime, required String ext`.
- It passes `kind: format.hasVideo ? MediaKind.video : MediaKind.audio`, `mimeType: mime`, `ext: ext` and `formatId: format.formatId`. The call site already has `mime` and `ext` in scope.

**`lib/ui/screens/library_tab.dart`:**
- The filter and the row icon use `entry.kind`.
- `openFile` / `shareFile` pass `mimeType: entry.mimeType ?? '*/*'`.

**Tests:**
- **history:** v2 fields round-trip. For a legacy row with no kind, a `'1920x1080'` label reads as video and `'medium'` as audio.
- **Migration:** create a **v1** database file in a temp directory with the exact old SQL (copy the v1 `CREATE TABLE` into the test), insert two rows and close it. Then `HistoryService.open(path)` must return rows with the backfilled `kind` and null `mimeType`/`ext`/`formatId`, and `PRAGMA user_version` must be 2.
- **Controller:** the muxed-MP4 test also asserts the recorded entry has `kind video`, `mimeType 'video/mp4'`, `ext 'mp4'` and `formatId '18'`. The audio test asserts `kind audio`, `'audio/mpeg'` and `'mp3'`.

Commit: `history: schema v2 with explicit kind, MIME, extension and format id`.

## Step 7: stale entries and clearing the library (files are never deleted)

**`library_tab.dart`:**
- `_guard` gains an optional `VoidCallback? onRemove`. When it's set, the failure dialog has two actions:
  - "Remove from library" (`isDestructiveAction: true`), which deletes the history row and invalidates `historyListProvider`;
  - "Keep".

  The dialog adds `content: Text('Removing only forgets it here — nothing else is deleted.')`.
  - Open and Share failures from a row pass `onRemove`.
- Extract the existing remove logic (`history.delete(id)` + `ref.invalidate(historyListProvider)`) into one `static Future<void> _remove(WidgetRef ref, HistoryEntry e)`, used by both the sheet and the dialog.
- The actions sheet's "Remove from library" button gets a line of text under it: **"Only removes it from this list — the file stays in Downloads."** (`AppType.meta`, `AppColors.n400`).
- **Clear library:** below the rows, only when there is at least one entry, add a centred `TapTarget` text "Clear library" (`CupertinoColors.systemRed`). It opens a `CupertinoAlertDialog`:
  - title **"Clear your library?"**;
  - content **"This removes all $n entries from Woofer. Your downloaded files stay in Downloads."**;
  - actions "Cancel" and "Clear" (`isDestructiveAction`), where Clear runs `history.clear()` (it already exists) and invalidates the list.

**Tests (`screens_test.dart`):**
- open fails → tap "Remove from library" → the row is gone (fake history list provider backed by a mutable list) and `storage.opened` was called;
- "Keep" leaves it;
- Clear library → confirm → empty state "Nothing here yet.";
- Clear → Cancel → rows stay;
- the Clear button is absent when the list is empty;
- **no code path calls a delete on storage.** `_OpenStorage` records any `openFile` call, and `StorageService` has no delete method. Assert the dialog copy contains "stay in Downloads".

Commit: `library: remove stale entries from the error dialog; clear library with confirmation`.

## Step 8: Settings copy matches real behaviour

**`settings_tab.dart`:**
- "Save location" value becomes **`Downloads/woofer`**.
- Under the Downloads group, add a footnote (`AppType.meta`, `AppColors.n400`, `height: 1.4`): **"Every download starts on the best quality available, marked Best in the format sheet — you can pick another there. Audio-only picks are saved as MP3."**
- Footer: convert `SettingsTab` to a `StatefulWidget` that caches `PackageInfo.fromPlatform()` in `initState`.
  - Render `FutureBuilder` text `'Woofer ${info.version} · made quiet'`, falling back to `'Woofer · made quiet'` on error or while loading.
  - The hardcoded "1.0" goes away.
- Rows stay non-interactive (no chevron, no `onTap`), per the TODO.

**`format_sheet.dart`:** `_QualityRow` gets `bool best`. It's true when `f == chooseDefaultFormat(_list, video: _isVideo)`; compute that once per build. When true, show a small pill **"Best"** after the label (`AppType.label`, w600, `AppColors.a300`, background `AppColors.a500.withValues(alpha: 0.16)`, radius `AppRadius.chip`).

**Tests:**
- Settings shows `Downloads/woofer` and the footnote;
- the footer shows `Woofer · made quiet` when PackageInfo is unavailable in tests;
- **no text matches `RegExp(r'\d+\.\d+')` in the footer;**
- the format sheet shows exactly one "Best", and it is on the top video row (1080p in `_info`).

Commit: `settings: copy matches real behaviour; Best is marked in the format sheet`.

## Step 9: loading and cancel UX

1. **Busy hint (`download_tab.dart`).** When `state is Downloading || state is Processing`, show this under Fetch (`AppType.meta`, `AppColors.n400`, centred): **"A download is in progress — cancel it to fetch another link."** Put that string in `lib/ui/format_utils.dart` as `const busyFetchMessage`.
2. **Rejected shares get feedback.**
   - In `lib/state/share_intent.dart`, add:
     ```dart
     /// Bumped each time a shared link is dropped because a download owns yt-dlp.
     final shareRejectedProvider =
         NotifierProvider<ShareRejections, int>(ShareRejections.new);

     class ShareRejections extends Notifier<int> {
       @override
       int build() => 0;
       void bump() => state++;
     }
     ```
   - In `sharedUrlProvider`, read `final rejected = ref.read(shareRejectedProvider.notifier);` **at the top, next to `controller`**. Never use `ref` later in the loop.
   - In **both** the initial and the live branch: `if (url != null) { if (controller.canExtract) { …existing… } else { rejected.bump(); } }`. A rejected URL is still **not** yielded (the existing test pins this).
   - In `HomeShell`, add `ref.listen<int>(shareRejectedProvider, (p, n) { if (n > (p ?? 0)) _showToast(busyFetchMessage, icon: CupertinoIcons.info_circle); });`.
3. **Cancel is acknowledged and does not pop the sheet (`home_shell.dart`).** The listener's first branch becomes:
   ```dart
   final cancelled = next is FormatsReady && (prev is Downloading || prev is Processing);
   if (cancelled) {
     _showToast('Download cancelled.', icon: CupertinoIcons.xmark_circle);
   } else if (next is FormatsReady && prev is! FormatsReady) {
     /* existing: open the format sheet post-frame */
   } else if (next is Done && prev is! Done) {
     /* existing */
   }
   ```
   `Failed → retry() → FormatsReady` still re-opens the sheet, which is intended.
4. **Toast plumbing.**
   - `_showToast(String msg, {IconData icon = CupertinoIcons.check_mark_circled})`, and `_Toast` takes `icon`.
   - Wrap `_Toast` in `Semantics(liveRegion: true, child: …)` so TalkBack announces it. Do **not** use `SemanticsService.announce`.
5. **Unknown size (`_ActiveCard`).** When `total <= 0`, the status reads `'${formatBytes(d.received)} downloaded · size unknown'`. The indeterminate stripe is already shown.

**Tests:**
- `download_controller_test.dart`: the busy-share test also asserts `c.read(shareRejectedProvider)` is `0` after the idle share and `1` after the busy one.
- `screens_test.dart`, with a driven controller:
  ```dart
  class _Driven extends DownloadController {
    @override
    DownloadState build() => const Idle();
    void go(DownloadState s) => state = s;
  }
  ```
  - `Downloading → FormatsReady` shows "Download cancelled." and **no** "AVAILABLE QUALITIES" (the sheet stays closed).
  - Control: `Loading → FormatsReady` **does** open the sheet.
  - Bumping `shareRejectedProvider` (via `ProviderScope.containerOf(t.element(find.byType(HomeShell)))`) shows `busyFetchMessage`.
  - The `Downloading` state shows the busy hint.
  - `total: -1` shows "size unknown".
  - Every toast test ends with `await t.pump(const Duration(seconds: 3));`.
- Mutation-check: remove the `cancelled` branch and the "no sheet" test must fail.

Commit: `ux: explain a blocked fetch, acknowledge cancel, flag unknown size`.

## Step 10: docs

- **`PROJECT_TODO.md`:**
  - tick the five completed P3 items, each with a resolution line;
  - "Perform final visual QA on a real device" **stays unchecked** (device unauthorized). Add the TalkBack, large-text, landscape and Remove-animations passes to its checklist;
  - refresh the baseline counts.
- **`CHANGELOG.md` (Unreleased):** list the user-visible items from Steps 2–9.
- **`CLAUDE.md`:**
  - under "Design system", add rules: use `TapTarget`; freeze loops with `reduceMotion`; test with `test/accessibility_test.dart`'s `pumpApp`;
  - under "Architecture", note history schema v2 and that `migrate()` must be extended for every future schema bump;
  - add the toast-timer test gotcha.

Commit: `docs: P3 resolutions, changelog, contributor rules`.

## Critical files

- **New:** `lib/ui/motion.dart`, `lib/ui/widgets/tap_target.dart`, `lib/ui/widgets/info_button.dart`, `test/accessibility_test.dart`, `test/layout_test.dart`, `test/contrast_test.dart`.
- **Modified:** `lib/ui/screens/{home_shell,download_tab,library_tab,settings_tab}.dart`, `lib/ui/sheets/{format_sheet,about_sheet}.dart`, `lib/ui/widgets/{aurora_background,fetch_button,woofer_mark,glass_button}.dart`, `lib/services/history_service.dart`, `lib/state/{download_controller,share_intent}.dart`, `lib/ui/format_utils.dart`, and the tests `{history_service,format_utils,download_controller,screens}_test.dart`.
- **Reused as is:**
  - `chooseDefaultFormat` (`lib/models/media_format_order.dart`)
  - `HistoryService.clear/delete`
  - `historyListProvider`
  - `formatBytes` (`format_utils.dart`)
  - `AppTouch.min`
  - `GlassSheet`
  - the existing `_OpenStorage`, `_VersionedYtdlp` and `_app` helpers in `screens_test.dart`.

## Verification

1. **From `app/`:** `flutter analyze` (no issues) and `flutter test` (the current 129 plus all new tests, all green).
2. The **mutation checks** listed in Steps 2, 3 and 9 were done, and `git diff` is empty afterwards.
3. **From `app/android/`:** `JAVA_HOME="C:\Program Files\Android\Android Studio\jbr" ./gradlew :app:testDebugUnitTest` is still green. P3 doesn't touch Kotlin; this confirms nothing broke.
4. **`flutter build apk --release`** succeeds. The upgrade path itself is covered by the migration test.
5. **Not verifiable here:** TalkBack, real font scaling, the Remove-animations toggle, and looks on the physical phone. That's the open P3 device-QA item.

## Out of scope

- Device visual QA (blocked on ADB authorization).
- A preferences store or real settings toggles. The TODO says keep the rows informational.
- Deleting files from MediaStore (decided against, above).
- Any design-token changes beyond swapping placeholder `n600`→`n500`.
