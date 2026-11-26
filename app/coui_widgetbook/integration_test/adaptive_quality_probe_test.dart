// What each quality tier really draws, and whether the device's own frames
// can move a surface from one to the next.
//
// The widget tests read the material a tier hands to the surface (the
// refraction request, the backdrop pass); `flutter_tester` cannot run a shader
// filter, so they cannot say what reaches the screen. This probe does, on a
// device with Metal: one glass surface over a field of black-and-white
// stripes, captured the way an app states the tier it wants
// (`CoUIApp(adaptiveQuality: CoreAdaptiveQuality(forced: tier))`).
//
//   Q1  The bend. The refraction program disperses the stripes into colour
//       along the surface's rim, so the rim holds pixels whose channels
//       disagree. `full` has them; `noRefraction` and `solid` do not.
//   Q2  The backdrop pass and the fill. A translucent fill lets the stripes
//       through; the opaque fill of `solid` does not. The stripes' contrast
//       inside the surface is the measure: present at `full` and
//       `noRefraction`, gone at `solid`.
//   Q3  The loop. The same surface among a dozen more, against a frame rate
//       no glass scene can hold. The governor is fed by the engine's own frame
//       timings — nothing is injected — and has to take the app down to the
//       lowest tier; the capture taken then reads like Q1/Q2's `solid`.
//
// All three are read off pixels, not off the widget tree, so a seat that
// stopped applying the tier — or applied it to the theme but not to what is
// drawn, or never heard from the engine — fails here and nowhere else.
//
// Run as:
//
//   flutter test integration_test/adaptive_quality_probe_test.dart \
//     -d macos --dart-define=PROBE_DEVICE_ID=macos

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const kProbeDeviceId = String.fromEnvironment('PROBE_DEVICE_ID');

/// The captured area, in logical pixels.
const double _kWidth = 600;
const double _kHeight = 400;

/// Where the measured surface sits and how big it is.
const double _kLeft = 200;
const double _kTop = 150;
const double _kSurfaceWidth = 200;
const double _kSurfaceHeight = 100;

/// How much more stripe contrast a translucent fill shows than an opaque one.
///
/// Measured on the device this was written on (an Apple M3 Max, Metal):
/// `full` and `noRefraction` read a contrast of 117, `solid` reads zero. The
/// gap is deliberately a fraction of that.
const int _kContrastGap = 20;

/// The most contrast the stripes may leave behind an opaque fill.
const int _kOpaqueContrast = 2;

/// What one capture is measured as.
typedef _Reading = ({int disperse, int contrast});

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    expect(
      kProbeDeviceId,
      isNotEmpty,
      reason: 'Pass --dart-define=PROBE_DEVICE_ID',
    );
  });

  testWidgets('Q1/Q2 — each tier draws what the ladder says', (tester) async {
    if (!ui.ImageFilter.isShaderFilterSupported) {
      debugPrint('Q1  device=$kProbeDeviceId  not run: no shader filters');
      return;
    }

    Future<_Reading> read(CoreQualityTier tier) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _app(key, CoreAdaptiveQuality(forced: tier), cards: 0, moving: false),
      );
      await tester.pumpAndSettle();

      final reading = await _capture(tester, key);

      return reading;
    }

    final readings = <CoreQualityTier, _Reading>{
      for (final tier in CoreQualityTier.values) tier: await read(tier),
    };
    for (final MapEntry(key: tier, value: reading) in readings.entries) {
      debugPrint(
        'Q1  device=$kProbeDeviceId  tier=${tier.name}  '
        'dispersedPixelsInLeftBand=${reading.disperse}  '
        'stripeContrastInside=${reading.contrast}',
      );
    }

    final full = readings[CoreQualityTier.full]!;
    final noRefraction = readings[CoreQualityTier.noRefraction]!;
    final solid = readings[CoreQualityTier.solid]!;

    expect(
      full.disperse,
      greaterThan(0),
      reason: 'no bend at `full` — the harness is not showing refraction',
    );
    expect(
      noRefraction.disperse,
      lessThan(full.disperse ~/ 4),
      reason: '`noRefraction` still bends: the tier did not reach the draw',
    );
    expect(
      solid.disperse,
      lessThan(full.disperse ~/ 4),
      reason: '`solid` still bends: the tier did not reach the draw',
    );
    expect(
      noRefraction.contrast,
      greaterThan(solid.contrast + _kContrastGap),
      reason:
          '`noRefraction` keeps the backdrop pass and the translucent fill, '
          'so the stripes still show through',
    );
    expect(
      full.contrast,
      greaterThan(solid.contrast + _kContrastGap),
      reason: '`full` shows the stripes through the fill',
    );
    expect(
      solid.contrast,
      lessThanOrEqualTo(_kOpaqueContrast),
      reason: '`solid` is an opaque fill: nothing of the backdrop is left',
    );
  });

  testWidgets(
    'Q3 — a device that cannot keep up gives the glass up, and the screen '
    'shows it',
    (tester) async {
      if (!ui.ImageFilter.isShaderFilterSupported) {
        debugPrint('Q3  device=$kProbeDeviceId  not run: no shader filters');
        return;
      }
      binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
      // The program is compiled before the first frame is judged.
      await tester.runAsync(SurfaceRefractionProgram.warmUp);

      final changes = <CoreQualityChange>[];
      final key = GlobalKey();
      await tester.pumpWidget(
        _app(
          key,
          CoreAdaptiveQuality(
            // The highest rate the governor accepts: a budget of about two
            // milliseconds of raster per frame, which no scene of a dozen
            // glass cards fits in on any device.
            targetFrameRate: CoreFrameBudget.highestRefreshRate,
            tuning: const CoreQualityTuning(
              skipSeconds: 0.3,
              warmupSeconds: 0.6,
              windowSeconds: 0.5,
              cooldownSeconds: 1,
            ),
            onQualityChanged: changes.add,
          ),
          cards: 12,
          moving: true,
        ),
      );

      // Real time, with the engine producing frames, until the governor has
      // reached the floor or the allowance runs out.
      for (var waited = 0; waited < 30000; waited += 250) {
        if (changes.isNotEmpty && changes.last.to == CoreQualityTier.solid) {
          break;
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
      }
      // And a moment at the new tier, so the screen has caught up.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump();

      final reading = await _capture(tester, key);
      for (final change in changes) {
        final percentile = change.percentileMillis.toStringAsFixed(2);
        final budget = change.budgetMillis.toStringAsFixed(2);
        debugPrint(
          'Q3  device=$kProbeDeviceId  ${change.from.name} -> '
          '${change.to.name}  reason=${change.reason.name}  '
          '${change.metric.name} p=${percentile}ms '
          'over ${change.framesMeasured} frames  budget=${budget}ms',
        );
      }
      debugPrint(
        'Q3  device=$kProbeDeviceId  settled  '
        'dispersedPixelsInLeftBand=${reading.disperse}  '
        'stripeContrastInside=${reading.contrast}',
      );

      expect(
        changes,
        isNotEmpty,
        reason:
            'the engine reported frames far over budget and the governor '
            'did not move: it is not hearing the engine',
      );
      expect(
        changes.first.from,
        CoreQualityTier.full,
        reason: 'an app that states nothing but the rate starts at the top',
      );
      expect(
        changes.last.to,
        CoreQualityTier.solid,
        reason: 'a device that misses every frame ends on the lowest tier',
      );
      expect(
        reading.disperse,
        lessThan(_kBendFloor),
        reason: 'the governor reached `solid` and the screen still bends',
      );
      expect(
        reading.contrast,
        lessThanOrEqualTo(_kOpaqueContrast),
        reason: 'the governor reached `solid` and the fill is not opaque',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

/// The most dispersed pixels the rim may hold when nothing bends it.
///
/// A tier that bends reads 2640 on the device this was written on; one that
/// does not reads zero.
const int _kBendFloor = 8;

/// A glass surface (and [cards] more below it) over the stripes, stated at
/// [quality].
Widget _app(
  GlobalKey key,
  CoreAdaptiveQuality quality, {
  required int cards,
  required bool moving,
}) => CoUIApp(
  theme: ThemeData.fromCore(CoreThemePresets.light),
  surfaceStyle: CoreSurfaceStyleId.liquidGlass,
  surfaceTuning: const CoreSurfaceTuning(surfaceBlur: 0.1),
  adaptiveQuality: quality,
  home: Align(
    alignment: Alignment.topLeft,
    child: RepaintBoundary(
      key: key,
      child: SizedBox(
        width: _kWidth,
        height: _kHeight,
        child: _Stage(cards: cards, moving: moving),
      ),
    ),
  ),
);

/// Pixels of the area under [key], measured.
Future<_Reading> _capture(WidgetTester tester, GlobalKey key) async {
  final dpr = tester.view.devicePixelRatio;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: dpr);
    final data = await image.toByteData();

    return data!.buffer.asUint8List();
  });

  return _measure(bytes!, dpr);
}

/// The two readings of one capture.
///
/// *Disperse* counts, inside the surface's left rim, the pixels whose channels
/// disagree: black-and-white stripes have none, so colour there is the bend's
/// dispersion. *Contrast* is the spread between the lightest and the darkest
/// pixel in the surface's interior, where only the backdrop pass and the
/// translucent fill put the stripes.
_Reading _measure(Uint8List bytes, double dpr) {
  final width = (_kWidth * dpr).round();

  var disperse = 0;
  for (
    var y = ((_kTop + 30) * dpr).round();
    y < ((_kTop + 70) * dpr).round();
    y++
  ) {
    for (
      var x = ((_kLeft + 2) * dpr).round();
      x < ((_kLeft + 24) * dpr).round();
      x++
    ) {
      final at = (y * width + x) * 4;
      final r = bytes[at];
      final g = bytes[at + 1];
      final b = bytes[at + 2];
      if ((r - g).abs() > 24 || (g - b).abs() > 24) disperse++;
    }
  }

  var lightest = 0;
  var darkest = 255;
  for (
    var y = ((_kTop + 35) * dpr).round();
    y < ((_kTop + 65) * dpr).round();
    y++
  ) {
    for (
      var x = ((_kLeft + 60) * dpr).round();
      x < ((_kLeft + 140) * dpr).round();
      x++
    ) {
      final at = (y * width + x) * 4;
      final luma = (bytes[at] + bytes[at + 1] + bytes[at + 2]) ~/ 3;
      if (luma > lightest) lightest = luma;
      if (luma < darkest) darkest = luma;
    }
  }

  return (disperse: disperse, contrast: lightest - darkest);
}

/// The stripes, the measured surface, and — when [cards] says so — a block of
/// more glass below it and a speck that moves, so the engine draws every frame
/// and every frame pays for every backdrop pass.
class _Stage extends StatefulWidget {
  const _Stage({required this.cards, required this.moving});

  final int cards;
  final bool moving;

  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void initState() {
    super.initState();
    if (widget.moving) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(child: CustomPaint(painter: _Stripes())),
      if (widget.moving)
        Positioned(
          left: 8,
          top: 8,
          width: 24,
          height: 24,
          child: CustomPaint(painter: _Speck(_controller)),
        ),
      for (var i = 0; i < widget.cards; i++)
        Positioned(
          left: 16 + (i % 6) * 96.0,
          top: 290 + (i ~/ 6) * 56.0,
          width: 88,
          height: 48,
          child: const OutlinedContainer(
            role: CoreSurfaceRole.functional,
            child: SizedBox.expand(),
          ),
        ),
      const Positioned(
        left: _kLeft,
        top: _kTop,
        width: _kSurfaceWidth,
        height: _kSurfaceHeight,
        child: OutlinedContainer(
          role: CoreSurfaceRole.functional,
          child: SizedBox.expand(),
        ),
      ),
    ],
  );
}

class _Stripes extends CustomPainter {
  const _Stripes();

  @override
  void paint(Canvas canvas, Size size) {
    final black = Paint()..color = const Color(0xFF000000);
    final white = Paint()..color = const Color(0xFFFFFFFF);
    var x = 0.0;
    var dark = true;
    while (x < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 4, size.height),
        dark ? black : white,
      );
      x += 4;
      dark = !dark;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Speck extends CustomPainter {
  _Speck(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * 2 * math.pi;
    canvas.drawCircle(
      Offset(size.width / 2 + 8 * math.sin(t), size.height / 2),
      5,
      Paint()..color = const Color(0xFFE8334A),
    );
  }

  @override
  bool shouldRepaint(_Speck oldDelegate) => true;
}
