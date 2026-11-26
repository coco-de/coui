// Whether a liquid-glass popover panel keeps its backdrop blur while it fades.
//
// `flutter_tester` cannot run `ImageFilter.shader`, and an offscreen opacity
// layer is a property of the compositor, so neither the unit suites nor a
// layer-tree walk can say what the *pixels* of a faded glass panel are. This
// probe opens the shipped `Popup` through the shipped popover engine on a
// device, holds the open and the close animation at chosen progresses and
// reads what the compositor produced.
//
// The backdrop is vertical black and white stripes two logical pixels wide:
// the sharpest thing a Gaussian of the glass's sigma can be asked to remove.
// A panel that blurs what is behind it leaves almost no stripe in its middle;
// a panel that is a plain translucent plate leaves all of them, only veiled.
//
//   P1  Settled. The panel at rest blurs its backdrop. This is the premise —
//       an opacity layer at full alpha saves no pass — and the reference every
//       other case is read against.
//   P2  Opening. At each held progress the middle of the panel holds far fewer
//       stripes than the page beside it, and the stripes return as the
//       progress falls: the blur recedes with the fill instead of vanishing in
//       the first frame.
//   P3  Closing. The same, with the animation running the other way and
//       through its own curve.
//   P4  Dissolving. At the lowest level the stripes are mostly back, open and
//       close — a panel that stayed fully blurred until the fill reached zero
//       would fail here: it would pop from blurred to sharp in the last frame.
//
// The progress is held with `timeDilation`: raised to a very large number once
// the animation reaches the level asked for, so the ticker stops for as long as
// a capture takes, and put back to carry on. The level actually held is read
// from the tree and printed with every number.
//
// Captured from a boundary around the whole app, which is at the root's
// origin — where the compositor's backdrop and the surface's coordinates
// agree — and which, unlike a boundary inside the page, contains the overlay
// the popover panel is mounted in.
//
// Run as:
//
//   flutter test integration_test/popover_fade_probe_test.dart \
//     -d macos --dart-define=PROBE_DEVICE_ID=macos [--dart-define=PROBE_TAG=x]
//
// The captures land in the app's temporary directory (printed by P1) as
// `<tag>-open-050.png`, `<tag>-close-025.png` … for a reviewer to look at.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const kProbeDeviceId = String.fromEnvironment('PROBE_DEVICE_ID');

/// Names the run in the captures' file names, so a run of the same probe on
/// another tree does not overwrite the first.
const kProbeTag = String.fromEnvironment('PROBE_TAG', defaultValue: 'run');

final String _kShotsDir = '${Directory.systemTemp.path}/popover-fade';

/// Two logical pixels: with the glass's sigma of 4 the first harmonic of a
/// 4-pixel period is attenuated to a thousandth at the middle of the blur and
/// to a quarter at a quarter of it, so the stripes are a gauge of how much
/// blur is left, down to a few tenths of a pixel.
const double _kStripe = 2;

/// How long the panel takes to open and to close. Long, so that the progress
/// between two frames moves by a few percent even on a loaded machine.
const Duration _kOpen = Duration(milliseconds: 4000);
const Duration _kClose = Duration(milliseconds: 6000);

/// `timeDilation` while a capture is taken: the ticker advances by a
/// millionth of the real time, which is nothing over a capture.
const double _kFrozen = 1000000;

/// The levels the panel is held at, open and close.
const List<double> _kLevels = [0.75, 0.5, 0.25, 0.1];

/// How much of the page's stripe contrast a held panel may keep in its middle
/// at each level, for the panel to count as blurring what is behind it.
///
/// The blur is the glass's sigma times the progress, so the stripes return as
/// the progress falls; the budget is read against the page beside the panel,
/// not against a fixed number. A plain translucent plate keeps the veil's
/// share of the page's contrast (0.75 at half progress), which is above every
/// budget here.
const List<({double level, double budget})> _kBudget = [
  (level: 0.75, budget: 0.15),
  (level: 0.5, budget: 0.30),
  (level: 0.25, budget: 0.65),
];

/// How much of the page's contrast the settled panel may keep.
const double _kSettledBudget = 0.05;

/// How much of the page's contrast a panel held at the lowest level has to
/// give back: a material that stayed fully blurred until the fill was gone
/// would keep almost none here and pop to sharp in the last frame.
const double _kDissolvedFloor = 0.5;

/// The page beside the panel is not part of the fade, so its stripes have to be
/// as sharp as ever at every capture — or a panel that kept few of them is
/// merely reading a darkened page.
const double _kPageFloor = 100;

class _Stripes extends CustomPainter {
  const _Stripes();

  @override
  void paint(Canvas canvas, Size size) {
    final black = Paint()..color = const Color(0xFF000000);
    final white = Paint()..color = const Color(0xFFFFFFFF);
    var dark = true;
    for (var x = 0.0; x < size.width; x += _kStripe) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, _kStripe, size.height),
        dark ? black : white,
      );
      dark = !dark;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget _app(GlobalKey boundary, GlobalKey anchor) => RepaintBoundary(
  key: boundary,
  child: CoUIApp(
    theme: ThemeData.fromCore(CoreThemePresets.light),
    surfaceStyle: CoreSurfaceStyleId.liquidGlass,
    home: Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _Stripes())),
        Positioned(
          left: 40,
          top: 40,
          width: 80,
          height: 32,
          child: SizedBox(key: anchor),
        ),
      ],
    ),
  ),
);

PopoverEntryHandle<void> _open(BuildContext anchor) =>
    const PopoverOverlayHandler().show<void>(
      context: anchor,
      alignment: Alignment.topLeft,
      anchorAlignment: Alignment.bottomLeft,
      // A held popup never settles: the follow ticker would keep a frame
      // scheduled for ever, and nothing here moves the anchor.
      follow: false,
      modal: false,
      showDuration: _kOpen,
      dismissDuration: _kClose,
      builder: (_) => const Popup(
        children: [SizedBox(width: 260, height: 160)],
      ),
    );

class _Shot {
  _Shot(this.bytes, this.width, this.dpr);

  final Uint8List bytes;
  final int width;
  final double dpr;

  /// The luma of the pixel at the logical point, 0 to 255.
  double luma(int x, int y) {
    final px = (x * dpr + dpr / 2).floor();
    final py = (y * dpr + dpr / 2).floor();
    final o = (py * width + px) * 4;

    return (bytes[o] + bytes[o + 1] + bytes[o + 2]) / 3;
  }

  /// How much stripe is left in [region]: the standard deviation of the
  /// column means. Averaging each column over the rows first removes anything
  /// that varies down the page, which the stripes do not.
  double stripeContrast(Rect region) {
    final left = region.left.floor();
    final right = region.right.floor();
    final top = region.top.floor();
    final bottom = region.bottom.floor();
    final means = <double>[];
    for (var x = left; x < right; x++) {
      var sum = 0.0;
      for (var y = top; y < bottom; y++) {
        sum += luma(x, y);
      }
      means.add(sum / (bottom - top));
    }
    final mean = means.reduce((a, b) => a + b) / means.length;
    var variance = 0.0;
    for (final m in means) {
      variance += (m - mean) * (m - mean);
    }

    return math.sqrt(variance / means.length);
  }
}

/// The panel's fade as the engine paints it: the opacity of the nearest
/// `FadeTransition` above the `Popup`, which is the engine's own.
double? _engineOpacity(WidgetTester tester) {
  final popup = find.byType(Popup);
  if (popup.evaluate().isEmpty) return null;
  double? found;
  popup.evaluate().first.visitAncestorElements((element) {
    final render = element is RenderObjectElement ? element.renderObject : null;
    if (render is RenderAnimatedOpacity) {
      found = render.opacity.value;

      return false;
    }

    return true;
  });

  return found;
}

/// How far in view the panel is, as the surface and the engine agree on it.
///
/// A glass panel fades its own terms and leaves the engine's opacity at full,
/// so the number is read off the surface's fade box when there is one and off
/// the engine's opacity when there is not — the same probe reads a tree in
/// which the engine fades the panel as a whole. The box is found by what it
/// calls itself, so the probe needs nothing of the package that is not public.
double? _progress(WidgetTester tester) {
  final popup = find.byType(Popup);
  if (popup.evaluate().isEmpty) return null;
  double? fromSurface;
  void visit(Element element) {
    if (fromSurface != null) return;
    final render = element is RenderObjectElement ? element.renderObject : null;
    if (render != null &&
        render.toStringShort().startsWith('RenderSurfaceFadeBox')) {
      for (final property in render.toDiagnosticsNode().getProperties()) {
        if (property.name == 'progress') {
          fromSurface = property.value as double?;
        }
      }

      return;
    }
    element.visitChildren(visit);
  }

  popup.evaluate().first.visitChildren(visit);

  return fromSurface ?? _engineOpacity(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    expect(
      kProbeDeviceId,
      isNotEmpty,
      reason: 'Pass --dart-define=PROBE_DEVICE_ID',
    );
  });
  tearDown(() => timeDilation = 1);

  Future<_Shot> capture(
    WidgetTester tester,
    GlobalKey boundaryKey, {
    String? label,
  }) async {
    final dpr = tester.view.devicePixelRatio;
    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final shot = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: dpr);
      final data = await image.toByteData();
      if (label != null) {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory(_kShotsDir).createSync(recursive: true);
        await File(
          '$_kShotsDir/$kProbeTag-$label.png',
        ).writeAsBytes(png!.buffer.asUint8List());
      }
      final width = image.width;
      image.dispose();

      return _Shot(data!.buffer.asUint8List(), width, dpr);
    });

    return shot!;
  }

  /// Pumps until the engine's fade reaches [level] going [rising] or falling,
  /// then freezes the animation there.
  Future<double> holdAt(
    WidgetTester tester,
    double level, {
    required bool rising,
  }) async {
    timeDilation = 1;
    for (var i = 0; i < 2000; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final now = _progress(tester);
      if (now == null) continue;
      if (rising ? now >= level : now <= level) break;
    }
    timeDilation = _kFrozen;
    // Two frames at the frozen clock: the second paints the held value.
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));

    return _progress(tester) ?? double.nan;
  }

  /// The stripes in the middle of the panel and on the page beside it, as the
  /// share of the page's that the panel keeps.
  ({double kept, double page, double panel}) read(
    WidgetTester tester,
    _Shot shot,
  ) {
    final rect = tester.getRect(find.byType(Popup));
    final middle = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.4,
      height: rect.height * 0.4,
    );
    final view = tester.view.physicalSize / tester.view.devicePixelRatio;
    final beside = rect.right + 24 + 80 <= view.width
        ? Rect.fromLTWH(rect.right + 24, rect.top + rect.height * 0.3, 80, 40)
        : Rect.fromLTWH(
            rect.left - 24 - 80,
            rect.top + rect.height * 0.3,
            80,
            40,
          );
    final page = shot.stripeContrast(beside);
    final panel = shot.stripeContrast(middle);

    return (kept: panel / page, page: page, panel: panel);
  }

  testWidgets('P1–P4 — a glass popover panel keeps its blur while it fades', (
    tester,
  ) async {
    if (!ui.ImageFilter.isShaderFilterSupported) {
      debugPrint('P1  device=$kProbeDeviceId  not run: no shader filters');

      return;
    }
    debugPrint(
      'P1  device=$kProbeDeviceId tag=$kProbeTag '
      'dpr=${tester.view.devicePixelRatio} shots=$_kShotsDir',
    );
    final boundary = GlobalKey();
    final anchor = GlobalKey();
    await tester.runAsync(SurfaceRefractionProgram.warmUp);
    await tester.pumpWidget(_app(boundary, anchor));
    await tester.pump(const Duration(milliseconds: 100));

    final handle = _open(anchor.currentContext!);

    // ── P2: opening ────────────────────────────────────────────────────
    final opening = <double, ({double held, double kept, double page})>{};
    for (final level in _kLevels.reversed) {
      // Rising: the levels are visited from the lowest.
      final held = await holdAt(tester, level, rising: true);
      final shot = await capture(
        tester,
        boundary,
        label: 'open-${(level * 100).round().toString().padLeft(3, '0')}',
      );
      final r = read(tester, shot);
      opening[level] = (held: held, kept: r.kept, page: r.page);
      debugPrint(
        'P2  open level=$level held=${held.toStringAsFixed(3)} '
        'page=${r.page.toStringAsFixed(1)} panel=${r.panel.toStringAsFixed(1)} '
        'kept=${r.kept.toStringAsFixed(3)}',
      );
    }

    // ── P1: settled ────────────────────────────────────────────────────
    timeDilation = 1;
    for (var i = 0; i < 2000; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if ((_progress(tester) ?? 0) >= 1) break;
    }
    await tester.pump(const Duration(milliseconds: 300));
    final settledShot = await capture(tester, boundary, label: 'settled');
    final settled = read(tester, settledShot);
    debugPrint(
      'P1  settled progress=${_progress(tester)} '
      'page=${settled.page.toStringAsFixed(1)} '
      'panel=${settled.panel.toStringAsFixed(1)} '
      'kept=${settled.kept.toStringAsFixed(3)}',
    );
    expect(
      settled.page,
      greaterThan(100),
      reason: 'the page lost its stripes: the premise is gone',
    );
    expect(
      settled.kept,
      lessThan(_kSettledBudget),
      reason: 'the settled panel does not blur its backdrop',
    );

    // ── P3: closing ────────────────────────────────────────────────────
    handle.close();
    final closing = <double, ({double held, double kept, double page})>{};
    for (final level in _kLevels) {
      final held = await holdAt(tester, level, rising: false);
      final shot = await capture(
        tester,
        boundary,
        label: 'close-${(level * 100).round().toString().padLeft(3, '0')}',
      );
      final r = read(tester, shot);
      closing[level] = (held: held, kept: r.kept, page: r.page);
      debugPrint(
        'P3  close level=$level held=${held.toStringAsFixed(3)} '
        'page=${r.page.toStringAsFixed(1)} panel=${r.panel.toStringAsFixed(1)} '
        'kept=${r.kept.toStringAsFixed(3)}',
      );
    }
    timeDilation = 1;
    handle.dismissImmediately();
    await tester.pump(const Duration(milliseconds: 100));

    // ── verdicts ───────────────────────────────────────────────────────
    for (final phase in {'opening': opening, 'closing': closing}.entries) {
      for (final entry in phase.value.entries) {
        expect(
          entry.value.page,
          greaterThan(_kPageFloor),
          reason:
              '${phase.key} at ${entry.value.held.toStringAsFixed(2)}: the '
              'page beside the panel lost its stripes',
        );
      }
      for (final budget in _kBudget) {
        final held = phase.value[budget.level]!;
        expect(
          held.kept,
          lessThan(budget.budget),
          reason:
              '${phase.key} at ${held.held.toStringAsFixed(2)}: the panel '
              'kept ${held.kept.toStringAsFixed(2)} of the stripes on the '
              'page — a plate, not glass',
        );
      }
      final lowest = phase.value[_kLevels.last]!;
      expect(
        lowest.kept,
        greaterThan(_kDissolvedFloor),
        reason:
            '${phase.key} at ${lowest.held.toStringAsFixed(2)}: the panel '
            'kept only ${lowest.kept.toStringAsFixed(2)} of the stripes on '
            'the page — the blur has not dissolved with the fill',
      );
      // The blur recedes with the progress: lower progress, more stripes.
      final ordered = [for (final l in _kLevels) phase.value[l]!.kept];
      for (var i = 1; i < ordered.length; i++) {
        expect(
          ordered[i],
          greaterThanOrEqualTo(ordered[i - 1] - 0.02),
          reason:
              '${phase.key}: the stripes do not come back as the progress '
              'falls ($ordered)',
        );
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
