import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';

/// How far a blurred shadow reaches past its own box, in sigmas. A Gaussian
/// is as good as gone three standard deviations out — the bound a renderer
/// sizes a blur's canvas by.
const double _kBlurReachSigmas = 3;

/// Paint-ready resolver output for Flutter `MockupFoldable`.
///
/// Widget tree (`mockup_foldable.dart` decides which parts render at the
/// angle it is drawn at):
///
/// ```text
/// Align (top centre)
///   └─ SizedBox (width × height)                       // the stage
///        └─ Stacks (unclipped)
///             ├─ SnapshotWidget                         // the open body
///             │    └─ MockupDevice ← innerDeviceStyle   // * live when flat,
///             │         └─ screen                       //   two halves when bent
///             │              ├─ content                 // clear of the island
///             │              └─ island                  // ← ResolvedMockupFoldableIsland
///             ├─ Transform → CustomPaint (edgeColor)    // right slab's edge
///             ├─ Transform → CustomPaint (edgeColor)    // left slab's edge
///             └─ Transform                              // the cover
///                  └─ Stacks
///                       ├─ MockupDevice ← coverDeviceStyle
///                       │    └─ screen (content, island)
///                       ├─ screen-off scrim (coverScreenRect)
///                       └─ shade (coverBorderRadius)
/// ```
///
/// Every length has `theme.scaling` applied. The two nested device styles are
/// forwarded as they are: each `MockupDevice` resolves and scales its own.
/// What stands on a face's screen — its status island — is resolved apart,
/// by [resolveMockupFoldableIsland], from inside that screen.
@immutable
class ResolvedMockupFoldable {
  /// Creates a [ResolvedMockupFoldable].
  const ResolvedMockupFoldable({
    required this.width,
    required this.height,
    required this.hingeX,
    required this.thickness,
    required this.perspective,
    required this.innerDeviceWidth,
    required this.innerDeviceStyle,
    required this.innerOverflow,
    required this.innerBorderRadius,
    required this.innerScreenRect,
    required this.innerScreenBorderRadius,
    required this.coverWidth,
    required this.coverDeviceWidth,
    required this.coverDeviceStyle,
    required this.coverBorderRadius,
    required this.coverScreenRect,
    required this.coverScreenBorderRadius,
    required this.edgeColor,
    required this.screenOffColor,
    required this.shadeColor,
    required this.shadeOpacity,
    required this.duration,
    required this.curve,
  });

  /// Width of the stage — the open body's (logical px, scaling pre-applied).
  final double width;

  /// Height of the stage — the open body's, and the cover's (scaling
  /// pre-applied).
  final double height;

  /// Where the hinge runs, from the stage's left edge (scaling pre-applied).
  final double hingeX;

  /// How deep each slab is (scaling pre-applied).
  final double thickness;

  /// How far away the device is seen from, in open-body widths — a ratio,
  /// so it carries no scaling.
  final double perspective;

  /// The `width` handed to the open body's `MockupDevice`. Unscaled: the
  /// device applies `theme.scaling` itself.
  final double innerDeviceWidth;

  /// The open body's style, forwarded to its `MockupDevice` as it is.
  final CoreMockupDeviceStyle innerDeviceStyle;

  /// How far the open body paints past its own box on each side — its
  /// buttons and its cast shadow. The picture taken of it while it is bent
  /// is this much larger, so neither is cut off.
  final EdgeInsets innerOverflow;

  /// The open body's corners, as its `MockupDevice` draws them.
  final BorderRadius innerBorderRadius;

  /// The inner screen, measured from the stage's top-left corner.
  final Rect innerScreenRect;

  /// The inner screen's corners, as its `MockupDevice` draws them.
  final BorderRadius innerScreenBorderRadius;

  /// Width of the cover — half the stage (scaling pre-applied).
  final double coverWidth;

  /// The `width` handed to the cover's `MockupDevice`. Unscaled: the device
  /// applies `theme.scaling` itself.
  final double coverDeviceWidth;

  /// The cover's style, forwarded to its `MockupDevice` as it is.
  final CoreMockupDeviceStyle coverDeviceStyle;

  /// The cover's corners, as its `MockupDevice` draws them.
  final BorderRadius coverBorderRadius;

  /// The cover screen, measured from the cover's top-left corner.
  final Rect coverScreenRect;

  /// The cover screen's corners, as its `MockupDevice` draws them.
  final BorderRadius coverScreenBorderRadius;

  /// The colour of a slab's outer edge.
  final Color edgeColor;

  /// The colour laid over a screen that is off.
  final Color screenOffColor;

  /// The colour laid over a half that is turned away from the viewer.
  final Color shadeColor;

  /// How strong the shade is over a half seen edge on, 0 to 1.
  final double shadeOpacity;

  /// How long the device takes to reach a new angle. Zero when the style
  /// says so or the user asked for reduced motion.
  final Duration duration;

  /// The easing of the move to a new angle.
  final Curve curve;
}

/// Paint-ready resolver output for the status island of one screen of a
/// Flutter `MockupFoldable`.
///
/// Widget tree, inside the face's `MockupDevice` screen (`mockup_foldable.dart`
/// leaves out the parts whose box is `null`):
///
/// ```text
/// MediaQuery (padding ← contentPadding)
///   └─ Stacks
///        ├─ SafeArea → content                         // clear of the column
///        └─ IgnorePointer → ExcludeSemantics           // the island
///             └─ Stacks
///                  ├─ camera (cameraRect, cameraColor)  // * the cover only
///                  ├─ clock (clockRect) → Text (clockText, clockTextStyle)
///                  └─ indicator (indicatorRect)
///                       └─ CustomPaint (ringPath, dotsPath)
/// ```
///
/// Every box is in the screen's own space — origin at its top-left corner —
/// with `theme.scaling` applied. The clock's text is the role at the island's
/// own scale and carries no `theme.scaling`: the text axis is the theme
/// typography's.
@immutable
class ResolvedMockupFoldableIsland {
  /// Creates a [ResolvedMockupFoldableIsland].
  const ResolvedMockupFoldableIsland({
    required this.contentPadding,
    required this.cameraRect,
    required this.cameraColor,
    required this.clockRect,
    required this.clockText,
    required this.clockTextStyle,
    required this.indicatorRect,
    required this.ringPath,
    required this.ringColor,
    required this.dotsPath,
    required this.dotsColor,
  });

  /// The room the content keeps clear of the island: the column's width, on
  /// the screen's right.
  final EdgeInsets contentPadding;

  /// The camera's box; `null` where no camera shows.
  final Rect? cameraRect;

  /// The camera's fill.
  final Color cameraColor;

  /// The box the clock's words are centred in; `null` where no status shows.
  final Rect? clockRect;

  /// The clock's words.
  final String clockText;

  /// The clock's text style, at the island's scale.
  final TextStyle clockTextStyle;

  /// The status indicator's box; `null` where no status shows.
  final Rect? indicatorRect;

  /// The indicator's ring and the glyph inside it, sized to [indicatorRect];
  /// `null` with it.
  final Path? ringPath;

  /// The colour [ringPath] is filled with.
  final Color ringColor;

  /// The indicator's dots, sized to [indicatorRect]; `null` with it.
  final Path? dotsPath;

  /// The colour [dotsPath] is filled with.
  final Color dotsColor;
}

/// Single entry-point resolver for Flutter `MockupFoldable`.
///
/// Resolves the standard nested-merge chain into a paint-ready
/// [ResolvedMockupFoldable]:
///
/// ```text
/// CoreMockupFoldableStyle.defaultX                    // design system
///   → CoreMockupFoldableTheme.style                   // 프로젝트 공통
///   → widget.mockupFoldableStyle                      // 인스턴스별
/// ```
///
/// The sizes of the two faces come from [CoreMockupFoldableLayout.compute],
/// the rule set both platforms share. What each face then draws — where its
/// screen sits, how round it is, how far its buttons and shadow reach — is
/// read back from the face's own resolvers, so a scrim laid over a screen
/// lands on exactly the box the `MockupDevice` paints.
///
/// The semantic [widgetWidth] is a widget prop — the theme cannot override
/// it; the widget supplies the design-system fallback
/// (`CoreMockupFoldableStyle.defaultWidth`) on the widget edge.
ResolvedMockupFoldable resolveMockupFoldable(
  BuildContext context, {
  required double widgetWidth,
  CoreMockupFoldableStyle? mockupFoldableStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;

  final merged = _mergeChain(theme, mockupFoldableStyle);

  // ─── Stage 1 RESOLVE (Flutter = Web) ─────────────────
  final settledEdgeColor =
      merged.edgeColor ?? CoreMockupFoldableStyle.defaultEdgeColor;
  final settledScreenOffColor =
      merged.screenOffColor ?? CoreMockupFoldableStyle.defaultScreenOffColor;
  final settledShadeColor =
      merged.shadeColor ?? CoreMockupFoldableStyle.defaultShadeColor;
  final shadeOpacity =
      merged.shadeOpacity ?? CoreMockupFoldableStyle.defaultShadeOpacity;
  final settledDuration =
      merged.duration ?? CoreMockupFoldableStyle.defaultDuration;
  final settledCurve = merged.curve ?? CoreMockupFoldableStyle.defaultCurve;
  final layout = _layoutOf(merged, widgetWidth: widgetWidth);
  final perspective = layout.perspective;
  final innerDeviceStyle = layout.innerDeviceStyle;
  final coverDeviceStyle = layout.coverDeviceStyle;
  final innerDeviceWidth = layout.width;
  final coverDeviceWidth = layout.coverWidth;

  // ─── The faces' own geometry — what each `MockupDevice` draws ──
  final inner = resolveMockupDevice(
    context,
    device: CoreMockupFoldableLayout.innerDevice,
    orientation: CoreMockupFoldableLayout.innerOrientation,
    widgetWidth: innerDeviceWidth,
    mockupDeviceStyle: innerDeviceStyle,
  );
  final innerBody = resolveOutlinedContainer(
    context,
    containerStyle: inner.containerStyle,
  );
  final cover = resolveMockupDevice(
    context,
    device: CoreMockupFoldableLayout.coverDevice,
    orientation: CoreMockupFoldableLayout.coverOrientation,
    widgetWidth: coverDeviceWidth,
    mockupDeviceStyle: coverDeviceStyle,
  );
  final coverBody = resolveOutlinedContainer(
    context,
    containerStyle: cover.containerStyle,
  );

  // ─── Stage 2 EMIT — geometry, scaling pre-applied ────
  final width = inner.width;
  final height = inner.height;
  final hingeX = layout.hingeX * scaling;
  final thickness = layout.thickness * scaling;
  final coverWidth = cover.width;
  final innerBorderRadius = innerBody.borderRadius;
  final coverBorderRadius = coverBody.borderRadius;
  // A device states its screen inside its bezel box; the stage wants it
  // from the body's corner.
  final innerScreenRect = inner.screenRect.shift(inner.bezelRect.topLeft);
  final innerScreenBorderRadius = inner.screenBorderRadius;
  final coverScreenRect = cover.screenRect.shift(cover.bezelRect.topLeft);
  final coverScreenBorderRadius = cover.screenBorderRadius;
  final innerOverflow = _overflowOf(
    Offset.zero & Size(width, height),
    buttons: [inner.powerButton, inner.volumeUpButton, inner.volumeDownButton],
    shadows: innerBody.boxShadow,
  );

  // ─── Stage 2 EMIT — colours through the active scheme ─
  final edgeColor = scheme.resolve(settledEdgeColor).toValue();
  final screenOffColor = scheme.resolve(settledScreenOffColor).toValue();
  final shadeColor = scheme.resolve(settledShadeColor).toValue();

  // ─── Stage 2 EMIT — motion ───────────────────────────
  final duration = resolveMotionDuration(context, settledDuration);
  final curve = settledCurve.toValue();

  return ResolvedMockupFoldable(
    width: width,
    height: height,
    hingeX: hingeX,
    thickness: thickness,
    perspective: perspective,
    innerDeviceWidth: innerDeviceWidth,
    innerDeviceStyle: innerDeviceStyle,
    innerOverflow: innerOverflow,
    innerBorderRadius: innerBorderRadius,
    innerScreenRect: innerScreenRect,
    innerScreenBorderRadius: innerScreenBorderRadius,
    coverWidth: coverWidth,
    coverDeviceWidth: coverDeviceWidth,
    coverDeviceStyle: coverDeviceStyle,
    coverBorderRadius: coverBorderRadius,
    coverScreenRect: coverScreenRect,
    coverScreenBorderRadius: coverScreenBorderRadius,
    edgeColor: edgeColor,
    screenOffColor: screenOffColor,
    shadeColor: shadeColor,
    shadeOpacity: shadeOpacity,
    duration: duration,
    curve: curve,
  );
}

/// Resolver for the status island of one [screen] of a Flutter
/// `MockupFoldable`, or `null` when that screen shows none.
///
/// The island is the operating system's, drawn on the screen: its colours and
/// its type are the screen's own. A screen may run in a brightness of its own
/// (`MockupFoldable.screenBrightness`), and only a context inside the screen
/// sees that theme — so the island is resolved from there, by the widget that
/// draws it, apart from [resolveMockupFoldable]. Both settle the style by the
/// same chain and size the device by the same layout.
///
/// [showCamera] and [showStatus] are the widget's flags. The cover's island
/// starts with its camera; the inner screen has none.
ResolvedMockupFoldableIsland? resolveMockupFoldableIsland(
  BuildContext context, {
  required CoreMockupFoldScreen screen,
  required double widgetWidth,
  required bool showCamera,
  required bool showStatus,
  CoreMockupFoldableStyle? mockupFoldableStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;

  final merged = _mergeChain(theme, mockupFoldableStyle);

  // ─── Stage 1 RESOLVE (Flutter = Web) ─────────────────
  final island = _layoutOf(merged, widgetWidth: widgetWidth).islandOf(
    screen,
    showCamera: showCamera,
    showStatus: showStatus,
  );
  if (island == null) return null;

  final settledCameraColor =
      merged.islandCameraColor ??
      CoreMockupFoldableStyle.defaultIslandCameraColor;
  final settledTextStyle = CoreMockupFoldableStyle.defaultIslandTextStyle.merge(
    merged.islandTextStyle,
  );
  final settledIconColor =
      merged.islandIconColor ?? CoreMockupFoldableStyle.defaultIslandIconColor;
  final settledDotColor =
      merged.islandDotColor ?? CoreMockupFoldableStyle.defaultIslandDotColor;

  // ─── Stage 2 EMIT — geometry, scaling pre-applied ────
  final contentPadding = EdgeInsets.only(right: island.column.width * scaling);
  final cameraRect = _scaledRect(island.camera, scaling);
  final clockRect = _scaledRect(island.clock, scaling);
  final indicatorRect = _scaledRect(island.indicator, scaling);
  final ringPath = indicatorRect == null
      ? null
      : CoreMockupFoldableStyle.islandRingGlyph.toPath(indicatorRect.size);
  final dotsPath = indicatorRect == null
      ? null
      : CoreMockupFoldableStyle.islandDotsGlyph.toPath(indicatorRect.size);

  // ─── Stage 2 EMIT — the clock, at the island's scale ─
  // The role's size times the island's scale (iOS points → px), and not
  // times `scaling`: the text axis is the theme typography's, which is
  // already pre-scaled. Tracking is materialised as px against the role's
  // size, so it takes the same factor; leading is a ratio and stays.
  final role = settledTextStyle.toValue(theme: theme);
  final roleSize = role.fontSize;
  final roleTracking = role.letterSpacing;
  final clockTextStyle = role.copyWith(
    fontSize: roleSize == null ? null : roleSize * island.scale,
    letterSpacing: roleTracking == null ? null : roleTracking * island.scale,
  );
  // The clock's words are sample content, the same on both platforms.
  const clockText = CoreMockupFoldableStyle.sampleTime;

  // ─── Stage 2 EMIT — colours through the active scheme ─
  final cameraColor = scheme.resolve(settledCameraColor).toValue();
  final ringColor = scheme.resolve(settledIconColor).toValue();
  final dotsColor = scheme.resolve(settledDotColor).toValue();

  return ResolvedMockupFoldableIsland(
    contentPadding: contentPadding,
    cameraRect: cameraRect,
    cameraColor: cameraColor,
    clockRect: clockRect,
    clockText: clockText,
    clockTextStyle: clockTextStyle,
    indicatorRect: indicatorRect,
    ringPath: ringPath,
    ringColor: ringColor,
    dotsPath: dotsPath,
    dotsColor: dotsColor,
  );
}

/// The merge chain both resolvers settle the style by — one function, so the
/// island cannot be resolved by another chain than the device it stands on.
CoreMockupFoldableStyle _mergeChain(
  ThemeData theme,
  CoreMockupFoldableStyle? mockupFoldableStyle,
) => resolveStyleChain(const CoreMockupFoldableStyle(), [
  theme.coreComponentTheme?.mockupFoldable?.style,
  mockupFoldableStyle,
]);

/// The shared layout of a device [widgetWidth] wide under [merged] — the
/// sizes of the two faces and where each screen's island stands.
CoreMockupFoldableLayout _layoutOf(
  CoreMockupFoldableStyle merged, {
  required double widgetWidth,
}) => CoreMockupFoldableLayout.compute(
  width: widgetWidth,
  innerDeviceStyle: CoreMockupFoldableStyle.defaultInnerDeviceStyle.merge(
    merged.innerDeviceStyle,
  ),
  coverDeviceStyle: CoreMockupFoldableStyle.defaultCoverDeviceStyle.merge(
    merged.coverDeviceStyle,
  ),
  thickness: merged.thickness ?? CoreMockupFoldableStyle.defaultThickness,
  perspective: merged.perspective ?? CoreMockupFoldableStyle.defaultPerspective,
  islandWidth: merged.islandWidth ?? CoreMockupFoldableStyle.defaultIslandWidth,
  islandOffset:
      merged.islandOffset ?? CoreMockupFoldableStyle.defaultIslandOffset,
  islandCameraSize:
      merged.islandCameraSize ??
      CoreMockupFoldableStyle.defaultIslandCameraSize,
);

/// A layout box at `scaling`; `null` stays `null`.
Rect? _scaledRect(CoreMockupDeviceRect? rect, double scaling) => rect == null
    ? null
    : Rect.fromLTWH(
        rect.left * scaling,
        rect.top * scaling,
        rect.width * scaling,
        rect.height * scaling,
      );

/// How far a device paints past [body] on each side: its [buttons], which
/// protrude on purpose, and its cast [shadows], each reaching as far as its
/// offset, its spread and its blur carry it. Rounded up to whole pixels, so
/// the picture's box does not cut a part of one.
EdgeInsets _overflowOf(
  Rect body, {
  required List<ResolvedMockupButton?> buttons,
  required List<BoxShadow> shadows,
}) {
  var reach = body;
  for (final button in buttons) {
    if (button != null) reach = reach.expandToInclude(button.rect);
  }
  for (final shadow in shadows) {
    reach = reach.expandToInclude(
      body
          .shift(shadow.offset)
          .inflate(
            shadow.spreadRadius + shadow.blurSigma * _kBlurReachSigmas,
          ),
    );
  }

  return .fromLTRB(
    math.max(body.left - reach.left, 0).ceilToDouble(),
    math.max(body.top - reach.top, 0).ceilToDouble(),
    math.max(reach.right - body.right, 0).ceilToDouble(),
    math.max(reach.bottom - body.bottom, 0).ceilToDouble(),
  );
}
