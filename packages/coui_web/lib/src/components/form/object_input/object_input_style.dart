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
// ResolvedObjectInput
// ═══════════════════════════════════════════════════

/// Resolved styling values for Web `ObjectInput`.
///
/// surface:content — draws its own box (a single `<div>` restating
/// the surface marker rather than a parent panel drawing it), on the
/// page rather than floating over it.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                       // inline-flex row, border + padding
///   ├─ leading (optional Component)  // caller-provided
///   ├─ field (<input>)               // resolved per-instance via
///   │                                   `resolveObjectInputField`
///   ├─ separator (<span>)            // repeated between fields
///   └─ trailing (optional Component) // caller-provided
/// ```
///
/// `co_object_input` reads `resolved.root.className` /
/// `resolved.root.inlineStyles` and `resolved.separator.className` /
/// `.inlineStyles` straight off; per-field chrome is composed by
/// [resolveObjectInputField] (closes over per-field `maxLength` plus
/// the merged short / medium / long max-width bucket values and the
/// merged short / medium `maxLength` bucket thresholds).
///
/// Output of [resolveObjectInput] — the nested-merge chain
/// (`design system default` → `theme.objectInput.style` →
/// `widget.objectInputStyle`) is applied once. The merged field-width
/// bucket values + `maxLength` thresholds are NOT carried here — they are
/// layout-bucket config consumed by [resolveObjectInputField] (the
/// per-field `max-width` pick), not paint chrome on the container, so the
/// widget reads them from the merge chain via
/// [resolveObjectInputFieldBuckets] (the number_ticker separate-resolver
/// pattern) and forwards them to [resolveObjectInputField].
class ResolvedObjectInput implements WebResolvedChrome {
  /// Creates a [ResolvedObjectInput].
  const ResolvedObjectInput({
    required this.root,
    required this.separator,
    required this.fieldInputVariant,
    required this.fieldInputSize,
    required this.fieldInputStyle,
  });

  /// Paint-ready chrome for the outermost `<div>` row — composed
  /// `inline-flex items-center` className (plus disabled-state
  /// `cursor-not-allowed`) and per-instance dimensional +
  /// colour inline-CSS bundle. State-driven (`enabled`, `focused`) so
  /// both the disabled-state Tailwind classes and the focused-state
  /// border colour travel with the pre-computed root chrome.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the field separator `<span>` — composed
  /// `select-none` className plus the per-instance separator-colour
  /// inline-CSS bundle.
  final WebElementChrome separator;

  /// Variant of each field's composed `TextField` (`plain`: the outer
  /// container owns the single boundary).
  final CoreTextFieldVariant fieldInputVariant;

  /// Size row of each field's composed `TextField` (`lg`).
  final CoreComponentSize fieldInputSize;

  /// Chromeless nested style raw-forwarded to each field's composed
  /// `TextField` (transparent chrome, centred, token-backed monospace
  /// value / placeholder, per-field focus ring suppressed). Chained from
  /// `CoreObjectInputStyle.defaultFieldInputStyle`.
  final CoreTextFieldStyle fieldInputStyle;
}

// ═══════════════════════════════════════════════════
// ResolvedObjectInputField — per-field chrome
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for a single field `<input>` inside a
/// `ObjectInput`.
///
/// DOM shape:
///
/// ```text
/// field (<input>)        // resolved.root — per-field maxLength → max-width
/// ```
class ResolvedObjectInputField implements WebResolvedChrome {
  /// Creates a [ResolvedObjectInputField].
  const ResolvedObjectInputField({required this.root});

  /// Paint-ready chrome for the field `<input>` — composed Tailwind
  /// className (`bg-transparent outline-none text-center`) plus an inline
  /// `max-width` rem rule selected from the per-field `maxLength` against
  /// the merged short / medium / long bucket widths.
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// ResolvedObjectInputRules — scoped <style> text
// ═══════════════════════════════════════════════════

/// Scoped CSS text for the `<style>` block in `ObjectInput`.
///
/// Non-empty only when the container's hover border has no Tailwind class
/// to ride — a raw (token-less) `hoverBorderColor`, or a raw resting
/// `borderColor`, which is emitted inline and so outranks every class.
/// `:hover` cannot be inline CSS, so in that condition `resolveObjectInput`
/// drops the `hover:border-*` utility and the container carries its scope
/// id instead (class XOR rule):
/// `#co-object-input-<id>:hover{border-color: …}`.
class ResolvedObjectInputRules {
  /// Creates a [ResolvedObjectInputRules].
  const ResolvedObjectInputRules({required this.css});

  /// Raw CSS rule text — empty on the default path (pure utility classes).
  final String css;
}

/// The class-path hover fragment never reads the scope selector — only the
/// rule text does — so [resolveObjectInput], which has no scope id, passes
/// this in its place.
const String _kClassPathScope = '';

/// Where the container's hover border rides: a pseudo class when every
/// colour involved is a token, a scoped rule when one is not.
///
/// Precedence is `disabled > focus > hover > rest`:
/// * **disabled** — no hover step (`enabled == false` → empty).
/// * **focus** — the container tracks focus itself (`focusin` /
///   `focusout` → [focused]) and swaps the resting border for
///   `focusBorderColor`; while it is focused no hover fragment is emitted
///   at all, so the cascade order of `hover:` against any focus class never
///   comes into play.
/// * **hover** — `hoverBorderColor` (token → class, raw → scoped rule).
///
/// A raw resting border is emitted inline, which outranks every class and
/// every selector; the hover step then needs `!important` or it would
/// never show. A token rest border is a class and loses to both paths.
PseudoEmit _resolveHoverBorder(
  CoreObjectInputStyle merged, {
  required bool enabled,
  required bool focused,
  required String scopeSelector,
}) {
  if (!enabled || focused) return (className: '', rule: '');
  final hover =
      merged.hoverBorderColor ?? CoreObjectInputStyle.defaultHoverBorderColor;
  final rest = merged.borderColor ?? CoreObjectInputStyle.defaultBorderColor;
  if (rest.token == null) {
    return (
      className: '',
      rule:
          '${WebPseudo.hover.selector(scopeSelector)}'
          '{border-color: ${hover.toValue()} !important;}',
    );
  }
  return emitPseudoColor(
    hover,
    hover,
    .border,
    pseudo: .hover,
    scopeSelector: scopeSelector,
  );
}

// ═══════════════════════════════════════════════════
// Resolver — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedObjectInput] for the given [context].
///
/// Walks the nested-merge chain (Epic #1302):
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.objectInput.style
///   → widget.objectInputStyle
/// ```
ResolvedObjectInput resolveObjectInput(
  BuildContext context, {
  required bool enabled,
  required bool focused,
  CoreObjectInputStyle? objectInputStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.objectInput;

  final merged = resolveStyleChain(const CoreObjectInputStyle(), [
    csTheme?.style,
    objectInputStyle,
  ]);

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Colour / typography route through the emit family — one
  // class-XOR-inline decision per value. Token-bound values emit Tailwind
  // classes (dark-mode reactive); raw overrides go inline. No
  // `scheme.resolve` (a no-op on Web).
  // `disabled > focus > rest`: a disabled container takes its own fill and
  // border tokens (never an opacity over the enabled pair — an alpha is not a
  // forced value in a colour-forcing accessibility mode) and does not claim
  // the focus ring.
  final effectiveBackground = enabled
      ? merged.backgroundColor ?? CoreObjectInputStyle.defaultBackgroundColor
      : merged.disabledBackgroundColor ??
            CoreObjectInputStyle.defaultDisabledBackgroundColor;
  final backgroundEmit = enabled
      ? emitColor(
          merged.backgroundColor,
          CoreObjectInputStyle.defaultBackgroundColor,
          .background,
        )
      : emitColor(
          merged.disabledBackgroundColor,
          CoreObjectInputStyle.defaultDisabledBackgroundColor,
          .background,
        );
  // Border colour reflects the disabled / focused / unfocused choice. Each
  // state routes through `emitColor` with its own default fallback.
  final borderEmit = !enabled
      ? emitColor(
          merged.disabledBorderColor,
          CoreObjectInputStyle.defaultDisabledBorderColor,
          .border,
        )
      : focused
      ? emitColor(
          merged.focusBorderColor,
          CoreObjectInputStyle.defaultFocusBorderColor,
          .border,
        )
      : emitColor(
          merged.borderColor,
          CoreObjectInputStyle.defaultBorderColor,
          .border,
        );
  final hoverBorderEmit = _resolveHoverBorder(
    merged,
    enabled: enabled,
    focused: focused,
    scopeSelector: _kClassPathScope,
  );
  // Separator typography — `emitTypography` merges the design-system
  // default role with any per-instance overlay, emitting a `text-{role}`
  // class for a pure role or an inline bundle for a scalar / raw overlay.
  final separatorEmit = emitTypography(
    enabled
        ? merged.separatorTextStyle
        : (merged.separatorTextStyle ?? const CoreTextStyle()).copyWith(
            color:
                merged.disabledSeparatorColor ??
                CoreObjectInputStyle.defaultDisabledSeparatorColor,
          ),
    CoreObjectInputStyle.defaultSeparatorTextStyle,
  );
  final borderRadius =
      (merged.borderRadius ?? CoreObjectInputStyle.defaultBorderRadius)
          .toValue();
  final borderWidth =
      merged.borderWidth ?? CoreObjectInputStyle.defaultBorderWidth;
  final padding = (merged.padding ?? CoreObjectInputStyle.defaultPadding)
      .toValue();
  // The box is a row of the control ladder (the lg rung, the row of the
  // text field beside it): unstated, it goes out as the row variable so a
  // density moves it, as on Flutter. A caller's own height is a statement
  // and stays as stated.
  final height = merged.height == null
      ? controlHeightCss(CoreObjectInputStyle.defaultHeight)
      : '${merged.height! / kRemDivisor}rem';
  final fieldSpacing = spaceCss(
    merged.fieldSpacing ?? CoreObjectInputStyle.defaultFieldSpacing,
  );
  final separatorPadding =
      (merged.separatorPadding ?? CoreObjectInputStyle.defaultSeparatorPadding)
          .toValue();

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer container Tailwind className. Disabled-state
  /// classes (`cursor-not-allowed`) travel with the root
  /// chrome because the resolver receives `enabled`. The background +
  /// border colour token classes from the emit family stack here.
  ///
  /// Marks the container as a component surface — restated here rather
  /// than composing an `OutlinedContainer` Web widget (a single
  /// `<div>`, no DOM restructure); the Flutter twin composes the
  /// primitive. Unconditional across both focus states: the fill is a
  /// real, opaque design token and no glyph rides on it, only the
  /// per-field `<input>`s' typed text / caret and the separator text
  /// (already carrying their own colour) — so there is no
  /// fill-less-box risk in either state.
  String buildContainerClassName() => <String>[
    WebLayout.inlineFlexItemsCenter,
    // `cursor-not-allowed` only. The fill and border already say "disabled"
    // in their own tokens, and an opacity on top would say it a second way —
    // the way a colour-forcing accessibility mode cannot hear, because it
    // substitutes colours and leaves alpha alone.
    if (!enabled) 'cursor-not-allowed',
    backgroundEmit.className,
    borderEmit.className,
    hoverBorderEmit.className,
    ...webSurfaceMarkerFor(.content),
  ].where((c) => c.isNotEmpty).join(' ');

  /// Composes the outer container inline CSS — border / radius / padding
  /// plus any raw colour fragments from the emit family (token colours
  /// stay on classes and contribute `null` here).
  Styles buildContainerInlineStyles() => .new(
    raw: {
      'border-style': 'solid',
      'border-width': strokeWidthCss(borderWidth),
      ...surfaceBleedVar(strokeWidthCss(borderWidth)),
      'border-radius': borderRadius,
      'padding': padding,
      'height': height,
      'gap': fieldSpacing,
      ...?backgroundEmit.inline,
      ...?borderEmit.inline,
      // The other half of the surface marker above.
      ...surfaceFillVar(effectiveBackground),
    },
  );

  /// Composes the field separator `<span>` Tailwind className —
  /// `select-none` (plus literal-whitespace preservation for space
  /// separators — HTML would otherwise collapse them, tightening the gap
  /// versus Flutter's `Text` which keeps every space) and the typography
  /// role / colour token classes from the emit family.
  String buildSeparatorClassName() => <String>[
    'select-none',
    'whitespace-pre',
    separatorEmit.className,
  ].where((c) => c.isNotEmpty).join(' ');

  /// Composes the field separator `<span>` inline CSS — the separator
  /// padding (Flutter `Padding(separatorPadding)` parity) plus any raw
  /// typography overlay fragments from the emit family (token role /
  /// colour stay on classes and contribute `null` here).
  Styles buildSeparatorInlineStyles() {
    final raw = {
      'padding': separatorPadding,
      ...?separatorEmit.inline,
    };
    return Styles(raw: raw);
  }

  return ResolvedObjectInput(
    root: WebElementChrome(
      className: buildContainerClassName(),
      inlineStyles: buildContainerInlineStyles(),
    ),
    separator: WebElementChrome(
      className: buildSeparatorClassName(),
      inlineStyles: buildSeparatorInlineStyles(),
    ),
    fieldInputVariant: CoreObjectInputStyle.defaultFieldInputVariant,
    fieldInputSize: CoreObjectInputStyle.defaultFieldInputSize,
    fieldInputStyle: CoreObjectInputStyle.defaultFieldInputStyle.merge(
      merged.fieldInputStyle,
    ),
  );
}

/// Resolves the merged field-width bucket config for `ObjectInput` —
/// the short / medium / long `max-width` bucket values consumed by
/// [resolveObjectInputField] to pick a per-field `max-width`. This is
/// layout-bucket config, not paint chrome on the container, so it is
/// exposed as a separate `resolveCo*` entry point and kept off
/// [ResolvedObjectInput] (Epic #1603 옵션 B 최종 — no scalar metadata on
/// `ResolvedCo*`; number_ticker separate-resolver pattern).
///
/// The two `maxLength` *boundaries* are not here: they decide which
/// width applies rather than what any width is, so they are widget-plane
/// behaviour (`ObjectInput.shortFieldMaxChars` /
/// `mediumFieldMaxChars`) and reach [resolveObjectInputField] straight
/// from the widget.
///
/// Walks the same merge chain as [resolveObjectInput]
/// (design-system default → `CoreObjectInputTheme.style` →
/// `widget.objectInputStyle`).
({
  double shortFieldMaxWidth,
  double mediumFieldMaxWidth,
  double longFieldMaxWidth,
  double charWidth,
})
resolveObjectInputFieldBuckets(
  BuildContext context, {
  CoreObjectInputStyle? objectInputStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.objectInput;
  final merged = resolveStyleChain(const CoreObjectInputStyle(), [
    csTheme?.style,
    objectInputStyle,
  ]);
  return (
    shortFieldMaxWidth:
        merged.shortFieldMaxWidth ??
        CoreObjectInputStyle.defaultShortFieldMaxWidth,
    mediumFieldMaxWidth:
        merged.mediumFieldMaxWidth ??
        CoreObjectInputStyle.defaultMediumFieldMaxWidth,
    longFieldMaxWidth:
        merged.longFieldMaxWidth ??
        CoreObjectInputStyle.defaultLongFieldMaxWidth,
    charWidth: merged.charWidth ?? CoreObjectInputStyle.defaultCharWidth,
  );
}

// ═══════════════════════════════════════════════════
// resolveObjectInputRules — scoped <style> entry point
// ═══════════════════════════════════════════════════

/// Resolves the scoped `<style>` rules for an `ObjectInput` whose hover
/// border has no Tailwind class — see [ResolvedObjectInputRules]. Returns
/// empty CSS on the default path ([resolveObjectInput] keeps the
/// `hover:border-*` utility: class XOR rule).
///
/// The merge chain and the hover decision mirror [resolveObjectInput]
/// (both read [_resolveHoverBorder]), so the class-drop condition and the
/// scoped rule can never see different values — split them and the border
/// either steps twice or not at all.
ResolvedObjectInputRules resolveObjectInputRules(
  BuildContext context, {
  required String scopeId,
  required bool enabled,
  required bool focused,
  CoreObjectInputStyle? objectInputStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.objectInput;
  final merged = resolveStyleChain(const CoreObjectInputStyle(), [
    csTheme?.style,
    objectInputStyle,
  ]);

  final hoverBorderEmit = _resolveHoverBorder(
    merged,
    enabled: enabled,
    focused: focused,
    scopeSelector: '#$scopeId',
  );
  return ResolvedObjectInputRules(css: hoverBorderEmit.rule);
}

// ═══════════════════════════════════════════════════
// resolveObjectInputField — per-field entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedObjectInputField] for a single field wrapper
/// `<div>` inside a `ObjectInput` — the field's typography / chrome now
/// lives on the composed `TextField` (fed the chained
/// `resolved.fieldInputStyle`), so the wrapper only fixes the field
/// width: `charWidth * intrinsicChars` (Flutter
/// `SizedBox(width: charWidth * maxLength)` parity) capped by the bucket
/// `max-width` picked from the per-field `maxLength`.
ResolvedObjectInputField resolveObjectInputField({
  required double shortFieldMaxWidth,
  required double mediumFieldMaxWidth,
  required double longFieldMaxWidth,
  required int shortFieldMaxChars,
  required int mediumFieldMaxChars,
  required double charWidth,
  required int intrinsicChars,
  int? maxLength,
}) {
  /// Picks the bucket max-width (logical px) for the per-field
  /// `maxLength` — short (≤[shortFieldMaxChars]), medium
  /// (≤[mediumFieldMaxChars]), or long.
  double? fieldMaxWidth() {
    if (maxLength == null) return null;
    if (maxLength <= shortFieldMaxChars) return shortFieldMaxWidth;
    if (maxLength <= mediumFieldMaxChars) return mediumFieldMaxWidth;
    return longFieldMaxWidth;
  }

  /// Inline CSS for the field wrapper `<div>` — the per-character
  /// intrinsic width capped by the bucket `max-width`; the child
  /// `TextField` fills it.
  Styles buildRootInlineStyles() {
    final raw = {
      'width': '${charWidth * intrinsicChars / kRemDivisor}rem',
    };
    final width = fieldMaxWidth();
    if (width != null) raw['max-width'] = '${width / kRemDivisor}rem';
    return Styles(raw: raw);
  }

  return ResolvedObjectInputField(
    root: WebElementChrome(
      className: WebLayout.flex,
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}
