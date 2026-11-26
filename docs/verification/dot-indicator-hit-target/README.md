# DotIndicator Web pointer targets

On the parent PR #5737 commit, a horizontal interactive indicator with 6px
dots and a 6px gap selected item 3 when the pointer clicked the visible centre
of item 2. This happened with both the round default and an 18px active marker.
The shared 24px `coui-touch-target::after` boxes overlapped: in Ego Lite,
`document.elementFromPoint` returned the later item's tab. The screenshot
`before-default-second-click.png` shows item 3 after clicking item 2.

The DotIndicator-specific rule partitions the gap between adjacent visible
markers. The whole painted marker is selectable even for an active length of
60px; the outside ends and cross axis retain the original 24px reach. The
shared touch target is unchanged. On a dense group the independent target
regions along the axis are necessarily smaller than 24px; this does not claim
that each dense marker has a disjoint 24×24px target. For 30px gaps, all three
computed target boxes are 24×24px.

In Ego Lite on macOS, LTR and RTL clicks on every visible centre selected the
right item for horizontal and vertical 18×6 overrides, interactive round dots,
30px spacing and 60px active length. The outer 11px reach of the first and
last dots worked for LTR and RTL, and the end of the 60px marker remained
clickable. Tab and horizontal/vertical arrow keys updated selection and drew
the focus ring (`after-keyboard-*.png`). An RTL case also exposed physical
`margin-right` placing no gap between the last two dots; logical
`margin-inline-end` fixes this without changing LTR paint. The LTR default
passive dots and horizontal override crops matched before/after byte for byte.
These are actual desktop browser interactions, not a physical phone test.

The Flutter baseline was also opened in Ego Lite: keyboard selection, focus
rings and centre clicks worked, but vertical spacing is a separate Flutter
issue. Its screen reader semantics need separate review: interactive nested
buttons include unnamed tappable descendants. Neither issue is claimed fixed
by this Web change.

## Reproduce the standalone Web preview

From the repository root with the pinned Flutter SDK on `PATH`:

```sh
flutter pub get
dart --packages=.dart_tool/package_config.json docs/verification/dot-indicator-hit-target/web-head.dart
mkdir -p /tmp/coui-indicator-preview-web
cp tool/parity/vendor/tailwind/tailwind-play-3.4.17.js /tmp/coui-indicator-preview-web/tailwind.js
python3 - <<'PY'
from pathlib import Path
head = Path('/tmp/coui-indicator-web-head.html').read_text()
Path('/tmp/coui-indicator-preview-web/index.html').write_text(
    f'<!doctype html><html><head>{head}</head><body>'
    '<script defer src="main.dart.js"></script></body></html>')
PY
dart compile js --packages=.dart_tool/package_config.json \
  -o /tmp/coui-indicator-preview-web/main.dart.js \
  docs/verification/dot-indicator-hit-target/web-preview.dart
python3 -m http.server 19477 --bind 127.0.0.1 --directory /tmp/coui-indicator-preview-web
dart test packages/coui_web/test/components/display/dot_indicator_style_test.dart
```

## RTL switch first-click regression

An immediate LTR → RTL switch caused `transition-all` to animate the physical
margins behind `margin-inline-end`. For the first frame the gap between items
2 and 3 collapsed from 6px to 0px, overlapping the split pointer regions.
In three independent fresh runs, pointer down hit item 3, pointer up hit item
2, the click hit neither and the selection stayed at item 1. The fix excludes
margin transitions while keeping the visual and size transitions. In three
matching fresh runs the 6px gap remained, down/up/click hit item 2, and it was
selected. [Before/after event trace](rtl-transition-events.json). A separate
run checked six RTL first clicks and 30 centre clicks across both directions,
horizontal and vertical, circular defaults, 30px gaps and 60px active markers:
all selected the expected dots. Keyboard and accessibility tree were checked.
The initial 400×650 preview crop was pixel-identical before/after;
[fixed screenshot](rtl-fixed-initial.png). These are Ego Lite desktop checks.

The change was additionally tested together with #5737, #5741 and #5743 in a
local integration commit `d63205414`. Flutter 2,239, Web 2,180 and Core 6
related tests passed; localization generator and token guard passed. Release
SSR and hydrated docs computed-style checks were performed. The
[integrated 7-1–7-29 ledger](integrated-checklist-7.md) explicitly identifies
partial or unrun checks. Complete component verification, physical screen
reader checks and Figma comparison are still open; this remains draft.

## Original CoUI Figma component comparison

The unmodified [CoUI Figma medium / selected 3 variant](https://www.figma.com/design/9FgsLhiWz0aLsVqcoI6nYJ?node-id=3557:132) contains five visible 8px markers, 8px gaps and 8px group padding within an 88×24 logical box. The [original Figma export](figma-medium-original.png) has a 148×56 transparent canvas because invisible children extend its screenshot bounds; the actual variant occupies the top-left 88×24. Its inactive fill is RGB (207,209,212), and active fill is RGB (29,32,37).

For a narrow, transparent-to-white comparison, the top-left 88×24 reference was composited over white and compared to same-sized 1× crops of the actual **latest-main** release docs default preview: [Web](figma-comparison-web.png) and [Flutter](figma-comparison-flutter.png). Exact RGB inequality is Web 184/2112 pixels (8.712%) and Flutter 380/2112 pixels (17.992%). Current active marker centres are RGB (30,32,37), one red channel value above the reference; marker edges have different rasterization. These percentages are for the tiny component crop, not a whole screen. They include anti-aliasing and are not a claim that every changed pixel is a layout defect. The reference export and browser render are kept separate, and no default color was overridden. Exact visual fidelity below 2% remains open.
