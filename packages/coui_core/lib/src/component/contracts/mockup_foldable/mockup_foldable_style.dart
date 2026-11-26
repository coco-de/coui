/// Per-instance style for `MockupFoldable`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_device_style.dart';
import 'package:coui_core/src/component/contracts/mockup_foldable/mockup_foldable_glyphs.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/motion/easing_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/vector_glyph.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `MockupFoldable` — a device that folds
/// down its middle — is drawn.
///
/// The body is not drawn here: open it is a `MockupDevice` tablet on its
/// side, and the back of its left half is a `MockupDevice` phone. Their looks
/// come through the two nested slots ([innerDeviceStyle],
/// [coverDeviceStyle]). The fields stated here are what a folding device adds
/// to them — how deep the halves are, how far away the device is seen from,
/// what a turned half and a dark screen look like, how the fold moves, and
/// the status island: the column at the screen's right edge that holds the
/// cover's camera, the clock and the status indicator, where a slab phone has
/// a status bar across the top.
///
/// The island is the operating system's, like the device's status bar: every
/// `island*` length is in iOS points, drawn at the scale the face it stands
/// on draws its own system lengths at (the nested style's
/// `systemBarReferenceScale`, or its landscape counterpart for the open
/// body).
///
/// ### Resolve chain.
///
/// ```text
/// design system default (this class' `static const defaultX`)
///   → CoreMockupFoldableTheme.style                // 프로젝트 공통
///   → widget.mockupFoldableStyle                   // 인스턴스별
/// ```
///
/// What stays on the widget: the content (`child`), how far the device is
/// folded (`foldAngle`), its `width`, whether the camera, the status and the
/// gesture bar show, and the screen brightness it passes on to both faces.
@immutable
class CoreMockupFoldableStyle implements CoreStyle<CoreMockupFoldableStyle> {
  /// Creates a [CoreMockupFoldableStyle].
  const CoreMockupFoldableStyle({
    this.innerDeviceStyle,
    this.coverDeviceStyle,
    this.thickness,
    this.perspective,
    this.edgeColor,
    this.screenOffColor,
    this.shadeColor,
    this.shadeOpacity,
    this.islandWidth,
    this.islandOffset,
    this.islandCameraSize,
    this.islandCameraColor,
    this.islandTextStyle,
    this.islandIconColor,
    this.islandDotColor,
    this.duration,
    this.curve,
  });

  // ─── Design-system defaults ───────────────────────────

  /// Default width of the open body (logical px) — a semantic layout knob,
  /// like `CoreMockupDeviceStyle.defaultWidth`. The cover is half of it.
  static const double defaultWidth = 480;

  /// The scale the default faces draw the operating system's lengths at (iOS
  /// points → logical px): the scale at which the default body's inner
  /// screen, 458 wide, stands for a 958-point screen.
  ///
  /// It does not follow the width — a wider device is a larger screen, not a
  /// larger drawing — like every system length of `MockupDevice`.
  static const double defaultSystemScale = 0.478;

  // The body's own colours: graphite, darker than the kit's device. Literal
  // and mode-invariant, for the reason `CoreMockupDeviceStyle` gives — a
  // device does not change colour with the theme.
  //
  // The body is a solid, not a gradient like the kit's device: a stated
  // gradient wins over a stated colour
  // (`CoreMockupDeviceStyle.resolveBodyGradient`), so a default gradient here
  // would leave a caller's `railColor` on either face without effect.
  static const CoreColor _bodyColor = CoreColor(0xFF575757);
  static const CoreColor _bodyBorderColor = CoreColor(0xFF464646);
  static const CoreColor _buttonColor = CoreColor(0xFF6A6A6A);

  /// Default style of the open body: the kit's tablet with what makes it this
  /// device stated over it — a graphite body with rounder corners and no rim
  /// light, two volume buttons on the top edge and the power button on the
  /// right one, all on the half that does not fold over, and the system
  /// scale ([defaultSystemScale]).
  static const CoreMockupDeviceStyle defaultInnerDeviceStyle =
      CoreMockupDeviceStyle(
        railColor: _bodyColor,
        borderColor: _bodyBorderColor,
        buttonColor: _buttonColor,
        rimHighlightWidth: 0,
        rimGlowWidth: 0,
        borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
        // Fractions of the edge each button sits on (device geometry): the
        // volume pair starts 72% along the top edge, the power button 28%
        // down the right edge.
        landscapeVolumeButtonLength: CoreSize.size32,
        landscapeVolumeButtonOffset: 0.72,
        volumeButtonSpacing: CoreSpace.space6,
        landscapePowerButtonLength: 54,
        landscapePowerButtonOffset: 0.28,
        landscapeSystemBarReferenceScale: defaultSystemScale,
      );

  /// Default style of the cover: the kit's phone in the same graphite, without
  /// what the back of a folding half does not carry — no buttons and no
  /// antenna bands. A zero length is how a device says "none". Its camera is
  /// the island's, not the phone's own.
  static const CoreMockupDeviceStyle defaultCoverDeviceStyle =
      CoreMockupDeviceStyle(
        railColor: _bodyColor,
        borderColor: _bodyBorderColor,
        rimHighlightWidth: 0,
        rimGlowWidth: 0,
        powerButtonLength: 0,
        volumeButtonLength: 0,
        volumeButtonSpacing: 0,
        landscapePowerButtonLength: 0,
        landscapeVolumeButtonLength: 0,
        antennaBandLength: 0,
        systemBarReferenceScale: defaultSystemScale,
      );

  /// Default depth of each half (logical px). Device geometry: it does not
  /// follow the width, like the rest of the hardware.
  static const double defaultThickness = CoreSize.size12;

  /// Default viewing distance, in open-body widths. Far enough that a half
  /// turned edge on still reads as a slab rather than a wedge.
  static const double defaultPerspective = 2.5;

  /// Default colour of a half's outer edge — the body's own colour.
  static const CoreColor defaultEdgeColor = _bodyColor;

  /// Default colour of a screen that is off — the bezel's black, so a dark
  /// screen and the glass around it read as one.
  static const CoreColor defaultScreenOffColor =
      CoreMockupDeviceStyle.defaultBezelColor;

  /// Default colour laid over a half that is turned away from the viewer.
  static const CoreColor defaultShadeColor =
      CoreMockupDeviceStyle.defaultBezelColor;

  /// Default strength of the shade over a half seen edge on.
  static const double defaultShadeOpacity = CoreOpacity.opacity40;

  /// Default width of the island's column (iOS points) — the room at the
  /// screen's right edge the content keeps clear.
  static const double defaultIslandWidth = CoreSize.size96;

  /// Default distance from the screen's top edge to the island's first part
  /// (iOS points). Device geometry, off the ladders.
  static const double defaultIslandOffset = 30;

  /// Default diameter of the cover's camera (iOS points).
  static const double defaultIslandCameraSize = CoreSize.size36;

  /// Default fill of the cover's camera — the device's lens black, the same
  /// in every mode.
  static const CoreColor defaultIslandCameraColor =
      CoreMockupDeviceStyle.defaultLensColor;

  /// Default text style of the island's clock — the role a phone's status
  /// bar sets its clock in, in `on-surface`, so it flips with the screen.
  static const CoreTextStyle defaultIslandTextStyle = CoreTextStyle.token(
    CoreTextStyles.titleSmall,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default colour of the status indicator's ring and glyph — `on-surface`,
  /// with the clock.
  static const CoreColor defaultIslandIconColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default colour of the status indicator's dots — `on-surface` at 30%.
  static const CoreColor defaultIslandDotColor = CoreColor.token(
    CoreColors.onSurface,
    opacity: CoreOpacity.opacity30,
  );

  /// Default length of the fold — `CoreDuration.slow`, the longest a
  /// transition runs, so the reduced-motion setting turns it off.
  static const Duration defaultDuration = Duration(
    milliseconds: CoreDuration.slow,
  );

  /// Default easing of the fold — `CoreEasing.move`.
  static const CoreCubicBezier defaultCurve = CoreEasing.move;

  // ─── Fixed island content — not overridable ───────────
  // What the island shows is sample content, as a `MockupDevice`'s status bar
  // is: an operating system caught at one moment. The clock's words and the
  // indicator's drawing are stated once and read by both platforms.

  /// The clock the island shows — the one `MockupDevice` shows.
  static const String sampleTime = CoreMockupDeviceStyle.sampleTime;

  /// The status indicator's ring and the wifi glyph inside it.
  static const CoreVectorGlyph islandRingGlyph =
      CoreMockupFoldableGlyphs.statusRing;

  /// The four dots that close the status indicator's ring.
  static const CoreVectorGlyph islandDotsGlyph =
      CoreMockupFoldableGlyphs.statusDots;

  /// The side of the box the status indicator is drawn in (iOS points).
  static const double islandIndicatorSize = CoreMockupFoldableGlyphs.statusBox;

  /// The height of the line the clock is centred in (iOS points) — the line
  /// box of the default role.
  static const double islandClockHeight = 22;

  /// The gap between the cover's camera and the clock under it (iOS points).
  /// The island is one unit, so the gaps inside it are the drawing's own.
  static const double islandCameraGap = CoreSpace.space16;

  /// The gap between the clock and the status indicator under it (iOS
  /// points).
  static const double islandClockGap = CoreSpace.space6;

  // ─── Instance override slots ──────────────────────────

  /// The look of the open body — the tablet the device is when unfolded.
  /// `null` leaves this device's own body: graphite, with rounder corners
  /// than the kit's tablet.
  ///
  /// Laid over [defaultInnerDeviceStyle] and handed to the `MockupDevice`
  /// that draws the open body, which fills in the rest.
  final CoreMockupDeviceStyle? innerDeviceStyle;

  /// The look of the cover — the phone on the back of the half that folds
  /// over. `null` leaves this device's own cover: graphite, with no buttons
  /// or antenna bands.
  ///
  /// Laid over [defaultCoverDeviceStyle] and handed to the `MockupDevice`
  /// that draws the cover, which fills in the rest. Its size is not a
  /// choice: the cover is half the open body wide and as tall.
  final CoreMockupDeviceStyle? coverDeviceStyle;

  /// How deep each half is, in logical px — the strip that shows when a half
  /// is seen edge on. `null` uses
  /// `CoreMockupFoldableStyle.defaultThickness`.
  final double? thickness;

  /// How far away the device is seen from, in open-body widths. A smaller
  /// value exaggerates the depth of a half turned towards the viewer.
  /// `null` uses
  /// `CoreMockupFoldableStyle.defaultPerspective`.
  final double? perspective;

  /// The colour of a half's outer edge. `null` uses
  /// `CoreMockupFoldableStyle.defaultEdgeColor`.
  final CoreColor? edgeColor;

  /// The colour of a screen that is off: the cover while the device is open,
  /// the inner screen while it is shut. `null` uses
  /// `CoreMockupFoldableStyle.defaultScreenOffColor`.
  final CoreColor? screenOffColor;

  /// The colour laid over a half that is turned away from the viewer.
  /// `null` uses
  /// `CoreMockupFoldableStyle.defaultShadeColor`.
  final CoreColor? shadeColor;

  /// How strong the shade is over a half seen edge on, 0 to 1; a half facing
  /// the viewer has none. `null` uses
  /// `CoreMockupFoldableStyle.defaultShadeOpacity`.
  final double? shadeOpacity;

  /// How wide the column at the screen's right edge is, in iOS points — the
  /// room the camera, the clock and the status indicator stand in, and the
  /// room the content keeps clear while any of them shows. `null` uses
  /// `CoreMockupFoldableStyle.defaultIslandWidth`.
  final double? islandWidth;

  /// How far below the screen's top edge the island starts, in iOS points.
  /// `null` uses
  /// `CoreMockupFoldableStyle.defaultIslandOffset`.
  final double? islandOffset;

  /// The diameter of the cover's camera, in iOS points. `null` uses
  /// `CoreMockupFoldableStyle.defaultIslandCameraSize`.
  final double? islandCameraSize;

  /// The fill of the cover's camera. `null` uses
  /// `CoreMockupFoldableStyle.defaultIslandCameraColor`.
  final CoreColor? islandCameraColor;

  /// The text style of the island's clock — a role and a colour, set at its
  /// iOS size and drawn at the face's system scale. `null` uses
  /// `CoreMockupFoldableStyle.defaultIslandTextStyle`.
  final CoreTextStyle? islandTextStyle;

  /// The colour of the status indicator's ring and the glyph inside it.
  /// `null` uses
  /// `CoreMockupFoldableStyle.defaultIslandIconColor`.
  final CoreColor? islandIconColor;

  /// The colour of the four dots that close the status indicator's ring.
  /// `null` uses
  /// `CoreMockupFoldableStyle.defaultIslandDotColor`.
  final CoreColor? islandDotColor;

  /// How long the device takes to reach a new fold angle. Zero follows the
  /// angle at once, which is what a slider driving it wants. `null` uses
  /// `CoreMockupFoldableStyle.defaultDuration`.
  final Duration? duration;

  /// The easing of the move to a new fold angle. `null` uses
  /// `CoreMockupFoldableStyle.defaultCurve`.
  final CoreCubicBezier? curve;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. The two nested device styles and
  /// the clock's text style are merged recursively, so a partial override
  /// only replaces what it states.
  @override
  CoreMockupFoldableStyle merge(CoreMockupFoldableStyle? other) {
    if (other == null) return this;

    return CoreMockupFoldableStyle(
      innerDeviceStyle:
          innerDeviceStyle?.merge(other.innerDeviceStyle) ??
          other.innerDeviceStyle,
      coverDeviceStyle:
          coverDeviceStyle?.merge(other.coverDeviceStyle) ??
          other.coverDeviceStyle,
      thickness: other.thickness ?? thickness,
      perspective: other.perspective ?? perspective,
      edgeColor: other.edgeColor ?? edgeColor,
      screenOffColor: other.screenOffColor ?? screenOffColor,
      shadeColor: other.shadeColor ?? shadeColor,
      shadeOpacity: other.shadeOpacity ?? shadeOpacity,
      islandWidth: other.islandWidth ?? islandWidth,
      islandOffset: other.islandOffset ?? islandOffset,
      islandCameraSize: other.islandCameraSize ?? islandCameraSize,
      islandCameraColor: other.islandCameraColor ?? islandCameraColor,
      islandTextStyle:
          islandTextStyle?.merge(other.islandTextStyle) ??
          other.islandTextStyle,
      islandIconColor: other.islandIconColor ?? islandIconColor,
      islandDotColor: other.islandDotColor ?? islandDotColor,
      duration: other.duration ?? duration,
      curve: other.curve ?? curve,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreMockupFoldableStyle copyWith({
    CoreMockupDeviceStyle? innerDeviceStyle,
    CoreMockupDeviceStyle? coverDeviceStyle,
    double? thickness,
    double? perspective,
    CoreColor? edgeColor,
    CoreColor? screenOffColor,
    CoreColor? shadeColor,
    double? shadeOpacity,
    double? islandWidth,
    double? islandOffset,
    double? islandCameraSize,
    CoreColor? islandCameraColor,
    CoreTextStyle? islandTextStyle,
    CoreColor? islandIconColor,
    CoreColor? islandDotColor,
    Duration? duration,
    CoreCubicBezier? curve,
  }) {
    return CoreMockupFoldableStyle(
      innerDeviceStyle: innerDeviceStyle ?? this.innerDeviceStyle,
      coverDeviceStyle: coverDeviceStyle ?? this.coverDeviceStyle,
      thickness: thickness ?? this.thickness,
      perspective: perspective ?? this.perspective,
      edgeColor: edgeColor ?? this.edgeColor,
      screenOffColor: screenOffColor ?? this.screenOffColor,
      shadeColor: shadeColor ?? this.shadeColor,
      shadeOpacity: shadeOpacity ?? this.shadeOpacity,
      islandWidth: islandWidth ?? this.islandWidth,
      islandOffset: islandOffset ?? this.islandOffset,
      islandCameraSize: islandCameraSize ?? this.islandCameraSize,
      islandCameraColor: islandCameraColor ?? this.islandCameraColor,
      islandTextStyle: islandTextStyle ?? this.islandTextStyle,
      islandIconColor: islandIconColor ?? this.islandIconColor,
      islandDotColor: islandDotColor ?? this.islandDotColor,
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMockupFoldableStyle &&
          runtimeType == other.runtimeType &&
          innerDeviceStyle == other.innerDeviceStyle &&
          coverDeviceStyle == other.coverDeviceStyle &&
          thickness == other.thickness &&
          perspective == other.perspective &&
          edgeColor == other.edgeColor &&
          screenOffColor == other.screenOffColor &&
          shadeColor == other.shadeColor &&
          shadeOpacity == other.shadeOpacity &&
          islandWidth == other.islandWidth &&
          islandOffset == other.islandOffset &&
          islandCameraSize == other.islandCameraSize &&
          islandCameraColor == other.islandCameraColor &&
          islandTextStyle == other.islandTextStyle &&
          islandIconColor == other.islandIconColor &&
          islandDotColor == other.islandDotColor &&
          duration == other.duration &&
          curve == other.curve;

  @override
  int get hashCode => Object.hash(
    innerDeviceStyle,
    coverDeviceStyle,
    thickness,
    perspective,
    edgeColor,
    screenOffColor,
    shadeColor,
    shadeOpacity,
    islandWidth,
    islandOffset,
    islandCameraSize,
    islandCameraColor,
    islandTextStyle,
    islandIconColor,
    islandDotColor,
    duration,
    curve,
  );
}
