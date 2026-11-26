/// Derived geometry for `MockupDevice` — the one place both platform
/// resolvers and the Figma builder compute the device's rectangles from.
library;

import 'dart:math' as math;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/component/alignment.dart';
import 'package:coui_core/src/component/contracts/frame/core_gradient.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_camera_placement.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_device.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_device_rect.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_orientation.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_system_bar_layout.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:meta/meta.dart';

/// One antenna band: the body edge it lies on and its body-space rectangle.
///
/// The edge is carried out of the geometry because a Figma part is pinned,
/// not laid out — a band on the bottom edge has to hold to the bottom when
/// the member resizes, and the rectangle alone cannot say which edge it came
/// from.
typedef CoreMockupDeviceAntennaBand = ({
  CoreMockupDeviceEdge edge,
  CoreMockupDeviceRect rect,
});

/// The content insets a screen's hardware and system chrome reserve, in
/// screen-space logical px.
///
/// Physical sides, not reading-direction ones: a camera or a bar is fixed to
/// the device, and the device does not mirror when the text does.
typedef CoreMockupDeviceSafeArea = ({
  double top,
  double bottom,
  double left,
  double right,
});

/// Which edge of the body a hardware part lies on.
enum CoreMockupDeviceEdge {
  /// The body's left edge.
  left,

  /// The body's right edge.
  right,

  /// The body's top edge.
  top,

  /// The body's bottom edge.
  bottom;

  /// The edge this one becomes when the body turns a quarter turn
  /// clockwise — the single rule that places every button and antenna band
  /// in landscape.
  ///
  /// Stated once rather than per device so the two orientations cannot
  /// drift apart: a turned body carries its parts, it does not re-decide
  /// where they go.
  CoreMockupDeviceEdge get turned => switch (this) {
    left => top,
    top => right,
    right => bottom,
    bottom => left,
  };

  /// Whether this edge runs vertically (left / right) — a part lying on it
  /// is long in the vertical.
  bool get isVertical => this == left || this == right;
}

/// Every rectangle a `MockupDevice` paints, derived from the settled
/// style values by a single rule set (the bezel is uniform, the body
/// radius is concentric with the screen, and the camera, buttons and
/// antenna bands take their upright pose turned by the orientation).
///
/// Unscaled: the Flutter resolver multiplies by `theme.scaling` and the
/// Web resolver divides into `rem` — computing here once means the two
/// platforms cannot disagree on a derived value.
///
/// The hardware is drawn in px that do not follow the width, but the two bars
/// over the screen are the operating system's: they are authored in iOS points
/// and every length of them is multiplied by the authored [systemBarScale].
/// Resizing stretches their layout boxes, not their drawings or vertical
/// positions.
///
/// Three coordinate spaces, each rectangle in exactly one:
///
/// - **body-space** — origin at the body's top-left corner. [bezelBox],
///   [screenBox], [rimHighlight], [rimGlow], [powerButton], [volumeUpButton],
///   [volumeDownButton], [antennaBands]. A button protrudes past the body on
///   purpose, so its coordinates may be negative.
/// - **screen-space** — origin at the screen's top-left corner. [statusBar],
///   [gestureBarArea], [gestureBar], and the camera set when [cameraPlacement]
///   is [CoreMockupCameraPlacement.screen].
/// - **bezel-space** — origin at the bezel box's top-left corner
///   ([bezelBox]). The camera set when [cameraPlacement] is
///   [CoreMockupCameraPlacement.bezel].
///
/// The camera set is [camera], [lens], [core] and [lensHighlight]: they share
/// one space, so a platform places the whole assembly under one parent.
@immutable
class CoreMockupDeviceLayout {
  const CoreMockupDeviceLayout._({
    required this.deviceWidth,
    required this.deviceHeight,
    required this.inset,
    required this.bezelBox,
    required this.screenBox,
    required this.screenWidth,
    required this.screenHeight,
    required this.bezelBorderRadius,
    required this.screenBorderRadius,
    required this.rimHighlight,
    required this.rimGlow,
    required this.cameraPlacement,
    required this.cameraEdge,
    required this.camera,
    required this.lens,
    required this.core,
    required this.lensHighlight,
    required this.systemBarScale,
    required this.statusBar,
    required this.gestureBarArea,
    required this.gestureBar,
    required this.gestureBarRadius,
    required this.powerButton,
    required this.powerButtonEdge,
    required this.volumeUpButton,
    required this.volumeDownButton,
    required this.volumeButtonEdge,
    required this.antennaBands,
  });

  /// Computes the layout for one device at [width].
  ///
  /// Every argument is a *settled* style value (merge chain + default
  /// already applied by the caller) — this function owns no defaults.
  factory CoreMockupDeviceLayout.compute({
    required CoreMockupDevice device,
    required CoreMockupOrientation orientation,
    required double width,
    required double railWidth,
    required double bezelWidth,
    required CoreBorderRadius borderRadius,
    required double screenAspectWidth,
    required double screenAspectHeight,
    required CoreMockupCameraPlacement cameraPlacement,
    required double cameraWidth,
    required double cameraHeight,
    required double cameraOffset,
    required double lensSize,
    required double lensOffset,
    required double cameraCoreSize,
    required double lensHighlightSizeRatio,
    required double lensHighlightOffsetXRatio,
    required double lensHighlightOffsetYRatio,
    required double buttonThickness,
    required double buttonProtrusion,
    required double powerButtonLength,
    required double powerButtonOffset,
    required double volumeButtonLength,
    required double volumeButtonOffset,
    required double volumeButtonSpacing,
    required double landscapePowerButtonLength,
    required double landscapePowerButtonOffset,
    required double landscapeVolumeButtonLength,
    required double landscapeVolumeButtonOffset,
    required double antennaBandLength,
    required double antennaSideNearOffset,
    required double antennaSideFarOffset,
    required double antennaTopOffset,
    required double antennaBottomOffset,
    required double rimHighlightInset,
    required double rimGlowTopInset,
    required double rimGlowBottomInset,
    required double systemBarReferenceWidth,
    required double systemBarReferenceScale,
    required double landscapeSystemBarReferenceWidth,
    required double landscapeSystemBarReferenceScale,
    required double statusBarHeight,
    required double landscapeStatusBarHeight,
    required double statusBarInset,
    required double statusBarContentCenter,
    required double statusBarWingWidth,
    required double statusBarTrailingInset,
    required double statusBarTrailingSpacing,
    required double statusBarClockSpacing,
    required double statusBarLeadingSpacing,
    required double? gestureBarWidthRatio,
    required double gestureBarWidth,
    required double landscapeGestureBarWidth,
    required double gestureBarHeight,
    required double gestureBarOffset,
    required double gestureBarRadius,
    required double gestureBarAreaHeight,
    required double landscapeGestureBarAreaHeight,
  }) {
    // ─── Frame — bezel uniform, radii concentric ──────────
    // The aspect states proportions, not a direction: it is read
    // long-side-first and [orientation] alone decides which way that long
    // side runs. Stating the turn twice — once as an axis, once by the
    // order of the aspect pair — would let the two disagree, and the one
    // that placed the buttons would win silently.
    final landscape = orientation == CoreMockupOrientation.landscape;
    final longAspect = math.max(screenAspectWidth, screenAspectHeight);
    final shortAspect = math.min(screenAspectWidth, screenAspectHeight);
    final (aspectWidth, aspectHeight) = landscape
        ? (longAspect, shortAspect)
        : (shortAspect, longAspect);

    final inset = railWidth + bezelWidth;
    final screenWidth = math.max<double>(width - inset * 2, 0);
    final screenHeight = aspectWidth == 0
        ? 0.0
        : screenWidth * aspectHeight / aspectWidth;
    final deviceHeight = screenHeight + inset * 2;

    // The bezel box sits one rail in from the body edge; the screen sits one
    // bezel in from the bezel box (so one whole inset in from the body).
    final bezelBox = (
      left: railWidth,
      top: railWidth,
      width: math.max<double>(width - railWidth * 2, 0),
      height: math.max<double>(deviceHeight - railWidth * 2, 0),
    );
    final screenBox = (
      left: inset,
      top: inset,
      width: screenWidth,
      height: screenHeight,
    );

    // ─── Rim — two strokes over the body, inset top and bottom only ──
    final rimHighlight = (
      left: 0.0,
      top: rimHighlightInset,
      width: width,
      height: math.max<double>(deviceHeight - rimHighlightInset * 2, 0),
    );
    final rimGlow = (
      left: 0.0,
      top: rimGlowTopInset,
      width: width,
      height: math.max<double>(
        deviceHeight - rimGlowTopInset - rimGlowBottomInset,
        0,
      ),
    );

    // ─── Camera — the upright pose, then turned ───────────
    // A camera in the bezel strip stays on the top strip in both
    // orientations. A camera cut out of the screen rests against the screen's
    // top edge upright and, when the body turns clockwise, against its
    // leading (left) edge — the upright pose turned a quarter turn
    // counter-clockwise, so the pill stands on end and the lens, which sits
    // at the pill's right end upright, sits at its top end.
    final onScreen = cameraPlacement == CoreMockupCameraPlacement.screen;
    final cameraEdge = onScreen && landscape
        ? CoreMockupDeviceEdge.left
        : CoreMockupDeviceEdge.top;
    final standing = cameraEdge == CoreMockupDeviceEdge.left;
    final hostWidth = onScreen ? screenWidth : bezelBox.width;
    final camera = standing
        ? (
            left: cameraOffset,
            top: (screenHeight - cameraWidth) / 2,
            width: cameraHeight,
            height: cameraWidth,
          )
        : (
            left: (hostWidth - cameraWidth) / 2,
            top: cameraOffset,
            width: cameraWidth,
            height: cameraHeight,
          );
    final lens = lensSize > 0
        ? standing
              ? (
                  left: camera.left + (camera.width - lensSize) / 2,
                  top: camera.top + lensOffset,
                  width: lensSize,
                  height: lensSize,
                )
              : (
                  left: camera.left + camera.width - lensOffset - lensSize,
                  top: camera.top + (camera.height - lensSize) / 2,
                  width: lensSize,
                  height: lensSize,
                )
        : null;
    final coreHost = lens ?? camera;
    final core = (
      left: coreHost.left + (coreHost.width - cameraCoreSize) / 2,
      top: coreHost.top + (coreHost.height - cameraCoreSize) / 2,
      width: cameraCoreSize,
      height: cameraCoreSize,
    );
    // The glint sits up and to the left of the core whichever way the pill
    // turns, so its offsets are not rotated with the camera.
    final lensHighlight = (
      left: core.left + cameraCoreSize * lensHighlightOffsetXRatio,
      top: core.top + cameraCoreSize * lensHighlightOffsetYRatio,
      width: cameraCoreSize * lensHighlightSizeRatio,
      height: cameraCoreSize * lensHighlightSizeRatio,
    );

    // ─── System bars — iOS points at the authored scale ──
    // Resizing stretches the screen and the status bar background, while
    // its edge-anchored wings, height, glyphs, text and home indicator retain
    // their dimensions. Resolve the reference scale for this pose rather
    // than deriving a new scale from the caller's width.
    final referenceWidth = landscape
        ? landscapeSystemBarReferenceWidth
        : systemBarReferenceWidth;
    final referenceScale = landscape
        ? landscapeSystemBarReferenceScale
        : systemBarReferenceScale;
    final systemBarScale = referenceWidth > 0
        ? math.max<double>(referenceScale, 0)
        : 0.0;

    // A device that draws no status bar in this pose states a height of `0`.
    final barHeightPoints = landscape
        ? landscapeStatusBarHeight
        : statusBarHeight;
    final statusBar = barHeightPoints > 0
        ? CoreMockupStatusBarLayout.compute(
            device: device,
            screenWidth: screenWidth,
            scale: systemBarScale,
            height: barHeightPoints,
            inset: statusBarInset,
            contentCenter: statusBarContentCenter,
            wingWidth: statusBarWingWidth,
            trailingInset: statusBarTrailingInset,
            trailingSpacing: statusBarTrailingSpacing,
            clockSpacing: statusBarClockSpacing,
            leadingSpacing: statusBarLeadingSpacing,
          )
        : null;

    // The gesture bar sits `gestureBarOffset` above the bottom edge, centred,
    // inside an area along the bottom whose height is the device's own
    // bottom safe-area inset. A stated width ratio pins the bar to that
    // fraction of the screen instead of its authored length.
    final gestureBarPoints = landscape
        ? landscapeGestureBarWidth
        : gestureBarWidth;
    final gestureBarWidthPx = gestureBarWidthRatio != null
        ? screenWidth * gestureBarWidthRatio
        : gestureBarPoints * systemBarScale;
    final gestureBarHeightPx = gestureBarHeight * systemBarScale;
    final gestureBarGap = gestureBarOffset * systemBarScale;
    final gestureBar = (
      left: (screenWidth - gestureBarWidthPx) / 2,
      top: screenHeight - gestureBarGap - gestureBarHeightPx,
      width: gestureBarWidthPx,
      height: gestureBarHeightPx,
    );
    final gestureBarAreaPoints = landscape
        ? landscapeGestureBarAreaHeight
        : gestureBarAreaHeight;
    final gestureBarAreaPx = gestureBarAreaPoints * systemBarScale;
    final gestureBarArea = (
      left: 0.0,
      top: screenHeight - gestureBarAreaPx,
      width: screenWidth,
      height: gestureBarAreaPx,
    );

    // ─── Buttons — the upright pose, then turned ──────────
    // Each device states where its buttons sit when held upright, and the
    // landscape pose is that pose turned a quarter turn clockwise — never
    // a second table. The canvas already draws that rule (a tablet's
    // volume moves left → top and its power top → right), so deriving it
    // keeps the two poses from drifting and gives a turned phone its
    // buttons without anyone authoring a third row. How long a button is and
    // how far along its edge it sits are authored per orientation, because
    // the canvas measures them afresh after the turn.
    final (portraitVolumeEdge, portraitPowerEdge) = switch (device) {
      .phone => (CoreMockupDeviceEdge.left, CoreMockupDeviceEdge.right),
      .tablet => (CoreMockupDeviceEdge.left, CoreMockupDeviceEdge.top),
    };
    final volumeEdge = landscape
        ? portraitVolumeEdge.turned
        : portraitVolumeEdge;
    final powerEdge = landscape ? portraitPowerEdge.turned : portraitPowerEdge;
    CoreMockupDeviceRect onEdge(
      CoreMockupDeviceEdge edge,
      double fraction,
      double length, {
      required bool fromRightEnd,
    }) => switch (edge) {
      .left => (
        left: -buttonProtrusion,
        top: deviceHeight * fraction,
        width: buttonThickness,
        height: length,
      ),
      .right => (
        left: width - (buttonThickness - buttonProtrusion),
        top: deviceHeight * fraction,
        width: buttonThickness,
        height: length,
      ),
      .top => (
        left: fromRightEnd
            ? width - width * fraction - length
            : width * fraction,
        top: -buttonProtrusion,
        width: length,
        height: buttonThickness,
      ),
      .bottom => (
        left: fromRightEnd
            ? width - width * fraction - length
            : width * fraction,
        top: deviceHeight - (buttonThickness - buttonProtrusion),
        width: length,
        height: buttonThickness,
      ),
    };
    // Power hugs the top-right corner: measured from the top on a
    // vertical edge, from the right end on the top edge. Volume hugs the
    // top-left corner: from the top, or from the left end.
    final powerLength = landscape
        ? landscapePowerButtonLength
        : powerButtonLength;
    final powerOffset = landscape
        ? landscapePowerButtonOffset
        : powerButtonOffset;
    final volumeLength = landscape
        ? landscapeVolumeButtonLength
        : volumeButtonLength;
    final volumeOffset = landscape
        ? landscapeVolumeButtonOffset
        : volumeButtonOffset;
    final powerButton = onEdge(
      powerEdge,
      powerOffset,
      powerLength,
      fromRightEnd: true,
    );
    final volumeUpButton = onEdge(
      volumeEdge,
      volumeOffset,
      volumeLength,
      fromRightEnd: false,
    );
    // A second volume button only when the style states a gap between
    // the two — `0` is how a device says "one rocker".
    final volumeDownButton = volumeLength > 0 && volumeButtonSpacing > 0
        ? switch (volumeEdge) {
            .top || .bottom => (
              left: volumeUpButton.left + volumeLength + volumeButtonSpacing,
              top: volumeUpButton.top,
              width: volumeUpButton.width,
              height: volumeUpButton.height,
            ),
            .left || .right => (
              left: volumeUpButton.left,
              top: volumeUpButton.top + volumeLength + volumeButtonSpacing,
              width: volumeUpButton.width,
              height: volumeUpButton.height,
            ),
          }
        : null;

    // ─── Antenna bands — the upright set, carried one edge clockwise ──
    // Each band is stated by its edge, which end of that edge it is measured
    // from, and how far from that end. The turned set keeps the end and the
    // distance and only moves the edge (left → top → right → bottom →
    // left): the canvas draws it that way, which is a rotation of the edges
    // but not of the distances. A band is as thick as the rail, so it spans
    // exactly the band of body outside the bezel.
    CoreMockupDeviceAntennaBand band(
      CoreMockupDeviceEdge portraitEdge, {
      required bool fromFarEnd,
      required double distance,
    }) {
      final edge = landscape ? portraitEdge.turned : portraitEdge;
      final along = edge.isVertical ? deviceHeight : width;
      final start = fromFarEnd
          ? along - distance - antennaBandLength
          : distance;
      final rect = switch (edge) {
        .left => (
          left: 0.0,
          top: start,
          width: railWidth,
          height: antennaBandLength,
        ),
        .right => (
          left: width - railWidth,
          top: start,
          width: railWidth,
          height: antennaBandLength,
        ),
        .top => (
          left: start,
          top: 0.0,
          width: antennaBandLength,
          height: railWidth,
        ),
        .bottom => (
          left: start,
          top: deviceHeight - railWidth,
          width: antennaBandLength,
          height: railWidth,
        ),
      };
      return (edge: edge, rect: rect);
    }

    // `0` is how a device says "no antenna bands".
    final antennaBands = antennaBandLength > 0
        ? <CoreMockupDeviceAntennaBand>[
            band(
              CoreMockupDeviceEdge.top,
              fromFarEnd: true,
              distance: antennaTopOffset,
            ),
            band(
              CoreMockupDeviceEdge.left,
              fromFarEnd: false,
              distance: antennaSideNearOffset,
            ),
            band(
              CoreMockupDeviceEdge.right,
              fromFarEnd: false,
              distance: antennaSideNearOffset,
            ),
            band(
              CoreMockupDeviceEdge.left,
              fromFarEnd: true,
              distance: antennaSideFarOffset,
            ),
            band(
              CoreMockupDeviceEdge.right,
              fromFarEnd: true,
              distance: antennaSideFarOffset,
            ),
            band(
              CoreMockupDeviceEdge.bottom,
              fromFarEnd: false,
              distance: antennaBottomOffset,
            ),
          ]
        : const <CoreMockupDeviceAntennaBand>[];

    return CoreMockupDeviceLayout._(
      deviceWidth: width,
      deviceHeight: deviceHeight,
      inset: inset,
      bezelBox: bezelBox,
      screenBox: screenBox,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      bezelBorderRadius: deflateBorderRadius(borderRadius, railWidth),
      screenBorderRadius: deflateBorderRadius(borderRadius, inset),
      rimHighlight: rimHighlight,
      rimGlow: rimGlow,
      cameraPlacement: cameraPlacement,
      cameraEdge: cameraEdge,
      camera: camera,
      lens: lens,
      core: core,
      lensHighlight: lensHighlight,
      systemBarScale: systemBarScale,
      statusBar: statusBar,
      gestureBarArea: gestureBarArea,
      gestureBar: gestureBar,
      gestureBarRadius: gestureBarRadius * systemBarScale,
      powerButton: powerButton,
      powerButtonEdge: powerEdge,
      volumeUpButton: volumeUpButton,
      volumeDownButton: volumeDownButton,
      volumeButtonEdge: volumeEdge,
      antennaBands: antennaBands,
    );
  }

  /// Body width — the `width` the caller supplied.
  final double deviceWidth;

  /// Body height — screen height plus the uniform inset on both sides.
  final double deviceHeight;

  /// Rail + bezel: the uniform distance from the body edge to the screen.
  final double inset;

  /// The bezel box (body-space) — one rail in from the body edge on every
  /// side. The bezel's fill, outline and inner shadow belong to it, and a
  /// camera set in the bezel strip is placed in its coordinate space.
  final CoreMockupDeviceRect bezelBox;

  /// The screen box (body-space) — one whole [inset] in from the body edge.
  /// Inside the bezel it sits at `(bezelWidth, bezelWidth)`.
  final CoreMockupDeviceRect screenBox;

  /// Screen width — body width minus twice [inset].
  final double screenWidth;

  /// Screen height — [screenWidth] through the aspect ratio.
  final double screenHeight;

  /// Body radius minus the rail — the bezel box's corners.
  final CoreBorderRadius bezelBorderRadius;

  /// Body radius minus [inset] — the screen's corners (concentric).
  final CoreBorderRadius screenBorderRadius;

  /// The rim highlight's box (body-space) — the body's width, inset from the
  /// top and bottom edges only. Its corners are the body's own radius, not
  /// deflated.
  final CoreMockupDeviceRect rimHighlight;

  /// The rim glow's box (body-space) — see [rimHighlight]; its top and bottom
  /// insets are stated apart.
  final CoreMockupDeviceRect rimGlow;

  /// Which space the camera set ([camera] / [lens] / [core] /
  /// [lensHighlight]) is in: screen-space or bezel-space.
  final CoreMockupCameraPlacement cameraPlacement;

  /// The edge of its space the camera rests against: [CoreMockupDeviceEdge.top]
  /// for a camera in the bezel strip and for an upright camera cut out of the
  /// screen, [CoreMockupDeviceEdge.left] for a turned one (it stands on end
  /// against the screen's leading edge).
  final CoreMockupDeviceEdge cameraEdge;

  /// Camera cut-out (in the [cameraPlacement] space).
  final CoreMockupDeviceRect camera;

  /// Lens ring inside the cut-out (in the [cameraPlacement] space); `null`
  /// when the device states no lens ring (its cut-out is the lens).
  final CoreMockupDeviceRect? lens;

  /// Lens core dot (in the [cameraPlacement] space) — centred in [lens] when
  /// present, otherwise in [camera].
  final CoreMockupDeviceRect core;

  /// The glint on [core] (in the [cameraPlacement] space) — a circle whose
  /// box is the rectangle given.
  final CoreMockupDeviceRect lensHighlight;

  /// Whether the camera cut-out is itself the lens — true when the device
  /// draws no lens ring inside it.
  ///
  /// Decides the cut-out's fill, the one colour whose owner depends on the
  /// device's shape: a cut-out that holds a ring is a hole in the screen
  /// and takes the cut-out fill (the ring takes the lens fill); a cut-out
  /// with no ring is the lens and takes the lens fill. Derived from the
  /// geometry rather than the device name so an override that adds or
  /// removes the ring repaints consistently — and so both platform resolvers
  /// and the Figma builder read one answer.
  bool get cameraIsLens => lens == null;

  /// Logical px per iOS point — the factor the status bar and the gesture bar
  /// are drawn at, authored per pose and independent of the widget width.
  /// `0` when the style states no reference width or a non-positive scale.
  final double systemBarScale;

  /// The status bar over the top of the screen, or `null` when the device
  /// draws none in this pose (a phone turned on its side). Screen-space.
  ///
  /// It is drawn over the child, behind the camera set: the bar's background
  /// is the screen's own fill, painted so the child's overflow cannot show
  /// through it, and a camera cut out of the screen stands on top of it.
  final CoreMockupStatusBarLayout? statusBar;

  /// The area along the bottom of the screen the gesture bar lives in
  /// (screen-space) — full width, as tall as the device's bottom safe-area
  /// inset. Nothing is painted for it: the screen's own fill shows through.
  final CoreMockupDeviceRect gestureBarArea;

  /// Home gesture bar (screen-space) — a bar `gestureBarOffset` above the
  /// bottom edge, centred in [gestureBarArea]'s width.
  final CoreMockupDeviceRect gestureBar;

  /// Home gesture bar corner radius (logical px).
  final double gestureBarRadius;

  /// Power button (body-space; protrudes past the body). A device with none
  /// states a zero length: the rectangle is then empty and [hasPowerButton]
  /// is `false`.
  final CoreMockupDeviceRect powerButton;

  /// The body edge [powerButton] protrudes from.
  final CoreMockupDeviceEdge powerButtonEdge;

  /// Volume up — or the single rocker (body-space). A device with no volume
  /// button states a zero length: the rectangle is then empty and
  /// [hasVolumeButton] is `false`.
  final CoreMockupDeviceRect volumeUpButton;

  /// Volume down (body-space); `null` when the device has one rocker or no
  /// volume button.
  final CoreMockupDeviceRect? volumeDownButton;

  /// The body edge [volumeUpButton] and [volumeDownButton] protrude from.
  final CoreMockupDeviceEdge volumeButtonEdge;

  /// Whether the device has a power button — its length is not zero.
  /// Platforms draw no part for a device that has none, rather than a
  /// zero-sized one.
  bool get hasPowerButton => powerButton.width > 0 && powerButton.height > 0;

  /// Whether the device has a volume button — its length is not zero. See
  /// [hasPowerButton].
  bool get hasVolumeButton =>
      volumeUpButton.width > 0 && volumeUpButton.height > 0;

  /// Antenna bands (body-space), each with the edge it lies on; empty when
  /// the device draws none. The bands do not overlap, so their order carries
  /// no stacking meaning.
  final List<CoreMockupDeviceAntennaBand> antennaBands;

  /// Content insets around everything visible over the screen, in
  /// screen-space logical px.
  ///
  /// Each of the camera, the status bar and the gesture bar reserves its own
  /// edge and releases it when hidden; none is derived from another's flag.
  ///
  /// - **top** — the status bar's whole height, or, when the camera is cut out
  ///   of the screen against its top edge, the camera's reach plus the same
  ///   gap on its content side — whichever is deeper, so an oversized override
  ///   of either cannot intrude into the child. A camera in the bezel strip
  ///   reserves nothing.
  /// - **left** — a camera turned onto the screen's leading edge: its reach
  ///   plus the same gap on its content side.
  /// - **bottom** — the gesture bar's area, or the bar's own footprint from
  ///   the bottom edge if an override makes it reach higher.
  /// - **right** — nothing is fixed to the right edge today; the side is here
  ///   so a platform maps the whole record to its edge-insets type without
  ///   caring which side a part stands on.
  ///
  /// Clamped to the screen so a tiny mockup still has a non-negative
  /// viewport.
  CoreMockupDeviceSafeArea safeAreaInsets({
    required bool showCamera,
    required bool showStatusBar,
    required bool showGestureBar,
  }) {
    // The camera's far reach in each direction: an oversized lens or core
    // contributes, so style overrides cannot intrude into the child.
    final cameraBottom = math.max(
      math.max(camera.top + camera.height, core.top + core.height),
      lens == null ? 0.0 : lens!.top + lens!.height,
    );
    final cameraRight = math.max(
      math.max(camera.left + camera.width, core.left + core.width),
      lens == null ? 0.0 : lens!.left + lens!.width,
    );
    final cameraOnScreen =
        showCamera && cameraPlacement == CoreMockupCameraPlacement.screen;
    final cameraTop = cameraOnScreen && cameraEdge == CoreMockupDeviceEdge.top
        ? cameraBottom + camera.top
        : 0.0;
    final cameraLeft = cameraOnScreen && cameraEdge == CoreMockupDeviceEdge.left
        ? cameraRight + camera.left
        : 0.0;
    final statusTop = showStatusBar && statusBar != null
        ? statusBar!.rect.height
        : 0.0;
    final top = math.max(cameraTop, statusTop).clamp(0.0, screenHeight);
    final bottom = showGestureBar
        ? math
              .max(gestureBarArea.height, screenHeight - gestureBar.top)
              .clamp(0.0, screenHeight - top)
        : 0.0;
    final left = cameraLeft.clamp(0.0, screenWidth);
    return (top: top, bottom: bottom, left: left, right: 0.0);
  }

  /// The gloss along a hardware button's length, pointed along the button on
  /// [edge]: top to bottom for a button on a vertical edge, left to right for
  /// one on a horizontal edge. Colours and stops are [authored]'s; its own
  /// `begin` / `end` are not read.
  static CoreGradient buttonLengthGradient(
    CoreGradient authored,
    CoreMockupDeviceEdge edge,
  ) => CoreGradient(
    type: authored.type,
    colors: authored.colors,
    stops: authored.stops,
    begin: edge.isVertical
        ? CoreAlignment.topCenter
        : CoreAlignment.centerStart,
    end: edge.isVertical ? CoreAlignment.bottomCenter : CoreAlignment.centerEnd,
  );

  /// The shade across a hardware button's thickness on [edge]: [depthColor]
  /// at the side nearest the body, clear at the far side.
  static CoreGradient buttonDepthGradient(
    CoreColor depthColor,
    CoreMockupDeviceEdge edge,
  ) {
    // The body lies on the opposite side of the button from the edge's name:
    // a button on the left edge has the body to its right.
    final (begin, end) = switch (edge) {
      .left => (CoreAlignment.centerEnd, CoreAlignment.centerStart),
      .right => (CoreAlignment.centerStart, CoreAlignment.centerEnd),
      .top => (CoreAlignment.bottomCenter, CoreAlignment.topCenter),
      .bottom => (CoreAlignment.topCenter, CoreAlignment.bottomCenter),
    };
    return CoreGradient(
      type: CoreGradientType.linear,
      colors: [depthColor, CoreColor.transparent],
      stops: const [0, 1],
      begin: begin,
      end: end,
    );
  }

  /// Every corner of [radius] reduced by [amount], clamped at zero — the
  /// concentric-inset rule a rounded box inside a rounded box follows.
  static CoreBorderRadius deflateBorderRadius(
    CoreBorderRadius radius,
    double amount,
  ) => .only(
    topLeft: math.max(radius.topLeft - amount, 0),
    topRight: math.max(radius.topRight - amount, 0),
    bottomLeft: math.max(radius.bottomLeft - amount, 0),
    bottomRight: math.max(radius.bottomRight - amount, 0),
  );
}
