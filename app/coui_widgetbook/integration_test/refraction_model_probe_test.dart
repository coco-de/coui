// Which law the shipped refraction program bends by, and whether the bend it
// draws is the one Core states.
//
// The rim band can be bent by two laws (`CoreRefractionModel`). Core states
// both as a travel per inset; the fragment program is a transcription of them
// that the unit suite can only compare as text, because `flutter_tester`
// renders with Skia, where a shader filter does not run. The program's uniform
// for the law is also an *index* the Dart side writes by position — a number
// in the wrong slot draws the default law and nothing says so.
//
//   M1  Each law, measured. A gray ramp is the backdrop and a panel of the
//       shipped bend sits over its left edge; the colour that shows through a
//       column of the band says which backdrop position it sampled, and the
//       difference to the column's own position is the travel. Compared with
//       Core's `displacementAt` at the same insets, for both laws. A program
//       that ignored the uniform draws the default law twice and fails the
//       second; one that read the wrong slot fails both.
//   M2  The laws differ where Core says they do: the default is the stronger
//       at the rim and the weaker from a few pixels in, so the two profiles
//       cross. A probe that only checked "they differ" would pass for any
//       change at all.
//   M3  A paraxial request at an index of one bends nothing, measured on the
//       same panel — the control that says the ramp method reads zero as zero.
//
// ## Why the panel is the bare primitive
//
// The shipped surface adds a fill, a wall and a rim of light on top of the
// bent backdrop, and each of them changes the colour a column shows. The
// measurement inverts a *colour* into a *position*, so it needs the bent
// backdrop and nothing over it. `SurfaceBlur` is the widget that mounts the
// program; given a request and no sheen it draws exactly that. The blur is a
// hair above zero because a surface with no blur mounts no pass at all, and
// the bend rides the pass (`refraction_sampling_probe_test.dart`, P3).
//
// ## Units
//
// The program's coordinates arrive in physical pixels (`uSize` and
// `FlutterFragCoord()`, measured), and so does the band: `bezel` of the
// shorter side. Core's `displacementAt` is unit-free, so it is evaluated in
// physical pixels at the device ratio and the result is compared in logical
// ones. The lens and the dispersion are switched off in the request under
// measurement — the first adds a travel of its own and the second splits the
// channels this reads one of.
//
// Run as:
//
//   flutter test integration_test/refraction_model_probe_test.dart \
//     -d macos --dart-define=PROBE_DEVICE_ID=macos

import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Supplied by the runner alongside `-d`, so every reported value carries the
/// device it came from. Empty means the probe refuses to report.
const kProbeDeviceId = String.fromEnvironment('PROBE_DEVICE_ID');

/// Logical size of the capture.
const double kCaptureWidth = 400;
const double kCaptureHeight = 300;

/// The panel's rectangle, logical. 100 on the short side puts the shipped
/// 27% band at 27 logical pixels.
const double kPanelLeft = 100;
const double kPanelTop = 100;
const double kPanelWidth = 200;
const double kPanelHeight = 100;
const double kPanelRadius = 24;

/// The backdrop: black at [kRampStart], white at [kRampEnd], linear between
/// and flat outside. Wide enough that the deepest rim sample of either law
/// lands inside it, and steep enough that one 8-bit level is under a pixel.
const double kRampStart = 100;
const double kRampEnd = 260;

/// The request under measurement: the shipped bend, with the lens and the
/// dispersion off (see the file note).
CoreSurfaceRefraction request(CoreRefractionModel model, {double index = 1.5}) {
  final shipped = CoreSurfaceRecipe.of(
    CoreSurfaceStyleId.liquidGlass,
  ).refraction!;

  return CoreSurfaceRefraction(
    bezel: shipped.bezel,
    strength: shipped.strength,
    refractiveIndex: index,
    model: model,
  );
}

/// One column of the band: how far inside the panel's left edge it is, and how
/// far the backdrop it shows is from where it sits.
typedef BandColumn = ({double inset, double travel});

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    expect(
      kProbeDeviceId,
      isNotEmpty,
      reason: 'Pass --dart-define=PROBE_DEVICE_ID',
    );
  });

  testWidgets('M1–M3 — each law draws the travel Core states for it', (
    tester,
  ) async {
    if (!ui.ImageFilter.isShaderFilterSupported) {
      debugPrint('M1  device=$kProbeDeviceId  not run: no shader filters');
      return;
    }
    final dpr = tester.view.devicePixelRatio;

    /// The band, one entry per physical column from the edge inward.
    Future<List<BandColumn>> measure(CoreSurfaceRefraction asked) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: kCaptureWidth,
                height: kCaptureHeight,
                child: Stack(
                  children: [
                    const Positioned.fill(child: CustomPaint(painter: _Ramp())),
                    Positioned(
                      left: kPanelLeft,
                      top: kPanelTop,
                      width: kPanelWidth,
                      height: kPanelHeight,
                      child: SurfaceBlur(
                        borderRadius: BorderRadius.circular(kPanelRadius),
                        surfaceBlur: 0.1,
                        refraction: asked,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      // The program loads after the first frame; a second settle is the frame
      // that draws with it.
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = (await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: dpr);
        final data = await image.toByteData();

        return data!.buffer.asUint8List();
      }))!;

      return columns(bytes, dpr);
    }

    final snell = await measure(request(CoreRefractionModel.snell));
    final paraxial = await measure(request(CoreRefractionModel.paraxial));
    final control = await measure(
      request(CoreRefractionModel.paraxial, index: 1),
    );

    /// Core's travel at a column, in logical pixels, inward-positive.
    double expected(CoreRefractionModel model, double inset) {
      final band =
          request(model).bezel *
          (kPanelWidth < kPanelHeight ? kPanelWidth : kPanelHeight) *
          dpr;
      final physical = request(
        model,
      ).displacementAt(insetPx: inset * dpr, bandPx: band);

      return -physical / dpr;
    }

    void report(String label, CoreRefractionModel model, List<BandColumn> got) {
      final buffer = StringBuffer(
        'M1  device=$kProbeDeviceId  dpr=$dpr  $label  inset:measured/core',
      );
      for (final column in got.where((c) => c.inset >= 1 && c.inset <= 26)) {
        if ((column.inset * dpr).round() % (dpr * 3).round() != 0) continue;
        buffer.write(
          '  ${column.inset.toStringAsFixed(1)}:'
          '${column.travel.toStringAsFixed(1)}/'
          '${expected(model, column.inset).toStringAsFixed(1)}',
        );
      }
      debugPrint(buffer.toString());
    }

    report('snell   ', CoreRefractionModel.snell, snell);
    report('paraxial', CoreRefractionModel.paraxial, paraxial);

    // M1 — the travel Core states, for both laws, at every column of the
    // band that is not on its very edge (where a half-pixel is a large share).
    // The tolerance is the 8-bit ramp and the nearest-neighbour read: about a
    // pixel and a half in the worst column.
    const tolerance = 2.0;
    void within(String label, CoreRefractionModel model, List<BandColumn> got) {
      var worst = 0.0;
      var at = 0.0;
      var columns = 0;
      for (final column in got.where((c) => c.inset >= 1.0 && c.inset <= 26)) {
        final error = (column.travel - expected(model, column.inset)).abs();
        columns++;
        if (error > worst) {
          worst = error;
          at = column.inset;
        }
      }
      debugPrint(
        'M1  device=$kProbeDeviceId  $label  columns=$columns  '
        'worst=${worst.toStringAsFixed(2)}px at inset ${at.toStringAsFixed(1)}',
      );
      expect(columns, greaterThan(20), reason: '$label: columns read');
      expect(
        worst,
        lessThan(tolerance),
        reason: '$label: the program does not draw the travel Core states',
      );
    }

    within('snell   ', CoreRefractionModel.snell, snell);
    within('paraxial', CoreRefractionModel.paraxial, paraxial);

    // M2 — the profiles cross: the default is the stronger at the rim and the
    // weaker from a few pixels in.
    double at(List<BandColumn> got, double inset) => got
        .reduce(
          (a, b) => (a.inset - inset).abs() <= (b.inset - inset).abs() ? a : b,
        )
        .travel;
    final rimDefault = at(snell, 1.5);
    final rimParaxial = at(paraxial, 1.5);
    final midDefault = at(snell, 15);
    final midParaxial = at(paraxial, 15);
    debugPrint(
      'M2  device=$kProbeDeviceId  rim: snell=${rimDefault.toStringAsFixed(1)}'
      ' paraxial=${rimParaxial.toStringAsFixed(1)}  '
      'mid: snell=${midDefault.toStringAsFixed(1)}'
      ' paraxial=${midParaxial.toStringAsFixed(1)}',
    );
    expect(
      rimDefault - rimParaxial,
      greaterThan(8),
      reason: 'the default law is not the stronger at the rim',
    );
    expect(
      midParaxial - midDefault,
      greaterThan(5),
      reason: 'the default law is not the weaker from a few pixels in',
    );

    // M3 — the control: no bend reads as no travel.
    final worstControl = control
        .where((c) => c.inset >= 1 && c.inset <= 26)
        .map((c) => c.travel.abs())
        .reduce((a, b) => a > b ? a : b);
    debugPrint(
      'M3  device=$kProbeDeviceId  index one: worst travel '
      '${worstControl.toStringAsFixed(2)}px',
    );
    expect(
      worstControl,
      lessThan(tolerance),
      reason: 'the ramp method reads a bend where there is none',
    );
  });
}

/// The columns of the band, read from the middle row of the capture.
///
/// A column shows the backdrop it sampled. The ramp is linear in logical
/// position, so the green channel (the one sample when dispersion is off)
/// inverts to a position, and the position minus the column's own is the
/// travel.
List<BandColumn> columns(Uint8List rgba, double dpr) {
  final width = (kCaptureWidth * dpr).round();
  final row = ((kPanelTop + (kPanelHeight / 2)) * dpr).round();
  final out = <BandColumn>[];
  final first = (kPanelLeft * dpr).round();
  final last = ((kPanelLeft + 28) * dpr).round();

  for (var x = first; x < last; x++) {
    final green = rgba[((row * width) + x) * 4 + 1];
    final sampled = kRampStart + ((green / 255) * (kRampEnd - kRampStart));
    // The pixel's centre, as the program sees it.
    final own = (x + 0.5) / dpr;
    out.add((inset: own - kPanelLeft, travel: sampled - own));
  }

  return out;
}

class _Ramp extends CustomPainter {
  const _Ramp();

  @override
  void paint(Canvas canvas, Size size) {
    // One rectangle per physical column would need the ratio; a gradient
    // shader is exact at any ratio.
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(kRampStart, 0),
        const Offset(kRampEnd, 0),
        const [Color(0xFF000000), Color(0xFFFFFFFF)],
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
