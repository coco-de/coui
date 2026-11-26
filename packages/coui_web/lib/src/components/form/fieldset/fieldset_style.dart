library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Fieldset`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                      // the variant's box (plain: none), flex column
///   ├─ header (<div>)               // renders only when legend != null || description != null
///   │    ├─ legendWrapper (<div>)   // renders only when legend != null
///   │    │    └─ legend (<span>)    // caller-provided legend content
///   │    ├─ Gap (legendDescriptionGapStyle)   // both != null
///   │    └─ description (<div>)     // caller-provided description content
///   ├─ Gap (headerFieldsGapStyle)   // header && children
///   └─ fields (<div>)               // renders only when children non-empty
///        └─ children (Components)   // stacked form rows
/// ```
///
/// `co_fieldset.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion
/// in the widget body.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries `WebElementChrome`
/// slots (paint-ready chrome) plus the two nested `CoreGapStyle` slots
/// forwarded raw to `Gap`. Dimensional chrome
/// (radius / padding / fieldSpacing / border-width / legend padding) is
/// always
/// emitted inline as `(merged.X ?? variant row).toValue()` / rem (single
/// signature — no dimensional Tailwind class, no class-drop branch).
/// Colour / typography keep the token-class default + inline override
/// surface (card model). The legend typography override is folded into
/// the legend slot's inline CSS here — no nested `CoreTextStyle` slot is
/// exposed because the legend is rendered as a raw `<span>` (not a
/// unified child widget).
class ResolvedFieldset implements WebResolvedChrome {
  /// Creates a [ResolvedFieldset].
  const ResolvedFieldset({
    required this.root,
    required this.header,
    required this.legendWrapper,
    required this.legend,
    required this.description,
    required this.fields,
    required this.legendDescriptionGapStyle,
    required this.headerFieldsGapStyle,
  });

  /// Paint-ready chrome for the outermost `<div>` group container.
  ///
  /// className carries the layout classes plus the colour token classes
  /// (the variant's fill / `border-<token>`) and the state-driven
  /// `opacity-50` disabled class. The dimensional
  /// chrome (border-radius / padding / border-width) is
  /// always
  /// emitted inline through the inline-CSS bundle as
  /// `(merged.X ?? variant row).toValue()` / rem; the colour overrides layer
  /// on inline when the caller overrode them. The spacing between fields
  /// lives on [fields], not here — the header sits apart from the fields
  /// by its own gap.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the header `<div>` that holds the legend and
  /// the description — a flex column. `co_fieldset` skips this element
  /// when neither is given.
  final WebElementChrome header;

  /// Paint-ready chrome for the legend wrapper `<div>` — the legend
  /// padding emitted inline as `(merged.legendPadding ?? default)`
  /// through `CoreEdgeInsets.toValue()` (no `p-*` class). `co_fieldset`
  /// skips this element when `legend == null`.
  final WebElementChrome legendWrapper;

  /// Paint-ready chrome for the legend `<span>` — the design-system
  /// default typography (Tailwind `text-* font-*` classes) on the
  /// default path plus the caller-supplied [CoreTextStyle] override
  /// layered as inline CSS (the matching token / colour / weight class
  /// is suppressed when overridden, card model). `co_fieldset` skips
  /// this element when `legend == null`.
  final WebElementChrome legend;

  /// Paint-ready chrome for the description `<div>` — the design-system
  /// default typography (`bodySmall` + `onSurfaceVariant`) as Tailwind
  /// classes plus any caller [CoreTextStyle] override layered inline.
  /// The disabled state does not recolour it: the root's `opacity-50`
  /// dims it with the rest of the group. `co_fieldset` skips this element
  /// when `description == null`.
  final WebElementChrome description;

  /// Paint-ready chrome for the fields `<div>` — a flex column whose
  /// inline `gap` is the spacing between fields. `co_fieldset` skips this
  /// element when there are no children.
  final WebElementChrome fields;

  /// Gap between the legend and the description beneath it — nested
  /// [CoreGapStyle] forwarded raw to the `Gap` component (it scales
  /// itself).
  final CoreGapStyle legendDescriptionGapStyle;

  /// Gap between the header (legend, then description) and the first
  /// field — nested [CoreGapStyle] forwarded raw to the `Gap` component.
  final CoreGapStyle headerFieldsGapStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedFieldset] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreFieldsetStyle.default*,
///                        defaultsByVariant[variant], defaultsBySize[size])
///   → theme.coreComponentTheme.fieldset.style
///   → theme.coreComponentTheme.fieldset.variantStyles[variant]
///   → widget.fieldsetStyle
/// ```
ResolvedFieldset resolveFieldset(
  BuildContext context, {
  required bool enabled,
  required CoreComponentSize size,
  CoreFieldsetVariant variant = CoreFieldsetVariant.defaultVariant,
  CoreFieldsetStyle? fieldsetStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.fieldset;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreFieldsetStyle(), [
    csTheme?.style,
    csTheme?.variantStyles?[variant],
    fieldsetStyle,
  ]);
  final variantStyle = CoreFieldsetStyle.defaultsByVariant[variant]!;

  // ─── Resolved chrome values ───────────────────────────
  // Each default flows from `CoreFieldsetStyle.default*` — the single
  // source of truth both platforms read (the Flutter resolver folds in
  // the same constants), so a designer override to a Style default
  // reaches Web and Flutter alike.
  //
  // Dimensional chrome is always emitted inline via
  // `(merged.X ?? default).toValue()` / rem (single signature — no
  // Tailwind class, no class-drop branch). The radius / padding share
  // their CSS surface across default and override so the resolved chrome
  // reflects `merged.X` directly (Epic #1603 signature gate).
  final borderRadius = (merged.borderRadius ?? variantStyle.borderRadius!)
      .toValue();
  final fieldSpacing =
      merged.fieldSpacing ?? CoreFieldsetStyle.defaultFieldSpacing;
  final padding = (merged.padding ?? variantStyle.padding!).toValue();
  final borderWidth = merged.borderWidth ?? variantStyle.borderWidth!;
  final legendPadding =
      merged.legendPadding ?? CoreFieldsetStyle.defaultLegendPadding;

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Colour / typography route through the emit family — one
  // class-XOR-inline decision per design value. Token-bound values emit
  // Tailwind classes (dark-mode reactive); raw overrides go inline. No
  // `scheme.resolve` (a no-op on Web) and no hand-rolled
  // `if (override != null)` / `.token!.name` branches.
  //
  // The variant's row states the fill. `outlined` / `plain` state the
  // token-less transparent sentinel (`CoreFieldsetStyle
  // .defaultBackgroundColor`), so `emitColor` emits `background-color:
  // transparent` inline on that path (no fill class) and any token / raw
  // override layers in the same way; `filled` states a token and emits its
  // class.
  final effectiveBackground =
      merged.backgroundColor ?? variantStyle.backgroundColor!;
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    variantStyle.backgroundColor!,
    .background,
  );
  // A raw colour whose token is null and whose ARGB is `0` (the
  // `CoreColor.transparent` sentinel itself) means "no fill" — mirrors
  // the Flutter resolver's `hasFill` check. Gated because `backdrop-
  // filter` is independent of the fill var: an unconditional marker
  // would frost a box with no tint to explain it.
  final hasFill =
      effectiveBackground.token != null || effectiveBackground.argb != 0;
  final effectiveBorderColor = merged.borderColor ?? variantStyle.borderColor!;
  final borderEmit = emitColor(
    merged.borderColor,
    variantStyle.borderColor!,
    .border,
  );
  // A box exists when it paints a fill or an edge — mirrors the Flutter
  // resolver's `hasBox`. `plain` states neither, so it takes no cast and no
  // material: a cast around nothing would float as a stray shadow.
  final hasEdge =
      borderWidth > 0 &&
      (effectiveBorderColor.token != null || effectiveBorderColor.argb != 0);
  final hasBox = hasFill || hasEdge;
  // Legend typography — Stage 1 RESOLVE: the size-keyed default (role +
  // colour) is the EMIT baseline instead of the flat
  // `defaultLegendTextStyle` directly — `xs`/`sm`/`md` settle on the
  // 16px `titleSmall` rung, `lg`/`xl`/`xl2` on the 18px `titleMedium`
  // rung (`CoreFieldsetStyle.defaultsBySize`). `enabled` forces the
  // colour half of both the baseline and any per-instance override to
  // `disabledLegendColor` — the size-derived role still applies
  // underneath, and a per-instance colour override cannot silently win
  // over the disabled state (same "select between resolved values"
  // shape `resolveFormLabel` uses — a plain `<span>` legend has no CSS
  // "disabled" pseudo-class to lean on anyway, so this has to be a
  // build-time select).
  final sizeLegendTextStyle =
      CoreFieldsetStyle.defaultsBySize[size]!.legendTextStyle!;
  final disabledLegendColor =
      merged.disabledLegendColor ??
      CoreFieldsetStyle.defaultDisabledLegendColor;
  final legendStyleBase = enabled
      ? sizeLegendTextStyle
      : sizeLegendTextStyle.copyWith(color: disabledLegendColor);
  final legendStyleOverride = enabled
      ? merged.legendTextStyle
      : merged.legendTextStyle?.copyWith(color: disabledLegendColor);

  // EMIT Stage 2 (theme-free) — `emitTypography` merges the resolved
  // base role with any per-instance overlay, emitting the `text-{role}`
  // (+ token colour) classes for a pure role and any explicit scalar /
  // raw colour overlay inline. Single typography entry point — no
  // manual `text-${...token!.name}` role-class assembly.
  final legendEmit = emitTypography(legendStyleOverride, legendStyleBase);

  // Description typography — same entry point; the colour does not switch
  // with `enabled` (the root's `opacity-50` dims it with the group).
  final descriptionEmit = emitTypography(
    merged.descriptionTextStyle,
    CoreFieldsetStyle.defaultDescriptionTextStyle,
  );

  // Nested gap slots — composite, so `default.merge(merged)`, forwarded raw
  // to `Gap`.
  final legendDescriptionGapStyle = CoreFieldsetStyle
      .defaultLegendDescriptionGapStyle
      .merge(merged.legendDescriptionGapStyle);
  final headerFieldsGapStyle = CoreFieldsetStyle.defaultHeaderFieldsGapStyle
      .merge(merged.headerFieldsGapStyle);

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer container Tailwind className. Layout classes are
  /// always present; the colour classes come from the emit family
  /// ([backgroundEmit] / [borderEmit] — token-bound colours emit a class,
  /// raw overrides emit inline). The bare `border` class supplies the
  /// border-style (the width / colour layer over it). The dimensional
  /// chrome is inline-only (see [buildRootInlineStyles]).
  String buildRootClassName() {
    final classList = [
      // States no shadow of its own, so it takes the style's — the
      // Flutter twin reads the same cast. No-op under every style that
      // injects none. Gated on [hasBox]: a box-less (`plain`) group takes
      // no cast.
      if (hasBox) kControlShadowRestMarker,
      // `items-stretch` so form-input children fill the inline-axis
      // (matches the Flutter `crossAxisAlignment: .stretch`).
      WebLayout.wFull,
      WebLayout.flex,
      WebLayout.flexCol,
      WebLayout.itemsStretch,
      backgroundEmit.className,
      'border',
      borderEmit.className,
      if (!enabled) 'opacity-50',
      // Marks the panel as a component surface — restated here rather
      // than composing an `OutlinedContainer` Web widget (a single
      // `<div>`, no nested chrome to delegate); the Flutter twin
      // composes the primitive. Gated on [hasFill]: the default
      // background is the token-less transparent sentinel, and
      // `backdrop-filter` is independent of the fill var, so marking a
      // fill-less box would frost it with nothing to explain the tint
      // (mirrors the Flutter resolver's `surfaceBlur: 0`).
      if (hasFill) ...webSurfaceMarkerFor(.content),
    ];

    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the outer container inline-CSS bundle. The dimensional
  /// chrome (border-radius / padding / border-width) is
  /// always inline as `(merged.X ?? variant row).toValue()` / rem; the
  /// emit-family colour fragments layer on inline only for raw overrides
  /// (token colours stay on classes). Always non-null because dimensional
  /// chrome is unconditional.
  Styles buildRootInlineStyles() {
    final raw = {
      'border-radius': borderRadius,
      'padding': padding,
      'border-width': strokeWidthCss(borderWidth),
      ...?backgroundEmit.inline,
      ...?borderEmit.inline,
      // The other half of the surface marker above.
      if (hasFill) ...surfaceFillVar(effectiveBackground),
    };

    return Styles(raw: raw);
  }

  /// Composes the legend-wrapper `<div>` inline-CSS — the legend
  /// padding emitted always inline as
  /// `(merged.legendPadding ?? default).toValue()` (single signature —
  /// no `p-*` class).
  Styles buildLegendWrapperInlineStyles() => .new(
    raw: {
      'padding': legendPadding.toValue(),
    },
  );

  /// Composes the fields-wrapper inline-CSS — the spacing between fields
  /// (`gap`), inline through `spaceCss` so the density axis reaches it.
  Styles buildFieldsInlineStyles() => .new(
    raw: {
      'gap': spaceCss(fieldSpacing),
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedFieldset(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    header: const WebElementChrome(
      className:
          '${WebLayout.wFull} ${WebLayout.flex} ${WebLayout.flexCol} '
          '${WebLayout.itemsStretch}',
    ),
    legendWrapper: WebElementChrome(
      className: '',
      inlineStyles: buildLegendWrapperInlineStyles(),
    ),
    legend: WebElementChrome(
      className: legendEmit.className,
      inlineStyles: legendEmit.inline == null
          ? null
          : Styles(raw: legendEmit.inline),
    ),
    description: WebElementChrome(
      className: descriptionEmit.className,
      inlineStyles: descriptionEmit.inline == null
          ? null
          : Styles(raw: descriptionEmit.inline),
    ),
    fields: WebElementChrome(
      className:
          '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.itemsStretch}',
      inlineStyles: buildFieldsInlineStyles(),
    ),
    legendDescriptionGapStyle: legendDescriptionGapStyle,
    headerFieldsGapStyle: headerFieldsGapStyle,
  );
}
