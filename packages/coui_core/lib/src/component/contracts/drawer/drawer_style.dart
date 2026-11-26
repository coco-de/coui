/// Per-instance style for `Drawer`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/divider/divider_style.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/focus_ring.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/control_size.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/layout.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Drawer` should render.
///
/// `CoreDrawerStyle` carries panel chrome / dimensional /
/// barrier / animation overrides as platform-neutral domain-typed
/// fields, plus nested `CoreTextStyle`s for the title and description,
/// a nested `CoreGapStyle` between them, a nested `CoreButtonStyle` for
/// the header close-button affordance, and the grab-handle pill's chrome
/// (`dragHandle*`, drawn when the widget's `showDragHandle` is on).
///
/// Variant-independent design-system defaults live as `static const`
/// on this class — Flutter and Web resolvers reference the same
/// `CoreDrawerStyle.defaultX` so the two platforms cannot silently
/// diverge. The drawer has no visual variant; its semantic
/// `CoreDrawerSide` enum lives on the widget, not on this style
/// (Epic #1302 원칙 6/7).
///
/// ```text
/// design system default (CoreDrawerStyle.defaultX)
///   → CoreDrawerTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.drawerStyle                          // 인스턴스별
/// ```
@immutable
class CoreDrawerStyle implements CoreStyle<CoreDrawerStyle> {
  /// Creates a [CoreDrawerStyle].
  const CoreDrawerStyle({
    this.panelBackgroundColor,
    this.panelBorderColor,
    this.panelBorderRadius,
    this.panelBorderWidth,
    this.panelWidth,
    this.panelHeight,
    this.panelPadding,
    this.headerPadding,
    this.headerSpacing,
    this.footerPadding,
    this.panelBoxShadow,
    this.shadowBaseColor,
    this.barrierColor,
    this.barrierOpacity,
    this.backdropScale,
    this.backdropCornerRadius,
    this.openAnimationDuration,
    this.closeAnimationDuration,
    this.titleStyle,
    this.closeButtonStyle,
    this.dividerStyle,
    this.descriptionStyle,
    this.titleDescriptionGapStyle,
    this.dragHandleColor,
    this.dragHandleWidth,
    this.dragHandleThickness,
    this.dragHandleInset,
    this.dragHandleBorderRadius,
  });

  // ── Design-system defaults ────────────────────
  //
  // Variant-independent defaults — single source of truth shared by
  // the Flutter and Web resolvers. The drawer has no visual variant
  // so there is no `defaultsByVariant` map.

  /// Default panel background fill.
  static const CoreColor defaultPanelBackgroundColor = CoreColor.token(
    CoreColors.surfaceBright,
  );

  /// Default panel border stroke colour — the line on the panel's inner
  /// edge, a step quieter than the control outline.
  static const CoreColor defaultPanelBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default panel corner radius of a `top` / `bottom` sheet — rounded on
  /// the two corners that face into the viewport (resolver picks the
  /// side-specific corner pair). Stored as a uniform border radius; the
  /// resolver zeroes the edge-flush corners per `CoreDrawerSide`. A
  /// `left` / `right` panel uses [defaultSidePanelBorderRadius] instead.
  static const CoreBorderRadius defaultPanelBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius16,
  );

  /// Default panel corner radius of a `left` / `right` drawer — square, the
  /// panel is a column of the page rather than a floating card. Stands in
  /// for [defaultPanelBorderRadius] on those two sides when
  /// [panelBorderRadius] is unset.
  static const CoreBorderRadius defaultSidePanelBorderRadius =
      CoreBorderRadius.zero;

  /// Default panel border stroke width of a `left` / `right` drawer (1
  /// logical px) — drawn on the inner edge only, the one facing the page.
  static const double defaultPanelBorderWidth = CoreStrokeWidth.stroke1;

  /// Default panel border stroke width of a `top` / `bottom` sheet — none.
  /// Stands in for [defaultPanelBorderWidth] on those two sides when
  /// [panelBorderWidth] is unset.
  static const double defaultSheetPanelBorderWidth = CoreStrokeWidth.stroke0;

  /// Default panel width for `left` / `right` drawers (400 logical px).
  static const double defaultPanelWidth = CoreLayout.layout400;

  /// Default panel inner content padding — `space20` above and below,
  /// `space24` at the sides.
  static const CoreEdgeInsets defaultPanelPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space24,
    vertical: CoreSpace.space20,
  );

  /// Default panel header padding — `space24` above and at the sides,
  /// `space16` below.
  static const CoreEdgeInsets defaultHeaderPadding = CoreEdgeInsets.only(
    left: CoreSpace.space24,
    top: CoreSpace.space24,
    right: CoreSpace.space24,
    bottom: CoreSpace.space16,
  );

  /// Default space between the title block and the close button (16
  /// logical px).
  static const double defaultHeaderSpacing = CoreSpace.space16;

  /// Default padding of the footer row — `space16` above and below,
  /// `space24` at the sides.
  static const CoreEdgeInsets defaultFooterPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space24,
    vertical: CoreSpace.space16,
  );

  /// Default header close-button style — the single source for the
  /// close affordance's own chrome, raw-forwarded to
  /// `Button(variant: .plain, size: .sm, shape: .square, buttonStyle: …)`
  /// on both platforms. The `plain` variant owns the resting-opacity /
  /// hover-fade / foreground semantics; this slot sets the `sm` row's 32
  /// square with no padding (the square centres the glyph), the `radius8`
  /// corner, the 16 logical-px close glyph (`leadingIconStyle`), the 150 ms
  /// hover transition, and the focus-ring width
  /// (`focusOutlineStyle.borderWidth`).
  static const CoreButtonStyle defaultCloseButtonStyle = CoreButtonStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    height: CoreControlSize.heightSm,
    width: CoreControlSize.heightSm,
    padding: CoreEdgeInsets.zero,
    animationDuration: Duration(milliseconds: CoreDuration.fast),
    focusOutlineStyle: CoreFocusOutlineStyle(
      borderWidth: CoreFocusRing.ringWidth,
    ),
    leadingIconStyle: CoreIconStyle(size: CoreIconSize.size16),
  );

  /// Default header divider style — empty, so `Divider` applies its own
  /// shared default (`outlineVariant` → `outline` fallback) when the
  /// per-instance [dividerStyle] slot is unset (#4815 디자이너 결정 #1).
  static const CoreDividerStyle defaultDividerStyle = CoreDividerStyle();

  /// Default panel elevation shadow — none; the panel is told apart from
  /// the page by its fill and the inner-edge line.
  static const List<CoreShadowLayer> defaultPanelBoxShadow = CoreShadow.none;

  /// Default base colour the [panelBoxShadow] layers tint against — the
  /// `shadow` token (pure black in both light & dark) so the elevation
  /// shadow reads correctly on any surface. Both platforms resolve this
  /// single source: Flutter `scheme.resolve(...).toValue()`, Web
  /// `.toValue()` → `rgb(var(--coui-shadow))`.
  static const CoreColor defaultShadowBaseColor = CoreColor.token(
    CoreColors.shadow,
  );

  /// Default header title typography slot — `titleMedium` role bound to
  /// the `onSurface` foreground token. Both platforms resolve this single
  /// nested slot (the role carries the font size / weight / letter-spacing
  /// / line-height; the `color` carries the tone), then overlay the
  /// per-instance [titleStyle] slot on top (sb-text-style-repackage).
  static const CoreTextStyle defaultTitleStyle = CoreTextStyle.token(
    CoreTextStyles.titleMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default header description typography slot — `bodySmall` in
  /// `onSurfaceVariant`, the supporting-text tier the kit's other
  /// descriptions use (Alert, Banner, Checkbox, Stepper, Steps). The
  /// per-instance [descriptionStyle] slot overlays on top.
  static const CoreTextStyle defaultDescriptionStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default spacer between the title and the description — `space4`, the
  /// gap a bottom sheet with a description is drawn with. Drawn only when
  /// both are present.
  static const CoreGapStyle defaultTitleDescriptionGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
  );

  /// Default grab-handle pill colour — the surface-container step, a quiet
  /// mark on the panel fill.
  static const CoreColor defaultDragHandleColor = CoreColor.token(
    CoreColors.surfaceContainer,
  );

  /// Default grab-handle pill length along the edge it lies on (48 logical
  /// px).
  static const double defaultDragHandleWidth = CoreSize.size48;

  /// Default grab-handle pill thickness across that edge (6 logical px).
  static const double defaultDragHandleThickness = CoreSize.size6;

  /// Default space around the pill — between it and the panel edge, and
  /// between it and the header or content beside it (8 logical px).
  /// Spacing: a theme density moves it.
  static const double defaultDragHandleInset = CoreSpace.space8;

  /// Default grab-handle pill corner — a pill (`radius9999`).
  static const CoreBorderRadius defaultDragHandleBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius9999);

  /// Default barrier (scrim) overlay colour — the pure-black `scrim`
  /// token; the dim level comes from [defaultBarrierOpacity], folded in
  /// by both platform resolvers via `scaleAlpha`.
  static const CoreColor defaultBarrierColor = CoreColor.token(
    CoreColors.scrim,
  );

  /// Default barrier (scrim) opacity multiplier — the modal scrim
  /// strength (`CoreOpacity.scrim`, 30 %), the same dim the dialog
  /// backdrop lays over the page, so content stays visible behind every
  /// modal scrim.
  static const double defaultBarrierOpacity = CoreOpacity.scrim;

  /// Default backdrop scale-down factor — `1.0`: the app content behind
  /// the drawer keeps its size and only the scrim dims it. The zoom-out
  /// effect (shadcn's drawer) is opt-in: a style states
  /// [zoomBackdropScale], and the swiper's `drawer` variant does.
  static const double defaultBackdropScale = 1;

  /// Default corner radius the backdrop clips to when fully open — none:
  /// the page behind the drawer stays square. See
  /// [zoomBackdropCornerRadius] for the zoom-out effect's clip.
  static const CoreBorderRadius defaultBackdropCornerRadius =
      CoreBorderRadius.zero;

  /// Backdrop scale of the opt-in zoom-out effect (95 %) — the app content
  /// shrinks as the panel slides in. Not a default: a style that wants the
  /// effect states it (`CoreSwiperStyle.defaultsByVariant` does for the
  /// `drawer` variant).
  static const double zoomBackdropScale = 0.95;

  /// Corner radius the zoom-out effect's clipped backdrop animates to
  /// (pairs with [zoomBackdropScale]).
  static const CoreBorderRadius zoomBackdropCornerRadius = CoreBorderRadius.all(
    CoreRadius.radius24,
  );

  /// Default open-direction slide animation duration (350 ms).
  /// Backs the [openAnimationDuration] override (1:1:1:1 chaining).
  static const Duration defaultOpenAnimationDuration = Duration(
    milliseconds: CoreDuration.ms350,
  );

  /// Default close-direction slide animation duration (350 ms).
  /// Backs the [closeAnimationDuration] override (1:1:1:1 chaining).
  static const Duration defaultCloseAnimationDuration = Duration(
    milliseconds: CoreDuration.ms350,
  );

  // ── Panel chrome (flat) ──────────────────────

  /// Panel background fill colour override.
  final CoreColor? panelBackgroundColor;

  /// Panel border stroke colour override.
  final CoreColor? panelBorderColor;

  /// Panel border radius override. When null, a `left` / `right` drawer
  /// defers to [defaultSidePanelBorderRadius] and a `top` / `bottom` sheet
  /// to [defaultPanelBorderRadius].
  final CoreBorderRadius? panelBorderRadius;

  /// Panel border stroke width override (logical px). When null, a
  /// `left` / `right` drawer defers to [defaultPanelBorderWidth] (1) and a
  /// `top` / `bottom` sheet to [defaultSheetPanelBorderWidth] (none). The
  /// line is drawn on the panel's inner edge only.
  final double? panelBorderWidth;

  /// Panel width override for `left` / `right` drawers (logical px).
  final double? panelWidth;

  /// Panel height override for `top` / `bottom` drawers (logical px).
  /// `null` (the default) sizes the panel to its content, up to the
  /// viewport.
  ///
  /// When null (the default) the panel is **content-sized** — it wraps
  /// its content on the slide axis, capped at the viewport extent
  /// (greedy children such as `ListView` fill up to that cap). An
  /// explicit value fixes the extent instead. The null-means-content
  /// semantic is why this field carries no `defaultPanelHeight` — on both
  /// platforms absence is the *absence of a constraint*, not a value.
  /// Flutter hands it to `SizedBox.height`, where null adds no height
  /// constraint and the route's loose, screen-bounded constraints let the
  /// panel wrap; Web omits the `height` declaration altogether
  /// (`if (panelHeight != null)`) so the panel stays `height: auto` under
  /// its `max-height: 100%` cap. Any constant would pin every top /
  /// bottom drawer to one extent and take content-sizing off the table.
  final double? panelHeight;

  /// Panel inner content padding override. When null, defers to
  /// [defaultPanelPadding] (24 on all sides). Pass
  /// `CoreEdgeInsets.zero` to suppress the default content padding
  /// when the panel's `content` supplies its own.
  final CoreEdgeInsets? panelPadding;

  /// Header padding override. When null, defers to
  /// [defaultHeaderPadding] (24 above and at the sides, 16 below).
  final CoreEdgeInsets? headerPadding;

  /// Space between the title block and the close button (logical px,
  /// pre-scaling). `null` → [defaultHeaderSpacing].
  final double? headerSpacing;

  /// Padding of the footer row (the `footer` slot), below its divider.
  /// `null` → [defaultFooterPadding].
  final CoreEdgeInsets? footerPadding;

  /// Panel elevation shadow override. When null, no shadow
  /// ([defaultPanelBoxShadow]).
  final List<CoreShadowLayer>? panelBoxShadow;

  /// Base colour the [panelBoxShadow] layers tint against. When null,
  /// defers to [defaultShadowBaseColor] (the `shadow` token).
  final CoreColor? shadowBaseColor;

  // ── Barrier / Animation ──────────────────────

  /// Barrier (scrim) overlay colour override.
  final CoreColor? barrierColor;

  /// Barrier (scrim) opacity multiplier override (0.0 – 1.0). When
  /// null, defers to [defaultBarrierOpacity] (0.3).
  final double? barrierOpacity;

  /// Backdrop scale-down factor override (0.0 – 1.0). When null, defers to
  /// [defaultBackdropScale] (1.0 — no zoom-out). Only takes effect when the
  /// widget's `transformBackdrop` behaviour flag is on.
  final double? backdropScale;

  /// Corner radius override for the scaled backdrop clip. When null,
  /// defers to [defaultBackdropCornerRadius]. A different radius per
  /// corner works on both platforms.
  ///
  /// Flutter lerps the full `BorderRadius` per corner with the open
  /// progress; Web writes the full CSS `border-radius` shorthand.
  final CoreBorderRadius? backdropCornerRadius;

  /// Open animation duration override.
  final Duration? openAnimationDuration;

  /// Close animation duration override.
  final Duration? closeAnimationDuration;

  // ── Slot Styles (nested) ─────────────────────

  /// Header title text style override, laid over [defaultTitleStyle]
  /// (`titleMedium` role + `onSurface` tone).
  ///
  /// The resolver composes one paint-ready title `TextStyle`
  /// (sb-text-style-repackage).
  final CoreTextStyle? titleStyle;

  /// Header close (dismiss) button style override.
  ///
  /// The single entry point for the close-button chrome — padding /
  /// hit-area radius (`borderRadius`) / close glyph
  /// (`leadingIconStyle`) / hover transition (`animationDuration`) /
  /// focus-ring width (`focusOutlineStyle.borderWidth`). Merged onto
  /// [defaultCloseButtonStyle] and raw-forwarded to
  /// `Button(variant: .plain, buttonStyle: …)` (the `plain` variant
  /// owns the resting-opacity / hover-fade / foreground semantics).
  final CoreButtonStyle? closeButtonStyle;

  /// Style of the header divider (the line under the title row). Merged
  /// onto [defaultDividerStyle], which is empty, so `Divider`'s own default
  /// applies; then passed to `Divider(dividerStyle: …)` as is.
  ///
  /// The header separator is `Divider`'s shared surface, not the panel's
  /// own edge — #4815 디자이너 결정 #1.
  ///
  /// A header with no rule under it — a bottom sheet's — states
  /// `CoreDividerStyle(thickness: 0)`: the rule then takes no space on
  /// either platform.
  final CoreDividerStyle? dividerStyle;

  /// Header description text style override — overlaid on
  /// [defaultDescriptionStyle] (`bodySmall` + `onSurfaceVariant`).
  final CoreTextStyle? descriptionStyle;

  /// Spacer between the title and the description — drawn only when the
  /// drawer has both. Merged onto [defaultTitleDescriptionGapStyle].
  final CoreGapStyle? titleDescriptionGapStyle;

  // ── Grab handle (drawn when the widget's `showDragHandle` is on) ──

  /// Grab-handle pill colour override.
  final CoreColor? dragHandleColor;

  /// Grab-handle pill length along the edge it lies on (logical px) — a
  /// horizontal pill on a top / bottom panel, a vertical one on a side
  /// drawer.
  final double? dragHandleWidth;

  /// Grab-handle pill thickness across that edge (logical px).
  final double? dragHandleThickness;

  /// Space around the pill — between it and the panel edge, and between it
  /// and what sits beside it (logical px).
  final double? dragHandleInset;

  /// Grab-handle pill corner radius override.
  final CoreBorderRadius? dragHandleBorderRadius;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested titleStyle /
  /// closeButtonStyle / dividerStyle slots are merged recursively.
  @override
  CoreDrawerStyle merge(CoreDrawerStyle? other) {
    if (other == null) return this;
    return CoreDrawerStyle(
      panelBackgroundColor: other.panelBackgroundColor ?? panelBackgroundColor,
      panelBorderColor: other.panelBorderColor ?? panelBorderColor,
      panelBorderRadius: other.panelBorderRadius ?? panelBorderRadius,
      panelBorderWidth: other.panelBorderWidth ?? panelBorderWidth,
      panelWidth: other.panelWidth ?? panelWidth,
      panelHeight: other.panelHeight ?? panelHeight,
      panelPadding: other.panelPadding ?? panelPadding,
      headerPadding: other.headerPadding ?? headerPadding,
      headerSpacing: other.headerSpacing ?? headerSpacing,
      footerPadding: other.footerPadding ?? footerPadding,
      panelBoxShadow: other.panelBoxShadow ?? panelBoxShadow,
      shadowBaseColor: other.shadowBaseColor ?? shadowBaseColor,
      barrierColor: other.barrierColor ?? barrierColor,
      barrierOpacity: other.barrierOpacity ?? barrierOpacity,
      backdropScale: other.backdropScale ?? backdropScale,
      backdropCornerRadius: other.backdropCornerRadius ?? backdropCornerRadius,
      openAnimationDuration:
          other.openAnimationDuration ?? openAnimationDuration,
      closeAnimationDuration:
          other.closeAnimationDuration ?? closeAnimationDuration,
      titleStyle: _mergeText(titleStyle, other.titleStyle),
      closeButtonStyle: _mergeButton(closeButtonStyle, other.closeButtonStyle),
      dividerStyle: _mergeDivider(dividerStyle, other.dividerStyle),
      descriptionStyle: _mergeText(descriptionStyle, other.descriptionStyle),
      titleDescriptionGapStyle:
          titleDescriptionGapStyle?.merge(other.titleDescriptionGapStyle) ??
          other.titleDescriptionGapStyle,
      dragHandleColor: other.dragHandleColor ?? dragHandleColor,
      dragHandleWidth: other.dragHandleWidth ?? dragHandleWidth,
      dragHandleThickness: other.dragHandleThickness ?? dragHandleThickness,
      dragHandleInset: other.dragHandleInset ?? dragHandleInset,
      dragHandleBorderRadius:
          other.dragHandleBorderRadius ?? dragHandleBorderRadius,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreDrawerStyle copyWith({
    CoreColor? panelBackgroundColor,
    CoreColor? panelBorderColor,
    CoreBorderRadius? panelBorderRadius,
    double? panelBorderWidth,
    double? panelWidth,
    double? panelHeight,
    CoreEdgeInsets? panelPadding,
    CoreEdgeInsets? headerPadding,
    double? headerSpacing,
    CoreEdgeInsets? footerPadding,
    List<CoreShadowLayer>? panelBoxShadow,
    CoreColor? shadowBaseColor,
    CoreColor? barrierColor,
    double? barrierOpacity,
    double? backdropScale,
    CoreBorderRadius? backdropCornerRadius,
    Duration? openAnimationDuration,
    Duration? closeAnimationDuration,
    CoreTextStyle? titleStyle,
    CoreButtonStyle? closeButtonStyle,
    CoreDividerStyle? dividerStyle,
    CoreTextStyle? descriptionStyle,
    CoreGapStyle? titleDescriptionGapStyle,
    CoreColor? dragHandleColor,
    double? dragHandleWidth,
    double? dragHandleThickness,
    double? dragHandleInset,
    CoreBorderRadius? dragHandleBorderRadius,
  }) {
    return CoreDrawerStyle(
      panelBackgroundColor: panelBackgroundColor ?? this.panelBackgroundColor,
      panelBorderColor: panelBorderColor ?? this.panelBorderColor,
      panelBorderRadius: panelBorderRadius ?? this.panelBorderRadius,
      panelBorderWidth: panelBorderWidth ?? this.panelBorderWidth,
      panelWidth: panelWidth ?? this.panelWidth,
      panelHeight: panelHeight ?? this.panelHeight,
      panelPadding: panelPadding ?? this.panelPadding,
      headerPadding: headerPadding ?? this.headerPadding,
      headerSpacing: headerSpacing ?? this.headerSpacing,
      footerPadding: footerPadding ?? this.footerPadding,
      panelBoxShadow: panelBoxShadow ?? this.panelBoxShadow,
      shadowBaseColor: shadowBaseColor ?? this.shadowBaseColor,
      barrierColor: barrierColor ?? this.barrierColor,
      barrierOpacity: barrierOpacity ?? this.barrierOpacity,
      backdropScale: backdropScale ?? this.backdropScale,
      backdropCornerRadius: backdropCornerRadius ?? this.backdropCornerRadius,
      openAnimationDuration:
          openAnimationDuration ?? this.openAnimationDuration,
      closeAnimationDuration:
          closeAnimationDuration ?? this.closeAnimationDuration,
      titleStyle: titleStyle ?? this.titleStyle,
      closeButtonStyle: closeButtonStyle ?? this.closeButtonStyle,
      dividerStyle: dividerStyle ?? this.dividerStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      titleDescriptionGapStyle:
          titleDescriptionGapStyle ?? this.titleDescriptionGapStyle,
      dragHandleColor: dragHandleColor ?? this.dragHandleColor,
      dragHandleWidth: dragHandleWidth ?? this.dragHandleWidth,
      dragHandleThickness: dragHandleThickness ?? this.dragHandleThickness,
      dragHandleInset: dragHandleInset ?? this.dragHandleInset,
      dragHandleBorderRadius:
          dragHandleBorderRadius ?? this.dragHandleBorderRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDrawerStyle &&
          runtimeType == other.runtimeType &&
          panelBackgroundColor == other.panelBackgroundColor &&
          panelBorderColor == other.panelBorderColor &&
          panelBorderRadius == other.panelBorderRadius &&
          panelBorderWidth == other.panelBorderWidth &&
          panelWidth == other.panelWidth &&
          panelHeight == other.panelHeight &&
          panelPadding == other.panelPadding &&
          headerPadding == other.headerPadding &&
          headerSpacing == other.headerSpacing &&
          footerPadding == other.footerPadding &&
          _shadowEq(panelBoxShadow, other.panelBoxShadow) &&
          shadowBaseColor == other.shadowBaseColor &&
          barrierColor == other.barrierColor &&
          barrierOpacity == other.barrierOpacity &&
          backdropScale == other.backdropScale &&
          backdropCornerRadius == other.backdropCornerRadius &&
          openAnimationDuration == other.openAnimationDuration &&
          closeAnimationDuration == other.closeAnimationDuration &&
          titleStyle == other.titleStyle &&
          closeButtonStyle == other.closeButtonStyle &&
          dividerStyle == other.dividerStyle &&
          descriptionStyle == other.descriptionStyle &&
          titleDescriptionGapStyle == other.titleDescriptionGapStyle &&
          dragHandleColor == other.dragHandleColor &&
          dragHandleWidth == other.dragHandleWidth &&
          dragHandleThickness == other.dragHandleThickness &&
          dragHandleInset == other.dragHandleInset &&
          dragHandleBorderRadius == other.dragHandleBorderRadius;

  @override
  int get hashCode {
    final shadowHash = panelBoxShadow == null
        ? null
        : Object.hashAll(panelBoxShadow!);
    return Object.hashAll([
      panelBackgroundColor,
      panelBorderColor,
      panelBorderRadius,
      panelBorderWidth,
      panelWidth,
      panelHeight,
      panelPadding,
      headerPadding,
      headerSpacing,
      footerPadding,
      shadowHash,
      shadowBaseColor,
      barrierColor,
      barrierOpacity,
      backdropScale,
      backdropCornerRadius,
      openAnimationDuration,
      closeAnimationDuration,
      titleStyle,
      closeButtonStyle,
      dividerStyle,
      descriptionStyle,
      titleDescriptionGapStyle,
      dragHandleColor,
      dragHandleWidth,
      dragHandleThickness,
      dragHandleInset,
      dragHandleBorderRadius,
    ]);
  }

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreButtonStyle? _mergeButton(
    CoreButtonStyle? base,
    CoreButtonStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreDividerStyle? _mergeDivider(
    CoreDividerStyle? base,
    CoreDividerStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static bool _shadowEq(
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
