# Tabs long-label overflow investigation

Task: task_a532e4cef0eb / ctx_ac99fef7f194
Branch: coco-de-dev/m4-coui-tabs

## Cause and scope

Flutter Tabs builds an IntrinsicHeight/Row. With expand=false, each label/badge
Row requests its intrinsic width and the outer Row cannot scroll. With
expand=true, Expanded allocates equal button widths but the inner label Row
still measures its non-flex children at their intrinsic widths. Long translated
labels, especially at 2× text scale, therefore overflow instead of fitting.
The existing height floor prevents vertical clipping but does not solve width.
This explains why a consumer needs an external horizontal-scroll workaround;
BottariFX source itself was not available in this checkout and was not inspected.

Web Tabs similarly has an inline-flex rail with no horizontal overflow viewport.
Its per-tab fixed height can also constrain enlarged text. TabPane already has
separate strip scrolling and is unchanged. No border-width-zero (#5720) behavior,
Figma source, baseline image, or unrelated worker file was changed.

No AGENTS.md was found in this checkout or its ancestor directories. Read the
CoUI Tabs skill and the CLAUDE.md-linked API, layering, interaction and validation
rules. The installed skill predates the current size API; repository code was
used as the authoritative implementation.

## Change

Added optional scrollable=false to the shared CoreTabsContract and both platforms'
Tabs, Tabs.labels and copyWith. Existing call sites, styles and default output
remain unchanged. Third-party classes implementing CoreTabsContract must add the
new getter, as with any extension of that interface.

scrollable=true preserves full intrinsic labels and uses a bounded horizontal
viewport. It takes precedence over expand. Horizontal drags scroll rather than
triggering swipe selection. Flutter reveals focused tabs using ensureVisible;
Web keeps existing native roving focus. Web scrollable tabs use a minimum height
instead of a fixed height, and neither ordinary nor closable tabs flex-shrink.
No ellipsis, forced smaller font, or hardcoded label measurements were added.
Consumers can replace their external scroll wrapper with scrollable=true, with
a bounded parent width. The default mode intentionally retains its existing
behavior; expand alone is not an automatic long-label fitting policy.

## Verification evidence

- Command: `cd packages/coui_flutter && flutter test --no-pub test/components/navigation/tabs_scrollable_test.dart test/components/navigation/tabs_test.dart test/components/navigation/tabs_close_test.dart`
  - Expected: no overflow, usable selection, existing behavior preserved.
  - Evidence: `00:02 +95: All tests passed!`
  - Pass: yes. New matrix covers 160/320px, 1×/2×, pill/underline and 11 labels
    (English, Korean, Japanese, Chinese, German, French, Spanish, Portuguese,
    Italian, Russian, Arabic); verifies drag without selection and last-tab tap.
    Also verifies keyboard arrows + Enter with offscreen focus reveal, RTL,
    badges, independent close action, empty/unbounded layouts, copyWith/style chain.
- Command: `dart test packages/coui_web/test/components/navigation/tabs_scrollable_test.dart packages/coui_web/test/components/navigation/tabs_test.dart packages/coui_web/test/components/navigation/tabs_close_test.dart packages/coui_web/test/components/navigation/tablist_keyboard_test.dart`
  - Expected: scrolling CSS, full labels, non-shrinking tabs, roving markers and
    existing default/close behavior preserved.
  - Evidence: `00:00 +54: All tests passed!`
  - Pass: yes, component and SSR verification. SSR emits its existing warning
    about a missing client entrypoint; no live DOM keyboard claim is made.
- Command: `cd packages/coui_flutter && flutter test --no-pub test/src/golden/size_axis_golden_test.dart --plain-name 'Tabs — every CoreTabsSize'`
  - Expected: existing macOS size-axis golden unchanged.
  - Evidence: `00:00 +1: All tests passed!`
  - Pass: yes; no update-goldens and no image changes.
- Command: `dart analyze --fatal-infos` on the changed contract, Flutter Tabs,
  Web Tabs directory and both new test files.
  - Expected: zero diagnostics.
  - Evidence: `No issues found!`
  - Pass: yes.
- Command: `dart format --set-exit-if-changed --output=none` on six changed Dart files;
  `git diff --check`.
  - Expected: no formatting drift or whitespace errors.
  - Evidence: `Formatted 6 files (0 changed) in 0.02 seconds.`; diff check exit 0.
  - Pass: yes.

## Limits and coordinator handoff

No Ego Lite tool or executable was available in this worker session. No other
browser was used. Live browser layout at 1×/2×, touch scrolling, and keyboard
focus visibility remain a visual QA follow-up; Web results above establish
SSR/CSS structure rather than browser geometry. Flutter geometry and input were
executed in widget tests, and the existing default screenshot was checked by
the golden comparator. No new screenshots or replacement baselines were created.

The API does not add imperative scroll control or automatically scroll on an
external selectedIndex change; callers can navigate by pointer/keyboard and
scroll the strip. Final merge/release and BottariFX adoption belong to coordinator
review; this worker does not merge or publish a package.
