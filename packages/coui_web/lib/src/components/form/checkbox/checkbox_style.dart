import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// The complete size palette has CSS variables; an arbitrary dimension does
// not. Keep exact matching so a fractional override never borrows a token.
const _kCheckboxSizeSteps = <double>[
  CoreSize.size4,
  CoreSize.size6,
  CoreSize.size8,
  CoreSize.size10,
  CoreSize.size12,
  CoreSize.size14,
  CoreSize.size16,
  CoreSize.size18,
  CoreSize.size20,
  CoreSize.size24,
  CoreSize.size28,
  CoreSize.size32,
  CoreSize.size36,
  CoreSize.size40,
  CoreSize.size44,
  CoreSize.size48,
  CoreSize.size56,
  CoreSize.size64,
  CoreSize.size72,
  CoreSize.size80,
  CoreSize.size88,
  CoreSize.size96,
  CoreSize.size112,
  CoreSize.size128,
];

String _checkboxSizeCss(double value) => _kCheckboxSizeSteps.contains(value)
    ? 'var(--coui-size-${value.toInt()})'
    : '${value / kRemDivisor}rem';

// ═══════════════════════════════════════════════════
// Resolved style (already-merged values)
// ═══════════════════════════════════════════════════

/// Marker class on the checkbox square — the scoped rules in
/// [resolveCheckboxRules] select through it with a descendant combinator,
/// since `:hover` / `:focus-visible` / `:active` land on the `Clickable`
/// root (the focusable, tabindex-bearing element) and the square is a
/// plain nested `<div>` that never receives focus or press itself.
///
/// Stable and unconditional rather than content-addressed, because it
/// only ever needs to be reachable from the sibling `<style>` block's
/// selector, never unique across instances.
const kCheckboxBoxMarker = 'co-checkbox-box';

/// Resolved styling values for Web `Checkbox`.
///
/// DOM shape (the outermost `Clickable` renders its own chrome via
/// `resolveClickable` — cursor / press-shrink / disabled opacity live
/// there, mirroring the Flutter twin's `Clickable(child: Row(…))`
/// composition; the focus ring is NOT the Clickable's — it hugs the box
/// via the scoped rules in [resolveCheckboxRules]):
///
/// ```text
/// Clickable (<div role="checkbox" class="… <scopeClass>">)   // owns tap / keyboard / cursor / press
///   └─ root (<span>)                                      // content wrapper, always present
///        ├─ <style>                                       // scoped halo + ring rules, when enabled
///        ├─ hiddenInput (<input>)                         // checkbox.dart renders only when name != null
///        ├─ prefix                                        // checkbox.dart renders only when prefix != null
///        ├─ Gap(gapStyle: indicatorLabelGapStyle)         // checkbox.dart renders only when prefix != null
///        ├─ box (<div class="co-checkbox-box">)           // always present (the square)
///        │    │  ::before                                 // halo — box + 2·spread, washed on :hover / :active
///        │    └─ glyphStack (<span class="contents">)     // fragment-equivalent — anchors the two stacked glyphs
///        │         ├─ checkGlyph (<span>)                 // CSS-anim scale slot, always mounted (visible when checked == true)
///        │         │    └─ Icon(iconStyle: checkmarkIconStyle)
///        │         └─ indeterminateGlyph (<span>)         // CSS-anim scale slot, always mounted (visible when checked == null)
///        │              └─ indicator (<div>)              // the dash — indeterminateLength × markThickness, pill
///        ├─ Gap(gapStyle: indicatorLabelGapStyle)         // checkbox.dart renders only when suffix / label / description
///        ├─ suffix                                        // checkbox.dart renders only when suffix != null
///        ├─ labelWrapper (<span>)                         // label text (+ Gap + description)
///        └─ trailing                                      // checkbox.dart renders only when trailing != null
/// ```
///
/// All chrome slots are paint-ready ([WebElementChrome]) — `checkbox.dart`
/// reads `resolved.<slot>.className` / `resolved.<slot>.inlineStyles`
/// straight off without invoking any top-level builder. The resolver
/// already closed over the runtime value (`checked`, `enabled`) passed in
/// at build time.
///
/// Output of [resolveCheckbox] — every field has had the merge chain
/// applied plus `CoreCheckboxStyle.defaultsBySize[size]!` / flat
/// `default*` fallback:
///
/// ```text
/// design system default (flat defaults + defaultsBySize)
///   → theme.checkbox.style
///   → widget.checkboxStyle
/// ```
class ResolvedCheckbox implements WebResolvedChrome {
  /// Creates a [ResolvedCheckbox].
  const ResolvedCheckbox({
    required this.root,
    required this.box,
    required this.glyphStack,
    required this.checkGlyph,
    required this.indeterminateGlyph,
    required this.indicator,
    required this.checkmarkIconStyle,
    required this.clickableStyle,
    required this.indicatorLabelGapStyle,
    required this.labelWrapper,
    required this.description,
    required this.labelDescriptionGapStyle,
  });

  /// Paint-ready chrome for the content wrapper `<span>` inside the
  /// composing `Clickable` (label typography + inline-flex layout).
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the checkbox square `<div>`.
  final WebElementChrome box;

  /// Paint-ready chrome for the `<span class="contents">` fragment that
  /// hosts the two stacked check / indeterminate glyph slots.
  final WebElementChrome glyphStack;

  /// Paint-ready chrome for the check glyph `<span>` (CSS-anim scale
  /// slot, always mounted).
  final WebElementChrome checkGlyph;

  /// Paint-ready chrome for the indeterminate glyph `<span>` (CSS-anim
  /// scale slot, always mounted).
  final WebElementChrome indeterminateGlyph;

  /// Paint-ready chrome for the indeterminate dash `<div>` glyph.
  final WebElementChrome indicator;

  /// Nested `CoreIconStyle` slot — forwarded to `Icon(iconStyle: …)`
  /// for the inner check glyph. Carries the resolved checkmark size and
  /// the per-state ink (enabled `onPrimary`, disabled the disabled ramp's
  /// content token).
  final CoreIconStyle checkmarkIconStyle;

  /// Nested [CoreGapStyle] slot for the horizontal gap between the
  /// checkbox indicator and the prefix / suffix / label slot in the
  /// labelled branch — forwarded straight to `Gap(gapStyle: …)`.
  /// The receiving `Gap` runs its own resolve step, so this slot is
  /// the merged design-system default + per-instance override in
  /// pre-scaling units (mirrors the Flutter resolver pattern).
  final CoreGapStyle indicatorLabelGapStyle;

  /// Paint-ready chrome for the label-text wrapper `<span>` — a
  /// shrinkable flex item (`min-w-0`) so the label wraps within the
  /// pane, mirroring Flutter's `Flexible(Text(…))`. The
  /// character-level wrap fallback inherits from the `CoUIWeb` app
  /// root (`break-words`).
  final WebElementChrome labelWrapper;

  /// Paint-ready chrome for the description line under the label —
  /// `checkbox.dart` renders this element only when the caller supplies
  /// a `description`.
  final WebElementChrome description;

  /// Nested [CoreGapStyle] slot for the vertical gap between the label
  /// and the description — forwarded straight to `Gap(gapStyle: …)`.
  final CoreGapStyle labelDescriptionGapStyle;

  /// Nested [CoreClickableStyle] slot for the composed `Clickable` —
  /// design default (`CoreCheckboxStyle.defaultClickableStyle`, which
  /// keeps the Clickable's generic disabled fade off because the
  /// checkbox paints its own disabled tokens) merged with the
  /// per-instance override, raw-forwarded to `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCheckbox] for the given [context] + runtime value.
///
/// Walks the nested-merge chain plus `CoreCheckboxStyle.defaultsBySize`
/// and the flat `default*` fallbacks:
///
/// ```text
/// design system default (flat defaults + defaultsBySize)
///   → theme.coreComponentTheme.checkbox.style
///   → widget.checkboxStyle
/// ```
ResolvedCheckbox resolveCheckbox(
  BuildContext context, {
  required CoreComponentSize size,
  required bool? checked,
  required bool enabled,
  // Whether the caller supplied a description — a build-time semantic
  // input like `enabled`, not an interaction state, so it belongs in the
  // resolver signature (widget/render-only.md). It picks the row's
  // cross-axis alignment and whether the content wrapper is a column.
  bool hasDescription = false,
  CoreCheckboxStyle? checkboxStyle,
}) {
  final merged = _mergedCheckboxStyle(context, checkboxStyle);

  // Size default table.
  final sizeDefaults = CoreCheckboxStyle.defaultsBySize[size]!;

  final checkmarkSize =
      merged.checkmarkSize ??
      merged.checkmarkIconStyle?.size ??
      sizeDefaults.checkmarkSize!;

  // Checkmark icon style — size from the ladder, ink from the default
  // partial (or the disabled ramp's token), per-instance override last.
  // The disabled ink is baked here rather than selected in the widget:
  // the `Icon` reads a single slot, and a disabled checked box whose
  // mark stayed `onPrimary` over the disabled container painted its mark
  // invisibly.
  final disabledCheckmarkColor =
      merged.disabledCheckmarkColor ??
      CoreCheckboxStyle.defaultDisabledCheckmarkColor;
  final checkmarkIconStyle = CoreIconStyle(size: checkmarkSize)
      .merge(CoreCheckboxStyle.defaultCheckmarkIconStyle)
      .merge(merged.checkmarkIconStyle)
      .merge(enabled ? null : CoreIconStyle(color: disabledCheckmarkColor));
  final checkmarkColorEmit = emitColor(
    checkmarkIconStyle.color,
    CoreCheckboxStyle.defaultCheckmarkIconStyle.color!,
    .text,
  );

  // Label text style — single emit path (web-specifics.md emit family).
  // The per-state foreground colour is baked into the merged style up
  // front: enabled reads the label slot colour (override else the default
  // `onSurface`), disabled forces `disabledForegroundColor` unless the
  // caller overrides the label colour. `emitTypography` then emits the
  // `text-{role}` class + the colour (token → class, raw → inline) + any
  // explicit font / weight / spacing overlay inline — no manual role-class
  // construction, no `scheme.resolve` (a no-op on Web).
  final disabledForegroundColor =
      merged.disabledForegroundColor ??
      CoreCheckboxStyle.defaultDisabledForegroundColor;
  final overrideLabelColor = merged.labelStyle?.color;
  final effectiveLabelColor = enabled
      ? (overrideLabelColor ?? CoreCheckboxStyle.defaultLabelStyle.color!)
      : (overrideLabelColor ?? disabledForegroundColor);
  //
  // `sizeDefaults.labelStyle` sits between the default and the override:
  // the default carries the role and colour, the size table carries only
  // this size's `fontSize`. Reading it is what makes the size axis reach
  // the text.
  final labelStyleForEmit = CoreCheckboxStyle.defaultLabelStyle
      .merge(sizeDefaults.labelStyle)
      .merge(merged.labelStyle)
      .copyWith(color: effectiveLabelColor);
  final labelEmit = emitTypography(
    labelStyleForEmit,
    CoreCheckboxStyle.defaultLabelStyle,
  );
  final minHeight = merged.minHeight ?? CoreCheckboxStyle.defaultMinHeight;

  // Description — same three-step chain, quieter default foreground, and
  // the same disabled fold onto `disabledForegroundColor`.
  final overrideDescriptionColor = merged.descriptionStyle?.color;
  final effectiveDescriptionColor = enabled
      ? (overrideDescriptionColor ??
            CoreCheckboxStyle.defaultDescriptionStyle.color!)
      : (overrideDescriptionColor ?? disabledForegroundColor);
  final descriptionStyleForEmit = CoreCheckboxStyle.defaultDescriptionStyle
      .merge(sizeDefaults.descriptionStyle)
      .merge(merged.descriptionStyle)
      .copyWith(color: effectiveDescriptionColor);
  final descriptionEmit = emitTypography(
    descriptionStyleForEmit,
    CoreCheckboxStyle.defaultDescriptionStyle,
  );
  final labelDescriptionGapStyle = CoreCheckboxStyle
      .defaultLabelDescriptionGapStyle
      .merge(
        merged.labelDescriptionGapStyle,
      );

  // Resolved chrome values.
  final boxSize = merged.boxSize ?? sizeDefaults.boxSize!;
  final indeterminateLength =
      merged.indeterminateLength ?? sizeDefaults.indeterminateLength!;
  final markThickness =
      merged.markThickness ?? CoreCheckboxStyle.defaultMarkThickness;
  final indeterminateBorderRadius =
      merged.indeterminateBorderRadius ??
      CoreCheckboxStyle.defaultIndeterminateBorderRadius;
  // Nested `CoreGapStyle` slot — merge the size-bucket default with the
  // per-instance override and forward straight to `Gap` (mirrors the
  // Flutter resolver). `Gap` runs its own resolve / scaling step, so
  // this slot stays in pre-scaling units.
  final indicatorLabelGapStyle =
      (sizeDefaults.indicatorLabelGapStyle ??
              CoreCheckboxStyle.defaultIndicatorLabelGapStyle)
          .merge(merged.indicatorLabelGapStyle);
  // Border width — a caller-supplied width rides inline (an arbitrary
  // `1.25` has no `border-strokeN` class), the default rides the class.
  final boxBorderWidthEmit = emitStrokeWidth(
    merged.boxBorderWidth,
    CoreCheckboxStyle.defaultBoxBorderWidth,
  );
  final borderRadius =
      merged.boxBorderRadius ?? CoreCheckboxStyle.defaultBoxBorderRadius;
  // State-transition duration — `merged.transitionDuration` override wins,
  // else the design-system default. Emitted inline (single inline
  // signature — arbitrary ms has no Tailwind `duration-N` class) so the
  // box colour fade + glyph scale / opacity all share one source.
  final transitionMs =
      (merged.transitionDuration ?? CoreCheckboxStyle.defaultTransitionDuration)
          .inMilliseconds;
  // Token-routed duration + easing (`durationMsCss` / `toVarCss` docs) so
  // the box colour fade + glyph scale / opacity all route through the
  // same `--coui-duration-*` / `--easing-*` variables a future systemic
  // override would retime, instead of raw `${ms}ms ease-in-out` literals.
  final transitionDurationCss = durationMsCss(transitionMs);
  final transitionEasingCss = CoreEasing.move.toVarCss();

  final isChecked = checked ?? false;
  final isIndet = checked == null;
  final isActive = isChecked || isIndet;

  // Box fill / border — one emit per axis through the emit family, keyed
  // on the value the widget states (disabled → active → resting). The
  // active border reuses the active fill so the stroke blends into it.
  final activeColor =
      merged.boxActiveColor ?? CoreCheckboxStyle.defaultBoxActiveColor;
  final Emit boxFillEmit;
  final Emit boxBorderEmit;
  if (!enabled) {
    boxFillEmit = emitColor(
      merged.disabledBackgroundColor,
      CoreCheckboxStyle.defaultDisabledBackgroundColor,
      .background,
    );
    boxBorderEmit = emitColor(
      merged.disabledBorderColor,
      CoreCheckboxStyle.defaultDisabledBorderColor,
      .border,
    );
  } else if (isActive) {
    boxFillEmit = emitColor(activeColor, activeColor, .background);
    boxBorderEmit = emitColor(activeColor, activeColor, .border);
  } else {
    boxFillEmit = emitColor(
      merged.boxBackgroundColor,
      CoreCheckboxStyle.defaultBoxBackgroundColor,
      .background,
    );
    boxBorderEmit = emitColor(
      merged.boxBorderColor,
      CoreCheckboxStyle.defaultBoxBorderColor,
      .border,
    );
  }
  final restingFill =
      merged.boxBackgroundColor ?? CoreCheckboxStyle.defaultBoxBackgroundColor;

  // ─── Local builders ───────────────────────────────────

  /// Builds the content wrapper `<span>` Tailwind classes.
  ///
  /// Label typography role + colour come from the single [labelEmit]
  /// (`emitTypography`) — the `text-{role}` class plus the token colour
  /// class (the per-state foreground baked into `labelStyleForEmit`). Any
  /// raw colour / scalar font overlay rides inline (see
  /// [buildRootInlineStyles]).
  ///
  /// Interaction chrome (cursor / select-none / press-shrink) is owned by
  /// the composing `Clickable` — the wrapper is pure content, mirroring
  /// the Flutter twin's `Clickable(child: Row(…))`.
  ///
  /// The indicator↔label gap is rendered as an explicit `Gap` child
  /// in the widget (Web/Flutter parity), so no `gap-spaceN` class is
  /// emitted here.
  String buildRootClassName() {
    final classList = [
      // Top-aligned once a description is present — the canvas states
      // `counterAxisAlignItems: MIN`, and centring the box against a
      // two-line block floats it against neither line. Without one the
      // row keeps `items-center`, which is what it always rendered.
      if (hasDescription)
        '${WebLayout.inlineFlex} ${WebLayout.itemsStart}'
      else
        WebLayout.inlineFlexItemsCenter,
      // Shrinkable flex item inside the Clickable so a long label
      // wraps within the pane instead of growing past it (the box is
      // `shrink-0`; the label wrapper below owns the wrap).
      WebLayout.maxWFull,
      WebLayout.minWZero,
      labelEmit.className,
    ];
    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Inline CSS for the content wrapper — the [labelEmit] inline bundle
  /// (raw colour / scalar font overlay only; token role + colour stay on
  /// classes in [buildRootClassName]).
  Styles? buildRootInlineStyles() {
    final inline = {
      ...?labelEmit.inline,
      // The whole row is the press area, so a stated floor goes here.
      // Nothing at the default — the row renders as it always has.
      if (minHeight > 0) 'min-height': '${minHeight / kRemDivisor}rem',
    };
    return inline.isEmpty ? null : Styles(raw: inline);
  }

  /// Builds the checkbox box (square) Tailwind classes. Border radius is
  /// **always** emitted inline (single inline signature) — only the
  /// colour / structure utility classes live here. The fill /
  /// border classes are whatever the emit family chose (token → class,
  /// raw → inline, see [buildBoxInlineStyles]).
  String buildBoxClassName() {
    final classList = <String>[
      kCheckboxBoxMarker,
      // States no shadow of its own, so it takes the style's — the
      // Flutter twin reads the same cast.
      kControlShadowRestMarker,
      boxBorderWidthEmit.className,
      boxFillEmit.className,
      boxBorderEmit.className,
      // Marks the resting box as a component surface — restated here
      // rather than composing an `OutlinedContainer` Web widget (a DOM
      // restructure) because the box is a single `<div>` with no nested
      // chrome to delegate; the Flutter twin composes the primitive for
      // the same state. Only the resting branch carries it: a checkmark
      // or dash rides on the checked / disabled fill and needs it to stay
      // legible, so those states are never marked.
      if (enabled && !isActive) ...webSurfaceMarkerFor(.content),
      // `relative` so the inner stack of check / indeterminate glyphs
      // (`absolute inset-0`) and the halo `::before` anchor to the
      // checkbox box, not to a higher containing block. Cursor is owned
      // by the composing `Clickable` root and inherits down.
      WebLayout.relative,
      WebLayout.flex,
      WebLayout.itemsCenter,
      WebLayout.justifyCenter,
      WebLayout.shrinkZero,
      // The box is 12, 14 or 16 at the smaller sizes, below the WCAG
      // minimum pointer target. This extends where a pointer is accepted
      // and draws nothing — the box still renders at its own size, and
      // a pointer on the extension reaches the composing `Clickable`.
      kWebTouchTargetMarker,
    ];
    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Inline CSS for the checkbox box — always-inline border radius +
  /// state-transition rule, plus whatever the fill / border emit routed
  /// inline (a raw override, or the transparent resting fill). The box
  /// colour transition duration matches the inner glyph transition so
  /// the checkmark fade-out stays visible against the receding active
  /// background (mirrors Flutter's `AnimatedContainer(duration:
  /// transitionDuration)`).
  Styles buildBoxInlineStyles() {
    final raw = <String, String>{};
    raw['width'] = _checkboxSizeCss(boxSize);
    raw['height'] = _checkboxSizeCss(boxSize);
    raw['border-radius'] = borderRadius.toValue();
    raw['transition'] =
        'background-color $transitionDurationCss $transitionEasingCss, '
        'border-color $transitionDurationCss $transitionEasingCss';
    raw
      ..addAll(boxFillEmit.inline ?? const {})
      ..addAll(boxBorderEmit.inline ?? const {})
      ..addAll(boxBorderWidthEmit.inline ?? const {});
    // The other half of the surface marker above — publishes the fill
    // this state chose so a material preset can restate it at its own
    // alpha. Empty (no-op) when the resting fill carries no token.
    if (enabled && !isActive) {
      raw
        ..addAll(surfaceFillVar(restingFill))
        // The line's width, so the material's edge band reaches the outside
        // of the border instead of one border inside it.
        ..addAll(
          surfaceBleedVar(
            strokeWidthCss(
              merged.boxBorderWidth ?? CoreCheckboxStyle.defaultBoxBorderWidth,
            ),
          ),
        );
    }
    return Styles(raw: raw);
  }

  /// Builds the glyph-stack `<span class="contents">` className. The
  /// wrapper carries no own styles, just hosts the two stacked glyphs.
  String buildGlyphStackClassName() => WebLayout.contents;

  /// Builds the check (✓) glyph slot Tailwind classes.
  ///
  /// Both glyphs are mounted simultaneously and positioned with
  /// `absolute inset-0` inside the (relative) checkbox box so they
  /// stack on top of each other. Value controls the visible one via
  /// `scale-100` (visible) ↔ `scale-0 pointer-events-none` (hidden); the
  /// transition timing itself is emitted inline (see
  /// [buildCheckGlyphInlineStyles]) over [transitionMs] to mirror
  /// Flutter's `AnimatedScale(duration: transitionDuration)`. Timing is
  /// inline rather than a bare `ease-in-out` class — that Tailwind class
  /// rides Tailwind's own built-in `in-out` curve, not `CoreEasing.move`.
  /// The ink is whatever the emit family chose for the icon slot's colour
  /// (token → `text-*` class, raw → inline).
  String buildCheckGlyphClassName() {
    final stateClass = isChecked
        ? 'scale-100 opacity-100'
        : 'scale-0 opacity-0 ${WebLayout.pointerEventsNone}';
    return '${WebLayout.absolute} ${WebLayout.insetZero} ${WebLayout.flex} '
        '${WebLayout.itemsCenter} ${WebLayout.justifyCenter}'
        ' transform-gpu transition-all origin-center'
        ' ${checkmarkColorEmit.className} $stateClass';
  }

  /// Inline CSS for the check glyph — always-inline transition timing
  /// (duration + easing, both token-routed) plus a raw icon colour
  /// override.
  Styles buildCheckGlyphInlineStyles() {
    final raw = <String, String>{};
    raw['transition-duration'] = transitionDurationCss;
    raw['transition-timing-function'] = transitionEasingCss;
    raw.addAll(checkmarkColorEmit.inline ?? const {});
    return Styles(raw: raw);
  }

  /// Builds the indeterminate (▬) glyph slot Tailwind classes. No colour
  /// class — the inner [indicator] carries the fill. Transition timing is
  /// emitted inline (see [buildIndeterminateGlyphInlineStyles]) for the
  /// same reason as [buildCheckGlyphClassName] — no bare `ease-in-out`
  /// class.
  String buildIndeterminateGlyphClassName() {
    final stateClass = isIndet
        ? 'scale-100 opacity-100'
        : 'scale-0 opacity-0 ${WebLayout.pointerEventsNone}';
    return '${WebLayout.absolute} ${WebLayout.insetZero} ${WebLayout.flex} '
        '${WebLayout.itemsCenter} ${WebLayout.justifyCenter}'
        ' transform-gpu transition-all origin-center'
        ' $stateClass';
  }

  /// Inline CSS for the indeterminate glyph slot — always-inline
  /// transition timing (mirrors the check glyph).
  Styles buildIndeterminateGlyphInlineStyles() => .new(
    raw: {
      'transition-duration': transitionDurationCss,
      'transition-timing-function': transitionEasingCss,
    },
  );

  // The dash's fill is the same ink as the checkmark — the icon slot's
  // colour, as a background this time.
  final dashFillEmit = emitColor(
    checkmarkIconStyle.color,
    CoreCheckboxStyle.defaultCheckmarkIconStyle.color!,
    .background,
  );

  /// The indeterminate dash's fill class; its dimensions ride inline.
  String buildIndicatorClassName() => dashFillEmit.className;

  /// Inline CSS for the indeterminate dash — the mark thickness as its
  /// height (rem, so it follows the root font size like every other
  /// dimension), the pill corner, and a raw fill override.
  Styles buildIndicatorInlineStyles() => .new(
    raw: {
      'width': _checkboxSizeCss(indeterminateLength),
      'height': '${markThickness / kRemDivisor}rem',
      'border-radius': indeterminateBorderRadius.toValue(),
      ...?dashFillEmit.inline,
    },
  );

  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreCheckboxStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── Compose paint-ready chrome ───────────────────────
  /// Builds the description line's Tailwind classes — its own
  /// `text-{role}` + colour class, which override the label typography
  /// the root wrapper puts on the whole row.
  String buildDescriptionClassName() {
    final classList = [WebLayout.minWZero, descriptionEmit.className];
    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Inline CSS for the description line — the raw colour / scalar font
  /// overlay only (token role + colour stay on classes above).
  Styles? buildDescriptionInlineStyles() {
    final inline = descriptionEmit.inline;
    return inline == null ? null : Styles(raw: inline);
  }

  return ResolvedCheckbox(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    box: WebElementChrome(
      className: buildBoxClassName(),
      inlineStyles: buildBoxInlineStyles(),
    ),
    glyphStack: WebElementChrome(className: buildGlyphStackClassName()),
    checkGlyph: WebElementChrome(
      className: buildCheckGlyphClassName(),
      inlineStyles: buildCheckGlyphInlineStyles(),
    ),
    indeterminateGlyph: WebElementChrome(
      className: buildIndeterminateGlyphClassName(),
      inlineStyles: buildIndeterminateGlyphInlineStyles(),
    ),
    indicator: WebElementChrome(
      className: buildIndicatorClassName(),
      inlineStyles: buildIndicatorInlineStyles(),
    ),
    checkmarkIconStyle: checkmarkIconStyle,
    clickableStyle: clickableStyle,
    indicatorLabelGapStyle: indicatorLabelGapStyle,
    labelWrapper: WebElementChrome(
      className: hasDescription
          // Two lines stack, so the wrapper becomes the canvas's
          // `content` column. The gap between them is an explicit `Gap`
          // child (Flutter parity), not a `gap-*` class.
          ? '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.itemsStart} '
                '${WebLayout.minWZero}'
          : WebLayout.minWZero,
    ),
    description: WebElementChrome(
      className: buildDescriptionClassName(),
      inlineStyles: buildDescriptionInlineStyles(),
    ),
    labelDescriptionGapStyle: labelDescriptionGapStyle,
  );
}

// ═══════════════════════════════════════════════════
// State layer + focus ring — scoped pseudo-state rules
// ═══════════════════════════════════════════════════

/// Scoped CSS text plus the class it is keyed to, for the `<style>` block
/// and the `Clickable` root's classList in `checkbox.dart`.
///
/// Both empty when the checkbox is disabled — a disabled box neither
/// washes nor takes focus, and its rest chrome IS its disabled chrome.
class ResolvedCheckboxRules {
  /// Creates a [ResolvedCheckboxRules].
  const ResolvedCheckboxRules({required this.scopeClass, required this.css});

  /// Class the `Clickable` root wears, and the class the CSS text below
  /// selects on. Empty exactly when [css] is empty — the pair travels
  /// together, never one without the other.
  final String scopeClass;

  /// Raw CSS rule text — empty on the disabled path.
  final String css;
}

/// Resolves the halo + focus-ring rules for one checkbox instance.
///
/// Re-walks the same merge chain [resolveCheckbox] runs — the chrome
/// composed there and the rules composed here have to see the same
/// resolved values, or the box wears a class the rules don't match.
///
/// Two things ride on the box's `::before` and `outline`, both keyed on
/// the pseudo-classes the `Clickable` root receives:
///
/// * the halo — a `::before` reaching `stateLayerSpread` beyond the box
///   with its own corner, transparent at rest and washed with
///   `stateLayerColor` at the ramp's hover / pressed weight (`:hover` /
///   `:active`, strongest last so pressed wins over hover);
/// * the focus ring — `focusRingScopedRule` aimed at the box: an
///   `outline` whose offset is the gap (transparent by default, so the
///   page shows through it — the same geometry `FocusOutline` draws on
///   Flutter), plus a `box-shadow` band only when the slot states a
///   painted one. A band composes over the box's resting cast so it does
///   not erase it.
ResolvedCheckboxRules resolveCheckboxRules(
  BuildContext context, {
  required bool enabled,
  CoreCheckboxStyle? checkboxStyle,
}) {
  if (!enabled) return const ResolvedCheckboxRules(scopeClass: '', css: '');

  final merged = _mergedCheckboxStyle(context, checkboxStyle);

  final layer = merged.stateLayer ?? CoreCheckboxStyle.defaultStateLayer;
  final ink =
      merged.stateLayerColor ?? CoreCheckboxStyle.defaultStateLayerColor;
  final spread =
      merged.stateLayerSpread ?? CoreCheckboxStyle.defaultStateLayerSpread;
  // The box's own stroke. The halo's `::before` is absolutely positioned,
  // so its inset is measured from the box's *padding* box — the stroke's
  // width inside the border box. Reaching `spread` beyond the border box
  // (where the Flutter twin's halo reaches, off the outer box) takes the
  // stroke on top of the spread.
  final boxBorderWidth =
      merged.boxBorderWidth ?? CoreCheckboxStyle.defaultBoxBorderWidth;
  final haloRadius =
      merged.stateLayerBorderRadius ??
      CoreCheckboxStyle.defaultStateLayerBorderRadius;
  final transitionMs =
      (merged.transitionDuration ?? CoreCheckboxStyle.defaultTransitionDuration)
          .inMilliseconds;
  final transitionCss =
      '${durationMsCss(transitionMs)} '
      '${CoreEasing.move.toVarCss()}';

  // The ring — the checkbox's own `focusOutlineStyle` slot over its
  // complete default (the system focus recipe), the same values the
  // Flutter twin hands `FocusOutline` around the box. The corner is not
  // read: an `outline` follows the box's own corner.
  final ringSlot = CoreCheckboxStyle.defaultFocusOutlineStyle.merge(
    merged.focusOutlineStyle,
  );
  final ringWidth = ringSlot.borderWidth!;
  final ringOffset = ringSlot.align! - ringWidth;
  final ringColor = ringSlot.borderColor!;
  final ringOffsetColor = ringSlot.offsetColor!;
  final ringOpacity = ringSlot.ringOpacity!;

  // Content-addressed off the exact values the rules below depend on —
  // two checkboxes that resolve identically share one class and one rule
  // instead of emitting a duplicate per instance.
  final seed =
      '${ink.token?.name}|${ink.argb}|${ink.opacity}'
      '|${layer.hover}|${layer.pressed}'
      '|$spread|$boxBorderWidth|${haloRadius.toValue()}|$transitionMs'
      '|${ringColor.token?.name}|${ringColor.argb}|${ringColor.opacity}'
      '|${ringOffsetColor.token?.name}|${ringOffsetColor.argb}'
      '|${ringOffsetColor.opacity}'
      '|$ringWidth|$ringOffset|$ringOpacity';
  final scopeClass =
      'co-checkbox-sl-${seed.hashCode.toRadixString(36).replaceAll('-', 'n')}';

  final scope = '.$scopeClass';
  const box = ' .$kCheckboxBoxMarker';
  final spreadRem = spread / kRemDivisor;
  // Theme-free `.toValue()` — token → `rgb(var(--coui-X) / NN%)`, raw →
  // rgba; the weight is the ramp's, the ink keeps its own hue.
  final restCss = ink.withOpacity(0).toValue();
  final hoverCss = ink.scaleAlpha(layer.hover).toValue();
  final pressedCss = ink.scaleAlpha(layer.pressed).toValue();

  final haloInset =
      'calc(-${spreadRem}rem - ${strokeWidthCss(boxBorderWidth)})';

  final buffer = StringBuffer()
    // The halo's body — always present so the wash tweens in place.
    ..write(
      '$scope$box::before{content:"";position:absolute;'
      'inset:$haloInset;border-radius:${haloRadius.toValue()};'
      'background-color:$restCss;pointer-events:none;'
      'transition:background-color $transitionCss;}',
    )
    // hover → pressed, so equal-specificity ties resolve to the later
    // rule — a pressed box does not step back to its hover wash while
    // the pointer is still over it.
    ..write('$scope:hover$box::before{background-color:$hoverCss;}')
    ..write('$scope:active$box::before{background-color:$pressedCss;}')
    // The ring — an outline on the box itself (plus the band, when one
    // paints, over the box's resting cast).
    ..write(
      focusRingScopedRule(
        scopeSelector: scope,
        pseudo: .focusVisible,
        target: box,
        ringColor: ringColor,
        offsetColor: ringOffsetColor,
        ringWidth: ringWidth,
        ringOffset: ringOffset,
        ringOpacity: ringOpacity,
        restShadow: kControlShadowVar,
      ),
    );

  return ResolvedCheckboxRules(scopeClass: scopeClass, css: buffer.toString());
}

/// The one merge chain both resolvers walk — theme style, then the
/// per-instance override.
CoreCheckboxStyle _mergedCheckboxStyle(
  BuildContext context,
  CoreCheckboxStyle? checkboxStyle,
) {
  final csTheme = context.theme.coreComponentTheme?.checkbox;
  return resolveStyleChain(const CoreCheckboxStyle(), [
    csTheme?.style,
    checkboxStyle,
  ]);
}
