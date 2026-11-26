import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `ChipInput`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="group">)                    // outer wrapper, flex-wrap
///   ├─ <style>                                 // only when the ring needs a scoped rule
///   ├─ Chip (filled · low · sm)                // repeated per chip
///   │    ├─ label
///   │    └─ Button.ghost (closeButtonStyle)    // only when enabled
///   │         └─ Icon(closeIconStyle)
///   └─ field (<input>)                         // co_chip_input renders only when _canAddMore
/// ```
///
/// `co_chip_input.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion
/// in the widget body.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots passed to child unified
///   widgets. `chipCloseIconStyle` is forwarded to `Icon(iconStyle:
///   …)` for every chip's remove button.
///
/// No scalar metadata (icon size / etc.) is exposed — semantic
/// identifiers stay on the widget prop and dimensional values are
/// folded into the appropriate Tailwind class or inline-CSS slot.
class ResolvedChipInput implements WebResolvedChrome {
  /// Creates a [ResolvedChipInput].
  const ResolvedChipInput({
    required this.root,
    required this.chipStyle,
    required this.field,
    required this.fieldStyle,
  });

  /// Paint-ready chrome for the outermost `<div role="group">` wrapper.
  /// Composed `flex w-full flex-wrap … focus-within:*` className plus
  /// the per-instance dimensional + colour inline-CSS bundle. The
  /// disabled-state class (`cursor-not-allowed`) travels
  /// with the root chrome because the resolver closed over `enabled`
  /// at build time.
  @override
  final WebElementChrome root;

  /// Nested [CoreChipStyle] slot for the composed `Chip` badges —
  /// `CoreChipInputStyle.defaultChipStyle` (compact pill divergences)
  /// merged with the per-instance override, raw-forwarded to
  /// `Chip(chipStyle:)`; the Chip's own resolver fills the rest.
  final CoreChipStyle chipStyle;

  /// Paint-ready chrome for the inline text-entry `<input>` — `co_chip_input`
  /// renders this element only when `_canAddMore`.
  final WebElementChrome field;

  /// Nested [CoreTextFieldStyle] slot for the composed chromeless
  /// `TextField` — `CoreChipInputStyle.chromelessFieldStyle` (suppresses
  /// the field's own chrome / focus ring) with the per-instance
  /// `inputTextStyle` override folded into `valueStyle` so the typed
  /// text honours it (mirrors the Flutter twin's
  /// `defaultInputTextStyle.merge(merged.inputTextStyle)`).
  final CoreTextFieldStyle fieldStyle;
}

/// Scoped CSS text for `<style>` block in `ChipInput`.
///
/// Non-empty only when the frame leaves a Tailwind class scale:
/// * the focus ring — a raw (token-less) ring colour, a sub-1
///   `ringOpacity`, an off-scale width / offset, or a painted gap band (a
///   `box-shadow` layer no class draws). `resolveChipInput` drops the three
///   `focus-within:outline-*` utility classes and the frame carries its
///   scope id instead (class XOR rule):
///   `#co-chip-input-<id>:focus-within{outline-…}`.
/// * the hover border — a raw `hoverBorderColor`, or a raw resting
///   `borderColor` (inline, so no class can step it):
///   `#co-chip-input-<id>:not(:focus-within):hover{border-color: …}`.
class ResolvedChipInputRules {
  /// Creates a [ResolvedChipInputRules].
  const ResolvedChipInputRules({required this.css});

  /// Raw CSS rule text — empty on the default path (pure utility classes).
  final String css;
}

/// The frame focus-ring values a `ChipInput` resolved from its nested
/// `focusOutlineStyle` slot — shared by [resolveChipInput] (which decides
/// whether the ring rides utility classes) and [resolveChipInputRules]
/// (which writes the fallback rule), so the two can never disagree about
/// what the ring is.
typedef _ChipInputRing = ({
  CoreColor color,
  CoreColor offsetColor,
  double width,
  double offset,
  double opacity,
  bool classSafe,
});

/// Resolves the frame focus ring from the merged style's nested
/// `focusOutlineStyle` slot.
///
/// Web has no `FocusOutline` widget twin here — `ChipInput` is stateless
/// and the ring keys off `:focus-within`, which is the browser's own
/// focus engine — so the shared slot resolves in this file. `align` is
/// the child-edge → ring-outer-edge distance (offset + width), mirroring
/// Flutter, so the Tailwind `outline-offset-<n>` step is derived from it.
///
/// Every ring field's override arrives through the nested
/// `merged.focusOutlineStyle` slot rather than a flat `merged.<field>`.
/// The three markers below cover the three fields ChipInput has no
/// same-named flat field for — each is load-bearing, and deleting any one
/// of them turns `check_web_resolver.sh` RULE D red. `borderColor` /
/// `borderWidth` get no marker because this file already reads
/// `merged.borderColor` / `merged.borderWidth` for the frame's own
/// stroke, which satisfies that guard on its own; a marker there would
/// never be consulted, and a marker that is never consulted is a dead
/// marker.
// guard-nested-override: align
// guard-nested-override: offsetColor
// guard-nested-override: ringOpacity
_ChipInputRing _resolveRing(CoreChipInputStyle merged) {
  final slot = merged.focusOutlineStyle;
  final width = slot?.borderWidth ?? CoreFocusOutlineStyle.defaultBorderWidth;
  final offset = (slot?.align ?? CoreFocusOutlineStyle.defaultAlign) - width;
  final color = slot?.borderColor ?? CoreFocusOutlineStyle.defaultBorderColor;
  final offsetColor =
      slot?.offsetColor ?? CoreFocusOutlineStyle.defaultOffsetColor;
  final opacity = slot?.ringOpacity ?? CoreFocusOutlineStyle.defaultRingOpacity;
  return (
    color: color,
    offsetColor: offsetColor,
    width: width,
    offset: offset,
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

/// The class-path hover fragment never reads the scope selector — only the
/// rule text does — so [resolveChipInput], which has no scope id, passes
/// this in its place.
const String _kClassPathScope = '';

/// Where the frame's hover border rides: a pseudo class when every colour
/// involved is a token, a scoped rule when one is not.
///
/// Precedence is `disabled > focus > hover > rest`:
/// * **disabled** — no hover step at all (`enabled == false` → empty).
/// * **focus** — the frame's focus indicator is the ring, which only reads
///   as a state change if the border under it stays at rest. Tailwind
///   orders `hover:` AFTER `focus-within:`, so a plain `hover:border-X`
///   would win over a focused frame at equal specificity. The class path
///   therefore restates the resting border under `focus-within:hover:`
///   (three pseudo-classes outrank the single `hover:`), and the rule path
///   scopes to `:not(:focus-within)`.
/// * **hover** — `hoverBorderColor` (token → class, raw → scoped rule).
///
/// A raw resting border is emitted inline, which outranks every class and
/// every selector; the hover step then needs `!important` or it would
/// never show. A token rest border is a class and loses to both paths.
PseudoEmit _resolveHoverBorder(
  CoreChipInputStyle merged, {
  required bool enabled,
  required String scopeSelector,
}) {
  if (!enabled) return (className: '', rule: '');
  final hover =
      merged.hoverBorderColor ?? CoreChipInputStyle.defaultHoverBorderColor;
  final rest = merged.borderColor ?? CoreChipInputStyle.defaultBorderColor;
  final unfocused = '$scopeSelector:not(:focus-within)';
  if (rest.token == null) {
    return (
      className: '',
      rule:
          '${WebPseudo.hover.selector(unfocused)}'
          '{border-color: ${hover.toValue()} !important;}',
    );
  }
  final hoverEmit = emitPseudoColor(
    hover,
    hover,
    .border,
    pseudo: .hover,
    scopeSelector: unfocused,
  );
  if (hoverEmit.rule.isNotEmpty) return hoverEmit;
  final restUnderHover = emitPseudoColor(
    rest,
    rest,
    .border,
    pseudo: .hover,
    scopeSelector: unfocused,
  );
  return (
    className:
        '${hoverEmit.className} '
        'focus-within:${restUnderHover.className}',
    rule: '',
  );
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedChipInput] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.chipInput.style
///   → widget.chipInputStyle
/// ```
ResolvedChipInput resolveChipInput(
  BuildContext context, {
  required bool enabled,
  CoreChipInputStyle? chipInputStyle,
}) {
  final chipInputTheme = context.theme.coreComponentTheme?.chipInput;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreChipInputStyle(), [
    chipInputTheme?.style,
    chipInputStyle,
  ]);

  // ─── Stage 1 RESOLVE — Core values (Flutter ≡ Web) ────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  final ring = _resolveRing(merged);
  final borderWidth =
      merged.borderWidth ?? CoreChipInputStyle.defaultBorderWidth;
  final borderRadius =
      merged.borderRadius ?? CoreChipInputStyle.defaultBorderRadius;
  // The frame's floor is a row of the control ladder (the md rung, the row
  // of the text field beside it): unstated, it goes out as the row variable
  // so a density moves it, as on Flutter. A caller's own minimum is a
  // statement and stays as stated.
  final minHeight = merged.minHeight == null
      ? controlHeightCss(CoreChipInputStyle.defaultMinHeight)
      : '${merged.minHeight! / kRemDivisor}rem';
  final padding = merged.padding ?? CoreChipInputStyle.defaultPadding;
  final inputPadding =
      merged.inputPadding ?? CoreChipInputStyle.defaultInputPadding;
  final chipSpacing =
      merged.chipSpacing ?? CoreChipInputStyle.defaultChipSpacing;
  // Chained (compact-pill default ⊕ per-instance override), then
  // raw-forwarded to the composed `Chip`, whose own resolver runs its
  // merge chain / token EMIT on top.
  final chipStyle = CoreChipInputStyle.defaultChipStyle.merge(
    merged.chipStyle,
  );
  // Nested chromeless-TextField slot — `defaultInputTextStyle` merged
  // with the per-instance override folds into `valueStyle` (mirrors
  // Flutter's `defaultInputTextStyle.merge(merged.inputTextStyle)`
  // exactly, rather than relying on `TextField`'s own unrelated
  // default role/colour) so the typed text honours it.
  final fieldStyle = CoreChipInputStyle.chromelessFieldStyle.copyWith(
    valueStyle: CoreChipInputStyle.defaultInputTextStyle.merge(
      merged.inputTextStyle,
    ),
  );

  // ─── Stage 2 EMIT (Web, theme-free) ───────────────────
  // Colours route through the emit family (class-XOR-inline per design
  // value); no `scheme.resolve` (a no-op on Web). Typography routes
  // through `emitTypography` so the role class + any explicit scalar
  // overlay emit together — never a hand-rolled `text-${role}`.
  // A disabled frame states its own tokens (fill + edge) rather than an
  // opacity wash over the enabled ones; the Flutter twin selects the same
  // two. The resolver closes over `enabled`, so the pick is made here.
  final backgroundEmit = enabled
      ? emitColor(
          merged.backgroundColor,
          CoreChipInputStyle.defaultBackgroundColor,
          .background,
        )
      : emitColor(
          merged.disabledBackgroundColor,
          CoreChipInputStyle.defaultDisabledBackgroundColor,
          .background,
        );
  // surface:content — the frame draws its own box on the root
  // `<div role="group">` rather than composing `OutlinedContainer` (the
  // inline entry field is deliberately chromeless so the root owns the
  // single visible boundary). The design default always states a solid
  // `surface` token, so the pair applies unconditionally unless the
  // caller explicitly opted out with a raw transparent override — same
  // gate every other content-role surface on this axis uses.
  final containerFillCore = enabled
      ? merged.backgroundColor ?? CoreChipInputStyle.defaultBackgroundColor
      : merged.disabledBackgroundColor ??
            CoreChipInputStyle.defaultDisabledBackgroundColor;
  final borderEmit = enabled
      ? emitColor(
          merged.borderColor,
          CoreChipInputStyle.defaultBorderColor,
          .border,
        )
      : emitColor(
          merged.disabledBorderColor,
          CoreChipInputStyle.defaultDisabledBorderColor,
          .border,
        );
  final hoverBorderEmit = _resolveHoverBorder(
    merged,
    enabled: enabled,
    scopeSelector: _kClassPathScope,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer chip-input container `<div role="group">`
  /// Tailwind className. The border / fill colour classes (token values
  /// only — raw overrides emit inline) read the emit-family results. The
  /// disabled-state class (`cursor-not-allowed`) travels with
  /// the root chrome because the resolver receives `enabled`.
  ///
  /// The three `focus-within:outline-*` classes ride only the class-safe
  /// path ([_ChipInputRing.classSafe]), and the width / offset steps are
  /// the *resolved* values — a literal `outline-2` here would silently
  /// render the design-system 2 for every on-scale override. A ring that
  /// has no class (raw colour, sub-1 opacity, off-scale geometry, a
  /// painted band) drops all three; `resolveChipInputRules` then paints
  /// it through a scoped `#<id>:focus-within{outline-…}` rule and the
  /// widget stamps that id on this element (class XOR rule).
  /// `outline-none` stays in both cases.
  String buildRootClassName() => <String>[
    // States no shadow of its own, so it takes the style's — the
    // Flutter twin reads the same cast.
    kControlShadowRestMarker,
    WebLayout.flex,
    WebLayout.wFull,
    WebLayout.flexWrap,
    WebLayout.itemsCenter,
    'border',
    // `outline-none` unconditionally (not `focus-within:`) so the
    // transparent outline is the resting state — flipping outline-style
    // only on focus transitions outline-color from currentColor to
    // transparent, flashing a text-coloured border on every focus.
    'outline-none',
    if (ring.classSafe)
      focusRingClassName(
        pseudo: .focusWithin,
        ringColor: ring.color,
        ringWidth: ring.width,
        ringOffset: ring.offset,
      ),
    backgroundEmit.className,
    borderEmit.className,
    hoverBorderEmit.className,
    if (!enabled) 'cursor-not-allowed',
    if (!containerFillCore.isTransparent) ...webSurfaceMarkerFor(.content),
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the outer chip-input container inline-CSS bundle —
  /// dimensional (min-height / gap / padding / radius / border-width)
  /// plus the emit-family inline colour fragments (raw colour overrides
  /// only — token values stay on classes above).
  Styles buildRootInlineStyles() => .new(
    raw: {
      'min-height': minHeight,
      'gap': spaceCss(chipSpacing),
      'border-radius': borderRadius.toValue(),
      'border-width': strokeWidthCss(borderWidth),
      // The material's edge band reaches over the border (transparent under
      // a style that draws its own edge), not inside it.
      ...surfaceBleedVar(strokeWidthCss(borderWidth)),
      // Logical longhands: the default insets differ between start and end
      // because of what they are, so the browser mirrors them with `dir`.
      ...padding.toLogicalDeclarations('padding'),
      ...?backgroundEmit.inline,
      ...?borderEmit.inline,
      // The marker's other half — a preset restates this fill at a lower
      // alpha and cannot know which token the frame chose.
      if (!containerFillCore.isTransparent)
        ...surfaceFillVar(containerFillCore),
    },
  );

  /// Composes the inline text-entry wrapper `<div>` Tailwind className
  /// — a flex-grower so the composed chromeless `TextField` shares the
  /// chips' row (the field's own chrome / typography / placeholder
  /// colour are the TextField's responsibility).
  String buildFieldClassName() => WebLayout.flex1;

  /// Composes the inline text-entry wrapper `<div>` inline-CSS bundle —
  /// the minimum width floor before the row wraps.
  Styles buildFieldInlineStyles() => .new(
    raw: {
      'min-width':
          '${CoreChipInputContract.defaultInputMinWidth / kRemDivisor}rem',
      ...inputPadding.toLogicalDeclarations('padding'),
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedChipInput(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    chipStyle: chipStyle,
    field: WebElementChrome(
      className: buildFieldClassName(),
      inlineStyles: buildFieldInlineStyles(),
    ),
    fieldStyle: fieldStyle,
  );
}

/// Resolves the scoped `<style>` rules for a `ChipInput` whose frame
/// focus ring has no class form — see
/// [ResolvedChipInputRules]. Returns empty CSS on the default path
/// ([resolveChipInput] keeps the utility classes: class XOR rule).
///
/// The merge chain mirrors [resolveChipInput] and both read the ring
/// through the same [_resolveRing], so the class-drop condition and the
/// scoped rule can never see different values — split them and the ring
/// either paints twice or not at all.
ResolvedChipInputRules resolveChipInputRules(
  BuildContext context, {
  required String scopeId,
  required bool enabled,
  CoreChipInputStyle? chipInputStyle,
}) {
  final chipInputTheme = context.theme.coreComponentTheme?.chipInput;
  final merged = resolveStyleChain(const CoreChipInputStyle(), [
    chipInputTheme?.style,
    chipInputStyle,
  ]);

  final ring = _resolveRing(merged);
  final hoverBorderEmit = _resolveHoverBorder(
    merged,
    enabled: enabled,
    scopeSelector: '#$scopeId',
  );

  final buffer = StringBuffer();
  if (!ring.classSafe) {
    buffer.write(
      focusRingScopedRule(
        scopeSelector: '#$scopeId',
        pseudo: .focusWithin,
        ringColor: ring.color,
        offsetColor: ring.offsetColor,
        ringWidth: ring.width,
        ringOffset: ring.offset,
        ringOpacity: ring.opacity,
        // A painted band composes over the frame's resting cast (the
        // `kControlShadowRestMarker` value) so stating one does not
        // erase it.
        restShadow: kControlShadowVar,
      ),
    );
  }
  buffer.write(hoverBorderEmit.rule);
  return ResolvedChipInputRules(css: buffer.toString());
}
