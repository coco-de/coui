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

/// Paint-ready chrome for Web `Accordion`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                       // accordion container
///   ├─ item renderer (<div>)         // per item — trigger + content
///   │    ├─ Clickable (<div role="button">)  // owns interaction + focus ring
///   │    │    └─ trigger (<div>)     // header row — resolveAccordionItem.trigger
///   │    │         ├─ title span     // user-supplied label
///   │    │         └─ chevron span   // resolveAccordionItem.chevron
///   │    └─ content (<div>)          // resolveAccordionItem.content
///   │         └─ content inner (<div>)  // resolveAccordionItem.contentInner
///   └─ divider (<div>)               // between items + trailing — only when overridden
/// ```
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots ([root] / [divider]) for the
///   outer container and the optional between-items rule.
/// * Cat 2 — the nested [CoreAccordionStyle] slot ([accordionStyle]) —
///   the fully-merged style bundle forwarded to [resolveAccordionItem]
///   so the per-item resolver consumes a single source of truth without
///   re-running the merge chain.
///
/// No scalar metadata (variant / allowMultiple) is exposed — semantic
/// identifiers stay on the widget prop.
///
/// `root` carries the outer container chrome (`w-full` className plus the
/// emit-family background / border colour token classes, and the optional
/// inline chrome bundle for border-radius / border-width / row-gap when
/// the merged style overrides them). `divider` carries the between-items
/// rule chrome — non-null only when the merged style supplies a custom
/// `dividerColor` / `dividerThickness` (the widget falls back to the
/// default `Separator` when `divider == null`).
class ResolvedAccordion implements WebResolvedChrome {
  /// Creates a [ResolvedAccordion].
  const ResolvedAccordion({
    required this.root,
    required this.accordionStyle,
    required this.clickableStyle,
    this.divider,
  });

  /// Paint-ready chrome for the outer container `<div>` — `w-full`
  /// className (plus the emit-family background / border colour token
  /// classes), plus the optional inline-CSS bundle for radius /
  /// border-width / row-gap overrides from the merged style.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the between-items divider `<div>` —
  /// `w-full` className (plus the emit-family `background-color` token
  /// class) plus `height` inline-CSS driven by the merged `dividerColor`
  /// / `dividerThickness`. `null` when the merged style supplies neither;
  /// the widget then falls back to the default `Separator`.
  final WebElementChrome? divider;

  /// Nested [CoreAccordionStyle] slot — the fully-merged style bundle
  /// (`design-system default → theme.style → widget.accordionStyle`)
  /// forwarded to [resolveAccordionItem] so the per-item resolver
  /// composes from the same source of truth.
  final CoreAccordionStyle accordionStyle;

  /// Nested [CoreClickableStyle] slot for the composed per-item trigger
  /// `Clickable` — `CoreAccordionStyle.defaultClickableStyle` merged with
  /// the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle: …)`. The Clickable owns the trigger's
  /// click / keyboard activation / cursor / press feedback / focus ring.
  final CoreClickableStyle clickableStyle;
}

/// Resolver output for a single accordion item's chrome (Web).
///
/// DOM shape (per item):
///
/// ```text
/// Clickable (<div role="button">)     // owns interaction + focus ring
///   └─ trigger (<div>)                // resolved.trigger — header row
///        ├─ title span                // user-supplied label
///        └─ chevron span              // resolved.chevron
/// content (<div>)                     // resolved.content
///   └─ content inner (<div>)          // resolved.contentInner
/// ```
///
/// Each slot is pre-composed for the current per-item `isExpanded`
/// state by [resolveAccordionItem]; the widget passes the
/// className / inlineStyles pairs straight to the matching `<div>` /
/// `<span>`.
///
/// Per Epic #1603 (옵션 B 최종) the resolver also carries:
/// * Cat 2 — nested [CoreIconStyle] slot ([chevronIconStyle]) forwarded
///   to `Icon(iconStyle: …)`.
class ResolvedAccordionItem implements WebResolvedChrome {
  /// Creates a [ResolvedAccordionItem].
  const ResolvedAccordionItem({
    required this.trigger,
    required this.triggerTitle,
    required this.chevron,
    required this.content,
    required this.contentInner,
    required this.chevronIconStyle,
  });

  /// Paint-ready chrome for the trigger row `<div>` (the header row
  /// nested inside the composing `Clickable`) — Tailwind `flex` /
  /// `flex-1` / `items-center` / `justify-between` / label typography
  /// role className, plus the inline-CSS bundle carrying the resolved
  /// trigger padding / gap and the optional background / colour /
  /// typography overlays. Cursor / focus ring / press feedback are owned
  /// by the composing `Clickable` wrapper.
  ///
  /// The trigger acts as the `root` per the
  /// [WebResolvedChrome] contract — it's the outermost element of
  /// the per-item chrome surface.
  @override
  WebElementChrome get root => trigger;

  /// Paint-ready chrome for the trigger row `<div>` — see [root].
  final WebElementChrome trigger;

  /// Paint-ready layout chrome for the trigger title `<span>`
  /// (`flex-1 text-left`) — render-only: the layout lives in the
  /// resolver, not the widget.
  final WebElementChrome triggerTitle;

  /// Paint-ready chrome for the chevron icon wrapper `<span>` —
  /// `flex items-center shrink-0 transition-transform` className (a box
  /// exactly as tall as the icon, so it turns about the icon's centre)
  /// with `rotate-180` appended when expanded, plus the inline-CSS bundle
  /// carrying the
  /// resolved `transition-duration` and the optional chevron colour
  /// override.
  final WebElementChrome chevron;

  /// Paint-ready chrome for the content collapse wrapper `<div>` —
  /// `overflow-hidden transition-all ease-in-out` className, plus the
  /// `display:grid; grid-template-rows: {0fr|1fr}` inline-CSS bundle
  /// that drives the expand / collapse animation alongside the
  /// resolved `transition-duration`.
  final WebElementChrome content;

  /// Paint-ready chrome for the content inner `<div>` — `bodySmall`
  /// typography role className, plus the inline-CSS bundle for
  /// `min-height:0` (required so the parent grid row can fully collapse
  /// to zero height), the resolved content padding (when expanded), and
  /// the optional merged content text style overlays.
  final WebElementChrome contentInner;

  /// Nested [CoreIconStyle] slot — design-system default merged with
  /// the per-instance `arrowIconStyle` / `chevronIconStyle` override.
  /// Forwarded to `Icon(iconStyle: …)` by `co_accordion` so the
  /// chevron icon sizes / colours from a single source of truth (no raw
  /// scalar leak).
  final CoreIconStyle chevronIconStyle;
}

// ═══════════════════════════════════════════════════
// Resolvers
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedAccordion] for the given [context].
///
/// Single entry point for the accordion Style slot — applies the
/// two-stage merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.accordion.style
///   → widget.accordionStyle
/// ```
ResolvedAccordion resolveAccordion(
  BuildContext context, {
  CoreAccordionStyle? accordionStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.accordion;

  // ─── Stage 1 RESOLVE — merge chain (local var) ────────
  final merged = resolveStyleChain(const CoreAccordionStyle(), [
    coreTheme?.style,
    accordionStyle,
  ]);

  // ─── Local builders — outer container chrome ──────────

  // A caller-supplied background is the only thing that gives this
  // panel a fill — see `CoreAccordionStyle.backgroundColor`'s doc: there
  // is no design-system default, so an accordion with no override draws
  // no box at all. `backdrop-filter` is independent of the fill var, so
  // marking a fill-less panel would frost a box with nothing to explain
  // the tint (mirrors the Flutter resolver's `surfaceBlur: 0`).
  final hasFill = merged.backgroundColor != null;

  /// Composes the outer container `<div>` Tailwind className — content-sized
  /// plus the emit-family background / border colour token classes
  /// (raw overrides go inline instead and contribute an empty class).
  String buildRootClassName() {
    final classList = [
      // Flutter hugs loose constraints and fills tight ones. Let the block
      // follow its parent's flow: content width as a flex item, full width
      // in a block parent. Callers can still state an explicit width.
      WebLayout.maxWFull,
      if (merged.backgroundColor != null)
        emitColor(
          merged.backgroundColor,
          merged.backgroundColor!,
          .background,
        ).className,
      if (merged.borderColor != null)
        emitColor(merged.borderColor, merged.borderColor!, .border).className,
      // Marks this as a component surface, so a material preset reaches
      // it. Its Flutter twin gets the same treatment by composing
      // `OutlinedContainer` — without this restatement the same
      // accordion is glass on one platform and an opaque box (or, here,
      // nothing at all) on the other. Gated on [hasFill] for the same
      // reason `Fieldset` gates it.
      if (hasFill) ...webSurfaceMarkerFor(.content),
    ];
    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the outer container `<div>` inline CSS — the merged
  /// background / border colour raw-override fragments (token values
  /// stay on classes), plus border-width / border-radius / row-gap
  /// overrides. Each is override-only (no design-system default) so the
  /// rule is emitted only when the merged style supplies it. Returns
  /// `null` when none apply so the widget can skip the `styles`
  /// attribute entirely.
  Styles? buildRootInlineStyles() {
    final backgroundInline = merged.backgroundColor == null
        ? null
        : emitColor(
            merged.backgroundColor,
            merged.backgroundColor!,
            .background,
          ).inline;
    final borderInline = merged.borderColor == null
        ? null
        : emitColor(merged.borderColor, merged.borderColor!, .border).inline;
    final raw = <String, String>{
      ...?backgroundInline,
      ...?borderInline,
      // The other half of the surface marker above.
      if (hasFill) ...surfaceFillVar(merged.backgroundColor!),
    };
    if (merged.borderWidth != null) {
      raw['border-width'] = strokeWidthCss(merged.borderWidth!);
    }
    if (merged.borderRadius != null) {
      raw['border-radius'] = merged.borderRadius!.toValue();
    }
    if (merged.itemSpacing != null) {
      raw['display'] = WebLayout.flex;
      raw['flex-direction'] = 'column';
      raw['row-gap'] = spaceCss(merged.itemSpacing!);
    }
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  // ─── Local builders — between-items divider chrome ────

  /// Composes the divider `<div>` chrome — non-null only when the
  /// merged style supplies a custom `dividerColor` and / or
  /// `dividerThickness`. Returns `null` otherwise (the widget falls
  /// back to the default `Separator`).
  WebElementChrome? buildDividerChrome() {
    if (merged.dividerColor == null && merged.dividerThickness == null) {
      return null;
    }
    final dividerEmit = merged.dividerColor == null
        ? null
        : emitColor(merged.dividerColor, merged.dividerColor!, .background);
    final raw = <String, String>{...?dividerEmit?.inline};
    if (merged.dividerThickness != null) {
      // Stroke-axis value (mirrors Flutter's composed `Divider`, which
      // always runs `theme.geometry.stroke` on this same field) — must
      // ride `strokeWidthCss` so the neo-brutalism `strokeFloor` preset
      // reaches it via `--coui-stroke-width-N`, not a literal rem it
      // can't override.
      raw['height'] = strokeWidthCss(merged.dividerThickness!);
    }
    final className = [
      WebLayout.wFull,
      ?dividerEmit?.className,
    ].where((cls) => cls.isNotEmpty).join(' ');
    return WebElementChrome(
      className: className,
      inlineStyles: raw.isEmpty ? null : Styles(raw: raw),
    );
  }

  // Nested Clickable slot — partial default (pressedScale off + focus-ring
  // corner) merged with the per-instance override, raw-forwarded (the
  // Clickable's own resolver fills the rest). The Clickable owns each
  // trigger's click / keyboard activation / cursor / press feedback /
  // focus ring.
  final clickableStyle = CoreAccordionStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── RETURN — bare mapping ────────────────────────────
  return ResolvedAccordion(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    accordionStyle: merged,
    clickableStyle: clickableStyle,
    divider: buildDividerChrome(),
  );
}

/// Resolves [ResolvedAccordionItem] for a single accordion item.
///
/// Reads the merged [CoreAccordionStyle] off [resolved] so the per-item
/// chrome composes from the same source of truth without re-running the
/// merge chain. Closes over the per-item runtime state ([isExpanded]) so
/// each slot's chrome bundle is pre-composed.
ResolvedAccordionItem resolveAccordionItem({
  required ResolvedAccordion resolved,
  required bool isExpanded,
}) {
  final merged = resolved.accordionStyle;

  // ─── Stage 1 RESOLVE — merge chain + default fallback ─

  // Trigger row chrome — design-system default (`defaultTriggerStyle`:
  // vertical padding) merged with the per-instance override so the
  // padding composes from a single source of truth.
  final triggerStyle = CoreAccordionStyle.defaultTriggerStyle.merge(
    merged.triggerStyle,
  );
  // `defaultTriggerStyle` always supplies padding so the merged slot's
  // `padding` is non-null.
  final triggerPadding = triggerStyle.padding!;
  // 1-off label↔chevron spacer — the dedicated `iconGapStyle` slot
  // (default supplies `size`, so non-null). Emitted inline as the flex
  // container `gap` (Web renders the gap as native CSS, not `Gap`).
  final triggerGap =
      (merged.iconGapStyle ?? CoreAccordionStyle.defaultIconGapStyle).size!;
  // Trigger background — override-only (no design-system default), so it
  // stays an emit-family decision only when present: a token colour lands
  // as a class, a raw one inline. Flutter paints the same value behind the
  // trigger row.
  final triggerBackgroundEmit = emitColorOrInherit(
    triggerStyle.backgroundColor,
    .background,
  );

  // Trigger label typography — design-system default role (`bodyMedium`,
  // medium weight, `onSurface`) with the optional `foregroundColor`
  // overriding the default colour, merged with the per-instance
  // `triggerStyle.labelStyle` overlay. `emitTypography` emits the role on
  // a `text-{role}` class (+ token colour class) and any explicit scalar
  // / raw-colour overlay inline. The label colour precedence is
  // `labelStyle.color → foregroundColor → default onSurface` (the
  // `foregroundColor` is folded into the fallback default's colour).
  // guard-nested-override: labelTextStyle — the override rides the nested
  // trigger label-style slot carried by the merged trigger style; this
  // default only feeds the emit-family fallback, so no flat label-text-style
  // field reference appears here.
  final labelDefault = CoreAccordionStyle.defaultLabelTextStyle.copyWith(
    color: triggerStyle.foregroundColor,
  );
  final labelEmit = emitTypography(triggerStyle.labelStyle, labelDefault);

  // Chevron icon style — design-system default size (`arrowIconStyle`
  // override → nested `chevronIconStyle.size` → default) packed into a
  // `CoreIconStyle` with the optional chevron colour. Forwarded to
  // `Icon(iconStyle: …)` by `co_accordion`.
  final arrowIconSize =
      merged.arrowIconStyle?.size ??
      merged.chevronIconStyle?.size ??
      CoreAccordionStyle.defaultChevronIconStyle.size!;
  final chevronIconStyle = CoreIconStyle(
    size: arrowIconSize,
    color: merged.chevronIconStyle?.color,
  );

  // Expand / collapse animation duration — caller override wins, else
  // the design-system default. Emitted inline as `transition-duration`
  // (no `duration-N` Tailwind class) so the override / default paths
  // share one signature.
  final durationMs =
      (merged.duration ?? CoreAccordionStyle.defaultDuration).inMilliseconds;

  // Expanded content padding — caller override wins, else the
  // design-system default (symmetric vertical). Emitted inline.
  final contentPadding =
      merged.contentPadding ?? CoreAccordionStyle.defaultContentPadding;

  // Expanded content typography — design-system default role
  // (`bodySmall`, `onSurface`) merged with the per-instance
  // `contentTextStyle` overlay. `emitTypography` emits the role class +
  // any explicit overlay inline.
  final contentEmit = emitTypography(
    merged.contentTextStyle,
    CoreAccordionStyle.defaultContentTextStyle,
  );

  // Chevron colour — override-only emit-family decision (no
  // design-system colour default; the chevron inherits the trigger
  // colour otherwise).
  final chevronColorEmit = merged.chevronIconStyle?.color == null
      ? null
      : emitColor(
          merged.chevronIconStyle!.color,
          merged.chevronIconStyle!.color!,
          .text,
        );

  // ─── Local builders — trigger row chrome ──────────────

  /// Composes the trigger row `<div>` Tailwind className — `flex` /
  /// `flex-1` / `items-center` / `justify-between`, plus the label
  /// typography role class ([labelEmit] — inherited by the title
  /// `<span>`), the trigger fill when it is a token
  /// ([triggerBackgroundEmit]) and `hover:underline`. Cursor / focus ring /
  /// press feedback are owned by the composing `Clickable` wrapper.
  String buildTriggerClassName() {
    final classList = [
      WebLayout.flex,
      WebLayout.flex1,
      WebLayout.itemsCenter,
      WebLayout.justifyBetween,
      labelEmit.className,
      triggerBackgroundEmit.className,
      'hover:underline',
    ];
    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the trigger row `<div>` inline CSS — the resolved padding
  /// shorthand + icon-to-label gap (always inline), the optional
  /// background colour override, plus the label typography overlay
  /// fragments (explicit scalar / raw-colour overlays only — token role
  /// / colour stay on classes).
  Styles buildTriggerInlineStyles() {
    return Styles(
      raw: {
        'padding': triggerPadding.toValue(),
        'gap': spaceCss(triggerGap),
        ...?triggerBackgroundEmit.inline,
        ...?labelEmit.inline,
      },
    );
  }

  // ─── Local builders — chevron icon chrome ─────────────

  /// Composes the chevron `<span>` wrapper Tailwind className —
  /// `flex items-center shrink-0 transition-transform`, appending
  /// `rotate-180` when the item is expanded plus the token-colour class
  /// (raw overrides go inline). Timing (duration + easing) is emitted
  /// inline — Tailwind's `transition-transform` utility carries its own
  /// baked-in `cubic-bezier(0.4,0,0.2,1)` default timing-function, not
  /// `CoreEasing.move`, so the inline write is what makes this
  /// reachable by a token-driven override.
  ///
  /// The wrapper is a flex box so it is exactly as tall as the icon. The
  /// icon is an inline box that sits on the text baseline; inside a plain
  /// span it lands on a line as tall as the trigger's label, off that
  /// line's centre, and `rotate-180` then turns it about the line's centre
  /// rather than its own — measured, the closed chevron sat 1.5px above
  /// the Flutter one and the open chevron 1.5px below. Flutter rotates the
  /// icon box itself, which the trigger row centres; so do Collapsible,
  /// Disclosure, Tree and NavigationMenu here.
  String buildChevronClassName() => [
    WebLayout.flexItemsCenter,
    '${WebLayout.shrinkZero} transition-transform',
    if (isExpanded) 'rotate-180',
    ?chevronColorEmit?.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the chevron `<span>` inline CSS — the resolved
  /// `transition-duration` / `transition-timing-function` (always inline,
  /// token-routed) plus the optional raw `color` override fragment from
  /// the merged `chevronIconStyle` (token colours stay on the class
  /// above).
  Styles buildChevronInlineStyles() => .new(
    raw: {
      'transition-duration': durationMsCss(durationMs),
      'transition-timing-function': CoreEasing.move.toVarCss(),
      ...?chevronColorEmit?.inline,
    },
  );

  // ─── Local builders — content wrapper chrome ──────────

  /// Composes the content collapse wrapper `<div>` Tailwind
  /// className — `overflow-hidden transition-all`. Timing is emitted
  /// inline (see [buildContentInlineStyles]) rather than a bare
  /// `ease-in-out` class — that Tailwind class rides Tailwind's own
  /// built-in curve, not `CoreEasing.move`.
  String buildContentClassName() =>
      '${WebLayout.overflowHidden} transition-all';

  /// Composes the content collapse wrapper `<div>` inline CSS —
  /// the `display:grid` + `grid-template-rows` animation between
  /// `0fr` (collapsed) and `1fr` (expanded), plus the resolved
  /// `transition-duration` / `transition-timing-function` (always
  /// inline, token-routed).
  Styles buildContentInlineStyles() => .new(
    raw: {
      'display': 'grid',
      'grid-template-rows': isExpanded ? '1fr' : '0fr',
      'transition-duration': durationMsCss(durationMs),
      'transition-timing-function': CoreEasing.move.toVarCss(),
    },
  );

  // ─── Local builders — content inner chrome ────────────

  /// Composes the content inner `<div>` Tailwind className — the
  /// `bodySmall` typography role class ([contentEmit] — inherited by the
  /// content). The content padding is emitted inline (when expanded).
  String buildContentInnerClassName() => contentEmit.className;

  /// Composes the content inner `<div>` inline CSS — `min-height:0`
  /// (required so the parent grid row can fully collapse to zero
  /// height), the resolved content padding (left / right / bottom, only
  /// when expanded so the collapsed row has no residual height), plus
  /// the merged content typography overlay fragments (explicit scalar /
  /// raw-colour overlays only — token role / colour stay on the class).
  Styles buildContentInnerInlineStyles() {
    final raw = {'min-height': '0'};
    if (isExpanded) {
      raw['padding-left'] = spaceCss(contentPadding.left);
      raw['padding-right'] = spaceCss(contentPadding.right);
      raw['padding-bottom'] = spaceCss(contentPadding.bottom);
    }
    raw.addAll({...?contentEmit.inline});
    return Styles(raw: raw);
  }

  return ResolvedAccordionItem(
    trigger: WebElementChrome(
      className: buildTriggerClassName(),
      inlineStyles: buildTriggerInlineStyles(),
    ),
    triggerTitle: const WebElementChrome(
      className: '${WebLayout.flex1} text-left',
    ),
    chevron: WebElementChrome(
      className: buildChevronClassName(),
      inlineStyles: buildChevronInlineStyles(),
    ),
    content: WebElementChrome(
      className: buildContentClassName(),
      inlineStyles: buildContentInlineStyles(),
    ),
    contentInner: WebElementChrome(
      className: buildContentInnerClassName(),
      inlineStyles: buildContentInnerInlineStyles(),
    ),
    chevronIconStyle: chevronIconStyle,
  );
}
