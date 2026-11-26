// Tests for CoreMockupDeviceStyle / CoreMockupDeviceLayout.

import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import 'support/brand_fixture.dart';

const _kColorPrimary = CoreColor.token(CoreColors.primary);
const _kColorOutline = CoreColor.token(CoreColors.outline);
const _kColorSurface = CoreColor.token(CoreColors.surface);

/// The Figma canvas's own device widths — the canvas widths the device
/// geometry was measured at, not the design-system default.
const _kPhonePreviewWidth = 160.0;
const _kPhoneLandscapePreviewWidth = 328.0;
const _kTabletPreviewWidth = 321.0;
const _kTabletLandscapePreviewWidth = 455.0;

/// The canvas states every length to three decimals, so compare each edge
/// with a tolerance instead of the record as a whole.
void _expectRect(
  CoreMockupDeviceRect actual, {
  required double left,
  required double top,
  required double width,
  required double height,
}) {
  expect(actual.left, closeTo(left, 1e-3));
  expect(actual.top, closeTo(top, 1e-3));
  expect(actual.width, closeTo(width, 1e-3));
  expect(actual.height, closeTo(height, 1e-3));
}

/// The four canvas members: a device in a pose, at the body width the canvas
/// draws it at.
const _kMembers =
    <
      ({
        CoreMockupDevice device,
        CoreMockupOrientation orientation,
        double width,
      })
    >[
      (
        device: CoreMockupDevice.phone,
        orientation: CoreMockupOrientation.portrait,
        width: _kPhonePreviewWidth,
      ),
      (
        device: CoreMockupDevice.phone,
        orientation: CoreMockupOrientation.landscape,
        width: _kPhoneLandscapePreviewWidth,
      ),
      (
        device: CoreMockupDevice.tablet,
        orientation: CoreMockupOrientation.portrait,
        width: _kTabletPreviewWidth,
      ),
      (
        device: CoreMockupDevice.tablet,
        orientation: CoreMockupOrientation.landscape,
        width: _kTabletLandscapePreviewWidth,
      ),
    ];

void _expectInsets(
  CoreMockupDeviceSafeArea actual, {
  required double top,
  required double bottom,
  required double left,
  double right = 0,
}) {
  expect(actual.top, closeTo(top, 1e-3), reason: 'top');
  expect(actual.bottom, closeTo(bottom, 1e-3), reason: 'bottom');
  expect(actual.left, closeTo(left, 1e-3), reason: 'left');
  expect(actual.right, closeTo(right, 1e-3), reason: 'right');
}

/// The tight bounds of a glyph path — the end points and the extrema of every
/// cubic — so the box a glyph states can be held to the drawing it states.
({double minX, double minY, double maxX, double maxY}) _pathBounds(
  String path,
) {
  final tokens = RegExp(r'[MLCZ]|-?\d+(?:\.\d+)?').allMatches(path).toList();
  final xs = <double>[];
  final ys = <double>[];
  var i = 0;
  double x = 0;
  double y = 0;
  double startX = 0;
  double startY = 0;
  double number() => double.parse(tokens[i++].group(0)!);
  void add(double px, double py) {
    xs.add(px);
    ys.add(py);
  }

  // The extrema of one cubic's coordinate: roots of its derivative.
  Iterable<double> extrema(double p0, double p1, double p2, double p3) sync* {
    final a = -p0 + 3 * p1 - 3 * p2 + p3;
    final b = 2 * (p0 - 2 * p1 + p2);
    final c = p1 - p0;
    if (a.abs() < 1e-12) {
      if (b.abs() > 1e-12) yield -c / b;
      return;
    }
    final disc = b * b - 4 * a * c;
    if (disc < 0) return;
    final root = math.sqrt(disc);
    yield (-b + root) / (2 * a);
    yield (-b - root) / (2 * a);
  }

  double at(double t, double p0, double p1, double p2, double p3) {
    final m = 1 - t;
    return m * m * m * p0 +
        3 * m * m * t * p1 +
        3 * m * t * t * p2 +
        t * t * t * p3;
  }

  while (i < tokens.length) {
    final command = tokens[i++].group(0)!;
    switch (command) {
      case 'M':
        x = number();
        y = number();
        startX = x;
        startY = y;
        add(x, y);
      case 'L':
        x = number();
        y = number();
        add(x, y);
      case 'C':
        final x1 = number();
        final y1 = number();
        final x2 = number();
        final y2 = number();
        final x3 = number();
        final y3 = number();
        for (final t in [
          ...extrema(x, x1, x2, x3),
          ...extrema(y, y1, y2, y3),
        ].where((t) => t > 0 && t < 1)) {
          add(at(t, x, x1, x2, x3), at(t, y, y1, y2, y3));
        }
        x = x3;
        y = y3;
        add(x, y);
      case 'Z':
        x = startX;
        y = startY;
    }
  }
  return (
    minX: xs.reduce(math.min),
    minY: ys.reduce(math.min),
    maxX: xs.reduce(math.max),
    maxY: ys.reduce(math.max),
  );
}

/// Where a platform's row puts the items of a group whose every item has a
/// width of its own: the arithmetic of a `Row`, a flexbox and an auto-layout
/// frame, written out once. Every item is centred on the group box's middle.
List<CoreMockupDeviceRect> _rowRects(CoreMockupStatusBarGroup group) {
  double widthOf(CoreMockupStatusBarItem item) => switch (item) {
    CoreMockupStatusBarGlyph() => item.width,
    CoreMockupStatusBarBattery() => item.width,
    CoreMockupStatusBarText() => throw StateError('text has no width here'),
  };
  double heightOf(CoreMockupStatusBarItem item) => switch (item) {
    CoreMockupStatusBarGlyph() => item.height,
    CoreMockupStatusBarBattery() => item.height,
    CoreMockupStatusBarText() => throw StateError('text has no height here'),
  };
  final items = group.items;
  final total =
      items.fold<double>(0, (sum, item) => sum + widthOf(item)) +
      items
          .take(items.length - 1)
          .fold<double>(0, (sum, item) => sum + item.gapAfter);
  var left = switch (group.alignment) {
    CoreMainAxisAlignment.start => group.box.left,
    CoreMainAxisAlignment.end => group.box.left + group.box.width - total,
    CoreMainAxisAlignment.center =>
      group.box.left + (group.box.width - total) / 2,
    _ => throw StateError('a status bar group is start, center or end'),
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

/// Settles every style value the way a platform resolver does — merge
/// chain output plus the per-device table plus the flat defaults — and
/// hands the result to the shared layout rule set.
CoreMockupDeviceLayout _layout(
  CoreMockupDevice device, {
  required double width,
  CoreMockupOrientation orientation = CoreMockupOrientation.portrait,
  CoreMockupDeviceStyle override = const CoreMockupDeviceStyle(),
}) {
  final d = CoreMockupDeviceStyle.defaultsByDevice[device]!;
  final s = override;
  return CoreMockupDeviceLayout.compute(
    device: device,
    orientation: orientation,
    width: width,
    railWidth: s.railWidth ?? CoreMockupDeviceStyle.defaultRailWidth,
    bezelWidth: s.bezelWidth ?? d.bezelWidth!,
    borderRadius: s.borderRadius ?? d.borderRadius!,
    screenAspectWidth: s.screenAspectWidth ?? d.screenAspectWidth!,
    screenAspectHeight: s.screenAspectHeight ?? d.screenAspectHeight!,
    cameraPlacement: s.cameraPlacement ?? d.cameraPlacement!,
    cameraWidth: s.cameraWidth ?? d.cameraWidth!,
    cameraHeight: s.cameraHeight ?? d.cameraHeight!,
    cameraOffset: s.cameraOffset ?? d.cameraOffset!,
    lensSize: s.lensSize ?? d.lensSize!,
    lensOffset: s.lensOffset ?? d.lensOffset!,
    cameraCoreSize: s.cameraCoreSize ?? d.cameraCoreSize!,
    lensHighlightSizeRatio:
        s.lensHighlightSizeRatio ??
        CoreMockupDeviceStyle.defaultLensHighlightSizeRatio,
    lensHighlightOffsetXRatio:
        s.lensHighlightOffsetXRatio ??
        CoreMockupDeviceStyle.defaultLensHighlightOffsetXRatio,
    lensHighlightOffsetYRatio:
        s.lensHighlightOffsetYRatio ??
        CoreMockupDeviceStyle.defaultLensHighlightOffsetYRatio,
    buttonThickness:
        s.buttonThickness ?? CoreMockupDeviceStyle.defaultButtonThickness,
    buttonProtrusion:
        s.buttonProtrusion ?? CoreMockupDeviceStyle.defaultButtonProtrusion,
    powerButtonLength: s.powerButtonLength ?? d.powerButtonLength!,
    powerButtonOffset: s.powerButtonOffset ?? d.powerButtonOffset!,
    volumeButtonLength: s.volumeButtonLength ?? d.volumeButtonLength!,
    volumeButtonOffset: s.volumeButtonOffset ?? d.volumeButtonOffset!,
    volumeButtonSpacing: s.volumeButtonSpacing ?? d.volumeButtonSpacing!,
    landscapePowerButtonLength:
        s.landscapePowerButtonLength ?? d.landscapePowerButtonLength!,
    landscapePowerButtonOffset:
        s.landscapePowerButtonOffset ?? d.landscapePowerButtonOffset!,
    landscapeVolumeButtonLength:
        s.landscapeVolumeButtonLength ?? d.landscapeVolumeButtonLength!,
    landscapeVolumeButtonOffset:
        s.landscapeVolumeButtonOffset ?? d.landscapeVolumeButtonOffset!,
    antennaBandLength: s.antennaBandLength ?? d.antennaBandLength!,
    antennaSideNearOffset:
        s.antennaSideNearOffset ??
        CoreMockupDeviceStyle.defaultAntennaSideNearOffset,
    antennaSideFarOffset:
        s.antennaSideFarOffset ??
        CoreMockupDeviceStyle.defaultAntennaSideFarOffset,
    antennaTopOffset:
        s.antennaTopOffset ?? CoreMockupDeviceStyle.defaultAntennaTopOffset,
    antennaBottomOffset:
        s.antennaBottomOffset ??
        CoreMockupDeviceStyle.defaultAntennaBottomOffset,
    rimHighlightInset:
        s.rimHighlightInset ?? CoreMockupDeviceStyle.defaultRimHighlightInset,
    rimGlowTopInset:
        s.rimGlowTopInset ?? CoreMockupDeviceStyle.defaultRimGlowTopInset,
    rimGlowBottomInset:
        s.rimGlowBottomInset ?? CoreMockupDeviceStyle.defaultRimGlowBottomInset,
    systemBarReferenceWidth:
        s.systemBarReferenceWidth ?? d.systemBarReferenceWidth!,
    systemBarReferenceScale:
        s.systemBarReferenceScale ?? d.systemBarReferenceScale!,
    landscapeSystemBarReferenceWidth:
        s.landscapeSystemBarReferenceWidth ??
        d.landscapeSystemBarReferenceWidth!,
    landscapeSystemBarReferenceScale:
        s.landscapeSystemBarReferenceScale ??
        d.landscapeSystemBarReferenceScale!,
    statusBarHeight: s.statusBarHeight ?? d.statusBarHeight!,
    landscapeStatusBarHeight:
        s.landscapeStatusBarHeight ?? d.landscapeStatusBarHeight!,
    statusBarInset: s.statusBarInset ?? d.statusBarInset!,
    statusBarContentCenter:
        s.statusBarContentCenter ?? d.statusBarContentCenter!,
    statusBarWingWidth: s.statusBarWingWidth ?? d.statusBarWingWidth!,
    statusBarTrailingInset:
        s.statusBarTrailingInset ?? d.statusBarTrailingInset!,
    statusBarTrailingSpacing:
        s.statusBarTrailingSpacing ?? d.statusBarTrailingSpacing!,
    statusBarClockSpacing:
        s.statusBarClockSpacing ??
        CoreMockupDeviceStyle.defaultStatusBarClockSpacing,
    statusBarLeadingSpacing:
        s.statusBarLeadingSpacing ??
        CoreMockupDeviceStyle.defaultStatusBarLeadingSpacing,
    // The deprecated pin has no default: it is only ever stated.
    gestureBarWidthRatio: s.pinnedGestureBarWidthRatio,
    gestureBarWidth: s.gestureBarWidth ?? d.gestureBarWidth!,
    landscapeGestureBarWidth:
        s.landscapeGestureBarWidth ?? d.landscapeGestureBarWidth!,
    gestureBarHeight:
        s.gestureBarHeight ?? CoreMockupDeviceStyle.defaultGestureBarHeight,
    gestureBarOffset:
        s.gestureBarOffset ?? CoreMockupDeviceStyle.defaultGestureBarOffset,
    gestureBarRadius:
        s.gestureBarRadius ?? CoreMockupDeviceStyle.defaultGestureBarRadius,
    gestureBarAreaHeight: s.gestureBarAreaHeight ?? d.gestureBarAreaHeight!,
    landscapeGestureBarAreaHeight:
        s.landscapeGestureBarAreaHeight ?? d.landscapeGestureBarAreaHeight!,
  );
}

void main() {
  group('CoreMockupDeviceLayout safe area', () {
    for (final m in _kMembers) {
      test('${m.device} ${m.orientation}: each Show flag releases its own', () {
        final l = _layout(m.device, width: m.width, orientation: m.orientation);
        CoreMockupDeviceSafeArea at({
          required bool camera,
          required bool status,
          required bool gesture,
        }) => l.safeAreaInsets(
          showCamera: camera,
          showStatusBar: status,
          showGestureBar: gesture,
        );
        final all = at(camera: true, status: true, gesture: true);
        final cameraOnly = at(camera: true, status: false, gesture: false);
        final statusOnly = at(camera: false, status: true, gesture: false);
        final gestureOnly = at(camera: false, status: false, gesture: true);
        final none = at(camera: false, status: false, gesture: false);

        expect(none, (top: 0.0, bottom: 0.0, left: 0.0, right: 0.0));
        // The bottom belongs to the gesture bar alone.
        expect(cameraOnly.bottom, 0);
        expect(statusOnly.bottom, 0);
        expect(gestureOnly.bottom, greaterThan(0));
        expect(all.bottom, gestureOnly.bottom);
        // The left belongs to the camera alone.
        expect(statusOnly.left, 0);
        expect(gestureOnly.left, 0);
        expect(all.left, cameraOnly.left);
        // The top is whichever of the camera and the status bar reaches
        // deeper — neither is derived from the other's flag.
        expect(gestureOnly.top, 0);
        expect(all.top, math.max(cameraOnly.top, statusOnly.top));
        // Nothing is fixed to the right edge.
        expect(all.right, 0);
      });
    }

    test('phone portrait: the status bar, then the camera, then the bar', () {
      final l = _layout(.phone, width: _kPhonePreviewWidth);
      // Status bar 59 points × 144/402 = 21.134; the pill reaches 4 + 13 and
      // mirrors the 4 — 21. Together the deeper one holds; alone each does.
      _expectInsets(
        l.safeAreaInsets(
          showCamera: true,
          showStatusBar: true,
          showGestureBar: true,
        ),
        top: 21.134,
        bottom: 12.179,
        left: 0,
      );
      _expectInsets(
        l.safeAreaInsets(
          showCamera: true,
          showStatusBar: false,
          showGestureBar: false,
        ),
        top: 21,
        bottom: 0,
        left: 0,
      );
      _expectInsets(
        l.safeAreaInsets(
          showCamera: false,
          showStatusBar: true,
          showGestureBar: false,
        ),
        top: 21.134,
        bottom: 0,
        left: 0,
      );
    });

    test('phone landscape: no status bar, the camera stands on the left', () {
      final l = _layout(
        .phone,
        width: _kPhoneLandscapePreviewWidth,
        orientation: .landscape,
      );
      // The status bar is not drawn turned, so its flag changes nothing; the
      // pill is 4 + 13 + the 4 mirrored in from the left edge.
      for (final status in [true, false]) {
        _expectInsets(
          l.safeAreaInsets(
            showCamera: true,
            showStatusBar: status,
            showGestureBar: true,
          ),
          top: 0,
          bottom: 7.497,
          left: 21,
        );
      }
      _expectInsets(
        l.safeAreaInsets(
          showCamera: false,
          showStatusBar: true,
          showGestureBar: true,
        ),
        top: 0,
        bottom: 7.497,
        left: 0,
      );
    });

    for (final m in [_kMembers[2], _kMembers[3]]) {
      test(
        'tablet ${m.orientation}: the bar reserves the top, not the camera',
        () {
          final l = _layout(
            .tablet,
            width: m.width,
            orientation: m.orientation,
          );
          // The camera is in the bezel strip and reserves nothing; the bar is
          // 32 points tall, the bottom area 20.
          _expectInsets(
            l.safeAreaInsets(
              showCamera: true,
              showStatusBar: true,
              showGestureBar: true,
            ),
            top: 11.463,
            bottom: 7.164,
            left: 0,
          );
          _expectInsets(
            l.safeAreaInsets(
              showCamera: true,
              showStatusBar: false,
              showGestureBar: true,
            ),
            top: 0,
            bottom: 7.164,
            left: 0,
          );
        },
      );
    }

    test('oversized lens and bar overrides determine clearance', () {
      final layout = _layout(
        .phone,
        width: _kPhonePreviewWidth,
        override: const CoreMockupDeviceStyle(
          cameraOffset: 12,
          cameraHeight: 20,
          lensSize: 60,
          // 65 points from the bottom edge — past the 34-point area.
          gestureBarHeight: 5,
          gestureBarOffset: 60,
        ),
      );
      // The lens reaches deeper than the status bar, so it decides the top;
      // the bar's own footprint is deeper than its area, so it decides the
      // bottom.
      _expectInsets(
        layout.safeAreaInsets(
          showCamera: true,
          showStatusBar: true,
          showGestureBar: true,
        ),
        top: 64,
        bottom: 23.284,
        left: 0,
      );
      // Hide the camera and the status bar's own height is what is left.
      _expectInsets(
        layout.safeAreaInsets(
          showCamera: false,
          showStatusBar: true,
          showGestureBar: false,
        ),
        top: 21.134,
        bottom: 0,
        left: 0,
      );
    });

    test('tiny and zero-size screens never produce negative content space', () {
      for (final width in [0.0, 16.0, 20.0]) {
        for (final m in _kMembers) {
          final layout = _layout(
            m.device,
            width: width,
            orientation: m.orientation,
          );
          for (final camera in [false, true]) {
            for (final status in [false, true]) {
              for (final bar in [false, true]) {
                final insets = layout.safeAreaInsets(
                  showCamera: camera,
                  showStatusBar: status,
                  showGestureBar: bar,
                );
                expect(insets.top, greaterThanOrEqualTo(0));
                expect(insets.bottom, greaterThanOrEqualTo(0));
                expect(insets.left, greaterThanOrEqualTo(0));
                expect(
                  insets.top + insets.bottom,
                  lessThanOrEqualTo(layout.screenHeight),
                );
                expect(insets.left, lessThanOrEqualTo(layout.screenWidth));
              }
            }
          }
        }
      }
    });
  });

  group('CoreMockupDeviceStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreMockupDeviceStyle(
        backgroundColor: _kColorSurface,
        railColor: CoreMockupDeviceStyle.defaultRailColor,
        borderColor: _kColorOutline,
        borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
      );
      const themeStyle = CoreMockupDeviceStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
      );
      const widgetStyle = CoreMockupDeviceStyle(railColor: _kColorPrimary);

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.backgroundColor, _kColorSurface);
      expect(effective.railColor, _kColorPrimary);
      expect(effective.borderColor, _kColorOutline);
      expect(
        effective.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius36),
      );
    });

    test('equality + copyWith', () {
      const a = CoreMockupDeviceStyle(
        railColor: _kColorSurface,
        borderColor: _kColorOutline,
      );
      const b = CoreMockupDeviceStyle(
        railColor: _kColorSurface,
        borderColor: _kColorOutline,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final copy = a.copyWith(
        borderRadius: const CoreBorderRadius.all(CoreRadius.radius48),
      );
      expect(
        copy.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius48),
      );
      expect(copy.railColor, _kColorSurface);
      expect(copy.borderColor, _kColorOutline);
      expect(copy, isNot(equals(a)));
    });

    test('geometry override fields merge + copyWith', () {
      const base = CoreMockupDeviceStyle(
        railWidth: 4,
        bezelWidth: 10,
        cameraWidth: 20,
        cameraHeight: 8,
        lensSize: 5,
        powerButtonLength: 50,
        volumeButtonSpacing: 6,
        landscapePowerButtonOffset: 0.1,
        gestureBarWidth: 100,
        statusBarInset: 10,
        screenAspectWidth: 3,
        screenAspectHeight: 4,
      );
      const overrideStyle = CoreMockupDeviceStyle(
        bezelWidth: 12,
        screenAspectWidth: 9,
        screenAspectHeight: 19.5,
        landscapeVolumeButtonOffset: 0.4,
      );

      final merged = base.merge(overrideStyle);
      expect(merged.bezelWidth, 12);
      expect(merged.screenAspectWidth, 9);
      expect(merged.screenAspectHeight, 19.5);
      expect(merged.railWidth, 4);
      expect(merged.cameraWidth, 20);
      expect(merged.lensSize, 5);
      expect(merged.powerButtonLength, 50);
      expect(merged.volumeButtonSpacing, 6);
      expect(merged.gestureBarWidth, 100);
      expect(merged.statusBarInset, 10);
      expect(merged.landscapePowerButtonOffset, 0.1);
      expect(merged.landscapeVolumeButtonOffset, 0.4);

      final copy = base.copyWith(
        cameraHeight: 12,
        landscapeVolumeButtonOffset: 0.5,
      );
      expect(copy.cameraHeight, 12);
      expect(copy.cameraWidth, 20);
      expect(copy.landscapePowerButtonOffset, 0.1);
      expect(copy.landscapeVolumeButtonOffset, 0.5);
      expect(
        base.copyWith(landscapePowerButtonOffset: 0.2),
        isNot(equals(base)),
      );
    });

    test('nested containerStyle merges recursively', () {
      const base = CoreMockupDeviceStyle(
        containerStyle: CoreOutlinedContainerStyle(boxShadow: CoreShadow.lg),
      );
      const overlay = CoreMockupDeviceStyle(
        containerStyle: CoreOutlinedContainerStyle(
          clipBehavior: CoreClipBehavior.none,
        ),
      );
      final merged = base.merge(overlay);
      // The overlay's clip lands, the base's shadow survives — a plain `??`
      // would have dropped it.
      expect(merged.containerStyle?.boxShadow, CoreShadow.lg);
      expect(merged.containerStyle?.clipBehavior, CoreClipBehavior.none);
    });

    test('defaultsByDevice — every device, per-device values', () {
      expect(
        CoreMockupDeviceStyle.defaultsByDevice.keys,
        containsAll(CoreMockupDevice.values),
      );
      final phone =
          CoreMockupDeviceStyle.defaultsByDevice[CoreMockupDevice.phone]!;
      final tablet =
          CoreMockupDeviceStyle.defaultsByDevice[CoreMockupDevice.tablet]!;
      expect(
        phone.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius24),
      );
      expect(
        tablet.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius16),
      );
      expect(phone.bezelWidth, 5);
      expect(tablet.bezelWidth, 8);
      expect(phone.screenAspectWidth! / phone.screenAspectHeight!, 9 / 19.5);
      // The canvas's screen box, as the proportion it states.
      expect(tablet.screenAspectWidth, 299);
      expect(tablet.screenAspectHeight, 433);
      expect(phone.cameraPlacement, CoreMockupCameraPlacement.screen);
      expect(tablet.cameraPlacement, CoreMockupCameraPlacement.bezel);
      expect(phone.cameraCoreSize, 3.9);
      expect(tablet.cameraCoreSize, 2.4);
      expect(phone.antennaBandLength, 1.9);
      expect(tablet.antennaBandLength, 0);
      // A tablet's buttons are measured per orientation; a phone's stay.
      expect(tablet.powerButtonLength, 45.433);
      expect(tablet.landscapePowerButtonLength, 49.522);
      expect(tablet.volumeButtonLength, 33.317);
      expect(tablet.landscapeVolumeButtonLength, 36.316);
      expect(phone.landscapePowerButtonLength, phone.powerButtonLength);
      expect(phone.landscapeVolumeButtonLength, phone.volumeButtonLength);
      expect(phone.landscapePowerButtonOffset, phone.powerButtonOffset);
      expect(phone.landscapeVolumeButtonOffset, phone.volumeButtonOffset);
      expect(CoreMockupDevice.defaultDevice, CoreMockupDevice.phone);
    });

    test('system bar values — one per device, in iOS points', () {
      final phone =
          CoreMockupDeviceStyle.defaultsByDevice[CoreMockupDevice.phone]!;
      final tablet =
          CoreMockupDeviceStyle.defaultsByDevice[CoreMockupDevice.tablet]!;
      // An iPhone 16 Pro is 402 wide upright and 874 on its side.
      expect(phone.systemBarReferenceWidth, 402);
      expect(phone.landscapeSystemBarReferenceWidth, 874);
      // The tablet's are the widths its 299 / 433 screens stand for at the
      // phone's factor, 144 / 402.
      expect(tablet.systemBarReferenceWidth, closeTo(299 * 402 / 144, 1e-9));
      expect(
        tablet.landscapeSystemBarReferenceWidth,
        closeTo(433 * 402 / 144, 1e-9),
      );
      expect(phone.statusBarHeight, 59);
      expect(phone.landscapeStatusBarHeight, 0);
      expect(tablet.statusBarHeight, 32);
      expect(tablet.landscapeStatusBarHeight, 32);
      expect(phone.statusBarInset, 24);
      expect(tablet.statusBarInset, 16);
      expect(phone.statusBarContentCenter, 32.5);
      expect(tablet.statusBarContentCenter, 16);
      expect(phone.statusBarWingWidth, 101);
      expect(phone.statusBarTrailingInset, 2);
      expect(phone.statusBarTrailingSpacing, 6);
      expect(tablet.statusBarWingWidth, 0);
      expect(tablet.statusBarTrailingSpacing, 4);
      expect(phone.gestureBarAreaHeight, 34);
      expect(phone.landscapeGestureBarAreaHeight, 21);
      expect(tablet.gestureBarAreaHeight, 20);
      expect(tablet.landscapeGestureBarAreaHeight, 20);
      expect(phone.gestureBarWidth, 144);
      expect(phone.landscapeGestureBarWidth, 209);
      expect(tablet.gestureBarWidth, 314);
      expect(tablet.landscapeGestureBarWidth, 314);
      // Flat: the same on both devices.
      expect(CoreMockupDeviceStyle.defaultStatusBarClockSpacing, 2);
      expect(CoreMockupDeviceStyle.defaultStatusBarLeadingSpacing, 8);
      expect(CoreMockupDeviceStyle.defaultGestureBarHeight, 5);
      expect(CoreMockupDeviceStyle.defaultGestureBarOffset, 8);
      expect(CoreMockupDeviceStyle.defaultGestureBarRadius, 2);
    });

    test('every system bar field merges, copies and compares', () {
      const full = CoreMockupDeviceStyle(
        gestureBarColor: _kColorPrimary,
        statusBarIconColor: _kColorPrimary,
        statusBarBatteryBorderColor: _kColorOutline,
        statusBarBatteryCapColor: _kColorSurface,
        statusBarTextStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
        systemBarReferenceWidth: 1,
        landscapeSystemBarReferenceWidth: 2,
        statusBarHeight: 3,
        landscapeStatusBarHeight: 4,
        statusBarInset: 5,
        statusBarContentCenter: 6,
        statusBarWingWidth: 7,
        statusBarTrailingInset: 8,
        statusBarTrailingSpacing: 9,
        statusBarClockSpacing: 10,
        statusBarLeadingSpacing: 11,
        gestureBarWidth: 12,
        landscapeGestureBarWidth: 13,
        gestureBarHeight: 14,
        gestureBarOffset: 15,
        gestureBarRadius: 16,
        gestureBarAreaHeight: 17,
        landscapeGestureBarAreaHeight: 18,
      );
      const empty = CoreMockupDeviceStyle();
      // Merging onto nothing keeps every field; merging nothing keeps them too.
      expect(empty.merge(full), full);
      expect(full.merge(empty), full);
      expect(full.merge(null), full);
      expect(full.copyWith(), full);
      expect(full.hashCode, empty.merge(full).hashCode);
      // Each field takes part in equality: changing any one makes a different
      // style, which is what lets a theme switch rebuild its children.
      final changed = <CoreMockupDeviceStyle>[
        full.copyWith(gestureBarColor: _kColorSurface),
        full.copyWith(statusBarIconColor: _kColorSurface),
        full.copyWith(statusBarBatteryBorderColor: _kColorSurface),
        full.copyWith(statusBarBatteryCapColor: _kColorPrimary),
        full.copyWith(
          statusBarTextStyle: const CoreTextStyle.token(
            CoreTextStyles.labelSmall,
          ),
        ),
        full.copyWith(systemBarReferenceWidth: 101),
        full.copyWith(landscapeSystemBarReferenceWidth: 102),
        full.copyWith(statusBarHeight: 103),
        full.copyWith(landscapeStatusBarHeight: 104),
        full.copyWith(statusBarInset: 105),
        full.copyWith(statusBarContentCenter: 106),
        full.copyWith(statusBarWingWidth: 107),
        full.copyWith(statusBarTrailingInset: 108),
        full.copyWith(statusBarTrailingSpacing: 109),
        full.copyWith(statusBarClockSpacing: 110),
        full.copyWith(statusBarLeadingSpacing: 111),
        full.copyWith(gestureBarWidth: 112),
        full.copyWith(landscapeGestureBarWidth: 113),
        full.copyWith(gestureBarHeight: 114),
        full.copyWith(gestureBarOffset: 115),
        full.copyWith(gestureBarRadius: 116),
        full.copyWith(gestureBarAreaHeight: 117),
        full.copyWith(landscapeGestureBarAreaHeight: 118),
      ];
      for (final style in changed) {
        expect(style, isNot(full));
      }
      // The later style wins field by field.
      final merged = full.merge(
        const CoreMockupDeviceStyle(statusBarInset: 99),
      );
      expect(merged.statusBarInset, 99);
      expect(merged.statusBarHeight, 3);
    });

    test(
      'the status bar text style merges as a nested slot, not a replace',
      () {
        const base = CoreMockupDeviceStyle(
          statusBarTextStyle: CoreTextStyle.token(CoreTextStyles.titleSmall),
        );
        const over = CoreMockupDeviceStyle(
          statusBarTextStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
        );
        final merged = base.merge(over).statusBarTextStyle!;
        // The role survives; the weight lands on top of it.
        expect(merged.token, CoreTextStyles.titleSmall);
        expect(merged.fontWeight, CoreFontWeight.bold);
      },
    );

    test('hex values the canvas prints convert to ARGB, alpha first', () {
      // Figma prints #RRGGBBAA; CoreColor is 0xAARRGGBB. Each pair below is
      // the canvas's spelling and the constant that has to equal it.
      // The canvas string is reordered by hand here — which is exactly the
      // conversion to pin. The optical layers are pinned here; every other
      // hardware colour is pinned in the copy-literal group below.
      int argbOf(String rrggbbaa) {
        final rgb = rrggbbaa.substring(0, 6);
        final aa = rrggbbaa.substring(6, 8);
        return int.parse('$aa$rgb', radix: 16);
      }

      expect(
        CoreMockupDeviceStyle.defaultBezelInnerShadowColor.argb,
        argbOf('ffffff29'),
      );
      expect(
        CoreMockupDeviceStyle.defaultButtonDepthColor.argb,
        argbOf('00000059'),
      );
      expect(
        CoreMockupDeviceStyle.defaultRimGlowGradient.colors.map((c) => c.argb),
        [argbOf('ffffffff'), argbOf('ffffff00')],
      );
      expect(
        CoreMockupDeviceStyle.defaultButtonLengthGradient.colors.map(
          (c) => c.argb,
        ),
        [
          argbOf('ffffff00'),
          argbOf('ffffffad'),
          argbOf('00000080'),
          argbOf('ffffff00'),
          argbOf('ffffff00'),
          argbOf('00000080'),
          argbOf('ffffff7a'),
          argbOf('ffffff00'),
        ],
      );
    });

    test('every gradient states its stops, one per colour', () {
      for (final g in [
        CoreMockupDeviceStyle.defaultRailGradient,
        CoreMockupDeviceStyle.defaultRimGlowGradient,
        CoreMockupDeviceStyle.defaultCoreGradient,
        CoreMockupDeviceStyle.defaultButtonLengthGradient,
        CoreMockupDeviceStyle.defaultAntennaGradient,
      ]) {
        expect(g.stops, isNotNull);
        expect(g.stops!.length, g.colors.length);
      }
      expect(
        CoreMockupDeviceStyle.defaultRailGradient.stops,
        [0, 0.1, 0.9, 1],
      );
      expect(
        CoreMockupDeviceStyle.defaultCoreGradient.type,
        CoreGradientType.radial,
      );
      // The body gradient runs top to bottom — in landscape too.
      expect(
        CoreMockupDeviceStyle.defaultRailGradient.begin,
        CoreAlignment.topCenter,
      );
      expect(
        CoreMockupDeviceStyle.defaultRailGradient.end,
        CoreAlignment.bottomCenter,
      );
    });

    test('the lens core is a gradient unless a solid is stated', () {
      expect(
        CoreMockupDeviceStyle.resolveCoreGradient(),
        CoreMockupDeviceStyle.defaultCoreGradient,
      );
      // A stated cut-out fill makes the core that solid.
      expect(
        CoreMockupDeviceStyle.resolveCoreGradient(cutoutColor: _kColorPrimary),
        isNull,
      );
      const own = CoreGradient(
        type: CoreGradientType.radial,
        colors: [_kColorPrimary, _kColorSurface],
      );
      expect(
        CoreMockupDeviceStyle.resolveCoreGradient(
          cutoutColor: _kColorPrimary,
          coreGradient: own,
        ),
        own,
      );
    });

    test('the body is a gradient unless a solid is stated', () {
      expect(
        CoreMockupDeviceStyle.resolveBodyGradient(),
        CoreMockupDeviceStyle.defaultRailGradient,
      );
      // A caller's (or the shared theme's) solid makes the body that solid.
      expect(
        CoreMockupDeviceStyle.resolveBodyGradient(railColor: _kColorPrimary),
        isNull,
      );
      // A stated gradient wins over everything.
      const own = CoreGradient(
        type: CoreGradientType.linear,
        colors: [_kColorPrimary, _kColorSurface],
      );
      expect(
        CoreMockupDeviceStyle.resolveBodyGradient(
          railColor: _kColorPrimary,
          railGradient: own,
        ),
        own,
      );
    });

    test('the optical layers are literals, screen / bar are tokens', () {
      for (final c in [
        CoreMockupDeviceStyle.defaultBezelInnerShadowColor,
        CoreMockupDeviceStyle.defaultButtonDepthColor,
        ...CoreMockupDeviceStyle.defaultRimGlowGradient.colors,
        ...CoreMockupDeviceStyle.defaultButtonLengthGradient.colors,
      ]) {
        expect(c.token, isNull, reason: 'white / black laid over at alpha');
      }
      expect(CoreMockupDeviceStyle.defaultBackgroundColor.token, isNotNull);
      // The bar and the status bar's glyphs are `on-surface`, opaque.
      expect(CoreMockupDeviceStyle.defaultGestureBarColor.token, isNotNull);
      expect(CoreMockupDeviceStyle.defaultGestureBarColor.opacity, 1);
      expect(CoreMockupDeviceStyle.defaultStatusBarIconColor.token, isNotNull);
      expect(CoreMockupDeviceStyle.defaultStatusBarIconColor.opacity, 1);
      // The phone battery's outline and nub are faint versions of it.
      expect(
        CoreMockupDeviceStyle.defaultStatusBarBatteryBorderColor.token,
        CoreMockupDeviceStyle.defaultStatusBarIconColor.token,
      );
      expect(
        CoreMockupDeviceStyle.defaultStatusBarBatteryBorderColor.opacity,
        0.35,
      );
      expect(
        CoreMockupDeviceStyle.defaultStatusBarBatteryCapColor.opacity,
        CoreOpacity.opacity40,
      );
      // The button has its own base colour under two gloss layers.
      expect(
        CoreMockupDeviceStyle.defaultButtonColor,
        isNot(CoreMockupDeviceStyle.defaultRailColor),
      );
      // The body shadow rides the nested container slot.
      expect(
        CoreMockupDeviceStyle.defaultContainerStyle.boxShadow,
        CoreMockupDeviceStyle.defaultBodyShadow,
      );
    });

    test('the body casts the v1 two-layer shadow, unstrengthened', () {
      // Pinned to v1's `CoreShadow.xl` at the designer's request (#5485):
      // the device is not to move when the shadow scale does.
      expect(CoreMockupDeviceStyle.defaultBodyShadow, const [
        (
          offsetX: 0.0,
          offsetY: 14.0,
          blurRadius: 28.0,
          spreadRadius: -5.0,
          opacity: 0.08,
          inset: false,
        ),
        (
          offsetX: 0.0,
          offsetY: 6.0,
          blurRadius: 10.0,
          spreadRadius: -3.0,
          opacity: 0.05,
          inset: false,
        ),
      ]);
      // Not the v2 scale step, which is one wide layer.
      expect(
        CoreMockupDeviceStyle.defaultBodyShadow,
        isNot(CoreShadow.xl),
      );
      // The dark theme's multiplier is left out, so both brightnesses draw
      // the alpha the layers state — what v1 drew in either mode.
      expect(
        CoreMockupDeviceStyle.defaultContainerStyle.shadowStrengthens,
        isFalse,
      );
      const light = CoreSurfaceGeometryConstraint();
      const dark = CoreSurfaceGeometryConstraint(brightness: .dark);
      expect(
        light.shadow(CoreMockupDeviceStyle.defaultBodyShadow),
        CoreMockupDeviceStyle.defaultBodyShadow,
      );
      // The control: through the dark seat the same stack would be ×4.
      expect(
        dark.shadow(CoreMockupDeviceStyle.defaultBodyShadow).first.opacity,
        closeTo(0.08 * CoreShadow.darkStrength, 1e-12),
      );
      // What the resolvers do for a pinned stack: the dark seat with the
      // brightness put back to light.
      expect(
        dark
            .copyWith(brightness: .light)
            .shadow(CoreMockupDeviceStyle.defaultBodyShadow),
        CoreMockupDeviceStyle.defaultBodyShadow,
      );
    });

    test('the side button is its own colour, not the rail', () {
      // The designer copy lays the button on its own grey, lighter than the
      // body's middle — it does not follow the rail.
      expect(
        CoreMockupDeviceStyle.defaultButtonColor,
        isNot(CoreMockupDeviceStyle.defaultRailColor),
      );
      final railL = CoreColorConversion.colorToOKLch(
        CoreMockupDeviceStyle.defaultRailColor,
      ).l;
      final buttonL = CoreColorConversion.colorToOKLch(
        CoreMockupDeviceStyle.defaultButtonColor,
      ).l;
      expect(buttonL, greaterThan(railL));
    });

    test('defaultWidth — single source of truth (320 logical px)', () {
      expect(CoreMockupDeviceStyle.defaultWidth, 320);
    });
  });

  group("CoreMockupDeviceStyle — hardware colours are the designer copy's", () {
    // Every hardware default and the value the designer copy paints it, a
    // gradient stop by stop. The canvas prints these as #RRGGBB.
    final copyValue = <String, (CoreColor, int)>{
      'defaultRailColor': (CoreMockupDeviceStyle.defaultRailColor, 0xFF7D7F82),
      'defaultBorderColor': (
        CoreMockupDeviceStyle.defaultBorderColor,
        0xFF646568,
      ),
      'defaultRimHighlightColor': (
        CoreMockupDeviceStyle.defaultRimHighlightColor,
        0xFFFFFFFF,
      ),
      'defaultBezelColor': (
        CoreMockupDeviceStyle.defaultBezelColor,
        0xFF000000,
      ),
      'defaultBezelBorderColor': (
        CoreMockupDeviceStyle.defaultBezelBorderColor,
        0xFF27282B,
      ),
      'defaultButtonColor': (
        CoreMockupDeviceStyle.defaultButtonColor,
        0xFFAEAFB2,
      ),
      'defaultLensColor': (CoreMockupDeviceStyle.defaultLensColor, 0xFF000000),
      'defaultCutoutColor': (
        CoreMockupDeviceStyle.defaultCutoutColor,
        0xFF000000,
      ),
      'defaultLensHighlightColor': (
        CoreMockupDeviceStyle.defaultLensHighlightColor,
        0xFFFFFFFF,
      ),
      for (final (name, gradient, stops) in <(String, CoreGradient, List<int>)>[
        (
          'defaultRailGradient',
          CoreMockupDeviceStyle.defaultRailGradient,
          [0xFFC3C4C6, 0xFF7D7F82, 0xFF7D7F82, 0xFFAEAFB2],
        ),
        (
          'defaultAntennaGradient',
          CoreMockupDeviceStyle.defaultAntennaGradient,
          [0xFFFCFCFD, 0xFFE4E5E7],
        ),
        (
          'defaultCoreGradient',
          CoreMockupDeviceStyle.defaultCoreGradient,
          [
            0xFF000000,
            0xFF0A3348,
            0xFF0C3B52,
            0xFF105171,
            0xFF0C3B52,
            0xFF000000,
          ],
        ),
      ])
        for (var i = 0; i < stops.length; i++)
          '$name[$i]': (gradient.colors[i], stops[i]),
    };

    // The places a device must not change: light, dark and both
    // high-contrast modes under every surface style, read through CoUI's own
    // palette and through a chromatic brand's. A token anywhere in the
    // hardware would show up here as more than one value.
    final schemesBySource = <String, Map<String, CoreColorScheme>>{
      for (final (sourceName, source) in <(String, CoreSchemeSource)>[
        ('coui', CouiColorPresets.source),
        ('brand', kBrandFixtureSource),
      ])
        sourceName: {
          for (final style in CoreSurfaceStyleId.values)
            for (final brightness in CoreBrightness.values)
              for (final highContrast in [false, true])
                '${style.name} / ${brightness.name}'
                        '${highContrast ? ' / high contrast' : ''}':
                    resolveThemeSchemeFrom(
                      source,
                      brightness: brightness,
                      highContrast: highContrast,
                      surfaceStyle: style,
                    ),
        },
    };

    // `colour` resolved in every scheme of every source, all together.
    Set<int> everyValue(CoreColor colour) => {
      for (final schemes in schemesBySource.values)
        for (final scheme in schemes.values) scheme.resolve(colour).argb,
    };

    test("each hardware default is the copy's literal, at full strength", () {
      for (final MapEntry(key: name, value: (color, argb))
          in copyValue.entries) {
        expect(color.token, isNull, reason: '$name reads a token');
        expect(color.opacity, 1, reason: name);
        expect(color.argb, argb, reason: name);
      }
    });

    test('the gradients have exactly the stops listed — none extra', () {
      expect(CoreMockupDeviceStyle.defaultRailGradient.colors, hasLength(4));
      expect(CoreMockupDeviceStyle.defaultAntennaGradient.colors, hasLength(2));
      expect(CoreMockupDeviceStyle.defaultCoreGradient.colors, hasLength(6));
    });

    test('no mode and no palette moves a hardware colour', () {
      for (final MapEntry(key: name, value: (color, argb))
          in copyValue.entries) {
        expect(everyValue(color), {argb}, reason: name);
      }
    });

    test('the check can fail: tokens that follow the mode or the palette are '
        'told apart', () {
      // `surface` is the screen's own token and moves with the mode; a fixed
      // slot holds still across modes but is the palette's colour, so a
      // chromatic brand moves it. If either stopped differing, the check
      // above would be comparing nothing.
      expect(
        everyValue(const CoreColor.token(CoreColors.surface)).length,
        greaterThan(1),
      );
      for (final slot in [
        CoreColors.primaryFixedDim,
        CoreColors.onPrimaryFixed,
        CoreColors.onPrimaryFixedVariant,
        CoreColors.secondaryFixed,
      ]) {
        int lightOf(CoreSchemeSource source) => resolveThemeSchemeFrom(
          source,
          brightness: CoreBrightness.light,
        ).resolve(CoreColor.token(slot)).argb;
        expect(
          lightOf(CouiColorPresets.source),
          isNot(lightOf(kBrandFixtureSource)),
          reason: slot.name,
        );
      }
    });

    test('the optical layers stay literals', () {
      final literals = <String, CoreColor>{
        'defaultBezelInnerShadowColor':
            CoreMockupDeviceStyle.defaultBezelInnerShadowColor,
        'defaultButtonDepthColor':
            CoreMockupDeviceStyle.defaultButtonDepthColor,
        for (final (i, c)
            in CoreMockupDeviceStyle.defaultRimGlowGradient.colors.indexed)
          'defaultRimGlowGradient[$i]': c,
        for (final (i, c)
            in CoreMockupDeviceStyle.defaultButtonLengthGradient.colors.indexed)
          'defaultButtonLengthGradient[$i]': c,
        'defaultContainerStyle.shadowBaseColor':
            CoreMockupDeviceStyle.defaultContainerStyle.shadowBaseColor!,
      };
      for (final entry in literals.entries) {
        expect(entry.value.token, isNull, reason: entry.key);
        expect(entry.value.opacity, 1, reason: entry.key);
      }
    });

    test('a literal does not follow the mode either', () {
      for (final entry in {
        CoreMockupDeviceStyle.defaultBezelInnerShadowColor: 0x29FFFFFF,
        CoreMockupDeviceStyle.defaultButtonDepthColor: 0x59000000,
        // The body's drop shadow is a literal black — the device's colour,
        // not the palette's `shadow` slot, which a brand may turn over.
        CoreMockupDeviceStyle.defaultContainerStyle.shadowBaseColor!:
            0xFF000000,
      }.entries) {
        expect(everyValue(entry.key), {entry.value});
      }
    });
  });

  group('CoreMockupDeviceLayout — phone portrait (canvas 160 wide)', () {
    final l = _layout(.phone, width: _kPhonePreviewWidth);

    test('frame: 160×328 body, 154×322 bezel, 144×312 screen, inset 8', () {
      expect(l.inset, 8);
      expect(l.deviceWidth, 160);
      expect(l.deviceHeight, 328);
      expect(l.screenWidth, 144);
      expect(l.screenHeight, 312);
      _expectRect(l.bezelBox, left: 3, top: 3, width: 154, height: 322);
      _expectRect(l.screenBox, left: 8, top: 8, width: 144, height: 312);
    });

    test('radii are concentric: 24 → 21 → 16', () {
      expect(l.bezelBorderRadius, const CoreBorderRadius.all(21));
      expect(l.screenBorderRadius, const CoreBorderRadius.all(16));
    });

    test('rim strokes are inset top and bottom only', () {
      _expectRect(l.rimHighlight, left: 0, top: 0.4, width: 160, height: 327.2);
      _expectRect(l.rimGlow, left: 0, top: 0.8, width: 160, height: 326.8);
    });

    test('camera pill 45×13 in the screen, lens 6.5 at its right end', () {
      expect(l.cameraPlacement, CoreMockupCameraPlacement.screen);
      expect(l.cameraEdge, CoreMockupDeviceEdge.top);
      _expectRect(l.camera, left: 49.5, top: 4, width: 45, height: 13);
      _expectRect(l.lens!, left: 84.75, top: 7.25, width: 6.5, height: 6.5);
      _expectRect(l.core, left: 86.05, top: 8.55, width: 3.9, height: 3.9);
      _expectRect(
        l.lensHighlight,
        left: 86.57,
        top: 8.81,
        width: 1.04,
        height: 1.04,
      );
      // The pill holds a ring, so it is a hole — the cut-out fill, not the
      // lens fill.
      expect(l.cameraIsLens, isFalse);
    });

    test('buttons: volume left at 20% (+34 for down), power right at 30%', () {
      expect(l.volumeButtonEdge, CoreMockupDeviceEdge.left);
      expect(l.powerButtonEdge, CoreMockupDeviceEdge.right);
      _expectRect(
        l.volumeUpButton,
        left: -1.5,
        top: 65.6,
        width: 2,
        height: 26,
      );
      _expectRect(
        l.volumeDownButton!,
        left: -1.5,
        top: 99.6,
        width: 2,
        height: 26,
      );
      _expectRect(l.powerButton, left: 159.5, top: 98.4, width: 2, height: 40);
      // Protrudes one and a half of its two px past the body.
      expect(l.powerButton.left + l.powerButton.width, 161.5);
    });

    test('six antenna bands, as thick as the rail', () {
      final bands = l.antennaBands;
      expect(bands.length, 6);
      final expected = <(CoreMockupDeviceEdge, double, double, double, double)>[
        (.top, 122.441, 0, 1.9, 3),
        (.left, 0, 35.782, 3, 1.9),
        (.right, 157, 35.782, 3, 1.9),
        (.left, 0, 290.355, 3, 1.9),
        (.right, 157, 290.355, 3, 1.9),
        (.bottom, 31.549, 325, 1.9, 3),
      ];
      for (var i = 0; i < expected.length; i++) {
        final (edge, left, top, width, height) = expected[i];
        expect(bands[i].edge, edge, reason: 'band $i');
        _expectRect(
          bands[i].rect,
          left: left,
          top: top,
          width: width,
          height: height,
        );
      }
    });
  });

  group('CoreMockupDeviceLayout — phone landscape (canvas 328 wide)', () {
    final l = _layout(
      .phone,
      width: _kPhoneLandscapePreviewWidth,
      orientation: .landscape,
    );

    test('frame turns: 328×160 body, 322×154 bezel, 312×144 screen', () {
      // The aspect is read long-side-first — 9:19.5 authored, 19.5:9 drawn.
      expect(l.screenWidth, 312);
      expect(l.screenHeight, closeTo(144, 1e-9));
      expect(l.deviceHeight, closeTo(160, 1e-9));
      _expectRect(l.bezelBox, left: 3, top: 3, width: 322, height: 154);
    });

    test('the pill stands on the leading edge, lens at its top end', () {
      // The upright pose turned counter-clockwise: top edge → left edge,
      // right end → top end.
      expect(l.cameraPlacement, CoreMockupCameraPlacement.screen);
      expect(l.cameraEdge, CoreMockupDeviceEdge.left);
      _expectRect(l.camera, left: 4, top: 49.5, width: 13, height: 45);
      _expectRect(l.lens!, left: 7.25, top: 52.75, width: 6.5, height: 6.5);
      _expectRect(l.core, left: 8.55, top: 54.05, width: 3.9, height: 3.9);
      // The glint is not rotated with the pill.
      _expectRect(
        l.lensHighlight,
        left: 9.07,
        top: 54.31,
        width: 1.04,
        height: 1.04,
      );
    });

    test('buttons turn with the body: volume on top, power on the bottom', () {
      // The portrait pose is volume left / power right; a quarter turn
      // clockwise carries them to top / bottom. Nothing authors this pair
      // — it is the same rule the tablet's turn already follows.
      expect(l.volumeButtonEdge, CoreMockupDeviceEdge.top);
      expect(l.powerButtonEdge, CoreMockupDeviceEdge.bottom);
      _expectRect(
        l.volumeUpButton,
        left: 65.6,
        top: -1.5,
        width: 26,
        height: 2,
      );
      _expectRect(l.powerButton, left: 189.6, top: 159.5, width: 40, height: 2);
    });

    test('the second volume button steps along the edge it sits on', () {
      // Portrait stacks the rocker vertically; on a horizontal edge the
      // step has to follow the edge instead, or the two overlap.
      _expectRect(
        l.volumeDownButton!,
        left: 99.6,
        top: -1.5,
        width: 26,
        height: 2,
      );
    });

    test('the antenna set is the upright set carried one edge clockwise', () {
      final byEdge = <CoreMockupDeviceEdge, List<CoreMockupDeviceRect>>{};
      for (final band in l.antennaBands) {
        (byEdge[band.edge] ??= []).add(band.rect);
      }
      expect(l.antennaBands.length, 6);
      expect(byEdge[CoreMockupDeviceEdge.top]!.length, 2);
      expect(byEdge[CoreMockupDeviceEdge.bottom]!.length, 2);
      expect(byEdge[CoreMockupDeviceEdge.left]!.length, 1);
      expect(byEdge[CoreMockupDeviceEdge.right]!.length, 1);
      final top = byEdge[CoreMockupDeviceEdge.top]!;
      _expectRect(top[0], left: 35.782, top: 0, width: 1.9, height: 3);
      _expectRect(top[1], left: 290.355, top: 0, width: 1.9, height: 3);
      final bottom = byEdge[CoreMockupDeviceEdge.bottom]!;
      _expectRect(bottom[0], left: 35.782, top: 157, width: 1.9, height: 3);
      _expectRect(bottom[1], left: 290.355, top: 157, width: 1.9, height: 3);
      _expectRect(
        byEdge[CoreMockupDeviceEdge.left]!.single,
        left: 0,
        top: 31.549,
        width: 3,
        height: 1.9,
      );
      _expectRect(
        byEdge[CoreMockupDeviceEdge.right]!.single,
        left: 325,
        top: 122.441,
        width: 3,
        height: 1.9,
      );
    });

    test('a turned camera reserves no top inset', () {
      expect(
        l
            .safeAreaInsets(
              showCamera: true,
              showStatusBar: false,
              showGestureBar: false,
            )
            .top,
        0,
      );
    });
  });

  group('CoreMockupDeviceLayout — tablet portrait (canvas 321 wide)', () {
    final l = _layout(.tablet, width: _kTabletPreviewWidth);

    test('frame: 321×455 body, 315×449 bezel, 299×433 screen, inset 11', () {
      expect(l.inset, 11);
      expect(l.screenWidth, 299);
      expect(l.screenHeight, 433);
      expect(l.deviceHeight, 455);
      _expectRect(l.bezelBox, left: 3, top: 3, width: 315, height: 449);
      _expectRect(l.screenBox, left: 11, top: 11, width: 299, height: 433);
    });

    test('radii are concentric: 16 → 13 → 5', () {
      expect(l.bezelBorderRadius, const CoreBorderRadius.all(13));
      expect(l.screenBorderRadius, const CoreBorderRadius.all(5));
    });

    test('camera is a 4 circle in the bezel strip, no ring, core 2.4', () {
      expect(l.cameraPlacement, CoreMockupCameraPlacement.bezel);
      expect(l.cameraEdge, CoreMockupDeviceEdge.top);
      _expectRect(l.camera, left: 155.5, top: 2, width: 4, height: 4);
      expect(l.lens, isNull);
      _expectRect(l.core, left: 156.3, top: 2.8, width: 2.4, height: 2.4);
      _expectRect(
        l.lensHighlight,
        left: 156.62,
        top: 2.96,
        width: 0.64,
        height: 0.64,
      );
      // No ring: the round cut-out IS the lens and takes the lens fill.
      expect(l.cameraIsLens, isTrue);
      // The strip is 8 wide and the camera 4: it is centred on it.
      expect(l.camera.top + l.camera.height / 2, 4);
    });

    test('a bezel camera reserves nothing from the screen', () {
      expect(
        l
            .safeAreaInsets(
              showCamera: true,
              showStatusBar: false,
              showGestureBar: false,
            )
            .top,
        0,
      );
    });

    test('power on the top edge, volume on the left, no second volume', () {
      expect(l.powerButtonEdge, CoreMockupDeviceEdge.top);
      expect(l.volumeButtonEdge, CoreMockupDeviceEdge.left);
      _expectRect(
        l.powerButton,
        left: 238.096,
        top: -1.5,
        width: 45.433,
        height: 2,
      );
      _expectRect(
        l.volumeUpButton,
        left: -1.5,
        top: 83.642,
        width: 2,
        height: 33.317,
      );
      expect(l.volumeDownButton, isNull);
    });

    test('no antenna bands', () {
      expect(l.antennaBands, isEmpty);
    });
  });

  group('CoreMockupDeviceLayout — tablet landscape (canvas 455 wide)', () {
    final l = _layout(
      .tablet,
      width: _kTabletLandscapePreviewWidth,
      orientation: .landscape,
    );

    test('frame turns: 455×321 body, 449×315 bezel, 433×299 screen', () {
      expect(l.screenWidth, 433);
      expect(l.screenHeight, 299);
      expect(l.deviceHeight, 321);
      _expectRect(l.bezelBox, left: 3, top: 3, width: 449, height: 315);
    });

    test('the camera stays in the top strip, centred on it', () {
      expect(l.cameraPlacement, CoreMockupCameraPlacement.bezel);
      expect(l.cameraEdge, CoreMockupDeviceEdge.top);
      _expectRect(l.camera, left: 222.5, top: 2, width: 4, height: 4);
      _expectRect(l.core, left: 223.3, top: 2.8, width: 2.4, height: 2.4);
      _expectRect(
        l.lensHighlight,
        left: 223.62,
        top: 2.96,
        width: 0.64,
        height: 0.64,
      );
    });

    test('buttons turn with the body: volume on top, power on the right', () {
      expect(l.volumeButtonEdge, CoreMockupDeviceEdge.top);
      expect(l.powerButtonEdge, CoreMockupDeviceEdge.right);
    });

    test(
      'and are the landscape lengths and offsets, not the portrait ones',
      () {
        // A turned tablet's slabs are longer, and sit at fractions measured
        // afresh — power 0.155 down the right edge, volume 0.621 along the top.
        _expectRect(
          l.volumeUpButton,
          left: 282.343,
          top: -1.5,
          width: 36.316,
          height: 2,
        );
        _expectRect(
          l.powerButton,
          left: 454.5,
          top: 49.748,
          width: 2,
          height: 49.522,
        );
        expect(l.volumeDownButton, isNull);
      },
    );
  });

  group('CoreMockupDeviceLayout — hardware gradients follow the part', () {
    const length = CoreMockupDeviceStyle.defaultButtonLengthGradient;

    test('the gloss runs along a button, whichever edge it is on', () {
      final vertical = CoreMockupDeviceLayout.buttonLengthGradient(
        length,
        CoreMockupDeviceEdge.left,
      );
      expect(vertical.begin, CoreAlignment.topCenter);
      expect(vertical.end, CoreAlignment.bottomCenter);
      final horizontal = CoreMockupDeviceLayout.buttonLengthGradient(
        length,
        CoreMockupDeviceEdge.top,
      );
      expect(horizontal.begin, CoreAlignment.centerStart);
      expect(horizontal.end, CoreAlignment.centerEnd);
      // Only the direction is the layout's: the stops are the style's.
      expect(horizontal.colors, length.colors);
      expect(horizontal.stops, length.stops);
    });

    test('the shade is darkest at the edge nearest the body', () {
      const dark = CoreMockupDeviceStyle.defaultButtonDepthColor;
      // The body is to the right of a left-edge button, so the dark end is
      // its right side.
      final left = CoreMockupDeviceLayout.buttonDepthGradient(
        dark,
        CoreMockupDeviceEdge.left,
      );
      expect(left.colors.first, dark);
      expect(left.colors.last, CoreColor.transparent);
      expect(left.begin, CoreAlignment.centerEnd);
      expect(left.end, CoreAlignment.centerStart);
      final right = CoreMockupDeviceLayout.buttonDepthGradient(
        dark,
        CoreMockupDeviceEdge.right,
      );
      expect(right.begin, CoreAlignment.centerStart);
      final top = CoreMockupDeviceLayout.buttonDepthGradient(
        dark,
        CoreMockupDeviceEdge.top,
      );
      expect(top.begin, CoreAlignment.bottomCenter);
      final bottom = CoreMockupDeviceLayout.buttonDepthGradient(
        dark,
        CoreMockupDeviceEdge.bottom,
      );
      expect(bottom.begin, CoreAlignment.topCenter);
    });
  });

  group('CoreMockupDeviceLayout — the aspect is proportions, not a turn', () {
    // The rule this replaced read direction off the aspect pair's order. If
    // that derivation ever comes back, these two go red — nothing else in the
    // suite authors an aspect wider than it is tall.
    test('an authored landscape aspect draws portrait under portrait', () {
      final flipped = _layout(
        .tablet,
        width: _kTabletPreviewWidth,
        override: const CoreMockupDeviceStyle(
          screenAspectWidth: 433,
          screenAspectHeight: 299,
        ),
      );
      final plain = _layout(.tablet, width: _kTabletPreviewWidth);
      // Same body either way — the pair is read long-side-first.
      expect(flipped.screenHeight, plain.screenHeight);
      expect(flipped.deviceHeight, plain.deviceHeight);
      expect(flipped.screenHeight, greaterThan(flipped.screenWidth));
    });

    test('and the buttons keep their upright edges', () {
      final flipped = _layout(
        .tablet,
        width: _kTabletPreviewWidth,
        override: const CoreMockupDeviceStyle(
          screenAspectWidth: 433,
          screenAspectHeight: 299,
        ),
      );
      // Portrait tablet: volume on the left edge, power on the top edge.
      expect(flipped.volumeButtonEdge, CoreMockupDeviceEdge.left);
      expect(flipped.powerButtonEdge, CoreMockupDeviceEdge.top);
    });
  });

  group('CoreMockupDeviceLayout — derivations', () {
    test('deflateBorderRadius clamps at zero per corner', () {
      expect(
        CoreMockupDeviceLayout.deflateBorderRadius(
          const CoreBorderRadius.only(topLeft: 10, bottomRight: 2),
          4,
        ),
        const CoreBorderRadius.only(topLeft: 6),
      );
    });

    test('a ring override decides the cut-out fill, not the device name', () {
      // A phone told to draw no ring has a cut-out that is the lens.
      expect(
        _layout(
          .phone,
          width: _kPhonePreviewWidth,
          override: const CoreMockupDeviceStyle(lensSize: 0),
        ).cameraIsLens,
        isTrue,
      );
      // A tablet told to draw a ring has a cut-out that is a hole.
      expect(
        _layout(
          .tablet,
          width: _kTabletPreviewWidth,
          override: const CoreMockupDeviceStyle(lensSize: 4),
        ).cameraIsLens,
        isFalse,
      );
    });

    test('the placement is data, not a device name', () {
      // A tablet told its camera is cut out of the screen puts the whole
      // assembly in screen space against the top edge, and reserves a top
      // inset like a phone's.
      final onScreen = _layout(
        .tablet,
        width: _kTabletPreviewWidth,
        override: const CoreMockupDeviceStyle(
          cameraPlacement: CoreMockupCameraPlacement.screen,
        ),
      );
      expect(onScreen.cameraPlacement, CoreMockupCameraPlacement.screen);
      _expectRect(
        onScreen.camera,
        left: 147.5,
        top: 2,
        width: 4,
        height: 4,
      );
      expect(
        onScreen
            .safeAreaInsets(
              showCamera: true,
              showStatusBar: false,
              showGestureBar: false,
            )
            .top,
        greaterThan(0),
      );
    });

    test('device size = screen + inset × 2 for any width', () {
      final l = _layout(.phone, width: CoreMockupDeviceStyle.defaultWidth);
      expect(l.deviceWidth, l.screenWidth + l.inset * 2);
      expect(l.deviceHeight, l.screenHeight + l.inset * 2);
    });

    test('an antenna length of 0 draws no bands', () {
      expect(
        _layout(
          .phone,
          width: _kPhonePreviewWidth,
          override: const CoreMockupDeviceStyle(antennaBandLength: 0),
        ).antennaBands,
        isEmpty,
      );
    });
  });

  group('CoreMockupDeviceLayout — fixed system chrome', () {
    test('each pose uses its authored reference scale', () {
      // Phone upright: 144 over 402; on its side: 312 over 874.
      expect(
        _layout(.phone, width: _kPhonePreviewWidth).systemBarScale,
        closeTo(144 / 402, 1e-12),
      );
      expect(
        _layout(
          .phone,
          width: _kPhoneLandscapePreviewWidth,
          orientation: .landscape,
        ).systemBarScale,
        closeTo(312 / 874, 1e-12),
      );
      // The canvas draws the tablet's bars at the phone's factor in both
      // poses, which is what its two reference widths are authored to give.
      for (final m in [_kMembers[2], _kMembers[3]]) {
        expect(
          _layout(
            .tablet,
            width: m.width,
            orientation: m.orientation,
          ).systemBarScale,
          closeTo(144 / 402, 1e-12),
        );
      }
    });

    test(
      'resizing preserves bar heights, glyph sizes and content centres',
      () {
        // Figma resizing stretches the layout boxes.
        // The drawings keep their dimensions.
        for (final m in _kMembers) {
          for (final factor in [0.5, 1.0, 2.0, 3.7]) {
            final l = _layout(
              m.device,
              width: m.width * factor,
              orientation: m.orientation,
            );
            final d = CoreMockupDeviceStyle.defaultsByDevice[m.device]!;
            final scale = m.orientation == .landscape
                ? d.landscapeSystemBarReferenceScale!
                : d.systemBarReferenceScale!;
            expect(l.systemBarScale, closeTo(scale, 1e-12));
            final area = m.orientation == .landscape
                ? d.landscapeGestureBarAreaHeight!
                : d.gestureBarAreaHeight!;
            expect(l.gestureBarArea.height, closeTo(area * scale, 1e-9));
            expect(l.gestureBar.height, closeTo(5 * scale, 1e-9));
            expect(l.gestureBarRadius, closeTo(2 * scale, 1e-9));
            final bar = l.statusBar;
            if (bar != null) {
              final height = m.orientation == .landscape
                  ? d.landscapeStatusBarHeight!
                  : d.statusBarHeight!;
              expect(bar.scale, l.systemBarScale);
              expect(bar.rect.height, closeTo(height * scale, 1e-9));
              expect(bar.rect.width, l.screenWidth);
              expect(
                bar.contentCenter,
                closeTo(d.statusBarContentCenter! * scale, 1e-9),
              );
            }
          }
        }
      },
    );

    test('hardware and system chrome retain their dimensions', () {
      final small = _layout(.phone, width: 160);
      final big = _layout(.phone, width: 640);
      // Both hardware and the OS drawings retain their design dimensions.
      expect(big.camera.width, small.camera.width);
      expect(big.camera.height, small.camera.height);
      expect(
        big.gestureBarArea.height,
        equals(small.gestureBarArea.height),
      );
    });

    test(
      'resizing preserves Figma vertical geometry and screen-edge anchoring',
      () {
        for (final width in [160.0, 240.0, 320.0]) {
          final l = _layout(.phone, width: width);
          final bar = l.statusBar!;
          expect(l.camera.top, 4);
          expect(l.camera.width, 45);
          expect(l.camera.height, 13);
          expect(bar.rect.height, closeTo(21.13432884, 1e-6));
          expect(bar.contentCenter, closeTo(11.64179104, 1e-6));
          final leadingCenter =
              bar.leading.box.left + bar.leading.box.width / 2;
          expect(
            leadingCenter,
            closeTo(26.68656716, 1e-6),
          );
          final trailingCenter =
              bar.trailing.box.left + bar.trailing.box.width / 2;
          expect(l.screenWidth - trailingCenter, closeTo(27.04477612, 1e-6));
          expect(l.gestureBar.width, closeTo(51.58208955, 1e-6));
          expect(l.gestureBar.height, closeTo(1.79104478, 1e-6));
          expect(
            l.screenHeight - l.gestureBar.top - l.gestureBar.height,
            closeTo(2.86567164, 1e-6),
          );
          _expectInsets(
            l.safeAreaInsets(
              showCamera: true,
              showStatusBar: true,
              showGestureBar: true,
            ),
            top: 21.13432884,
            bottom: 12.17910448,
            left: 0,
          );
        }
      },
    );

    test('reference scale can be overridden independently in each pose', () {
      const style = CoreMockupDeviceStyle(
        systemBarReferenceScale: 0.5,
        landscapeSystemBarReferenceScale: 0.25,
      );
      expect(
        _layout(.phone, width: 320, override: style).statusBar!.rect.height,
        29.5,
      );
      expect(_layout(.phone, width: 640, override: style).camera.top, 4);
      expect(
        _layout(
          .phone,
          width: 320,
          orientation: .landscape,
          override: style,
        ).gestureBar.height,
        1.25,
      );
      expect(style.copyWith().merge(const CoreMockupDeviceStyle()), style);
      expect(
        style,
        isNot(const CoreMockupDeviceStyle(systemBarReferenceScale: 0.25)),
      );
    });

    test('no reference width, no bars — never a division by zero', () {
      final l = _layout(
        .phone,
        width: _kPhonePreviewWidth,
        override: const CoreMockupDeviceStyle(systemBarReferenceWidth: 0),
      );
      expect(l.systemBarScale, 0);
      expect(l.statusBar!.rect.height, 0);
      expect(l.gestureBar.height, 0);
    });
  });

  group('CoreMockupDeviceLayout — phone status bar (canvas 160 wide)', () {
    final l = _layout(.phone, width: _kPhonePreviewWidth);
    final bar = l.statusBar!;

    test('59 points over 402, flush with the top of the screen', () {
      _expectRect(bar.rect, left: 0, top: 0, width: 144, height: 21.134);
      expect(bar.scale, closeTo(0.358209, 1e-6));
      expect(bar.contentCenter, closeTo(11.642, 1e-3));
    });

    test('the clock sits in the leading wing, centred', () {
      expect(bar.leading.alignment, CoreMainAxisAlignment.center);
      // A 101-point wing 24 points in: 8.597 in, 36.179 wide.
      expect(bar.leading.box.left, closeTo(8.597, 1e-3));
      expect(bar.leading.box.width, closeTo(36.179, 1e-3));
      expect(bar.leading.items.length, 1);
      final clock = bar.leading.items.single as CoreMockupStatusBarText;
      expect(clock.text, '9:41');
      // The canvas's "9:41" is centred at (26.687, 11.642).
      expect(
        bar.leading.box.left + bar.leading.box.width / 2,
        closeTo(26.687, 1e-3),
      );
      expect(
        bar.leading.box.top + bar.leading.box.height / 2,
        closeTo(11.642, 1e-3),
      );
    });

    test("the groups' boxes are symmetric about the content line", () {
      for (final group in [bar.leading, bar.trailing]) {
        expect(
          group.box.top + group.box.height / 2,
          closeTo(bar.contentCenter, 1e-9),
        );
        // …and stay inside the bar.
        expect(group.box.top, greaterThanOrEqualTo(0));
        expect(
          group.box.top + group.box.height,
          lessThanOrEqualTo(bar.rect.height + 1e-9),
        );
      }
    });

    test('signal, wifi and battery in the trailing wing, centred', () {
      expect(bar.trailing.alignment, CoreMainAxisAlignment.center);
      // The trailing wing is 101 points wide at the other edge, 2 points
      // narrower on its outer side.
      expect(bar.trailing.box.left, closeTo(99.224, 1e-3));
      expect(bar.trailing.box.width, closeTo(35.463, 1e-3));
      final kinds = [
        for (final item in bar.trailing.items) item.runtimeType,
      ];
      expect(kinds, [
        CoreMockupStatusBarGlyph,
        CoreMockupStatusBarGlyph,
        CoreMockupStatusBarBattery,
      ]);
      final rects = _rowRects(bar.trailing);
      // The canvas's three parts: (103.403, 9.452) 6.878 × 4.38 · (112.429,
      // 9.433) 6.14 × 4.416 · (120.719, 9.313) 9.789 × 4.657.
      _expectRect(
        rects[0],
        left: 103.403,
        top: 9.452,
        width: 6.878,
        height: 4.38,
      );
      _expectRect(
        rects[1],
        left: 112.429,
        top: 9.433,
        width: 6.14,
        height: 4.416,
      );
      _expectRect(
        rects[2],
        left: 120.719,
        top: 9.313,
        width: 9.789,
        height: 4.657,
      );
      // 6 points between them.
      expect(bar.trailing.items[0].gapAfter, closeTo(2.149, 1e-3));
      expect(bar.trailing.items[2].gapAfter, 0);
    });

    test("the glyphs are the phone's, filling their own proportions", () {
      final cellular = bar.trailing.items[0] as CoreMockupStatusBarGlyph;
      final wifi = bar.trailing.items[1] as CoreMockupStatusBarGlyph;
      expect(cellular.glyph, CoreMockupDeviceStyle.phoneCellularGlyph);
      expect(wifi.glyph, CoreMockupDeviceStyle.phoneWifiGlyph);
      // Scaled uniformly: the box has the glyph's own aspect.
      for (final item in [cellular, wifi]) {
        expect(
          item.width / item.height,
          closeTo(item.glyph.width / item.glyph.height, 1e-9),
        );
        expect(item.width / item.glyph.width, closeTo(bar.scale, 1e-9));
      }
    });

    test('the battery is an outline, a level and a nub in one box', () {
      final battery = bar.trailing.items[2] as CoreMockupStatusBarBattery;
      // The canvas measures these a hair (0.015) off the ideal 0 / 2 / 26
      // points — a scaling artefact — so they are held to 0.02.
      void expectNear(
        CoreMockupDeviceRect actual, {
        required double left,
        required double top,
        required double width,
        required double height,
      }) {
        expect(actual.left, closeTo(left, 0.02));
        expect(actual.top, closeTo(top, 0.02));
        expect(actual.width, closeTo(width, 1e-3));
        expect(actual.height, closeTo(height, 1e-3));
      }

      expectNear(battery.border, left: 0, top: 0, width: 8.955, height: 4.657);
      expect(battery.borderWidth, closeTo(0.358, 1e-3));
      expect(battery.borderRadius, closeTo(1.433, 1e-3));
      expectNear(
        battery.capacity,
        left: 0.701,
        top: 0.716,
        width: 7.522,
        height: 3.224,
      );
      expect(battery.capacityRadius, closeTo(0.716, 1e-3));
      expectNear(
        battery.cap,
        left: 9.299,
        top: 1.612,
        width: 0.476,
        height: 1.46,
      );
      expect(battery.capGlyph, CoreMockupDeviceStyle.phoneBatteryCapGlyph);
      // The level is the outline shrunk by 2 points on every side.
      expect(battery.capacity.left, closeTo(2 * bar.scale, 1e-9));
      expect(
        battery.capacity.width,
        closeTo(battery.border.width - 4 * bar.scale, 1e-9),
      );
      // The box is outline + 1-point gap + nub.
      expect(
        battery.width,
        closeTo(battery.border.width + bar.scale + battery.cap.width, 1e-9),
      );
    });

    test('the clock text style is a role and a colour, no size of its own', () {
      final style = CoreMockupDeviceStyle
          .defaultsByDevice[CoreMockupDevice.phone]!
          .statusBarTextStyle!;
      expect(style.token, CoreTextStyles.titleSmall);
      expect(style.color, const CoreColor.token(CoreColors.onSurface));
      expect(style.fontSize, isNull);
    });
  });

  group('CoreMockupDeviceLayout — tablet status bar', () {
    for (final m in [_kMembers[2], _kMembers[3]]) {
      group('${m.orientation} (canvas ${m.width} wide)', () {
        final l = _layout(.tablet, width: m.width, orientation: m.orientation);
        final bar = l.statusBar!;
        final screenWidth = l.screenWidth;

        test('32 points tall in both poses, groups on the two edges', () {
          _expectRect(
            bar.rect,
            left: 0,
            top: 0,
            width: screenWidth,
            height: 11.463,
          );
          expect(bar.contentCenter, closeTo(5.731, 1e-3));
          // No wings: both groups share one box between the 16-point insets
          // and are pushed to its two ends.
          expect(bar.leading.alignment, CoreMainAxisAlignment.start);
          expect(bar.trailing.alignment, CoreMainAxisAlignment.end);
          expect(bar.leading.box, bar.trailing.box);
          expect(bar.leading.box.left, closeTo(5.731, 1e-3));
          expect(
            bar.leading.box.left + bar.leading.box.width,
            closeTo(screenWidth - 5.731, 1e-3),
          );
          // The whole bar's height: it is already symmetric.
          expect(bar.leading.box.top, 0);
          expect(bar.leading.box.height, closeTo(11.463, 1e-3));
        });

        test(
          'clock, meridiem and date lead; wifi, percent and battery trail',
          () {
            final leading = [
              for (final item in bar.leading.items)
                (item as CoreMockupStatusBarText).text,
            ];
            expect(leading, ['9:41', '오전', '4월 1일 수요일']);
            // 2 points between the clock and its meridiem, 8 before the date.
            expect(bar.leading.items[0].gapAfter, closeTo(0.716, 1e-3));
            expect(bar.leading.items[1].gapAfter, closeTo(2.866, 1e-3));
            expect(bar.leading.items[2].gapAfter, 0);
            expect(bar.trailing.items.length, 3);
            final wifi = bar.trailing.items[0] as CoreMockupStatusBarGlyph;
            final percent = bar.trailing.items[1] as CoreMockupStatusBarText;
            final battery = bar.trailing.items[2] as CoreMockupStatusBarGlyph;
            expect(wifi.glyph, CoreMockupDeviceStyle.tabletWifiGlyph);
            expect(percent.text, '100%');
            expect(battery.glyph, CoreMockupDeviceStyle.tabletBatteryGlyph);
            // 4 points between the trailing items.
            expect(wifi.gapAfter, closeTo(1.433, 1e-3));
            expect(percent.gapAfter, closeTo(1.433, 1e-3));
            expect(battery.gapAfter, 0);
            // The canvas's glyph boxes: wifi 4.836 × 3.582, battery
            // 9.791 × 4.657.
            expect(wifi.width, closeTo(4.836, 1e-3));
            expect(wifi.height, closeTo(3.582, 1e-3));
            expect(battery.width, closeTo(9.791, 1e-3));
            expect(battery.height, closeTo(4.657, 1e-3));
          },
        );

        test('the right end of the trailing group is 16 points in', () {
          // Space-between: the battery ends at the content box's right edge,
          // which is where the canvas puts it (width − 5.731).
          final box = bar.trailing.box;
          expect(box.left + box.width, closeTo(screenWidth - 5.731, 1e-3));
        });
      });
    }

    test("the clock text style is a label role, not the phone's title", () {
      final style = CoreMockupDeviceStyle
          .defaultsByDevice[CoreMockupDevice.tablet]!
          .statusBarTextStyle!;
      expect(style.token, CoreTextStyles.labelLarge);
      expect(style.color, const CoreColor.token(CoreColors.onSurface));
    });
  });

  group('CoreMockupDeviceLayout — phone turned has no status bar', () {
    test('the height of 0 draws none', () {
      final l = _layout(
        .phone,
        width: _kPhoneLandscapePreviewWidth,
        orientation: .landscape,
      );
      expect(l.statusBar, isNull);
    });

    test('a state of a height brings one back — it is data, not a rule', () {
      final l = _layout(
        .phone,
        width: _kPhoneLandscapePreviewWidth,
        orientation: .landscape,
        override: const CoreMockupDeviceStyle(landscapeStatusBarHeight: 59),
      );
      expect(l.statusBar, isNotNull);
      expect(l.statusBar!.rect.height, closeTo(59 * l.systemBarScale, 1e-9));
    });
  });

  group('CoreMockupDeviceLayout — home indicator', () {
    // Each member's area and bar, screen-space: the instance the canvas
    // draws along the bottom and the bar inside it.
    final cases =
        <
          ({
            String name,
            int member,
            CoreMockupDeviceRect area,
            CoreMockupDeviceRect bar,
            double radius,
          })
        >[
          (
            name: 'phone portrait',
            member: 0,
            area: (left: 0, top: 299.821, width: 144, height: 12.179),
            bar: (left: 46.209, top: 307.343, width: 51.582, height: 1.791),
            radius: 0.716,
          ),
          (
            name: 'phone landscape',
            member: 1,
            area: (left: 0, top: 136.503, width: 312, height: 7.497),
            bar: (left: 118.696, top: 139.359, width: 74.609, height: 1.785),
            radius: 0.714,
          ),
          (
            name: 'tablet portrait',
            member: 2,
            area: (left: 0, top: 425.836, width: 299, height: 7.164),
            bar: (left: 93.261, top: 428.343, width: 112.478, height: 1.791),
            radius: 0.716,
          ),
          (
            name: 'tablet landscape',
            member: 3,
            area: (left: 0, top: 291.836, width: 433, height: 7.164),
            bar: (left: 160.261, top: 294.343, width: 112.478, height: 1.791),
            radius: 0.716,
          ),
        ];
    for (final c in cases) {
      test('${c.name}: the area, the bar and its radius match the canvas', () {
        final m = _kMembers[c.member];
        final l = _layout(m.device, width: m.width, orientation: m.orientation);
        _expectRect(
          l.gestureBarArea,
          left: c.area.left,
          top: c.area.top,
          width: c.area.width,
          height: c.area.height,
        );
        _expectRect(
          l.gestureBar,
          left: c.bar.left,
          top: c.bar.top,
          width: c.bar.width,
          height: c.bar.height,
        );
        expect(l.gestureBarRadius, closeTo(c.radius, 1e-3));
        // The bar is centred, with an 8-point gap below it.
        expect(
          l.gestureBar.left + l.gestureBar.width / 2,
          closeTo(l.screenWidth / 2, 1e-9),
        );
        expect(
          l.screenHeight - (l.gestureBar.top + l.gestureBar.height),
          closeTo(8 * l.systemBarScale, 1e-9),
        );
      });
    }

    test('the bar stays inside its area', () {
      for (final m in _kMembers) {
        final l = _layout(m.device, width: m.width, orientation: m.orientation);
        expect(l.gestureBar.top, greaterThanOrEqualTo(l.gestureBarArea.top));
        expect(
          l.gestureBar.top + l.gestureBar.height,
          lessThanOrEqualTo(l.gestureBarArea.top + l.gestureBarArea.height),
        );
      }
    });

    test('a stated width ratio still pins the bar to that fraction', () {
      final l = _layout(
        .phone,
        width: _kPhonePreviewWidth,
        // The deprecated pin: a caller who stated it still gets its bar.
        override: const CoreMockupDeviceStyle(gestureBarWidthRatio: 0.5),
      );
      const pinned = CoreMockupDeviceStyle(gestureBarWidthRatio: 0.5);
      expect(pinned.pinnedGestureBarWidthRatio, 0.5);
      expect(const CoreMockupDeviceStyle().pinnedGestureBarWidthRatio, isNull);
      expect(l.gestureBar.width, closeTo(72, 1e-9));
      expect(l.gestureBar.left, closeTo(36, 1e-9));
      // Everything else about the bar is untouched.
      expect(l.gestureBar.height, closeTo(1.791, 1e-3));
    });
  });

  group('MockupDevice status bar content', () {
    test('the sample content is fixed, not localised chrome', () {
      expect(CoreMockupDeviceStyle.sampleTime, '9:41');
      expect(CoreMockupDeviceStyle.sampleMeridiem, '오전');
      expect(CoreMockupDeviceStyle.sampleDate, '4월 1일 수요일');
      expect(CoreMockupDeviceStyle.sampleBatteryLevel, '100%');
    });

    // The box a glyph states is its own tight bounds: a platform scales the
    // path from that box to the rectangle the layout gives, so a box wider
    // than the drawing would shrink it.
    final glyphs = <String, CoreVectorGlyph>{
      'phoneCellular': CoreMockupDeviceStyle.phoneCellularGlyph,
      'phoneWifi': CoreMockupDeviceStyle.phoneWifiGlyph,
      'phoneBatteryCap': CoreMockupDeviceStyle.phoneBatteryCapGlyph,
      'tabletWifi': CoreMockupDeviceStyle.tabletWifiGlyph,
      'tabletBattery': CoreMockupDeviceStyle.tabletBatteryGlyph,
    };
    for (final entry in glyphs.entries) {
      test('${entry.key} fills the box it states', () {
        final glyph = entry.value;
        final bounds = _pathBounds(glyph.path);
        expect(bounds.minX, closeTo(0, 1e-3));
        expect(bounds.minY, closeTo(0, 1e-3));
        expect(bounds.maxX, closeTo(glyph.width, 1e-3));
        expect(bounds.maxY, closeTo(glyph.height, 1e-3));
      });
    }

    test('the glyph path speaks only absolute M, L, C and Z', () {
      for (final glyph in glyphs.values) {
        expect(glyph.path, startsWith('M '));
        expect(glyph.path, endsWith('Z'));
        expect(glyph.path, matches(RegExp(r'^[MLCZ0-9. \-]+$')));
      }
    });

    test('the nub is the one non-zero-winding drawing', () {
      expect(
        CoreMockupDeviceStyle.phoneBatteryCapGlyph.fillRule,
        CoreVectorFillRule.nonZero,
      );
      for (final glyph in [
        CoreMockupDeviceStyle.phoneCellularGlyph,
        CoreMockupDeviceStyle.phoneWifiGlyph,
        CoreMockupDeviceStyle.tabletWifiGlyph,
        CoreMockupDeviceStyle.tabletBatteryGlyph,
      ]) {
        expect(glyph.fillRule, CoreVectorFillRule.evenOdd);
      }
    });

    test('CoreVectorGlyph has value equality', () {
      const a = CoreVectorGlyph(
        path: 'M 0 0 L 1 0 L 1 1 Z',
        width: 1,
        height: 1,
        fillRule: CoreVectorFillRule.evenOdd,
      );
      const b = CoreVectorGlyph(
        path: 'M 0 0 L 1 0 L 1 1 Z',
        width: 1,
        height: 1,
        fillRule: CoreVectorFillRule.evenOdd,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          const CoreVectorGlyph(
            path: 'M 0 0 L 1 0 L 1 1 Z',
            width: 1,
            height: 1,
            fillRule: CoreVectorFillRule.nonZero,
          ),
        ),
      );
    });
  });

  group('CoreMockupDeviceContract', () {
    test('every Show flag defaults to drawn', () {
      expect(CoreMockupDeviceContract.defaultShowCamera, isTrue);
      expect(CoreMockupDeviceContract.defaultShowStatusBar, isTrue);
      expect(CoreMockupDeviceContract.defaultShowGestureBar, isTrue);
    });
  });

  group('CoreMockupDeviceTheme', () {
    test('passes through style + deviceStyles with value equality', () {
      const style = CoreMockupDeviceStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
      );
      const perDevice = {
        CoreMockupDevice.tablet: CoreMockupDeviceStyle(
          railColor: _kColorPrimary,
        ),
      };
      const a = CoreMockupDeviceTheme(style: style, deviceStyles: perDevice);
      const b = CoreMockupDeviceTheme(style: style, deviceStyles: perDevice);
      expect(a.style, style);
      expect(
        a.deviceStyles?[CoreMockupDevice.tablet]?.railColor,
        _kColorPrimary,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreMockupDeviceFinish', () {
    const flat = CoreMockupDeviceFinish.flat;
    final flatRow = CoreMockupDeviceStyle.defaultsByFinish[flat]!;

    test('realistic is the default and its row states nothing', () {
      expect(
        CoreMockupDeviceFinish.defaultFinish,
        CoreMockupDeviceFinish.realistic,
      );
      expect(
        CoreMockupDeviceStyle.defaultsByFinish[CoreMockupDeviceFinish
            .realistic],
        const CoreMockupDeviceStyle(),
      );
      // Every finish has a row.
      expect(
        CoreMockupDeviceStyle.defaultsByFinish.keys,
        unorderedEquals(CoreMockupDeviceFinish.values),
      );
    });

    test('the realistic literals are untouched', () {
      expect(
        CoreMockupDeviceStyle.defaultBezelColor,
        const CoreColor(0xFF000000),
      );
      expect(CoreMockupDeviceStyle.defaultWidth, 320);
      expect(
        CoreMockupDeviceStyle.defaultWidthFor(
          CoreMockupDeviceFinish.realistic,
        ),
        320,
      );
    });

    test('flat states a ring of space8 in surfaceContainerHighest', () {
      expect(flatRow.bezelWidth, CoreSpace.space8);
      expect(
        flatRow.bezelColor,
        const CoreColor.token(CoreColors.surfaceContainerHighest),
      );
      expect(
        flatRow.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius32),
      );
      expect(flatRow.screenAspectWidth, 1);
      expect(flatRow.screenAspectHeight, 2);
    });

    test('the body takes the ring colour so no fill shows at the corners', () {
      expect(flatRow.railColor, flatRow.bezelColor);
      expect(
        CoreMockupDeviceStyle.resolveBodyGradient(
          railColor: flatRow.railColor,
          railGradient: flatRow.railGradient,
        ),
        isNull,
      );
    });

    test('flat states no rail, line, rim light, inner glow or lens ring', () {
      expect(flatRow.railWidth, 0);
      expect(flatRow.borderWidth, 0);
      expect(flatRow.bezelBorderWidth, 0);
      expect(flatRow.bezelInnerShadowBlur, 0);
      expect(flatRow.bezelInnerShadowSpread, 0);
      expect(flatRow.rimHighlightWidth, 0);
      expect(flatRow.rimGlowWidth, 0);
      expect(flatRow.lensSize, 0);
    });

    test('flat states no cast shadow and realistic keeps its own', () {
      expect(flatRow.containerStyle?.boxShadow, isEmpty);
      expect(
        flatRow.containerStyle?.boxShadow,
        isNotNull,
        reason: 'an empty stack is stated, not left to the default',
      );
      final merged = CoreMockupDeviceStyle.defaultContainerStyle.merge(
        flatRow.containerStyle,
      );
      expect(merged.boxShadow, isEmpty);
      expect(
        CoreMockupDeviceStyle.defaultContainerStyle.boxShadow,
        CoreMockupDeviceStyle.defaultBodyShadow,
      );
    });

    test('flat body width is the 240 screen plus the ring on both sides', () {
      expect(CoreMockupDeviceStyle.defaultFlatScreenWidth, 240);
      expect(CoreMockupDeviceStyle.defaultFlatWidth, 256);
      expect(CoreMockupDeviceStyle.defaultWidthFor(flat), 256);
    });

    for (final device in CoreMockupDevice.values) {
      for (final orientation in CoreMockupOrientation.values) {
        test('flat $device $orientation: no buttons, no bands, screen radius '
            '24, a 1 : 2 screen', () {
          final l = _layout(
            device,
            width: CoreMockupDeviceStyle.defaultWidthFor(flat),
            orientation: orientation,
            override: flatRow,
          );
          expect(l.hasPowerButton, isFalse);
          expect(l.hasVolumeButton, isFalse);
          expect(l.volumeDownButton, isNull);
          expect(l.antennaBands, isEmpty);
          expect(l.inset, CoreSpace.space8);
          expect(l.bezelBorderRadius, const CoreBorderRadius.all(32));
          expect(l.screenBorderRadius, const CoreBorderRadius.all(24));
          // `width` is the body's horizontal extent, so a turned frame keeps
          // the 240 across and is half as tall.
          expect(l.screenWidth, closeTo(240, 1e-9));
          final landscape = orientation == CoreMockupOrientation.landscape;
          expect(l.screenHeight, closeTo(landscape ? 120 : 480, 1e-9));
        });
      }
    }

    test('realistic keeps its buttons', () {
      for (final m in _kMembers) {
        final l = _layout(m.device, width: m.width, orientation: m.orientation);
        expect(l.hasPowerButton, isTrue, reason: '${m.device}');
        expect(l.hasVolumeButton, isTrue, reason: '${m.device}');
      }
    });

    test('the Show flags default per finish', () {
      for (final finish in CoreMockupDeviceFinish.values) {
        final drawn = finish == CoreMockupDeviceFinish.realistic;
        expect(CoreMockupDeviceContract.defaultShowCameraFor(finish), drawn);
        expect(
          CoreMockupDeviceContract.defaultShowStatusBarFor(finish),
          drawn,
        );
        expect(
          CoreMockupDeviceContract.defaultShowGestureBarFor(finish),
          drawn,
        );
      }
    });

    test('the theme carries finishStyles with value equality', () {
      const perFinish = {
        CoreMockupDeviceFinish.flat: CoreMockupDeviceStyle(
          bezelColor: _kColorPrimary,
        ),
      };
      const a = CoreMockupDeviceTheme(finishStyles: perFinish);
      const b = CoreMockupDeviceTheme(finishStyles: perFinish);
      const c = CoreMockupDeviceTheme(
        finishStyles: {
          CoreMockupDeviceFinish.flat: CoreMockupDeviceStyle(
            bezelColor: _kColorOutline,
          ),
        },
      );
      expect(a.finishStyles?[flat]?.bezelColor, _kColorPrimary);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(const CoreMockupDeviceTheme())));
    });
  });
}
