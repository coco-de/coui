/// Per-instance style for `Window`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/window_panel/window_panel_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing chrome / dimensional overrides for a
/// `Window`.
///
/// `CoreWindowStyle` carries the flat dimensional slot
/// (`titleBarHeight`). The window itself delegates
/// the visual chrome (title bar / outline / radius / shadow) to
/// `WindowPanel`, so surface-level styling lives in
/// `CoreWindowPanelStyle` instead.
///
/// Resolve chain per Epic #1302:
///
/// ```text
/// design system default (CoreWindowStyle.defaultX)
///   → CoreWindowTheme.style                           // 프로젝트 공통
///   → parent component slot override
///   → widget.windowStyle                              // 인스턴스별
/// ```
@immutable
class CoreWindowStyle implements CoreStyle<CoreWindowStyle> {
  /// Creates a [CoreWindowStyle].
  const CoreWindowStyle({
    this.titleBarHeight,
    this.snapPreviewBorderRadius,
    this.snapBarBorderRadius,
    this.snapTileBorderRadius,
    this.snapTileInnerBorderRadius,
    this.snapBarShadow,
    this.snapBarTileSpacing,
    this.snapBarPadding,
    this.snapPreviewBorderColor,
    this.snapPreviewBackgroundColor,
    this.snapBarBorderColor,
    this.snapBarBackgroundColor,
    this.snapBarBorderWidth,
    this.snapBarHeight,
    this.snapBarTopOffset,
    this.snapBarHiddenOffset,
    this.snapBarAnimation,
    this.snapTileSpacing,
    this.windowTransition,
    this.minimizedScale,
    this.closeAnimationScaleMin,
    this.closeAnimationScaleMax,
    this.snapPreviewBlurSigma,
    this.snapTileBorderColor,
    this.snapTileBorderWidth,
    this.snapTileBackgroundColor,
    this.snapTileHoverBackgroundColor,
    this.unfocusedTitleStyle,
    this.panelStyle,
  });

  // ═══════════════════════════════════════════════════
  // 1. Defaults — single (Phase 6f/6g, variant-independent)
  // ═══════════════════════════════════════════════════
  //
  // Design-system defaults consumed by the Flutter / Web window
  // resolvers and the navigator's snap-bar / open-close transition.
  // Single source of truth shared across platforms — Flutter and Web
  // can only diverge via an explicit per-instance override.

  /// Default title bar height in logical/CSS px (pre-scaling).
  static const double defaultTitleBarHeight = CoreSpace.space32;

  /// Default border radius for the floating snap-preview overlay
  /// (semi-transparent surface shown while dragging a window into a
  /// snap zone) — the panel role, the same corner as a window.
  /// Web consumes via the `tailwindRadius` adapter, Flutter via
  /// `BorderRadius.circular(...)`.
  static const CoreBorderRadius defaultSnapPreviewBorderRadius =
      CoreBorderRadius.all(CoreRadiusRole.panel);

  /// Default border radius for the snap-bar banner container (the
  /// rounded strip that drops down from the navigator top while a
  /// window is being dragged) — the panel role. Web via `tailwindRadius`,
  /// Flutter via `BorderRadius.circular(...)`.
  static const CoreBorderRadius defaultSnapBarBorderRadius =
      CoreBorderRadius.all(CoreRadiusRole.panel);

  /// Default corner of a snap-bar tile on the preset's outer edge (the
  /// edge that sits against the banner). A tile sits one banner padding
  /// inside the banner, so its outer corner is the banner's corner minus
  /// that padding (12 − 8 = 4) and stays concentric with it. Web via
  /// `tailwindRadius`, Flutter via `BorderRadius.circular(...)`.
  static const CoreBorderRadius defaultSnapTileBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius4);

  /// Default corner of a snap-bar tile on an edge it shares with a
  /// sibling tile — half the outer corner, so abutting tiles read as one
  /// preset.
  static const CoreBorderRadius defaultSnapTileInnerBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius2);

  /// Default drop shadow of the snap-bar banner — the `lg` step of the
  /// shadow scale ([CoreShadow.lg]), the same layers the canvas's
  /// `shadow/lg` effect style states.
  static const List<CoreShadowLayer> defaultSnapBarShadow = CoreShadow.lg;

  /// Default spacing between adjacent tiles inside the snap-bar grid
  /// (8 logical/CSS px at 1x scaling). Flutter applies it as
  /// native `Row.spacing`; Web emits the matching CSS `gap` value on
  /// the flex container.
  static const double defaultSnapBarTileSpacing = CoreSpace.space8;

  /// Default inner padding of the snap-bar banner and the snap-preview
  /// overlay container (8 logical/CSS px at 1x scaling, symmetric on
  /// all four sides). Flutter applies it as `EdgeInsets`; Web emits
  /// the matching tailwind `p-*` class.
  static const CoreEdgeInsets defaultSnapBarPadding = CoreEdgeInsets.all(
    CoreSpace.space8,
  );

  /// Default outline colour of the floating snap-preview overlay border.
  static const CoreColor defaultSnapPreviewBorderColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default semi-transparent surface fill of the snap-preview overlay.
  ///
  /// Opacity `100 / 255` exactly mirrors the Flutter `_BlurContainer`'s
  /// legacy `surface.withAlpha(100)` backdrop (Flutter-first single
  /// source) so both platforms render the identical alpha byte.
  static const CoreColor defaultSnapPreviewBackgroundColor = CoreColor.token(
    CoreColors.surface,
    opacity: 100 / 255,
  );

  /// Default outline colour of the snap-bar banner container border.
  static const CoreColor defaultSnapBarBorderColor = CoreColor.token(
    CoreColors.outlineSubtle,
  );

  /// Default surface fill of the snap-bar banner container.
  static const CoreColor defaultSnapBarBackgroundColor = CoreColor.token(
    CoreColors.surfaceBright,
  );

  /// Default outline colour of each snap-bar tile border.
  static const CoreColor defaultSnapTileBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default surface fill of a snap-bar tile at rest (not hovered).
  static const CoreColor defaultSnapTileBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default fill of a snap-bar tile while hovered.
  static const CoreColor defaultSnapTileHoverBackgroundColor = CoreColor.token(
    CoreColors.secondary,
  );

  /// Default snap-bar drop-down show/hide animation duration.
  ///
  /// Matches the design-system "smooth" transition step; shared by
  /// Flutter (`Duration`) and Web (CSS `transition` value) so the two
  /// platforms cannot silently diverge. Overridden by
  /// [snapBarAnimation].
  static const Duration defaultSnapBarAnimation = Duration(
    milliseconds: CoreDuration.moderate,
  );

  /// Default window open / close / maximize transition duration.
  ///
  /// Matches the standard transition step; consumed by the Web CSS
  /// `transition` value for the floating window frame and by Flutter's
  /// open/close scale + opacity animation. Overridden by
  /// [windowTransition].
  static const Duration defaultWindowTransition = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Default scale of the window when minified during a drag-snap.
  /// Overridden by [minimizedScale].
  static const double defaultMinimizedScale = 0.65;

  /// Lower bound of the close-animation scale tween (opening start /
  /// closing target on Web; opening start on Flutter). Overridden by
  /// [closeAnimationScaleMin].
  static const double defaultCloseAnimationScaleMin = 0.8;

  /// Upper bound of the close-animation scale tween (Flutter-only —
  /// browsers animate the single `transform: scale(...)` directly).
  /// Overridden by [closeAnimationScaleMax].
  static const double defaultCloseAnimationScaleMax = 0.9;

  /// Default snap-bar banner height (logical/CSS px). Overridden by
  /// [snapBarHeight].
  static const double defaultSnapBarHeight = 100;

  /// Default top offset of the snap-bar banner (logical/CSS px).
  /// Overridden by [snapBarTopOffset].
  static const double defaultSnapBarTopOffset = 24;

  // Snap-bar tween anchors — coordinate-system sentinels, not design
  // decisions: the bar's slide position is expressed as a fraction of
  // its own height where -1 ≡ fully hidden above the edge and 0 ≡ at
  // rest. Changing these redefines the coordinate space itself (every
  // offset value would shift meaning), so they are deliberately NOT
  // per-instance style fields. Tunable motion design lives in
  // [snapBarHiddenOffset] (peek pose) instead; the fade tween spans
  // [snapBarHiddenOffset] → [defaultSnapBarTranslateRangeMax].

  /// Lower bound of the snap-bar Y translate tween (-1 = hidden above).
  static const double defaultSnapBarTranslateRangeMin = -1;

  /// Upper bound of the snap-bar Y translate tween (0 = at rest).
  static const double defaultSnapBarTranslateRangeMax = 0;

  /// Resting offset of the hidden snap-bar — the "peek" pose fraction
  /// (also the start of the content fade-in). Overridden by
  /// [snapBarHiddenOffset].
  static const double defaultSnapBarHiddenOffset = -0.85;

  /// Gaussian σ of the snap-preview ghost's backdrop blur — Flutter
  /// `ImageFilter.blur(sigmaX/Y:)` and CSS `backdrop-filter: blur(σpx)`
  /// share the same σ convention, so one constant drives both.
  /// Overridden by [snapPreviewBlurSigma].
  static const double defaultSnapPreviewBlurSigma = 8;

  /// Default border width of the snap-bar banner container in
  /// logical/CSS px — the same stroke both platform resolvers draw
  /// (Flutter `OutlinedContainer` outline / Web `border` class), also
  /// folded into the bar's content height by the tile-group layout.
  /// Overridden by [snapBarBorderWidth].
  static const double defaultSnapBarBorderWidth = CoreStrokeWidth.stroke1;

  /// Default border width of an individual snap-bar preset tile in
  /// logical/CSS px. Overridden by [snapTileBorderWidth].
  static const double defaultSnapTileBorderWidth = CoreStrokeWidth.stroke1;

  /// Default snap-bar tile gap in logical px used by the navigator
  /// render path — distinct from [defaultSnapBarTileSpacing] which is
  /// the layout token applied as Flutter `Row.spacing` / Web flex `gap`
  /// CSS on the container. Overridden by [snapTileSpacing].
  static const double defaultSnapTileSpacing = 2;

  /// Default chrome of the composed `WindowPanel` when FLOATING —
  /// nested slot raw-forwarded into the panel whose own resolver
  /// settles the final chrome (child-component-composition). A FULL
  /// maximize forces the corner radius to zero on top of this (the
  /// frame sits flush with every desktop edge), which is why the
  /// radius lives here rather than as an inline literal in each
  /// platform widget. The floating corner is the panel's own default
  /// ([CoreWindowPanelStyle.defaultBorderRadius]), so a window and a bare
  /// panel share one corner.
  static const CoreWindowPanelStyle defaultPanelStyle = CoreWindowPanelStyle(
    borderRadius: CoreWindowPanelStyle.defaultBorderRadius,
  );

  // ═══════════════════════════════════════════════════
  // 2. Props — per-instance overrides
  // ═══════════════════════════════════════════════════

  /// Title bar height in logical pixels.
  final double? titleBarHeight;

  /// Border radius for the floating snap-preview overlay (semi-transparent
  /// surface shown while dragging a window into a snap zone). Overrides
  /// [defaultSnapPreviewBorderRadius] when set.
  final CoreBorderRadius? snapPreviewBorderRadius;

  /// Border radius for the snap-bar banner container (the rounded strip
  /// that drops down from the navigator top while a window is being
  /// dragged). Overrides [defaultSnapBarBorderRadius] when set.
  final CoreBorderRadius? snapBarBorderRadius;

  /// Corner of a snap-bar tile on the preset's outer edge. Overrides
  /// [defaultSnapTileBorderRadius] when set.
  final CoreBorderRadius? snapTileBorderRadius;

  /// Corner of a snap-bar tile on an edge it shares with a sibling tile.
  /// Overrides [defaultSnapTileInnerBorderRadius] when set.
  final CoreBorderRadius? snapTileInnerBorderRadius;

  /// Drop shadow of the snap-bar banner (tinted by the `shadow` token).
  /// Overrides [defaultSnapBarShadow] when set.
  final List<CoreShadowLayer>? snapBarShadow;

  /// Spacing between adjacent tiles in the snap-bar grid (logical px).
  /// Flutter applies it as `Row.spacing`; Web sets the same value as the
  /// flex container's CSS `gap`. Overrides [defaultSnapBarTileSpacing]
  /// when set.
  final double? snapBarTileSpacing;

  /// Inner padding of the snap-bar banner / snap-preview container.
  /// Overrides [defaultSnapBarPadding] when set.
  final CoreEdgeInsets? snapBarPadding;

  /// Outline colour of the snap-preview overlay border.
  /// Overrides [defaultSnapPreviewBorderColor] when set.
  final CoreColor? snapPreviewBorderColor;

  /// Semi-transparent surface fill of the snap-preview overlay.
  /// Overrides [defaultSnapPreviewBackgroundColor] when set.
  final CoreColor? snapPreviewBackgroundColor;

  /// Outline colour of the snap-bar banner container border.
  /// Overrides [defaultSnapBarBorderColor] when set.
  final CoreColor? snapBarBorderColor;

  /// Surface fill of the snap-bar banner container.
  /// Overrides [defaultSnapBarBackgroundColor] when set.
  final CoreColor? snapBarBackgroundColor;

  /// Border width of the snap-bar banner container.
  /// Overrides [defaultSnapBarBorderWidth] when set.
  final double? snapBarBorderWidth;

  /// Height of the snap-bar banner (logical/CSS px).
  /// Overrides [defaultSnapBarHeight] when set.
  final double? snapBarHeight;

  /// Top offset of the expanded snap-bar banner (logical/CSS px).
  /// Overrides [defaultSnapBarTopOffset] when set.
  final double? snapBarTopOffset;

  /// Resting "peek" pose of the hidden snap-bar as a fraction of its
  /// height (−1 = fully hidden, 0 = fully shown); also the start of
  /// the content fade-in. Overrides [defaultSnapBarHiddenOffset] when
  /// set.
  final double? snapBarHiddenOffset;

  /// Snap-bar drop-down show/hide animation duration.
  /// Overrides [defaultSnapBarAnimation] when set.
  final Duration? snapBarAnimation;

  /// Inner gap between abutting snap-bar tiles (logical px).
  /// Overrides [defaultSnapTileSpacing] when set.
  final double? snapTileSpacing;

  /// Window open / close / maximize transition duration.
  /// Overrides [defaultWindowTransition] when set.
  final Duration? windowTransition;

  /// Scale of the window while minified during a drag-snap.
  /// Overrides [defaultMinimizedScale] when set.
  final double? minimizedScale;

  /// Lower bound of the close-animation scale tween.
  /// Overrides [defaultCloseAnimationScaleMin] when set.
  final double? closeAnimationScaleMin;

  /// Upper bound of the close-animation scale tween.
  /// Overrides [defaultCloseAnimationScaleMax] when set.
  final double? closeAnimationScaleMax;

  /// Gaussian σ of the snap-preview ghost's backdrop blur.
  /// Overrides [defaultSnapPreviewBlurSigma] when set.
  final double? snapPreviewBlurSigma;

  /// Outline colour of each snap-bar tile border.
  /// Overrides [defaultSnapTileBorderColor] when set.
  final CoreColor? snapTileBorderColor;

  /// Border width of each snap-bar tile in logical/CSS px.
  /// Overrides [defaultSnapTileBorderWidth] when set.
  final double? snapTileBorderWidth;

  /// Fill of a snap-bar tile at rest. Overrides
  /// [defaultSnapTileBackgroundColor] when set.
  final CoreColor? snapTileBackgroundColor;

  /// Fill of a snap-bar tile while hovered. Overrides
  /// [defaultSnapTileHoverBackgroundColor] when set.
  final CoreColor? snapTileHoverBackgroundColor;

  /// Title-text overlay merged onto the panel's `titleStyle` for every
  /// window EXCEPT the frontmost one — both platforms dim unfocused
  /// titles with it (reference behaviour: focused = onSurface, rest =
  /// muted). Overrides [defaultUnfocusedTitleStyle] when set.
  final CoreTextStyle? unfocusedTitleStyle;

  /// Look of the `WindowPanel` inside the window, passed to the panel as
  /// is. Laid over [defaultPanelStyle]; while the window is fully
  /// maximized, its corner radius is forced to zero.
  ///
  /// A nested slot, raw-forwarded into the panel
  /// (child-component-composition).
  final CoreWindowPanelStyle? panelStyle;

  /// Default unfocused-title overlay: colour-only (onSurfaceVariant),
  /// so the panel's own title typography role/weight stay intact.
  static const CoreTextStyle defaultUnfocusedTitleStyle = CoreTextStyle(
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Returns a copy with non-null fields from [other] overriding the
  /// matching fields here.
  @override
  CoreWindowStyle merge(CoreWindowStyle? other) {
    if (other == null) return this;
    return CoreWindowStyle(
      titleBarHeight: other.titleBarHeight ?? titleBarHeight,
      snapPreviewBorderRadius:
          other.snapPreviewBorderRadius ?? snapPreviewBorderRadius,
      snapBarBorderRadius: other.snapBarBorderRadius ?? snapBarBorderRadius,
      snapTileBorderRadius: other.snapTileBorderRadius ?? snapTileBorderRadius,
      snapTileInnerBorderRadius:
          other.snapTileInnerBorderRadius ?? snapTileInnerBorderRadius,
      snapBarShadow: other.snapBarShadow ?? snapBarShadow,
      snapBarTileSpacing: other.snapBarTileSpacing ?? snapBarTileSpacing,
      snapBarPadding: other.snapBarPadding ?? snapBarPadding,
      snapPreviewBorderColor:
          other.snapPreviewBorderColor ?? snapPreviewBorderColor,
      snapPreviewBackgroundColor:
          other.snapPreviewBackgroundColor ?? snapPreviewBackgroundColor,
      snapBarBorderColor: other.snapBarBorderColor ?? snapBarBorderColor,
      snapBarBackgroundColor:
          other.snapBarBackgroundColor ?? snapBarBackgroundColor,
      snapBarBorderWidth: other.snapBarBorderWidth ?? snapBarBorderWidth,
      snapBarHeight: other.snapBarHeight ?? snapBarHeight,
      snapBarTopOffset: other.snapBarTopOffset ?? snapBarTopOffset,
      snapBarHiddenOffset: other.snapBarHiddenOffset ?? snapBarHiddenOffset,
      snapBarAnimation: other.snapBarAnimation ?? snapBarAnimation,
      snapTileSpacing: other.snapTileSpacing ?? snapTileSpacing,
      windowTransition: other.windowTransition ?? windowTransition,
      minimizedScale: other.minimizedScale ?? minimizedScale,
      closeAnimationScaleMin:
          other.closeAnimationScaleMin ?? closeAnimationScaleMin,
      closeAnimationScaleMax:
          other.closeAnimationScaleMax ?? closeAnimationScaleMax,
      snapPreviewBlurSigma: other.snapPreviewBlurSigma ?? snapPreviewBlurSigma,
      snapTileBorderColor: other.snapTileBorderColor ?? snapTileBorderColor,
      snapTileBorderWidth: other.snapTileBorderWidth ?? snapTileBorderWidth,
      snapTileBackgroundColor:
          other.snapTileBackgroundColor ?? snapTileBackgroundColor,
      snapTileHoverBackgroundColor:
          other.snapTileHoverBackgroundColor ?? snapTileHoverBackgroundColor,
      unfocusedTitleStyle:
          unfocusedTitleStyle?.merge(other.unfocusedTitleStyle) ??
          other.unfocusedTitleStyle,
      panelStyle: panelStyle?.merge(other.panelStyle) ?? other.panelStyle,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreWindowStyle copyWith({
    double? titleBarHeight,
    CoreBorderRadius? snapPreviewBorderRadius,
    CoreBorderRadius? snapBarBorderRadius,
    CoreBorderRadius? snapTileBorderRadius,
    CoreBorderRadius? snapTileInnerBorderRadius,
    List<CoreShadowLayer>? snapBarShadow,
    double? snapBarTileSpacing,
    CoreEdgeInsets? snapBarPadding,
    CoreColor? snapPreviewBorderColor,
    CoreColor? snapPreviewBackgroundColor,
    CoreColor? snapBarBorderColor,
    CoreColor? snapBarBackgroundColor,
    double? snapBarBorderWidth,
    double? snapBarHeight,
    double? snapBarTopOffset,
    double? snapBarHiddenOffset,
    Duration? snapBarAnimation,
    double? snapTileSpacing,
    Duration? windowTransition,
    double? minimizedScale,
    double? closeAnimationScaleMin,
    double? closeAnimationScaleMax,
    double? snapPreviewBlurSigma,
    CoreColor? snapTileBorderColor,
    double? snapTileBorderWidth,
    CoreColor? snapTileBackgroundColor,
    CoreColor? snapTileHoverBackgroundColor,
    CoreTextStyle? unfocusedTitleStyle,
    CoreWindowPanelStyle? panelStyle,
  }) {
    return CoreWindowStyle(
      titleBarHeight: titleBarHeight ?? this.titleBarHeight,
      snapPreviewBorderRadius:
          snapPreviewBorderRadius ?? this.snapPreviewBorderRadius,
      snapBarBorderRadius: snapBarBorderRadius ?? this.snapBarBorderRadius,
      snapTileBorderRadius: snapTileBorderRadius ?? this.snapTileBorderRadius,
      snapTileInnerBorderRadius:
          snapTileInnerBorderRadius ?? this.snapTileInnerBorderRadius,
      snapBarShadow: snapBarShadow ?? this.snapBarShadow,
      snapBarTileSpacing: snapBarTileSpacing ?? this.snapBarTileSpacing,
      snapBarPadding: snapBarPadding ?? this.snapBarPadding,
      snapPreviewBorderColor:
          snapPreviewBorderColor ?? this.snapPreviewBorderColor,
      snapPreviewBackgroundColor:
          snapPreviewBackgroundColor ?? this.snapPreviewBackgroundColor,
      snapBarBorderColor: snapBarBorderColor ?? this.snapBarBorderColor,
      snapBarBackgroundColor:
          snapBarBackgroundColor ?? this.snapBarBackgroundColor,
      snapBarBorderWidth: snapBarBorderWidth ?? this.snapBarBorderWidth,
      snapBarHeight: snapBarHeight ?? this.snapBarHeight,
      snapBarTopOffset: snapBarTopOffset ?? this.snapBarTopOffset,
      snapBarHiddenOffset: snapBarHiddenOffset ?? this.snapBarHiddenOffset,
      snapBarAnimation: snapBarAnimation ?? this.snapBarAnimation,
      snapTileSpacing: snapTileSpacing ?? this.snapTileSpacing,
      windowTransition: windowTransition ?? this.windowTransition,
      minimizedScale: minimizedScale ?? this.minimizedScale,
      closeAnimationScaleMin:
          closeAnimationScaleMin ?? this.closeAnimationScaleMin,
      closeAnimationScaleMax:
          closeAnimationScaleMax ?? this.closeAnimationScaleMax,
      snapPreviewBlurSigma: snapPreviewBlurSigma ?? this.snapPreviewBlurSigma,
      snapTileBorderColor: snapTileBorderColor ?? this.snapTileBorderColor,
      snapTileBorderWidth: snapTileBorderWidth ?? this.snapTileBorderWidth,
      snapTileBackgroundColor:
          snapTileBackgroundColor ?? this.snapTileBackgroundColor,
      snapTileHoverBackgroundColor:
          snapTileHoverBackgroundColor ?? this.snapTileHoverBackgroundColor,
      unfocusedTitleStyle: unfocusedTitleStyle ?? this.unfocusedTitleStyle,
      panelStyle: panelStyle ?? this.panelStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreWindowStyle &&
          runtimeType == other.runtimeType &&
          titleBarHeight == other.titleBarHeight &&
          snapPreviewBorderRadius == other.snapPreviewBorderRadius &&
          snapBarBorderRadius == other.snapBarBorderRadius &&
          snapTileBorderRadius == other.snapTileBorderRadius &&
          snapTileInnerBorderRadius == other.snapTileInnerBorderRadius &&
          _shadowEquals(snapBarShadow, other.snapBarShadow) &&
          snapBarTileSpacing == other.snapBarTileSpacing &&
          snapBarPadding == other.snapBarPadding &&
          snapPreviewBorderColor == other.snapPreviewBorderColor &&
          snapPreviewBackgroundColor == other.snapPreviewBackgroundColor &&
          snapBarBorderColor == other.snapBarBorderColor &&
          snapBarBackgroundColor == other.snapBarBackgroundColor &&
          snapBarBorderWidth == other.snapBarBorderWidth &&
          snapBarHeight == other.snapBarHeight &&
          snapBarTopOffset == other.snapBarTopOffset &&
          snapBarHiddenOffset == other.snapBarHiddenOffset &&
          snapBarAnimation == other.snapBarAnimation &&
          snapTileSpacing == other.snapTileSpacing &&
          windowTransition == other.windowTransition &&
          minimizedScale == other.minimizedScale &&
          closeAnimationScaleMin == other.closeAnimationScaleMin &&
          closeAnimationScaleMax == other.closeAnimationScaleMax &&
          snapPreviewBlurSigma == other.snapPreviewBlurSigma &&
          snapTileBorderColor == other.snapTileBorderColor &&
          snapTileBorderWidth == other.snapTileBorderWidth &&
          snapTileBackgroundColor == other.snapTileBackgroundColor &&
          snapTileHoverBackgroundColor == other.snapTileHoverBackgroundColor &&
          unfocusedTitleStyle == other.unfocusedTitleStyle &&
          panelStyle == other.panelStyle;

  @override
  int get hashCode => Object.hashAll([
    titleBarHeight,
    snapPreviewBorderRadius,
    snapBarBorderRadius,
    snapTileBorderRadius,
    snapTileInnerBorderRadius,
    Object.hashAll(snapBarShadow ?? const <CoreShadowLayer>[]),
    snapBarTileSpacing,
    snapBarPadding,
    snapPreviewBorderColor,
    snapPreviewBackgroundColor,
    snapBarBorderColor,
    snapBarBackgroundColor,
    snapBarBorderWidth,
    snapBarHeight,
    snapBarTopOffset,
    snapBarHiddenOffset,
    snapBarAnimation,
    snapTileSpacing,
    windowTransition,
    minimizedScale,
    closeAnimationScaleMin,
    closeAnimationScaleMax,
    snapPreviewBlurSigma,
    snapTileBorderColor,
    snapTileBorderWidth,
    snapTileBackgroundColor,
    snapTileHoverBackgroundColor,
    unfocusedTitleStyle,
    panelStyle,
  ]);

  /// Element-wise equality for the shadow layer list (records compare by
  /// value, lists by identity — so `==` alone would miss equal layers).
  static bool _shadowEquals(
    List<CoreShadowLayer>? a,
    List<CoreShadowLayer>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
