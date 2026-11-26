# Flutter DotIndicator axis spacing

A 6px `spacing` override produced a 0px vertical gap: the widget assigned
inter-item spacing to left/right padding regardless of its axis. Its RTL
horizontal edge padding also left only 3px between some dots. Regression
widget tests first reproduced both failures, then passed with axis-aware and
text-direction-aware edge padding. Tests cover horizontal and vertical gaps,
RTL, and asymmetric outer padding.

The running Flutter preview was opened in Ego Lite on macOS. `before.png` shows
the missing vertical gaps; `after.png` shows the 6px gaps. Clicking the second
vertical marker and using Tab/ArrowDown both selected it, with the keyboard
focus ring visible (`after-click.png`, `after-keyboard.png`). The horizontal
indicator crop is byte-identical before/after. This is desktop browser
verification, not a physical phone test. Flutter Web's existing nested unnamed
interactive semantics are separate and remain unaddressed.

To reproduce from the repository root with Flutter 3.47.6 on PATH:

```sh
flutter pub get
cd packages/coui_flutter
flutter test --no-pub test/components/display/dot_indicator_test.dart
cd ../../app/coui_widgetbook
flutter run --no-pub -d web-server --web-hostname 127.0.0.1 --web-port 19476 \
  -t ../../docs/verification/dot-indicator-vertical-spacing/flutter-preview.dart
```
