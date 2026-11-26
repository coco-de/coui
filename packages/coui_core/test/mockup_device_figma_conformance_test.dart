// Conformance of the Core MockupDevice layout and style defaults to the
// measured Figma canvas (`MockupDevice` redesign).
//
// Every expected value below is a canvas measurement transcribed from the
// design measurements. None is read back from the layout implementation or
// from a style default, so this file is a second reading of the canvas: when
// the code and the canvas disagree, the failure names the member, the
// element and the number.
//
// Conventions
// - Lengths are logical px and compared with a 0.02 px tolerance (the canvas
//   prints three decimals and a few parts sit 0.015 px off their ideal).
// - Colours are written the way Figma prints them (`#RRGGBB[AA]`) and
//   converted to ARGB here, independently of the code.
// - Hardware colours (frame, bezel, buttons, camera) are the designer copy's
//   values, written as literals: one value in every mode and under every
//   palette, so no scheme token stands in for them. The optical layers
//   (button gloss and depth, rim glow, bezel inner shadow, the body's drop
//   shadow) are literals too.
// - Each test collects every mismatch of its element, then fails once with
//   the whole list, so one failing element reports all of its numbers.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import 'support/brand_fixture.dart';

const double _kTol = 0.02;

CoreMockupDeviceRect _r(
  double left,
  double top,
  double width,
  double height,
) => (left: left, top: top, width: width, height: height);

typedef _Band = ({CoreMockupDeviceEdge edge, CoreMockupDeviceRect rect});

/// `#RRGGBB` / `#RRGGBBAA` (Figma) to ARGB.
int _hex(String figma) {
  final h = figma.replaceFirst('#', '');
  final rgb = int.parse(h.substring(0, 6), radix: 16);
  final alpha = h.length == 8 ? int.parse(h.substring(6), radix: 16) : 0xFF;
  return (alpha << 24) | rgb;
}

/// The positions of [count] evenly distributed stops.
List<double> _evenStops(int count) => [
  for (var i = 0; i < count; i++)
    if (count == 1) 0.0 else i / (count - 1),
];

String _argb(int value) => '0x${value.toRadixString(16).padLeft(8, '0')}';

String _fmt(double value) => value.toStringAsFixed(4);

/// Collects the mismatches of one element and reports them together.
class _Check {
  _Check(this.scope);

  final String scope;
  final List<String> failures = [];

  void fail(String what, String detail) =>
      failures.add('$scope / ${_label(what)}: $detail');

  /// Drops a leading segment that only repeats the end of the scope, so a
  /// failure reads `tablet portrait / power button / left`.
  String _label(String what) {
    final cut = what.indexOf(' / ');
    if (cut < 0) return what;
    return scope.endsWith(' / ${what.substring(0, cut)}')
        ? what.substring(cut + 3)
        : what;
  }

  void close(
    String what,
    double actual,
    double expected, {
    double tol = _kTol,
  }) {
    if (actual.isNaN || (actual - expected).abs() > tol) {
      fail(
        what,
        'expected ${_fmt(expected)} actual ${_fmt(actual)} (tolerance $tol)',
      );
    }
  }

  void same(String what, Object? actual, Object? expected) {
    if (actual != expected) {
      fail(what, 'expected $expected actual $actual');
    }
  }

  void rect(
    String what,
    CoreMockupDeviceRect actual,
    CoreMockupDeviceRect expected, {
    double tol = _kTol,
  }) {
    close('$what / left', actual.left, expected.left, tol: tol);
    close('$what / top', actual.top, expected.top, tol: tol);
    close('$what / width', actual.width, expected.width, tol: tol);
    close('$what / height', actual.height, expected.height, tol: tol);
  }

  void radiusAll(String what, CoreBorderRadius actual, double expected) {
    close('$what / top-left', actual.topLeft, expected);
    close('$what / top-right', actual.topRight, expected);
    close('$what / bottom-left', actual.bottomLeft, expected);
    close('$what / bottom-right', actual.bottomRight, expected);
  }

  /// A colour the canvas prints as hex: a literal, never a scheme token.
  void color(String what, CoreColor actual, String figmaHex) {
    if (actual.token != null) {
      fail(what, 'expected the literal $figmaHex, got token ${actual.token}');
      return;
    }
    if (actual.argb != _hex(figmaHex)) {
      fail(
        what,
        'expected $figmaHex (${_argb(_hex(figmaHex))}) '
        'actual ${_argb(actual.argb)}',
      );
    }
    close('$what / opacity', actual.opacity, 1, tol: 1e-9);
  }

  /// A colour bound to a Semantic slot: the slot and the paint opacity.
  void tokenColor(
    String what,
    CoreColor actual,
    CoreColorToken token, {
    double opacity = 1,
  }) {
    if (actual.token != token) {
      fail(what, 'expected token $token actual ${actual.token}');
    }
    close('$what / opacity', actual.opacity, opacity, tol: 1e-9);
  }

  /// [colors] holds one entry per stop: a `#RRGGBB[AA]` string for a stop the
  /// canvas prints as hex, or a [CoreColorToken] for a stop bound to a
  /// Semantic slot (opaque; the paint opacity belongs to the paint).
  void gradient(
    String what,
    CoreGradient actual, {
    required CoreGradientType type,
    required List<double> stops,
    required List<Object> colors,
    CoreAlignment? begin,
    CoreAlignment? end,
  }) {
    same('$what / type', actual.type, type);
    final count = actual.colors.length;
    final actualStops = actual.stops ?? _evenStops(count);
    if (actualStops.length != stops.length) {
      fail(
        '$what / stop count',
        'expected ${stops.length} actual ${actualStops.length}',
      );
    } else {
      for (var i = 0; i < stops.length; i++) {
        close('$what / stop[$i]', actualStops[i], stops[i], tol: 1e-9);
      }
    }
    if (count != colors.length) {
      fail('$what / colour count', 'expected ${colors.length} actual $count');
    } else {
      for (var i = 0; i < count; i++) {
        switch (colors[i]) {
          case final CoreColorToken slot:
            tokenColor('$what / colour[$i]', actual.colors[i], slot);
          case final String hex:
            color('$what / colour[$i]', actual.colors[i], hex);
          case final other:
            fail('$what / colour[$i]', 'unsupported expectation $other');
        }
      }
    }
    if (begin != null) same('$what / begin', actual.begin, begin);
    if (end != null) same('$what / end', actual.end, end);
  }

  void done() {
    if (failures.isNotEmpty) {
      _failAll(failures);
    }
  }
}

void _failAll(List<String> failures) {
  fail('${failures.length} mismatch(es):\n  ${failures.join('\n  ')}');
}

void _check(String name, void Function(_Check c) body) {
  test(name, () {
    final c = _Check(name);
    body(c);
    c.done();
  });
}

// ─── The four canvas members ────────────────────────────────────────────

class _Member {
  const _Member({
    required this.name,
    required this.device,
    required this.orientation,
    required this.width,
    required this.height,
    required this.bodyRadius,
    required this.bezelRadius,
    required this.screenRadius,
    required this.bezel,
    required this.screen,
    required this.placement,
    required this.cameraEdge,
    required this.camera,
    required this.lens,
    required this.core,
    required this.highlight,
    required this.cameraRadius,
    required this.lensRadius,
    required this.coreRadius,
    required this.power,
    required this.powerEdge,
    required this.volumeUp,
    required this.volumeDown,
    required this.volumeEdge,
    required this.antenna,
    required this.gestureArea,
    required this.gestureBar,
    required this.gestureBarRadius,
    required this.statusTop,
    required this.cameraTop,
    required this.cameraLeft,
  });

  final String name;
  final CoreMockupDevice device;
  final CoreMockupOrientation orientation;

  /// Body size.
  final double width;
  final double height;

  final double bodyRadius;
  final double bezelRadius;
  final double screenRadius;

  /// Body-space boxes.
  final CoreMockupDeviceRect bezel;
  final CoreMockupDeviceRect screen;

  /// The space the camera set is drawn in, and the edge it stands on.
  final CoreMockupCameraPlacement placement;
  final CoreMockupDeviceEdge cameraEdge;
  final CoreMockupDeviceRect camera;
  final CoreMockupDeviceRect? lens;
  final CoreMockupDeviceRect core;
  final CoreMockupDeviceRect highlight;
  final double cameraRadius;
  final double? lensRadius;
  final double coreRadius;

  final CoreMockupDeviceRect power;
  final CoreMockupDeviceEdge powerEdge;
  final CoreMockupDeviceRect volumeUp;
  final CoreMockupDeviceRect? volumeDown;
  final CoreMockupDeviceEdge volumeEdge;

  final List<_Band> antenna;

  /// Screen-space home indicator instance box and bar.
  final CoreMockupDeviceRect gestureArea;
  final CoreMockupDeviceRect gestureBar;
  final double gestureBarRadius;

  /// Insets (screen px) each part reserves while visible.
  final double statusTop;
  final double cameraTop;
  final double cameraLeft;
}

final List<_Band> _phonePortraitAntenna = [
  (edge: CoreMockupDeviceEdge.top, rect: _r(122.441, 0, 1.9, 3)),
  (edge: CoreMockupDeviceEdge.left, rect: _r(0, 35.782, 3, 1.9)),
  (edge: CoreMockupDeviceEdge.right, rect: _r(157, 35.782, 3, 1.9)),
  (edge: CoreMockupDeviceEdge.left, rect: _r(0, 290.355, 3, 1.9)),
  (edge: CoreMockupDeviceEdge.right, rect: _r(157, 290.355, 3, 1.9)),
  (edge: CoreMockupDeviceEdge.bottom, rect: _r(31.549, 325, 1.9, 3)),
];

final List<_Band> _phoneLandscapeAntenna = [
  (edge: CoreMockupDeviceEdge.top, rect: _r(35.782, 0, 1.9, 3)),
  (edge: CoreMockupDeviceEdge.top, rect: _r(290.355, 0, 1.9, 3)),
  (edge: CoreMockupDeviceEdge.bottom, rect: _r(35.782, 157, 1.9, 3)),
  (edge: CoreMockupDeviceEdge.bottom, rect: _r(290.355, 157, 1.9, 3)),
  (edge: CoreMockupDeviceEdge.left, rect: _r(0, 31.549, 3, 1.9)),
  (edge: CoreMockupDeviceEdge.right, rect: _r(325, 122.441, 3, 1.9)),
];

final List<_Member> _members = [
  _Member(
    name: 'phone portrait',
    device: CoreMockupDevice.phone,
    orientation: CoreMockupOrientation.portrait,
    width: 160,
    height: 328,
    bodyRadius: 24,
    bezelRadius: 21,
    screenRadius: 16,
    bezel: _r(3, 3, 154, 322),
    screen: _r(8, 8, 144, 312),
    placement: CoreMockupCameraPlacement.screen,
    cameraEdge: CoreMockupDeviceEdge.top,
    camera: _r(49.5, 4, 45, 13),
    lens: _r(84.75, 7.25, 6.5, 6.5),
    core: _r(86.05, 8.55, 3.9, 3.9),
    highlight: _r(86.57, 8.81, 1.04, 1.04),
    cameraRadius: 6.5,
    lensRadius: 3.25,
    coreRadius: 1.95,
    power: _r(159.5, 98.4, 2, 40),
    powerEdge: CoreMockupDeviceEdge.right,
    volumeUp: _r(-1.5, 65.6, 2, 26),
    volumeDown: _r(-1.5, 99.6, 2, 26),
    volumeEdge: CoreMockupDeviceEdge.left,
    antenna: _phonePortraitAntenna,
    gestureArea: _r(0, 299.821, 144, 12.179),
    gestureBar: _r(46.209, 307.343, 51.582, 1.791),
    gestureBarRadius: 0.716,
    statusTop: 21.134,
    cameraTop: 21,
    cameraLeft: 0,
  ),
  _Member(
    name: 'phone landscape',
    device: CoreMockupDevice.phone,
    orientation: CoreMockupOrientation.landscape,
    width: 328,
    height: 160,
    bodyRadius: 24,
    bezelRadius: 21,
    screenRadius: 16,
    bezel: _r(3, 3, 322, 154),
    screen: _r(8, 8, 312, 144),
    placement: CoreMockupCameraPlacement.screen,
    cameraEdge: CoreMockupDeviceEdge.left,
    camera: _r(4, 49.5, 13, 45),
    lens: _r(7.25, 52.75, 6.5, 6.5),
    core: _r(8.55, 54.05, 3.9, 3.9),
    highlight: _r(9.07, 54.31, 1.04, 1.04),
    cameraRadius: 6.5,
    lensRadius: 3.25,
    coreRadius: 1.95,
    power: _r(189.6, 159.5, 40, 2),
    powerEdge: CoreMockupDeviceEdge.bottom,
    volumeUp: _r(65.6, -1.5, 26, 2),
    volumeDown: _r(99.6, -1.5, 26, 2),
    volumeEdge: CoreMockupDeviceEdge.top,
    antenna: _phoneLandscapeAntenna,
    gestureArea: _r(0, 136.503, 312, 7.497),
    gestureBar: _r(118.696, 139.359, 74.609, 1.785),
    gestureBarRadius: 0.714,
    // The canvas draws no status bar on a phone on its side.
    statusTop: 0,
    cameraTop: 0,
    // Same rule as the upright pose, turned: camera x 4 + width 13 + 4.
    cameraLeft: 21,
  ),
  _Member(
    name: 'tablet portrait',
    device: CoreMockupDevice.tablet,
    orientation: CoreMockupOrientation.portrait,
    width: 321,
    height: 455,
    bodyRadius: 16,
    bezelRadius: 13,
    screenRadius: 5,
    bezel: _r(3, 3, 315, 449),
    screen: _r(11, 11, 299, 433),
    placement: CoreMockupCameraPlacement.bezel,
    cameraEdge: CoreMockupDeviceEdge.top,
    camera: _r(155.5, 2, 4, 4),
    lens: null,
    core: _r(156.3, 2.8, 2.4, 2.4),
    highlight: _r(156.62, 2.96, 0.64, 0.64),
    cameraRadius: 2,
    lensRadius: null,
    coreRadius: 1.2,
    power: _r(238.096, -1.5, 45.433, 2),
    powerEdge: CoreMockupDeviceEdge.top,
    volumeUp: _r(-1.5, 83.642, 2, 33.317),
    volumeDown: null,
    volumeEdge: CoreMockupDeviceEdge.left,
    antenna: const [],
    gestureArea: _r(0, 425.836, 299, 7.164),
    gestureBar: _r(93.261, 428.343, 112.478, 1.791),
    gestureBarRadius: 0.716,
    statusTop: 11.463,
    cameraTop: 0,
    cameraLeft: 0,
  ),
  _Member(
    name: 'tablet landscape',
    device: CoreMockupDevice.tablet,
    orientation: CoreMockupOrientation.landscape,
    width: 455,
    height: 321,
    bodyRadius: 16,
    bezelRadius: 13,
    screenRadius: 5,
    bezel: _r(3, 3, 449, 315),
    screen: _r(11, 11, 433, 299),
    placement: CoreMockupCameraPlacement.bezel,
    cameraEdge: CoreMockupDeviceEdge.top,
    camera: _r(222.5, 2, 4, 4),
    lens: null,
    core: _r(223.3, 2.8, 2.4, 2.4),
    highlight: _r(223.62, 2.96, 0.64, 0.64),
    cameraRadius: 2,
    lensRadius: null,
    coreRadius: 1.2,
    power: _r(454.5, 49.748, 2, 49.522),
    powerEdge: CoreMockupDeviceEdge.right,
    volumeUp: _r(282.343, -1.5, 36.316, 2),
    volumeDown: null,
    volumeEdge: CoreMockupDeviceEdge.top,
    antenna: const [],
    gestureArea: _r(0, 291.836, 433, 7.164),
    gestureBar: _r(160.261, 294.343, 112.478, 1.791),
    gestureBarRadius: 0.716,
    statusTop: 11.463,
    cameraTop: 0,
    cameraLeft: 0,
  ),
];

/// Settles the style inputs the way a platform resolver does — the flat
/// (device-independent) defaults, then the per-device row — and runs the
/// shared layout rule set.
CoreMockupDeviceLayout _compute(_Member m) {
  final d = CoreMockupDeviceStyle.defaultsByDevice[m.device]!;
  return CoreMockupDeviceLayout.compute(
    device: m.device,
    orientation: m.orientation,
    width: m.width,
    railWidth: CoreMockupDeviceStyle.defaultRailWidth,
    bezelWidth: d.bezelWidth!,
    borderRadius: d.borderRadius!,
    screenAspectWidth: d.screenAspectWidth!,
    screenAspectHeight: d.screenAspectHeight!,
    cameraPlacement: d.cameraPlacement!,
    cameraWidth: d.cameraWidth!,
    cameraHeight: d.cameraHeight!,
    cameraOffset: d.cameraOffset!,
    lensSize: d.lensSize!,
    lensOffset: d.lensOffset!,
    cameraCoreSize: d.cameraCoreSize!,
    lensHighlightSizeRatio: CoreMockupDeviceStyle.defaultLensHighlightSizeRatio,
    lensHighlightOffsetXRatio:
        CoreMockupDeviceStyle.defaultLensHighlightOffsetXRatio,
    lensHighlightOffsetYRatio:
        CoreMockupDeviceStyle.defaultLensHighlightOffsetYRatio,
    buttonThickness: CoreMockupDeviceStyle.defaultButtonThickness,
    buttonProtrusion: CoreMockupDeviceStyle.defaultButtonProtrusion,
    powerButtonLength: d.powerButtonLength!,
    powerButtonOffset: d.powerButtonOffset!,
    volumeButtonLength: d.volumeButtonLength!,
    volumeButtonOffset: d.volumeButtonOffset!,
    volumeButtonSpacing: d.volumeButtonSpacing!,
    landscapePowerButtonLength: d.landscapePowerButtonLength!,
    landscapePowerButtonOffset: d.landscapePowerButtonOffset!,
    landscapeVolumeButtonLength: d.landscapeVolumeButtonLength!,
    landscapeVolumeButtonOffset: d.landscapeVolumeButtonOffset!,
    antennaBandLength: d.antennaBandLength!,
    antennaSideNearOffset: CoreMockupDeviceStyle.defaultAntennaSideNearOffset,
    antennaSideFarOffset: CoreMockupDeviceStyle.defaultAntennaSideFarOffset,
    antennaTopOffset: CoreMockupDeviceStyle.defaultAntennaTopOffset,
    antennaBottomOffset: CoreMockupDeviceStyle.defaultAntennaBottomOffset,
    rimHighlightInset: CoreMockupDeviceStyle.defaultRimHighlightInset,
    rimGlowTopInset: CoreMockupDeviceStyle.defaultRimGlowTopInset,
    rimGlowBottomInset: CoreMockupDeviceStyle.defaultRimGlowBottomInset,
    systemBarReferenceWidth: d.systemBarReferenceWidth!,
    systemBarReferenceScale: d.systemBarReferenceScale!,
    landscapeSystemBarReferenceWidth: d.landscapeSystemBarReferenceWidth!,
    landscapeSystemBarReferenceScale: d.landscapeSystemBarReferenceScale!,
    statusBarHeight: d.statusBarHeight!,
    landscapeStatusBarHeight: d.landscapeStatusBarHeight!,
    statusBarInset: d.statusBarInset!,
    statusBarContentCenter: d.statusBarContentCenter!,
    statusBarWingWidth: d.statusBarWingWidth!,
    statusBarTrailingInset: d.statusBarTrailingInset!,
    statusBarTrailingSpacing: d.statusBarTrailingSpacing!,
    statusBarClockSpacing: CoreMockupDeviceStyle.defaultStatusBarClockSpacing,
    statusBarLeadingSpacing:
        CoreMockupDeviceStyle.defaultStatusBarLeadingSpacing,
    // The deprecated pin is only ever stated, never defaulted.
    gestureBarWidthRatio:
        const CoreMockupDeviceStyle().pinnedGestureBarWidthRatio,
    gestureBarWidth: d.gestureBarWidth!,
    landscapeGestureBarWidth: d.landscapeGestureBarWidth!,
    gestureBarHeight: CoreMockupDeviceStyle.defaultGestureBarHeight,
    gestureBarOffset: CoreMockupDeviceStyle.defaultGestureBarOffset,
    gestureBarRadius: CoreMockupDeviceStyle.defaultGestureBarRadius,
    gestureBarAreaHeight: d.gestureBarAreaHeight!,
    landscapeGestureBarAreaHeight: d.landscapeGestureBarAreaHeight!,
  );
}

CoreMockupDeviceStyle _row(CoreMockupDevice device) =>
    CoreMockupDeviceStyle.defaultsByDevice[device]!;

// ─── Status bar helpers ─────────────────────────────────────────────────

/// Where a platform row puts the items of a group: laid in a row with
/// `gapAfter` between them, aligned inside the group box, every item centred
/// on the box's middle line. Text has no width of its own in Core, so a caller
/// states the measured width of the text it knows.
List<CoreMockupDeviceRect> _flow(
  CoreMockupStatusBarGroup group, {
  double textWidth = 0,
  double textHeight = 0,
}) {
  double widthOf(CoreMockupStatusBarItem item) => switch (item) {
    CoreMockupStatusBarGlyph() => item.width,
    CoreMockupStatusBarBattery() => item.width,
    CoreMockupStatusBarText() => textWidth,
  };
  double heightOf(CoreMockupStatusBarItem item) => switch (item) {
    CoreMockupStatusBarGlyph() => item.height,
    CoreMockupStatusBarBattery() => item.height,
    CoreMockupStatusBarText() => textHeight,
  };
  final items = group.items;
  var total = 0.0;
  for (var i = 0; i < items.length; i++) {
    total += widthOf(items[i]);
    if (i < items.length - 1) total += items[i].gapAfter;
  }
  var left = switch (group.alignment) {
    CoreMainAxisAlignment.start => group.box.left,
    CoreMainAxisAlignment.end => group.box.left + group.box.width - total,
    CoreMainAxisAlignment.center =>
      group.box.left + (group.box.width - total) / 2,
    _ => double.nan,
  };
  final centerY = group.box.top + group.box.height / 2;
  final rects = <CoreMockupDeviceRect>[];
  for (final item in items) {
    final height = heightOf(item);
    rects.add((
      left: left,
      top: centerY - height / 2,
      width: widthOf(item),
      height: height,
    ));
    left += widthOf(item) + item.gapAfter;
  }
  return rects;
}

/// Compares two SVG path strings token by token (commands exactly, numbers
/// within [tol]).
void _expectPath(
  _Check c,
  String what,
  String actual,
  String expected, {
  double tol = 2e-3,
}) {
  final token = RegExp(r'[MLCZ]|-?\d+(?:\.\d+)?(?:e-?\d+)?');
  final a = token.allMatches(actual).map((m) => m.group(0)!).toList();
  final e = token.allMatches(expected).map((m) => m.group(0)!).toList();
  if (a.length != e.length) {
    c.fail(what, 'expected ${e.length} path tokens actual ${a.length}');
    return;
  }
  var reported = 0;
  for (var i = 0; i < a.length; i++) {
    final isCommand = RegExp(r'^[MLCZ]$').hasMatch(e[i]);
    final bad = isCommand
        ? a[i] != e[i]
        : (double.parse(a[i]) - double.parse(e[i])).abs() > tol;
    if (bad && reported < 5) {
      c.fail(what, 'token $i expected ${e[i]} actual ${a[i]}');
      reported++;
    }
  }
}

// ─── Glyph outlines (reference size, taken from the canvas vectors) ─────

/// Canvas `phoneCellular` glyph outline at the reference (point) size.
const _kPhoneCellularPath =
    'M 19.2 1.1462 C 19.2 0.5132 18.7224 0 18.1333 0 L 17.0667 0 C '
    '16.4776 0 16 0.5132 16 1.1462 L 16 11.0802 C 16 11.7132 16.4776 '
    '12.2264 17.0667 12.2264 L 18.1333 12.2264 C 18.7224 12.2264 19.2 '
    '11.7132 19.2 11.0802 L 19.2 1.1462 Z M 11.7659 2.4453 L 12.8326 '
    '2.4453 C 13.4217 2.4453 13.8992 2.9708 13.8992 3.619 L 13.8992 '
    '11.0527 C 13.8992 11.7009 13.4217 12.2264 12.8326 12.2264 L '
    '11.7659 12.2264 C 11.1768 12.2264 10.6992 11.7009 10.6992 11.0527 '
    'L 10.6992 3.619 C 10.6992 2.9708 11.1768 2.4453 11.7659 2.4453 Z M '
    '7.4341 5.0943 L 6.3674 5.0943 C 5.7783 5.0943 5.3008 5.6265 5.3008 '
    '6.283 L 5.3008 11.0377 C 5.3008 11.6942 5.7783 12.2264 6.3674 '
    '12.2264 L 7.4341 12.2264 C 8.0232 12.2264 8.5008 11.6942 8.5008 '
    '11.0377 L 8.5008 6.283 C 8.5008 5.6265 8.0232 5.0943 7.4341 5.0943 '
    'Z M 2.1333 7.5396 L 1.0667 7.5396 C 0.4776 7.5396 0 8.0642 0 '
    '8.7113 L 0 11.0547 C 0 11.7018 0.4776 12.2264 1.0667 12.2264 L '
    '2.1333 12.2264 C 2.7224 12.2264 3.2 11.7018 3.2 11.0547 L 3.2 '
    '8.7113 C 3.2 8.0642 2.7224 7.5396 2.1333 7.5396 Z';

/// Canvas `phoneWifi` glyph outline at the reference (point) size.
const _kPhoneWifiPath =
    'M 8.5713 2.4663 C 11.0584 2.4664 13.4504 3.3885 15.2529 5.0419 C '
    '15.3887 5.1696 15.6056 5.168 15.7393 5.0383 L 17.0368 3.7749 C '
    '17.1045 3.7091 17.1422 3.62 17.1417 3.5274 C 17.1411 3.4347 '
    '17.1023 3.346 17.0338 3.281 C 12.3028 -1.0937 4.8391 -1.0937 '
    '0.1081 3.281 C 0.0395 3.346 0.0006 3.4346 0 3.5273 C -0.0006 3.62 '
    '0.037 3.7091 0.1047 3.7749 L 1.4026 5.0383 C 1.5362 5.1682 1.7533 '
    '5.1698 1.8889 5.0419 C 3.6917 3.3884 6.0839 2.4663 8.5713 2.4663 Z '
    'M 8.5679 6.6866 C 9.9253 6.6865 11.2341 7.1982 12.2403 8.1223 C '
    '12.3763 8.2535 12.5907 8.2507 12.7234 8.1159 L 14.0106 6.7966 C '
    '14.0784 6.7274 14.1161 6.6335 14.1151 6.536 C 14.1141 6.4384 '
    '14.0746 6.3454 14.0054 6.2776 C 10.9416 3.3867 6.1969 3.3867 3.133 '
    '6.2776 C 3.0638 6.3454 3.0244 6.4385 3.0234 6.5361 C 3.0225 6.6337 '
    '3.0603 6.7275 3.1282 6.7966 L 4.4151 8.1159 C 4.5478 8.2507 4.7621 '
    '8.2535 4.8982 8.1223 C 5.9037 7.1988 7.2115 6.6871 8.5679 6.6866 Z '
    'M 11.0924 9.4801 C 11.0943 9.5855 11.0572 9.687 10.9899 9.7608 L '
    '8.8133 12.2156 C 8.7495 12.2877 8.6625 12.3283 8.5717 12.3283 C '
    '8.4809 12.3283 8.3939 12.2877 8.3301 12.2156 L 6.1531 9.7608 C '
    '6.0859 9.687 6.0489 9.5854 6.0509 9.48 C 6.0528 9.3747 6.0937 '
    '9.2749 6.1636 9.2043 C 7.5537 7.8904 9.5897 7.8904 10.9798 9.2043 '
    'C 11.0497 9.275 11.0904 9.3748 11.0924 9.4801 Z';

/// Canvas `phoneBatteryCap` glyph outline at the reference (point) size.
const _kPhoneBatteryCapPath =
    'M 0 0 L 0 4.0755 C 0.8047 3.7303 1.328 2.9273 1.328 2.0377 C 1.328 '
    '1.1481 0.8047 0.3452 0 0 Z';

/// Canvas `tabletWifi` glyph outline at the reference (point) size.
const _kTabletWifiPath =
    'M 0.2904 3.8671 C 0.63 4.2168 1.1593 4.1569 1.5887 3.7772 C 3.0068 '
    '2.4981 4.7744 1.8386 6.7518 1.8386 C 8.7291 1.8386 10.5067 2.5181 '
    '11.9148 3.7772 C 12.3343 4.1669 12.8635 4.2068 13.2131 3.8671 C '
    '13.5626 3.5074 13.6125 2.9678 13.253 2.5881 C 11.755 1.0592 9.3083 '
    '0 6.7518 0 C 4.1952 0 1.7385 1.0692 0.2505 2.5981 C -0.109 2.9678 '
    '-0.0691 3.5074 0.2904 3.8771 L 0.2904 3.8671 Z M 2.7571 6.3752 C '
    '3.1466 6.7549 3.6459 6.715 4.0853 6.3552 C 4.8044 5.7857 5.7631 '
    '5.396 6.7518 5.4059 C 7.7304 5.4059 8.6892 5.7857 9.4182 6.3652 C '
    '9.8576 6.725 10.3769 6.7449 10.7564 6.3652 C 11.1259 5.9855 '
    '11.1858 5.4059 10.7963 5.0462 C 9.8276 4.1769 8.3696 3.5673 6.7617 '
    '3.5673 C 5.1539 3.5673 3.6859 4.1769 2.7272 5.0462 C 2.3876 5.366 '
    '2.3177 5.9156 2.7671 6.3752 L 2.7571 6.3752 Z M 6.0926 9.6927 C '
    '6.5221 10.1024 6.9715 10.1024 7.4009 9.6927 L 8.2098 8.9133 C '
    '8.6392 8.4936 8.7291 7.964 8.2398 7.6043 C 7.8303 7.3145 7.311 '
    '7.1247 6.7518 7.1247 C 6.1925 7.1247 5.6632 7.3145 5.2638 7.6143 C '
    '4.7744 7.964 4.8743 8.5036 5.3037 8.9133 L 6.1026 9.6927 L 6.0926 '
    '9.6927 Z';

/// Canvas `tabletBattery` glyph outline at the reference (point) size.
const _kTabletBatteryPath =
    'M 26.0024 4.32 L 26.0024 8.3292 C 26.4026 8.219 27.333 7.3269 '
    '27.333 6.3246 C 27.333 5.3223 26.4026 4.4302 26.0024 4.32 Z M '
    '25.0019 7.4973 C 25.0019 7.7078 25.0019 7.9183 25.0019 8.1288 C '
    '25.0019 8.3092 25.0019 8.4796 25.0019 8.66 C 24.9919 9.0509 '
    '24.9719 9.4318 24.9018 9.8227 C 24.8318 10.2136 24.7218 10.5744 '
    '24.5417 10.9252 C 24.3616 11.276 24.1315 11.5867 23.8613 11.8574 C '
    '23.5912 12.128 23.2711 12.3585 22.9309 12.5389 C 22.5807 12.7194 '
    '22.2206 12.8296 21.8304 12.8998 C 21.4502 12.9699 21.06 12.99 '
    '20.6698 13 C 20.4897 13 20.3197 13 20.1396 13 C 19.9295 13 19.7194 '
    '13 19.5093 13 L 5.4926 13 C 5.2825 13 5.0724 13 4.8623 13 C 4.6822 '
    '13 4.5121 13 4.3321 13 C 3.9419 12.99 3.5617 12.9699 3.1715 '
    '12.8998 C 2.7813 12.8296 2.4212 12.7194 2.071 12.5389 C 1.7308 '
    '12.3585 1.4107 12.128 1.1405 11.8574 C 0.8704 11.5867 0.6403 '
    '11.266 0.4602 10.9252 C 0.2801 10.5744 0.1701 10.2136 0.1 9.8227 C '
    '0.03 9.4418 0.01 9.0509 0 8.66 C 0 8.4796 0 8.3092 0 8.1288 C 0 '
    '7.9183 0 7.7078 0 7.4973 L 0 5.4927 C 0 5.2822 0 5.0717 0 4.8612 C '
    '0 4.6808 0 4.5104 0 4.33 C 0.01 3.9391 0.03 3.5582 0.1 3.1773 C '
    '0.1701 2.7864 0.2801 2.4256 0.4602 2.0748 C 0.6403 1.724 0.8704 '
    '1.4133 1.1405 1.1426 C 1.4107 0.872 1.7308 0.6415 2.071 0.4611 C '
    '2.4212 0.2806 2.7813 0.1704 3.1715 0.1002 C 3.5517 0.0301 3.9419 '
    '0.01 4.3321 0 C 4.5121 0 4.6822 0 4.8623 0 C 5.0724 0 5.2825 0 '
    '5.4926 0 L 19.4993 0 C 19.7094 0 19.9195 0 20.1296 0 C 20.3097 0 '
    '20.4797 0 20.6598 0 C 21.05 0.01 21.4302 0.0301 21.8204 0.1002 C '
    '22.2106 0.1704 22.5707 0.2806 22.9209 0.4611 C 23.2711 0.6415 '
    '23.5812 0.872 23.8513 1.1426 C 24.1215 1.4133 24.3516 1.734 '
    '24.5317 2.0748 C 24.7118 2.4256 24.8218 2.7864 24.8918 3.1773 C '
    '24.9619 3.5582 24.9819 3.9491 24.9919 4.33 C 24.9919 4.5104 '
    '24.9919 4.6808 24.9919 4.8612 C 24.9919 5.0717 24.9919 5.2822 '
    '24.9919 5.4927 L 24.9919 7.4973 L 25.0019 7.4973 Z';

// ─── Hardware colours: the designer copy's literals ──────────────────────

/// A hardware colour layer, with the value the canvas prints for it.
typedef _Layer = ({String name, CoreColor color, String hex});

/// One layer per stop of [gradient]; a missing stop is an empty colour, which
/// the value check then reports.
List<_Layer> _stopLayers(
  String name,
  CoreGradient gradient,
  List<String> hexes,
) => [
  for (var i = 0; i < hexes.length; i++)
    (
      name: '$name[$i]',
      color: i < gradient.colors.length
          ? gradient.colors[i]
          : CoreColor.transparent,
      hex: hexes[i],
    ),
];

/// Every hardware colour of the device, written with the value the canvas
/// prints.
List<_Layer> _hardwareLayers() => [
  (
    name: 'body solid',
    color: CoreMockupDeviceStyle.defaultRailColor,
    hex: '#7d7f82',
  ),
  ..._stopLayers('body gradient', CoreMockupDeviceStyle.defaultRailGradient, [
    '#c3c4c6',
    '#7d7f82',
    '#7d7f82',
    '#aeafb2',
  ]),
  (
    name: 'body border',
    color: CoreMockupDeviceStyle.defaultBorderColor,
    hex: '#646568',
  ),
  (
    name: 'rim highlight',
    color: CoreMockupDeviceStyle.defaultRimHighlightColor,
    hex: '#ffffff',
  ),
  ..._stopLayers('antenna band', CoreMockupDeviceStyle.defaultAntennaGradient, [
    '#fcfcfd',
    '#e4e5e7',
  ]),
  (
    name: 'side button base',
    color: CoreMockupDeviceStyle.defaultButtonColor,
    hex: '#aeafb2',
  ),
  (
    name: 'bezel fill',
    color: CoreMockupDeviceStyle.defaultBezelColor,
    hex: '#000000',
  ),
  (
    name: 'bezel outline',
    color: CoreMockupDeviceStyle.defaultBezelBorderColor,
    hex: '#27282b',
  ),
  (
    name: 'camera / lens fill',
    color: CoreMockupDeviceStyle.defaultLensColor,
    hex: '#000000',
  ),
  (
    name: 'camera pill fill',
    color: CoreMockupDeviceStyle.defaultCutoutColor,
    hex: '#000000',
  ),
  ..._stopLayers('core', CoreMockupDeviceStyle.defaultCoreGradient, [
    '#000000',
    '#0a3348',
    '#0c3b52',
    '#105171',
    '#0c3b52',
    '#000000',
  ]),
  (
    name: 'lens highlight',
    color: CoreMockupDeviceStyle.defaultLensHighlightColor,
    hex: '#ffffff',
  ),
];

/// The colour sources an app can render from: CoUI's own palette, and a
/// chromatic brand's read through the standard mapping.
final Map<String, CoreSchemeSource> _kSources = {
  'coui': CouiColorPresets.source,
  'brand': kBrandFixtureSource,
};

/// The scheme every component reads for one mode of one source.
CoreColorScheme _scheme(
  CoreSchemeSource source, {
  required CoreBrightness brightness,
  required bool highContrast,
}) => resolveThemeSchemeFrom(
  source,
  brightness: brightness,
  highContrast: highContrast,
);

/// The four modes a hardware colour must not follow: Light, Dark, and both
/// high-contrast modes.
const List<({String name, CoreBrightness brightness, bool highContrast})>
_kModes = [
  (name: 'light', brightness: CoreBrightness.light, highContrast: false),
  (name: 'dark', brightness: CoreBrightness.dark, highContrast: false),
  (
    name: 'high-contrast light',
    brightness: CoreBrightness.light,
    highContrast: true,
  ),
  (
    name: 'high-contrast dark',
    brightness: CoreBrightness.dark,
    highContrast: true,
  ),
];

void main() {
  for (final m in _members) {
    group(m.name, () {
      _check('${m.name} / body size', (c) {
        final l = _compute(m);
        c
          ..close('body width', l.deviceWidth, m.width)
          ..close('body height', l.deviceHeight, m.height);
      });

      _check('${m.name} / body radius', (c) {
        c.radiusAll('body radius', _row(m.device).borderRadius!, m.bodyRadius);
      });

      _check('${m.name} / bezel box and radius', (c) {
        final l = _compute(m);
        c
          ..rect('bezel box', l.bezelBox, m.bezel)
          ..radiusAll('bezel radius', l.bezelBorderRadius, m.bezelRadius);
      });

      _check('${m.name} / screen box and radius', (c) {
        final l = _compute(m);
        c
          ..rect('screen box', l.screenBox, m.screen)
          ..close('screen width', l.screenWidth, m.screen.width)
          ..close('screen height', l.screenHeight, m.screen.height)
          ..radiusAll('screen radius', l.screenBorderRadius, m.screenRadius);
      });

      _check('${m.name} / camera set', (c) {
        final l = _compute(m);
        c
          ..same('camera placement', l.cameraPlacement, m.placement)
          ..same('camera edge', l.cameraEdge, m.cameraEdge)
          ..rect('camera', l.camera, m.camera);
        final lens = l.lens;
        if (m.lens == null) {
          c
            ..same('lens present', lens != null, false)
            ..same('camera is the lens (no ring)', l.cameraIsLens, true);
        } else if (lens == null) {
          c.fail('lens', 'expected a ring, layout has none');
        } else {
          c
            ..same('camera is the lens (no ring)', l.cameraIsLens, false)
            ..rect('lens', lens, m.lens!);
        }
        c
          ..rect('core', l.core, m.core)
          ..rect('lens highlight', l.lensHighlight, m.highlight);
        // The corner radius of every pill / circle is half its short side.
        double half(CoreMockupDeviceRect r) =>
            (r.width < r.height ? r.width : r.height) / 2;
        c.close(
          'camera radius (half short side)',
          half(l.camera),
          m.cameraRadius,
        );
        if (lens != null && m.lensRadius != null) {
          c.close('lens radius (half short side)', half(lens), m.lensRadius!);
        }
        c.close('core radius (half short side)', half(l.core), m.coreRadius);
      });

      _check('${m.name} / power button', (c) {
        final l = _compute(m);
        c
          ..rect('power button', l.powerButton, m.power)
          ..same('power button edge', l.powerButtonEdge, m.powerEdge);
        final short = l.powerButton.width < l.powerButton.height
            ? l.powerButton.width
            : l.powerButton.height;
        c
          ..close('power button thickness', short, 2)
          ..close('power button radius (half thickness)', short / 2, 1);
      });

      _check('${m.name} / volume buttons', (c) {
        final l = _compute(m);
        c
          ..rect('volume up', l.volumeUpButton, m.volumeUp)
          ..same('volume button edge', l.volumeButtonEdge, m.volumeEdge);
        final down = l.volumeDownButton;
        if (m.volumeDown == null) {
          c.same('volume down present', down != null, false);
        } else if (down == null) {
          c.fail('volume down', 'expected a button, layout has none');
        } else {
          c.rect('volume down', down, m.volumeDown!);
        }
      });

      _check('${m.name} / antenna bands', (c) {
        final l = _compute(m);
        final actual = [...l.antennaBands]
          ..sort((a, b) {
            final byLeft = a.rect.left.compareTo(b.rect.left);
            return byLeft != 0 ? byLeft : a.rect.top.compareTo(b.rect.top);
          });
        final expected = [...m.antenna]
          ..sort((a, b) {
            final byLeft = a.rect.left.compareTo(b.rect.left);
            return byLeft != 0 ? byLeft : a.rect.top.compareTo(b.rect.top);
          });
        c.same('band count', actual.length, expected.length);
        if (actual.length == expected.length) {
          for (var i = 0; i < expected.length; i++) {
            final e = expected[i];
            final label =
                'band ${e.edge.name} at '
                '(${e.rect.left}, ${e.rect.top})';
            c
              ..rect(label, actual[i].rect, e.rect)
              ..same('$label / edge', actual[i].edge, e.edge);
          }
        }
      });

      _check('${m.name} / rim highlight and rim glow rectangles', (c) {
        final l = _compute(m);
        // Both strokes span the body width and are inset only at the top and
        // the bottom (0.4 / 0.4 and 0.8 / 0.4); the canvas draws them in both
        // orientations.
        c
          ..rect(
            'rim highlight',
            l.rimHighlight,
            _r(0, 0.4, m.width, m.height - 0.8),
          )
          ..rect('rim glow', l.rimGlow, _r(0, 0.8, m.width, m.height - 1.2));
      });

      _check('${m.name} / home indicator', (c) {
        final l = _compute(m);
        c
          ..rect('area', l.gestureBarArea, m.gestureArea)
          ..rect('bar', l.gestureBar, m.gestureBar)
          ..close('bar radius', l.gestureBarRadius, m.gestureBarRadius)
          // The bar stands 8 pt (scaled) above the bottom edge: 2.866 px.
          ..close(
            'bar gap to the bottom edge',
            l.screenHeight - (l.gestureBar.top + l.gestureBar.height),
            2.866,
          );
      });

      _check('${m.name} / derived safe-area insets', (c) {
        final l = _compute(m);
        for (final camera in [true, false]) {
          for (final status in [true, false]) {
            for (final gesture in [true, false]) {
              final got = l.safeAreaInsets(
                showCamera: camera,
                showStatusBar: status,
                showGestureBar: gesture,
              );
              final flags = 'camera=$camera status=$status gesture=$gesture';
              final statusTop = status ? m.statusTop : 0.0;
              final cameraTop = camera ? m.cameraTop : 0.0;
              c
                ..close(
                  '$flags / top',
                  got.top,
                  statusTop > cameraTop ? statusTop : cameraTop,
                )
                ..close(
                  '$flags / bottom',
                  got.bottom,
                  gesture ? m.gestureArea.height : 0,
                )
                ..close('$flags / left', got.left, camera ? m.cameraLeft : 0)
                ..close('$flags / right', got.right, 0);
            }
          }
        }
      });
    });
  }

  // ─── Status bar (phone portrait, tablet portrait, tablet landscape) ────

  group('status bar', () {
    _check('phone landscape / no status bar', (c) {
      final l = _compute(_members[1]);
      c.same('status bar', l.statusBar, null);
    });

    _check('phone portrait / status bar', (c) {
      final l = _compute(_members[0]);
      final bar = l.statusBar;
      if (bar == null) {
        c.fail('status bar', 'expected a status bar, layout has none');
        return;
      }
      c
        ..rect('box', bar.rect, _r(0, 0, 144, 21.134))
        // 144 / 402: the canvas draws the bar at 0.3582 of its point size.
        ..close('scale', bar.scale, 144 / 402, tol: 5e-4)
        ..close('content line y', bar.contentCenter, 11.642);

      final leading = bar.leading;
      c
        ..same(
          'leading alignment',
          leading.alignment,
          CoreMainAxisAlignment.center,
        )
        ..close('leading box left', leading.box.left, 8.597)
        ..close('leading box width', leading.box.width, 36.179)
        ..close(
          'leading box centre y',
          leading.box.top + leading.box.height / 2,
          11.642,
        )
        // The clock text box (12 x 8 at 20.687, 7.642) is centred in the box.
        ..close(
          'clock centre x',
          leading.box.left + leading.box.width / 2,
          20.687 + 12 / 2,
        )
        ..same('leading item count', leading.items.length, 1);
      if (leading.items.isNotEmpty) {
        final clock = leading.items.first;
        if (clock is CoreMockupStatusBarText) {
          c.same('clock text', clock.text, '9:41');
        } else {
          c.fail('clock', 'expected a text item, got ${clock.runtimeType}');
        }
      }

      final trailing = bar.trailing;
      c
        ..same(
          'trailing alignment',
          trailing.alignment,
          CoreMainAxisAlignment.center,
        )
        // The Levels frame is 36.179 wide at 99.224 with 2 pt (0.716) of
        // padding on its right.
        ..close('trailing box left', trailing.box.left, 99.224)
        ..close(
          'trailing box right',
          trailing.box.left + trailing.box.width,
          99.224 + 36.179 - 0.716,
        )
        ..close(
          'trailing box centre y',
          trailing.box.top + trailing.box.height / 2,
          11.642,
        );
      final items = trailing.items;
      if (items.length != 3 ||
          items[0] is! CoreMockupStatusBarGlyph ||
          items[1] is! CoreMockupStatusBarGlyph ||
          items[2] is! CoreMockupStatusBarBattery) {
        c.fail(
          'trailing items',
          'expected cellular glyph, wifi glyph, battery; got '
              '${items.map((i) => i.runtimeType).toList()}',
        );
        return;
      }
      final cellular = items[0] as CoreMockupStatusBarGlyph;
      final wifi = items[1] as CoreMockupStatusBarGlyph;
      final battery = items[2] as CoreMockupStatusBarBattery;
      c
        ..close('gap after cellular (6 pt)', cellular.gapAfter, 2.149)
        ..close('gap after wifi (6 pt)', wifi.gapAfter, 2.149)
        ..close('gap after battery', battery.gapAfter, 0);
      final flowed = _flow(trailing);
      c
        ..rect('cellular', flowed[0], _r(103.403, 9.452, 6.878, 4.38))
        ..rect('wifi', flowed[1], _r(112.429, 9.433, 6.14, 4.416))
        ..rect('battery box', flowed[2], _r(120.719, 9.313, 9.789, 4.657))
        // The three battery parts, relative to the battery box. The canvas
        // draws them 0.015 px left of their ideal 0 / 2 / 26 pt positions.
        ..rect('battery outline', battery.border, _r(-0.015, 0, 8.955, 4.657))
        ..close('battery outline stroke', battery.borderWidth, 0.358)
        ..close('battery outline radius', battery.borderRadius, 1.433)
        ..rect(
          'battery level',
          battery.capacity,
          _r(0.701, 0.716, 7.522, 3.224),
        )
        ..close('battery level radius', battery.capacityRadius, 0.716)
        ..rect('battery nub', battery.cap, _r(9.299, 1.612, 0.476, 1.46))
        ..same(
          'battery nub fill rule',
          battery.capGlyph.fillRule,
          CoreVectorFillRule.nonZero,
        );
      _expectPath(
        c,
        'battery nub path',
        battery.capGlyph.path,
        _kPhoneBatteryCapPath,
      );
      c.same(
        'cellular fill rule',
        cellular.glyph.fillRule,
        CoreVectorFillRule.evenOdd,
      );
      _expectPath(c, 'cellular path', cellular.glyph.path, _kPhoneCellularPath);
      c.same('wifi fill rule', wifi.glyph.fillRule, CoreVectorFillRule.evenOdd);
      _expectPath(c, 'wifi path', wifi.glyph.path, _kPhoneWifiPath);
      // A glyph's own box is in reference points: drawn size = box x scale.
      c
        ..close('cellular box x scale', cellular.glyph.width * bar.scale, 6.878)
        ..close('cellular box y scale', cellular.glyph.height * bar.scale, 4.38)
        ..close('wifi box x scale', wifi.glyph.width * bar.scale, 6.14)
        ..close('wifi box y scale', wifi.glyph.height * bar.scale, 4.416);
    });

    for (final m in [_members[2], _members[3]]) {
      _check('${m.name} / status bar', (c) {
        final l = _compute(m);
        final bar = l.statusBar;
        if (bar == null) {
          c.fail('status bar', 'expected a status bar, layout has none');
          return;
        }
        final w = m.screen.width;
        c
          ..rect('box', bar.rect, _r(0, 0, w, 11.463))
          ..close('scale', bar.scale, 144 / 402, tol: 5e-4)
          ..close('content line y', bar.contentCenter, 5.731);

        // Horizontal padding 5.731, space between: the leading group starts
        // at the padding, the trailing group ends at it.
        final leading = bar.leading;
        c
          ..same(
            'leading alignment',
            leading.alignment,
            CoreMainAxisAlignment.start,
          )
          ..close('leading group left', leading.box.left, 5.731)
          ..close(
            'leading box centre y',
            leading.box.top + leading.box.height / 2,
            5.731,
          );
        final lead = leading.items;
        final leadText = <String>[];
        final leadGaps = <double>[];
        for (final item in lead) {
          if (item is CoreMockupStatusBarText) {
            leadText.add(item.text);
          } else {
            leadText.add('<${item.runtimeType}>');
          }
          leadGaps.add(item.gapAfter);
        }
        c.same('leading items', leadText.join(' | '), '9:41 | 오전 | 4월 1일 수요일');
        if (leadGaps.length == 3) {
          c
            ..close('gap clock to AM', leadGaps[0], 0.716)
            ..close('gap AM to date', leadGaps[1], 2.866)
            ..close('gap after date', leadGaps[2], 0);
        }

        final trailing = bar.trailing;
        c
          ..same(
            'trailing alignment',
            trailing.alignment,
            CoreMainAxisAlignment.end,
          )
          ..close(
            'trailing group right',
            trailing.box.left + trailing.box.width,
            w - 5.731,
          )
          ..close(
            'trailing box centre y',
            trailing.box.top + trailing.box.height / 2,
            5.731,
          );
        final items = trailing.items;
        if (items.length != 3 ||
            items[0] is! CoreMockupStatusBarGlyph ||
            items[1] is! CoreMockupStatusBarText ||
            items[2] is! CoreMockupStatusBarGlyph) {
          c.fail(
            'trailing items',
            'expected wifi glyph, "100%" text, battery glyph; got '
                '${items.map((i) => i.runtimeType).toList()}',
          );
          return;
        }
        final wifi = items[0] as CoreMockupStatusBarGlyph;
        final percent = items[1] as CoreMockupStatusBarText;
        final battery = items[2] as CoreMockupStatusBarGlyph;
        c
          ..same('percent text', percent.text, '100%')
          ..close('gap after wifi', wifi.gapAfter, 1.433)
          ..close('gap after percent', percent.gapAfter, 1.433)
          ..close('gap after battery', battery.gapAfter, 0)
          ..close('wifi width', wifi.width, 4.836)
          ..close('wifi height', wifi.height, 3.582)
          ..close('battery width', battery.width, 9.791)
          ..close('battery height', battery.height, 4.657);
        // Flow with the measured width of "100%" (a 13 x 6 text box); the
        // portrait trailing frame starts at 262.773, the landscape frame sits
        // the width difference (433 - 299) further right.
        final flowed = _flow(trailing, textWidth: 13, textHeight: 6);
        final shift = w - 299;
        c
          ..close('wifi left', flowed[0].left, 262.773 + shift)
          ..close(
            'percent left',
            flowed[1].left,
            262.773 + 4.839 + 1.433 + shift,
          )
          ..close('battery left', flowed[2].left, 283.478 + shift)
          ..close(
            'trailing group width (frame 30.496)',
            wifi.width + 1.433 + 13 + 1.433 + battery.width,
            30.496,
            tol: 0.01,
          )
          // Items are centred on the 6-high frame (y 2.731 .. 8.731); their own
          // y is not in the measurements, the frame is.
          ..close('wifi centre y', flowed[0].top + flowed[0].height / 2, 5.731)
          ..close(
            'battery centre y',
            flowed[2].top + flowed[2].height / 2,
            5.731,
          )
          ..same(
            'wifi fill rule',
            wifi.glyph.fillRule,
            CoreVectorFillRule.evenOdd,
          );
        _expectPath(c, 'wifi path', wifi.glyph.path, _kTabletWifiPath);
        c.same(
          'battery fill rule',
          battery.glyph.fillRule,
          CoreVectorFillRule.evenOdd,
        );
        _expectPath(c, 'battery path', battery.glyph.path, _kTabletBatteryPath);
        c
          ..close('wifi box x scale', wifi.glyph.width * bar.scale, 4.836)
          ..close('wifi box y scale', wifi.glyph.height * bar.scale, 3.582)
          ..close('battery box x scale', battery.glyph.width * bar.scale, 9.791)
          ..close(
            'battery box y scale',
            battery.glyph.height * bar.scale,
            4.657,
          );
      });
    }

    _check('status bar text roles', (c) {
      // Phone clock: Pretendard 16 pt at reference size, bound to the
      // title-small variables — so its weight is the title roles' weight,
      // SemiBold 600; tablet texts: Medium 14 pt. Letter spacing -0.01 em; the
      // canvas draws them at 5.731 / 5.015 px and -0.0573 / -0.0501 px.
      final phone = _row(CoreMockupDevice.phone).statusBarTextStyle!;
      final tablet = _row(CoreMockupDevice.tablet).statusBarTextStyle!;
      c
        ..same('phone role', phone.token, CoreTextStyles.titleSmall)
        ..tokenColor('phone text colour', phone.color!, CoreColors.onSurface)
        ..tokenColor('tablet text colour', tablet.color!, CoreColors.onSurface);
      final phoneRole = phone.token!.read(CoreTypography.coui);
      final tabletRole = tablet.token!.read(CoreTypography.coui);
      c
        ..close('phone role size', phoneRole.fontSize!, 16)
        ..same('phone role weight', phoneRole.fontWeight, 600)
        ..close('phone role tracking (em)', phoneRole.letterSpacing!, -0.01)
        ..close('tablet role size', tabletRole.fontSize!, 14)
        ..same('tablet role weight', tabletRole.fontWeight, 500)
        ..close('tablet role tracking (em)', tabletRole.letterSpacing!, -0.01);
      const s = 144 / 402;
      c
        ..close('phone text px (16 x scale)', 16 * s, 5.731)
        ..close('tablet text px (14 x scale)', 14 * s, 5.015)
        ..close('phone tracking px', -0.01 * 16 * s, -0.0573)
        ..close('tablet tracking px', -0.01 * 14 * s, -0.0501);
    });
  });

  // ─── Paint data ─────────────────────────────────────────────────────────

  group('paint data', () {
    _check('body fill gradient', (c) {
      // Top to bottom (gradient transform [[0,1,0],[-1,0,1]]: t = y).
      c
        ..gradient(
          'default rail gradient',
          CoreMockupDeviceStyle.defaultRailGradient,
          type: CoreGradientType.linear,
          stops: [0, 0.1, 0.9, 1],
          colors: ['#c3c4c6', '#7d7f82', '#7d7f82', '#aeafb2'],
          begin: CoreAlignment.topCenter,
          end: CoreAlignment.bottomCenter,
        )
        // The solid body fill is the gradient's middle colour.
        ..color(
          'body solid (the gradient middle)',
          CoreMockupDeviceStyle.defaultRailColor,
          '#7d7f82',
        );
      final painted = CoreMockupDeviceStyle.resolveBodyGradient();
      if (painted == null) {
        c.fail('painted body fill', 'expected the gradient, got the solid');
      } else {
        c.same(
          'painted body fill',
          painted,
          CoreMockupDeviceStyle.defaultRailGradient,
        );
      }
    });

    _check('body border and body shadow', (c) {
      c
        ..color(
          'border colour',
          CoreMockupDeviceStyle.defaultBorderColor,
          '#646568',
        )
        ..close(
          'border width',
          CoreMockupDeviceStyle.defaultBorderWidth,
          1,
          tol: 1e-9,
        );
      final shadow = CoreMockupDeviceStyle.defaultContainerStyle.boxShadow;
      if (shadow == null || shadow.length != 2) {
        c.fail('shadow layers', 'expected 2 layers, got ${shadow?.length}');
        return;
      }
      // DROP_SHADOW #00000014 (0, 14) blur 28 spread -5 and #0000000D (0, 6)
      // blur 10 spread -3 — the v1 two-layer cast the device is pinned to
      // (#5485, `defaultBodyShadow`); alpha compared as the canvas's 8-bit
      // byte.
      // The colour is black with no variable bound, so the code states it as
      // a literal rather than reading the palette's `shadow` slot.
      c.same(
        'shadow base colour (literal black, no slot)',
        CoreMockupDeviceStyle.defaultContainerStyle.shadowBaseColor,
        CoreColor(_hex('#000000')),
      );
      const expected = [
        (dx: 0.0, dy: 14.0, blur: 28.0, spread: -5.0, alpha: 0x14),
        (dx: 0.0, dy: 6.0, blur: 10.0, spread: -3.0, alpha: 0x0D),
      ];
      for (var i = 0; i < expected.length; i++) {
        final layer = shadow[i];
        final e = expected[i];
        c
          ..close('shadow[$i] offset x', layer.offsetX, e.dx, tol: 1e-9)
          ..close('shadow[$i] offset y', layer.offsetY, e.dy, tol: 1e-9)
          ..close('shadow[$i] blur', layer.blurRadius, e.blur, tol: 1e-9)
          ..close('shadow[$i] spread', layer.spreadRadius, e.spread, tol: 1e-9)
          ..same(
            'shadow[$i] alpha byte',
            (layer.opacity * 255).round(),
            e.alpha,
          )
          ..same('shadow[$i] inset', layer.inset, false);
      }
    });

    _check('rim highlight stroke', (c) {
      c
        ..color(
          'colour',
          CoreMockupDeviceStyle.defaultRimHighlightColor,
          '#ffffff',
        )
        ..close(
          'stroke width (inside)',
          CoreMockupDeviceStyle.defaultRimHighlightWidth,
          0.5,
        )
        ..close(
          'vertical inset',
          CoreMockupDeviceStyle.defaultRimHighlightInset,
          0.4,
        );
    });

    _check('rim glow stroke', (c) {
      c
        ..gradient(
          'gradient',
          CoreMockupDeviceStyle.defaultRimGlowGradient,
          type: CoreGradientType.linear,
          stops: [0, 0.51],
          colors: ['#ffffff', '#ffffff00'],
          begin: CoreAlignment.topCenter,
          end: CoreAlignment.bottomCenter,
        )
        ..close(
          'paint opacity',
          CoreMockupDeviceStyle.defaultRimGlowOpacity,
          0.5,
        )
        ..close(
          'stroke width (inside)',
          CoreMockupDeviceStyle.defaultRimGlowWidth,
          0.6,
        )
        ..close(
          'top inset',
          CoreMockupDeviceStyle.defaultRimGlowTopInset,
          0.8,
        )
        ..close(
          'bottom inset',
          CoreMockupDeviceStyle.defaultRimGlowBottomInset,
          0.4,
        )
        ..close('layer blur', CoreMockupDeviceStyle.defaultRimGlowBlur, 0.8);
    });

    _check('bezel fill, outline and inner shadow', (c) {
      c
        ..color(
          'fill',
          CoreMockupDeviceStyle.defaultBezelColor,
          '#000000',
        )
        ..color(
          'outline colour',
          CoreMockupDeviceStyle.defaultBezelBorderColor,
          '#27282b',
        )
        ..close(
          'outline width (outside)',
          CoreMockupDeviceStyle.defaultBezelBorderWidth,
          0.5,
        )
        ..color(
          'inner shadow colour',
          CoreMockupDeviceStyle.defaultBezelInnerShadowColor,
          '#ffffff29',
        )
        ..close(
          'inner shadow blur',
          CoreMockupDeviceStyle.defaultBezelInnerShadowBlur,
          0.5,
        )
        ..close(
          'inner shadow spread',
          CoreMockupDeviceStyle.defaultBezelInnerShadowSpread,
          0.3,
        );
    });

    _check('screen fill', (c) {
      c.tokenColor(
        'fill (color/surface)',
        CoreMockupDeviceStyle.defaultBackgroundColor,
        CoreColors.surface,
      );
    });

    _check('side buttons: fills and size', (c) {
      c
        ..close('thickness', CoreMockupDeviceStyle.defaultButtonThickness, 2)
        ..close(
          'protrusion',
          CoreMockupDeviceStyle.defaultButtonProtrusion,
          1.5,
        )
        // Layer 1: solid base.
        ..color(
          'solid base',
          CoreMockupDeviceStyle.defaultButtonColor,
          '#aeafb2',
        )
        // Layer 2: gloss along the length (hex, not bound to a variable).
        ..gradient(
          'length gloss',
          CoreMockupDeviceStyle.defaultButtonLengthGradient,
          type: CoreGradientType.linear,
          stops: [0, 0.05, 0.09, 0.15, 0.85, 0.91, 0.95, 1],
          colors: [
            '#ffffff00',
            '#ffffffad',
            '#00000080',
            '#ffffff00',
            '#ffffff00',
            '#00000080',
            '#ffffff7a',
            '#ffffff00',
          ],
        )
        // Layer 3: depth (hex), dark end #00000059 at the body side, far end
        // clear.
        ..color(
          'depth dark end',
          CoreMockupDeviceStyle.defaultButtonDepthColor,
          '#00000059',
        );
    });

    for (final edge in CoreMockupDeviceEdge.values) {
      _check('side button on the ${edge.name} edge: gradient directions', (c) {
        // The gloss runs along the button's length: vertical on a left/right
        // edge, horizontal on a top/bottom edge.
        final gloss = CoreMockupDeviceLayout.buttonLengthGradient(
          CoreMockupDeviceStyle.defaultButtonLengthGradient,
          edge,
        );
        c.gradient(
          'length gloss',
          gloss,
          type: CoreGradientType.linear,
          stops: [0, 0.05, 0.09, 0.15, 0.85, 0.91, 0.95, 1],
          colors: [
            '#ffffff00',
            '#ffffffad',
            '#00000080',
            '#ffffff00',
            '#ffffff00',
            '#00000080',
            '#ffffff7a',
            '#ffffff00',
          ],
        );
        if (edge.isVertical) {
          c
            ..close(
              'gloss runs along x (must not)',
              (gloss.end.x - gloss.begin.x).abs(),
              0,
              tol: 1e-9,
            )
            ..same(
              'gloss runs along y',
              (gloss.end.y - gloss.begin.y).abs() > 0,
              true,
            );
        } else {
          c
            ..close(
              'gloss runs along y (must not)',
              (gloss.end.y - gloss.begin.y).abs(),
              0,
              tol: 1e-9,
            )
            ..same(
              'gloss runs along x',
              (gloss.end.x - gloss.begin.x).abs() > 0,
              true,
            );
        }

        // The depth runs across the thickness and is darkest where the
        // button touches the body.
        final depth = CoreMockupDeviceLayout.buttonDepthGradient(
          CoreMockupDeviceStyle.defaultButtonDepthColor,
          edge,
        );
        c.same('depth type', depth.type, CoreGradientType.linear);
        if (depth.colors.length != 2) {
          c.fail('depth colours', 'expected 2, got ${depth.colors.length}');
          return;
        }
        final stops = depth.stops ?? const [0.0, 1.0];
        final darkIndex = depth.colors.indexWhere(
          (x) => x.argb == _hex('#00000059'),
        );
        final clearIndex = depth.colors.indexWhere(
          (x) => x.argb == _hex('#00000000'),
        );
        if (darkIndex < 0 || clearIndex < 0) {
          c.fail(
            'depth colours',
            'expected #00000059 and #00000000, got '
                '${depth.colors.map((x) => _argb(x.argb)).toList()}',
          );
          return;
        }
        ({double x, double y}) at(int index) {
          final t = stops[index];
          return (
            x: depth.begin.x + t * (depth.end.x - depth.begin.x),
            y: depth.begin.y + t * (depth.end.y - depth.begin.y),
          );
        }

        final dark = at(darkIndex);
        final clear = at(clearIndex);
        if (edge.isVertical) {
          c.close(
            'depth runs along y (must not)',
            (dark.y - clear.y).abs(),
            0,
            tol: 1e-9,
          );
        } else {
          c.close(
            'depth runs along x (must not)',
            (dark.x - clear.x).abs(),
            0,
            tol: 1e-9,
          );
        }
        // The body lies to the right of a left button, to the left of a
        // right button, below a top button and above a bottom button.
        final towardBody = switch (edge) {
          CoreMockupDeviceEdge.left => dark.x > clear.x,
          CoreMockupDeviceEdge.right => dark.x < clear.x,
          CoreMockupDeviceEdge.top => dark.y > clear.y,
          CoreMockupDeviceEdge.bottom => dark.y < clear.y,
        };
        c.same('dark end lies on the body side', towardBody, true);
      });
    }

    _check('antenna band paint', (c) {
      c
        ..gradient(
          'gradient',
          CoreMockupDeviceStyle.defaultAntennaGradient,
          type: CoreGradientType.linear,
          stops: [0, 1],
          // The 70 % belongs to the paint, not to the stops.
          colors: ['#fcfcfd', '#e4e5e7'],
          begin: CoreAlignment.topCenter,
          end: CoreAlignment.bottomCenter,
        )
        ..close('opacity', CoreMockupDeviceStyle.defaultAntennaOpacity, 0.7)
        // A band is as thick as the rail (3) and 1.9 long.
        ..close(
          'rail width (band thickness)',
          CoreMockupDeviceStyle.defaultRailWidth,
          3,
        )
        ..close(
          'phone band length',
          _row(CoreMockupDevice.phone).antennaBandLength!,
          1.9,
        );
    });

    _check('camera set paint', (c) {
      c
        ..color(
          'camera / lens fill',
          CoreMockupDeviceStyle.defaultLensColor,
          '#000000',
        )
        ..color(
          'phone camera pill fill',
          CoreMockupDeviceStyle.defaultCutoutColor,
          '#000000',
        )
        ..color(
          'lens highlight',
          CoreMockupDeviceStyle.defaultLensHighlightColor,
          '#ffffff',
        )
        // Identity gradient transform: a radial from the centre of the core.
        ..gradient(
          'core gradient',
          CoreMockupDeviceStyle.defaultCoreGradient,
          type: CoreGradientType.radial,
          stops: [0.2, 0.35, 0.5, 0.62, 0.8, 1],
          colors: [
            '#000000',
            '#0a3348',
            '#0c3b52',
            '#105171',
            '#0c3b52',
            '#000000',
          ],
          begin: CoreAlignment.center,
        );
      final painted = CoreMockupDeviceStyle.resolveCoreGradient();
      if (painted == null) {
        c.fail('painted core fill', 'expected the gradient, got the solid');
      } else {
        c.same(
          'painted core fill',
          painted,
          CoreMockupDeviceStyle.defaultCoreGradient,
        );
      }
    });

    _check('side button position fractions', (c) {
      final phone = _row(CoreMockupDevice.phone);
      final tablet = _row(CoreMockupDevice.tablet);
      c
        ..close('phone power', phone.powerButtonOffset!, 0.30, tol: 1e-5)
        ..close('phone volume', phone.volumeButtonOffset!, 0.20, tol: 1e-5)
        ..close(
          'phone landscape power',
          phone.landscapePowerButtonOffset!,
          0.30,
          tol: 1e-5,
        )
        ..close(
          'phone landscape volume',
          phone.landscapeVolumeButtonOffset!,
          0.20,
          tol: 1e-5,
        )
        ..close(
          'phone volume spacing',
          phone.volumeButtonSpacing!,
          8,
          tol: 1e-9,
        )
        ..close(
          'tablet portrait power',
          tablet.powerButtonOffset!,
          0.11673,
          tol: 1e-5,
        )
        ..close(
          'tablet portrait volume',
          tablet.volumeButtonOffset!,
          0.18383,
          tol: 1e-5,
        )
        ..close(
          'tablet landscape power',
          tablet.landscapePowerButtonOffset!,
          0.15498,
          tol: 1e-5,
        )
        ..close(
          'tablet landscape volume',
          tablet.landscapeVolumeButtonOffset!,
          0.62053,
          tol: 1e-5,
        );
    });

    _check('status bar colours', (c) {
      c
        ..tokenColor(
          'glyphs and battery level (color/on-surface)',
          CoreMockupDeviceStyle.defaultStatusBarIconColor,
          CoreColors.onSurface,
        )
        ..tokenColor(
          'battery outline (on-surface, 35 %)',
          CoreMockupDeviceStyle.defaultStatusBarBatteryBorderColor,
          CoreColors.onSurface,
          opacity: 0.35,
        )
        ..tokenColor(
          'battery nub (on-surface, 40 %)',
          CoreMockupDeviceStyle.defaultStatusBarBatteryCapColor,
          CoreColors.onSurface,
          opacity: 0.4,
        );
    });

    _check('home indicator colour', (c) {
      // Opaque on-surface (the earlier 20 % is gone).
      c.tokenColor(
        'bar fill',
        CoreMockupDeviceStyle.defaultGestureBarColor,
        CoreColors.onSurface,
      );
    });

    _check('sample content', (c) {
      c
        ..same('time', CoreMockupDeviceStyle.sampleTime, '9:41')
        ..same('meridiem', CoreMockupDeviceStyle.sampleMeridiem, '오전')
        ..same('date', CoreMockupDeviceStyle.sampleDate, '4월 1일 수요일')
        ..same(
          'battery level',
          CoreMockupDeviceStyle.sampleBatteryLevel,
          '100%',
        );
    });

    _check('contract flags default to shown', (c) {
      c
        ..same('Show camera', CoreMockupDeviceContract.defaultShowCamera, true)
        ..same(
          'Show gesture bar',
          CoreMockupDeviceContract.defaultShowGestureBar,
          true,
        )
        ..same(
          'Show status bar',
          CoreMockupDeviceContract.defaultShowStatusBar,
          true,
        );
    });
  });

  // ─── Hardware colours: literals, printed values, invariance ───────────

  group('hardware colours', () {
    _check('every hardware layer is a literal', (c) {
      for (final layer in _hardwareLayers()) {
        final token = layer.color.token;
        if (token != null) {
          c.fail(layer.name, 'expected a literal, got token ${token.name}');
        }
        c.close('${layer.name} / opacity', layer.color.opacity, 1, tol: 1e-9);
      }
    });

    _check('every hardware layer is the value the canvas prints', (c) {
      for (final layer in _hardwareLayers()) {
        c.same(layer.name, _argb(layer.color.argb), _argb(_hex(layer.hex)));
      }
    });

    for (final source in _kSources.entries) {
      _check(
        'every hardware layer is the printed value in all four modes '
        '(${source.key})',
        (c) {
          for (final mode in _kModes) {
            final scheme = _scheme(
              source.value,
              brightness: mode.brightness,
              highContrast: mode.highContrast,
            );
            for (final layer in _hardwareLayers()) {
              c.same(
                '${layer.name} / ${mode.name}',
                _argb(scheme.resolve(layer.color).argb),
                _argb(_hex(layer.hex)),
              );
            }
          }
        },
      );
    }

    _check('the screen fill moves with the mode (the check can fail)', (c) {
      // The screen is the only part of the device that follows the mode: if
      // `surface` stopped differing between modes, the invariance checks above
      // would be comparing nothing.
      final values = {
        for (final mode in _kModes)
          _argb(
            _scheme(
              CouiColorPresets.source,
              brightness: mode.brightness,
              highContrast: mode.highContrast,
            ).resolve(CoreMockupDeviceStyle.defaultBackgroundColor).argb,
          ),
      };
      c.same(
        'distinct screen fills across four modes > 1',
        values.length > 1,
        true,
      );
    });

    _check('a fixed slot moves with the palette (the check can fail)', (c) {
      // A fixed slot holds one value across the modes but is the palette's
      // colour, so a chromatic brand moves it — which is why the hardware
      // states literals. If it stopped differing, the per-source checks
      // above would be comparing nothing.
      for (final slot in [
        CoreColors.primaryFixedDim,
        CoreColors.onPrimaryFixed,
        CoreColors.onPrimaryFixedVariant,
        CoreColors.secondaryFixed,
      ]) {
        final values = {
          for (final source in _kSources.values)
            _argb(
              _scheme(
                source,
                brightness: CoreBrightness.light,
                highContrast: false,
              ).resolve(CoreColor.token(slot)).argb,
            ),
        };
        c.same('${slot.name} differs between sources', values.length > 1, true);
      }
    });
  });
}
