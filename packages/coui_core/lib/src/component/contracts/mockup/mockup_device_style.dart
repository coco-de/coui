/// Per-instance style for `MockupDevice`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/alignment.dart';
import 'package:coui_core/src/component/contracts/frame/core_gradient.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_camera_placement.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_device.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_device_finish.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_status_bar_glyphs.dart';
import 'package:coui_core/src/component/contracts/outlined_container/outlined_container_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/shape/vector_glyph.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `MockupDevice` should render.
///
/// The device is drawn by one rule set rather than a bag of numbers: a
/// uniform bezel (`railWidth` + `bezelWidth`) around the screen, a body
/// radius concentric with the screen radius, and a camera / buttons /
/// antenna bands placed by which side is the long one. The values that
/// differ per device kind live in [defaultsByDevice]; everything else is a
/// plain `default*`.
///
/// Hardware colours ([railColor] / [borderColor] / [rimHighlightColor] /
/// [bezelColor] / [bezelBorderColor] / [buttonColor] / [lensColor] /
/// [cutoutColor] / [lensHighlightColor] and the body, antenna and lens core
/// gradients) are the designer copy's own values, written as literal
/// colours. A real device does not change colour when the UI switches to
/// dark mode, and it is not made of the app's palette, so these are
/// **mode-invariant and palette-independent**: no scheme mode and no brand
/// palette tints the device. The button gloss, the rim glow, the bezel's
/// inner shadow, the button depth and the body's drop shadow are white or
/// black at partial alpha laid over whatever lies beneath — optics rather
/// than a surface colour — and are literals for the same reason. Only the
/// screen, the status bar and the gesture bar follow the active scheme.
///
/// The status bar and the gesture bar are not hardware: they are the
/// operating system's own chrome, drawn at the size an iPhone or iPad draws
/// them (**iOS points**) at the fixed scale authored by the design — every
/// `statusBar*` and `gestureBar*` length is in points, and
/// `CoreMockupDeviceLayout.systemBarScale` turns points into logical px. The
/// hardware lengths above stay in unscaled logical px.
///
/// ```text
/// CoreMockupDeviceStyle.defaultX / defaultsByDevice[device]
///   → defaultsByFinish[finish]                          // 마감 (flat 만 값을 가짐)
///   → CoreMockupTheme.style (shared cross-variant fallback)
///   → CoreMockupDeviceTheme.style                       // 프로젝트 공통
///   → CoreMockupDeviceTheme.deviceStyles[device]
///   → CoreMockupDeviceTheme.finishStyles[finish]
///   → widget.mockupDeviceStyle                          // 인스턴스별
/// ```
///
/// The finish row sits above the per-device row and below every theme and
/// instance layer: it restates what a device-picture drawing is made of
/// (rail, buttons, rim light, shadow …) for a frame that is not one, and a
/// project or an instance can still restate any of it.
@immutable
class CoreMockupDeviceStyle implements CoreStyle<CoreMockupDeviceStyle> {
  /// Creates a [CoreMockupDeviceStyle].
  const CoreMockupDeviceStyle({
    this.backgroundColor,
    this.railColor,
    this.railGradient,
    this.borderColor,
    this.borderWidth,
    this.rimHighlightColor,
    this.rimHighlightWidth,
    this.rimHighlightInset,
    this.rimGlowGradient,
    this.rimGlowOpacity,
    this.rimGlowWidth,
    this.rimGlowTopInset,
    this.rimGlowBottomInset,
    this.rimGlowBlur,
    this.bezelColor,
    this.bezelBorderColor,
    this.bezelBorderWidth,
    this.bezelInnerShadowColor,
    this.bezelInnerShadowBlur,
    this.bezelInnerShadowSpread,
    this.buttonColor,
    this.buttonLengthGradient,
    this.buttonDepthColor,
    this.lensColor,
    this.cutoutColor,
    this.coreGradient,
    this.lensHighlightColor,
    this.gestureBarColor,
    this.statusBarIconColor,
    this.statusBarBatteryBorderColor,
    this.statusBarBatteryCapColor,
    this.statusBarTextStyle,
    this.borderRadius,
    this.railWidth,
    this.bezelWidth,
    this.cameraPlacement,
    this.cameraWidth,
    this.cameraHeight,
    this.cameraOffset,
    this.lensSize,
    this.lensOffset,
    this.cameraCoreSize,
    this.lensHighlightSizeRatio,
    this.lensHighlightOffsetXRatio,
    this.lensHighlightOffsetYRatio,
    this.buttonThickness,
    this.buttonProtrusion,
    this.powerButtonLength,
    this.powerButtonOffset,
    this.volumeButtonLength,
    this.volumeButtonOffset,
    this.volumeButtonSpacing,
    this.landscapePowerButtonLength,
    this.landscapePowerButtonOffset,
    this.landscapeVolumeButtonLength,
    this.landscapeVolumeButtonOffset,
    this.antennaGradient,
    this.antennaOpacity,
    this.antennaBandLength,
    this.antennaSideNearOffset,
    this.antennaSideFarOffset,
    this.antennaTopOffset,
    this.antennaBottomOffset,
    this.systemBarReferenceWidth,
    this.systemBarReferenceScale,
    this.landscapeSystemBarReferenceWidth,
    this.landscapeSystemBarReferenceScale,
    this.statusBarHeight,
    this.landscapeStatusBarHeight,
    this.statusBarInset,
    this.statusBarContentCenter,
    this.statusBarWingWidth,
    this.statusBarTrailingInset,
    this.statusBarTrailingSpacing,
    this.statusBarClockSpacing,
    this.statusBarLeadingSpacing,
    @Deprecated(
      'State gestureBarWidth (and landscapeGestureBarWidth) instead (since '
      '0.154) — the bar is an iOS length at the authored reference scale, '
      'not a fraction of its width.',
    )
    this.gestureBarWidthRatio,
    this.gestureBarWidth,
    this.landscapeGestureBarWidth,
    this.gestureBarHeight,
    this.gestureBarOffset,
    this.gestureBarRadius,
    this.gestureBarAreaHeight,
    this.landscapeGestureBarAreaHeight,
    this.screenAspectWidth,
    this.screenAspectHeight,
    this.containerStyle,
  });

  // ─── Design-system defaults (device-independent) ──────
  // Flutter and Web resolvers read these directly so both platforms share
  // a single source of truth.

  /// Default screen fill — follows the active scheme (`surface`).
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default solid body fill — the colour the body gradient rests on between
  /// its lit ends, the designer copy's middle stop.
  ///
  /// Only painted when the body is a solid: a caller (or the shared mockup
  /// theme's `frameColor`) that states it gets this solid body instead of
  /// [defaultRailGradient] — see [resolveBodyGradient].
  static const CoreColor defaultRailColor = CoreColor(0xFF7D7F82);

  /// Default body fill — a top-to-bottom gradient, the same in both
  /// orientations: lit at the top edge, resting through the middle, a
  /// softer light at the bottom edge. The designer copy's stops.
  static const CoreGradient defaultRailGradient = CoreGradient(
    type: CoreGradientType.linear,
    colors: [
      CoreColor(0xFFC3C4C6),
      CoreColor(0xFF7D7F82),
      CoreColor(0xFF7D7F82),
      CoreColor(0xFFAEAFB2),
    ],
    stops: [0, 0.1, 0.9, 1],
    begin: CoreAlignment.topCenter,
    end: CoreAlignment.bottomCenter,
  );

  /// Default rim stroke colour, drawn inside the body's outer edge — the
  /// designer copy's value, a darker grey than the body's middle.
  static const CoreColor defaultBorderColor = CoreColor(0xFF646568);

  /// Default rim stroke width (logical px).
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default rim highlight stroke colour — the lit hairline just inside the
  /// rim. White at full strength, the designer copy's value.
  static const CoreColor defaultRimHighlightColor = CoreColor(0xFFFFFFFF);

  /// Default rim highlight stroke width (logical px), drawn inside the box.
  /// Device geometry, off the stroke ladder.
  static const double defaultRimHighlightWidth = 0.5;

  /// Default rim highlight inset from the body's top and bottom edges
  /// (logical px). The left and right edges are not inset.
  static const double defaultRimHighlightInset = 0.4;

  /// Default rim glow stroke — white fading to clear by the middle of the
  /// body, top to bottom in both orientations. A literal, not a slot: white
  /// fading to clear is an optical effect, and it reads the same in every
  /// mode.
  static const CoreGradient defaultRimGlowGradient = CoreGradient(
    type: CoreGradientType.linear,
    colors: [CoreColor(0xFFFFFFFF), CoreColor(0x00FFFFFF)],
    stops: [0, 0.51],
    begin: CoreAlignment.topCenter,
    end: CoreAlignment.bottomCenter,
  );

  /// Default rim glow opacity — a paint opacity over the whole stroke, not
  /// folded into the gradient's stops.
  static const double defaultRimGlowOpacity = CoreOpacity.opacity50;

  /// Default rim glow stroke width (logical px), drawn inside the box.
  /// Device geometry, off the stroke ladder.
  static const double defaultRimGlowWidth = 0.6;

  /// Default rim glow inset from the body's top edge (logical px). The left
  /// and right edges are not inset.
  static const double defaultRimGlowTopInset = 0.8;

  /// Default rim glow inset from the body's bottom edge (logical px) — the
  /// same as the rim highlight's, so the two strokes end together.
  static const double defaultRimGlowBottomInset = 0.4;

  /// Default rim glow blur radius (logical px) — a layer blur over the
  /// glow stroke alone.
  static const double defaultRimGlowBlur = 0.8;

  /// Default inner bezel fill — black, the designer copy's value.
  static const CoreColor defaultBezelColor = CoreColor(0xFF000000);

  /// Default bezel outline colour — drawn outside the bezel box, on the rail.
  /// The designer copy's value.
  static const CoreColor defaultBezelBorderColor = CoreColor(0xFF27282B);

  /// Default bezel outline width (logical px), drawn outside the bezel box.
  /// Device geometry, off the stroke ladder.
  static const double defaultBezelBorderWidth = 0.5;

  /// Default bezel inner-shadow colour — a faint light edge along the
  /// bezel's inside, the glass meeting the frame. A literal, not a slot:
  /// white at 16% laid over the glass is an optical effect, and it reads the
  /// same in every mode.
  static const CoreColor defaultBezelInnerShadowColor = CoreColor(0x29FFFFFF);

  /// Default bezel inner-shadow blur radius (logical px). The shadow has no
  /// offset.
  static const double defaultBezelInnerShadowBlur = 0.5;

  /// Default bezel inner-shadow spread (logical px).
  static const double defaultBezelInnerShadowSpread = 0.3;

  /// Default hardware button base fill — the solid under the two gloss
  /// layers. The designer copy's value — its own colour, lighter than the
  /// body's middle rather than following [defaultRailColor].
  static const CoreColor defaultButtonColor = CoreColor(0xFFAEAFB2);

  /// Default hardware button gloss along its length — bright and dark bands
  /// at both ends, clear between. Authored for an upright (vertical) button,
  /// top to bottom; the layout points it along a horizontal button's length
  /// (`CoreMockupDeviceLayout.buttonLengthGradient`). A literal, not a slot:
  /// white and black at partial alpha laid over [defaultButtonColor] are an
  /// optical effect, and they read the same in every mode.
  static const CoreGradient defaultButtonLengthGradient = CoreGradient(
    type: CoreGradientType.linear,
    colors: [
      CoreColor(0x00FFFFFF),
      CoreColor(0xADFFFFFF),
      CoreColor(0x80000000),
      CoreColor(0x00FFFFFF),
      CoreColor(0x00FFFFFF),
      CoreColor(0x80000000),
      CoreColor(0x7AFFFFFF),
      CoreColor(0x00FFFFFF),
    ],
    stops: [0, 0.05, 0.09, 0.15, 0.85, 0.91, 0.95, 1],
    begin: CoreAlignment.topCenter,
    end: CoreAlignment.bottomCenter,
  );

  /// Default hardware button shade across its thickness — this dark at the
  /// edge nearest the body, clear at the far edge
  /// (`CoreMockupDeviceLayout.buttonDepthGradient`). A literal, not a slot:
  /// black at 35% laid over the button is an optical effect, and it reads the
  /// same in every mode.
  static const CoreColor defaultButtonDepthColor = CoreColor(0x59000000);

  /// Default lens ring fill — also the camera cut-out's fill when the cut-out
  /// is itself the lens. Black, the designer copy's value.
  static const CoreColor defaultLensColor = CoreColor(0xFF000000);

  /// Default camera cut-out fill when it holds a lens ring. Black, the
  /// designer copy's value.
  static const CoreColor defaultCutoutColor = CoreColor(0xFF000000);

  /// Default lens core fill — a radial gradient from the centre of its box:
  /// black at the middle, a blue glass sheen around it, black again at the
  /// rim, the designer copy's stops. The radius reaches the edge of the box
  /// (half its side).
  static const CoreGradient defaultCoreGradient = CoreGradient(
    type: CoreGradientType.radial,
    colors: [
      CoreColor(0xFF000000),
      CoreColor(0xFF0A3348),
      CoreColor(0xFF0C3B52),
      CoreColor(0xFF105171),
      CoreColor(0xFF0C3B52),
      CoreColor(0xFF000000),
    ],
    stops: [0.2, 0.35, 0.5, 0.62, 0.8, 1],
    begin: CoreAlignment.center,
  );

  /// Default lens highlight fill — the glint on the core. White at full
  /// strength, the designer copy's value.
  static const CoreColor defaultLensHighlightColor = CoreColor(0xFFFFFFFF);

  /// Default lens highlight diameter as a fraction of the core's diameter.
  /// The same proportion on every device, so it is stated once.
  static const double defaultLensHighlightSizeRatio = 0.26666666666666666;

  /// Default lens highlight distance from the core's left edge as a fraction
  /// of the core's diameter — the same in both orientations, because the
  /// glint sits up and to the left of the core whichever way the pill turns.
  static const double defaultLensHighlightOffsetXRatio = 0.13333333333333333;

  /// Default lens highlight distance from the core's top edge as a fraction
  /// of the core's diameter — see [defaultLensHighlightOffsetXRatio].
  static const double defaultLensHighlightOffsetYRatio = 0.06666666666666667;

  /// Default home gesture bar colour — `on-surface`, opaque: the bar is as
  /// strong as the clock above it, the way the operating system draws it.
  static const CoreColor defaultGestureBarColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default status bar glyph fill — the signal and wifi glyphs, the phone
  /// battery's level and the tablet battery. `on-surface`, so it flips with
  /// the scheme together with the clock.
  static const CoreColor defaultStatusBarIconColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default fill of the phone battery's outline — `on-surface` at 35%, a
  /// faint frame around the level. Off the opacity ladder (it has 30 and 40).
  static const CoreColor defaultStatusBarBatteryBorderColor = CoreColor.token(
    CoreColors.onSurface,
    opacity: 0.35,
  );

  /// Default fill of the phone battery's nub — `on-surface` at 40%.
  static const CoreColor defaultStatusBarBatteryCapColor = CoreColor.token(
    CoreColors.onSurface,
    opacity: CoreOpacity.opacity40,
  );

  /// Default rail band width — the body ring outside the bezel (the rim
  /// stroke is drawn inside this band). Device geometry, off the ladders.
  static const double defaultRailWidth = 3;

  /// Default bezel width.
  ///
  /// Unused: the bezel is a per-device fact, so each device states it in
  /// [defaultsByDevice].
  @Deprecated(
    'Per-device now: read defaultsByDevice[device].bezelWidth instead '
    '(since 0.154) — a phone and a tablet no longer share one bezel.',
  )
  static const double defaultBezelWidth = CoreSpace.space6;

  /// Default lens-core dot diameter (logical px).
  ///
  /// Unused: the core is sized per device, so each device states it in
  /// [defaultsByDevice].
  @Deprecated(
    'Per-device now: read defaultsByDevice[device].cameraCoreSize instead '
    '(since 0.154) — the phone and tablet cores are different sizes.',
  )
  static const double defaultCameraCoreSize = 3;

  /// Default hardware button thickness — how far the slab reaches
  /// across the body edge (logical px).
  static const double defaultButtonThickness = CoreStrokeWidth.stroke2;

  /// Default hardware button protrusion — how much of the thickness
  /// sits outside the body (logical px). The rest tucks behind it. Device
  /// geometry, off the ladders.
  static const double defaultButtonProtrusion = 1.5;

  /// Default antenna band fill — a pale gradient top to bottom, whichever
  /// way the band lies. The designer copy's stops.
  static const CoreGradient defaultAntennaGradient = CoreGradient(
    type: CoreGradientType.linear,
    colors: [CoreColor(0xFFFCFCFD), CoreColor(0xFFE4E5E7)],
    stops: [0, 1],
    begin: CoreAlignment.topCenter,
    end: CoreAlignment.bottomCenter,
  );

  /// Default antenna band opacity — a paint opacity over the band, not
  /// folded into the gradient's stops. Device geometry, off the opacity
  /// ladder.
  static const double defaultAntennaOpacity = 0.7;

  /// Default distance of an upright body's two side-band pairs from the
  /// *near* (top) end of the sides (logical px). Device geometry.
  static const double defaultAntennaSideNearOffset = 35.782;

  /// Default distance of an upright body's two side-band pairs from the *far*
  /// (bottom) end of the sides (logical px). Device geometry; not the near
  /// offset restated — the bands are not mirrored top to bottom.
  static const double defaultAntennaSideFarOffset = 35.745;

  /// Default distance of an upright body's top band from the *far* (right)
  /// end of the top edge (logical px). Device geometry.
  static const double defaultAntennaTopOffset = 35.659;

  /// Default distance of an upright body's bottom band from the *near* (left)
  /// end of the bottom edge (logical px). Device geometry.
  static const double defaultAntennaBottomOffset = 31.549;

  /// Default status bar gap between the clock and its meridiem (iOS points) —
  /// the two words of "9:41 오전" sit this far apart on the tablet.
  static const double defaultStatusBarClockSpacing = CoreSpace.space2;

  /// Default status bar gap between the clock group and the date (iOS points)
  /// — the tablet's leading group reads "9:41 오전  4월 1일 수요일".
  static const double defaultStatusBarLeadingSpacing = CoreSpace.space8;

  /// Default home gesture bar width as a fraction of the screen width.
  ///
  /// Unused: the bar's width is an iOS length at the authored reference scale.
  /// Each device states it in [defaultsByDevice]. Stating
  /// [gestureBarWidthRatio] pins the bar to that fraction of the width.
  @Deprecated(
    'Per-device now: read defaultsByDevice[device].gestureBarWidth instead '
    '(since 0.154) — the bar is an iOS length at the authored reference '
    'scale, not a fraction of its width.',
  )
  static const double defaultGestureBarWidthRatio = 0.34;

  /// Default home gesture bar height (iOS points).
  /// Device geometry, off the ladders.
  static const double defaultGestureBarHeight = 5;

  /// Default home gesture bar distance from the screen's bottom edge (iOS
  /// points).
  static const double defaultGestureBarOffset = CoreSpace.space8;

  /// Default home gesture bar corner radius (iOS points) — a little under
  /// half its height, so the ends are rounded rather than a full pill.
  static const double defaultGestureBarRadius = CoreRadius.radius2;

  /// Default partial style for the composed `OutlinedContainer` body —
  /// only the shadow, which is the one thing this component states about
  /// that primitive beyond its own rail / rim / radius fields. Fill,
  /// stroke, radius and inset are supplied by the resolver from those
  /// fields; everything else is the primitive's own default.
  ///
  /// The cast is [defaultBodyShadow] in black, a literal rather than the
  /// palette's `shadow` token: the device's colour is the same in every
  /// mode, so it does not follow a palette slot that can turn over. Its
  /// alpha is the stack's own in every mode too — `shadowStrengthens: false`
  /// leaves the dark theme's multiplier (`CoreShadow.darkStrength`) out, so
  /// the device casts on a dark page exactly what it casts on a light one.
  static const CoreOutlinedContainerStyle defaultContainerStyle =
      CoreOutlinedContainerStyle(
        boxShadow: defaultBodyShadow,
        shadowBaseColor: CoreColor(0xFF000000),
        shadowStrengthens: false,
      );

  /// The cast under the device body — two layers, a wide soft one and a
  /// tight one under it, each pulled in by a negative spread so the shadow
  /// sits inside the body's outline.
  ///
  /// Pinned to the cast v1 drew (the two-layer `CoreShadow.xl` of v1) at the
  /// designer's request, epic #5485: the v2 shadow scale moved `xl` to one
  /// wide modal layer, which reads as a panel floating off the page, not a
  /// device lying on it. Stated here rather than as a reference to the scale
  /// so a later move of the scale does not move the device. It is not a step
  /// of the scale, so the Figma builder draws it as the numbers it is.
  static const List<CoreShadowLayer> defaultBodyShadow = [
    (
      offsetX: 0,
      offsetY: 14,
      blurRadius: 28,
      spreadRadius: -5,
      opacity: 0.08,
      inset: false,
    ),
    (
      offsetX: 0,
      offsetY: 6,
      blurRadius: 10,
      spreadRadius: -3,
      opacity: 0.05,
      inset: false,
    ),
  ];

  /// Default device width (logical px).
  ///
  /// `width` itself is NOT an instance field on this Style — it is a
  /// semantic layout knob supplied on the widget edge. This constant only
  /// holds the DESIGN-SYSTEM DEFAULT VALUE so Flutter and Web resolvers
  /// share a single source of truth.
  static const double defaultWidth = 320;

  /// Screen width of the `flat` finish (logical px) — 240, off the size
  /// ladder like [defaultWidth], written as the two rungs that sum to it.
  static const double defaultFlatScreenWidth =
      CoreSize.size112 + CoreSize.size128;

  /// Ring thickness of the `flat` finish — the one the `flat` row states
  /// for `bezelWidth`, shared so the default body width cannot drift from it.
  static const double defaultFlatBezelWidth = CoreSpace.space8;

  /// Default device width of the `flat` finish (logical px): the body is the
  /// screen plus the ring on both sides, so the screen is
  /// [defaultFlatScreenWidth] wide (the `flat` row has no rail).
  static const double defaultFlatWidth =
      defaultFlatScreenWidth + defaultFlatBezelWidth * 2;

  /// Default device width on [finish].
  ///
  /// `width` is not an instance field on this Style (it is a widget prop),
  /// so the finish cannot restate it through [defaultsByFinish]; this is the
  /// finish-aware counterpart of [defaultWidth] that both platforms' widgets
  /// read.
  static double defaultWidthFor(CoreMockupDeviceFinish finish) =>
      switch (finish) {
        .realistic => defaultWidth,
        .flat => defaultFlatWidth,
      };

  // ─── Fixed status bar content — not chrome, not overridable ──────
  // What the status bar shows is sample content, the way the picture inside a
  // screenshot is: a mockup draws an operating system caught at one moment, so
  // the clock reads 9:41 whatever locale the app runs in and no caller words
  // it. That makes the text neither a widget parameter nor a localisation
  // member, and the glyph drawings below the same — each is stated here once
  // and read by both platforms and by the Figma builder.

  /// The clock the status bar shows.
  static const String sampleTime = '9:41';

  /// The tablet clock's meridiem, set apart from [sampleTime].
  static const String sampleMeridiem = '오전';

  /// The date the tablet's status bar shows beside its clock.
  static const String sampleDate = '4월 1일 수요일';

  /// The battery percentage the tablet's status bar shows beside its battery.
  static const String sampleBatteryLevel = '100%';

  /// The phone's cellular-signal glyph.
  static const CoreVectorGlyph phoneCellularGlyph =
      CoreMockupStatusBarGlyphs.phoneCellular;

  /// The phone's wifi glyph.
  static const CoreVectorGlyph phoneWifiGlyph =
      CoreMockupStatusBarGlyphs.phoneWifi;

  /// The nub on the end of the phone's battery.
  static const CoreVectorGlyph phoneBatteryCapGlyph =
      CoreMockupStatusBarGlyphs.phoneBatteryCap;

  /// The tablet's wifi glyph.
  static const CoreVectorGlyph tabletWifiGlyph =
      CoreMockupStatusBarGlyphs.tabletWifi;

  /// The tablet's battery — outline, nub and level as one drawing.
  static const CoreVectorGlyph tabletBatteryGlyph =
      CoreMockupStatusBarGlyphs.tabletBattery;

  // The phone's battery is three parts laid in one box — an outline, a level
  // inside it and a nub beside it — and these are that box's proportions (iOS
  // points). They are the artwork's own, so they are fixed with it.

  /// The phone battery outline's width.
  static const double phoneBatteryWidth = 25;

  /// The phone battery outline's height.
  static const double phoneBatteryHeight = 13;

  /// The phone battery outline's stroke, drawn inside its box.
  static const double phoneBatteryBorderWidth = CoreStrokeWidth.stroke1;

  /// The phone battery outline's corner radius.
  static const double phoneBatteryRadius = CoreRadius.radius4;

  /// How far the phone battery's level is inset from its outline on every
  /// side — so the level is the outline's box shrunk by this much.
  static const double phoneBatteryCapacityInset = CoreSpace.space2;

  /// The phone battery level's corner radius.
  static const double phoneBatteryCapacityRadius = CoreRadius.radius2;

  /// The gap between the phone battery's outline and its nub.
  static const double phoneBatteryCapGap = 1;

  /// How far below the phone battery's top edge its nub starts.
  static const double phoneBatteryCapOffset = 4.5;

  // ─── Per-device defaults — one table ──────────────────
  // Lengths the size / space ladders carry are tokens; the rest are the
  // device's own geometry (documented per field) and stay raw, the way
  // `defaultWidth` does.

  /// Per-device defaults for the fields that differ by device kind.
  static const Map<CoreMockupDevice, CoreMockupDeviceStyle> defaultsByDevice = {
    CoreMockupDevice.phone: CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
      // Rail 3 + bezel 5: the screen sits 8 in from the body edge.
      bezelWidth: 5,
      // The pill is cut out of the screen.
      cameraPlacement: CoreMockupCameraPlacement.screen,
      // Device geometry, off the ladders: a 45 × 13 pill, 4 down from the
      // screen's edge.
      cameraWidth: 45,
      cameraHeight: 13,
      cameraOffset: CoreSpace.space4,
      // The lens ring sits 3.25 in from the pill's end, centred across it.
      lensSize: 6.5,
      lensOffset: 3.25,
      cameraCoreSize: 3.9,
      powerButtonLength: CoreSize.size40,
      // Fractions of the edge the button sits on (device geometry): power
      // 30% down the right edge, volume 20% down the left edge.
      powerButtonOffset: 0.30,
      volumeButtonLength: 26,
      volumeButtonOffset: 0.20,
      // Two volume buttons; the second starts one length plus this gap
      // below the first.
      volumeButtonSpacing: CoreSpace.space8,
      // Which edge each button sits on when the phone turns is derived
      // (the upright pose, rotated); how far along that edge it sits, and
      // how long it is, is authored, because the canvas places it by eye
      // rather than by the rotation — the tablet's landscape pair is not its
      // portrait pair rotated either. The phone keeps its portrait lengths
      // and fractions in landscape.
      landscapePowerButtonLength: CoreSize.size40,
      landscapePowerButtonOffset: 0.30,
      landscapeVolumeButtonLength: 26,
      landscapeVolumeButtonOffset: 0.20,
      // Six bands, each 1.9 long and as thick as the rail.
      antennaBandLength: 1.9,
      // The design draws iOS lengths at the reference screen widths 144
      // upright and 312 on its side. Keep that point-to-pixel scale when the
      // body resizes, just like Figma's fixed-height system chrome.
      systemBarReferenceWidth: 402,
      systemBarReferenceScale: 0.3582089552238806,
      landscapeSystemBarReferenceWidth: 874,
      landscapeSystemBarReferenceScale: 0.35697940503432496,
      // A 59-point bar, none at all on its side (iOS hides it there).
      statusBarHeight: 59,
      landscapeStatusBarHeight: 0,
      // The clock and the signal glyphs each sit in a 101-point wing, 24 in
      // from their edge; the trailing wing keeps 2 points more on its outer
      // side. Everything is centred on a line 32.5 points below the top: the
      // middle of the 23-point band between 20 points of padding above and 16
      // below (31.5), dropped one point more by the 2 points of padding the
      // wings keep above their content.
      statusBarInset: CoreSpace.space24,
      statusBarContentCenter: 32.5,
      statusBarWingWidth: 101,
      statusBarTrailingInset: CoreSpace.space2,
      statusBarTrailingSpacing: CoreSpace.space6,
      statusBarTextStyle: CoreTextStyle.token(
        CoreTextStyles.titleSmall,
        color: CoreColor.token(CoreColors.onSurface),
      ),
      // A 34-point area along the bottom upright and 21 on its side — the
      // bottom safe-area insets of an iPhone — with a bar 144 / 209 points
      // wide.
      gestureBarWidth: 144,
      landscapeGestureBarWidth: 209,
      gestureBarAreaHeight: 34,
      landscapeGestureBarAreaHeight: 21,
      screenAspectWidth: 9,
      screenAspectHeight: 19.5,
    ),
    CoreMockupDevice.tablet: CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      // Rail 3 + bezel 8: the screen sits 11 in from the body edge.
      bezelWidth: CoreSpace.space8,
      // The camera sits in the bezel strip above the screen, 2 below the
      // bezel's top — centred on the 8-wide strip.
      cameraPlacement: CoreMockupCameraPlacement.bezel,
      cameraWidth: CoreSize.size4,
      cameraHeight: CoreSize.size4,
      cameraOffset: CoreSpace.space2,
      // No lens ring — the round cut-out is the lens, the core sits in it.
      lensSize: 0,
      lensOffset: 0,
      cameraCoreSize: 2.4,
      // The tablet's buttons are measured per orientation: a turned tablet's
      // slabs are longer (device geometry, from the 321 × 455 and 455 × 321
      // canvas members).
      //
      // Power hugs the top-right corner on whichever edge is short: a
      // fraction of that edge, from its right end. Must stay past the body
      // radius so the slab does not overlap the curve.
      powerButtonLength: 45.433,
      powerButtonOffset: 0.11673208722741432,
      volumeButtonLength: 33.317,
      volumeButtonOffset: 0.18382857142857142,
      // A single rocker — no gap, no second button.
      volumeButtonSpacing: 0,
      // Landscape turns the edges, so the corners the buttons hug are
      // different corners: power sits on the right edge, a fraction of it
      // down from the top; volume on the top edge, a fraction of it along
      // from the left.
      landscapePowerButtonLength: 49.522,
      landscapePowerButtonOffset: 0.15497819314641745,
      landscapeVolumeButtonLength: 36.316,
      landscapeVolumeButtonOffset: 0.620534065934066,
      // No antenna bands.
      antennaBandLength: 0,
      // The canvas draws the tablet's bars at the phone's scale (0.358 of an
      // iOS point), so the width its 299- and 433-wide screens stand for at
      // that scale — 299 × 402 / 144 upright, 433 × 402 / 144 on its side —
      // is the reference, not an iPad's own 834 / 1194. The bars are 32
      // points tall in both poses.
      systemBarReferenceWidth: 834.7083333333334,
      systemBarReferenceScale: 0.3582089552238806,
      landscapeSystemBarReferenceWidth: 1208.7916666666667,
      landscapeSystemBarReferenceScale: 0.3582089552238806,
      statusBarHeight: CoreSize.size32,
      landscapeStatusBarHeight: CoreSize.size32,
      // No wings: the clock group hugs the leading edge and the glyph group
      // the trailing one, 16 points in, both centred on the bar's own middle.
      statusBarInset: CoreSpace.space16,
      statusBarContentCenter: CoreSize.size16,
      statusBarWingWidth: 0,
      statusBarTrailingInset: 0,
      statusBarTrailingSpacing: CoreSpace.space4,
      statusBarTextStyle: CoreTextStyle.token(
        CoreTextStyles.labelLarge,
        color: CoreColor.token(CoreColors.onSurface),
      ),
      // A 20-point area along the bottom and a bar 314 points wide, in both
      // poses.
      gestureBarWidth: 314,
      landscapeGestureBarWidth: 314,
      gestureBarAreaHeight: CoreSize.size20,
      landscapeGestureBarAreaHeight: CoreSize.size20,
      // The canvas's screen box (299 × 433), as the proportion it states.
      screenAspectWidth: 299,
      screenAspectHeight: 433,
    ),
  };

  /// Per-finish overrides, laid over [defaultsByDevice].
  ///
  /// `realistic` is an empty row: it states nothing, so every value is the
  /// plain default or the per-device one. `flat` restates what a frame is
  /// made of: one 8-thick ring in the palette's `surfaceContainerHighest`
  /// around a 1 : 2 screen, with no rail, antenna band, button, rim light,
  /// bezel line or inner shadow, no lens ring and no cast shadow. The body
  /// radius is 32, so the screen's — derived from it by the ring — is 24.
  ///
  /// The ring takes the same token as the body fill: with no rail the body
  /// sits wholly under the bezel, and a body fill of another colour would
  /// show at the anti-aliased corners. The ring is the first piece of hardware
  /// colour that follows the active scheme; `realistic`'s stays a literal.
  ///
  /// `flat` also states a 1 : 2 screen for every device kind — a frame is
  /// not a picture of a tablet.
  ///
  /// Reach — the `flat` edge is a fill and nothing else: it states no border
  /// or outline. A mode that forces colours repaints fills with the page
  /// colour, so there the ring does not separate from the screen. A
  /// forced-colour-safe line would take layout from the 8-thick ring (a
  /// border on Flutter's box) or add a Web-only outline no counterpart
  /// mirrors, so the finish does not draw one; a caller who needs the edge
  /// there states a border colour and width on the instance style or in
  /// `finishStyles`. A shared mockup theme and `finishStyles` both lay over
  /// this row, so a shared theme that states a radius or body colour wins
  /// over the `flat` values and `finishStyles` is how to restate them.
  static const Map<CoreMockupDeviceFinish, CoreMockupDeviceStyle>
  defaultsByFinish = {
    CoreMockupDeviceFinish.realistic: CoreMockupDeviceStyle(),
    CoreMockupDeviceFinish.flat: CoreMockupDeviceStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
      bezelWidth: defaultFlatBezelWidth,
      bezelColor: CoreColor.token(CoreColors.surfaceContainerHighest),
      railColor: CoreColor.token(CoreColors.surfaceContainerHighest),
      // No rail, no outer line, no line or inner glow on the bezel.
      railWidth: 0,
      borderWidth: 0,
      // A zero width still leaves a hairline on Flutter's box border; only
      // an invisible colour removes it.
      borderColor: CoreColor.transparent,
      bezelBorderWidth: 0,
      bezelInnerShadowBlur: 0,
      bezelInnerShadowSpread: 0,
      // No rim light.
      rimHighlightWidth: 0,
      rimGlowWidth: 0,
      // No lens ring.
      lensSize: 0,
      lensOffset: 0,
      // No buttons: a zero length is how a device says "none".
      powerButtonLength: 0,
      volumeButtonLength: 0,
      volumeButtonSpacing: 0,
      landscapePowerButtonLength: 0,
      landscapeVolumeButtonLength: 0,
      // No antenna bands.
      antennaBandLength: 0,
      screenAspectWidth: 1,
      screenAspectHeight: 2,
      // No cast shadow.
      containerStyle: CoreOutlinedContainerStyle(boxShadow: CoreShadow.none),
    ),
  };

  /// The body's gradient fill, or `null` when the body is a solid.
  ///
  /// Both platforms and the Figma builder read this one answer instead of
  /// each deciding the precedence: a stated [railGradient] wins; a stated
  /// [railColor] (a caller's, or the shared mockup theme's `frameColor`) makes
  /// the body that solid; with neither the body is [defaultRailGradient].
  /// Both arguments are the merge chain's output — `null` means "not stated".
  static CoreGradient? resolveBodyGradient({
    CoreColor? railColor,
    CoreGradient? railGradient,
  }) => railGradient ?? (railColor == null ? defaultRailGradient : null);

  /// The lens core's gradient fill, or `null` when the core is a solid.
  ///
  /// The same precedence as [resolveBodyGradient]: a stated [coreGradient]
  /// wins; a stated [cutoutColor] makes the core that solid; with neither the
  /// core is [defaultCoreGradient].
  static CoreGradient? resolveCoreGradient({
    CoreColor? cutoutColor,
    CoreGradient? coreGradient,
  }) => coreGradient ?? (cutoutColor == null ? defaultCoreGradient : null);

  // ─── Instance override slots ──────────────────────────

  /// Fill behind both the child and the safe-area bands.
  /// Use the child's background colour here for a continuous surface, or
  /// leave the child transparent to share this single background layer.
  final CoreColor? backgroundColor;

  /// Rail (body ring) solid fill override.
  ///
  /// Stating it makes the body this solid instead of the default gradient
  /// (see [resolveBodyGradient]); [railGradient] wins over it when both are
  /// stated.
  final CoreColor? railColor;

  /// Rail (body ring) gradient fill override — replaces the default body
  /// gradient, and wins over [railColor].
  final CoreGradient? railGradient;

  /// Rim stroke colour override — the hairline inside the body edge.
  final CoreColor? borderColor;

  /// Rim stroke width override (logical px).
  final double? borderWidth;

  /// Rim highlight stroke colour override — the lit hairline just inside the
  /// rim.
  final CoreColor? rimHighlightColor;

  /// Rim highlight stroke width override (logical px), drawn inside its box.
  final double? rimHighlightWidth;

  /// Rim highlight inset override — from the body's top and bottom edges
  /// (logical px).
  final double? rimHighlightInset;

  /// Rim glow stroke override — the gradient the glow is stroked with.
  final CoreGradient? rimGlowGradient;

  /// Rim glow opacity override — a paint opacity over the whole glow stroke.
  final double? rimGlowOpacity;

  /// Rim glow stroke width override (logical px), drawn inside its box.
  final double? rimGlowWidth;

  /// Rim glow inset override — from the body's top edge (logical px).
  final double? rimGlowTopInset;

  /// Rim glow inset override — from the body's bottom edge (logical px).
  final double? rimGlowBottomInset;

  /// Rim glow blur radius override (logical px).
  final double? rimGlowBlur;

  /// Inner bezel fill override.
  final CoreColor? bezelColor;

  /// Bezel outline colour override — drawn outside the bezel box.
  final CoreColor? bezelBorderColor;

  /// Bezel outline width override (logical px).
  final double? bezelBorderWidth;

  /// Bezel inner-shadow colour override — alpha included.
  final CoreColor? bezelInnerShadowColor;

  /// Bezel inner-shadow blur radius override (logical px).
  final double? bezelInnerShadowBlur;

  /// Bezel inner-shadow spread override (logical px).
  final double? bezelInnerShadowSpread;

  /// Hardware button base fill override — the solid under the gloss layers.
  final CoreColor? buttonColor;

  /// Hardware button gloss-along-the-length override. Authored for an
  /// upright button, top to bottom; the layout points it along the button
  /// (`CoreMockupDeviceLayout.buttonLengthGradient`), so its `begin` / `end`
  /// are not read.
  final CoreGradient? buttonLengthGradient;

  /// Hardware button shade-across-the-thickness override: the dark end of the
  /// fade, at the edge nearest the body. The far end is clear.
  final CoreColor? buttonDepthColor;

  /// Lens fill override — the ring inside the camera cut-out, or the
  /// cut-out itself when the device draws no ring ([lensSize] `0`: the
  /// round cut-out IS the lens).
  ///
  /// The removed `cameraColor` slot lands here when the cut-out is
  /// itself the lens; it lands on [cutoutColor] when a ring is drawn.
  final CoreColor? lensColor;

  /// Cut-out fill override — the camera cut-out whenever it holds a lens
  /// ring. A cut-out that is itself the lens takes [lensColor] instead
  /// (`CoreMockupDeviceLayout.cameraIsLens`).
  ///
  /// This is where the removed `cameraColor` slot lands for a ringed
  /// cut-out — which of the two takes it is decided by the lens, not by
  /// the caller. Stating it also makes the lens core this solid instead of
  /// [defaultCoreGradient] (see [resolveCoreGradient]).
  final CoreColor? cutoutColor;

  /// Lens core fill override — a radial gradient from the core's centre to
  /// the edge of its box.
  final CoreGradient? coreGradient;

  /// Lens highlight fill override — the glint on the core.
  final CoreColor? lensHighlightColor;

  /// Home gesture bar colour override.
  final CoreColor? gestureBarColor;

  /// Status bar glyph fill override — the signal and wifi glyphs, the phone
  /// battery's level and the tablet battery.
  final CoreColor? statusBarIconColor;

  /// Fill override for the phone battery's outline.
  final CoreColor? statusBarBatteryBorderColor;

  /// Fill override for the phone battery's nub.
  final CoreColor? statusBarBatteryCapColor;

  /// Status bar text style override — the clock, the date and the battery
  /// percentage. A role and a colour, authored at its iOS size: the layout's
  /// `CoreMockupDeviceLayout.systemBarScale` applies the authored fixed scale;
  /// tracking and leading — ratios — follow the resulting font size.
  final CoreTextStyle? statusBarTextStyle;

  /// Body corner radius override. The bezel and screen radii are derived
  /// from it (minus the rail, minus the whole inset) so the three stay
  /// concentric.
  final CoreBorderRadius? borderRadius;

  /// Rail band width override (logical px).
  final double? railWidth;

  /// Inner bezel width override (logical px).
  final double? bezelWidth;

  /// Where the camera assembly sits override — over the screen, or in the
  /// bezel strip above it. Decides which space the camera / lens / core /
  /// highlight rectangles are in (`CoreMockupDeviceLayout.cameraPlacement`).
  final CoreMockupCameraPlacement? cameraPlacement;

  /// Camera cut-out width override (logical px) — the long side of the
  /// upright pill.
  final double? cameraWidth;

  /// Camera cut-out height override (logical px) — the short side of the
  /// upright pill.
  final double? cameraHeight;

  /// Camera distance override from the top edge of the space it sits in —
  /// the screen's, or the bezel's — for an upright body; a turned phone
  /// measures it from the screen's left edge instead (logical px).
  final double? cameraOffset;

  /// Lens ring diameter override (logical px); `0` draws no ring.
  final double? lensSize;

  /// Lens ring inset from the cut-out's end override (logical px) — the right
  /// end of an upright pill, the top end of a turned one.
  final double? lensOffset;

  /// Lens core dot diameter override (logical px).
  final double? cameraCoreSize;

  /// Lens highlight diameter override, as a fraction of the core's diameter.
  final double? lensHighlightSizeRatio;

  /// Lens highlight distance override from the core's left edge, as a fraction
  /// of the core's diameter.
  final double? lensHighlightOffsetXRatio;

  /// Lens highlight distance override from the core's top edge, as a fraction
  /// of the core's diameter.
  final double? lensHighlightOffsetYRatio;

  /// Hardware button thickness override (logical px).
  final double? buttonThickness;

  /// Hardware button protrusion past the body override (logical px).
  final double? buttonProtrusion;

  /// Power button length along its edge override for a portrait body
  /// (logical px).
  final double? powerButtonLength;

  /// Power button position override for a portrait body — a fraction of
  /// its edge, measured from the top-right corner.
  final double? powerButtonOffset;

  /// Volume button length along its edge override for a portrait body
  /// (logical px).
  final double? volumeButtonLength;

  /// Volume button position override for a portrait body — a fraction of
  /// its edge, measured from the top-left corner.
  final double? volumeButtonOffset;

  /// Gap between the two volume buttons override (logical px); `0` draws
  /// a single rocker.
  final double? volumeButtonSpacing;

  /// Power button length override for a turned body
  /// (`CoreMockupOrientation.landscape`) — the landscape counterpart of
  /// [powerButtonLength].
  final double? landscapePowerButtonLength;

  /// Power button position override for a turned body
  /// (`CoreMockupOrientation.landscape`) — the landscape counterpart of
  /// [powerButtonOffset].
  ///
  /// Which *edge* the button moves to is derived (the upright pose turned a
  /// quarter turn clockwise); how far *along* that edge it sits is stated
  /// here, because the canvas places it by eye rather than by the rotation.
  final double? landscapePowerButtonOffset;

  /// Volume button length override for a turned body — the landscape
  /// counterpart of [volumeButtonLength].
  final double? landscapeVolumeButtonLength;

  /// Volume button position override for a turned body — the landscape
  /// counterpart of [volumeButtonOffset], on the same terms as
  /// [landscapePowerButtonOffset].
  final double? landscapeVolumeButtonOffset;

  /// Antenna band fill override — top to bottom, whichever way the band lies.
  final CoreGradient? antennaGradient;

  /// Antenna band opacity override — a paint opacity over each band.
  final double? antennaOpacity;

  /// Antenna band length override (logical px); `0` draws no bands. A band
  /// is as thick as the rail.
  final double? antennaBandLength;

  /// Override for where an upright body's side bands sit measured from the
  /// *near* (top) end of the sides (logical px).
  final double? antennaSideNearOffset;

  /// Override for where an upright body's side bands sit measured from the
  /// *far* (bottom) end of the sides (logical px).
  final double? antennaSideFarOffset;

  /// Override for where an upright body's top band sits measured from the
  /// *far* (right) end of the top edge (logical px).
  final double? antennaTopOffset;

  /// Override for where an upright body's bottom band sits measured from the
  /// *near* (left) end of the bottom edge (logical px).
  final double? antennaBottomOffset;

  /// Width the status bar and gesture bar are authored for when the device is
  /// held upright (iOS points). A non-positive width disables the system
  /// drawings. Their point-to-pixel scale is [systemBarReferenceScale].
  final double? systemBarReferenceWidth;

  /// Portrait iOS-point-to-logical-pixel scale authored by the design.
  /// Independent of widget width: resizing stretches the background while
  /// bar height, content position, glyphs and the home indicator stay fixed.
  final double? systemBarReferenceScale;

  /// Width the status bar and gesture bar are authored for when the device is
  /// turned (iOS points) — the landscape counterpart of
  /// [systemBarReferenceWidth].
  final double? landscapeSystemBarReferenceWidth;

  /// Landscape iOS-point-to-logical-pixel scale authored by the design.
  final double? landscapeSystemBarReferenceScale;

  /// Status bar height override for an upright device (iOS points).
  final double? statusBarHeight;

  /// Status bar height override for a turned device (iOS points); `0` draws
  /// none — the landscape counterpart of [statusBarHeight].
  final double? landscapeStatusBarHeight;

  /// Status bar inset override — from the screen's side edge to the first and
  /// last group (iOS points).
  final double? statusBarInset;

  /// Status bar content line override — how far below the bar's top edge the
  /// line every clock, glyph and text is centred on (iOS points).
  final double? statusBarContentCenter;

  /// Status bar wing width override (iOS points). With a width, each group is
  /// centred in a box that wide at its own side; `0` lets the groups hug the
  /// two edges instead.
  final double? statusBarWingWidth;

  /// Status bar trailing wing inset override — how much room the trailing
  /// wing keeps on its outer side beyond [statusBarInset] (iOS points). Only
  /// meaningful with a [statusBarWingWidth].
  final double? statusBarTrailingInset;

  /// Gap override between the glyphs of the status bar's trailing group (iOS
  /// points).
  final double? statusBarTrailingSpacing;

  /// Gap override between the clock and its meridiem (iOS points).
  final double? statusBarClockSpacing;

  /// Gap override between the clock group and the date (iOS points).
  final double? statusBarLeadingSpacing;

  /// Home gesture bar width override — a fraction of the screen width.
  ///
  /// Stating it pins the bar to that fraction of the screen's width and wins
  /// over [gestureBarWidth] / [landscapeGestureBarWidth]; leaving it out lets
  /// the bar be the iOS length the device authors.
  @Deprecated(
    'State gestureBarWidth (and landscapeGestureBarWidth) instead (since '
    '0.154) — the bar is an iOS length at the authored reference scale, '
    'not a '
    'fraction of its width.',
  )
  final double? gestureBarWidthRatio;

  /// The fraction of the screen's width the gesture bar is pinned to, or
  /// `null` when none is stated.
  ///
  /// The one place the deprecated [gestureBarWidthRatio] is read: a resolver
  /// hands this to `CoreMockupDeviceLayout.compute`, so no platform code has to
  /// name a deprecated member to keep a caller's pin working until the field is
  /// removed.
  double? get pinnedGestureBarWidthRatio => gestureBarWidthRatio;

  /// Home gesture bar width override for an upright device (iOS points).
  final double? gestureBarWidth;

  /// Home gesture bar width override for a turned device (iOS points) — the
  /// landscape counterpart of [gestureBarWidth].
  final double? landscapeGestureBarWidth;

  /// Home gesture bar height override (iOS points).
  final double? gestureBarHeight;

  /// Home gesture bar distance from the screen's bottom edge override (iOS
  /// points).
  final double? gestureBarOffset;

  /// Home gesture bar corner radius override (iOS points).
  final double? gestureBarRadius;

  /// Height override of the area the gesture bar lives in, upright (iOS
  /// points) — the bottom safe-area inset a visible bar reserves.
  final double? gestureBarAreaHeight;

  /// Height override of the gesture bar's area for a turned device (iOS
  /// points) — the landscape counterpart of [gestureBarAreaHeight].
  final double? landscapeGestureBarAreaHeight;

  /// Screen aspect ratio width component override.
  final double? screenAspectWidth;

  /// Screen aspect ratio height component override.
  final double? screenAspectHeight;

  /// Nested style for the composed `OutlinedContainer` body — shadow,
  /// clip, motion. Raw-forwarded; the primitive resolves it.
  final CoreOutlinedContainerStyle? containerStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreMockupDeviceStyle merge(CoreMockupDeviceStyle? other) {
    if (other == null) return this;
    return CoreMockupDeviceStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      railColor: other.railColor ?? railColor,
      railGradient: other.railGradient ?? railGradient,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      rimHighlightColor: other.rimHighlightColor ?? rimHighlightColor,
      rimHighlightWidth: other.rimHighlightWidth ?? rimHighlightWidth,
      rimHighlightInset: other.rimHighlightInset ?? rimHighlightInset,
      rimGlowGradient: other.rimGlowGradient ?? rimGlowGradient,
      rimGlowOpacity: other.rimGlowOpacity ?? rimGlowOpacity,
      rimGlowWidth: other.rimGlowWidth ?? rimGlowWidth,
      rimGlowTopInset: other.rimGlowTopInset ?? rimGlowTopInset,
      rimGlowBottomInset: other.rimGlowBottomInset ?? rimGlowBottomInset,
      rimGlowBlur: other.rimGlowBlur ?? rimGlowBlur,
      bezelColor: other.bezelColor ?? bezelColor,
      bezelBorderColor: other.bezelBorderColor ?? bezelBorderColor,
      bezelBorderWidth: other.bezelBorderWidth ?? bezelBorderWidth,
      bezelInnerShadowColor:
          other.bezelInnerShadowColor ?? bezelInnerShadowColor,
      bezelInnerShadowBlur: other.bezelInnerShadowBlur ?? bezelInnerShadowBlur,
      bezelInnerShadowSpread:
          other.bezelInnerShadowSpread ?? bezelInnerShadowSpread,
      buttonColor: other.buttonColor ?? buttonColor,
      buttonLengthGradient: other.buttonLengthGradient ?? buttonLengthGradient,
      buttonDepthColor: other.buttonDepthColor ?? buttonDepthColor,
      lensColor: other.lensColor ?? lensColor,
      cutoutColor: other.cutoutColor ?? cutoutColor,
      coreGradient: other.coreGradient ?? coreGradient,
      lensHighlightColor: other.lensHighlightColor ?? lensHighlightColor,
      gestureBarColor: other.gestureBarColor ?? gestureBarColor,
      statusBarIconColor: other.statusBarIconColor ?? statusBarIconColor,
      statusBarBatteryBorderColor:
          other.statusBarBatteryBorderColor ?? statusBarBatteryBorderColor,
      statusBarBatteryCapColor:
          other.statusBarBatteryCapColor ?? statusBarBatteryCapColor,
      statusBarTextStyle:
          statusBarTextStyle?.merge(other.statusBarTextStyle) ??
          other.statusBarTextStyle,
      borderRadius: other.borderRadius ?? borderRadius,
      railWidth: other.railWidth ?? railWidth,
      bezelWidth: other.bezelWidth ?? bezelWidth,
      cameraPlacement: other.cameraPlacement ?? cameraPlacement,
      cameraWidth: other.cameraWidth ?? cameraWidth,
      cameraHeight: other.cameraHeight ?? cameraHeight,
      cameraOffset: other.cameraOffset ?? cameraOffset,
      lensSize: other.lensSize ?? lensSize,
      lensOffset: other.lensOffset ?? lensOffset,
      cameraCoreSize: other.cameraCoreSize ?? cameraCoreSize,
      lensHighlightSizeRatio:
          other.lensHighlightSizeRatio ?? lensHighlightSizeRatio,
      lensHighlightOffsetXRatio:
          other.lensHighlightOffsetXRatio ?? lensHighlightOffsetXRatio,
      lensHighlightOffsetYRatio:
          other.lensHighlightOffsetYRatio ?? lensHighlightOffsetYRatio,
      buttonThickness: other.buttonThickness ?? buttonThickness,
      buttonProtrusion: other.buttonProtrusion ?? buttonProtrusion,
      powerButtonLength: other.powerButtonLength ?? powerButtonLength,
      powerButtonOffset: other.powerButtonOffset ?? powerButtonOffset,
      volumeButtonLength: other.volumeButtonLength ?? volumeButtonLength,
      volumeButtonOffset: other.volumeButtonOffset ?? volumeButtonOffset,
      volumeButtonSpacing: other.volumeButtonSpacing ?? volumeButtonSpacing,
      landscapePowerButtonLength:
          other.landscapePowerButtonLength ?? landscapePowerButtonLength,
      landscapePowerButtonOffset:
          other.landscapePowerButtonOffset ?? landscapePowerButtonOffset,
      landscapeVolumeButtonLength:
          other.landscapeVolumeButtonLength ?? landscapeVolumeButtonLength,
      landscapeVolumeButtonOffset:
          other.landscapeVolumeButtonOffset ?? landscapeVolumeButtonOffset,
      antennaGradient: other.antennaGradient ?? antennaGradient,
      antennaOpacity: other.antennaOpacity ?? antennaOpacity,
      antennaBandLength: other.antennaBandLength ?? antennaBandLength,
      antennaSideNearOffset:
          other.antennaSideNearOffset ?? antennaSideNearOffset,
      antennaSideFarOffset: other.antennaSideFarOffset ?? antennaSideFarOffset,
      antennaTopOffset: other.antennaTopOffset ?? antennaTopOffset,
      antennaBottomOffset: other.antennaBottomOffset ?? antennaBottomOffset,
      systemBarReferenceWidth:
          other.systemBarReferenceWidth ?? systemBarReferenceWidth,
      systemBarReferenceScale:
          other.systemBarReferenceScale ?? systemBarReferenceScale,
      landscapeSystemBarReferenceWidth:
          other.landscapeSystemBarReferenceWidth ??
          landscapeSystemBarReferenceWidth,
      landscapeSystemBarReferenceScale:
          other.landscapeSystemBarReferenceScale ??
          landscapeSystemBarReferenceScale,
      statusBarHeight: other.statusBarHeight ?? statusBarHeight,
      landscapeStatusBarHeight:
          other.landscapeStatusBarHeight ?? landscapeStatusBarHeight,
      statusBarInset: other.statusBarInset ?? statusBarInset,
      statusBarContentCenter:
          other.statusBarContentCenter ?? statusBarContentCenter,
      statusBarWingWidth: other.statusBarWingWidth ?? statusBarWingWidth,
      statusBarTrailingInset:
          other.statusBarTrailingInset ?? statusBarTrailingInset,
      statusBarTrailingSpacing:
          other.statusBarTrailingSpacing ?? statusBarTrailingSpacing,
      statusBarClockSpacing:
          other.statusBarClockSpacing ?? statusBarClockSpacing,
      statusBarLeadingSpacing:
          other.statusBarLeadingSpacing ?? statusBarLeadingSpacing,
      gestureBarWidthRatio: other.gestureBarWidthRatio ?? gestureBarWidthRatio,
      gestureBarWidth: other.gestureBarWidth ?? gestureBarWidth,
      landscapeGestureBarWidth:
          other.landscapeGestureBarWidth ?? landscapeGestureBarWidth,
      gestureBarHeight: other.gestureBarHeight ?? gestureBarHeight,
      gestureBarOffset: other.gestureBarOffset ?? gestureBarOffset,
      gestureBarRadius: other.gestureBarRadius ?? gestureBarRadius,
      gestureBarAreaHeight: other.gestureBarAreaHeight ?? gestureBarAreaHeight,
      landscapeGestureBarAreaHeight:
          other.landscapeGestureBarAreaHeight ?? landscapeGestureBarAreaHeight,
      screenAspectWidth: other.screenAspectWidth ?? screenAspectWidth,
      screenAspectHeight: other.screenAspectHeight ?? screenAspectHeight,
      // Nested slot — recursive merge so a caller's partial override keeps
      // the rest of this style's own container defaults.
      containerStyle:
          containerStyle?.merge(other.containerStyle) ?? other.containerStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreMockupDeviceStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? railColor,
    CoreGradient? railGradient,
    CoreColor? borderColor,
    double? borderWidth,
    CoreColor? rimHighlightColor,
    double? rimHighlightWidth,
    double? rimHighlightInset,
    CoreGradient? rimGlowGradient,
    double? rimGlowOpacity,
    double? rimGlowWidth,
    double? rimGlowTopInset,
    double? rimGlowBottomInset,
    double? rimGlowBlur,
    CoreColor? bezelColor,
    CoreColor? bezelBorderColor,
    double? bezelBorderWidth,
    CoreColor? bezelInnerShadowColor,
    double? bezelInnerShadowBlur,
    double? bezelInnerShadowSpread,
    CoreColor? buttonColor,
    CoreGradient? buttonLengthGradient,
    CoreColor? buttonDepthColor,
    CoreColor? lensColor,
    CoreColor? cutoutColor,
    CoreGradient? coreGradient,
    CoreColor? lensHighlightColor,
    CoreColor? gestureBarColor,
    CoreColor? statusBarIconColor,
    CoreColor? statusBarBatteryBorderColor,
    CoreColor? statusBarBatteryCapColor,
    CoreTextStyle? statusBarTextStyle,
    CoreBorderRadius? borderRadius,
    double? railWidth,
    double? bezelWidth,
    CoreMockupCameraPlacement? cameraPlacement,
    double? cameraWidth,
    double? cameraHeight,
    double? cameraOffset,
    double? lensSize,
    double? lensOffset,
    double? cameraCoreSize,
    double? lensHighlightSizeRatio,
    double? lensHighlightOffsetXRatio,
    double? lensHighlightOffsetYRatio,
    double? buttonThickness,
    double? buttonProtrusion,
    double? powerButtonLength,
    double? powerButtonOffset,
    double? volumeButtonLength,
    double? volumeButtonOffset,
    double? volumeButtonSpacing,
    double? landscapePowerButtonLength,
    double? landscapePowerButtonOffset,
    double? landscapeVolumeButtonLength,
    double? landscapeVolumeButtonOffset,
    CoreGradient? antennaGradient,
    double? antennaOpacity,
    double? antennaBandLength,
    double? antennaSideNearOffset,
    double? antennaSideFarOffset,
    double? antennaTopOffset,
    double? antennaBottomOffset,
    double? systemBarReferenceWidth,
    double? systemBarReferenceScale,
    double? landscapeSystemBarReferenceWidth,
    double? landscapeSystemBarReferenceScale,
    double? statusBarHeight,
    double? landscapeStatusBarHeight,
    double? statusBarInset,
    double? statusBarContentCenter,
    double? statusBarWingWidth,
    double? statusBarTrailingInset,
    double? statusBarTrailingSpacing,
    double? statusBarClockSpacing,
    double? statusBarLeadingSpacing,
    double? gestureBarWidthRatio,
    double? gestureBarWidth,
    double? landscapeGestureBarWidth,
    double? gestureBarHeight,
    double? gestureBarOffset,
    double? gestureBarRadius,
    double? gestureBarAreaHeight,
    double? landscapeGestureBarAreaHeight,
    double? screenAspectWidth,
    double? screenAspectHeight,
    CoreOutlinedContainerStyle? containerStyle,
  }) {
    return CoreMockupDeviceStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      railColor: railColor ?? this.railColor,
      railGradient: railGradient ?? this.railGradient,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      rimHighlightColor: rimHighlightColor ?? this.rimHighlightColor,
      rimHighlightWidth: rimHighlightWidth ?? this.rimHighlightWidth,
      rimHighlightInset: rimHighlightInset ?? this.rimHighlightInset,
      rimGlowGradient: rimGlowGradient ?? this.rimGlowGradient,
      rimGlowOpacity: rimGlowOpacity ?? this.rimGlowOpacity,
      rimGlowWidth: rimGlowWidth ?? this.rimGlowWidth,
      rimGlowTopInset: rimGlowTopInset ?? this.rimGlowTopInset,
      rimGlowBottomInset: rimGlowBottomInset ?? this.rimGlowBottomInset,
      rimGlowBlur: rimGlowBlur ?? this.rimGlowBlur,
      bezelColor: bezelColor ?? this.bezelColor,
      bezelBorderColor: bezelBorderColor ?? this.bezelBorderColor,
      bezelBorderWidth: bezelBorderWidth ?? this.bezelBorderWidth,
      bezelInnerShadowColor:
          bezelInnerShadowColor ?? this.bezelInnerShadowColor,
      bezelInnerShadowBlur: bezelInnerShadowBlur ?? this.bezelInnerShadowBlur,
      bezelInnerShadowSpread:
          bezelInnerShadowSpread ?? this.bezelInnerShadowSpread,
      buttonColor: buttonColor ?? this.buttonColor,
      buttonLengthGradient: buttonLengthGradient ?? this.buttonLengthGradient,
      buttonDepthColor: buttonDepthColor ?? this.buttonDepthColor,
      lensColor: lensColor ?? this.lensColor,
      cutoutColor: cutoutColor ?? this.cutoutColor,
      coreGradient: coreGradient ?? this.coreGradient,
      lensHighlightColor: lensHighlightColor ?? this.lensHighlightColor,
      gestureBarColor: gestureBarColor ?? this.gestureBarColor,
      statusBarIconColor: statusBarIconColor ?? this.statusBarIconColor,
      statusBarBatteryBorderColor:
          statusBarBatteryBorderColor ?? this.statusBarBatteryBorderColor,
      statusBarBatteryCapColor:
          statusBarBatteryCapColor ?? this.statusBarBatteryCapColor,
      statusBarTextStyle: statusBarTextStyle ?? this.statusBarTextStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      railWidth: railWidth ?? this.railWidth,
      bezelWidth: bezelWidth ?? this.bezelWidth,
      cameraPlacement: cameraPlacement ?? this.cameraPlacement,
      cameraWidth: cameraWidth ?? this.cameraWidth,
      cameraHeight: cameraHeight ?? this.cameraHeight,
      cameraOffset: cameraOffset ?? this.cameraOffset,
      lensSize: lensSize ?? this.lensSize,
      lensOffset: lensOffset ?? this.lensOffset,
      cameraCoreSize: cameraCoreSize ?? this.cameraCoreSize,
      lensHighlightSizeRatio:
          lensHighlightSizeRatio ?? this.lensHighlightSizeRatio,
      lensHighlightOffsetXRatio:
          lensHighlightOffsetXRatio ?? this.lensHighlightOffsetXRatio,
      lensHighlightOffsetYRatio:
          lensHighlightOffsetYRatio ?? this.lensHighlightOffsetYRatio,
      buttonThickness: buttonThickness ?? this.buttonThickness,
      buttonProtrusion: buttonProtrusion ?? this.buttonProtrusion,
      powerButtonLength: powerButtonLength ?? this.powerButtonLength,
      powerButtonOffset: powerButtonOffset ?? this.powerButtonOffset,
      volumeButtonLength: volumeButtonLength ?? this.volumeButtonLength,
      volumeButtonOffset: volumeButtonOffset ?? this.volumeButtonOffset,
      volumeButtonSpacing: volumeButtonSpacing ?? this.volumeButtonSpacing,
      landscapePowerButtonLength:
          landscapePowerButtonLength ?? this.landscapePowerButtonLength,
      landscapePowerButtonOffset:
          landscapePowerButtonOffset ?? this.landscapePowerButtonOffset,
      landscapeVolumeButtonLength:
          landscapeVolumeButtonLength ?? this.landscapeVolumeButtonLength,
      landscapeVolumeButtonOffset:
          landscapeVolumeButtonOffset ?? this.landscapeVolumeButtonOffset,
      antennaGradient: antennaGradient ?? this.antennaGradient,
      antennaOpacity: antennaOpacity ?? this.antennaOpacity,
      antennaBandLength: antennaBandLength ?? this.antennaBandLength,
      antennaSideNearOffset:
          antennaSideNearOffset ?? this.antennaSideNearOffset,
      antennaSideFarOffset: antennaSideFarOffset ?? this.antennaSideFarOffset,
      antennaTopOffset: antennaTopOffset ?? this.antennaTopOffset,
      antennaBottomOffset: antennaBottomOffset ?? this.antennaBottomOffset,
      systemBarReferenceWidth:
          systemBarReferenceWidth ?? this.systemBarReferenceWidth,
      systemBarReferenceScale:
          systemBarReferenceScale ?? this.systemBarReferenceScale,
      landscapeSystemBarReferenceWidth:
          landscapeSystemBarReferenceWidth ??
          this.landscapeSystemBarReferenceWidth,
      landscapeSystemBarReferenceScale:
          landscapeSystemBarReferenceScale ??
          this.landscapeSystemBarReferenceScale,
      statusBarHeight: statusBarHeight ?? this.statusBarHeight,
      landscapeStatusBarHeight:
          landscapeStatusBarHeight ?? this.landscapeStatusBarHeight,
      statusBarInset: statusBarInset ?? this.statusBarInset,
      statusBarContentCenter:
          statusBarContentCenter ?? this.statusBarContentCenter,
      statusBarWingWidth: statusBarWingWidth ?? this.statusBarWingWidth,
      statusBarTrailingInset:
          statusBarTrailingInset ?? this.statusBarTrailingInset,
      statusBarTrailingSpacing:
          statusBarTrailingSpacing ?? this.statusBarTrailingSpacing,
      statusBarClockSpacing:
          statusBarClockSpacing ?? this.statusBarClockSpacing,
      statusBarLeadingSpacing:
          statusBarLeadingSpacing ?? this.statusBarLeadingSpacing,
      gestureBarWidthRatio: gestureBarWidthRatio ?? this.gestureBarWidthRatio,
      gestureBarWidth: gestureBarWidth ?? this.gestureBarWidth,
      landscapeGestureBarWidth:
          landscapeGestureBarWidth ?? this.landscapeGestureBarWidth,
      gestureBarHeight: gestureBarHeight ?? this.gestureBarHeight,
      gestureBarOffset: gestureBarOffset ?? this.gestureBarOffset,
      gestureBarRadius: gestureBarRadius ?? this.gestureBarRadius,
      gestureBarAreaHeight: gestureBarAreaHeight ?? this.gestureBarAreaHeight,
      landscapeGestureBarAreaHeight:
          landscapeGestureBarAreaHeight ?? this.landscapeGestureBarAreaHeight,
      screenAspectWidth: screenAspectWidth ?? this.screenAspectWidth,
      screenAspectHeight: screenAspectHeight ?? this.screenAspectHeight,
      containerStyle: containerStyle ?? this.containerStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMockupDeviceStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          railColor == other.railColor &&
          railGradient == other.railGradient &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          rimHighlightColor == other.rimHighlightColor &&
          rimHighlightWidth == other.rimHighlightWidth &&
          rimHighlightInset == other.rimHighlightInset &&
          rimGlowGradient == other.rimGlowGradient &&
          rimGlowOpacity == other.rimGlowOpacity &&
          rimGlowWidth == other.rimGlowWidth &&
          rimGlowTopInset == other.rimGlowTopInset &&
          rimGlowBottomInset == other.rimGlowBottomInset &&
          rimGlowBlur == other.rimGlowBlur &&
          bezelColor == other.bezelColor &&
          bezelBorderColor == other.bezelBorderColor &&
          bezelBorderWidth == other.bezelBorderWidth &&
          bezelInnerShadowColor == other.bezelInnerShadowColor &&
          bezelInnerShadowBlur == other.bezelInnerShadowBlur &&
          bezelInnerShadowSpread == other.bezelInnerShadowSpread &&
          buttonColor == other.buttonColor &&
          buttonLengthGradient == other.buttonLengthGradient &&
          buttonDepthColor == other.buttonDepthColor &&
          lensColor == other.lensColor &&
          cutoutColor == other.cutoutColor &&
          coreGradient == other.coreGradient &&
          lensHighlightColor == other.lensHighlightColor &&
          gestureBarColor == other.gestureBarColor &&
          statusBarIconColor == other.statusBarIconColor &&
          statusBarBatteryBorderColor == other.statusBarBatteryBorderColor &&
          statusBarBatteryCapColor == other.statusBarBatteryCapColor &&
          statusBarTextStyle == other.statusBarTextStyle &&
          borderRadius == other.borderRadius &&
          railWidth == other.railWidth &&
          bezelWidth == other.bezelWidth &&
          cameraPlacement == other.cameraPlacement &&
          cameraWidth == other.cameraWidth &&
          cameraHeight == other.cameraHeight &&
          cameraOffset == other.cameraOffset &&
          lensSize == other.lensSize &&
          lensOffset == other.lensOffset &&
          cameraCoreSize == other.cameraCoreSize &&
          lensHighlightSizeRatio == other.lensHighlightSizeRatio &&
          lensHighlightOffsetXRatio == other.lensHighlightOffsetXRatio &&
          lensHighlightOffsetYRatio == other.lensHighlightOffsetYRatio &&
          buttonThickness == other.buttonThickness &&
          buttonProtrusion == other.buttonProtrusion &&
          powerButtonLength == other.powerButtonLength &&
          powerButtonOffset == other.powerButtonOffset &&
          volumeButtonLength == other.volumeButtonLength &&
          volumeButtonOffset == other.volumeButtonOffset &&
          volumeButtonSpacing == other.volumeButtonSpacing &&
          landscapePowerButtonLength == other.landscapePowerButtonLength &&
          landscapePowerButtonOffset == other.landscapePowerButtonOffset &&
          landscapeVolumeButtonLength == other.landscapeVolumeButtonLength &&
          landscapeVolumeButtonOffset == other.landscapeVolumeButtonOffset &&
          antennaGradient == other.antennaGradient &&
          antennaOpacity == other.antennaOpacity &&
          antennaBandLength == other.antennaBandLength &&
          antennaSideNearOffset == other.antennaSideNearOffset &&
          antennaSideFarOffset == other.antennaSideFarOffset &&
          antennaTopOffset == other.antennaTopOffset &&
          antennaBottomOffset == other.antennaBottomOffset &&
          systemBarReferenceWidth == other.systemBarReferenceWidth &&
          systemBarReferenceScale == other.systemBarReferenceScale &&
          landscapeSystemBarReferenceWidth ==
              other.landscapeSystemBarReferenceWidth &&
          landscapeSystemBarReferenceScale ==
              other.landscapeSystemBarReferenceScale &&
          statusBarHeight == other.statusBarHeight &&
          landscapeStatusBarHeight == other.landscapeStatusBarHeight &&
          statusBarInset == other.statusBarInset &&
          statusBarContentCenter == other.statusBarContentCenter &&
          statusBarWingWidth == other.statusBarWingWidth &&
          statusBarTrailingInset == other.statusBarTrailingInset &&
          statusBarTrailingSpacing == other.statusBarTrailingSpacing &&
          statusBarClockSpacing == other.statusBarClockSpacing &&
          statusBarLeadingSpacing == other.statusBarLeadingSpacing &&
          gestureBarWidthRatio == other.gestureBarWidthRatio &&
          gestureBarWidth == other.gestureBarWidth &&
          landscapeGestureBarWidth == other.landscapeGestureBarWidth &&
          gestureBarHeight == other.gestureBarHeight &&
          gestureBarOffset == other.gestureBarOffset &&
          gestureBarRadius == other.gestureBarRadius &&
          gestureBarAreaHeight == other.gestureBarAreaHeight &&
          landscapeGestureBarAreaHeight ==
              other.landscapeGestureBarAreaHeight &&
          screenAspectWidth == other.screenAspectWidth &&
          screenAspectHeight == other.screenAspectHeight &&
          containerStyle == other.containerStyle;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    railColor,
    railGradient,
    borderColor,
    borderWidth,
    rimHighlightColor,
    rimHighlightWidth,
    rimHighlightInset,
    rimGlowGradient,
    rimGlowOpacity,
    rimGlowWidth,
    rimGlowTopInset,
    rimGlowBottomInset,
    rimGlowBlur,
    bezelColor,
    bezelBorderColor,
    bezelBorderWidth,
    bezelInnerShadowColor,
    bezelInnerShadowBlur,
    bezelInnerShadowSpread,
    buttonColor,
    buttonLengthGradient,
    buttonDepthColor,
    lensColor,
    cutoutColor,
    coreGradient,
    lensHighlightColor,
    gestureBarColor,
    statusBarIconColor,
    statusBarBatteryBorderColor,
    statusBarBatteryCapColor,
    statusBarTextStyle,
    borderRadius,
    railWidth,
    bezelWidth,
    cameraPlacement,
    cameraWidth,
    cameraHeight,
    cameraOffset,
    lensSize,
    lensOffset,
    cameraCoreSize,
    lensHighlightSizeRatio,
    lensHighlightOffsetXRatio,
    lensHighlightOffsetYRatio,
    buttonThickness,
    buttonProtrusion,
    powerButtonLength,
    powerButtonOffset,
    volumeButtonLength,
    volumeButtonOffset,
    volumeButtonSpacing,
    landscapePowerButtonLength,
    landscapePowerButtonOffset,
    landscapeVolumeButtonLength,
    landscapeVolumeButtonOffset,
    antennaGradient,
    antennaOpacity,
    antennaBandLength,
    antennaSideNearOffset,
    antennaSideFarOffset,
    antennaTopOffset,
    antennaBottomOffset,
    systemBarReferenceWidth,
    systemBarReferenceScale,
    landscapeSystemBarReferenceWidth,
    landscapeSystemBarReferenceScale,
    statusBarHeight,
    landscapeStatusBarHeight,
    statusBarInset,
    statusBarContentCenter,
    statusBarWingWidth,
    statusBarTrailingInset,
    statusBarTrailingSpacing,
    statusBarClockSpacing,
    statusBarLeadingSpacing,
    gestureBarWidthRatio,
    gestureBarWidth,
    landscapeGestureBarWidth,
    gestureBarHeight,
    gestureBarOffset,
    gestureBarRadius,
    gestureBarAreaHeight,
    landscapeGestureBarAreaHeight,
    screenAspectWidth,
    screenAspectHeight,
    containerStyle,
  ]);
}
