# DotIndicator semantics investigation — 2026-10-28

Base: CoUI main `3d092c0603a73627c41fd2e83cc4c16a9ef0fb6d`.

## Observed and inspected

- In an earlier Ego Lite run of Flutter Web, enabling the Flutter accessibility
  tree produced per-dot named outer button nodes with selected state, plus
  separate unnamed inner tappable button nodes. A passive indicator also exposed
  button/tappable semantics. This is a browser accessibility-tree observation,
  not a VoiceOver or TalkBack test.
- The outer node is `DotIndicator`'s `Semantics(label, button, selected)`.
  `Clickable` supplies another `Semantics(enabled, button, selected)` and a
  `GestureDetector` inside it; its `semanticsButton` and `enabled` default true
  even if `onPressed` is null. `ExcludeFocus` affects focus, not descendants'
  semantics.
- `Clickable._handlePressed` also sends a semantic tap event and handles audio
  feedback. A new outer `onTap` that calls `onChanged` directly would bypass
  this path. Flutter's SDK documentation warns that `MergeSemantics` merges all
  descendants and the first semantic gesture wins if multiple exist, so only
  one marker/one action should be merged at a time and verified.
- Flutter Carousel's slide and banner variants both compose this component with
  `onChanged`, so the interactive fix affects them. Flutter shows a dot for one
  item, while Web Carousel uses more than one; that existing parity difference
  is separate from the duplicated semantics.
- The current DotIndicator docs claim passive Flutter dots are not buttons;
  the previously observed tree contradicts that statement.

## Smallest candidate and limitations

Merge each interactive dot's outer name/selection with its one inner Clickable
semantics, retaining the Clickable gesture action and feedback. For passive
mode, prevent descendant Clickable semantics from producing buttons/actions
while keeping selected position available. Confirm behavior on active → passive
and passive → active rebuilds, pointer, keyboard, screen reader action, both
axes and Carousel, including first/last selection. Keep visual and hit-test
behavior unchanged. This was the candidate at investigation time; subsequent verification is recorded in `../dot-indicator-semantics/README.md`.

The existing labels `dotIndicatorGoToItem` / `dotIndicatorLabel` imply
navigation even when passive. A clear passive position label is a separate
localization decision: `packages/coui_i10n/chrome/i18n` contains 11 source
languages, and `tool/gen_chrome_localizations.dart` generates both Flutter and
Web non-English implementations; interfaces, handwritten English defaults,
parameter metadata, parity tests and component docs must be updated together.
Do not silently reuse the unrelated `progressStepValue` string.

`packages/coui_flutter/test/components/display/dot_indicator_semantics_test.dart`
started as a draft regression test for named single action nodes, selected state,
semantic tap callback, and passive action absence. It was not run during the
initial whole-gallery capture; subsequent test results are recorded separately.
Actual VoiceOver and TalkBack verification remain outstanding.
