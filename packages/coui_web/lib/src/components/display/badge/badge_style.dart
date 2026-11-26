import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

/// The corner of the leading status dot — half its own side, so it is a
/// circle at whatever diameter it resolves to. Not a design token: it is
/// the geometry of a circle, the Web spelling of the Flutter twin's
/// `BoxShape.circle`, and it stays a circle under any radius preset.
const String _kCircleRadiusCss = '50%';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Badge`.
///
/// DOM shape (`badge.dart` decides which optional branches render):
///
/// ```text
/// root (<span>)
///   ├─ <style>                       // scoped state-layer / focus-ring rules, interactive only
///   ├─ leadingDot (<span>)           // showDot, label / count forms only
///   ├─ Gap (iconLabelGapStyle)       // after the leading dot
///   ├─ IconTheme (iconStyle)         // no DOM of its own
///   │    └─ adornment (<span>)       // label form only
///   │         └─ leading            // caller-supplied Component, optional
///   ├─ Gap (iconLabelGapStyle)       // after leading
///   ├─ label/count (<span>)         // wrapping label or single-line count
///   │    └─ child
///   ├─ Gap (iconLabelGapStyle)       // before trailing
///   └─ IconTheme (iconStyle)
///        └─ adornment (<span>)       // label form only
///             └─ trailing           // caller-supplied Component, optional
/// ```
///
/// The dot form ([CoreBadgeForm.dot]) renders the root alone — no content
/// row at all, so the box is the step's diameter rather than its padding.
///
/// `badge.dart` reads each slot's `className` + `inlineStyles` straight
/// from `resolved.<slot>` — no merge / fallback / conversion in the widget
/// body. The gap between the row's parts is an explicit `Gap` driven by
/// [iconLabelGapStyle], matching the Flutter widget (each `Gap` runs its
/// own resolve step).
class ResolvedBadge implements WebResolvedChrome {
  /// Creates a [ResolvedBadge].
  const ResolvedBadge({
    required this.root,
    required this.leadingDot,
    required this.label,
    required this.count,
    required this.adornment,
    required this.iconLabelGapStyle,
    required this.iconStyle,
  });

  /// Paint-ready chrome for the outermost `<span>` element.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the leading status dot — a circle in the
  /// badge's foreground colour. Rendered by the widget only when `showDot`
  /// is on and the form is not [CoreBadgeForm.dot].
  final WebElementChrome leadingDot;

  /// Bounded, wrapping label content.
  final WebElementChrome label;

  /// Single-line, shrinkable count content with its full text in the DOM.
  final WebElementChrome count;

  /// Fixed-size layout slot around optional label icons.
  final WebElementChrome adornment;

  /// Nested [CoreGapStyle] slot — forwarded straight to `Gap(gapStyle: …)`
  /// between the parts of the content row. The design-system default
  /// merged with the per-instance override, in pre-scaling units.
  final CoreGapStyle iconLabelGapStyle;

  /// Nested [CoreIconStyle] slot — the step's icon size with the
  /// per-instance override over it, handed to the leading and trailing
  /// slots as the ambient `IconTheme`, the same way the Flutter twin wraps
  /// them in `IconTheme(size, color)`. A `null` colour leaves the glyphs on
  /// `currentColor`, which is the badge's foreground — the colour the
  /// Flutter twin falls back to.
  final CoreIconStyle iconStyle;
}

/// Scoped CSS text for `<style>` block in `Badge`.
///
/// Empty for a badge that is not pressable. A pressable badge always
/// carries the state layer — its foreground washed over its fill on
/// `:hover`, `:active` and the keyboard press — because the wash is a
/// `color-mix()` of two resolved colours and has no utility-class form.
/// The focus ring joins it only when it has no class form either (a raw
/// override colour, a sub-1 `ringOpacity`, an off-scale width / offset, or
/// a painted gap band — see `focusRingIsClassSafe`); `resolveBadge` drops
/// the `focus-visible:outline-*` classes in that same condition (class XOR
/// rule).
class ResolvedBadgeRules {
  /// Creates a [ResolvedBadgeRules].
  const ResolvedBadgeRules({required this.css});

  /// Raw CSS rule text — empty for a badge that is not pressable.
  final String css;
}

/// The merged override chain and the design-system rows it falls back to,
/// for one badge.
///
/// - `merged` — theme style → theme tone row → theme variant row → the
///   instance's `badgeStyle`, on an empty base.
/// - `chrome` — the step's row ([CoreBadgeStyle.defaultsBySize]), what
///   the form changes on top of it
///   ([CoreBadgeStyle.defaultsByForm]) and the tone's resting colours at
///   this strength ([CoreBadgeToneStyle.restingStyleFor]).
///
/// Shared by [resolveBadge] and [resolveBadgeRules] so the chrome and the
/// scoped rules always read the same resolved values.
typedef _BadgeLayers = ({CoreBadgeStyle merged, CoreBadgeStyle chrome});

_BadgeLayers _resolveBadgeLayers(
  BuildContext context, {
  required CoreBadgeTone tone,
  required CoreBadgeVariant variant,
  required CoreBadgeForm form,
  required CoreComponentSize size,
  CoreBadgeStyle? badgeStyle,
}) {
  final badgeTheme = context.theme.coreComponentTheme?.badge;
  final merged = resolveStyleChain(const CoreBadgeStyle(), [
    badgeTheme?.style,
    badgeTheme?.toneStyles?[tone],
    badgeTheme?.variantStyles?[variant],
    badgeStyle,
  ]);
  final sizeRow = CoreBadgeStyle.defaultsBySize[size]!;
  final chrome = sizeRow
      .merge(CoreBadgeStyle.defaultsByForm[form])
      .merge(
        CoreBadgeStyle.defaultsByTone[tone]!.restingStyleFor(variant, form),
      );
  return (merged: merged, chrome: chrome);
}

/// Resolves the badge focus-ring values shared by [resolveBadge] (which
/// decides whether the `focus-visible:outline-*` classes emit) and
/// [resolveBadgeRules] (which emits the scoped fallback) — a single
/// source so the class-drop condition and the scoped rule always agree.
typedef _BadgeFocusRing = ({
  double width,
  double offset,
  CoreColor color,
  CoreColor offsetColor,
  double opacity,
  bool classSafe,
});

_BadgeFocusRing _resolveBadgeFocusRing(CoreFocusOutlineStyle? override) {
  // Focus-ring field overrides ride the nested focus-outline slot (the
  // `override` arg = merged.focusOutlineStyle), base-then-merged below — not
  // a flat merged.<field>. The ring is an outline on the badge's own box, so
  // it follows the badge's corner without being told it.
  // guard-nested-override: ringOpacity
  final slot = CoreBadgeStyle.defaultFocusOutlineStyle.merge(override);
  final width = slot.borderWidth!;
  final offset = slot.align! - width;
  final color = slot.borderColor!;
  final offsetColor = slot.offsetColor!;
  final opacity = slot.ringOpacity ?? CoreFocusOutlineStyle.defaultRingOpacity;
  return (
    width: width,
    offset: offset,
    color: color,
    offsetColor: offsetColor,
    opacity: opacity,
    classSafe: focusRingIsClassSafe(
      ringColor: color,
      offsetColor: offsetColor,
      ringOpacity: opacity,
      ringWidth: width,
      ringOffset: offset,
    ),
  );
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedBadge] for the given [context].
///
/// Merge chain:
///
/// ```text
/// defaultsBySize[size] → defaultsByForm[form] → defaultsByTone[tone] × variant
///   → theme.coreComponentTheme.badge.style
///   → theme.coreComponentTheme.badge.toneStyles[tone]
///   → theme.coreComponentTheme.badge.variantStyles[variant]
///   → widget.badgeStyle
/// ```
///
/// The semantic [tone], [variant], [form] and [size] are widget props —
/// they pick the rows of the Core tables here. The theme cannot override
/// them (semantic identifiers are widget-only).
ResolvedBadge resolveBadge(
  BuildContext context, {
  required CoreBadgeTone tone,
  required CoreBadgeVariant variant,
  required CoreBadgeForm form,
  required CoreComponentSize size,
  required bool interactive,
  CoreBadgeStyle? badgeStyle,
}) {
  final layers = _resolveBadgeLayers(
    context,
    tone: tone,
    variant: variant,
    form: form,
    size: size,
    badgeStyle: badgeStyle,
  );
  final merged = layers.merged;
  final chrome = layers.chrome;

  final isDot = form == CoreBadgeForm.dot;
  final isCount = form == CoreBadgeForm.count;

  // ─── Stage 1 — RESOLVE ────────────────────────────────
  // The fill every form paints: a dot paints its tone's dot colour here.
  final backgroundColor = merged.backgroundColor ?? chrome.backgroundColor!;
  // `null` only for a dot whose style states no foreground — a dot has no
  // content to colour.
  final foregroundColor = merged.foregroundColor ?? chrome.foregroundColor;
  // Stated by the tone row for `outlined` only; with no colour no border is
  // drawn, at any width.
  final borderColor = merged.borderColor ?? chrome.borderColor;
  final borderWidth = merged.borderWidth ?? CoreBadgeStyle.defaultBorderWidth;
  // The form's corner — the step's for a word, the pill for a number and a
  // dot. Always inline, so default and override share one CSS surface.
  final borderRadius = (merged.borderRadius ?? chrome.borderRadius!).toValue();
  final padding = merged.padding ?? chrome.padding!;
  final minHeight = merged.minHeight ?? chrome.minHeight!;
  final dotSize = merged.dotSize ?? chrome.dotSize!;
  final leadingDotSize = merged.leadingDotSize ?? chrome.leadingDotSize!;
  // Nested `CoreIconStyle` slot — the step's size with the per-instance
  // override over it (size and colour), forwarded to the slots' ambient
  // `IconTheme`. `Icon` emits it: the exact size inline, a token colour as
  // a class and a raw one inline.
  final iconStyle = chrome.iconStyle!.merge(merged.iconStyle);
  // Nested `CoreGapStyle` slot — the step's default merged with the
  // per-instance override, forwarded straight to `Gap(gapStyle: …)` (each
  // `Gap` runs its own resolve step, matching Flutter).
  final iconLabelGapStyle = chrome.iconLabelGapStyle!.merge(
    merged.iconLabelGapStyle,
  );
  // The chrome transition, on every badge: the Flutter twin's box is an
  // `AnimatedContainer`, which animates any change to its fill or line —
  // a hover, and equally a tone swapped at runtime on a badge nobody can
  // press. Duration and curve go inline: the duration through
  // `durationMsCss` (a step's `--coui-duration-*` variable, which the
  // reduced-motion rule zeroes, or an off-scale value routed through the
  // shared reduced-motion factor), the curve as the `move` alias the
  // Flutter twin names, rather than the utility's own default curve.
  final transitionDurationCss = durationMsCss(
    (merged.transitionDuration ?? CoreBadgeStyle.defaultTransitionDuration)
        .inMilliseconds,
  );
  final transitionEasingCss = CoreEasing.move.toVarCss();
  // Whether this badge paints a fill at rest. The surface material is a
  // statement about a filled box, so a badge whose resting fill is
  // transparent (`outlined`, the fill token at opacity 0) carries no marker:
  // handed the material it frosts a backdrop behind nothing, draws an edge
  // band around a box that is not there, and loses the stroke that is its
  // only edge. The Flutter twin withholds the material on the same answer.
  final hasFill = surfacePaintsFill(backgroundColor);

  // ─── Stage 2 — EMIT (Web, theme-free) ─────────────────
  // Every colour / typography value routes through the emit family — one
  // class-XOR-inline decision per design value. Token-bound values emit
  // Tailwind classes (dark-mode reactive); raw overrides go inline.
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    backgroundColor,
    .background,
  );
  final foregroundEmit = emitColorOrInherit(foregroundColor, .text);
  final borderEmit = emitColorOrInherit(borderColor, .border);
  // The leading dot wears the label's colour, so it reads as part of the
  // label — unless the style states a colour of its own for it (the
  // `outlined` status tones do, the line's colour).
  final leadingDotColor =
      merged.leadingDotColor ?? chrome.leadingDotColor ?? foregroundColor;
  final leadingDotEmit = emitColorOrInherit(leadingDotColor, .background);
  // The step's role with the form's weight laid over it (600 for a word,
  // 700 for a number) — a `text-{role}` class plus the weight inline.
  final labelEmit = emitTypography(merged.labelStyle, chrome.labelStyle!);

  // Focus-ring slot — design-system default merged with the per-instance
  // `focusOutlineStyle` override. When the resolved ring has a class form
  // (`ring.classSafe`) it rides `focus-visible:outline-*` utility classes
  // below; otherwise it paints via the scoped `#scopeId:focus-visible` rule
  // from `resolveBadgeRules`.
  final ring = _resolveBadgeFocusRing(merged.focusOutlineStyle);

  // ─── Local builders ───────────────────────────────────

  /// Composes the root `<span>` Tailwind className.
  ///
  /// Dimensions ride the size scale (`--coui-size-*`) while they are the
  /// step's own value: the minimum height of a word and a number (and the
  /// minimum width of a number), the side of a dot. An override goes inline
  /// instead (class XOR inline per property). These are the badge's own
  /// rows, not control rows, so no density moves them — the Flutter twin
  /// does not move them either.
  String buildRootClassName() {
    // Focus ring — an outline under the `focus-visible:` pseudo-state
    // (inline CSS cannot express pseudo-state). Keyboard focus only, as the
    // Flutter twin's ring follows `Clickable`'s focus *highlight*: a pointer
    // press focuses the badge without showing a ring on either platform.
    // `outline-none` is the ring's resting state (`2px solid transparent`,
    // offset 2), so focusing only moves the colour. On the class-safe path
    // width / offset / colour ride `focus-visible:outline-*` utilities;
    // otherwise the classes drop and the ring paints via the scoped
    // `#scopeId:focus-visible` rule instead.
    final focusRingClasses = interactive
        ? [
            'outline-none',
            if (ring.classSafe)
              focusRingClassName(
                pseudo: .focusVisible,
                ringColor: ring.color,
                ringWidth: ring.width,
                ringOffset: ring.offset,
              ),
          ].join(' ')
        : '';

    final classList = [
      '${WebLayout.inlineFlexCenterNoWrap} select-none',
      if (!isDot) 'box-border max-w-full',
      // States no shadow of its own, so it takes the style's — the Flutter
      // twin reads the same cast into its own `BoxDecoration`. No-op under
      // every style that injects none.
      kControlShadowRestMarker,
      // Marks this element as a component surface — restated here because
      // Badge can't compose `OutlinedContainer` (its Web root is a fixed
      // `<span>`; wrapping it in a `<div>` breaks the inline flow a badge
      // sits in). Only on a badge that paints a fill at rest ([hasFill]).
      if (hasFill) ...webSurfaceMarkerFor(.content),
      if (!isDot) labelEmit.className,
      if (!isDot && merged.minHeight == null) 'min-h-${minHeight.tailwindSize}',
      if (isCount && merged.minHeight == null)
        'min-w-${minHeight.tailwindSize}',
      if (isDot && merged.dotSize == null) ...[
        'w-${dotSize.tailwindSize}',
        'h-${dotSize.tailwindSize}',
      ],
      backgroundEmit.className,
      foregroundEmit.className,
      borderEmit.className,
      // The properties that move; the clock rides inline (see
      // `buildRootInlineStyles`).
      'transition-colors',
      if (interactive) 'cursor-pointer',
      focusRingClasses,
    ];

    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the root `<span>` inline-CSS bundle.
  ///
  /// Emits padding (label / count only), border-radius and the transition
  /// clock always, the border width when a border colour resolved, any
  /// dimension the caller overrode, and the inline colour / typography
  /// fragments the emit family produced (raw overrides only — token values
  /// stay on classes).
  Styles? buildRootInlineStyles() {
    final minHeightRem = '${minHeight / kRemDivisor}rem';
    final dotSizeRem = '${dotSize / kRemDivisor}rem';
    final raw = {
      // A dot pads nothing and takes its box from the step instead —
      // padding would make the box the padding's size, which is the one
      // thing the dot form exists to state. Horizontal only by default: the
      // height is the step's.
      if (!isDot) ...padding.toLogicalDeclarations('padding'),
      if (!isDot && merged.minHeight != null) 'min-height': minHeightRem,
      if (isCount && merged.minHeight != null) 'min-width': minHeightRem,
      if (isDot && merged.dotSize != null) ...{
        'width': dotSizeRem,
        'height': dotSizeRem,
      },
      'border-radius': borderRadius,
      // Only where a border colour resolved — a width with no colour would
      // paint the preflight's default border colour, which the Flutter twin
      // (no colour → no border) never draws.
      if (borderColor != null) 'border-width': strokeWidthCss(borderWidth),
      'transition-duration': transitionDurationCss,
      'transition-timing-function': transitionEasingCss,
      ...?backgroundEmit.inline,
      ...?foregroundEmit.inline,
      ...?borderEmit.inline,
      if (!isDot) ...?labelEmit.inline,
      // The marker's other half — a preset restates this fill at a lower
      // alpha and cannot know which token the badge chose. Empty (and a
      // no-op) when the fill is not token-bound, and withheld with the
      // marker when the badge paints no fill.
      if (hasFill) ...surfaceFillVar(backgroundColor),
    };

    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the leading status dot's Tailwind className — a fixed side
  /// on the size scale while it is the step's own value, filled with the
  /// foreground colour class (empty for a raw colour, which goes inline).
  String buildLeadingDotClassName() {
    final classList = [
      WebLayout.inlineBlock,
      WebLayout.shrinkZero,
      if (merged.leadingDotSize == null) ...[
        'w-${leadingDotSize.tailwindSize}',
        'h-${leadingDotSize.tailwindSize}',
      ],
      leadingDotEmit.className,
    ];
    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the leading status dot's inline-CSS bundle — the circle, an
  /// overridden side, and a raw foreground colour.
  Styles buildLeadingDotInlineStyles() {
    final leadingDotRem = '${leadingDotSize / kRemDivisor}rem';
    return Styles(
      raw: {
        if (merged.leadingDotSize != null) ...{
          'width': leadingDotRem,
          'height': leadingDotRem,
        },
        'border-radius': _kCircleRadiusCss,
        ...?leadingDotEmit.inline,
      },
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedBadge(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    leadingDot: WebElementChrome(
      className: buildLeadingDotClassName(),
      inlineStyles: buildLeadingDotInlineStyles(),
    ),
    label: const WebElementChrome(
      className: 'min-w-0 whitespace-normal [overflow-wrap:anywhere]',
    ),
    count: const WebElementChrome(
      className: 'min-w-0 overflow-hidden text-ellipsis whitespace-nowrap',
    ),
    adornment: const WebElementChrome(className: 'inline-flex shrink-0'),
    iconLabelGapStyle: iconLabelGapStyle,
    iconStyle: iconStyle,
  );
}

/// Resolves the scoped `<style>` rules for a pressable `Badge`.
///
/// Empty when not [interactive] — a badge that cannot be pressed has no
/// states and paints no wash.
///
/// - **State layer** — the badge's foreground laid over its fill at the
///   [CoreBadgeStyle.stateLayer] weight: `hover` while hovered, `pressed`
///   while held (`:active`, or the keyboard press marker
///   [kClickableKeyPressedMarker] `badge.dart` sets while Enter / Space is
///   down — written after `:hover` so they win on the tie). No focus wash —
///   focus draws the ring, and a wash on top of it would make a focused
///   badge read as a hovered one. A `color-mix()` of the two resolved
///   colours (`stateLayerWashCss`), so tokens stay tokens and the browser
///   composites them at paint time, the way the Flutter twin blends them
///   with `Color.alphaBlend`. Omitted for a dot whose style states no
///   foreground — there is no ink to wash with.
///
///   How the wash reaches the box depends on where the resting fill lives:
///   - a token fill on a marked surface ([surfacePaintsFill]) is restated
///     by a style preset's material rule at the material's share. The
///     state rule sits below that rule — `:where(#id)` drops the id's
///     weight, the surface class keeps it above the fill utility — and
///     publishes the wash through the same custom properties the resting
///     fill does (`stateLayerWashFillVar`), so under a translucent preset
///     the washed fill stays translucent, folded the way the Flutter twin
///     folds `materialFill(washed)`. Without a material it paints the wash
///     itself.
///   - any other fill — unfilled (no marker, so no material), or a raw
///     override (inline, which outranks every selector) — is washed by an
///     `#id` rule marked `!important`.
/// - **Focus ring** — only when the resolved ring has no class form (raw
///   override colour, sub-1 `ringOpacity`, off-scale width / offset, or a
///   painted gap band). A painted band composes over the badge's resting
///   cast (`var(--coui-control-shadow)`, the [kControlShadowRestMarker]
///   value) so stating a band does not erase it.
///
/// The merge chain is the one [resolveBadge] walks (`_resolveBadgeLayers`),
/// so the classes there and the rules here always see the same values.
ResolvedBadgeRules resolveBadgeRules(
  BuildContext context, {
  required String scopeId,
  required CoreBadgeTone tone,
  required CoreBadgeVariant variant,
  required CoreBadgeForm form,
  required CoreComponentSize size,
  required bool interactive,
  CoreBadgeStyle? badgeStyle,
}) {
  if (!interactive) return const ResolvedBadgeRules(css: '');

  final layers = _resolveBadgeLayers(
    context,
    tone: tone,
    variant: variant,
    form: form,
    size: size,
    badgeStyle: badgeStyle,
  );
  final merged = layers.merged;
  final chrome = layers.chrome;

  // ─── Stage 1 — RESOLVE ────────────────────────────────
  // Same fill and ink `resolveBadge` paints — the wash composites over
  // whatever the badge actually wears.
  final backgroundColor = merged.backgroundColor ?? chrome.backgroundColor!;
  final foregroundColor = merged.foregroundColor ?? chrome.foregroundColor;
  final stateLayer = merged.stateLayer ?? CoreBadgeStyle.defaultStateLayer;
  final ring = _resolveBadgeFocusRing(merged.focusOutlineStyle);

  // ─── Stage 2 — EMIT — scoped rules ────────────────────
  final selector = '#$scopeId';
  final buffer = StringBuffer();
  if (foregroundColor != null) {
    // A token fill on a marked surface — the fill a preset's material rule
    // restates from the surface vars. The wash follows it there; any other
    // fill is washed directly (see the doc above).
    final publishesFill =
        surfacePaintsFill(backgroundColor) && backgroundColor.token != null;
    final scope = publishesFill
        ? ':where($selector).$kWebSurfaceMarker'
        : selector;

    /// The declarations that paint the wash at [weight].
    String washAt(double weight) {
      final wash = stateLayerWashCss(
        ink: foregroundColor,
        base: backgroundColor,
        weight: weight,
      );
      if (!publishesFill) return 'background-color:$wash !important;';
      final declarations = StringBuffer('background-color:$wash;');
      // `!important` on the properties alone: their resting values ride the
      // inline style, which outranks every selector that is not.
      stateLayerWashFillVar(
        ink: foregroundColor,
        base: backgroundColor,
        weight: weight,
      ).forEach(
        (property, value) => declarations.write('$property:$value !important;'),
      );
      return declarations.toString();
    }

    buffer
      ..write('$scope:hover{${washAt(stateLayer.hover)}}')
      ..write(
        '$scope:active,$scope.$kClickableKeyPressedMarker'
        '{${washAt(stateLayer.pressed)}}',
      );
  }
  if (!ring.classSafe) {
    buffer.write(
      focusRingScopedRule(
        scopeSelector: selector,
        pseudo: .focusVisible,
        ringColor: ring.color,
        offsetColor: ring.offsetColor,
        ringWidth: ring.width,
        ringOffset: ring.offset,
        ringOpacity: ring.opacity,
        restShadow: kControlShadowVar,
      ),
    );
  }

  return ResolvedBadgeRules(css: buffer.toString());
}
