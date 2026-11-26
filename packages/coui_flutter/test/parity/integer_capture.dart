// #3665 — pins a capture's rasterized width to an explicit integer so
// `RenderRepaintBoundary.toImage()`'s own rounding has nothing fractional
// left to round.
//
// Measured empirically (12 real Button captures, varying only the label
// text): `toImage()` always CEILs its rendered width — even a
// 0.024-fractional-remainder capture ("Confirm Order", 121.03125) rounded
// UP to 122. The *same* intrinsic widths captured on Web via
// `element.boundingBox()`/`element.screenshot()` instead round to
// NEAREST — Chrome's pipeline gave "Confirm Order" 121, not 122. Text-
// driven intrinsic widths are *systematically* fractional (sub-pixel font
// metrics), not occasionally, so this isn't a rare edge case: any label
// whose natural width's fractional remainder is `< 0.5` diverges by
// exactly 1px between the two platforms — not a rasterizer difference, a
// rounding-function difference. `PixelDiffResult.passed`
// (`tool/parity/src/diff/pixel_diff.dart`) requires
// `dimensionMismatch == null` unconditionally, so no pixel threshold can
// absorb a 1px dimension mismatch; the capture box itself must land on
// the same integer on both platforms.
//
// The fix constrains the *outer* capture boundary to an explicit,
// pre-rounded integer width — round-to-nearest, not floor or ceil,
// because that's what Chrome's screenshot pipeline already does natively
// (all 12 samples agreed with `.round()`), so matching it is what lets
// the Web side need no corresponding fix at all. The measured widget
// itself is centered within that boundary at its own *natural* width
// (never force-stretched) — the boundary's width is within 0.5px of the
// natural width by construction, so the sliver of extra/missing space is
// imperceptible and is simply more of the same opaque page background
// (`parity_page_background.dart`) already composited behind it.
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The whole pixels Chrome clips a box [px] long to.
///
/// Chrome rounds the length its layout actually produced. Do not first
/// move Flutter's length to a presumed Chrome layout grid: a CSS width of
/// 187.499496px lays out at 187.484375px and captures 187 columns, while
/// nearest-grid snapping would incorrectly produce 188. A Web text box
/// whose actual width is 187.5 is a different input and remains different.
int chromeRoundedPx(double px) => px.round();

/// The two widths pass 2 of [captureAtIntegerWidth] is built from.
///
/// [width] is what the capture boundary is pinned to — the natural width
/// rounded to the nearest integer. [naturalWidth] is what the content
/// measured on its own in pass 1, kept because the two together decide how
/// much the content may overhang the boundary — see [overflowMaxWidth].
class PinnedWidth {
  const PinnedWidth({required this.width, required this.naturalWidth});

  /// The integer the capture boundary is pinned to — [chromeRoundedPx] of
  /// [naturalWidth].
  final double width;

  /// The content's own unconstrained width from pass 1.
  final double naturalWidth;

  /// The widest the content may lay out inside the pinned box.
  ///
  /// [chromeRoundedPx] rounds to nearest, so when the natural width's
  /// fraction is below 0.5 the pinned box is up to 0.5px *narrower* than the
  /// content. A non-flexible `Row` does not absorb that — it throws
  /// `RenderFlex overflowed` — so the content gets 1px of headroom, and
  /// only the rasterized boundary stays at [width]; the sub-pixel sliver is
  /// cropped from the image rather than thrown as a layout error.
  ///
  /// But the headroom is a *slack for shrink-wrapping content*, and it is
  /// wrong for content that fills whatever it is given. A container-driven
  /// root (`Divider`, `Progress`, a full-width form) measured 800 in pass 1
  /// because the ambient view is 800 wide; handing it a bound of 801 in
  /// pass 2 makes it lay out at 801 — one pixel wider than pass 1, one pixel
  /// wider than the boundary it is centered in, and one pixel wider than the
  /// 800 Web reports for the same `w-full` root. Measured on the nightly
  /// sweep: 88 cells reading `widthPx: flutter=801.0 web=800.0`, every one
  /// a fill-width component, and each of their PNGs cropped half a pixel
  /// off both edges. So the slack is granted only when it is needed — when
  /// the content is actually wider than the box — and a root that already
  /// fit gets exactly the box.
  ///
  /// `+1`, not unbounded: the maximum shortfall is 0.5px, so 1 is already
  /// double that margin, and an unbounded width broke `Command`, whose
  /// subtree has a descendant that requires a bounded incoming width.
  double get overflowMaxWidth => naturalWidth > width ? width + 1 : width;
}

/// The pinned-width box pass 2 wraps [child] in — the one place the
/// `SizedBox` / `Center` / `OverflowBox` shape is written, so the three
/// harnesses that pin a width (`flutter_capture_test.dart`,
/// `flutter_capture_matrix_test.dart`, and the overlay-pinning regression
/// test that reproduces the matrix tree) cannot drift from each other.
///
/// [child] is centered at its own natural width inside a box as wide as
/// [PinnedWidth.width] — never force-stretched. `Center` without a factor
/// fills all *available* height under a loose constraint (`Align`'s
/// documented behaviour) rather than shrink-wrapping to its child —
/// confirmed empirically: every matrix capture came back exactly 600px tall
/// (`flutter_test`'s default view height) before `heightFactor: 1` was
/// added. `widthFactor: 1` is set for the same reason on the other axis,
/// even though the `SizedBox`'s tight width would clamp it either way —
/// stating it keeps both axes shrink-wrapped by the same explicit rule.
///
/// `fit: .deferToChild` — `OverflowBox`'s own default (`OverflowBoxFit.max`)
/// sizes *itself* to the biggest constraint available on any axis it
/// doesn't override, not to its child; without it the single-Button
/// harness rasterized at the test view's height (600) instead of the
/// Button's real height (40). `.deferToChild` makes `OverflowBox` size
/// itself to its child on the un-overridden (height) axis, which is what
/// `heightFactor: 1` intends but cannot enforce on its own — `Center`
/// derives its size from its *immediate* child, and that child is this
/// `OverflowBox`.
Widget pinnedWidthBox(PinnedWidth pin, {required Widget child}) => SizedBox(
  width: pin.width,
  child: Center(
    widthFactor: 1,
    heightFactor: 1,
    child: OverflowBox(
      minWidth: 0,
      maxWidth: pin.overflowMaxWidth,
      fit: OverflowBoxFit.deferToChild,
      child: child,
    ),
  ),
);

/// Two-pass integer-width capture.
///
/// Pass 1 pumps [buildApp] with `null` — [content]'s natural, unconstrained
/// render — and measures [content]'s width via `tester.getSize`. Pass 2
/// pumps [buildApp] again with a [PinnedWidth] carrying that measurement
/// rounded as Chrome rounds it ([chromeRoundedPx]), and rasterizes
/// [boundaryKey]'s `RepaintBoundary` at the height Chrome keeps
/// ([rasterizeAtChromeHeight]).
///
/// [buildApp] is responsible for wrapping [content] in [pinnedWidthBox]
/// when the pin is non-null (and leaving [content] unconstrained when it's
/// `null`) — this function only measures and decides *what* integer to pin
/// to, not *where* in the tree that box goes (the ambient tree shape is
/// call-site-specific: `flutter_capture_test.dart`'s `buildTestApp` already
/// differs from the matrix entrypoint's).
Future<ui.Image> captureAtIntegerWidth(
  WidgetTester tester, {
  required Widget Function(PinnedWidth? pin) buildApp,
  required Finder content,
  required GlobalKey boundaryKey,
}) async {
  await tester.pumpWidget(buildApp(null));
  await tester.pumpAndSettle();
  final naturalWidth = tester.getSize(content).width;
  final pin = PinnedWidth(
    width: chromeRoundedPx(naturalWidth).toDouble(),
    naturalWidth: naturalWidth,
  );

  await tester.pumpWidget(buildApp(pin));
  await tester.pumpAndSettle();

  final image = await tester.runAsync(() {
    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    return rasterizeAtChromeHeight(boundary);
  });
  return image!;
}

/// Rasterizes [boundary] at the height Chrome clips the same box to.
///
/// `RenderRepaintBoundary.toImage()` CEILs a fractional height as it does a
/// width — a 156.31 tall stage rasterizes 157 rows — while Chrome's clip of
/// the same 156.3 rounds to 156. The width is already whole by the pin; the
/// height is left to the content, which makes it fractional only through
/// its own geometry (a frame at an aspect ratio over a fixed width), so the
/// extra row is cropped off the bottom rather than the content re-laid out
/// in a height it did not choose — the same top-anchored rows Chrome keeps.
Future<ui.Image> rasterizeAtChromeHeight(RenderRepaintBoundary boundary) async {
  final raster = await boundary.toImage();
  final rows = chromeRoundedPx(boundary.size.height);
  if (rows <= 0 || rows >= raster.height) return raster;
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawImage(raster, Offset.zero, Paint());
  final cropped = await recorder.endRecording().toImage(raster.width, rows);
  raster.dispose();

  return cropped;
}
