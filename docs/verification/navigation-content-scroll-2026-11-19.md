# NavigationBar: follow the visible content's scroll

Local verification of `fix/navigation-content-scroll`, originally based on
`ad1ba78e9` (2026-11-19). Before publication the branch was advanced to
`54851a80d`; none of the seven verified source/test files changed, confirmed by
their saved SHA-256 hashes. Merge status is recorded on the upstream PR. This
report describes local verification, not CI or release evidence; a released
consumer pin update is a separate step.

## Problem and change

`compact: .onScroll` consumed scroll updates from nested vertical lists and
inactive tabs. Scrolling an inner editor could compact the bar; a hidden tab
loading more rows could report offset zero and restore it while the visible
content remained scrolled down. Miracle Alarm had to filter these notifications
outside CoUI.

Flutter now checks the source within the nearest `ScrollNotificationObserver`:
the bar's own scroller, disabled ticker branches, offstage branches and vertical
scrollables nested inside another vertical scrollable do not drive compaction.
The listener ignores them without stopping notifications for other listeners.

Web applies the same visible outer-content rule to DOM events. It rejects hidden
panels and inner vertical scrollports. A vertical list inside a horizontal page
still drives the bar. The existing shared Core compaction state machine, public
constructors, defaults, style fields, animation values and rendering stay intact.
Core API documentation and the component guide describe the source selection.

This is a behavior fix, not a new style or component. Existing compact examples
remain registered in both preview registries. No version, generated changelog,
Figma projection, token, baseline, guard or dependency lock was changed.

## Verification

Commands below use Flutter/Dart from `/Users/cocode/fvm/versions/3.50.0/bin`.
Package commands run in their respective package directories. Raw logs,
captures and SHA-256 hashes of the changed source files are retained locally in
`build/navigation-content-scroll/` (ignored by Git).

| Check | Command | Expected | Actual evidence | Result |
|---|---|---|---|---|
| Flutter reproduction | `flutter test --no-pub test/components/navigation/navigation_bar_compact_test.dart --reporter expanded` before the fix | New tests expose the bug | `29` pass, `3` fail: nested list and offstage tab with tickers on/off | Reproduced |
| Web reproduction | `dart test tool/parity/test/web/navigation_compact_probe_test.dart --name 'nested vertical\|hidden tab' --reporter expanded` before the fix | Browser reproduces the same bug | `0` pass, `3` fail: nested list, display:none, visibility:hidden | Reproduced |
| Flutter regression | `flutter test --no-pub test/components/navigation/ test/components/layout/scaffold_test.dart --reporter expanded` | Navigation and scaffold tests pass | `00:10 +678: All tests passed!` | Pass |
| Web regression | `dart test test/components/navigation/ test/components/layout/scaffold_floating_footer_test.dart --reporter expanded` | Navigation and scaffold tests pass | `00:02 +374: All tests passed!` | Pass |
| Actual browser | `dart test tool/parity/test/web/navigation_compact_probe_test.dart --reporter expanded` | Source selection, motion, captions, lens, hit targets and positive horizontal-page case pass | `00:27 +19: All tests passed!` | Pass |
| Analysis | `dart analyze --fatal-infos` on the six changed Dart files | No diagnostics in changed files | `No issues found!` | Pass |
| Format | `dart format --output=none --set-exit-if-changed` on the six changed Dart files | No drift | `Formatted 6 files (0 changed)` | Pass |
| Contracts and layers | `bash scripts/guards/resolver/verify_contracts.sh` | Existing enforced checks pass | `=== All checks passed ===`; seven existing non-enforced migration warnings | Pass |
| Native render | `PARITY_MANIFEST=/tmp/coui-nav-visual-manifest.json PARITY_OUT=/tmp/coui-nav-visual flutter test --no-pub test/parity/flutter_capture_matrix_test.dart --reporter expanded` | Six variants capture without render errors | `+6: All tests passed!` | Pass |
| Web render | `dart run tool/parity/capture_web.dart --manifest=/tmp/coui-nav-visual-manifest.json --out=/tmp/coui-nav-visual` | Same six variants capture | `[capture_web] 6개 항목 캡처 완료` | Pass |

The visual manifest selects liquidGlass from the official navigation-bar
manifest: default, rail and sidebar, each in light and dark. All twelve native
and Web PNGs were inspected. These are fresh captures, not baseline comparisons.
The captures show platform differences in bar/rail shape and label placement;
cross-platform pixel equality is not claimed. The behavior suite uses the actual
optimized browser runtime for compact motion and source filtering.

Initial directory-wide analysis also reported seven existing public-doc infos in
the untouched `glass_navigation_dom_stub.dart`; changed-file analysis is clean.
No lint suppression was added. Full CI, a full docs-site build, Safari/Firefox,
Figma publication and a new upstream release were not run.

## Simulator verification before merge

The updated library is also exercised by a native integration entry point in
`app/coui_widgetbook`, built and installed on the booted iPhone Duo (iOS 27.2).
This runs the new CoUI source, not Miracle Alarm's older released dependency.
It uses touch drags through Flutter's live integration binding, without mocked
screen dimensions. The cover view reports 1398 × 2034 physical pixels at DPR 3
(466 × 678 logical pixels). This is simulator behavior evidence, not physical
hardware or performance evidence; the unfolded display is not covered here.

Run from `app/coui_widgetbook`, substituting an available simulator ID:

```sh
NAV_SCROLL_OUT=../../build/navigation-content-scroll/simulator \
flutter drive --no-pub --debug \
  -d 675D90C3-ED04-4D23-9841-6AFEAF344604 \
  --driver=test_driver/navigation_content_scroll_driver.dart \
  --target=integration_test/navigation_content_scroll_test.dart
```

Both themes exercise an inner-list drag, outer-content drag, inactive tab row
insertion, and reverse outer drag. Assertions check the source offsets, target
scale and settled animation scale. The driver saves five native screenshots
per theme; capture delivery is not a golden comparison. It waits for the raster
thread to present the settled frame before requesting the native screenshot.

| Check | Expected | Actual evidence | Result |
|---|---|---|---|
| Same integration command with pre-fix `NavigationBar` from `54851a80d` | Reproduce the nested-scroll bug | Both themes fail: `Expected: <1>`, `Actual: <0.84>`, `Inner list must not compact the bar` | Reproduced |
| Same integration command with this fix | Both themes keep the bar stable for inner/hidden content and compact/restore for outer content | `All tests passed.` (exit 0); inner offset `60`, outer compact offset `161.1667`, reverse offset `100`; scale `0.84` → `1.0` | Pass |
| Analysis of the integration test and driver | No new diagnostics | `No issues found!` | Pass |
| Format of the integration test and driver | No drift | `Formatted 2 files (0 changed)` | Pass |

Visual observation: the initial light screenshot omits the Profile icon until
the next repaint. The same missing icon is visible with the pre-fix source too;
the decoded-pixel difference between the two initial light captures is confined
to `(355, 1883)–(791, 1908)`, away from that icon. The icon is present in subsequent
captures. This existing first-paint/capture anomaly is not resolved by this
scroll-source fix; its cause is not established here. The report therefore does
not claim every native visual state is defect-free. Screenshot timing was also
adjusted to avoid capturing an intermediate restore animation.

The host's first Flutter 3.50 build automatically migrates its iOS project
(minimum target, Swift Package Manager and UIScene). These generated build
changes are excluded from this behavior fix. Re-running the command can perform
the same SDK migration. Existing plugin SPM adoption warnings did not prevent
the simulator build.

After advancing to `54851a80d`, the focused Flutter suite passed `32` tests and
the optimized Chrome suite passed `19` tests again. The new integration test
and driver also pass changed-file analysis and formatting checks.

## Consumer boundary

Miracle Alarm's `ControlStrip` measurements, bottom-right rail placement, home
canvas color, subpage header style and resting-bar measurement belong to its
screen shell. They do not require a new global CoUI default.

After this CoUI fix is merged and released, update all of Miracle Alarm's CoUI
sibling pins together and remove its `_FollowedScroll` wrapper. Keep the consumer
regression tests. Until then the application retains its working filter and its
released dependency pin, so this pending upstream change cannot break its build.

The resumed application work was separately checked with Flutter 3.47.6:
miracle_kit `164` tests, home `72` tests, static analysis and contract gates pass;
eight Duo captures (home/notification × cover/inner × light/dark) pass. The only
new application edit in this continuation adds the explicit type to
`duoGoldenDevices` required by its analyzer.
