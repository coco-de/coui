// The frost and the body shade of a glass surface, drawn by the engine.
//
// `flutter_tester` cannot run `ImageFilter.shader`, so the shade's pixels —
// and the claim that the second backdrop pass reads the first's output — are
// not something the unit suites can see. This probe mounts the shipped
// `SurfaceBlur` and the shipped preset on a device and reads what the
// compositor produced.
//
// The expected values are never a copy of the arithmetic: they are
// `CoreSurfaceFrost.mix` and `CoreSurfaceBodyShade.shade`, the statements the
// Web filter is tested against too, applied to pixels *measured on the same
// scene without the term*.
//
//   F1  The frost: a heavy blur of a striped backdrop laid over the lightly
//       blurred one at the share the theme states. Three captures — without
//       the frost, at share 1 (the cloud alone) and at 0.73 — and the third
//       must be `mix(cloud, copy, 0.73)`.
//   S1  The shade of a surface that bends nothing: bands of grey and colour,
//       with and without the shade, the shaded pixel equal to
//       `shade(strength, unshaded pixel)`. This is the program mounted with
//       every geometric uniform at zero.
//   S2  The same under a layer that saves a pass starting somewhere other
//       than the root's origin — the case in which the bend is withdrawn —
//       once for an image filter and once for a save-layer clip. The surface
//       itself is asked whether it reads the root's pass before a pixel is
//       judged. The shade must still be drawn, and by the same amounts: it
//       measures no coordinates.
//   F2  The frost under the same layers: the cloud is a pass of its own, and
//       needs no coordinates either.
//   S3  A surface that bends and shades: beyond the rim's band it shades
//       exactly as S1 does.
//   P1  The shipped preset, both palettes: the terms move pixels, and under
//       reduced transparency and under high contrast they do not.
//
// Captured from a boundary at the root's origin, which is where the
// compositor's backdrop and the surface's own coordinates agree.
//
// Run as:
//
//   flutter test integration_test/surface_finish_probe_test.dart \
//     -d macos --dart-define=PROBE_DEVICE_ID=macos
//
// The captures land in the app's temporary directory (printed by F1) as
// `f1-*.png`, `s1-*.png` … for a reviewer to look at.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const kProbeDeviceId = String.fromEnvironment('PROBE_DEVICE_ID');

/// Where the captures are written, for a reviewer to look at: the app's own
/// temporary directory, which is the one place a sandboxed macOS app may
/// write. The path is printed at the start of the run.
final String _kShotsDir = '${Directory.systemTemp.path}/surface-finish';

const double _kWidth = 400;
const double _kHeight = 300;

/// The stripes are 12 logical pixels wide, so a Gaussian of sigma 14 leaves
/// nothing of them (the first harmonic is attenuated to a thousandth).
const double _kStripe = 12;

/// Each band is 30 logical pixels tall.
const double _kBand = 30;

/// The columns that sit at the middle of a stripe, inside the panel and far
/// enough from its edges that the blur's edge handling does not reach them.
const List<int> _kStripeColumns = [66, 78, 90, 102, 114, 126];
const int _kStripeRow = 150;

/// The bands the shade is read on, by the row at the middle of each.
const List<({String name, int y})> _kBands = [
  (name: 'dark grey', y: 45),
  (name: 'mid grey', y: 75),
  (name: 'light grey', y: 105),
  (name: 'white', y: 135),
  (name: 'orange', y: 165),
  (name: 'red', y: 195),
  (name: 'green', y: 225),
  (name: 'blue', y: 255),
];
const int _kBandColumn = 300;

/// How far a measured pixel may be from the statement and still be the
/// statement: each stage quantises to 8 bits, and the engine's blur kernel is
/// its own.
const int _kTolerance = 3;

class _Backdrop extends CustomPainter {
  const _Backdrop();

  static const _bands = <Color>[
    Color(0xFF000000),
    Color(0xFF404040),
    Color(0xFF808080),
    Color(0xFFC0C0C0),
    Color(0xFFFFFFFF),
    Color(0xFFFF8000),
    Color(0xFFFF0000),
    Color(0xFF00FF00),
    Color(0xFF0000FF),
    Color(0xFF00C8C8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // Left half: black and white stripes, black first.
    for (var x = 0.0; x < 200; x += _kStripe) {
      paint.color = ((x ~/ _kStripe).isEven)
          ? const Color(0xFF000000)
          : const Color(0xFFFFFFFF);
      canvas.drawRect(Rect.fromLTWH(x, 0, _kStripe, size.height), paint);
    }
    // Right half: bands of grey and colour.
    for (var i = 0; i < _bands.length; i++) {
      paint.color = _bands[i];
      canvas.drawRect(Rect.fromLTWH(200, i * _kBand, 200, _kBand), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// One panel's pass: the shipped `SurfaceBlur`, with nothing drawn on top.
Widget _panel(double left, {CoreSurfaceRefraction? refraction}) => Positioned(
  left: left,
  top: 20,
  width: 160,
  height: 260,
  child: SurfaceBlur(
    borderRadius: BorderRadius.circular(24),
    surfaceBlur: 0.6,
    refraction: refraction,
    child: const SizedBox.expand(),
  ),
);

/// The scene both panels sit in, wrapped by [wrap] where a case needs the
/// surface under a layer. [boundary] marks what is captured: it starts at the
/// root's origin, which is where the compositor's backdrop and the surface's
/// own coordinates agree.
Widget _scene(
  GlobalKey boundary, {
  required ThemeData Function(ThemeData) theme,
  CoreSurfaceRefraction? refraction,
  Widget Function(Widget)? wrap,
}) {
  Widget content = Stack(
    children: [
      const Positioned.fill(child: CustomPaint(painter: _Backdrop())),
      _panel(20, refraction: refraction),
      _panel(220, refraction: refraction),
    ],
  );
  if (wrap != null) content = wrap(content);

  return CoUIApp(
    theme: ThemeData.fromCore(CoreThemePresets.light),
    home: Builder(
      builder: (context) => Theme(
        data: theme(Theme.of(context)),
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: boundary,
            child: SizedBox(width: _kWidth, height: _kHeight, child: content),
          ),
        ),
      ),
    ),
  );
}

typedef _Rgb = ({int r, int g, int b});

class _Shot {
  _Shot(this.bytes, this.width, this.dpr);

  final Uint8List bytes;
  final int width;
  final double dpr;

  _Rgb at(int x, int y) {
    final px = (x * dpr + dpr / 2).floor();
    final py = (y * dpr + dpr / 2).floor();
    final o = (py * width + px) * 4;

    return (r: bytes[o], g: bytes[o + 1], b: bytes[o + 2]);
  }
}

int _distance(_Rgb a, _Rgb b) {
  final d = [(a.r - b.r).abs(), (a.g - b.g).abs(), (a.b - b.b).abs()];

  return d.reduce((x, y) => x > y ? x : y);
}

double _diffRatio(_Shot a, _Shot b, {int x0 = 0, int x1 = 400}) {
  var differing = 0;
  var total = 0;
  for (var y = 0; y < _kHeight; y++) {
    for (var x = x0; x < x1; x++) {
      total++;
      if (_distance(a.at(x, y), b.at(x, y)) >= 2) differing++;
    }
  }

  return differing / total;
}

/// How far the moved scenes are shifted from the root's origin.
const int _kShiftX = 37;
const int _kShiftY = 21;

/// Layers that save a pass starting somewhere other than the root's origin,
/// which is the case in which the bend is withdrawn: one the size of what it
/// holds (an image filter) and one the size of the clip in effect where it
/// paints, here a save-layer clip that starts at the shift. The shift keeps
/// the scene's content away from the origin, so a term that read the wrong
/// coordinates would land on the wrong pixels. The image filter is a hairline
/// blur: it saves a pass and leaves every pixel as it was.
final List<({String name, String slug, Widget Function(Widget) wrap})>
_kMovedPasses = [
  (
    name: 'ImageFiltered',
    slug: 'image-filtered',
    wrap: (scene) => Padding(
      padding: EdgeInsets.only(
        left: _kShiftX.toDouble(),
        top: _kShiftY.toDouble(),
      ),
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 0.1, sigmaY: 0.1),
        child: scene,
      ),
    ),
  ),
  (
    name: 'ClipRect(antiAliasWithSaveLayer)',
    slug: 'clip-save-layer',
    wrap: (scene) => Padding(
      padding: EdgeInsets.only(
        left: _kShiftX.toDouble(),
        top: _kShiftY.toDouble(),
      ),
      child: ClipRect(clipBehavior: Clip.antiAliasWithSaveLayer, child: scene),
    ),
  ),
];

/// What each surface that mounted the program decided about the pass it
/// reads: whether the layers above it leave it the root's.
List<bool> _passDecisions(WidgetTester tester) => [
  for (final object in tester.allRenderObjects)
    if (object is RenderSurfaceBackdrop) object.debugReadsRootPass,
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    expect(
      kProbeDeviceId,
      isNotEmpty,
      reason: 'Pass --dart-define=PROBE_DEVICE_ID',
    );
  });

  Future<_Shot> capture(
    WidgetTester tester,
    Widget Function(GlobalKey) build, {
    String? label,
  }) async {
    final dpr = tester.view.devicePixelRatio;
    final key = GlobalKey();
    await tester.pumpWidget(build(key));
    // The program loads asynchronously and the surface re-renders when it
    // lands: settle, give the load a real turn of the event loop, settle.
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final shot = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: dpr);
      final data = await image.toByteData();
      if (label != null) {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory(_kShotsDir).createSync(recursive: true);
        await File(
          '$_kShotsDir/$label.png',
        ).writeAsBytes(png!.buffer.asUint8List());
      }

      return _Shot(data!.buffer.asUint8List(), (_kWidth * dpr).round(), dpr);
    });

    return shot!;
  }

  ThemeData Function(ThemeData) withFinish({
    CoreSurfaceFrost? frost,
    double shade = 0,
  }) =>
      (base) => base.copyWith(
        surfaceFrost: frost == null ? null : () => frost,
        surfaceBodyShade: shade > 0
            ? () => CoreSurfaceBodyShade(strength: shade)
            : null,
      );

  testWidgets('F1 — the frost is a heavy blur mixed over the light one', (
    tester,
  ) async {
    final dpr = tester.view.devicePixelRatio;
    debugPrint(
      'F1  device=$kProbeDeviceId dpr=$dpr '
      'shaderFilter=${ui.ImageFilter.isShaderFilterSupported} '
      'shots=$_kShotsDir',
    );
    const share = 0.73;
    final copy = await capture(
      tester,
      (key) => _scene(key, theme: withFinish()),
      label: 'f1-copy',
    );
    final cloud = await capture(
      tester,
      (key) => _scene(
        key,
        theme: withFinish(
          frost: const CoreSurfaceFrost(sigma: 14, opacity: 1),
        ),
      ),
      label: 'f1-cloud',
    );
    final mixed = await capture(
      tester,
      (key) => _scene(
        key,
        theme: withFinish(
          frost: const CoreSurfaceFrost(sigma: 14, opacity: share),
        ),
      ),
      label: 'f1-mixed',
    );

    var worst = 0;
    final rows = StringBuffer();
    for (final x in _kStripeColumns) {
      final c = copy.at(x, _kStripeRow);
      final k = cloud.at(x, _kStripeRow);
      final m = mixed.at(x, _kStripeRow);
      final want = (
        r: CoreSurfaceFrost.mix(
          cloud: k.r.toDouble(),
          copy: c.r.toDouble(),
          opacity: share,
        ).round(),
        g: CoreSurfaceFrost.mix(
          cloud: k.g.toDouble(),
          copy: c.g.toDouble(),
          opacity: share,
        ).round(),
        b: CoreSurfaceFrost.mix(
          cloud: k.b.toDouble(),
          copy: c.b.toDouble(),
          opacity: share,
        ).round(),
      );
      final off = _distance(m, want);
      if (off > worst) worst = off;
      rows.writeln(
        'x=$x copy=${c.r} cloud=${k.r} measured=${m.r} want=${want.r}',
      );
      expect(
        off,
        lessThanOrEqualTo(_kTolerance),
        reason: 'x=$x copy=$c cloud=$k measured=$m want=$want',
      );
    }
    debugPrint('F1  frost share=$share worst=$worst\n$rows');

    // The premises, so a tolerance every capture satisfies is not mistaken
    // for a verdict: the copy keeps the stripes, the cloud has none.
    final black = copy.at(78, _kStripeRow).r;
    final white = copy.at(90, _kStripeRow).r;
    expect(
      white - black,
      greaterThan(200),
      reason: 'the copy lost its stripes',
    );
    expect(
      (cloud.at(90, _kStripeRow).r - cloud.at(78, _kStripeRow).r).abs(),
      lessThan(8),
      reason: 'the cloud still has stripes in it',
    );
    expect(
      cloud.at(90, _kStripeRow).r,
      inInclusiveRange(118, 138),
      reason: 'the cloud is the mean of the stripes',
    );
  });

  testWidgets('S1 — the shade darkens each pixel by its own luminance', (
    tester,
  ) async {
    if (!ui.ImageFilter.isShaderFilterSupported) {
      debugPrint('S1  device=$kProbeDeviceId  not run: no shader filters');
      return;
    }
    const strength = 0.5;
    final plain = await capture(
      tester,
      (key) => _scene(key, theme: withFinish()),
      label: 's1-plain',
    );
    final shaded = await capture(
      tester,
      (key) => _scene(key, theme: withFinish(shade: strength)),
      label: 's1-shaded',
    );
    // The control for S2's premise: with nothing above them, these surfaces
    // read the root's pass.
    expect(_passDecisions(tester), isNotEmpty);
    expect(_passDecisions(tester), everyElement(isTrue));

    var worst = 0;
    final rows = StringBuffer();
    for (final band in _kBands) {
      final before = plain.at(_kBandColumn, band.y);
      final after = shaded.at(_kBandColumn, band.y);
      final want = CoreSurfaceBodyShade.shade(
        strength: strength,
        red: before.r / 255,
        green: before.g / 255,
        blue: before.b / 255,
      );
      final expected = (
        r: (want.red * 255).round(),
        g: (want.green * 255).round(),
        b: (want.blue * 255).round(),
      );
      final off = _distance(after, expected);
      if (off > worst) worst = off;
      rows.writeln('${band.name}: before=$before after=$after want=$expected');
      expect(
        off,
        lessThanOrEqualTo(_kTolerance),
        reason: '${band.name}: before=$before after=$after want=$expected',
      );
    }
    debugPrint('S1  shade strength=$strength worst=$worst\n$rows');

    // Not a no-op, and keyed on luminance.
    final bright = _kBands.firstWhere((b) => b.name == 'white');
    final dim = _kBands.firstWhere((b) => b.name == 'dark grey');
    int lost(_Rgb a, _Rgb b) => (a.r + a.g + a.b) - (b.r + b.g + b.b);
    final brightLoss = lost(
      plain.at(_kBandColumn, bright.y),
      shaded.at(_kBandColumn, bright.y),
    );
    final dimLoss = lost(
      plain.at(_kBandColumn, dim.y),
      shaded.at(_kBandColumn, dim.y),
    );
    expect(brightLoss, greaterThan(60), reason: 'white barely moved');
    expect(dimLoss, lessThan(brightLoss ~/ 4));
  });

  testWidgets(
    'S2 — under a layer that moves the pass, the shade is still drawn',
    (tester) async {
      if (!ui.ImageFilter.isShaderFilterSupported) {
        debugPrint('S2  device=$kProbeDeviceId  not run: no shader filters');
        return;
      }
      const strength = 0.5;
      for (final moved in _kMovedPasses) {
        final plain = await capture(
          tester,
          (key) => _scene(key, theme: withFinish(), wrap: moved.wrap),
          label: 's2-${moved.slug}-plain',
        );
        final shaded = await capture(
          tester,
          (key) => _scene(
            key,
            theme: withFinish(shade: strength),
            wrap: moved.wrap,
          ),
          label: 's2-${moved.slug}-shaded',
        );

        // The premise, read from the surface itself: the layers above it
        // leave the pass somewhere other than the root's origin. Without it a
        // shade that is drawn proves nothing about the case it is named for.
        final decisions = _passDecisions(tester);
        expect(decisions, isNotEmpty, reason: 'no surface mounted the program');
        expect(
          decisions,
          everyElement(isFalse),
          reason: '${moved.name} left the pass at the root',
        );

        // The scene is shifted by (37, 21): the band column and rows move
        // with it, and the capture is clipped at 400 wide, so read the band
        // column that stays in frame — the second panel's centre column is at
        // 300 + 37 and still inside.
        var worst = 0;
        final rows = StringBuffer();
        for (final band in _kBands) {
          const x = _kBandColumn + _kShiftX;
          final y = band.y + _kShiftY;
          if (y >= _kHeight) continue;
          final before = plain.at(x, y);
          final after = shaded.at(x, y);
          final want = CoreSurfaceBodyShade.shade(
            strength: strength,
            red: before.r / 255,
            green: before.g / 255,
            blue: before.b / 255,
          );
          final expected = (
            r: (want.red * 255).round(),
            g: (want.green * 255).round(),
            b: (want.blue * 255).round(),
          );
          final off = _distance(after, expected);
          if (off > worst) worst = off;
          rows.writeln(
            '${band.name}: before=$before after=$after want=$expected',
          );
          expect(
            off,
            lessThanOrEqualTo(_kTolerance),
            reason:
                '${moved.name} ${band.name}: before=$before after=$after '
                'want=$expected',
          );
        }
        debugPrint(
          'S2  shade under a moved pass (${moved.name}) worst=$worst\n$rows',
        );
        final white = _kBands.firstWhere((b) => b.name == 'white');
        expect(
          plain.at(_kBandColumn + _kShiftX, white.y + _kShiftY).r -
              shaded.at(_kBandColumn + _kShiftX, white.y + _kShiftY).r,
          greaterThan(60),
          reason: '${moved.name}: the shade was dropped with the bend',
        );
      }
    },
  );

  testWidgets(
    'F2 — under a layer that moves the pass, the frost is still drawn',
    (tester) async {
      const share = 0.73;
      for (final moved in _kMovedPasses) {
        final copy = await capture(
          tester,
          (key) => _scene(key, theme: withFinish(), wrap: moved.wrap),
          label: 'f2-${moved.slug}-copy',
        );
        final cloud = await capture(
          tester,
          (key) => _scene(
            key,
            theme: withFinish(
              frost: const CoreSurfaceFrost(sigma: 14, opacity: 1),
            ),
            wrap: moved.wrap,
          ),
          label: 'f2-${moved.slug}-cloud',
        );
        final mixed = await capture(
          tester,
          (key) => _scene(
            key,
            theme: withFinish(
              frost: const CoreSurfaceFrost(sigma: 14, opacity: share),
            ),
            wrap: moved.wrap,
          ),
          label: 'f2-${moved.slug}-mixed',
        );

        var worst = 0;
        for (final column in _kStripeColumns) {
          final x = column + _kShiftX;
          const y = _kStripeRow + _kShiftY;
          final c = copy.at(x, y);
          final k = cloud.at(x, y);
          final m = mixed.at(x, y);
          final want = (
            r: CoreSurfaceFrost.mix(
              cloud: k.r.toDouble(),
              copy: c.r.toDouble(),
              opacity: share,
            ).round(),
            g: CoreSurfaceFrost.mix(
              cloud: k.g.toDouble(),
              copy: c.g.toDouble(),
              opacity: share,
            ).round(),
            b: CoreSurfaceFrost.mix(
              cloud: k.b.toDouble(),
              copy: c.b.toDouble(),
              opacity: share,
            ).round(),
          );
          final off = _distance(m, want);
          if (off > worst) worst = off;
          expect(
            off,
            lessThanOrEqualTo(_kTolerance),
            reason:
                '${moved.name} x=$x copy=$c cloud=$k measured=$m want=$want',
          );
        }
        debugPrint(
          'F2  frost under a moved pass (${moved.name}) worst=$worst',
        );
        // And the cloud really is a cloud there: nothing of the stripes left.
        expect(
          (cloud.at(66 + _kShiftX, _kStripeRow + _kShiftY).r -
                  cloud.at(78 + _kShiftX, _kStripeRow + _kShiftY).r)
              .abs(),
          lessThan(8),
        );

        // The premise, read on a scene that also shades: a frost alone mounts
        // no object that can say what pass its layers read, and the wrapper
        // is the same one.
        await capture(
          tester,
          (key) => _scene(
            key,
            theme: withFinish(
              frost: const CoreSurfaceFrost(sigma: 14, opacity: share),
              shade: 0.5,
            ),
            wrap: moved.wrap,
          ),
        );
        final decisions = _passDecisions(tester);
        expect(decisions, isNotEmpty, reason: 'no surface mounted the program');
        expect(
          decisions,
          everyElement(isFalse),
          reason: '${moved.name} left the pass at the root',
        );
      }
    },
  );

  testWidgets('S3 — a surface that bends and shades shades its flat interior', (
    tester,
  ) async {
    if (!ui.ImageFilter.isShaderFilterSupported) {
      debugPrint('S3  device=$kProbeDeviceId  not run: no shader filters');
      return;
    }
    const strength = 0.5;
    final bend = CoreSurfaceRecipe.of(
      CoreSurfaceStyleId.liquidGlass,
    ).refraction!;
    final plain = await capture(
      tester,
      (key) => _scene(key, theme: withFinish(), refraction: bend),
      label: 's3-plain',
    );
    final shaded = await capture(
      tester,
      (key) => _scene(
        key,
        theme: withFinish(shade: strength),
        refraction: bend,
      ),
      label: 's3-shaded',
    );

    // Only the rows beyond the rim's band: the preset's band is a fifth of
    // the shorter side (32 logical pixels here), inside which the bend moves
    // each channel to another band of the backdrop — the premise of the
    // comparison would not hold there. The face's own magnification is small
    // enough at these rows that the bands read are the bands drawn.
    var worst = 0;
    var read = 0;
    for (final band in _kBands.where((b) => b.y >= 75 && b.y <= 225)) {
      final before = plain.at(_kBandColumn, band.y);
      final after = shaded.at(_kBandColumn, band.y);
      final want = CoreSurfaceBodyShade.shade(
        strength: strength,
        red: before.r / 255,
        green: before.g / 255,
        blue: before.b / 255,
      );
      final expected = (
        r: (want.red * 255).round(),
        g: (want.green * 255).round(),
        b: (want.blue * 255).round(),
      );
      final off = _distance(after, expected);
      if (off > worst) worst = off;
      read++;
      expect(
        off,
        lessThanOrEqualTo(_kTolerance),
        reason: '${band.name}: before=$before after=$after want=$expected',
      );
    }
    expect(read, greaterThanOrEqualTo(5));
    debugPrint('S3  bend + shade interior worst=$worst over $read bands');
  });

  for (final dark in [false, true]) {
    testWidgets(
      'P1 — the iOS 27 preset draws both terms in a '
      '${dark ? 'dark' : 'light'} app',
      (tester) async {
        final base = ThemeData.fromCore(
          dark ? CoreThemePresets.dark : CoreThemePresets.light,
        );
        Widget Function(GlobalKey) app({
          required CoreSurfaceTuning tuning,
          bool reduceTransparency = false,
          bool highContrast = false,
        }) =>
            (key) => material.MediaQuery(
              data: MediaQueryData(highContrast: highContrast),
              child: CoUIApp(
                theme: base,
                surfaceStyle: CoreSurfaceStyleId.liquidGlass,
                surfaceTuning: tuning,
                reduceTransparency: reduceTransparency,
                home: Align(
                  alignment: Alignment.topLeft,
                  child: RepaintBoundary(
                    key: key,
                    child: const SizedBox(
                      width: _kWidth,
                      height: _kHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: _Backdrop()),
                          ),
                          Positioned(
                            left: 20,
                            top: 20,
                            width: 160,
                            height: 260,
                            child: OutlinedContainer(
                              role: CoreSurfaceRole.functional,
                              child: SizedBox.expand(),
                            ),
                          ),
                          Positioned(
                            left: 220,
                            top: 20,
                            width: 160,
                            height: 260,
                            child: OutlinedContainer(
                              role: CoreSurfaceRole.functional,
                              child: SizedBox.expand(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );

        final theme = dark ? 'dark' : 'light';
        final withFinishShot = await capture(
          tester,
          app(tuning: CoreSurfaceTuning.ios27),
          label: 'p1-$theme-ios27',
        );
        // The same tuning with the two terms' strengths taken to nothing:
        // everything else the preset states stays.
        final without = await capture(
          tester,
          app(
            tuning: const CoreSurfaceTuning(
              surfaceBlur: 0.6,
              surfaceSaturation: 2,
              surfaceSaturationInDarkMode: 1.4,
              lightAngle: 0,
              lightAngleInDarkMode: 180,
              refractionModel: CoreRefractionModel.paraxial,
            ),
          ),
          label: 'p1-$theme-without',
        );
        final reduced = await capture(
          tester,
          app(tuning: CoreSurfaceTuning.ios27, reduceTransparency: true),
          label: 'p1-$theme-reduced',
        );
        final contrast = await capture(
          tester,
          app(tuning: CoreSurfaceTuning.ios27, highContrast: true),
          label: 'p1-$theme-contrast',
        );
        final contrastWithout = await capture(
          tester,
          app(
            tuning: const CoreSurfaceTuning(
              surfaceBlur: 0.6,
              surfaceSaturation: 2,
              surfaceSaturationInDarkMode: 1.4,
              lightAngle: 0,
              lightAngleInDarkMode: 180,
              refractionModel: CoreRefractionModel.paraxial,
            ),
            highContrast: true,
          ),
          label: 'p1-$theme-contrast-without',
        );

        final moved = _diffRatio(withFinishShot, without);
        final contrastMoved = _diffRatio(contrast, contrastWithout);
        final reducedMoved = _diffRatio(reduced, withFinishShot);
        debugPrint(
          'P1  $theme moved=${moved.toStringAsFixed(4)} '
          'underContrast=${contrastMoved.toStringAsFixed(4)} '
          'reducedVsPreset=${reducedMoved.toStringAsFixed(4)}',
        );
        expect(moved, greaterThan(0.02), reason: 'the terms drew nothing');
        expect(
          contrastMoved,
          lessThan(0.005),
          reason: 'high contrast still draws a term',
        );
        // Reduced transparency takes the whole pass, so it differs from the
        // preset by far more than the terms do.
        expect(reducedMoved, greaterThan(moved));
      },
    );
  }
}
