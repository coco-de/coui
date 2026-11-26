# DotIndicator semantics verification

Base `3d092c0603a73627c41fd2e83cc4c16a9ef0fb6d`. The previous Flutter
semantics tree exposed three named nodes and three unnamed actionable nodes
for three interactive dots; passive dots also appeared as buttons. Regression
tests reproduced both failures before the fix.

Interactive Flutter dots merge each label, selected state and the existing
Clickable semantics/action into one node, preserving Clickable's semantic tap
event and feedback. Passive Flutter/Web indicators expose one localized
read-only position and hide dot actions. An empty indicator is inaccessible
and has no keyboard action. The 11 locale strings are sourced from
`coui_i10n/chrome/i18n`; the generator and both platform parity tests were run.
Both Carousel variants, interactive/passive transitions, semantic tap, keyboard
arrows, Korean locale, empty state and existing feedback tests passed.

Ego Lite on macOS displayed Flutter and Web preview apps. The accessibility
snapshots in `flutter-accessibility.json` and `web-accessibility.json` contain
named interactive controls and one passive `Item 2 of 3` position; the Flutter
preview also contains an interactive Carousel. Activating the second Flutter
semantic button updated selection; Web Tab/ArrowRight updated selection.
Before/after images on both platforms are byte-identical across the whole
frame. This was a desktop browser accessibility-tree inspection, not a
physical iOS VoiceOver or Android TalkBack session.

Validation commands, with Flutter 3.47.6 on PATH:

```sh
cd packages/coui_i10n
dart run tool/gen_chrome_localizations.dart --check
cd ../coui_flutter
flutter test --no-pub test/components/display/dot_indicator_semantics_test.dart \
  test/components/display/dot_indicator_test.dart \
  test/components/display/carousel_test.dart test/components/l10n_wiring_test.dart \
  test/components/locale/chrome_localizations_source_test.dart \
  test/theme/tap_feedback_axis_test.dart
cd ../coui_web
dart test test/components/display/dot_indicator_semantics_test.dart \
  test/components/display/dot_indicator_style_test.dart \
  test/components/locale/chrome_localizations_source_test.dart
```

Both preview source files are included. Flutter preview can be served with
`flutter run --no-pub -d web-server -t` from `app/coui_widgetbook`. For Web,
from the repository root generate the local head, use the pinned Tailwind
script and compile the preview:

```sh
dart --packages=.dart_tool/package_config.json docs/verification/dot-indicator-semantics/web-head.dart
mkdir -p /tmp/coui-dot-semantics-web
cp tool/parity/vendor/tailwind/tailwind-play-3.4.17.js /tmp/coui-dot-semantics-web/tailwind.js
python3 - <<'PYWEB'
from pathlib import Path
head = Path('/tmp/coui-indicator-web-head.html').read_text()
Path('/tmp/coui-dot-semantics-web/index.html').write_text(
    f'<!doctype html><html><head>{head}</head><body>'
    '<script defer src="main.dart.js"></script></body></html>')
PYWEB
dart compile js --packages=.dart_tool/package_config.json \
  -o /tmp/coui-dot-semantics-web/main.dart.js \
  docs/verification/dot-indicator-semantics/web-preview.dart
python3 -m http.server 19477 --bind 127.0.0.1 --directory /tmp/coui-dot-semantics-web
```
