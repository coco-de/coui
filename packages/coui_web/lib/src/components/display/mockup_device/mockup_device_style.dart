import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `MockupDevice`.
///
/// DOM shape (back to front — every part is an absolute child of `root`
/// except where it says otherwise, so later siblings paint over earlier
/// ones):
///
/// ```text
/// root (<div>)                                  // relative inline-flex, body box
///   ├─ powerButton / volumeUpButton / volumeDownButton   // protrude past the body
///   ├─ OutlinedContainer(containerStyle: frameStyle, classes: frame.className)
///   │                                           // the body: gradient fill, rim, shadow
///   ├─ rimHighlight (<div>)                     // inset ring, white hairline
///   ├─ rimGlow (<div>)                          // layer-blurred, layer-opacity wrapper
///   │    └─ rimGlowRing (<div>)                 // gradient painted through a ring mask
///   ├─ antennaBands (<div>) × 6                 // phone only
///   └─ bezel (<div>)                            // fill, outline, inner shadow
///        ├─ screen (<div>)                      // overflow-hidden, screen fill
///        │    ├─ content (<div>)                // inset-0 + four-sided safe area
///        │    ├─ statusBar (<div>)              // showStatusBar, where the pose has one
///        │    │    ├─ leading (<div>) → items
///        │    │    └─ trailing (<div>) → items
///        │    ├─ screenCameraParts              // showCamera, camera cut out of the screen
///        │    └─ gestureBar (<div>)             // showGestureBar
///        └─ bezelCameraParts                    // showCamera, camera in the bezel strip
/// ```
///
/// The body is a composed `OutlinedContainer`, not a hand-rolled `<div>`
/// (`core/style-contract.md`'s child-component-composition rule), so its
/// chrome is the nested [frameStyle] slot; [frame] carries only the layout
/// class that stacks it between the buttons and the rim.
///
/// Every rectangle is absolute inline CSS the resolver pre-composed from
/// [CoreMockupDeviceLayout] — the same rule set the Flutter resolver reads
/// — so `mockup_device.dart` reads slots only. Every colour goes through the
/// emit family: a token fill becomes a class and a raw colour goes inline.
/// The screen, the status bar and the gesture bar stand on tokens that follow
/// the mode, so they become classes. The hardware colours are the designer
/// copy's literals, so they go inline and read the same in light, dark and
/// both high-contrast modes and under any brand palette; the optical layers —
/// button gloss and depth, rim glow, the bezel's inner shadow, the body's
/// drop shadow — are literals too. Nothing here is chrome a caller could
/// inject through `classes` / `css`.
class ResolvedMockupDevice implements WebResolvedChrome {
  /// Creates a [ResolvedMockupDevice].
  const ResolvedMockupDevice({
    required this.root,
    required this.frame,
    required this.frameStyle,
    required this.rimHighlight,
    required this.rimGlow,
    required this.rimGlowRing,
    required this.antennaBands,
    required this.bezel,
    required this.screen,
    required this.content,
    required this.statusBar,
    required this.screenCameraParts,
    required this.bezelCameraParts,
    required this.gestureBar,
    required this.powerButton,
    required this.volumeUpButton,
    required this.volumeDownButton,
  });

  /// Paint-ready chrome for the outer wrapper `<div>` — `relative
  /// inline-flex` (the positioning context for every part) plus the body's
  /// width and height as inline CSS. Carries no paint chrome of its own —
  /// that lives on [frameStyle].
  @override
  final WebElementChrome root;

  /// Layout-only class for the composed `OutlinedContainer` body — it fills
  /// the root. No chrome: that is [frameStyle]'s.
  final WebElementChrome frame;

  /// Nested [CoreOutlinedContainerStyle] for the body — the rail gradient (or
  /// the solid a caller stated), rim stroke, body radius and shadow.
  /// Raw-forwarded straight to `OutlinedContainer(containerStyle: …)`.
  final CoreOutlinedContainerStyle frameStyle;

  /// The lit hairline just inside the body's edge — an inset ring, so its
  /// fractional width is drawn rather than snapped to a device pixel; `null`
  /// when the finish draws no rim light.
  final WebElementChrome? rimHighlight;

  /// Wrapper of the rim glow — carries the layer blur and the paint opacity,
  /// which apply after the ring is cut, so the blur softens the ring itself;
  /// `null` when the finish draws no rim light.
  final WebElementChrome? rimGlow;

  /// The rim glow's ring — the gradient painted through a mask that leaves
  /// only the padding band (two full-box masks composited with `exclude`);
  /// `null` together with [rimGlow].
  final WebElementChrome? rimGlowRing;

  /// Antenna bands, each its own absolute `<div>`; empty for a device that
  /// draws none. The bands never overlap, so the order carries no stacking
  /// meaning.
  final List<WebElementChrome> antennaBands;

  /// Paint-ready chrome for the bezel `<div>` — its box, fill, concentric
  /// radius, and the two shadow layers that draw its outline (outside) and
  /// its inner glow.
  final WebElementChrome bezel;

  /// Paint-ready chrome for the screen `<div>` — absolute inside the bezel,
  /// `overflow-hidden`, the screen fill (token → class), size and derived
  /// radius inline.
  final WebElementChrome screen;

  /// Paint-ready chrome for the content `<div>` that fills the screen —
  /// `absolute inset-0` plus the four-sided safe-area padding.
  final WebElementChrome content;

  /// The status bar over the top of the screen; `null` when it is switched
  /// off (the caller's flag, or the finish's default) or the device draws
  /// none in this pose (a phone turned on its side).
  final ResolvedMockupDeviceStatusBar? statusBar;

  /// The camera set — cut-out, lens ring (when the device has one), core and
  /// glint, back to front — when it is cut out of the screen; empty when it
  /// sits in the bezel strip or the camera is switched off.
  final List<WebElementChrome> screenCameraParts;

  /// The camera set when it sits in the bezel strip; empty when it is cut out
  /// of the screen or the camera is switched off. Same order as
  /// [screenCameraParts].
  final List<WebElementChrome> bezelCameraParts;

  /// Home gesture bar `<div>`; `null` when it is switched off (the caller's
  /// flag, or the finish's default).
  final WebElementChrome? gestureBar;

  /// Power button `<div>` — absolute in body space, protruding; `null` when
  /// the device has none (the `flat` finish).
  final WebElementChrome? powerButton;

  /// Volume up (or the single rocker) `<div>`; `null` when the device has
  /// none.
  final WebElementChrome? volumeUpButton;

  /// Volume down `<div>`; `null` when the device has one rocker or none.
  final WebElementChrome? volumeDownButton;
}

/// Paint-ready chrome for the status bar of Web `MockupDevice`.
///
/// ```text
/// root (<div>)                       // the screen's fill over the top band
///   ├─ leading (<div>)               // flex row in its box
///   │    └─ leadingItems …
///   └─ trailing (<div>)
///        └─ trailingItems …
/// ```
class ResolvedMockupDeviceStatusBar implements WebResolvedChrome {
  /// Creates a [ResolvedMockupDeviceStatusBar].
  const ResolvedMockupDeviceStatusBar({
    required this.root,
    required this.leading,
    required this.trailing,
    required this.leadingItems,
    required this.trailingItems,
  });

  /// The bar itself — opaque screen fill over the top band, so the child's
  /// overflow cannot show through it.
  @override
  final WebElementChrome root;

  /// The leading group's box: a flex row aligned as the layout says.
  final WebElementChrome leading;

  /// The trailing group's box.
  final WebElementChrome trailing;

  /// The leading group's items, first to last.
  final List<ResolvedMockupDeviceStatusItem> leadingItems;

  /// The trailing group's items, first to last.
  final List<ResolvedMockupDeviceStatusItem> trailingItems;
}

/// Paint-ready chrome for one thing a `MockupDevice` status bar draws — a
/// piece of text, a vector glyph, or the phone's three-part battery.
///
/// [root] is its element; [content] says what it holds; [parts] are children
/// of that element (the battery's outline, level and nub).
class ResolvedMockupDeviceStatusItem implements WebResolvedChrome {
  /// Creates a [ResolvedMockupDeviceStatusItem].
  const ResolvedMockupDeviceStatusItem({
    required this.root,
    required this.content,
    this.parts = const [],
  });

  /// The item's element, gap to the next item included.
  @override
  final WebElementChrome root;

  /// What the element holds.
  final ResolvedMockupDeviceStatusContent content;

  /// Children of [root], back to front; empty for text and a plain glyph.
  final List<ResolvedMockupDeviceStatusItem> parts;
}

/// What a [ResolvedMockupDeviceStatusItem]'s element holds — sample text or a
/// vector drawing. A value bundle: it draws nothing itself and carries no
/// chrome; the item's `root` does.
class ResolvedMockupDeviceStatusContent {
  /// Nothing — the element is a box its parts (or its own fill) draw.
  const ResolvedMockupDeviceStatusContent.none()
    : text = null,
      path = null,
      viewBox = null,
      fillRule = null;

  /// A piece of sample text.
  const ResolvedMockupDeviceStatusContent.text(String this.text)
    : path = null,
      viewBox = null,
      fillRule = null;

  /// A vector drawing: an `<svg viewBox>` holding one filled `<path>`.
  const ResolvedMockupDeviceStatusContent.glyph({
    required String this.path,
    required String this.viewBox,
    required String this.fillRule,
  }) : text = null;

  /// The text; `null` unless the item is text.
  final String? text;

  /// The SVG path data (`d`); `null` unless the item is a glyph.
  final String? path;

  /// The SVG `viewBox` — the glyph's own box; `null` unless a glyph.
  final String? viewBox;

  /// The SVG `fill-rule` (`evenodd` / `nonzero`); `null` unless a glyph.
  final String? fillRule;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// A solid mask layer. Two of them — the first clipped to the content box —
/// composited with `exclude` leave exactly the padding band: the ring a
/// gradient stroke is painted through. Both spellings are emitted, because
/// Safari reads only the prefixed one and Chromium the unprefixed.
const _kRingMaskLayer = 'linear-gradient(#000 0 0)';

/// Resolves [ResolvedMockupDevice] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreMockupDeviceStyle.defaultX / defaultsByDevice)
///   → CoreMockupDeviceStyle.defaultsByFinish[finish]
///   → theme.coreComponentTheme.mockup.style (shared cross-variant)
///   → theme.coreComponentTheme.mockupDevice.style
///   → theme.coreComponentTheme.mockupDevice.deviceStyles[device]
///   → theme.coreComponentTheme.mockupDevice.finishStyles[finish]
///   → widget.mockupDeviceStyle
/// ```
///
/// The semantic [widgetWidth] is a widget prop — it threads through here
/// already resolved (the widget supplies the design-system fallback on
/// the widget edge) and the theme cannot override it. [showCamera] /
/// [showStatusBar] / [showGestureBar] are the caller's flags; `null` is the
/// finish's default, settled here so the widget reads one answer.
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
  final mkTheme = context.theme.coreComponentTheme?.mockup;
  final deviceTheme = context.theme.coreComponentTheme?.mockupDevice;

  // ─── Merge chain ──────────────────────────────────────
  // The shared `CoreMockupTheme.style` is folded into a seed exactly as
  // the Flutter resolver does, so both platforms settle every value in a
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

  // ─── Stage 1 RESOLVE (Flutter = Web) ──────────────────
  final railWidth = merged.railWidth ?? CoreMockupDeviceStyle.defaultRailWidth;
  final bezelWidth = merged.bezelWidth ?? byDevice.bezelWidth!;
  final borderWidth =
      merged.borderWidth ?? CoreMockupDeviceStyle.defaultBorderWidth;
  final borderRadius = merged.borderRadius ?? byDevice.borderRadius!;
  final layout = CoreMockupDeviceLayout.compute(
    device: device,
    orientation: orientation,
    width: widgetWidth,
    railWidth: railWidth,
    bezelWidth: bezelWidth,
    borderRadius: borderRadius,
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

  // The paint values that have a stated-or-default answer the layout does not
  // own. A solid a caller states beats the gradient (the one precedence both
  // platforms and the Figma builder read, in Core).
  final bodyGradient = CoreMockupDeviceStyle.resolveBodyGradient(
    railColor: merged.railColor,
    railGradient: merged.railGradient,
  );
  final coreGradient = CoreMockupDeviceStyle.resolveCoreGradient(
    cutoutColor: merged.cutoutColor,
    coreGradient: merged.coreGradient,
  );
  final rimHighlightColor =
      merged.rimHighlightColor ??
      CoreMockupDeviceStyle.defaultRimHighlightColor;
  final rimHighlightWidth =
      merged.rimHighlightWidth ??
      CoreMockupDeviceStyle.defaultRimHighlightWidth;
  final rimGlowGradient =
      merged.rimGlowGradient ?? CoreMockupDeviceStyle.defaultRimGlowGradient;
  final rimGlowOpacity =
      merged.rimGlowOpacity ?? CoreMockupDeviceStyle.defaultRimGlowOpacity;
  final rimGlowWidth =
      merged.rimGlowWidth ?? CoreMockupDeviceStyle.defaultRimGlowWidth;
  final rimGlowBlur =
      merged.rimGlowBlur ?? CoreMockupDeviceStyle.defaultRimGlowBlur;
  final bezelBorderColor =
      merged.bezelBorderColor ?? CoreMockupDeviceStyle.defaultBezelBorderColor;
  final bezelBorderWidth =
      merged.bezelBorderWidth ?? CoreMockupDeviceStyle.defaultBezelBorderWidth;
  final bezelInnerShadowColor =
      merged.bezelInnerShadowColor ??
      CoreMockupDeviceStyle.defaultBezelInnerShadowColor;
  final bezelInnerShadowBlur =
      merged.bezelInnerShadowBlur ??
      CoreMockupDeviceStyle.defaultBezelInnerShadowBlur;
  final bezelInnerShadowSpread =
      merged.bezelInnerShadowSpread ??
      CoreMockupDeviceStyle.defaultBezelInnerShadowSpread;
  final buttonLengthGradient =
      merged.buttonLengthGradient ??
      CoreMockupDeviceStyle.defaultButtonLengthGradient;
  final buttonDepthColor =
      merged.buttonDepthColor ?? CoreMockupDeviceStyle.defaultButtonDepthColor;
  final antennaGradient =
      merged.antennaGradient ?? CoreMockupDeviceStyle.defaultAntennaGradient;
  final antennaOpacity =
      merged.antennaOpacity ?? CoreMockupDeviceStyle.defaultAntennaOpacity;
  final statusBatteryBorderColor =
      merged.statusBarBatteryBorderColor ??
      CoreMockupDeviceStyle.defaultStatusBarBatteryBorderColor;

  // ─── Composed OutlinedContainer body ──────────────────
  // This component's own rail / rim / radius fields, with the nested
  // `containerStyle` slot (shadow by default) layered on top. The body holds
  // no child: the rim, the antenna bands and the bezel are siblings painted
  // over it. Domain values stay raw — `OutlinedContainer`'s resolver emits
  // them.
  final frameStyle =
      CoreOutlinedContainerStyle(
        backgroundColor:
            merged.railColor ?? CoreMockupDeviceStyle.defaultRailColor,
        backgroundGradient: bodyGradient,
        borderColor:
            merged.borderColor ?? CoreMockupDeviceStyle.defaultBorderColor,
        borderRadius: borderRadius,
        borderWidth: borderWidth,
      ).merge(
        CoreMockupDeviceStyle.defaultContainerStyle.merge(
          merged.containerStyle,
        ),
      );

  // ─── Stage 2 EMIT (Web, theme-free) ───────────────────
  // Every colour routes through the emit family and never reads the theme: a
  // token-bound fill becomes a Tailwind class, a raw one goes inline. The
  // screen and the bars sit on tokens that follow the mode. The hardware —
  // its fills, its gradients and its ring strokes — is the designer copy's
  // literals, emitted as they are, so the device does not change with the
  // mode or the palette.
  final bezelEmit = emitColor(
    merged.bezelColor,
    CoreMockupDeviceStyle.defaultBezelColor,
    .background,
  );
  final screenEmit = emitColor(
    merged.backgroundColor,
    CoreMockupDeviceStyle.defaultBackgroundColor,
    .background,
  );
  final lensEmit = emitColor(
    merged.lensColor,
    CoreMockupDeviceStyle.defaultLensColor,
    .background,
  );
  final cutoutEmit = emitColor(
    merged.cutoutColor,
    CoreMockupDeviceStyle.defaultCutoutColor,
    .background,
  );
  // The cut-out has no fill of its own: it takes the lens fill when it is
  // the lens, the cut-out fill when it holds a ring (the Core layout says
  // which — the same answer the Flutter resolver and the Figma builder
  // read).
  final cameraEmit = layout.cameraIsLens ? lensEmit : cutoutEmit;
  final lensHighlightEmit = emitColor(
    merged.lensHighlightColor,
    CoreMockupDeviceStyle.defaultLensHighlightColor,
    .background,
  );
  final gestureBarEmit = emitColor(
    merged.gestureBarColor,
    CoreMockupDeviceStyle.defaultGestureBarColor,
    .background,
  );
  final buttonEmit = emitColor(
    merged.buttonColor,
    CoreMockupDeviceStyle.defaultButtonColor,
    .background,
  );
  // Status bar glyphs are drawn with `fill="currentColor"`, so their colour
  // is a text colour on the `<svg>`; the battery level is a plain box.
  final iconTextEmit = emitColor(
    merged.statusBarIconColor,
    CoreMockupDeviceStyle.defaultStatusBarIconColor,
    .text,
  );
  final iconFillEmit = emitColor(
    merged.statusBarIconColor,
    CoreMockupDeviceStyle.defaultStatusBarIconColor,
    .background,
  );
  final capTextEmit = emitColor(
    merged.statusBarBatteryCapColor,
    CoreMockupDeviceStyle.defaultStatusBarBatteryCapColor,
    .text,
  );

  // ─── Local builders ───────────────────────────────────

  /// Logical px → `rem` (root-font reactive, like every other inline
  /// dimension on this platform).
  String rem(double px) => '${px / kRemDivisor}rem';

  /// Half the short side as a CSS radius — a pill for an oblong, a
  /// circle for a square. Derived, never stated.
  String pillRadius(CoreMockupDeviceRect r) =>
      rem((r.width < r.height ? r.width : r.height) / 2);

  /// The four inline offsets of an absolute rectangle.
  Map<String, String> boxStyles(CoreMockupDeviceRect r) => {
    'left': rem(r.left),
    'top': rem(r.top),
    'width': rem(r.width),
    'height': rem(r.height),
  };

  /// The absolute-rectangle inline bundle every hardware part shares.
  Map<String, String> rectStyles(CoreMockupDeviceRect r) => {
    ...boxStyles(r),
    'border-radius': pillRadius(r),
  };

  /// Joins class fragments, dropping the empty ones.
  String joinClasses(Iterable<String> fragments) =>
      fragments.where((c) => c.isNotEmpty).join(' ');

  /// A stroke drawn inside the box as an inset ring. A ring (a box-shadow
  /// with spread) rather than a CSS border: a border is snapped to whole
  /// device pixels and a half-pixel hairline would draw as a whole one. The
  /// width is a literal: every stroke of the device is part of its picture,
  /// which a surface style's stroke floor does not reach.
  String insetRing(double width, CoreColor color) =>
      'inset 0 0 0 ${pictureStrokeCss(width)} ${color.toValue()}';

  /// A stroke drawn outside the box, the outline counterpart of [insetRing].
  String outsetRing(double width, CoreColor color) =>
      '0 0 0 ${pictureStrokeCss(width)} ${color.toValue()}';

  /// One flat hardware part — `absolute` plus its pill rectangle and fill.
  WebElementChrome part(CoreMockupDeviceRect r, Emit fill) => .new(
    className: joinClasses([WebLayout.absolute, fill.className]),
    inlineStyles: Styles(raw: {...rectStyles(r), ...?fill.inline}),
  );

  /// One side button: the solid under the gloss along its length under the
  /// shade across its thickness (the first background layer is the top one).
  /// Both gradients are pointed by the layout for the edge the button is on.
  WebElementChrome button(CoreMockupDeviceRect r, CoreMockupDeviceEdge edge) {
    final gloss = CoreMockupDeviceLayout.buttonLengthGradient(
      buttonLengthGradient,
      edge,
    );
    final shade = CoreMockupDeviceLayout.buttonDepthGradient(
      buttonDepthColor,
      edge,
    );

    return .new(
      className: joinClasses([WebLayout.absolute, buttonEmit.className]),
      inlineStyles: Styles(
        raw: {
          ...rectStyles(r),
          ...?buttonEmit.inline,
          'background-image': '${shade.toValue()}, ${gloss.toValue()}',
        },
      ),
    );
  }

  /// One antenna band: a rectangle (no rounding) of the pale gradient, drawn
  /// top to bottom in the band's own frame, at the band's layer opacity.
  WebElementChrome antennaBand(CoreMockupDeviceRect r) => .new(
    className: WebLayout.absolute,
    inlineStyles: Styles(
      raw: {
        ...boxStyles(r),
        'background-image': antennaGradient.toValue(),
        'opacity': '$antennaOpacity',
      },
    ),
  );

  /// `justify-content` of a status bar group along its box.
  String justify(CoreMainAxisAlignment alignment) => switch (alignment) {
    .start => WebLayout.justifyStart,
    .end => WebLayout.justifyEnd,
    .center => WebLayout.justifyCenter,
    .spaceBetween => WebLayout.justifyBetween,
    .spaceAround => WebLayout.justifyAround,
    .spaceEvenly => WebLayout.justifyEvenly,
  };

  /// The gap to the next item of a status bar group, as a right margin (the
  /// last item states none). Physical, not logical: a device does not mirror
  /// when the text does. Pinned — the device's layout, not spacing.
  Map<String, String> gapAfter(CoreMockupStatusBarItem item) => {
    if (item.gapAfter > 0) 'margin-right': pinnedLengthCss(item.gapAfter),
  };

  /// A vector glyph's drawing: its own box as the `viewBox`, so the element
  /// scales it to whatever box the layout gives it.
  ResolvedMockupDeviceStatusContent glyphContent(CoreVectorGlyph glyph) =>
      .glyph(
        path: glyph.path,
        viewBox: '0 0 ${glyph.width} ${glyph.height}',
        fillRule: switch (glyph.fillRule) {
          .evenOdd => 'evenodd',
          .nonZero => 'nonzero',
        },
      );

  /// One status bar item, whatever it is. The text is the role's own, shrunk
  /// to the bar's scale.
  ResolvedMockupDeviceStatusItem statusItem(
    CoreMockupStatusBarItem item,
    double scale,
  ) {
    switch (item) {
      case final CoreMockupStatusBarText label:
        final text = emitScaledTypography(
          merged.statusBarTextStyle,
          byDevice.statusBarTextStyle!,
          factor: scale,
        );

        return ResolvedMockupDeviceStatusItem(
          root: WebElementChrome(
            className: joinClasses([
              WebLayout.whitespaceNowrap,
              WebLayout.shrinkZero,
              text.className,
            ]),
            inlineStyles: Styles(raw: {...?text.inline, ...gapAfter(label)}),
          ),
          content: .text(label.text),
        );
      case final CoreMockupStatusBarGlyph glyph:
        return ResolvedMockupDeviceStatusItem(
          root: WebElementChrome(
            className: joinClasses([
              WebLayout.shrinkZero,
              iconTextEmit.className,
            ]),
            inlineStyles: Styles(
              raw: {
                'width': rem(glyph.width),
                'height': rem(glyph.height),
                ...gapAfter(glyph),
                ...?iconTextEmit.inline,
              },
            ),
          ),
          content: glyphContent(glyph.glyph),
        );
      case final CoreMockupStatusBarBattery battery:
        return ResolvedMockupDeviceStatusItem(
          root: WebElementChrome(
            className: joinClasses([
              WebLayout.relative,
              WebLayout.shrinkZero,
            ]),
            inlineStyles: Styles(
              raw: {
                'width': rem(battery.width),
                'height': rem(battery.height),
                ...gapAfter(battery),
              },
            ),
          ),
          content: const .none(),
          parts: [
            // The outline: a faint ring inside its box.
            ResolvedMockupDeviceStatusItem(
              root: WebElementChrome(
                className: WebLayout.absolute,
                inlineStyles: Styles(
                  raw: {
                    ...boxStyles(battery.border),
                    'border-radius': rem(battery.borderRadius),
                    'box-shadow': insetRing(
                      battery.borderWidth,
                      statusBatteryBorderColor,
                    ),
                  },
                ),
              ),
              content: const .none(),
            ),
            // The level, inset evenly from the outline.
            ResolvedMockupDeviceStatusItem(
              root: WebElementChrome(
                className: joinClasses([
                  WebLayout.absolute,
                  iconFillEmit.className,
                ]),
                inlineStyles: Styles(
                  raw: {
                    ...boxStyles(battery.capacity),
                    'border-radius': rem(battery.capacityRadius),
                    ...?iconFillEmit.inline,
                  },
                ),
              ),
              content: const .none(),
            ),
            // The nub beside the outline: a drawing.
            ResolvedMockupDeviceStatusItem(
              root: WebElementChrome(
                className: joinClasses([
                  WebLayout.absolute,
                  capTextEmit.className,
                ]),
                inlineStyles: Styles(
                  raw: {...boxStyles(battery.cap), ...?capTextEmit.inline},
                ),
              ),
              content: glyphContent(battery.capGlyph),
            ),
          ],
        );
    }
  }

  // ─── Compose paint-ready chrome ───────────────────────
  final bezelShadows = <String>[
    if (bezelBorderWidth > 0) outsetRing(bezelBorderWidth, bezelBorderColor),
    if (bezelInnerShadowBlur > 0 || bezelInnerShadowSpread > 0)
      emitShadow(
        [
          (
            offsetX: 0,
            offsetY: 0,
            blurRadius: bezelInnerShadowBlur,
            spreadRadius: bezelInnerShadowSpread,
            opacity: 1,
            inset: true,
          ),
        ],
        base: bezelInnerShadowColor.toValue(),
      ),
  ];
  // A rim with no width is no rim (the `flat` finish): no layer at all.
  final hasRimHighlight = rimHighlightWidth > 0;
  final hasRimGlow = rimGlowWidth > 0;
  final safeArea = layout.safeAreaInsets(
    showCamera: cameraShown,
    showStatusBar: statusBarShown,
    showGestureBar: gestureBarShown,
  );

  // The camera set shares one space: the screen's or the bezel's. The parts
  // are the same either way; only which parent they stand in differs, so the
  // widget reads two lists and one of them is empty.
  final cameraParts = <WebElementChrome>[
    part(layout.camera, cameraEmit),
    if (layout.lens != null) part(layout.lens!, lensEmit),
    // The core is a gradient unless a caller stated a solid cut-out colour.
    if (coreGradient == null)
      part(layout.core, cutoutEmit)
    else
      WebElementChrome(
        className: WebLayout.absolute,
        inlineStyles: Styles(
          raw: {
            ...rectStyles(layout.core),
            'background-image': coreGradient.toValue(),
          },
        ),
      ),
    part(layout.lensHighlight, lensHighlightEmit),
  ];
  final cameraOnScreen = layout.cameraPlacement == .screen;

  final status = statusBarShown ? layout.statusBar : null;
  final statusBar = status == null
      ? null
      : ResolvedMockupDeviceStatusBar(
          root: WebElementChrome(
            className: joinClasses([
              WebLayout.absolute,
              screenEmit.className,
            ]),
            inlineStyles: Styles(
              raw: {
                ...boxStyles(status.rect),
                // The groups lay out left to right under any root direction,
                // as the device does not mirror with the text.
                'direction': 'ltr',
                ...?screenEmit.inline,
              },
            ),
          ),
          leading: WebElementChrome(
            className: joinClasses([
              WebLayout.absolute,
              WebLayout.flexItemsCenter,
              justify(status.leading.alignment),
            ]),
            inlineStyles: Styles(raw: boxStyles(status.leading.box)),
          ),
          trailing: WebElementChrome(
            className: joinClasses([
              WebLayout.absolute,
              WebLayout.flexItemsCenter,
              justify(status.trailing.alignment),
            ]),
            inlineStyles: Styles(raw: boxStyles(status.trailing.box)),
          ),
          leadingItems: [
            for (final item in status.leading.items)
              statusItem(item, status.scale),
          ],
          trailingItems: [
            for (final item in status.trailing.items)
              statusItem(item, status.scale),
          ],
        );

  return ResolvedMockupDevice(
    root: WebElementChrome(
      className: joinClasses([WebLayout.relative, WebLayout.inlineFlex]),
      inlineStyles: Styles(
        raw: {
          'width': rem(layout.deviceWidth),
          'height': rem(layout.deviceHeight),
        },
      ),
    ),
    frame: const WebElementChrome(className: WebLayout.absoluteFull),
    frameStyle: frameStyle,
    rimHighlight: hasRimHighlight
        ? WebElementChrome(
            className: WebLayout.absolute,
            inlineStyles: Styles(
              raw: {
                ...boxStyles(layout.rimHighlight),
                // Not deflated: the stroke follows the body's own corners.
                'border-radius': borderRadius.toValue(),
                'box-shadow': insetRing(rimHighlightWidth, rimHighlightColor),
              },
            ),
          )
        : null,
    rimGlow: hasRimGlow
        ? WebElementChrome(
            className: WebLayout.absolute,
            inlineStyles: Styles(
              raw: {
                ...boxStyles(layout.rimGlow),
                'opacity': '$rimGlowOpacity',
                if (rimGlowBlur > 0) 'filter': figmaLayerBlurCss(rimGlowBlur),
              },
            ),
          )
        : null,
    rimGlowRing: hasRimGlow
        ? WebElementChrome(
            className: WebLayout.absoluteFull,
            inlineStyles: Styles(
              raw: {
                'box-sizing': 'border-box',
                'padding': pictureStrokeCss(rimGlowWidth),
                'border-radius': borderRadius.toValue(),
                'background-image': rimGlowGradient.toValue(),
                '-webkit-mask':
                    '$_kRingMaskLayer content-box, $_kRingMaskLayer',
                '-webkit-mask-composite': 'xor',
                'mask': '$_kRingMaskLayer content-box, $_kRingMaskLayer',
                'mask-composite': 'exclude',
              },
            ),
          )
        : null,
    antennaBands: [
      for (final band in layout.antennaBands) antennaBand(band.rect),
    ],
    bezel: WebElementChrome(
      className: joinClasses([WebLayout.absolute, bezelEmit.className]),
      inlineStyles: Styles(
        raw: {
          ...boxStyles(layout.bezelBox),
          'border-radius': layout.bezelBorderRadius.toValue(),
          ...?bezelEmit.inline,
          // The outline lands outside the box, in the rail; the inner glow
          // is the glass meeting the frame. A finish that states neither
          // (the `flat` frame) emits no shadow at all.
          ...bezelShadows.isEmpty
              ? const <String, String>{}
              : {'box-shadow': bezelShadows.join(', ')},
        },
      ),
    ),
    screen: WebElementChrome(
      className: joinClasses([
        WebLayout.absolute,
        WebLayout.overflowHidden,
        screenEmit.className,
      ]),
      inlineStyles: Styles(
        raw: {
          // The screen sits `bezelWidth` in from the bezel box.
          'left': rem(layout.screenBox.left - layout.bezelBox.left),
          'top': rem(layout.screenBox.top - layout.bezelBox.top),
          'width': rem(layout.screenWidth),
          'height': rem(layout.screenHeight),
          'border-radius': layout.screenBorderRadius.toValue(),
          ...?screenEmit.inline,
        },
      ),
    ),
    content: WebElementChrome(
      className: WebLayout.absoluteFull,
      inlineStyles: Styles(
        raw: {
          'box-sizing': 'border-box',
          // The device's own safe area (status bar, camera, home bar) —
          // pinned, it is the picture's geometry rather than spacing.
          'padding-top': pinnedLengthCss(safeArea.top),
          'padding-right': pinnedLengthCss(safeArea.right),
          'padding-bottom': pinnedLengthCss(safeArea.bottom),
          'padding-left': pinnedLengthCss(safeArea.left),
        },
      ),
    ),
    statusBar: statusBar,
    screenCameraParts: cameraShown && cameraOnScreen ? cameraParts : const [],
    bezelCameraParts: cameraShown && !cameraOnScreen ? cameraParts : const [],
    gestureBar: gestureBarShown
        ? WebElementChrome(
            className: joinClasses([
              WebLayout.absolute,
              gestureBarEmit.className,
            ]),
            inlineStyles: Styles(
              raw: {
                ...boxStyles(layout.gestureBar),
                // A little under half the bar's height — rounded ends, not a
                // pill.
                'border-radius': rem(layout.gestureBarRadius),
                ...?gestureBarEmit.inline,
              },
            ),
          )
        : null,
    // A button with no length is no button (the `flat` finish): no part.
    powerButton: layout.hasPowerButton
        ? button(layout.powerButton, layout.powerButtonEdge)
        : null,
    volumeUpButton: layout.hasVolumeButton
        ? button(layout.volumeUpButton, layout.volumeButtonEdge)
        : null,
    volumeDownButton: layout.volumeDownButton == null
        ? null
        : button(layout.volumeDownButton!, layout.volumeButtonEdge),
  );
}
