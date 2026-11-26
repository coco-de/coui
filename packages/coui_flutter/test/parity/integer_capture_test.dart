// #3665 — proves `captureAtIntegerWidth` actually changes the rasterized
// width, using a label picked specifically because it demonstrates the
// divergence: the label has a fractional intrinsic width on both
// platforms, so Flutter's naive `toImage()` CEILs to one integer while a
// real Chrome capture of the same label rounds to the one below it —
// the expected value is the round-to-nearest target, not an arbitrary
// fixture.
//
// "Place Order" is that label at the Button label weight (500). Flutter's
// natural width is 105.129 (`tester.getSize`), so a naive capture ceils to
// 106 and round-to-nearest lands on 105. Chrome's `element.screenshot()`
// of the same Button is 105px (`tool/parity/test/web/
// web_capture_backend_test.dart`, run in CI with Chrome); at the earlier
// weight 600 the two platforms' natural widths sat 0.016px apart.
//
// The fractional remainder (.13) sits 0.37px from the .5 boundary, far
// beyond that cross-platform gap, so the label stays on the
// "ceil != round" side.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'integer_capture.dart';
import 'parity_fonts.dart';
import 'parity_page_background.dart';

const String _kLabel = 'Place Order';

/// Matches this file's own top-comment measurement — the Chrome
/// capture width for [_kLabel] via `web_capture_backend.dart`'s
/// wrapper, at `kCaptureAvailableWidthPx`-and-above available width
/// (`_kLabel`'s Button is content-sized, not `w-full` — see G2,
/// `web_capture_backend_test.dart` — so it's unaffected by the
/// available-width value itself, only by its own intrinsic size).
/// 105 is the round-to-nearest of Flutter's natural 105.129 at label
/// weight 500, and Chrome's screenshot width of the same Button.
const int _kExpectedCrossPlatformWidth = 105;

Widget _buildApp(PinnedWidth? pin, GlobalKey boundaryKey) {
  Widget button = Button(
    onPressed: () {},
    child: const Text(_kLabel),
  );
  if (pin != null) {
    // The shared pinned box (`pinnedWidthBox`) — the same tree every
    // harness pins with, so what this file proves about the boundary width
    // is a fact about the box the real captures use.
    button = pinnedWidthBox(pin, child: button);
  }
  return Theme(
    data: const ThemeData(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: material.Material(
        child: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: ColoredBox(
              color: parityPageBackground(dark: false),
              child: button,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadParityFonts);
  mainChromeRounding();

  testWidgets(
    'a naive single-pass capture CEILs a fractional intrinsic width '
    '(the pre-fix behavior — documents *why* the fix below is needed, '
    'not a regression target of its own)',
    (tester) async {
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(_buildApp(null, boundaryKey));
      await tester.pumpAndSettle();

      final naturalWidth = tester.getSize(find.byType(Button)).width;
      final image = await tester.runAsync(() {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        return boundary.toImage();
      });

      expect(
        image!.width,
        naturalWidth.ceil(),
        reason:
            'if this ever fails, toImage() stopped ceiling and this '
            "file's premise (§ top comment) needs re-measuring against "
            'a real Web capture, not just updating this expectation.',
      );
      expect(
        image.width,
        isNot(_kExpectedCrossPlatformWidth),
        reason:
            'the naive capture ($naturalWidth → ${image.width}) must '
            'differ from the cross-platform target '
            '($_kExpectedCrossPlatformWidth) for this test to mean '
            'anything — otherwise "$_kLabel" stopped being a '
            'divergent label (re-pick one via the measurement in this '
            "file's top comment).",
      );
    },
  );

  testWidgets(
    'captureAtIntegerWidth lands on the cross-platform (round-to-nearest) '
    'width, not the naive ceil',
    (tester) async {
      final boundaryKey = GlobalKey();
      final image = await captureAtIntegerWidth(
        tester,
        buildApp: (pin) => _buildApp(pin, boundaryKey),
        content: find.byType(Button),
        boundaryKey: boundaryKey,
      );

      expect(image.width, _kExpectedCrossPlatformWidth);
    },
  );
}

/// A box of [size] on the parity page, keyed for its boundary.
Widget _box(Size size, GlobalKey boundaryKey) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(
    child: RepaintBoundary(
      key: boundaryKey,
      child: SizedBox.fromSize(
        size: size,
        child: ColoredBox(color: parityPageBackground(dark: false)),
      ),
    ),
  ),
);

/// Rasterizes a box of [size] the way the captures do.
Future<ui.Image> _rasterizeBox(WidgetTester tester, Size size) async {
  final boundaryKey = GlobalKey();
  await tester.pumpWidget(_box(size, boundaryKey));
  final image = await tester.runAsync(
    () => rasterizeAtChromeHeight(
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary,
    ),
  );

  return image!;
}

void mainChromeRounding() {
  group('chromeRoundedPx — the whole pixels Chrome clips a length to', () {
    // These same vectors are independently captured in real Chrome by
    // capture_rounding_contract_test.dart. In particular, Chrome does not
    // snap a requested width just under .5 up to .5 before capturing it.
    test('matches the independently captured Chrome size vectors', () {
      final vectors =
          jsonDecode(
                File(
                  '../../tool/parity/fixtures/clip_rounding_vectors.json',
                ).readAsStringSync(),
              )
              as List;
      for (final vector in vectors.cast<Map<String, dynamic>>()) {
        final requested = (vector['requested'] as List).cast<num>();
        final expected = (vector['png'] as List).cast<int>();
        expect(chromeRoundedPx(requested[0].toDouble()), expected[0]);
        expect(chromeRoundedPx(requested[1].toDouble()), expected[1]);
      }
    });

    // The same sweep: a badge row 350.446564 in Flutter, 350.515625 in
    // Chrome — two widths, not float noise.
    test('distinct laid-out lengths keep their own rounding', () {
      expect(chromeRoundedPx(350.446564), 350);
      expect(chromeRoundedPx(350.515625), 351);
    });

    test('a half rounds up and anything else to the nearest', () {
      expect(chromeRoundedPx(157.5), 158);
      expect(chromeRoundedPx(156.307692), 156);
      expect(chromeRoundedPx(674.656), 675);
    });
  });

  group('rasterizeAtChromeHeight — the rows Chrome keeps', () {
    // `toImage()` alone would give 157 rows for 156.31 — a row Chrome's
    // clip of the same box does not have.
    testWidgets('a fraction under a half loses the extra bottom row', (
      tester,
    ) async {
      final image = await _rasterizeBox(tester, const Size(20, 156.307692));
      expect(image.height, 156);
      expect(image.width, 20);
    });

    testWidgets('a half and above keep the row toImage gives', (
      tester,
    ) async {
      final image = await _rasterizeBox(tester, const Size(20, 157.5));
      expect(image.height, 158);
    });

    testWidgets('a whole height is left alone', (tester) async {
      final image = await _rasterizeBox(tester, const Size(20, 24));
      expect(image.height, 24);
    });
  });
}
