import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved parts
// ═══════════════════════════════════════════════════

/// One hardware button: where it stands and its two gradient layers.
///
/// The fill under both gradients is the device's `buttonColor`.
@immutable
class ResolvedMockupButton {
  /// Creates a [ResolvedMockupButton].
  const ResolvedMockupButton({
    required this.rect,
    required this.lengthGradient,
    required this.depthGradient,
  });

  /// The button, body-space (scaling pre-applied). It starts at a negative
  /// coordinate on purpose — that is the protrusion.
  final Rect rect;

  /// The gloss along the button's length.
  final Gradient lengthGradient;

  /// The shade across the button's thickness, darkest at the body side.
  final Gradient depthGradient;
}

/// A hairline stroke drawn along a rounded box with no fill — the rim
/// highlight, the rim glow, the bezel outline and the phone battery's outline.
@immutable
class ResolvedMockupStroke {
  /// Creates a [ResolvedMockupStroke].
  const ResolvedMockupStroke({
    required this.rect,
    required this.borderRadius,
    required this.width,
    this.color,
    this.gradient,
  });

  /// The box the stroke runs along, in the space of whatever paints it
  /// (scaling pre-applied).
  final Rect rect;

  /// The box's corners.
  final BorderRadius borderRadius;

  /// Stroke width (scaling pre-applied).
  final double width;

  /// Solid stroke colour; `null` when the stroke is [gradient].
  final Color? color;

  /// Stroke gradient over [rect]; `null` when the stroke is [color].
  final Gradient? gradient;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedMockupStroke &&
          rect == other.rect &&
          borderRadius == other.borderRadius &&
          width == other.width &&
          color == other.color &&
          gradient == other.gradient;

  @override
  int get hashCode => Object.hash(rect, borderRadius, width, color, gradient);
}

/// One thing a status bar group draws, with scaling pre-applied.
@immutable
sealed class ResolvedMockupStatusBarItem {
  const ResolvedMockupStatusBarItem({required this.gapAfter});

  /// Space between this item and the next one in its group.
  final double gapAfter;
}

/// A piece of sample text — the clock, the date, the battery percentage.
final class ResolvedMockupStatusBarText extends ResolvedMockupStatusBarItem {
  /// Creates a [ResolvedMockupStatusBarText].
  const ResolvedMockupStatusBarText({
    required this.text,
    required this.style,
    required super.gapAfter,
  });

  /// What the text says.
  final String text;

  /// The role style at the bar's own size.
  final TextStyle style;
}

/// A filled vector drawing.
final class ResolvedMockupStatusBarGlyph extends ResolvedMockupStatusBarItem {
  /// Creates a [ResolvedMockupStatusBarGlyph].
  const ResolvedMockupStatusBarGlyph({
    required this.size,
    required this.path,
    required this.color,
    required super.gapAfter,
  });

  /// The box the drawing fills.
  final Size size;

  /// The outline, already scaled to [size] and carrying its fill rule.
  final Path path;

  /// Fill colour.
  final Color color;
}

/// The phone's battery: an outline, a level inside it and a nub beside it.
final class ResolvedMockupStatusBarBattery extends ResolvedMockupStatusBarItem {
  /// Creates a [ResolvedMockupStatusBarBattery].
  const ResolvedMockupStatusBarBattery({
    required this.size,
    required this.outline,
    required this.capacityRect,
    required this.capacityRadius,
    required this.capacityColor,
    required this.capRect,
    required this.capPath,
    required this.capColor,
    required super.gapAfter,
  });

  /// The whole battery's box — outline, gap and nub.
  final Size size;

  /// The outline, relative to the battery's own top-left. Its stroke is
  /// drawn inside its box.
  ///
  /// A stroke of the picture, like the nub's drawing: it is not a border of
  /// the device's chrome, so a surface style's stroke floor does not reach
  /// it (the floor would fill a battery four logical px tall).
  final ResolvedMockupStroke outline;

  /// The level's box, relative to the battery's own top-left.
  final Rect capacityRect;

  /// The level's corners.
  final BorderRadius capacityRadius;

  /// The level's colour.
  final Color capacityColor;

  /// The nub's box, relative to the battery's own top-left.
  final Rect capRect;

  /// The nub's outline, already scaled to [capRect]'s size.
  final Path capPath;

  /// The nub's colour.
  final Color capColor;
}

/// A row of status bar items and the area it lays out in.
@immutable
class ResolvedMockupStatusBarGroup {
  /// Creates a [ResolvedMockupStatusBarGroup].
  const ResolvedMockupStatusBarGroup({
    required this.box,
    required this.alignment,
    required this.contentAlignment,
    required this.items,
  });

  /// The area the row is laid out in, screen-space. It is symmetric about
  /// the bar's content line, so centring the row vertically in it puts
  /// every item on that line.
  final Rect box;

  /// Where along [box]'s width the row sits.
  final MainAxisAlignment alignment;

  /// Alignment of the natural-size decorative row when its box is narrower.
  /// The screen clips overflow, matching the Web and Figma drawings.
  final Alignment contentAlignment;

  /// The row's items, first to last.
  final List<ResolvedMockupStatusBarItem> items;
}

/// The status bar over the top of the screen.
@immutable
class ResolvedMockupStatusBar {
  /// Creates a [ResolvedMockupStatusBar].
  const ResolvedMockupStatusBar({
    required this.rect,
    required this.leading,
    required this.trailing,
  });

  /// The whole bar, screen-space. It is painted opaque in the screen's own
  /// fill so the child cannot show through it.
  final Rect rect;

  /// The group at the leading edge — the clock.
  final ResolvedMockupStatusBarGroup leading;

  /// The group at the trailing edge — signal, wifi and battery.
  final ResolvedMockupStatusBarGroup trailing;
}

// ═══════════════════════════════════════════════════
// ResolvedMockupDevice
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `MockupDevice`.
///
/// Widget tree, back to front (`mockup_device.dart` selects the optional
/// branches):
///
/// ```text
/// Align (topCenter)
///   └─ SizedBox (width)
///        └─ Stacks (clip none — the buttons protrude past the body)
///             ├─ Position (power / volume up / volume down) // buttonColor
///             │    └─ two gradient layers over the solid
///             ├─ OutlinedContainer (containerStyle)        // the body
///             ├─ Position.fill › CustomPaint (rimHighlight)
///             ├─ Position.fill › Opacity › ImageFiltered › CustomPaint
///             │                                           (rimGlow)
///             ├─ Position (antennaBands) * › Opacity       // phone only
///             └─ Position (bezelRect)
///                  └─ Stacks (clip none)
///                       ├─ Position.fill › InsetShadow › DecoratedBox
///                       │                  (bezel fill + outside outline)
///                       ├─ Position (screenRect) › ClipRRect
///                       │    └─ SizedBox › ColoredBox (backgroundColor)
///                       │         └─ Stacks
///                       │              ├─ Position.fill
///                       │              │    └─ MediaQuery › SafeArea › child
///                       │              ├─ status bar            // showStatusBar
///                       │              ├─ camera set            // placement screen
///                       │              └─ Position (gestureBarRect)
///                       └─ camera set                           // placement bezel
/// ```
///
/// The body is a composed `OutlinedContainer` with an explicit size — its
/// fill (a gradient unless a solid was stated) / stroke / radius and the
/// shadow (`defaultBodyShadow` in black at its own alpha, whatever the mode)
/// arrive as `coui_core`
/// domain values in [containerStyle] so that primitive runs its own colour /
/// radius resolution and scaling once. Every other value here is already a
/// Flutter paint type with `theme.scaling` applied — the widget is
/// render-only and never reads `theme.scaling` itself.
///
/// Rectangles are in the coordinate space of the `Stacks` that paints them:
/// buttons, rims, antenna bands and the bezel in the body's; the screen in
/// the bezel's; the status bar, gesture bar and (screen placement) camera
/// set in the screen's; a bezel-placement camera set in the bezel's.
@immutable
class ResolvedMockupDevice {
  /// Creates a [ResolvedMockupDevice].
  const ResolvedMockupDevice({
    required this.containerStyle,
    required this.width,
    required this.height,
    required this.powerButton,
    required this.volumeUpButton,
    required this.volumeDownButton,
    required this.buttonColor,
    required this.buttonBorderRadius,
    required this.rimHighlight,
    required this.rimGlow,
    required this.rimGlowOpacity,
    required this.rimGlowBlurSigma,
    required this.antennaBands,
    required this.antennaGradient,
    required this.antennaOpacity,
    required this.bezelRect,
    required this.bezelColor,
    required this.bezelBorderRadius,
    required this.bezelOutline,
    required this.bezelInnerShadow,
    required this.screenRect,
    required this.screenBorderRadius,
    required this.backgroundColor,
    required this.cameraPlacement,
    required this.cameraColor,
    required this.cameraRect,
    required this.cameraBorderRadius,
    required this.lensColor,
    required this.lensRect,
    required this.lensBorderRadius,
    required this.cutoutColor,
    required this.coreGradient,
    required this.coreRect,
    required this.coreBorderRadius,
    required this.lensHighlightColor,
    required this.lensHighlightRect,
    required this.lensHighlightBorderRadius,
    required this.statusBar,
    required this.gestureBarColor,
    required this.gestureBarRect,
    required this.gestureBarBorderRadius,
    required this.showCamera,
    required this.showStatusBar,
    required this.showGestureBar,
    this.safeAreaPadding = EdgeInsets.zero,
  });

  /// [CoreOutlinedContainerStyle] for the composed `OutlinedContainer`
  /// body — fill, rim stroke, body radius, the body's own size, and the
  /// shadow. Raw-forwarded so that primitive resolves colour / radius /
  /// scaling itself; the size is already in logical px (the primitive does
  /// not scale it).
  final CoreOutlinedContainerStyle containerStyle;

  /// Body width (logical px, scaling pre-applied).
  final double width;

  /// Body height (logical px, scaling pre-applied).
  final double height;

  /// Power button; `null` when the device has none (the `flat` finish).
  final ResolvedMockupButton? powerButton;

  /// Volume up (or the single rocker); `null` when the device has none.
  final ResolvedMockupButton? volumeUpButton;

  /// Volume down; `null` when the device has one rocker or none.
  final ResolvedMockupButton? volumeDownButton;

  /// Solid fill under every button's gradients.
  final Color buttonColor;

  /// Hardware button corners — half the slab thickness.
  final BorderRadius buttonBorderRadius;

  /// The lit hairline just inside the body's rim; `null` when the finish
  /// draws no rim light.
  final ResolvedMockupStroke? rimHighlight;

  /// The faded gradient hairline over the rim; `null` when the finish draws
  /// no rim light.
  final ResolvedMockupStroke? rimGlow;

  /// Layer opacity over the whole rim glow stroke.
  final double rimGlowOpacity;

  /// Gaussian σ of the layer blur over the rim glow; `0` for none.
  final double rimGlowBlurSigma;

  /// Antenna bands, body-space; empty for a device that draws none.
  final List<Rect> antennaBands;

  /// Top-to-bottom gradient in each band's own frame.
  final Gradient antennaGradient;

  /// Layer opacity over each antenna band.
  final double antennaOpacity;

  /// The bezel box, body-space (scaling pre-applied).
  final Rect bezelRect;

  /// Bezel fill.
  final Color bezelColor;

  /// Bezel corner radius — body radius minus the rail (scaling
  /// pre-applied).
  final BorderRadius bezelBorderRadius;

  /// The bezel's outline, drawn outside its box — a stroke of the picture,
  /// in the bezel's own space (scaling pre-applied); `null` when it has no
  /// width.
  final ResolvedMockupStroke? bezelOutline;

  /// The bezel's inner shadow, painted over its fill; `null` when it has
  /// neither blur nor spread.
  final BoxShadow? bezelInnerShadow;

  /// The screen box, bezel-space (scaling pre-applied).
  final Rect screenRect;

  /// Screen corner radius — body radius minus the whole inset (scaling
  /// pre-applied).
  final BorderRadius screenBorderRadius;

  /// Screen fill — the caller's `child` sits on this.
  final Color backgroundColor;

  /// Simulated device insets consumed by the child's SafeArea (scaled once).
  final EdgeInsets safeAreaPadding;

  /// Which space the camera set is in — the screen's or the bezel's.
  final CoreMockupCameraPlacement cameraPlacement;

  /// Camera cut-out fill — [lensColor] when the cut-out is the lens,
  /// [cutoutColor] when it holds a ring.
  ///
  /// Paint-side output only. The style slot of this name is gone — a
  /// caller overrides the fill through `CoreMockupDeviceStyle.lensColor`
  /// or `cutoutColor`, and the lens decides which one arrives here.
  final Color cameraColor;

  /// Camera cut-out, in the [cameraPlacement] space (scaling pre-applied).
  final Rect cameraRect;

  /// Camera cut-out corners — a pill (half its short side).
  final BorderRadius cameraBorderRadius;

  /// Lens ring fill.
  final Color lensColor;

  /// Lens ring; `null` when the device draws no ring.
  final Rect? lensRect;

  /// Lens ring corners — a circle.
  final BorderRadius lensBorderRadius;

  /// Lens core's solid fill — painted when [coreGradient] is `null`.
  final Color cutoutColor;

  /// Lens core's radial gradient, or `null` for the solid [cutoutColor].
  final Gradient? coreGradient;

  /// Lens core dot.
  final Rect coreRect;

  /// Lens core corners — a circle.
  final BorderRadius coreBorderRadius;

  /// Glint fill.
  final Color lensHighlightColor;

  /// Glint on the core.
  final Rect lensHighlightRect;

  /// Glint corners — a circle.
  final BorderRadius lensHighlightBorderRadius;

  /// Status bar; `null` when the device draws none in this pose.
  final ResolvedMockupStatusBar? statusBar;

  /// Home gesture bar colour.
  final Color gestureBarColor;

  /// Home gesture bar, screen-space.
  final Rect gestureBarRect;

  /// Home gesture bar corners — a little under half the bar's height.
  final BorderRadius gestureBarBorderRadius;

  /// Whether the camera set renders — the caller's flag, or the finish's
  /// default when the caller stated none.
  final bool showCamera;

  /// Whether the status bar renders — settled like [showCamera].
  final bool showStatusBar;

  /// Whether the home gesture bar renders — settled like [showCamera].
  final bool showGestureBar;
}

// ═══════════════════════════════════════════════════
// Resolver — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedMockupDevice] for the given [context].
///
/// Merge chain:
///
/// ```text
/// CoreMockupDeviceStyle.defaultX / defaultsByDevice[device]
///   → CoreMockupDeviceStyle.defaultsByFinish[finish]
///   → theme.coreComponentTheme.mockup.style (shared cross-variant)
///   → theme.coreComponentTheme.mockupDevice.style
///   → theme.coreComponentTheme.mockupDevice.deviceStyles[device]
///   → theme.coreComponentTheme.mockupDevice.finishStyles[finish]
///   → widget.mockupDeviceStyle
/// ```
///
/// The shared [CoreMockupTheme] (canonical `{style: CoreMockupStyle?}`
/// slot) is folded into the chain as a `CoreMockupDeviceStyle` seed so
/// every field resolves through a single [resolveStyleChain] pass. The
/// semantic [widgetWidth] is a widget prop — the theme cannot override
/// it; the widget supplies the design-system fallback
/// (`CoreMockupDeviceStyle.defaultWidthFor(finish)`) on the widget edge.
///
/// [showCamera] / [showStatusBar] / [showGestureBar] are the caller's
/// flags; `null` is the finish's default, settled here so the widget reads
/// one answer.
///
/// Every derived rectangle comes from [CoreMockupDeviceLayout.compute],
/// the single rule set both platforms share; this resolver only settles
/// the inputs and scales the outputs.
ResolvedMockupDevice resolveMockupDevice(
  BuildContext context, {
  required CoreMockupDevice device,
  required CoreMockupOrientation orientation,
  required double widgetWidth,
  CoreMockupDeviceFinish finish = CoreMockupDeviceFinish.defaultFinish,
  bool? showCamera,
  bool? showStatusBar,
  bool? showGestureBar,
  CoreMockupDeviceStyle? mockupDeviceStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final mkTheme = theme.coreComponentTheme?.mockup;
  final deviceTheme = theme.coreComponentTheme?.mockupDevice;

  // The shared `CoreMockupTheme.style` carries the screen fill, the rim
  // colour, the body fill (its `frameColor`) and the body radius. Fold it
  // into a seed so the per-field fallback ladders collapse into the
  // single `resolveStyleChain` pass.
  final mkSeed = mkTheme?.style == null
      ? null
      : CoreMockupDeviceStyle(
          backgroundColor: mkTheme!.style!.backgroundColor,
          railColor: mkTheme.style!.frameColor,
          borderColor: mkTheme.style!.borderColor,
          borderRadius: mkTheme.style!.borderRadius,
        );
  final merged = resolveStyleChain(const CoreMockupDeviceStyle(), [
    CoreMockupDeviceStyle.defaultsByFinish[finish],
    mkSeed,
    deviceTheme?.style,
    deviceTheme?.deviceStyles?[device],
    deviceTheme?.finishStyles?[finish],
    mockupDeviceStyle,
  ]);
  final byDevice = CoreMockupDeviceStyle.defaultsByDevice[device]!;
  // The caller's flag, or what the finish draws by default.
  final cameraShown =
      showCamera ?? CoreMockupDeviceContract.defaultShowCameraFor(finish);
  final statusBarShown =
      showStatusBar ?? CoreMockupDeviceContract.defaultShowStatusBarFor(finish);
  final gestureBarShown =
      showGestureBar ??
      CoreMockupDeviceContract.defaultShowGestureBarFor(finish);

  // ─── Stage 1 RESOLVE (Flutter = Web) ─────────────────
  final railWidth = merged.railWidth ?? CoreMockupDeviceStyle.defaultRailWidth;
  final bezelWidth = merged.bezelWidth ?? byDevice.bezelWidth!;
  final borderWidth =
      merged.borderWidth ?? CoreMockupDeviceStyle.defaultBorderWidth;
  final borderRadius = merged.borderRadius ?? byDevice.borderRadius!;
  // The active surface style bends the body radius once, here, and the
  // bezel / screen radii are deflated from that bent value — so the three
  // stay concentric under a preset. `OutlinedContainer` bends the raw
  // value it is handed on its own; the derived pair below therefore
  // converts with the identity constraint, exactly as that primitive does
  // for values it has already bent.
  final bentBorderRadius = theme.geometry.borderRadius(borderRadius);
  final layout = CoreMockupDeviceLayout.compute(
    device: device,
    orientation: orientation,
    width: widgetWidth,
    railWidth: railWidth,
    bezelWidth: bezelWidth,
    borderRadius: bentBorderRadius,
    screenAspectWidth: merged.screenAspectWidth ?? byDevice.screenAspectWidth!,
    screenAspectHeight:
        merged.screenAspectHeight ?? byDevice.screenAspectHeight!,
    cameraPlacement: merged.cameraPlacement ?? byDevice.cameraPlacement!,
    cameraWidth: merged.cameraWidth ?? byDevice.cameraWidth!,
    cameraHeight: merged.cameraHeight ?? byDevice.cameraHeight!,
    cameraOffset: merged.cameraOffset ?? byDevice.cameraOffset!,
    lensSize: merged.lensSize ?? byDevice.lensSize!,
    lensOffset: merged.lensOffset ?? byDevice.lensOffset!,
    cameraCoreSize: merged.cameraCoreSize ?? byDevice.cameraCoreSize!,
    lensHighlightSizeRatio:
        merged.lensHighlightSizeRatio ??
        CoreMockupDeviceStyle.defaultLensHighlightSizeRatio,
    lensHighlightOffsetXRatio:
        merged.lensHighlightOffsetXRatio ??
        CoreMockupDeviceStyle.defaultLensHighlightOffsetXRatio,
    lensHighlightOffsetYRatio:
        merged.lensHighlightOffsetYRatio ??
        CoreMockupDeviceStyle.defaultLensHighlightOffsetYRatio,
    buttonThickness:
        merged.buttonThickness ?? CoreMockupDeviceStyle.defaultButtonThickness,
    buttonProtrusion:
        merged.buttonProtrusion ??
        CoreMockupDeviceStyle.defaultButtonProtrusion,
    powerButtonLength: merged.powerButtonLength ?? byDevice.powerButtonLength!,
    powerButtonOffset: merged.powerButtonOffset ?? byDevice.powerButtonOffset!,
    volumeButtonLength:
        merged.volumeButtonLength ?? byDevice.volumeButtonLength!,
    volumeButtonOffset:
        merged.volumeButtonOffset ?? byDevice.volumeButtonOffset!,
    volumeButtonSpacing:
        merged.volumeButtonSpacing ?? byDevice.volumeButtonSpacing!,
    landscapePowerButtonLength:
        merged.landscapePowerButtonLength ??
        byDevice.landscapePowerButtonLength!,
    landscapePowerButtonOffset:
        merged.landscapePowerButtonOffset ??
        byDevice.landscapePowerButtonOffset!,
    landscapeVolumeButtonLength:
        merged.landscapeVolumeButtonLength ??
        byDevice.landscapeVolumeButtonLength!,
    landscapeVolumeButtonOffset:
        merged.landscapeVolumeButtonOffset ??
        byDevice.landscapeVolumeButtonOffset!,
    antennaBandLength: merged.antennaBandLength ?? byDevice.antennaBandLength!,
    antennaSideNearOffset:
        merged.antennaSideNearOffset ??
        CoreMockupDeviceStyle.defaultAntennaSideNearOffset,
    antennaSideFarOffset:
        merged.antennaSideFarOffset ??
        CoreMockupDeviceStyle.defaultAntennaSideFarOffset,
    antennaTopOffset:
        merged.antennaTopOffset ??
        CoreMockupDeviceStyle.defaultAntennaTopOffset,
    antennaBottomOffset:
        merged.antennaBottomOffset ??
        CoreMockupDeviceStyle.defaultAntennaBottomOffset,
    rimHighlightInset:
        merged.rimHighlightInset ??
        CoreMockupDeviceStyle.defaultRimHighlightInset,
    rimGlowTopInset:
        merged.rimGlowTopInset ?? CoreMockupDeviceStyle.defaultRimGlowTopInset,
    rimGlowBottomInset:
        merged.rimGlowBottomInset ??
        CoreMockupDeviceStyle.defaultRimGlowBottomInset,
    systemBarReferenceWidth:
        merged.systemBarReferenceWidth ?? byDevice.systemBarReferenceWidth!,
    systemBarReferenceScale:
        merged.systemBarReferenceScale ?? byDevice.systemBarReferenceScale!,
    landscapeSystemBarReferenceWidth:
        merged.landscapeSystemBarReferenceWidth ??
        byDevice.landscapeSystemBarReferenceWidth!,
    landscapeSystemBarReferenceScale:
        merged.landscapeSystemBarReferenceScale ??
        byDevice.landscapeSystemBarReferenceScale!,
    statusBarHeight: merged.statusBarHeight ?? byDevice.statusBarHeight!,
    landscapeStatusBarHeight:
        merged.landscapeStatusBarHeight ?? byDevice.landscapeStatusBarHeight!,
    statusBarInset: merged.statusBarInset ?? byDevice.statusBarInset!,
    statusBarContentCenter:
        merged.statusBarContentCenter ?? byDevice.statusBarContentCenter!,
    statusBarWingWidth:
        merged.statusBarWingWidth ?? byDevice.statusBarWingWidth!,
    statusBarTrailingInset:
        merged.statusBarTrailingInset ?? byDevice.statusBarTrailingInset!,
    statusBarTrailingSpacing:
        merged.statusBarTrailingSpacing ?? byDevice.statusBarTrailingSpacing!,
    statusBarClockSpacing:
        merged.statusBarClockSpacing ??
        CoreMockupDeviceStyle.defaultStatusBarClockSpacing,
    statusBarLeadingSpacing:
        merged.statusBarLeadingSpacing ??
        CoreMockupDeviceStyle.defaultStatusBarLeadingSpacing,
    // The deprecated pin has no default: it is only ever stated.
    gestureBarWidthRatio: merged.pinnedGestureBarWidthRatio,
    gestureBarWidth: merged.gestureBarWidth ?? byDevice.gestureBarWidth!,
    landscapeGestureBarWidth:
        merged.landscapeGestureBarWidth ?? byDevice.landscapeGestureBarWidth!,
    gestureBarHeight:
        merged.gestureBarHeight ??
        CoreMockupDeviceStyle.defaultGestureBarHeight,
    gestureBarOffset:
        merged.gestureBarOffset ??
        CoreMockupDeviceStyle.defaultGestureBarOffset,
    gestureBarRadius:
        merged.gestureBarRadius ??
        CoreMockupDeviceStyle.defaultGestureBarRadius,
    gestureBarAreaHeight:
        merged.gestureBarAreaHeight ?? byDevice.gestureBarAreaHeight!,
    landscapeGestureBarAreaHeight:
        merged.landscapeGestureBarAreaHeight ??
        byDevice.landscapeGestureBarAreaHeight!,
  );

  // ─── Stage 2 EMIT — geometry, scaling pre-applied ────
  final width = layout.deviceWidth * scaling;
  final height = layout.deviceHeight * scaling;
  const applied = CoreSurfaceGeometryConstraint();
  final bodyBorderRadius =
      bentBorderRadius.toValue(geometry: applied) * scaling;
  final bezelBorderRadius =
      layout.bezelBorderRadius.toValue(geometry: applied) * scaling;
  final screenBorderRadius =
      layout.screenBorderRadius.toValue(geometry: applied) * scaling;
  final bezelRect = _scaledRect(layout.bezelBox, scaling);
  // The screen's place inside the bezel box: one bezel in from its corner.
  final screenRect = _scaledRect((
    left: layout.screenBox.left - layout.bezelBox.left,
    top: layout.screenBox.top - layout.bezelBox.top,
    width: layout.screenBox.width,
    height: layout.screenBox.height,
  ), scaling);
  final safeArea = layout.safeAreaInsets(
    showCamera: cameraShown,
    showStatusBar: statusBarShown,
    showGestureBar: gestureBarShown,
  );
  final safeAreaPadding =
      EdgeInsets.fromLTRB(
        safeArea.left,
        safeArea.top,
        safeArea.right,
        safeArea.bottom,
      ) *
      scaling;
  final cameraRect = _scaledRect(layout.camera, scaling);
  final lensRect = layout.lens == null
      ? null
      : _scaledRect(layout.lens!, scaling);
  final coreRect = _scaledRect(layout.core, scaling);
  final lensHighlightRect = _scaledRect(layout.lensHighlight, scaling);
  final gestureBarRect = _scaledRect(layout.gestureBar, scaling);
  // Small parts are pills / circles: their radius is half the short side,
  // derived rather than stated (`resolveMockupDevice` owns the derivation,
  // the style states only sizes). The home bar is the exception — it is not
  // a pill, so its corner is the stated radius.
  final cameraBorderRadius = _pillRadius(cameraRect);
  final lensBorderRadius = _pillRadius(lensRect ?? coreRect);
  final coreBorderRadius = _pillRadius(coreRect);
  final lensHighlightBorderRadius = _pillRadius(lensHighlightRect);
  final gestureBarBorderRadius = BorderRadius.circular(
    layout.gestureBarRadius * scaling,
  );
  final buttonBorderRadius = _pillRadius(
    _scaledRect(layout.powerButton, scaling),
  );
  final antennaBands = [
    for (final band in layout.antennaBands) _scaledRect(band.rect, scaling),
  ];
  final rimGlowOpacity =
      merged.rimGlowOpacity ?? CoreMockupDeviceStyle.defaultRimGlowOpacity;
  final rimGlowBlurSigma = figmaLayerBlurToSigma(
    (merged.rimGlowBlur ?? CoreMockupDeviceStyle.defaultRimGlowBlur) * scaling,
  );
  final antennaOpacity =
      merged.antennaOpacity ?? CoreMockupDeviceStyle.defaultAntennaOpacity;
  // Every stroke of the device but the body's own border is part of its
  // picture — the rims, the bezel outline, the battery outline — so the
  // surface style's stroke floor does not reach them.
  final bezelBorderWidth =
      (merged.bezelBorderWidth ??
          CoreMockupDeviceStyle.defaultBezelBorderWidth) *
      scaling;

  // ─── Stage 2 EMIT — colours through the active scheme ─
  final bezelColor = scheme
      .resolve(merged.bezelColor ?? CoreMockupDeviceStyle.defaultBezelColor)
      .toValue();
  final bezelBorderColor = scheme
      .resolve(
        merged.bezelBorderColor ??
            CoreMockupDeviceStyle.defaultBezelBorderColor,
      )
      .toValue();
  final bezelInnerShadowColor = scheme
      .resolve(
        merged.bezelInnerShadowColor ??
            CoreMockupDeviceStyle.defaultBezelInnerShadowColor,
      )
      .toValue();
  final bezelInnerShadowBlur =
      merged.bezelInnerShadowBlur ??
      CoreMockupDeviceStyle.defaultBezelInnerShadowBlur;
  final bezelInnerShadowSpread =
      merged.bezelInnerShadowSpread ??
      CoreMockupDeviceStyle.defaultBezelInnerShadowSpread;
  // A zero blur and spread is no shadow at all (the `flat` finish).
  final bezelInnerShadow =
      bezelInnerShadowBlur > 0 || bezelInnerShadowSpread > 0
      ? (
          offsetX: 0.0,
          offsetY: 0.0,
          blurRadius: bezelInnerShadowBlur,
          spreadRadius: bezelInnerShadowSpread,
          opacity: 1.0,
          inset: true,
        ).toValue(
          bezelInnerShadowColor,
          scale: scaling,
        )
      : null;
  final backgroundColor = scheme
      .resolve(
        merged.backgroundColor ?? CoreMockupDeviceStyle.defaultBackgroundColor,
      )
      .toValue();
  final lensColor = scheme
      .resolve(merged.lensColor ?? CoreMockupDeviceStyle.defaultLensColor)
      .toValue();
  final cutoutColor = scheme
      .resolve(merged.cutoutColor ?? CoreMockupDeviceStyle.defaultCutoutColor)
      .toValue();
  // The cut-out has no fill of its own: it takes the lens fill when it is
  // the lens, the cut-out fill when it holds a ring (the Core layout says
  // which — the same answer the Web resolver and the Figma builder read).
  final cameraColor = layout.cameraIsLens ? lensColor : cutoutColor;
  // The core is a radial gradient unless a caller stated the cut-out fill,
  // which colours it as a solid.
  final coreGradient = CoreMockupDeviceStyle.resolveCoreGradient(
    cutoutColor: merged.cutoutColor,
    coreGradient: merged.coreGradient,
  )?.toValue(scheme: scheme);
  final lensHighlightColor = scheme
      .resolve(
        merged.lensHighlightColor ??
            CoreMockupDeviceStyle.defaultLensHighlightColor,
      )
      .toValue();
  final gestureBarColor = scheme
      .resolve(
        merged.gestureBarColor ?? CoreMockupDeviceStyle.defaultGestureBarColor,
      )
      .toValue();
  final buttonColor = scheme
      .resolve(merged.buttonColor ?? CoreMockupDeviceStyle.defaultButtonColor)
      .toValue();
  final rimHighlightColor = scheme
      .resolve(
        merged.rimHighlightColor ??
            CoreMockupDeviceStyle.defaultRimHighlightColor,
      )
      .toValue();
  final rimGlowGradient =
      (merged.rimGlowGradient ?? CoreMockupDeviceStyle.defaultRimGlowGradient)
          .toValue(scheme: scheme);
  final antennaGradient =
      (merged.antennaGradient ?? CoreMockupDeviceStyle.defaultAntennaGradient)
          .toValue(scheme: scheme);
  final rimHighlightWidth =
      (merged.rimHighlightWidth ??
          CoreMockupDeviceStyle.defaultRimHighlightWidth) *
      scaling;
  final rimGlowWidth =
      (merged.rimGlowWidth ?? CoreMockupDeviceStyle.defaultRimGlowWidth) *
      scaling;
  // A rim with no width is no rim (the `flat` finish): no layer at all.
  final rimHighlight = rimHighlightWidth > 0
      ? ResolvedMockupStroke(
          rect: _scaledRect(layout.rimHighlight, scaling),
          borderRadius: bodyBorderRadius,
          width: rimHighlightWidth,
          color: rimHighlightColor,
        )
      : null;
  final rimGlow = rimGlowWidth > 0
      ? ResolvedMockupStroke(
          rect: _scaledRect(layout.rimGlow, scaling),
          borderRadius: bodyBorderRadius,
          width: rimGlowWidth,
          gradient: rimGlowGradient,
        )
      : null;
  final bezelOutline = bezelBorderWidth > 0
      ? ResolvedMockupStroke(
          rect: Offset.zero & bezelRect.size,
          borderRadius: bezelBorderRadius,
          width: bezelBorderWidth,
          color: bezelBorderColor,
        )
      : null;

  // ─── Buttons — the gloss and the depth follow the edge each stands on ─
  final buttonLengthGradient =
      merged.buttonLengthGradient ??
      CoreMockupDeviceStyle.defaultButtonLengthGradient;
  final buttonDepthColor =
      merged.buttonDepthColor ?? CoreMockupDeviceStyle.defaultButtonDepthColor;
  // A button with no length is no button (the `flat` finish): no part at all.
  final powerButton = layout.hasPowerButton
      ? _resolveButton(
          scheme,
          scaling,
          rect: layout.powerButton,
          edge: layout.powerButtonEdge,
          lengthGradient: buttonLengthGradient,
          depthColor: buttonDepthColor,
        )
      : null;
  final volumeUpButton = layout.hasVolumeButton
      ? _resolveButton(
          scheme,
          scaling,
          rect: layout.volumeUpButton,
          edge: layout.volumeButtonEdge,
          lengthGradient: buttonLengthGradient,
          depthColor: buttonDepthColor,
        )
      : null;
  final volumeDownButton = layout.volumeDownButton == null
      ? null
      : _resolveButton(
          scheme,
          scaling,
          rect: layout.volumeDownButton!,
          edge: layout.volumeButtonEdge,
          lengthGradient: buttonLengthGradient,
          depthColor: buttonDepthColor,
        );

  // ─── Status bar ───────────────────────────────────────
  final statusBar = layout.statusBar == null
      ? null
      : _resolveStatusBar(
          layout.statusBar!,
          theme: theme,
          scaling: scaling,
          textStyle: byDevice.statusBarTextStyle!.merge(
            merged.statusBarTextStyle,
          ),
          iconColor: scheme
              .resolve(
                merged.statusBarIconColor ??
                    CoreMockupDeviceStyle.defaultStatusBarIconColor,
              )
              .toValue(),
          batteryBorderColor: scheme
              .resolve(
                merged.statusBarBatteryBorderColor ??
                    CoreMockupDeviceStyle.defaultStatusBarBatteryBorderColor,
              )
              .toValue(),
          batteryCapColor: scheme
              .resolve(
                merged.statusBarBatteryCapColor ??
                    CoreMockupDeviceStyle.defaultStatusBarBatteryCapColor,
              )
              .toValue(),
        );

  // ─── Composed OutlinedContainer body ──────────────────
  // Fill / rim stroke / body radius come from this component's own fields.
  // The body states its own size rather than taking it from a child: the
  // bezel, rims and bands are siblings positioned in body-space, so the
  // body's box must not depend on how thick a surface style draws its
  // stroke. The nested `containerStyle` slot (shadow by default) layers on
  // top so a caller can still restate any of it. Domain values stay raw —
  // `OutlinedContainer` resolves and scales them once.
  final containerStyle =
      CoreOutlinedContainerStyle(
        backgroundColor:
            merged.railColor ?? CoreMockupDeviceStyle.defaultRailColor,
        backgroundGradient: CoreMockupDeviceStyle.resolveBodyGradient(
          railColor: merged.railColor,
          railGradient: merged.railGradient,
        ),
        borderColor:
            merged.borderColor ?? CoreMockupDeviceStyle.defaultBorderColor,
        borderRadius: borderRadius,
        borderWidth: borderWidth,
        width: width,
        height: height,
      ).merge(
        CoreMockupDeviceStyle.defaultContainerStyle.merge(
          merged.containerStyle,
        ),
      );

  return ResolvedMockupDevice(
    containerStyle: containerStyle,
    width: width,
    height: height,
    powerButton: powerButton,
    volumeUpButton: volumeUpButton,
    volumeDownButton: volumeDownButton,
    buttonColor: buttonColor,
    buttonBorderRadius: buttonBorderRadius,
    rimHighlight: rimHighlight,
    rimGlow: rimGlow,
    rimGlowOpacity: rimGlowOpacity,
    rimGlowBlurSigma: rimGlowBlurSigma,
    antennaBands: antennaBands,
    antennaGradient: antennaGradient,
    antennaOpacity: antennaOpacity,
    bezelRect: bezelRect,
    bezelColor: bezelColor,
    bezelBorderRadius: bezelBorderRadius,
    bezelOutline: bezelOutline,
    bezelInnerShadow: bezelInnerShadow,
    screenRect: screenRect,
    screenBorderRadius: screenBorderRadius,
    backgroundColor: backgroundColor,
    cameraPlacement: layout.cameraPlacement,
    cameraColor: cameraColor,
    cameraRect: cameraRect,
    cameraBorderRadius: cameraBorderRadius,
    lensColor: lensColor,
    lensRect: lensRect,
    lensBorderRadius: lensBorderRadius,
    cutoutColor: cutoutColor,
    coreGradient: coreGradient,
    coreRect: coreRect,
    coreBorderRadius: coreBorderRadius,
    lensHighlightColor: lensHighlightColor,
    lensHighlightRect: lensHighlightRect,
    lensHighlightBorderRadius: lensHighlightBorderRadius,
    statusBar: statusBar,
    gestureBarColor: gestureBarColor,
    gestureBarRect: gestureBarRect,
    gestureBarBorderRadius: gestureBarBorderRadius,
    showCamera: cameraShown,
    showStatusBar: statusBarShown,
    showGestureBar: gestureBarShown,
    safeAreaPadding: safeAreaPadding,
  );
}

// ═══════════════════════════════════════════════════
// File-private slot helpers
// ═══════════════════════════════════════════════════

/// A Core layout rectangle as a Flutter [Rect] with [scaling] applied.
Rect _scaledRect(CoreMockupDeviceRect r, double scaling) => .fromLTWH(
  r.left * scaling,
  r.top * scaling,
  r.width * scaling,
  r.height * scaling,
);

/// Half the short side — a pill for an oblong, a circle for a square.
BorderRadius _pillRadius(Rect r) => .circular(r.shortestSide / 2);

/// One button: its rectangle and the two gradients pointed for the [edge] it
/// stands on.
ResolvedMockupButton _resolveButton(
  CoreColorScheme scheme,
  double scaling, {
  required CoreMockupDeviceRect rect,
  required CoreMockupDeviceEdge edge,
  required CoreGradient lengthGradient,
  required CoreColor depthColor,
}) => ResolvedMockupButton(
  rect: _scaledRect(rect, scaling),
  lengthGradient: CoreMockupDeviceLayout.buttonLengthGradient(
    lengthGradient,
    edge,
  ).toValue(scheme: scheme),
  depthGradient: CoreMockupDeviceLayout.buttonDepthGradient(
    depthColor,
    edge,
  ).toValue(scheme: scheme),
);

/// The status bar at `scaling`, its text set in the role at the bar's own
/// size.
///
/// The text's size is the materialised role's size times the bar's scale
/// (iOS points → px) and is **not** multiplied by `scaling` again: the text
/// axis is the theme typography's, which is already pre-scaled — the same
/// rule as every other text. Tracking is an em ratio materialised as px
/// against the role's size, so it follows the size on its own; leading is a
/// unitless ratio and stays.
ResolvedMockupStatusBar _resolveStatusBar(
  CoreMockupStatusBarLayout bar, {
  required ThemeData theme,
  required double scaling,
  required CoreTextStyle textStyle,
  required Color iconColor,
  required Color batteryBorderColor,
  required Color batteryCapColor,
}) {
  final role = textStyle.toValue(theme: theme);
  final size = role.fontSize;
  final tracking = role.letterSpacing;
  final style = role.copyWith(
    fontSize: size == null ? null : size * bar.scale,
    letterSpacing: tracking == null ? null : tracking * bar.scale,
  );

  ResolvedMockupStatusBarItem item(CoreMockupStatusBarItem it) => switch (it) {
    CoreMockupStatusBarText(:final text, :final gapAfter) =>
      ResolvedMockupStatusBarText(
        text: text,
        style: style,
        gapAfter: gapAfter * scaling,
      ),
    CoreMockupStatusBarGlyph(
      :final glyph,
      :final width,
      :final height,
      :final gapAfter,
    ) =>
      ResolvedMockupStatusBarGlyph(
        size: Size(width, height) * scaling,
        path: glyph.toPath(Size(width, height) * scaling),
        color: iconColor,
        gapAfter: gapAfter * scaling,
      ),
    CoreMockupStatusBarBattery(
      :final width,
      :final height,
      :final border,
      borderWidth: final outlineWidth,
      borderRadius: final outlineRadius,
      :final capacity,
      :final capacityRadius,
      :final cap,
      :final capGlyph,
      :final gapAfter,
    ) =>
      ResolvedMockupStatusBarBattery(
        size: Size(width, height) * scaling,
        outline: ResolvedMockupStroke(
          rect: _scaledRect(border, scaling),
          borderRadius: .circular(outlineRadius * scaling),
          width: outlineWidth * scaling,
          color: batteryBorderColor,
        ),
        capacityRect: _scaledRect(capacity, scaling),
        capacityRadius: .circular(capacityRadius * scaling),
        capacityColor: iconColor,
        capRect: _scaledRect(cap, scaling),
        capPath: capGlyph.toPath(Size(cap.width, cap.height) * scaling),
        capColor: batteryCapColor,
        gapAfter: gapAfter * scaling,
      ),
  };

  ResolvedMockupStatusBarGroup group(CoreMockupStatusBarGroup g) =>
      ResolvedMockupStatusBarGroup(
        box: _scaledRect(g.box, scaling),
        alignment: coreMainAxisAlignmentToFlutter(g.alignment),
        contentAlignment: switch (g.alignment) {
          .start => Alignment.centerLeft,
          .end => Alignment.centerRight,
          _ => Alignment.center,
        },
        items: [for (final it in g.items) item(it)],
      );

  return ResolvedMockupStatusBar(
    rect: _scaledRect(bar.rect, scaling),
    leading: group(bar.leading),
    trailing: group(bar.trailing),
  );
}
