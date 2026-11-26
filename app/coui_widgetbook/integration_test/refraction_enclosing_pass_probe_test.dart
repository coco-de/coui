/// Whether the bend still follows the surface when the surface sits inside
/// another pass.
///
/// `SurfaceBackdrop` tells the refraction program where the surface is, in
/// "root view x device pixel ratio" pixels, and the program subtracts that
/// from `FlutterFragCoord()`. The two only agree if the filter's coordinates
/// are the root's. That was measured under an `Opacity` and under clips
/// (`refraction_coordinate_space_probe_test.dart` S1, and G1 in
/// `refraction_geometry_probe_test.dart`) and nowhere else. The kit composes
/// its own backdrop pass beside the content, never around it, so a surface
/// only ends up inside another pass through an ancestor: a frosted container,
/// a second glass layer, a fade, a mask, a layer blur. An upstream glass
/// package found that on Impeller a program nested in such an ancestor is
/// handed coordinates relative to that ancestor's pass, which moves the band
/// by the pass's origin.
///
/// ## What is measured
///
/// Each enclosure is a chain of wrappers above the surface, measured at two
/// placements (centred in the enclosed region, and against its left edge) in
/// two scopes. `scene` encloses the backdrop and the surface together, the way
/// a transition or a frosted container wraps a page. `glassOnly` encloses the
/// surface alone with the backdrop outside it, the way a fade wraps a card.
///
///   E2  What the program is handed there: `uSize` and `FlutterFragCoord()`
///       read back as colour, as in S1, against the surface's root-relative
///       pixel the library assumes. It is the engine's answer, independent of
///       the library, and it names the pass origin when there is one.
///   E1  What the shipped functional glass surface draws there, read as one
///       of three things against an unenclosed control captured in the same
///       run: BENDS (the control's picture), FLAT (no dispersed pixel at all:
///       the material without the bend, which is what the kit documents for
///       a bend that cannot be drawn) or WRONG (anything else: a band in the
///       wrong place). G1's metric (coloured pixels in the left band; centre
///       above half of edge) is reported on every row and asserted wherever
///       the bend is drawn, but it cannot carry the verdict: a band moved by
///       a pass origin leaves G1's window as coloured as before, because the
///       window then lies outside the moved band, where the shader bends at
///       full strength.
///
/// The rule asserted ties the two together. In the `scene` scope, where the
/// engine hands the program the root's coordinates the surface must BEND, and
/// where it does not it must BEND or be FLAT, never WRONG. In the `glassOnly`
/// scope a layer that saves its own pass also isolates the glass from the
/// backdrop outside it, so the surface is flat whatever coordinates it is
/// handed; the rule there is only that it is never WRONG.
///
/// E0 checks the harness: the control reproduces pixel for pixel, and the
/// coordinate readback sees a known shift when the capture boundary leaves
/// the root's origin, so a clean E2 means something.
///
/// The capture boundary sits at the root's origin on purpose (see G1): the
/// surface reports its rectangle relative to the root, and `toImage` makes
/// the boundary the render target.
///
/// Run as:
///
///   flutter test integration_test/refraction_enclosing_pass_probe_test.dart \
///     -d macos --dart-define=PROBE_DEVICE_ID=macos
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Supplied by the runner alongside `-d`, so every reported value carries the
/// device it came from. Empty means the probe refuses to report.
const kProbeDeviceId = String.fromEnvironment('PROBE_DEVICE_ID');

/// Where PNGs and the results file go, when the sandbox lets them be written.
/// A number is the deliverable; the picture is for the person reading it.
const kProbeOutputDir = String.fromEnvironment('PROBE_OUTPUT_DIR');

const _kCoordsShaderAsset = 'shaders/probe_coords.frag';

/// Mirrors `kScale` in `probe_coords.frag`: each channel carries a pixel
/// count divided by this, so a reading has the step of `scale / 255`.
const double _kCoordsScale = 2048;

/// The large backdrop every capture is taken of. G1's.
const Size _kCaptureSize = Size(600, 400);

/// The surface under test. G1's.
const Size _kSurfaceSize = Size(200, 100);

/// What a `scene` enclosure holds. Inset from the capture so that its origin
/// is not the root's: an enclosure at the root's origin cannot displace
/// anything. The 200x100 surface is centred in it at (200, 150), which is
/// G1's centre, and sits against its left edge at (40, 150).
const Rect _kSceneRegion = Rect.fromLTWH(40, 40, 520, 320);

/// Logical width of one backdrop stripe. G1's.
const double _kStripeWidth = 4;

/// Too small to make an in-between colour, but not zero: zero mounts no
/// backdrop pass, and the bend rides that pass. G1's value.
const double _kHairline = 0.1;

/// G1's rule for a coloured pixel: two channels disagree by more than this.
const int _kColourSpread = 24;

/// How far a channel may differ from the control's before the pixel counts
/// as different.
const int _kMismatchTolerance = 32;

/// The share of the surface's pixels that may differ from the control's for
/// the surface to count as bending like the control.
const double _kBendsBudget = 0.02;

/// The share of the surface's pixels that may be coloured for the surface to
/// count as flat: the bend's dispersion is the only thing that colours it.
const double _kFlatBudget = 0.001;

/// How far a decoded coordinate may sit from the expected one, in device
/// pixels, for the engine to count as handing the program the root's: two
/// encoding steps. A coordinate readback draws its backdrop black, so the 1% of
/// backdrop an `Opacity(.99)` mixes into it adds nothing; against a striped
/// backdrop that mix moves a reading by up to 24 px, which at a device pixel
/// ratio of 1 is enough to hide a clip that starts 40 px from the root.
const double _kCoordinateTolerance = 16;

/// Where the capture boundary goes for the harness's known-shift control.
const Offset _kShiftedBoundary = Offset(40, 40);

/// How much the `Padding` wrapper moves the content box inside its region.
const Offset _kPaddingInset = Offset(60, 40);

/// Where one enclosure is placed in the capture.
enum _Placement {
  /// Centred in the scene region. G1's centre.
  centre(Offset(200, 150)),

  /// Against the scene region's left edge.
  edge(Offset(40, 150));

  const _Placement(this.at);

  /// The surface's top-left in the capture, in logical pixels.
  final Offset at;
}

/// What an enclosure holds.
enum _Scope {
  /// The backdrop and the surface together.
  scene,

  /// The surface alone; the backdrop is outside.
  glassOnly,
}

/// What a surface draws, read against the control.
enum _Verdict {
  /// The control's picture.
  bends,

  /// The material without the bend: nothing is dispersed.
  flat,

  /// A bend in the wrong place.
  wrong,
}

/// What a test learns about the device before it builds anything.
class _Env {
  const _Env({
    required this.dpr,
    required this.refraction,
    required this.coords,
  });

  /// Logical-to-device scale of the capture.
  final double dpr;

  /// The shipped refraction program, for the nested `SurfaceBackdrop`.
  final ui.FragmentProgram? refraction;

  /// The program that reads the coordinate space back as colour.
  final ui.FragmentProgram coords;
}

/// One widget put above the surface.
class _Wrapper {
  const _Wrapper(this.name, this.build, this.matches);

  final String name;

  /// Puts the wrapper above `child`.
  final Widget Function(Widget child, _Env env) build;

  /// Whether a widget in the tree is this wrapper. Asserted, so a wrapper the
  /// framework folded away cannot pass as a measurement of itself.
  final bool Function(Widget widget) matches;
}

ui.ImageFilter _hairlineBlur() =>
    ui.ImageFilter.blur(sigmaX: _kHairline, sigmaY: _kHairline);

final _Wrapper _clipRect = _Wrapper(
  'ClipRect',
  (child, env) => ClipRect(child: child),
  (widget) => widget is ClipRect,
);

final _Wrapper _clipRectSaveLayer = _Wrapper(
  'ClipRect(antiAliasWithSaveLayer)',
  (child, env) =>
      ClipRect(clipBehavior: Clip.antiAliasWithSaveLayer, child: child),
  (widget) =>
      widget is ClipRect && widget.clipBehavior == Clip.antiAliasWithSaveLayer,
);

final _Wrapper _clipRRect = _Wrapper(
  'ClipRRect',
  (child, env) =>
      ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
  (widget) => widget is ClipRRect && widget.clipBehavior == Clip.antiAlias,
);

final _Wrapper _clipRRectSaveLayer = _Wrapper(
  'ClipRRect(antiAliasWithSaveLayer)',
  (child, env) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAliasWithSaveLayer,
    child: child,
  ),
  (widget) =>
      widget is ClipRRect && widget.clipBehavior == Clip.antiAliasWithSaveLayer,
);

final _Wrapper _backdropFilter = _Wrapper(
  'BackdropFilter',
  (child, env) => BackdropFilter(filter: _hairlineBlur(), child: child),
  (widget) => widget is BackdropFilter,
);

final _Wrapper _imageFiltered = _Wrapper(
  'ImageFiltered',
  (child, env) => ImageFiltered(imageFilter: _hairlineBlur(), child: child),
  (widget) => widget is ImageFiltered,
);

/// An opaque white mask in `dstIn`: the layer is saved and the mask is
/// drawn, and the pixels are left as they were.
final _Wrapper _shaderMask = _Wrapper(
  'ShaderMask',
  (child, env) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (bounds) => const LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
    ).createShader(bounds),
    child: child,
  ),
  (widget) => widget is ShaderMask,
);

final _Wrapper _opacity = _Wrapper(
  'Opacity(.99)',
  (child, env) => Opacity(opacity: 0.99, child: child),
  (widget) => widget is Opacity,
);

/// A matrix that leaves every colour as it is.
final _Wrapper _colorFiltered = _Wrapper(
  'ColorFiltered',
  (child, env) => ColorFiltered(
    colorFilter: const ColorFilter.matrix(<double>[
      1, 0, 0, 0, 0, //
      0, 1, 0, 0, 0, //
      0, 0, 1, 0, 0, //
      0, 0, 0, 1, 0, //
    ]),
    child: child,
  ),
  (widget) => widget is ColorFiltered,
);

final _Wrapper _repaintBoundary = _Wrapper(
  'RepaintBoundary',
  (child, env) => RepaintBoundary(child: child),
  (widget) => widget is RepaintBoundary,
);

/// Pushes the content box away from its region's origin, so the box and the
/// clip above it no longer start in the same place.
final _Wrapper _padded = _Wrapper(
  'Padding',
  (child, env) => Padding(
    padding: EdgeInsets.only(left: _kPaddingInset.dx, top: _kPaddingInset.dy),
    child: child,
  ),
  (widget) => widget is Padding,
);

/// A second glass layer with the surface in its child subtree, which the
/// kit never composes itself (its pass is a sibling of the content). It bends
/// nothing, so what the surface samples is what the control samples and only
/// the surface's own coordinates are in question.
final _Wrapper _surfaceBackdrop = _Wrapper(
  'SurfaceBackdrop',
  (child, env) => SurfaceBackdrop(
    material: _hairlineBlur(),
    program: env.refraction!,
    refraction: const CoreSurfaceRefraction(bezel: 0.1, strength: 0),
    cornerRadius: 0,
    devicePixelRatio: env.dpr,
    child: child,
  ),
  (widget) => widget is SurfaceBackdrop,
);

/// The kit's own layer blur: `Frame` wraps its content in an `ImageFiltered`.
final _Wrapper _frameLayerBlur = _Wrapper(
  'Frame(layerBlur)',
  (child, env) => Frame(layerBlur: _kHairline, child: child),
  (widget) => widget is Frame && widget.layerBlur != null,
);

/// The kit's own opacity: `Frame` wraps its content in an `Opacity`.
final _Wrapper _frameOpacity = _Wrapper(
  'Frame(opacity)',
  (child, env) => Frame(opacity: 0.99, child: child),
  (widget) => widget is Frame && widget.opacity != null,
);

/// The kit's own edge fade: a `ShaderMask` over a scroll view. The content
/// is taller than the viewport, so the mask is in the tree from the first
/// frame.
final _Wrapper _fadeScroll = _Wrapper(
  'FadeScroll',
  (child, env) => FadeScroll(child: SizedBox(height: 900, child: child)),
  (widget) => widget is FadeScroll,
);

/// A chain of wrappers above the surface, outermost first.
class _Enclosure {
  const _Enclosure(
    this.label,
    this.wrappers, {
    this.scopes = _Scope.values,
    this.inset = Offset.zero,
    this.needsRefraction = false,
  });

  final String label;
  final List<_Wrapper> wrappers;

  /// The scopes this enclosure is meaningful in.
  final List<_Scope> scopes;

  /// How far the content box starts from the region's origin.
  final Offset inset;

  /// Whether a wrapper needs the shipped refraction program.
  final bool needsRefraction;

  Widget wrap(Widget child, _Env env) {
    var out = child;
    for (final wrapper in wrappers.reversed) {
      out = wrapper.build(out, env);
    }

    return out;
  }
}

/// The wrappers the task names, bare, then the same under a clip (how a
/// frosted container or a scroll view really holds them), then controls that
/// open no pass, then the kit's own.
final List<_Enclosure> _enclosures = <_Enclosure>[
  const _Enclosure('none', []),
  _Enclosure('BackdropFilter', [_backdropFilter]),
  _Enclosure('ImageFiltered', [_imageFiltered]),
  _Enclosure('ShaderMask', [_shaderMask]),
  _Enclosure('ClipRRect(antiAliasWithSaveLayer)', [_clipRRectSaveLayer]),
  _Enclosure('Opacity(.99)', [_opacity]),
  _Enclosure('SurfaceBackdrop (nested)', [
    _surfaceBackdrop,
  ], needsRefraction: true),
  _Enclosure('ClipRect > BackdropFilter', [_clipRect, _backdropFilter]),
  _Enclosure('ClipRect > ImageFiltered', [_clipRect, _imageFiltered]),
  _Enclosure('ClipRect > ShaderMask', [_clipRect, _shaderMask]),
  _Enclosure('ClipRect > Opacity(.99)', [_clipRect, _opacity]),
  _Enclosure('ClipRect > SurfaceBackdrop (nested)', [
    _clipRect,
    _surfaceBackdrop,
  ], needsRefraction: true),
  _Enclosure('ClipRect', [_clipRect]),
  _Enclosure('ClipRRect', [_clipRRect]),
  _Enclosure('ColorFiltered', [_colorFiltered]),
  _Enclosure('RepaintBoundary', [_repaintBoundary]),
  // The backdrop filter's box starts inside the clip, so a pass the size of
  // the clip and a pass the size of the filter start in different places.
  _Enclosure(
    'ClipRect > Padding > BackdropFilter',
    [_clipRect, _padded, _backdropFilter],
    scopes: [_Scope.scene],
    inset: _kPaddingInset,
  ),
  // Whether the opener or the clip is outermost decides what the pass is.
  _Enclosure('Opacity(.99) > ClipRect', [_opacity, _clipRect]),
  _Enclosure('ShaderMask > ClipRect', [_shaderMask, _clipRect]),
  _Enclosure('ClipRect > ColorFiltered', [_clipRect, _colorFiltered]),
  _Enclosure('ClipRect(antiAliasWithSaveLayer)', [_clipRectSaveLayer]),
  // Openers inside openers.
  _Enclosure('ImageFiltered > Opacity(.99)', [_imageFiltered, _opacity]),
  _Enclosure('Opacity(.99) > ClipRect > BackdropFilter', [
    _opacity,
    _clipRect,
    _backdropFilter,
  ]),
  _Enclosure('Frame(layerBlur)', [_frameLayerBlur]),
  _Enclosure('Frame(opacity)', [_frameOpacity]),
  // A fade over the bottom of the viewport would change the surface in the
  // glass-only scope, where the viewport is the surface.
  _Enclosure('FadeScroll', [_fadeScroll], scopes: [_Scope.scene]),
];

/// Controls by scope and placement, captured once per run.
final Map<String, _Capture> _controls = <String, _Capture>{};

/// Every line the run reports, in order, for the summary and the file.
final List<String> _lines = <String>[];

void _note(String line) {
  _lines.add(line);
  debugPrintSynchronously(line);
}

/// Records a failed check without ending the test, so one failing row does
/// not hide the rows after it.
void _soft(List<String> failures, bool ok, String message) {
  if (!ok) {
    failures.add(message);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    expect(
      kProbeDeviceId,
      isNotEmpty,
      reason:
          'Pass --dart-define=PROBE_DEVICE_ID=<deviceId> matching the -d '
          'flag. An unattributed value is not a measurement.',
    );
  });

  tearDownAll(_writeResults);

  group('E0 — the harness', () {
    testWidgets('the control reproduces, and G1 holds in this layout', (
      tester,
    ) async {
      final env = await _prepare(tester, tag: 'E0');
      if (env == null) {
        return;
      }
      final failures = <String>[];
      for (final scope in _Scope.values) {
        final counts = <_Placement, _Counts>{};
        for (final placement in _Placement.values) {
          final first = await _shoot(
            tester,
            env,
            enclosure: _enclosures.first,
            scope: scope,
            placement: placement,
            leaf: const _SurfaceLeaf(),
          );
          final second = await _shoot(
            tester,
            env,
            enclosure: _enclosures.first,
            scope: scope,
            placement: placement,
            leaf: const _SurfaceLeaf(),
          );
          final counted = _count(first.capture, second.capture, placement);
          counts[placement] = counted;
          _note(
            'E0  device=$kProbeDeviceId  dpr=${env.dpr}'
            '  window=${_windowSize(tester)}  scope=${scope.name}'
            '  placement=${placement.name}  band=${counted.band}'
            '  interior=${counted.interior}'
            '  mismatchBetweenTwoCaptures=${counted.mismatch}',
          );
          _soft(
            failures,
            counted.mismatch == 0,
            '${scope.name}/${placement.name}: the control does not '
            'reproduce, so no difference from it means anything',
          );
        }
        final centre = counts[_Placement.centre]!;
        final edge = counts[_Placement.edge]!;
        _soft(
          failures,
          edge.band > 0,
          '${scope.name}: no bend at all — the harness is not showing '
          'refraction',
        );
        _soft(
          failures,
          centre.band > edge.band ~/ 2,
          '${scope.name}: the centred control barely bends, so G1 does not '
          'hold in this layout',
        );
        _soft(
          failures,
          centre.surfaceColoured > 0 && edge.surfaceColoured > 0,
          '${scope.name}: the control has no dispersed pixel, so "flat" '
          'cannot be told from it',
        );
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    testWidgets('the coordinate readback sees a boundary that left the root', (
      tester,
    ) async {
      final env = await _prepare(tester, tag: 'E0');
      if (env == null) {
        return;
      }
      final home = await _shoot(
        tester,
        env,
        enclosure: _enclosures.first,
        scope: _Scope.glassOnly,
        placement: _Placement.centre,
        leaf: _CoordinateLeaf(env.coords),
        plainBackdrop: true,
      );
      final moved = await _shoot(
        tester,
        env,
        enclosure: _enclosures.first,
        scope: _Scope.glassOnly,
        placement: _Placement.centre,
        leaf: _CoordinateLeaf(env.coords),
        plainBackdrop: true,
        boundaryAt: _kShiftedBoundary,
      );
      final atHome = _readCoordinates(home);
      final atMoved = _readCoordinates(moved);
      final shift = _kShiftedBoundary * env.dpr;
      _note(
        'E0  device=$kProbeDeviceId  known shift of the capture boundary'
        ' ${_kShiftedBoundary.dx},${_kShiftedBoundary.dy} logical'
        '  fragDelta at root origin=${_pair(atHome.fragDx, atHome.fragDy)}'
        '  moved=${_pair(atMoved.fragDx, atMoved.fragDy)}'
        '  expected moved=${_pair(-shift.dx, -shift.dy)}',
      );
      expect(atHome.fragDx, closeTo(0, _kCoordinateTolerance));
      expect(atHome.fragDy, closeTo(0, _kCoordinateTolerance));
      expect(
        atMoved.fragDx,
        closeTo(-shift.dx, _kCoordinateTolerance),
        reason:
            'the readback did not see a boundary that left the root, so a '
            'clean E2 would not have seen a pass that did',
      );
      expect(atMoved.fragDy, closeTo(-shift.dy, _kCoordinateTolerance));
    });
  });

  group('E1/E2 — the bend inside an enclosure', () {
    for (final enclosure in _enclosures) {
      testWidgets('E1/E2 — ${enclosure.label}', (tester) async {
        final env = await _prepare(tester, tag: 'E1', enclosure: enclosure);
        if (env == null) {
          return;
        }
        final failures = <String>[];
        for (final scope in enclosure.scopes) {
          final readings = <_Placement, _Reading>{};
          final counts = <_Placement, _Counts>{};
          for (final placement in _Placement.values) {
            readings[placement] = _readCoordinates(
              await _shoot(
                tester,
                env,
                enclosure: enclosure,
                scope: scope,
                placement: placement,
                leaf: _CoordinateLeaf(env.coords),
                plainBackdrop: true,
              ),
            );
            final control = await _control(tester, env, scope, placement);
            final shot = await _shoot(
              tester,
              env,
              enclosure: enclosure,
              scope: scope,
              placement: placement,
              leaf: const _SurfaceLeaf(),
              png: true,
            );
            counts[placement] = _count(shot.capture, control, placement);
          }
          _report(enclosure, scope, env.dpr, readings, counts);
          _judge(failures, enclosure, scope, env.dpr, readings, counts);
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
      });
    }
  });
}

/// One line per enclosure and scope: what the engine hands the program, and
/// what the surface draws.
void _report(
  _Enclosure enclosure,
  _Scope scope,
  double dpr,
  Map<_Placement, _Reading> readings,
  Map<_Placement, _Counts> counts,
) {
  String engine(_Placement placement) {
    final read = readings[placement]!;
    // The pass origin is what the root-relative pixel loses: read minus
    // expected, negated and brought back to logical pixels.
    final origin = _pair(-read.fragDx / dpr, -read.fragDy / dpr);
    final width = (read.sizeX / dpr).toStringAsFixed(0);

    return 'origin=$origin width=$width rgba=${read.rgba}';
  }

  String drew(_Placement placement) {
    final c = counts[placement]!;

    return '${_verdict(c, dpr).name}'
        '(band=${c.band} interior=${c.interior}'
        ' coloured=${c.surfaceColoured} differs=${c.mismatch})';
  }

  _note(
    'ROW  device=$kProbeDeviceId  enclosure=${enclosure.label}'
    '  scope=${scope.name}'
    '  engine[centre]: ${engine(_Placement.centre)}'
    '  engine[edge]: ${engine(_Placement.edge)}'
    '  drew[centre]: ${drew(_Placement.centre)}'
    '  drew[edge]: ${drew(_Placement.edge)}',
  );
}

/// The rule: where the engine hands the program the root's coordinates the
/// surface must bend like the control; where it does not it must bend like
/// the control or be flat, and never be wrong.
void _judge(
  List<String> failures,
  _Enclosure enclosure,
  _Scope scope,
  double dpr,
  Map<_Placement, _Reading> readings,
  Map<_Placement, _Counts> counts,
) {
  for (final placement in _Placement.values) {
    final read = readings[placement]!;
    final verdict = _verdict(counts[placement]!, dpr);
    final where = '${enclosure.label} ${scope.name}/${placement.name}';
    final handedRoot =
        read.fragDx.abs() <= _kCoordinateTolerance &&
        read.fragDy.abs() <= _kCoordinateTolerance;
    // Only the scene scope can demand a bend: with the backdrop outside, a
    // layer that saves its own pass isolates the glass from it, and the
    // surface is flat whatever coordinates the program is handed.
    if (handedRoot && scope == _Scope.scene) {
      _soft(
        failures,
        verdict == _Verdict.bends,
        '$where: the engine hands the program the coordinates of the root, '
        'so the surface must bend like the control, and it drew '
        '${verdict.name}',
      );
    } else {
      _soft(
        failures,
        verdict != _Verdict.wrong,
        '$where: the engine hands the program coordinates '
        '${_pair(read.fragDx, read.fragDy)} device px away from the root, '
        'and the surface drew a bend in the wrong place',
      );
    }
  }
  // G1's metric, asserted wherever the bend is drawn.
  final centre = counts[_Placement.centre]!;
  final edge = counts[_Placement.edge]!;
  if (_verdict(edge, dpr) == _Verdict.bends) {
    _soft(
      failures,
      edge.band > 0 && centre.band > edge.band ~/ 2,
      '${enclosure.label} ${scope.name}: G1 does not hold: centre '
      '${centre.band}, edge ${edge.band}',
    );
  }
}

_Verdict _verdict(_Counts counts, double dpr) {
  if (counts.mismatch <= _surfacePixels(dpr) * _kBendsBudget) {
    return _Verdict.bends;
  }
  if (counts.surfaceColoured <= _surfacePixels(dpr) * _kFlatBudget) {
    return _Verdict.flat;
  }

  return _Verdict.wrong;
}

/// Loads what a test needs, or reports why it did not run.
Future<_Env?> _prepare(
  WidgetTester tester, {
  required String tag,
  _Enclosure? enclosure,
}) async {
  if (!ui.ImageFilter.isShaderFilterSupported) {
    _note('$tag  device=$kProbeDeviceId  not run: no shader filters');

    return null;
  }
  final programs = await tester.runAsync(
    () async => (
      await SurfaceRefractionProgram.warmUp(),
      await ui.FragmentProgram.fromAsset(_kCoordsShaderAsset),
    ),
  );
  final env = _Env(
    dpr: tester.view.devicePixelRatio,
    refraction: programs!.$1,
    coords: programs.$2,
  );
  if (enclosure != null &&
      enclosure.needsRefraction &&
      env.refraction == null) {
    _note(
      '$tag  device=$kProbeDeviceId  enclosure=${enclosure.label}'
      '  not run: the refraction program did not load',
    );

    return null;
  }

  return env;
}

/// Two device-pixel quantities as one token, whole pixels.
String _pair(double x, double y) =>
    '(${x.toStringAsFixed(0)},${y.toStringAsFixed(0)})';

String _windowSize(WidgetTester tester) {
  final logical = tester.view.physicalSize / tester.view.devicePixelRatio;

  return '${logical.width.toStringAsFixed(0)}x'
      '${logical.height.toStringAsFixed(0)}';
}

/// The leaf of a scene: something that sits at a placement and is read back.
abstract class _Leaf extends StatelessWidget {
  const _Leaf();
}

/// The shipped functional glass surface. G1's.
class _SurfaceLeaf extends _Leaf {
  const _SurfaceLeaf();

  @override
  Widget build(BuildContext context) => const OutlinedContainer(
    role: CoreSurfaceRole.functional,
    child: SizedBox.expand(),
  );
}

/// The shipped filter's shape (a clipped, composed backdrop filter) with the
/// coordinate probe in place of the refraction program.
class _CoordinateLeaf extends _Leaf {
  const _CoordinateLeaf(this.program);

  final ui.FragmentProgram program;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ui.ImageFilter.compose(
        outer: ui.ImageFilter.shader(program.fragmentShader()),
        inner: _hairlineBlur(),
      ),
      child: const SizedBox.expand(),
    ),
  );
}

/// A capture and where the leaf was when it was taken.
class _Shot {
  const _Shot({
    required this.capture,
    required this.rootCentre,
    required this.captureCentre,
  });

  final _Capture capture;

  /// The leaf's centre relative to the root, in device pixels. What the
  /// library assumes `FlutterFragCoord()` reads there.
  final Offset rootCentre;

  /// The leaf's centre relative to the capture boundary, in device pixels.
  /// The pixel to read.
  final Offset captureCentre;
}

Future<_Shot> _shoot(
  WidgetTester tester,
  _Env env, {
  required _Enclosure enclosure,
  required _Scope scope,
  required _Placement placement,
  required _Leaf leaf,
  Offset boundaryAt = Offset.zero,
  bool png = false,
  bool plainBackdrop = false,
}) async {
  final boundaryKey = GlobalKey();
  final leafKey = GlobalKey();
  final surface = placement.at & _kSurfaceSize;
  final region = scope == _Scope.scene ? _kSceneRegion : surface;
  // Where the content box starts: the region's origin, moved by whatever
  // the enclosure pushes it by.
  final origin = region.topLeft + enclosure.inset;
  final keyed = KeyedSubtree(key: leafKey, child: leaf);
  final inside = scope == _Scope.scene
      ? Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _StripesPainter(origin: origin, plain: plainBackdrop),
              ),
            ),
            Positioned.fromRect(rect: surface.shift(-origin), child: keyed),
          ],
        )
      : keyed;

  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: CoreSurfaceStyleId.liquidGlass,
      surfaceTuning: const CoreSurfaceTuning(surfaceBlur: _kHairline),
      home: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.only(left: boundaryAt.dx, top: boundaryAt.dy),
          child: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: _kCaptureSize.width,
              height: _kCaptureSize.height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _StripesPainter(plain: plainBackdrop),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: region,
                    child: enclosure.wrap(inside, env),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final leafBox = leafKey.currentContext!.findRenderObject()! as RenderBox;
  final centre = leafBox.size.center(Offset.zero);
  final shot = _Shot(
    capture: await _readBoundary(tester, boundary, pixelRatio: env.dpr),
    rootCentre: leafBox.localToGlobal(centre) * env.dpr,
    captureCentre: leafBox.localToGlobal(centre, ancestor: boundary) * env.dpr,
  );
  expect(
    shot.capture.width,
    (_kCaptureSize.width * env.dpr).round(),
    reason:
        'the capture is not the size the layout asked for, so the window '
        'is too small for this probe',
  );
  for (final wrapper in enclosure.wrappers) {
    expect(
      _isEnclosed(
        leafKey.currentContext!,
        boundaryKey.currentContext!,
        wrapper.matches,
      ),
      isTrue,
      reason: '${wrapper.name} is not above the surface in the tree',
    );
  }
  if (png) {
    await _writePng(
      tester,
      boundary,
      env.dpr,
      _label(enclosure, scope, placement),
    );
  }

  return shot;
}

/// Whether a widget [matches] sits between [leaf] and [boundary].
bool _isEnclosed(
  BuildContext leaf,
  BuildContext boundary,
  bool Function(Widget widget) matches,
) {
  var found = false;
  leaf.visitAncestorElements((element) {
    if (element == boundary) {
      return false;
    }
    if (matches(element.widget)) {
      found = true;

      return false;
    }

    return true;
  });

  return found;
}

String _label(_Enclosure enclosure, _Scope scope, _Placement placement) {
  final slug = enclosure.label
      .replaceAll(RegExp('[^A-Za-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  return 'enclosing-${scope.name}-$slug-${placement.name}';
}

/// The unenclosed capture for [scope] and [placement], taken once.
Future<_Capture> _control(
  WidgetTester tester,
  _Env env,
  _Scope scope,
  _Placement placement,
) async {
  final key = '${scope.name}/${placement.name}';
  final known = _controls[key];
  if (known != null) {
    return known;
  }
  final shot = await _shoot(
    tester,
    env,
    enclosure: _enclosures.first,
    scope: scope,
    placement: placement,
    leaf: const _SurfaceLeaf(),
  );

  return _controls[key] = shot.capture;
}

/// What the program read about its own coordinate space, against what the
/// library assumes.
class _Reading {
  const _Reading({
    required this.rgba,
    required this.sizeX,
    required this.fragDx,
    required this.fragDy,
  });

  final List<int> rgba;

  /// `uSize.x` as read, in device pixels.
  final double sizeX;

  /// Read minus expected, in device pixels. Zero is "the root's".
  final double fragDx;
  final double fragDy;
}

_Reading _readCoordinates(_Shot shot) {
  final x = shot.captureCentre.dx.floor();
  final y = shot.captureCentre.dy.floor();
  final px = shot.capture.pixelAt(x, y);
  // R = uSize.x, G = FlutterFragCoord().x, B = FlutterFragCoord().y, each
  // over `_kCoordsScale` and quantised to eight bits: a reading is good to a
  // step of about eight device pixels.
  final fragX = px[1] / 255 * _kCoordsScale;
  final fragY = px[2] / 255 * _kCoordsScale;

  return _Reading(
    rgba: px,
    sizeX: px[0] / 255 * _kCoordsScale,
    // The fragment is the pixel's centre; the library assumes the pixel
    // reached through the root.
    fragDx: fragX - (shot.rootCentre.dx.floor() + 0.5),
    fragDy: fragY - (shot.rootCentre.dy.floor() + 0.5),
  );
}

/// G1's window and more, read off one capture.
class _Counts {
  const _Counts({
    required this.band,
    required this.interior,
    required this.surfaceColoured,
    required this.mismatch,
  });

  /// G1's metric: coloured pixels in the surface's left band.
  final int band;

  /// Coloured pixels in the flat interior, which should have none.
  final int interior;

  /// Coloured pixels anywhere in the surface. Dispersion is the only thing
  /// that colours it, so none means no bend was drawn.
  final int surfaceColoured;

  /// Pixels of the surface that differ from the control's.
  final int mismatch;
}

_Counts _count(_Capture capture, _Capture control, _Placement placement) {
  final at = placement.at;
  final dpr = capture.width / _kCaptureSize.width;

  return _Counts(
    // G1's window, unchanged: past the 1px edge run, short of the corner arcs.
    band: capture.coloured(
      left: at.dx + 2,
      top: at.dy + 30,
      right: at.dx + 24,
      bottom: at.dy + 70,
      ratio: dpr,
    ),
    // The flat interior: inside the shipped 27% band on every side, clear of
    // the corners. The lens magnifies it but never fringes it.
    interior: capture.coloured(
      left: at.dx + 60,
      top: at.dy + 36,
      right: at.dx + 140,
      bottom: at.dy + 64,
      ratio: dpr,
    ),
    surfaceColoured: capture.coloured(
      left: at.dx,
      top: at.dy,
      right: at.dx + _kSurfaceSize.width,
      bottom: at.dy + _kSurfaceSize.height,
      ratio: dpr,
    ),
    mismatch: capture.differences(
      control,
      left: at.dx,
      top: at.dy,
      right: at.dx + _kSurfaceSize.width,
      bottom: at.dy + _kSurfaceSize.height,
      ratio: dpr,
    ),
  );
}

int _surfacePixels(double dpr) =>
    (_kSurfaceSize.width * dpr).round() * (_kSurfaceSize.height * dpr).round();

/// A capture with the geometry needed to read it back.
class _Capture {
  const _Capture(this.bytes, this.width, this.height);

  final Uint8List bytes;
  final int width;
  final int height;

  List<int> pixelAt(int x, int y) {
    final at = ((y * width) + x) * 4;

    return bytes.sublist(at, at + 4);
  }

  /// Pixels in a logical rectangle (scaled by [ratio]) whose channels
  /// disagree: G1's reading of a dispersed pixel.
  int coloured({
    required double left,
    required double top,
    required double right,
    required double bottom,
    required double ratio,
  }) {
    var n = 0;
    for (var y = (top * ratio).round(); y < (bottom * ratio).round(); y++) {
      for (var x = (left * ratio).round(); x < (right * ratio).round(); x++) {
        final at = ((y * width) + x) * 4;
        final r = bytes[at];
        final g = bytes[at + 1];
        final b = bytes[at + 2];
        if ((r - g).abs() > _kColourSpread || (g - b).abs() > _kColourSpread) {
          n++;
        }
      }
    }

    return n;
  }

  /// Pixels in a logical rectangle that differ from [other]'s by more than
  /// the tolerance in any channel.
  int differences(
    _Capture other, {
    required double left,
    required double top,
    required double right,
    required double bottom,
    required double ratio,
  }) {
    var n = 0;
    for (var y = (top * ratio).round(); y < (bottom * ratio).round(); y++) {
      for (var x = (left * ratio).round(); x < (right * ratio).round(); x++) {
        final at = ((y * width) + x) * 4;
        var worst = 0;
        for (var c = 0; c < 3; c++) {
          worst = math.max(worst, (bytes[at + c] - other.bytes[at + c]).abs());
        }
        if (worst > _kMismatchTolerance) {
          n++;
        }
      }
    }

    return n;
  }
}

Future<_Capture> _readBoundary(
  WidgetTester tester,
  RenderRepaintBoundary boundary, {
  required double pixelRatio,
}) async {
  final result = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData();
    final capture = _Capture(
      data!.buffer.asUint8List(),
      image.width,
      image.height,
    );
    image.dispose();

    return capture;
  });

  return result!;
}

Future<void> _writePng(
  WidgetTester tester,
  RenderRepaintBoundary boundary,
  double pixelRatio,
  String label,
) async {
  // The macOS runner is sandboxed, so an arbitrary path is refused; the
  // app's own temp directory is always writable and is where to look.
  final dir = kProbeOutputDir.isEmpty
      ? Directory.systemTemp.path
      : kProbeOutputDir;
  await tester.runAsync(() async {
    try {
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await File('$dir/$label.png').writeAsBytes(data!.buffer.asUint8List());
    } on Object catch (error) {
      debugPrintSynchronously('png not written ($label): $error');
    }
  });
}

/// The run's lines in one file, because a console that interleaves a test
/// runner's output with a device's is a poor place to read a table from.
void _writeResults() {
  final dir = kProbeOutputDir.isEmpty
      ? Directory.systemTemp.path
      : kProbeOutputDir;
  try {
    File(
      '$dir/enclosing-pass-results.txt',
    ).writeAsStringSync('${_lines.join('\n')}\n');
    debugPrintSynchronously(
      'results written to $dir/enclosing-pass-results.txt',
    );
  } on Object catch (error) {
    debugPrintSynchronously('results not written: $error');
  }
}

/// Vertical stripes, black then white, [_kStripeWidth] wide: G1's backdrop.
///
/// [origin] is where this painter's own origin sits in the capture. A copy
/// painted inside an enclosure has to line up stripe for stripe with the one
/// behind it, or the surface would see a different backdrop in each scope.
class _StripesPainter extends CustomPainter {
  const _StripesPainter({this.origin = Offset.zero, this.plain = false});

  final Offset origin;

  /// Black throughout, for a coordinate readback: nothing for an `Opacity`
  /// layer to mix into a reading.
  final bool plain;

  @override
  void paint(Canvas canvas, Size size) {
    final black = Paint()..color = const Color(0xFF000000);
    final white = Paint()..color = const Color(0xFFFFFFFF);
    if (plain) {
      canvas.drawRect(Offset.zero & size, black);

      return;
    }
    // Stripe n covers x in [n * width, (n + 1) * width) in capture pixels and
    // is dark when n is even.
    var n = (origin.dx / _kStripeWidth).floor();
    while (n * _kStripeWidth - origin.dx < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(
          n * _kStripeWidth - origin.dx,
          0,
          _kStripeWidth,
          size.height,
        ),
        n.isEven ? black : white,
      );
      n++;
    }
  }

  @override
  bool shouldRepaint(covariant _StripesPainter oldDelegate) =>
      oldDelegate.origin != origin || oldDelegate.plain != plain;
}
