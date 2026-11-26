/// Single-entry resolver and Tailwind helpers for `Banner` (Web).
///
/// Centralises the Epic #1302 / #1696 merge chain (`theme.banner.style` →
/// `theme.banner.variantStyles[variant]` → `component.bannerStyle`) and
/// converts the resolved [CoreBannerStyle] into a typed
/// [ResolvedBanner] bundle of [WebElementChrome] slots (className +
/// optional inline CSS). The widget reads from [ResolvedBanner] only
/// — no inline Tailwind composition in `co_banner.dart`.
///
/// Every colour / typography design value routes through the theme-free
/// emit family (`emitColor` / `emitTypography`) — a single
/// class-XOR-inline decision per value. Token-bound values (variant
/// defaults AND token overrides) emit Tailwind classes so they stay
/// dark-mode reactive; raw overrides go inline. No `scheme.resolve` (a
/// no-op on Web). Every dimensional value (padding / border-left width /
/// border radius / dismiss button padding + radius) is emitted inline
/// via `.toValue()` / rem.
///
/// The resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots passed to child unified
///   widgets. `iconStyle` is forwarded to the variant icon via
///   `Icon(iconStyle: …)`; `closeButtonStyle` is raw-forwarded to the
///   dismiss `Button(variant: .plain)`; `actionButtonStyle` is
///   forwarded to the action when it is a `Button`.
///
/// No scalar metadata (variant / iconSize / etc.) is exposed —
/// semantic identifiers stay on the widget prop.
library;

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

/// Paint-ready chrome for Web `Banner`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="banner">)
///   ├─ iconSpacer (<span aria-hidden>)         // only when showIcon — holds the icon's width
///   ├─ Gap (iconContentGapStyle)             // only when showIcon
///   └─ body (<div>)                            // flex-wrap: message + trailing
///        ├─ content (<div>)                    // position: relative
///        │    ├─ icon (<span aria-hidden>)     // only when showIcon — hung off the column
///        │    ├─ title (<div>)
///        │    │    └─ message
///        │    ├─ Gap (titleDescriptionGapStyle)   // only when description != null
///        │    └─ description (<div>)                // only when description != null
///        │         └─ description
///        └─ trailing (<div>)                       // only when action or onDismiss
///             ├─ action (<div>)                    // only when action != null
///             ├─ Gap (contentDismissGapStyle)      // only when both
///             └─ Button.plain (closeButtonStyle)   // only when onDismiss != null
///                  └─ Icon(closeButtonStyle.leadingIconStyle)
/// ```
///
/// `body` wraps: the message column is `flex: 1 1 <contentMinWidth>` and
/// the trailing group `flex: 0 0 auto`, so the trailing group stays beside
/// the column while the column keeps that floor and otherwise moves to
/// its own line, `row-gap` (`trailingRunSpacing`) below, starting where the
/// message text starts. `column-gap` is the gap the column keeps from the
/// trailing group on one line; a flex gap is not drawn across a line
/// break, so the wrapped line carries no leading gap.
///
/// The variant icon is out of flow: `iconSpacer` keeps its width (and the
/// `Gap` after it) in the root row, and the glyph itself is absolutely
/// positioned against the message column — its full height, to the column's
/// start side by the icon gap — so it is centred on the message block, on
/// one line and once the trailing group has wrapped below. Centring it on
/// the root instead would put it between the two lines.
///
/// All slot chromes are non-null — `co_banner` decides whether to
/// render each optional slot based on instance state.
///
/// The resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots passed to child unified
///   widgets. [iconStyle] is forwarded to the variant icon via
///   `Icon(iconStyle: …)`; [closeButtonStyle] is raw-forwarded to the
///   dismiss `Button(variant: .plain)`; [actionButtonStyle] is
///   forwarded to the action when it is a `Button`.
///   [iconContentGapStyle], [titleDescriptionGapStyle], and
///   [contentDismissGapStyle] are forwarded to `Gap(gapStyle: …)`
///   siblings so the inter-slot spacing matches Flutter 1:1.
///
/// No scalar metadata (variant / iconSize / etc.) is exposed —
/// semantic identifiers stay on the widget prop.
class ResolvedBanner implements WebResolvedChrome {
  /// Creates a [ResolvedBanner].
  const ResolvedBanner({
    required this.root,
    required this.iconSpacer,
    required this.icon,
    required this.body,
    required this.content,
    required this.trailing,
    required this.title,
    required this.description,
    required this.action,
    required this.iconStyle,
    required this.closeButtonStyle,
    required this.actionButtonStyle,
    required this.plainActionButtonStyle,
    required this.iconContentGapStyle,
    required this.titleDescriptionGapStyle,
    required this.contentDismissGapStyle,
  });

  /// Paint-ready chrome for the outermost `<div role="banner">` element
  /// (flex container + variant chrome + left border accent).
  ///
  /// The left accent is a single-edge border `CoreOutlinedContainerStyle`
  /// has no field for (its `borderWidth` is one scalar, drawn on every
  /// edge) — composing that primitive here would either grow a border on
  /// the other three edges or drop the accent, so this root restates the
  /// surface marker / control-shadow-rest / fill-var contract on its own
  /// box instead (the pattern `Alert` already uses on Web for a
  /// different reason). Its Flutter twin does the same restatement via
  /// `theme.surfaceFor` / `resolveSurfaceStroke` rather than composing
  /// `OutlinedContainer`, for the identical reason.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the in-flow `<span>` that keeps the icon's
  /// width in the root row — empty; the glyph is in [icon]. `co_banner`
  /// skips it when `showIcon` is false.
  final WebElementChrome iconSpacer;

  /// Paint-ready chrome for the variant icon wrapper `<span>`, hung off the
  /// message column: absolutely positioned over the column's full height,
  /// outside its start edge by the icon gap, centring the glyph. `co_banner`
  /// skips this element when `showIcon` is false.
  final WebElementChrome icon;

  /// Paint-ready chrome for the wrapping `<div>` that holds the message
  /// column and the trailing group — `flex-1` beside the icon, with the
  /// one-line `column-gap` and the wrapped-line `row-gap` inline.
  final WebElementChrome body;

  /// Paint-ready chrome for the title + description wrapper `<div>` — a
  /// column that grows from its `contentMinWidth` basis.
  final WebElementChrome content;

  /// Paint-ready chrome for the trailing group `<div>` (action + dismiss)
  /// — its own natural width, never grown or shrunk.
  final WebElementChrome trailing;

  /// Paint-ready chrome for the title `<div>`.
  final WebElementChrome title;

  /// Paint-ready chrome for the description `<div>` — `co_banner` skips
  /// this element when `description == null`.
  final WebElementChrome description;

  /// Paint-ready chrome for the action wrapper `<div>` — `co_banner`
  /// skips this element when `action == null`. The content → action
  /// gap is the `body` element's `column-gap`.
  final WebElementChrome action;

  /// Nested `CoreIconStyle` slot — passed to `Icon(iconStyle: …)` for
  /// the variant icon. Carries the resolved icon size and (when
  /// overridden) colour.
  final CoreIconStyle iconStyle;

  /// Nested `CoreButtonStyle` slot — raw-forwarded to
  /// `Button(variant: .plain, buttonStyle: …)` for the dismiss
  /// affordance (`co_banner` skips it when `onDismiss == null`).
  /// Chained `CoreBannerStyle.defaultCloseButtonStyle` →
  /// variant-foreground injection → caller `closeButtonStyle`; the
  /// button resolves its own padding / colours / hover-fade. The close
  /// glyph is a `Icon` child reading
  /// `closeButtonStyle.leadingIconStyle`.
  final CoreButtonStyle closeButtonStyle;

  /// Nested `CoreButtonStyle` slot — forwarded to the action when it is
  /// a `Button`, carrying the variant's foreground under the caller's
  /// own fields. Never null: the injection always states a colour, so an
  /// action that is a `Button` always has chrome to receive.
  final CoreButtonStyle actionButtonStyle;

  /// [actionButtonStyle] plus the inline inset a `plain` action needs —
  /// the bundle the widget forwards when the action is a `plain` `Button`.
  final CoreButtonStyle plainActionButtonStyle;

  /// Nested `CoreGapStyle` slot — forwarded to the `Gap(gapStyle: …)`
  /// sibling placed between the variant icon and the content. Mirrors the
  /// Flutter `Gap(gapStyle: resolved.iconContentGapStyle)` sibling 1:1.
  /// The content-to-action gap is the `body` element's `column-gap`.
  final CoreGapStyle iconContentGapStyle;

  /// Nested `CoreGapStyle` slot — forwarded to the `Gap(gapStyle: …)`
  /// sibling placed between the title and the description inside the
  /// content column. Mirrors the Flutter
  /// `Gap(gapStyle: resolved.titleDescriptionGapStyle)` sibling 1:1.
  final CoreGapStyle titleDescriptionGapStyle;

  /// Nested `CoreGapStyle` slot — forwarded to the `Gap(gapStyle: …)`
  /// sibling placed before the dismiss button. Mirrors the Flutter
  /// `Gap(gapStyle: resolved.contentDismissGapStyle)` sibling 1:1.
  final CoreGapStyle contentDismissGapStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedBanner] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.banner.style
///   → theme.coreComponentTheme.banner.variantStyles[variant]
///   → widget.bannerStyle
/// ```
///
/// The semantic [variant] is a widget prop — it threads through to
/// pick the variant token table here and the glyph in `co_banner`. The
/// theme cannot override it (semantic identifiers are widget-only).
///
/// [hasAction] says which slot leads the trailing group — the action, or
/// the dismiss button alone — and so which gap the message column keeps
/// from it on one line (the `body` element's `column-gap`).
ResolvedBanner resolveBanner(
  BuildContext context, {
  required CoreBannerVariant variant,
  required CoreBannerEmphasis emphasis,
  bool hasAction = false,
  CoreBannerStyle? bannerStyle,
}) {
  final bannerTheme = context.theme.coreComponentTheme?.banner;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreBannerStyle(), [
    bannerTheme?.style,
    bannerTheme?.variantStyles?[variant],
    bannerStyle,
  ]);

  // ─── Variant chrome (single source — defaultsByVariant) ───
  // Two axes: the tone says what kind of message, the emphasis how hard it
  // presses. Both are semantic identifiers off the component, so the theme
  // overrides neither and Flutter resolves the same pair.
  final vs = CoreBannerStyle.defaultsByVariant[variant]![emphasis]!;

  // ─── Stage1 RESOLVE — dimensional (all local var) ─────────
  // Every dimensional value below is `(merged.X ?? default)` and is
  // emitted inline via `.toValue()` / rem — no class-drop branch.
  final padding = (merged.padding ?? CoreBannerStyle.defaultPadding).toValue();
  // Inter-slot gaps are forwarded as nested `CoreGapStyle` slots so the
  // widget can render `Gap(gapStyle: …)` siblings — matching the
  // Flutter banner 1:1 (no inline `margin-*` on the surrounding chrome).
  final iconContentGapStyle = CoreBannerStyle.defaultIconContentGapStyle.merge(
    merged.iconContentGapStyle,
  );
  final titleDescriptionGapStyle = CoreBannerStyle
      .defaultTitleDescriptionGapStyle
      .merge(merged.titleDescriptionGapStyle);
  final contentDismissGapStyle = CoreBannerStyle.defaultContentDismissGapStyle
      .merge(merged.contentDismissGapStyle);
  final borderWidth = merged.borderWidth ?? CoreBannerStyle.defaultBorderWidth;
  // The floor half of the pair; the centring half is `items-center`,
  // already on the root className. Flutter states the same pair as a
  // BoxConstraints(minHeight:) over a centre-aligned Row.
  final minHeight = merged.minHeight ?? CoreBannerStyle.defaultMinHeight;
  final borderRadius =
      (merged.borderRadius ?? CoreBannerStyle.defaultBorderRadius).toValue();
  // The gap the message column keeps from whichever slot leads the trailing
  // group on one line — the action, else the dismiss. Both gap styles carry
  // a size through their defaults.
  final iconContentGapSize = iconContentGapStyle.size!;
  final contentTrailingGap =
      (hasAction ? iconContentGapStyle : contentDismissGapStyle).size!;
  final trailingRunSpacing =
      merged.trailingRunSpacing ?? CoreBannerStyle.defaultTrailingRunSpacing;
  // A layout bound: a `CoreLayout` step reads its variable, anything else
  // (an override off the scale) its own length. Density does not move it.
  final contentMinWidth =
      merged.contentMinWidth ?? CoreBannerStyle.defaultContentMinWidth;
  final contentMinWidthCss = CoreLayout.values.contains(contentMinWidth)
      ? 'var(--coui-layout-${contentMinWidth.toInt()})'
      : '${contentMinWidth / kRemDivisor}rem';

  // ─── Stage1 RESOLVE — nested icon slots (all local var) ───
  // Variant icon style — caller `iconStyle` slot wins, else
  // design-system default size. The resolved `CoreIconStyle` is
  // forwarded straight to `Icon(iconStyle: …)` by `co_banner`.
  final iconSize =
      merged.iconStyle?.size ?? CoreBannerStyle.defaultIconStyle.size;
  final iconStyle = (merged.iconStyle ?? const CoreIconStyle()).merge(
    CoreIconStyle(size: iconSize),
  );
  // Effective leading-icon colour — caller `iconStyle.color` else the
  // variant icon colour. Stays a `CoreColor` so the emit family / the
  // dismiss-button injection below keep the token reactive.
  final iconColor = merged.iconStyle?.color ?? vs.iconColor;
  // Dismiss-button chrome — chained `defaultCloseButtonStyle` (4-px tap
  // target + full-round corner + 20-px close glyph + 150 ms hover),
  // tinted with the effective icon colour so the glyph tracks the banner
  // variant, then the per-instance override on top (so a caller
  // `closeButtonStyle` still wins). Raw-forwarded to
  // `Button(variant: .plain, buttonStyle: …)` — the button resolves its own
  // padding / colours / hover-fade (mirrors the toast close button).
  // The glyph paints the variant's own foreground token at full strength,
  // resting and hovered alike. It used to rest at 70 % of that token and
  // fade up on hover, which produced a composited colour no contrast guard
  // could evaluate. A caller who wants a dimmer dismiss sets
  // `closeButtonStyle.foregroundColor` to a token that is actually dimmer.
  //
  // The variant row's focus-ring slot rides along: a solid row fills the
  // banner with a saturated colour, so its buttons state an opaque gap
  // band; a weak row states none and keeps the transparent default. The
  // caller's own slot still merges on top.
  final closeButtonStyle = CoreBannerStyle.defaultCloseButtonStyle
      .merge(
        CoreButtonStyle(
          foregroundColor: iconColor,
          hoverForegroundColor: iconColor,
          focusOutlineStyle: vs.focusOutlineStyle,
        ),
      )
      .merge(merged.closeButtonStyle);

  // Action-button slot — the variant's own foreground, then the
  // per-instance override on top (so a caller still wins). Same shape as
  // the dismiss injection above, and as `Toast`'s action.
  //
  // Without the injection a `Button` action keeps `plain`'s own label
  // colour, which is picked for a light neutral surface. On a solid
  // banner that is a dark grey label on a saturated fill: the message,
  // description, leading icon and dismiss glyph all track the variant
  // and the action alone did not.
  final actionForeground = merged.foregroundColor ?? vs.textColor;
  // The banner/toast foreground every action wears — shared by the two
  // bundles below so the plain one cannot drift from the other.
  final actionForegroundStyle = CoreButtonStyle(
    foregroundColor: actionForeground,
    hoverForegroundColor: actionForeground,
    focusOutlineStyle: vs.focusOutlineStyle,
  );
  final actionButtonStyle = CoreBannerStyle.defaultActionButtonStyle
      .merge(actionForegroundStyle)
      .merge(merged.actionButtonStyle);
  // A `plain` action gets the inline inset its variant lacks — and only
  // it; every other variant keeps its own size row's inset. The caller's
  // `actionButtonStyle` still wins over that default, the plain slot over
  // both. The widget picks between the two by the action's variant.
  final plainActionButtonStyle = CoreBannerStyle.defaultActionButtonStyle
      .merge(CoreBannerStyle.defaultPlainActionButtonStyle)
      .merge(actionForegroundStyle)
      .merge(merged.actionButtonStyle)
      .merge(merged.plainActionButtonStyle);

  // ─── Stage2 EMIT (Web, theme-free emit family) ────────────
  // Every colour / typography value routes through the emit family — a
  // single class-XOR-inline decision per value. Token-bound values
  // (variant defaults AND token overrides) emit Tailwind classes so they
  // stay dark-mode reactive; raw overrides go inline. No `scheme.resolve`
  // (a no-op on Web) and no hand-rolled `if (override != null)` branches.
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    vs.backgroundColor,
    .background,
  );
  // `solid` states no rule at all — a null colour means emit nothing, not
  // emit a transparent stroke (which would still occupy its width).
  final borderSource = merged.borderColor ?? vs.borderColor;
  final borderEmit = borderSource == null
      ? (className: '', inline: null)
      : emitColor(merged.borderColor, borderSource, .border);
  // The rule is a bottom border, so a raw border-colour override is
  // remapped from the emit's `border-color` property to
  // `border-bottom-color` before it reaches the inline bundle (token
  // borders stay on the class).
  final borderColorRaw = borderEmit.inline?['border-color'];
  final borderBottomColorInline = borderColorRaw == null
      ? const <String, String>{}
      : {'border-bottom-color': borderColorRaw};
  final foregroundEmit = emitColor(merged.foregroundColor, vs.textColor, .text);
  // Description has its own token: every `weak` pair steps it down to
  // `onSurfaceVariant` while the message keeps the tone's foreground.
  final descriptionColorEmit = emitColor(
    merged.foregroundColor,
    vs.descriptionColor,
    .text,
  );
  // Variant icon colour — caller `iconStyle.color` override else the
  // variant icon colour. Drives the icon `<span>` `currentColor`.
  final iconColorEmit = emitColor(merged.iconStyle?.color, vs.iconColor, .text);
  // Title / description typography — `emitTypography` merges the role
  // default with any per-instance overlay, emitting a `text-{role}` class
  // for a pure role or an inline bundle for a scalar/raw overlay. The
  // label colour inherits the root `foregroundEmit` class (banner sets
  // the variant tone on the root), so the slots carry only typography.
  final titleEmit = emitTypography(
    merged.titleStyle,
    CoreBannerStyle.defaultTitleStyle,
  );
  final descriptionEmit = emitTypography(
    merged.descriptionStyle,
    CoreBannerStyle.defaultDescriptionStyle,
  );
  // An explicit description color owns this text slot. Keep the root's
  // foreground for the message, action and other inherited content.
  final descriptionOverridesColor = merged.descriptionStyle?.color != null;

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes the root `<div role="banner">` Tailwind className —
  /// structural classes + variant colour tokens only (dimensional chrome
  /// lives inline).
  ///
  /// Marks this element as a component surface (`webSurfaceMarkerFor`)
  /// and, since the banner states no shadow of its own, takes the active
  /// style's injected cast at rest (`kControlShadowRestMarker`) — the
  /// same two things `OutlinedContainer` gives a composed surface for
  /// free, restated here because the left accent blocks literal
  /// composition (see [root]'s doc comment).
  String buildRootClassName() => <String>[
    ...webSurfaceMarkerFor(.content),
    // Full-width strip — the Flutter twin's root Row fills its parent
    // (mainAxisSize.max); without `w-full` the Web banner shrinks to
    // its content while Flutter spans the pane.
    WebLayout.flexFullItemsCenter,
    backgroundEmit.className,
    borderEmit.className,
    foregroundEmit.className,
    kControlShadowRestMarker,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the root `<div role="banner">` inline-CSS bundle — every
  /// dimensional value (padding / border-left width / border radius) is
  /// emitted inline (single inline signature), plus any raw colour
  /// override fragments from the emit family. The inter-slot spacing is
  /// NOT a uniform flex `gap` — the widget renders explicit
  /// `Gap(gapStyle: …)` siblings between slots so the spacing matches
  /// the Flutter banner 1:1.
  ///
  /// Publishes the resolved fill through [surfaceFillVar] — the other
  /// half of the surface contract restated in [buildRootClassName] — so
  /// a style preset can restate it translucently without knowing which
  /// token this variant filled with.
  Styles buildRootInlineStyles() {
    final raw = {
      'padding': padding,
      // Bottom rule only, and only when this emphasis states one.
      // `box-sizing: border-box` keeps it out of the outer height so
      // `weak` and `solid` stay the same 72 tall.
      if (borderSource != null) ...{
        'border-bottom-width': strokeWidthCss(borderWidth),
        // The material's band reaches over the rule on the bottom edge only.
        ...surfaceBleedBottomVar(strokeWidthCss(borderWidth)),
      },
      'box-sizing': 'border-box',
      'min-height': '${minHeight / kRemDivisor}rem',
      'border-radius': borderRadius,
      ...surfaceFillVar(merged.backgroundColor ?? vs.backgroundColor),
      ...?backgroundEmit.inline,
      ...borderBottomColorInline,
      ...?foregroundEmit.inline,
    };
    return Styles(raw: raw);
  }

  /// Composes the variant-icon wrapper `<span>` Tailwind className —
  /// variant text colour drives the SVG via `currentColor`.
  String buildIconClassName() => <String>[
    [
      WebLayout.absolute,
      WebLayout.inlineFlex,
      WebLayout.itemsCenter,
      WebLayout.justifyCenter,
    ].join(' '),
    iconColorEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the icon spacer `<span>` Tailwind className — it never
  /// shrinks, so the row keeps the icon's width.
  String buildIconSpacerClassName() => WebLayout.shrinkZero;

  /// Composes the icon spacer inline-CSS bundle — the icon's own width, the
  /// length `Icon` gives the glyph, so the glyph hung off the column lands
  /// exactly where the in-flow icon used to.
  Styles buildIconSpacerInlineStyles() => Styles(
    raw: {'width': '${iconSize! / kRemDivisor}rem'},
  );

  /// Composes the variant-icon inline-CSS bundle — the slot `iconStyle`
  /// raw colour override (the icon → content gap lives on a sibling
  /// `Gap(gapStyle: resolved.iconContentGapStyle)`, not on the icon
  /// itself).
  Styles buildIconInlineStyles() => Styles(
    raw: {
      // The column's full height, so `items-center` centres the glyph on
      // the message block.
      'top': '0',
      'bottom': '0',
      // Outside the column's start edge by the icon gap — where the
      // spacer and the `Gap` after it put the glyph's box.
      'inset-inline-end': 'calc(100% + ${spaceCss(iconContentGapSize)})',
      ...?iconColorEmit.inline,
    },
  );

  /// Composes the wrapping body `<div>` Tailwind className — a wrapping
  /// flex row that takes the width beside the icon (`flex-1` + `min-w-0`)
  /// and centres the column and the trailing group on each line.
  String buildBodyClassName() => [
    WebLayout.flex,
    WebLayout.flexWrap,
    WebLayout.itemsCenter,
    WebLayout.flex1,
    WebLayout.minWZero,
  ].join(' ');

  /// Composes the body inline-CSS bundle — the one-line gap between the
  /// column and the trailing group, and the wrapped line's distance. Both
  /// are spacing, so both ride the spacing variables.
  Styles buildBodyInlineStyles() => Styles(
    raw: {
      'column-gap': spaceCss(contentTrailingGap),
      'row-gap': spaceCss(trailingRunSpacing),
    },
  );

  /// Composes the title + description wrapper `<div>` Tailwind
  /// className — `flex flex-col` so the title / `Gap` / description
  /// stack vertically.
  String buildContentClassName() =>
      '${WebLayout.relative} ${WebLayout.flex} ${WebLayout.flexCol}';

  /// Composes the column's inline-CSS bundle — it grows from its floor,
  /// and the floor never asks for more than the line it is on (a column
  /// alone on a line narrower than the floor takes that line's width, as
  /// the Flutter twin gives it the full width).
  Styles buildContentInlineStyles() => Styles(
    raw: {
      'flex': '1 1 $contentMinWidthCss',
      'min-width': 'min($contentMinWidthCss, 100%)',
    },
  );

  /// Composes the trailing group `<div>` Tailwind className — a centred
  /// row at its own natural width (`shrink-0`, no grow).
  String buildTrailingClassName() =>
      '${WebLayout.flexItemsCenter} ${WebLayout.shrinkZero}';

  /// Composes the action wrapper `<div>` Tailwind className — `shrink-0`
  /// so the action keeps its intrinsic size inside the trailing group.
  String buildActionClassName() => WebLayout.shrinkZero;

  /// Composes the title `<div>` Tailwind className — `labelLarge`
  /// typography role token (from the emit family). The colour inherits
  /// the root variant tone.
  String buildTitleClassName() => titleEmit.className;

  /// Composes the title `<div>` inline-CSS bundle — explicit
  /// `titleStyle` typography overlays only (the emit family routes a
  /// token colour to a class and any raw scalar overlay inline).
  Styles? buildTitleInlineStyles() {
    final inline = titleEmit.inline;
    return inline == null ? null : Styles(raw: inline);
  }

  /// Composes the description `<div>` Tailwind className — `bodySmall`
  /// typography role token plus its own colour class. The colour is
  /// stated here rather than inherited from the root because the
  /// description parts ways with the title on every `weak` pair; on the
  /// `solid` pairs it resolves to the same token and the class is a
  /// harmless restatement. The vertical gap to the title lives on a
  /// sibling `Gap(gapStyle: resolved.titleDescriptionGapStyle)`.
  String buildDescriptionClassName() => [
    descriptionEmit.className,
    if (!descriptionOverridesColor) descriptionColorEmit.className,
  ].where((c) => c.isNotEmpty).join(' ');

  /// Composes the description `<div>` inline-CSS bundle — explicit
  /// `descriptionStyle` typography overlays plus a raw colour override.
  Styles? buildDescriptionInlineStyles() {
    final raw = {
      ...?descriptionEmit.inline,
      if (!descriptionOverridesColor) ...?descriptionColorEmit.inline,
    };
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedBanner(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    iconSpacer: WebElementChrome(
      className: buildIconSpacerClassName(),
      inlineStyles: buildIconSpacerInlineStyles(),
    ),
    icon: WebElementChrome(
      className: buildIconClassName(),
      inlineStyles: buildIconInlineStyles(),
    ),
    body: WebElementChrome(
      className: buildBodyClassName(),
      inlineStyles: buildBodyInlineStyles(),
    ),
    content: WebElementChrome(
      className: buildContentClassName(),
      inlineStyles: buildContentInlineStyles(),
    ),
    trailing: WebElementChrome(className: buildTrailingClassName()),
    title: WebElementChrome(
      className: buildTitleClassName(),
      inlineStyles: buildTitleInlineStyles(),
    ),
    description: WebElementChrome(
      className: buildDescriptionClassName(),
      inlineStyles: buildDescriptionInlineStyles(),
    ),
    action: WebElementChrome(className: buildActionClassName()),
    iconStyle: iconStyle,
    // Raw forward — flows straight into
    // `Button(variant: .plain, buttonStyle: …)`; the button's own
    // resolver resolves colours / padding / hover-fade.
    closeButtonStyle: closeButtonStyle,
    actionButtonStyle: actionButtonStyle,
    plainActionButtonStyle: plainActionButtonStyle,
    iconContentGapStyle: iconContentGapStyle,
    titleDescriptionGapStyle: titleDescriptionGapStyle,
    contentDismissGapStyle: contentDismissGapStyle,
  );
}
