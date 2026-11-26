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
// ResolvedFormattedInput
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `FormattedInput`.
///
/// surface:content — draws its own box (a single `<div>` restating
/// the surface marker rather than a parent panel drawing it), on the
/// page rather than floating over it.
///
/// DOM shape (Story #3869 — single real `<input>`, no per-segment
/// `<input>` instances):
///
/// ```text
/// root (<div>)                       // full-width flex row, border + padding
///   ├─ leading (optional Component)  // caller-provided
///   ├─ field (<input>)               // the single real input — one
///   │                                   `input` event handler wraps
///   │                                   `CoreFormattedInputMaskEngine.apply`
///   └─ trailing (optional Component) // caller-provided
/// ```
///
/// All chrome slots are paint-ready ([WebElementChrome]) —
/// `formatted_input.dart` reads each slot's `className` / `inlineStyles`
/// straight off `resolved.<slot>`; no merge / fallback / conversion in the
/// widget body.
class ResolvedFormattedInput implements WebResolvedChrome {
  /// Creates a [ResolvedFormattedInput].
  const ResolvedFormattedInput({required this.root, required this.field});

  /// Paint-ready chrome for the outermost `<div>` row — composed
  /// `flex w-full items-center` className (plus disabled-state
  /// `cursor-not-allowed`) and per-instance dimensional + colour inline-CSS
  /// bundle.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the single real `<input>` — transparent /
  /// borderless chrome (the [root] container draws the box), centred
  /// value text, monospace value / placeholder typography. Derived from
  /// [CoreFormattedInputStyle.segmentInputStyle] (still `CoreTextFieldStyle?`
  /// per DDR-06 — the field name / type is unchanged, only its meaning
  /// narrows from "raw-forwarded to N composed `TextField`s" to
  /// "raw-forwarded to the one real `<input>`").
  final WebElementChrome field;
}

// ═══════════════════════════════════════════════════
// ResolvedFormattedInputRules — scoped <style> text
// ═══════════════════════════════════════════════════

/// Scoped CSS text for the `<style>` block in `FormattedInput`.
///
/// Non-empty only when the container's hover border has no Tailwind class
/// to ride — a raw (token-less) `hoverBorderColor`, or a raw resting
/// `borderColor`, which is emitted inline and so outranks every class.
/// `:hover` cannot be inline CSS, so in that condition `resolveFormattedInput`
/// drops the `hover:border-*` utility and the container carries its scope
/// id instead (class XOR rule):
/// `#co-formatted-input-<id>:hover{border-color: …}`.
class ResolvedFormattedInputRules {
  /// Creates a [ResolvedFormattedInputRules].
  const ResolvedFormattedInputRules({required this.css});

  /// Raw CSS rule text — empty on the default path (pure utility classes).
  final String css;
}

/// The class-path hover fragment never reads the scope selector — only the
/// rule text does — so [resolveFormattedInput], which has no scope id,
/// passes this in its place.
const String _kClassPathScope = '';

// A stated nested placeholder color wins in both enabled and disabled states.
CoreColor _placeholderColor(CoreFormattedInputStyle style, bool enabled) {
  final stated = style.segmentInputStyle?.placeholderStyle?.color;
  if (stated != null) return stated;
  if (!enabled) {
    return style.disabledForegroundColor ??
        CoreFormattedInputStyle.defaultDisabledForegroundColor;
  }
  return CoreFormattedInputStyle.defaultPlaceholderColor;
}

/// Where the container's hover border rides: a pseudo class when every
/// colour involved is a token, a scoped rule when one is not.
///
/// Precedence is `disabled > focus > hover > rest`: a disabled container has
/// no hover step, and while it is focused the focus border wins, so no hover
/// fragment is emitted at all. A raw resting border is emitted inline, which
/// outranks every class and every selector; the hover step then needs
/// `!important` or it would never show.
PseudoEmit _resolveHoverBorder(
  CoreFormattedInputStyle merged, {
  required bool enabled,
  required bool focused,
  required String scopeSelector,
}) {
  if (!enabled || focused) return (className: '', rule: '');
  final hover =
      merged.hoverBorderColor ??
      CoreFormattedInputStyle.defaultHoverBorderColor;
  final rest = merged.borderColor ?? CoreFormattedInputStyle.defaultBorderColor;
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

/// Resolves [ResolvedFormattedInput] for the given [context].
///
/// Walks the nested-merge chain:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.formattedInput.style
///   → widget.formattedInputStyle
/// ```
ResolvedFormattedInput resolveFormattedInput(
  BuildContext context, {
  required bool enabled,
  required bool focused,
  CoreFormattedInputStyle? formattedInputStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.formattedInput;

  final merged = resolveStyleChain(const CoreFormattedInputStyle(), [
    csTheme?.style,
    formattedInputStyle,
  ]);

  // ─── Stage 1 RESOLVE (Core values; theme-free) ─────────
  final borderRadius =
      (merged.borderRadius ?? CoreFormattedInputStyle.defaultBorderRadius)
          .toValue();
  final borderWidth =
      merged.borderWidth ?? CoreFormattedInputStyle.defaultBorderWidth;
  final padding = (merged.padding ?? CoreFormattedInputStyle.defaultPadding)
      .toValue();
  // The box is a row of the control ladder (the lg rung, the row of the
  // text field beside it): unstated, it goes out as the row variable so a
  // density moves it, as on Flutter. A caller's own height is a statement
  // and stays as stated.
  final height = merged.height == null
      ? controlHeightCss(CoreFormattedInputStyle.defaultHeight)
      : '${merged.height! / kRemDivisor}rem';
  final contentSpacing = spaceCss(
    merged.contentSpacing ?? CoreFormattedInputStyle.defaultContentSpacing,
  );
  final disabledForegroundColor =
      merged.disabledForegroundColor ??
      CoreFormattedInputStyle.defaultDisabledForegroundColor;
  // Effective border colour — focused vs unfocused choice (runtime state).
  final focusBorderColor =
      merged.focusBorderColor ??
      CoreFormattedInputStyle.defaultFocusBorderColor;
  final borderColor =
      merged.borderColor ?? CoreFormattedInputStyle.defaultBorderColor;
  final disabledBackgroundColor =
      merged.disabledBackgroundColor ??
      CoreFormattedInputStyle.defaultDisabledBackgroundColor;
  final disabledBorderColor =
      merged.disabledBorderColor ??
      CoreFormattedInputStyle.defaultDisabledBorderColor;
  // Disabled outranks focus — a field that cannot be edited should not
  // claim the focus ring, and the two can coexist.
  final effectiveBorderColor = switch ((enabled, focused)) {
    (false, _) => disabledBorderColor,
    (true, true) => focusBorderColor,
    (true, false) => borderColor,
  };

  final hoverBorderEmit = _resolveHoverBorder(
    merged,
    enabled: enabled,
    focused: focused,
    scopeSelector: _kClassPathScope,
  );

  // Segment (now: single-field) chrome — the design default merged with
  // the per-instance override, raw-forwarded exactly as before (DDR-06:
  // field/type unchanged). Only *what happens to it* changed — it used
  // to be handed to N composed `TextField`s; now its relevant subset is
  // converted straight to the one real `<input>`'s chrome below.
  final segmentInputStyle = CoreFormattedInputStyle.defaultSegmentInputStyle
      .merge(merged.segmentInputStyle);

  // ─── Stage 2 EMIT (Web, theme-free) ────────────────────
  // Token-bound colours emit Tailwind classes (dark-mode reactive); raw
  // overrides go inline. No `scheme.resolve` (a no-op on Web).
  final effectiveBackgroundColor = enabled
      ? merged.backgroundColor ?? CoreFormattedInputStyle.defaultBackgroundColor
      : disabledBackgroundColor;
  final backgroundEmit = emitColor(
    effectiveBackgroundColor,
    effectiveBackgroundColor,
    .background,
  );
  final borderEmit = emitColor(
    effectiveBorderColor,
    effectiveBorderColor,
    .border,
  );

  // Field (the single `<input>`) chrome — transparent by default (the
  // root container owns the box); backgroundColor / borderColor /
  // borderWidth honour a per-instance `segmentInputStyle` override the
  // same way the container's own chrome does.
  final fieldBackgroundEmit = emitColor(
    segmentInputStyle.backgroundColor,
    .transparent,
    .background,
  );
  final fieldBorderEmit = emitColor(
    segmentInputStyle.borderColor,
    .transparent,
    .border,
  );
  final fieldBorderWidth = segmentInputStyle.borderWidth ?? 0;
  final fieldPadding = (segmentInputStyle.padding ?? .zero).toValue();
  final fieldTextAlign = (segmentInputStyle.textAlign ?? .center).toValue();

  // Value / placeholder typography — role class + explicit overlay inline
  // via the canonical `emitTypography` entry point. The *raw* per-instance
  // override (`merged.segmentInputStyle?.X`, not the already-Core-defaulted
  // `segmentInputStyle.X`) is passed as `value` so `emitTypography` performs
  // exactly one default-merge, matching every other resolver's convention.
  // guard-nested-override: segmentTextStyle — reaches via
  // `merged.segmentInputStyle?.valueStyle` (nested Style slot), not a
  // top-level `segmentTextStyle` field (there is no such field).
  final valueEmit = emitTypography(
    merged.segmentInputStyle?.valueStyle,
    CoreFormattedInputStyle.defaultSegmentTextStyle,
  );
  // guard-nested-override: placeholderColor — reaches via
  // `merged.segmentInputStyle?.placeholderStyle?.color` (nested Style
  // slot), not a top-level `placeholderColor` field.
  final placeholderPseudo = emitPseudoColor(
    _placeholderColor(merged, enabled),
    CoreFormattedInputStyle.defaultPlaceholderColor,
    .text,
    pseudo: .placeholder,
    scopeSelector: _kClassPathScope,
  );
  // The placeholder takes its own role (`::placeholder` rides the
  // `placeholder:` variant) — the mask pattern is a hint in the body face,
  // not a value on the code grid. Only the role rides the pseudo-element;
  // a scalar overlay has no `::placeholder` inline form.
  final placeholderRole = CoreFormattedInputStyle
      .defaultSegmentPlaceholderTextStyle
      .merge(merged.segmentInputStyle?.placeholderStyle)
      .token;
  // The value's text colour while disabled (the enabled value inherits).
  final valueColorEmit = enabled
      ? null
      : emitColor(
          merged.segmentInputStyle?.valueStyle?.color,
          disabledForegroundColor,
          .text,
        );

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer container Tailwind className. Disabled-state
  /// classes (`cursor-not-allowed`) travel with the root chrome because the
  /// resolver receives `enabled`. Token colours emit as Tailwind classes via
  /// the emit family.
  ///
  /// The row is block-level and fills its parent (`flex w-full`), like every
  /// other text-entry field and like the Flutter twin, whose `Row` takes the
  /// width it is given. A shrink-to-fit row (`inline-flex`) would collapse to
  /// the `<input>`'s own default width (`size=20`), so a wider parent would
  /// never reach the field and the two platforms would draw it at different
  /// widths. A caller narrows it by sizing the parent — a class on this root
  /// does not reliably win against `w-full`.
  ///
  /// Marks the container as a component surface — restated here rather
  /// than composing an `OutlinedContainer` Web widget (a single
  /// `<div>`, no DOM restructure); the Flutter twin composes the
  /// primitive. Unconditional across both focus states: the fill is a
  /// real, opaque design token and no glyph rides on it, only the
  /// `<input>`'s typed text / caret (already carrying its own colour)
  /// — so there is no fill-less-box risk in either state.
  String buildRootClassName() => [
    WebLayout.flexFullItemsCenter,
    backgroundEmit.className,
    borderEmit.className,
    hoverBorderEmit.className,
    // `cursor-not-allowed` only. The fill and border already say
    // "disabled" in their own tokens, and an opacity on top would say it a
    // second way — the way a colour-forcing accessibility mode cannot
    // hear, because it substitutes colours and leaves alpha alone.
    if (!enabled) 'cursor-not-allowed',
    ...webSurfaceMarkerFor(.content),
  ].where((c) => c.isNotEmpty).join(' ');

  /// Composes the outer container inline CSS — border geometry / radius /
  /// padding, plus any raw colour overrides the emit family routed inline.
  Styles buildRootInlineStyles() => .new(
    raw: {
      'border-style': 'solid',
      'border-width': strokeWidthCss(borderWidth),
      // The material's edge band reaches over the border (transparent under
      // a style that draws its own edge), not inside it.
      ...surfaceBleedVar(strokeWidthCss(borderWidth)),
      'border-radius': borderRadius,
      'padding': padding,
      'height': height,
      'gap': contentSpacing,
      ...?backgroundEmit.inline,
      ...?borderEmit.inline,
      // The other half of the surface marker above.
      ...surfaceFillVar(effectiveBackgroundColor),
    },
  );

  /// Composes the single real `<input>`'s Tailwind className — fills the
  /// remaining row width (`flex-1 min-w-0`, alongside optional
  /// `leading` / `trailing`), transparent / borderless by default (the
  /// [root] container draws the box), monospace value typography, no
  /// browser focus outline (the container swaps its own border colour on
  /// focus instead).
  String buildFieldClassName() => <String>[
    WebLayout.flex1,
    WebLayout.minWZero,
    fieldBackgroundEmit.className,
    fieldBorderEmit.className,
    'outline-none',
    'font-${CoreFontFamily.scale.mono}',
    valueEmit.className,
    placeholderPseudo.className,
    if (placeholderRole != null) ...[
      'placeholder:font-${CoreFontFamily.scale.sans}',
      'placeholder:text-${placeholderRole.name}',
    ],
    ?valueColorEmit?.className,
    if (!enabled) 'cursor-not-allowed',
  ].where((c) => c.isNotEmpty).join(' ');

  /// Composes the single real `<input>`'s inline CSS bundle — border
  /// width / padding / text alignment (single inline signature), plus
  /// any raw colour overrides and the value-typography overlay
  /// (`font-size` / `font-weight` when overridden — the role class
  /// covers the unset case).
  Styles buildFieldInlineStyles() => .new(
    raw: {
      'border-style': 'solid',
      'border-width': strokeWidthCss(fieldBorderWidth),
      'padding': fieldPadding,
      'text-align': fieldTextAlign,
      ...?fieldBackgroundEmit.inline,
      ...?fieldBorderEmit.inline,
      ...?valueEmit.inline,
      ...?valueColorEmit?.inline,
    },
  );

  return ResolvedFormattedInput(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    field: WebElementChrome(
      className: buildFieldClassName(),
      inlineStyles: buildFieldInlineStyles(),
    ),
  );
}

// ═══════════════════════════════════════════════════
// resolveFormattedInputRules — scoped <style> entry point
// ═══════════════════════════════════════════════════

/// Resolves scoped rules for a raw hover border or placeholder color.
/// Returns empty CSS when token classes cover both. [inputId] targets the
/// native field without affecting inputs supplied in the surrounding slots.
///
/// The merge chain and the hover decision mirror [resolveFormattedInput]
/// (both read [_resolveHoverBorder]), so the class-drop condition and the
/// scoped rule can never see different values.
ResolvedFormattedInputRules resolveFormattedInputRules(
  BuildContext context, {
  required String scopeId,
  required bool enabled,
  required bool focused,
  String? inputId,
  CoreFormattedInputStyle? formattedInputStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.formattedInput;
  final merged = resolveStyleChain(const CoreFormattedInputStyle(), [
    csTheme?.style,
    formattedInputStyle,
  ]);

  final hoverBorderEmit = _resolveHoverBorder(
    merged,
    enabled: enabled,
    focused: focused,
    scopeSelector: '#$scopeId',
  );
  final placeholder = emitPseudoColor(
    _placeholderColor(merged, enabled),
    CoreFormattedInputStyle.defaultPlaceholderColor,
    .text,
    pseudo: .placeholder,
    scopeSelector: inputId == null ? '#$scopeId > input' : '#$inputId',
  );
  return ResolvedFormattedInputRules(
    css: hoverBorderEmit.rule + placeholder.rule,
  );
}
