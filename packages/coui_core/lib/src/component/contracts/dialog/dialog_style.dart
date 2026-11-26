/// Per-instance style for `Dialog`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/dialog/dialog_actions_layout.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/layout.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Dialog` should render.
///
/// `CoreDialogStyle` carries panel chrome / dimensional
/// overrides as flat fields (panel is part of the dialog, not a
/// separate component), plus nested `CoreTextStyle` /
/// `CoreButtonStyle` references for the title / content / action
/// button slots — Epic #1302's "atomic-style nesting" rule.
///
/// **Semantic enums live on the widget, not on this style** (Epic
/// #1302 원칙 6/7). [actionsLayout] is not one: it states how the actions
/// row spreads its actions — the row's distribution, like [actionSpacing] —
/// so a project can state it once in `CoreDialogTheme.style`.
///
/// ```text
/// design system default
///   → CoreDialogTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.dialogStyle                          // 인스턴스별
/// ```
@immutable
class CoreDialogStyle implements CoreStyle<CoreDialogStyle> {
  /// Creates a [CoreDialogStyle].
  const CoreDialogStyle({
    this.panelBackgroundColor,
    this.panelBorderColor,
    this.panelBorderWidth,
    this.panelBorderRadius,
    this.panelPadding,
    this.panelMinWidth,
    this.panelMaxWidth,
    this.surfaceBlur,
    this.surfaceOpacity,
    this.panelBoxShadow,
    this.shadowBaseColor,
    this.barrierColor,
    this.barrierOpacity,
    this.sectionGapStyle,
    this.actionsGapStyle,
    this.actionSpacing,
    this.actionRunSpacing,
    this.actionsLayout,
    this.contentClipMargin,
    this.routePadding,
    this.transitionDuration,
    this.scaleAnimationStart,
    this.scaleAnimationEnd,
    this.titleStyle,
    this.contentStyle,
    this.actionButtonStyle,
  });

  /// Default visual colour table (background / foreground / border /
  /// backdrop). Single source of truth shared by Flutter and Web — each
  /// platform resolves the [CoreColor] via its own extension
  /// (`.toValue()` / `scheme.resolve(...)`). Dialog has no variant enum
  /// so this is the single design-system default, keyed by nothing.
  ///
  /// Named `defaultsByVariant` (the shared 7-name dispatch-registry
  /// convention `core/design-tokens.md` reader census expects, even for
  /// a component with a single design-system default) rather than
  /// `defaults` — a bare `defaults` name is invisible to `defaultsBy*`
  /// prefix-matching coverage tooling (see `core/style-contract.md`
  /// "off-convention static names"). This also keeps the identifier
  /// matching `\.defaults[A-Z]`, which
  /// `scripts/guards/resolver/check_{flutter,web}_resolver.sh` RULE D
  /// already excludes from its per-field `default<Field>` chaining
  /// check — the resolver reads `variantStyle.X` from this table, not a
  /// per-field `merged.x ?? CoreDialogStyle.defaultX` chain.
  static const CoreDialogVariantStyle defaultsByVariant =
      CoreDialogVariantStyle(
        backgroundColor: defaultPanelBackgroundColor,
        foregroundColor: CoreColor.token(CoreColors.onSurface),
        borderColor: defaultPanelBorderColor,
        overlayColor: defaultBarrierColor,
      );

  /// Default panel fill — the `surfaceBright` token (the raised floating
  /// face). Named here (rather than
  /// only inside [defaultsByVariant]) so the [panelBackgroundColor] slot
  /// has the matching `default<Field>` its own doc promises; the table
  /// above references this const so the two can never drift.
  static const CoreColor defaultPanelBackgroundColor = CoreColor.token(
    CoreColors.surfaceBright,
  );

  /// Default panel border stroke colour — the `outlineSubtle` token, matching
  /// `CoreDrawerStyle.defaultPanelBorderColor` (the other panel-plus-
  /// backdrop overlay). Painted by
  /// `coui_flutter/lib/src/components/overlay/dialog/dialog.dart:686`
  /// (`Border.all(color: resolved.panelBorderColor)`).
  ///
  /// Named here (rather than only inside [defaultsByVariant]) for the same
  /// reason as [defaultPanelBackgroundColor]: the flat [panelBorderColor]
  /// slot needs the matching `default<Field>` its own doc promises, and it
  /// is what makes the value reachable outside Dart at all — the Figma
  /// exporter routes a static default through its instance field, and
  /// [defaultsByVariant] is a single [CoreDialogVariantStyle] rather than
  /// a `Map`, so nothing inside it is exportable. Before this const the
  /// border colour was Core-owned and read by both resolvers yet invisible
  /// to the exporter, and the plugin builder wrote the token name
  /// as a literal. The table above references this const so the two can
  /// never drift.
  static const CoreColor defaultPanelBorderColor = CoreColor.token(
    CoreColors.outlineSubtle,
  );

  /// Default backdrop barrier tint before [defaultBarrierOpacity] is
  /// applied — the pure-black `scrim` token (the same scrim a drawer
  /// lays). Referenced by [defaultsByVariant]'s `overlayColor` so there is
  /// one source.
  static const CoreColor defaultBarrierColor = CoreColor.token(
    CoreColors.scrim,
  );

  // ── Design-system defaults ────────────────────
  //
  // Variant-independent defaults — single source of truth shared by
  // the Flutter and Web resolvers. The dialog has no visual variant, so
  // `defaultsByVariant` above is a single instance rather than a Map.

  /// Default panel border width (1 logical px — thin stroke).
  static const double defaultPanelBorderWidth = CoreStrokeWidth.stroke1;

  /// Default panel inner content padding — 24 logical px above and on
  /// both sides, 20 below (the actions row sits closer to the bottom
  /// edge than the header does to the top).
  static const CoreEdgeInsets defaultPanelPadding = CoreEdgeInsets.only(
    top: CoreSpace.space24,
    left: CoreSpace.space24,
    right: CoreSpace.space24,
    bottom: CoreSpace.space20,
  );

  /// Default panel corner radius — the modal role (20 logical px on all
  /// four corners), one step rounder than the cards a dialog opens over.
  static const CoreBorderRadius defaultPanelBorderRadius = CoreBorderRadius.all(
    CoreRadiusRole.modal,
  );

  /// Default minimum width of the dialog panel (`CoreLayout.layout280`,
  /// 280 logical px) — a narrow viewport does not squeeze the panel below
  /// it. A viewport narrower than this plus the route's inset still wins:
  /// the panel takes the room the route leaves it.
  static const double defaultPanelMinWidth = CoreLayout.layout280;

  /// Default maximum width of the dialog panel — the layout token for a
  /// dialog panel (`CoreLayout.layout560`, 560 logical px).
  static const double defaultPanelMaxWidth = CoreLayout.layout560;

  /// Default elevation shadow of the dialog panel — the canonical
  /// Shadow Token Specification's Modal/Dialog mapping (`shadow-xl`,
  /// `CoreShadow.xl`). Field name (`panelBoxShadow`, not bare
  /// `boxShadow`) matches `CoreDrawerStyle`'s convention — both style
  /// classes carry a backdrop *and* a panel, so the prefix says which
  /// element the shadow belongs to (`CorePopupStyle`, which has no
  /// separate backdrop, keeps the bare name). #3777: this was declared
  /// nowhere (Core 0 / Flutter 0) before Web's own hardcoded
  /// `var(--shadow-lg)` — the popover/tooltip tier, not the modal tier —
  /// was the only place a dialog shadow existed at all.
  static const List<CoreShadowLayer> defaultPanelBoxShadow = CoreShadow.xl;

  /// Default base colour the [panelBoxShadow] layers tint against — the
  /// palette's `shadow` token, same rationale as `CorePopupStyle`'s
  /// `defaultShadowBaseColor`: a component can't know whether the page
  /// it lands on is light or dark, and the theme's brightness sets how
  /// strongly the palette's colour is drawn, so the shadow reads in
  /// either.
  static const CoreColor defaultShadowBaseColor = CoreColor.token(
    CoreColors.shadow,
  );

  /// Default gap slot between the dialog's head and body sections —
  /// header row / content, and inside the header row between leading /
  /// title / trailing (14 logical px). Carries the design-system gap
  /// size; the per-instance [sectionGapStyle] merges on top so the
  /// resolved gap rides a single [CoreGapStyle] (nested-slot pattern).
  /// Shared by Flutter and Web resolvers.
  static const CoreGapStyle defaultSectionGapStyle = CoreGapStyle(
    size: CoreSpace.space14,
  );

  /// Default gap slot between the dialog's body and its actions row
  /// (20 logical px). When the dialog has no content, the header row sits
  /// this far from the actions too. The per-instance [actionsGapStyle]
  /// merges on top. Shared by Flutter and Web resolvers.
  static const CoreGapStyle defaultActionsGapStyle = CoreGapStyle(
    size: CoreSpace.space20,
  );

  /// Default gap between adjacent action buttons (8 logical px). The
  /// per-instance [actionSpacing] (raw double) overrides this. Shared
  /// by Flutter and Web resolvers — the Flutter resolver applies
  /// scaling, the Web resolver emits an inline `gap` rem value.
  static const double defaultActionSpacing = CoreSpace.space8;

  /// Default gap between the rows actions wrap onto when they no longer
  /// fit on one line (8 logical px) — the same length as
  /// [defaultActionSpacing], so a wrapped action sits as far below the row
  /// above it as two actions sit apart. The per-instance
  /// [actionRunSpacing] overrides it. Spacing: both resolvers move it with
  /// the theme density, as they move [actionSpacing].
  static const double defaultActionRunSpacing = defaultActionSpacing;

  /// Default spread of the actions row — [CoreDialogActionsLayout.end]: at
  /// the panel's end, each action its own width, wrapping onto further rows
  /// at the end when one line cannot hold them. The per-instance
  /// [actionsLayout] overrides it. Shared by Flutter and Web resolvers.
  static const CoreDialogActionsLayout defaultActionsLayout =
      CoreDialogActionsLayout.end;

  /// Default reach of the body past its own box before the dialog clips
  /// what the body paints (4 logical px) — the focus outline's outer edge
  /// ([CoreFocusOutlineStyle.defaultAlign]).
  ///
  /// The body becomes a scroll region so a body taller than the room the
  /// route leaves scrolls while the title and actions stay put, and a
  /// scroll region clips. Clipped flush with the body, a field that spans
  /// the body would lose the outer edge of its focus ring — the ring sits
  /// 2px outside the field and is 2px wide. Reaching exactly as far as the
  /// ring keeps the whole ring, and the hard cast a boxed surface style
  /// adds under a control (4px across and down) with it. It stays inside
  /// the default gaps above and below the body (14 / 20) and the panel
  /// padding beside it (24), so nothing the body paints within that reach
  /// reaches the title or the actions either.
  static const double defaultContentClipMargin =
      CoreFocusOutlineStyle.defaultAlign;

  /// Default route inset padding around the dialog panel (16 logical
  /// px) — the [routePadding] fallback.
  ///
  /// Spacing: a theme density moves it on both platforms (12 / 16 / 20) —
  /// Flutter through the theme geometry where the route pads, Web through
  /// the spacing variable the panel's width cap reads.
  static const double defaultRoutePadding = CoreSpace.space16;

  /// Default open/close transition duration (200 ms) as a [Duration] —
  /// powers the backdrop opacity fade and the panel scale-and-fade-in,
  /// for the flat [transitionDuration] override slot.
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Default backdrop (scrim) opacity multiplier — the modal scrim
  /// strength (`CoreOpacity.scrim`, 30 %), the same dim every modal lays
  /// over the page.
  static const double defaultBarrierOpacity = CoreOpacity.scrim;

  /// Default scale at the start of the panel open animation.
  static const double defaultScaleAnimationStart = 0.9;

  /// Default scale at the end of the panel open animation (no
  /// scaling).
  static const double defaultScaleAnimationEnd = 1;

  /// Default title typography role — `titleLarge` (20 / 600 / 1.4, semibold
  /// via the role) coloured with the `onSurface` token. Both platforms
  /// merge the per-instance [titleStyle] on top of this single source and
  /// paint its colour: the Web resolver emits the role + colour through
  /// `emitTypography`, and the Flutter resolver materialises it via
  /// `.toValue(theme:)`. The title's colour is this default's own; it is
  /// not read from the panel foreground ([defaultsByVariant]
  /// `foregroundColor`), which colours only what the panel holds that
  /// states no colour.
  static const CoreTextStyle defaultTitleStyle = CoreTextStyle.token(
    CoreTextStyles.titleLarge,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default content (body) typography role — `bodyMedium` (14 / 400 /
  /// 1.5, a 21px line) coloured with the secondary `onSurfaceVariant`
  /// token (dialog description text).
  /// Both platforms merge the per-instance [contentStyle] on top of this
  /// single source and paint its colour: the Web resolver emits the role +
  /// colour through `emitTypography`, and the Flutter resolver materialises
  /// it via `.toValue(theme:)`. Like the title, the body's colour is its
  /// default's own, not the panel foreground.
  static const CoreTextStyle defaultContentStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  // ── Panel chrome (flat) ──────────────────────

  /// Panel background fill colour override. When null, defers to
  /// [defaultsByVariant] `background` (`surfaceBright` token).
  final CoreColor? panelBackgroundColor;

  /// Panel border stroke colour override. When null, defers to
  /// [defaultPanelBorderColor] (`outlineSubtle` token).
  final CoreColor? panelBorderColor;

  /// Panel border width override (logical pixels). When null, defers to
  /// [defaultPanelBorderWidth] (1 logical px).
  final double? panelBorderWidth;

  /// Panel border radius override. When null, defers to
  /// [defaultPanelBorderRadius] (20 logical px uniform).
  final CoreBorderRadius? panelBorderRadius;

  /// Panel content padding override. When null, defers to
  /// [defaultPanelPadding] (24 above and on both sides, 20 below).
  final CoreEdgeInsets? panelPadding;

  /// Panel minimum width override (logical pixels). When null, defers
  /// to [defaultPanelMinWidth] (`CoreLayout.layout280`, 280). A viewport
  /// that leaves less room than this narrows the panel to that room.
  final double? panelMinWidth;

  /// Panel maximum width override (logical pixels). When null, defers
  /// to [defaultPanelMaxWidth] (`CoreLayout.layout560`, 560).
  final double? panelMaxWidth;

  /// Backdrop blur sigma applied behind the panel.
  final double? surfaceBlur;

  /// Panel surface opacity multiplier (0.0 – 1.0).
  final double? surfaceOpacity;

  /// Elevation shadow of the dialog panel. When null, defers to
  /// [defaultPanelBoxShadow] (`CoreShadow.xl`, the Modal/Dialog rung).
  final List<CoreShadowLayer>? panelBoxShadow;

  /// Base colour the [panelBoxShadow] layers tint against. When null,
  /// defers to [defaultShadowBaseColor] (`shadow` token).
  final CoreColor? shadowBaseColor;

  /// Backdrop barrier overlay colour override. When null, defers to
  /// [defaultsByVariant] `overlayColor` (`scrim` token).
  final CoreColor? barrierColor;

  /// Backdrop (scrim) opacity multiplier override (0.0 – 1.0). When
  /// null, defers to [defaultBarrierOpacity] (0.3).
  final double? barrierOpacity;

  /// Gap slot between the dialog's head and body — header row / content —
  /// and inside the header row between leading / title / trailing.
  /// Forwarded straight to `Gap(gapStyle: …)` (Flutter) and to the
  /// inter-slot inline `gap` CSS (Web). `null` defers to
  /// [defaultSectionGapStyle] (14 logical px).
  final CoreGapStyle? sectionGapStyle;

  /// Gap slot between the dialog's body and its actions row. Forwarded
  /// straight to `Gap(gapStyle: …)` (Flutter) and to the inline `gap` CSS
  /// above the footer (Web). `null` defers to [defaultActionsGapStyle]
  /// (20 logical px).
  final CoreGapStyle? actionsGapStyle;

  /// Gap between adjacent action buttons inside the actions row
  /// (logical pixels), in either [actionsLayout]. Rendered as the spacing of
  /// the actions row (Flutter — the `Wrap` at the end, the stretched row when
  /// stretched) / inline `column-gap` CSS on the footer row (Web, where the
  /// stretched share subtracts it too). `null` defers to
  /// [defaultActionSpacing] (8 logical px).
  final double? actionSpacing;

  /// Gap between the rows the actions wrap onto once they no longer fit on
  /// one line (logical pixels), in either [actionsLayout] — the run spacing
  /// of the actions row (Flutter) / inline `row-gap` CSS on the wrapping
  /// footer (Web); two stretched actions that stack sit this far apart. One
  /// line of actions never reads it. `null` defers to
  /// [defaultActionRunSpacing] (8 logical px).
  final double? actionRunSpacing;

  /// How the actions row spreads its actions. [CoreDialogActionsLayout.end]
  /// keeps each action its own width at the panel's end;
  /// [CoreDialogActionsLayout.stretch] starts every action at the same share
  /// of the row so together they fill it — one action the whole row, two half
  /// each, and, when either does not fit its half, both stacked at the full
  /// width with [actionRunSpacing] between them (three or more: see
  /// [CoreDialogActionsLayout.stretch]). The order is always the order the
  /// actions were handed in. `null` defers to [defaultActionsLayout]
  /// ([CoreDialogActionsLayout.end]).
  ///
  /// A Flutter action list that asks for flex distribution itself (a
  /// `Flexible` / `Spacer` action) keeps the single `Row` it asked for in
  /// either layout.
  final CoreDialogActionsLayout? actionsLayout;

  /// How far past its own box the body keeps painting before the dialog
  /// clips it (logical pixels), on every side. `null` defers to
  /// [defaultContentClipMargin] (4 logical px, the focus outline's reach).
  ///
  /// The body scrolls when it is taller than the room the route leaves, so
  /// it is a clipping region; this is how much of what the body paints
  /// outside its box — a focus ring, a cast — survives the clip. Both
  /// platforms clip at the same place whether or not the body scrolls. A
  /// value larger than the gaps around the body lets scrolled text show
  /// over the title or the actions.
  final double? contentClipMargin;

  /// The room the dialog route leaves between the panel and the edges of
  /// the screen, in logical pixels — one length on every side. `null`
  /// defers to [defaultRoutePadding] (16 logical px).
  ///
  /// Each platform puts it where its panel can meet an edge: Flutter pads
  /// the route by it (inside the safe area, on all four sides — nothing in
  /// the route is laid out past it), Web caps the centred panel's width at
  /// the viewport less it on both sides. Spacing either way — a theme
  /// density moves a stated value too, the way it moves every padding.
  /// A full-screen dialog has no room around it, and ignores this.
  final double? routePadding;

  /// Open/close transition duration override. When null, defers to
  /// [defaultTransitionDuration] (200 ms).
  final Duration? transitionDuration;

  /// Panel open-animation start scale override. When null, defers to
  /// [defaultScaleAnimationStart] (0.9).
  final double? scaleAnimationStart;

  /// Panel open-animation end scale override. When null, defers to
  /// [defaultScaleAnimationEnd] (1.0).
  final double? scaleAnimationEnd;

  // ── Slot Styles (nested) ─────────────────────

  /// Title text style override.
  final CoreTextStyle? titleStyle;

  /// Content (body) text style override.
  final CoreTextStyle? contentStyle;

  /// Action button style override.
  ///
  /// To change an action button's **variant**, inject the button
  /// widget directly via `Dialog(actions: [Button(...)])` rather
  /// than packing variant into this style — Epic #1302 원칙 8
  /// (asChild pattern).
  ///
  /// **No default, and must not have one.** Null means the actions the
  /// caller handed in are rendered as they were handed in: Web branches
  /// on `when resolved.actionButtonStyle != null` and otherwise emits
  /// `action` untouched, taking no copy. A constant would rebuild every
  /// action `Button` in every dialog with dialog-level chrome merged
  /// underneath its own.
  ///
  /// And the value it would have to carry does not exist as a constant.
  /// A `Button`'s baseline chrome is per-variant
  /// (`CoreButtonStyle.defaultsByVariant`), and anything named here
  /// outranks that table inside `Button`'s resolver — so one constant
  /// would repaint a `.ghost` Cancel and a filled Save the same, which
  /// is the exact opposite of what the two buttons are for.
  final CoreButtonStyle? actionButtonStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreDialogStyle merge(CoreDialogStyle? other) {
    if (other == null) return this;
    return CoreDialogStyle(
      panelBackgroundColor: other.panelBackgroundColor ?? panelBackgroundColor,
      panelBorderColor: other.panelBorderColor ?? panelBorderColor,
      panelBorderWidth: other.panelBorderWidth ?? panelBorderWidth,
      panelBorderRadius: other.panelBorderRadius ?? panelBorderRadius,
      panelPadding: other.panelPadding ?? panelPadding,
      panelMinWidth: other.panelMinWidth ?? panelMinWidth,
      panelMaxWidth: other.panelMaxWidth ?? panelMaxWidth,
      surfaceBlur: other.surfaceBlur ?? surfaceBlur,
      surfaceOpacity: other.surfaceOpacity ?? surfaceOpacity,
      panelBoxShadow: other.panelBoxShadow ?? panelBoxShadow,
      shadowBaseColor: other.shadowBaseColor ?? shadowBaseColor,
      barrierColor: other.barrierColor ?? barrierColor,
      barrierOpacity: other.barrierOpacity ?? barrierOpacity,
      sectionGapStyle: _mergeGap(sectionGapStyle, other.sectionGapStyle),
      actionsGapStyle: _mergeGap(actionsGapStyle, other.actionsGapStyle),
      actionSpacing: other.actionSpacing ?? actionSpacing,
      actionRunSpacing: other.actionRunSpacing ?? actionRunSpacing,
      actionsLayout: other.actionsLayout ?? actionsLayout,
      contentClipMargin: other.contentClipMargin ?? contentClipMargin,
      routePadding: other.routePadding ?? routePadding,
      transitionDuration: other.transitionDuration ?? transitionDuration,
      scaleAnimationStart: other.scaleAnimationStart ?? scaleAnimationStart,
      scaleAnimationEnd: other.scaleAnimationEnd ?? scaleAnimationEnd,
      titleStyle: _mergeText(titleStyle, other.titleStyle),
      contentStyle: _mergeText(contentStyle, other.contentStyle),
      actionButtonStyle: _mergeButton(
        actionButtonStyle,
        other.actionButtonStyle,
      ),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreDialogStyle copyWith({
    CoreColor? panelBackgroundColor,
    CoreColor? panelBorderColor,
    double? panelBorderWidth,
    CoreBorderRadius? panelBorderRadius,
    CoreEdgeInsets? panelPadding,
    double? panelMinWidth,
    double? panelMaxWidth,
    double? surfaceBlur,
    double? surfaceOpacity,
    List<CoreShadowLayer>? panelBoxShadow,
    CoreColor? shadowBaseColor,
    CoreColor? barrierColor,
    double? barrierOpacity,
    CoreGapStyle? sectionGapStyle,
    CoreGapStyle? actionsGapStyle,
    double? actionSpacing,
    double? actionRunSpacing,
    CoreDialogActionsLayout? actionsLayout,
    double? contentClipMargin,
    double? routePadding,
    Duration? transitionDuration,
    double? scaleAnimationStart,
    double? scaleAnimationEnd,
    CoreTextStyle? titleStyle,
    CoreTextStyle? contentStyle,
    CoreButtonStyle? actionButtonStyle,
  }) {
    return CoreDialogStyle(
      panelBackgroundColor: panelBackgroundColor ?? this.panelBackgroundColor,
      panelBorderColor: panelBorderColor ?? this.panelBorderColor,
      panelBorderWidth: panelBorderWidth ?? this.panelBorderWidth,
      panelBorderRadius: panelBorderRadius ?? this.panelBorderRadius,
      panelPadding: panelPadding ?? this.panelPadding,
      panelMinWidth: panelMinWidth ?? this.panelMinWidth,
      panelMaxWidth: panelMaxWidth ?? this.panelMaxWidth,
      surfaceBlur: surfaceBlur ?? this.surfaceBlur,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      panelBoxShadow: panelBoxShadow ?? this.panelBoxShadow,
      shadowBaseColor: shadowBaseColor ?? this.shadowBaseColor,
      barrierColor: barrierColor ?? this.barrierColor,
      barrierOpacity: barrierOpacity ?? this.barrierOpacity,
      sectionGapStyle: sectionGapStyle ?? this.sectionGapStyle,
      actionsGapStyle: actionsGapStyle ?? this.actionsGapStyle,
      actionSpacing: actionSpacing ?? this.actionSpacing,
      actionRunSpacing: actionRunSpacing ?? this.actionRunSpacing,
      actionsLayout: actionsLayout ?? this.actionsLayout,
      contentClipMargin: contentClipMargin ?? this.contentClipMargin,
      routePadding: routePadding ?? this.routePadding,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      scaleAnimationStart: scaleAnimationStart ?? this.scaleAnimationStart,
      scaleAnimationEnd: scaleAnimationEnd ?? this.scaleAnimationEnd,
      titleStyle: titleStyle ?? this.titleStyle,
      contentStyle: contentStyle ?? this.contentStyle,
      actionButtonStyle: actionButtonStyle ?? this.actionButtonStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDialogStyle &&
          runtimeType == other.runtimeType &&
          panelBackgroundColor == other.panelBackgroundColor &&
          panelBorderColor == other.panelBorderColor &&
          panelBorderWidth == other.panelBorderWidth &&
          panelBorderRadius == other.panelBorderRadius &&
          panelPadding == other.panelPadding &&
          panelMinWidth == other.panelMinWidth &&
          panelMaxWidth == other.panelMaxWidth &&
          surfaceBlur == other.surfaceBlur &&
          surfaceOpacity == other.surfaceOpacity &&
          _shadowEq(panelBoxShadow, other.panelBoxShadow) &&
          shadowBaseColor == other.shadowBaseColor &&
          barrierColor == other.barrierColor &&
          barrierOpacity == other.barrierOpacity &&
          sectionGapStyle == other.sectionGapStyle &&
          actionsGapStyle == other.actionsGapStyle &&
          actionSpacing == other.actionSpacing &&
          actionRunSpacing == other.actionRunSpacing &&
          actionsLayout == other.actionsLayout &&
          contentClipMargin == other.contentClipMargin &&
          routePadding == other.routePadding &&
          transitionDuration == other.transitionDuration &&
          scaleAnimationStart == other.scaleAnimationStart &&
          scaleAnimationEnd == other.scaleAnimationEnd &&
          titleStyle == other.titleStyle &&
          contentStyle == other.contentStyle &&
          actionButtonStyle == other.actionButtonStyle;

  @override
  int get hashCode => Object.hashAll([
    panelBackgroundColor,
    panelBorderColor,
    panelBorderWidth,
    panelBorderRadius,
    panelPadding,
    panelMinWidth,
    panelMaxWidth,
    surfaceBlur,
    surfaceOpacity,
    if (panelBoxShadow != null) Object.hashAll(panelBoxShadow!),
    shadowBaseColor,
    barrierColor,
    barrierOpacity,
    sectionGapStyle,
    actionsGapStyle,
    actionSpacing,
    actionRunSpacing,
    actionsLayout,
    contentClipMargin,
    routePadding,
    transitionDuration,
    scaleAnimationStart,
    scaleAnimationEnd,
    titleStyle,
    contentStyle,
    actionButtonStyle,
  ]);

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

  static CoreGapStyle? _mergeGap(
    CoreGapStyle? base,
    CoreGapStyle? other,
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

/// Visual style definition for a dialog.
///
/// Defines colours for: surface background, text foreground, border,
/// and backdrop overlay. All values are platform-neutral
/// ([CoreColor]); the consuming renderer converts at use-site (Flutter
/// via `scheme.resolve(...).toValue()`; Web via `'bg-${color}'` /
/// `var(--coui-*)`).
@immutable
class CoreDialogVariantStyle {
  /// Creates a dialog variant style.
  const CoreDialogVariantStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.overlayColor,
  });

  /// Dialog surface background.
  final CoreColor backgroundColor;

  /// Panel foreground — the text and icon colour everything inside the
  /// panel inherits when it states no colour of its own (the leading /
  /// trailing slots). Web sets it as the panel's text class, Flutter as the
  /// panel's `DefaultTextStyle` / `IconTheme`. The title and body paint
  /// their typography defaults' colours instead
  /// ([CoreDialogStyle.defaultTitleStyle],
  /// [CoreDialogStyle.defaultContentStyle]).
  final CoreColor foregroundColor;

  /// Dialog border colour.
  final CoreColor borderColor;

  /// Backdrop overlay colour.
  final CoreColor overlayColor;
}
