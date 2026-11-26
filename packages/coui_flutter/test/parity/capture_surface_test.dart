// #3665 — the Flutter half of the capture-width contract
// `tool/parity/src/model/capture_surface.dart` names on the Web side.
//
// `flutter_capture_test.dart` never sets `tester.view.physicalSize` —
// every real Flutter capture renders under whatever `flutter_test`'s
// default `TestFlutterView` happens to be. That default was always 800
// logical px wide (`physicalSize.width / devicePixelRatio`), which is
// *why* `kCaptureAvailableWidthPx` on the Web side is 800 and not some
// other number: this constant is chosen to match Flutter's existing
// default, not the reverse. Before this file existed that coupling was
// entirely implicit — nothing would fail if a Flutter SDK upgrade ever
// changed `flutter_test`'s default view size, it would just silently
// change what every container-driven Flutter capture renders at. The
// first group below turns that implicit fact into an explicit, checked
// one.
//
// This file cannot `import` `tool/parity/src/model/capture_surface.dart`
// — `coui_flutter` is a separate pub package from the workspace-root
// `tool/` scripts, so it carries its own copy of the constant below. The
// same "declare a literal, verify it doesn't silently drift" pattern
// `tool/parity/src/manifest/surface_marker_registry.dart` already uses
// for a different cross-package literal set applies here too: this file
// makes no attempt to read the other side's source text (a `dart:io` file
// read from a Flutter `test` target reaches outside what any other test
// in this package does), and instead keeps both sides honest by each
// independently asserting against something *real* — this file against
// `flutter_test`'s actual default view size, `web_capture_backend_test.dart`
// against a real puppeteer capture — so either side drifting from the
// number they're each supposed to share fails on its own.
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors `tool/parity/src/model/capture_surface.dart`'s
/// `kCaptureAvailableWidthPx` — see this file's top comment for why the
/// two copies aren't a single shared Dart constant.
const int kCaptureAvailableWidthPx = 800;

/// A fresh key per capture — `RepaintBoundary` requires each mounted
/// instance's `GlobalKey` be unique for the *currently mounted* tree, and
/// the tests below run several sequential `testWidgets` in one file.
GlobalKey _newBoundaryKey() => GlobalKey();

/// The same "screenshot just the component, not the whole page" ambient
/// tree `flutter_capture_test.dart`'s `buildTestApp` sets up — duplicated
/// locally rather than imported from that test file (a small, deliberate
/// copy so this file doesn't create a dependency on another test file's
/// private implementation staying stable) — with an unconstrained
/// [Center] so a container-driven ([Divider]/[Progress]/[Slider]) child
/// stretches to the *ambient view's* own width rather than any width this
/// wrapper might otherwise impose.
Widget _buildCaptureApp(Widget child, GlobalKey boundaryKey) => Theme(
  data: const ThemeData(),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: material.Material(
      child: Center(
        child: RepaintBoundary(key: boundaryKey, child: child),
      ),
    ),
  ),
);

/// Rasterizes the widget under [boundaryKey]. Must run inside
/// [WidgetTester.runAsync] — same reason `flutter_capture_test.dart`'s
/// `_capturePng` does: `RenderRepaintBoundary.toImage` is real async I/O
/// `flutter_test`'s fake-async test zone won't let complete.
Future<ui.Image> _captureImage(
  WidgetTester tester,
  GlobalKey boundaryKey,
) async {
  final image = await tester.runAsync(() async {
    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    return boundary.toImage();
  });
  return image!;
}

void main() {
  group('ambient flutter_test view width (#3665 capture-width contract)', () {
    testWidgets(
      "tester.view's default logical width equals kCaptureAvailableWidthPx",
      (tester) async {
        // Deliberately reads tester.view UNMODIFIED — no
        // `tester.view.physicalSize = …` override anywhere in this file or
        // in `flutter_capture_test.dart`. This is the value every real
        // Flutter capture actually renders under today.
        final logicalWidth =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;
        expect(
          logicalWidth,
          kCaptureAvailableWidthPx.toDouble(),
          reason:
              "flutter_test's default TestFlutterView width drifted from "
              'kCaptureAvailableWidthPx — every container-driven Flutter '
              'capture just silently changed size. Either flutter_test '
              'changed its default (pin it explicitly in '
              'flutter_capture_test.dart\'s buildTestApp) or this constant '
              'needs updating alongside tool/parity/src/model/'
              'capture_surface.dart\'s.',
        );
      },
    );
  });

  group('G0 — container-driven widgets render at the contract width', () {
    final builders = <String, Widget Function()>{
      'Divider': Divider.new,
      'Progress': () => const Progress(value: 0.65),
      'Slider': Slider.new,
    };

    for (final entry in builders.entries) {
      testWidgets(
        '${entry.key} renders at kCaptureAvailableWidthPx wide',
        (tester) async {
          final boundaryKey = _newBoundaryKey();
          await tester.pumpWidget(
            _buildCaptureApp(entry.value(), boundaryKey),
          );
          await tester.pumpAndSettle();

          final image = await _captureImage(tester, boundaryKey);
          expect(image.width, kCaptureAvailableWidthPx);
        },
      );
    }
  });
}
