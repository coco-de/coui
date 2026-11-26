import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Element → semantic HTML tag
// ═══════════════════════════════════════════════════

/// Maps a [CoreTextBlockElement] to its semantic HTML tag name.
String textBlockElementTag(CoreTextBlockElement element) => switch (element) {
  .p => 'p',
  .span => 'span',
  .h1 => 'h1',
  .h2 => 'h2',
  .h3 => 'h3',
  .h4 => 'h4',
  .h5 => 'h5',
  .h6 => 'h6',
  .blockquote => 'blockquote',
  .pre => 'pre',
  .label => 'label',
  .strong => 'strong',
  .em => 'em',
  .small => 'small',
};

// ═══════════════════════════════════════════════════
// Typography preset — value class (no Styling marker)
// ═══════════════════════════════════════════════════

/// A typography preset for [TextBlock].
///
/// Replaces the legacy `TextBlockStyle` / `TextBlockStyling` marker
/// pair (Phase 6g — Styling marker sweep). A preset is now a plain
/// immutable value holding the resolved Tailwind class string; the
/// [TextBlock] widget joins the preset class strings into its root
/// element via [buildTextBlockClassName].
///
/// Construct presets through the static helpers on [TextBlock]
/// (`TextBlock.paragraph`, `TextBlock.heading1(context)`, …)
/// rather than instantiating this class directly.
@immutable
class TextBlockStyle {
  /// Creates a [TextBlockStyle] from a resolved Tailwind class string.
  const TextBlockStyle(this.classes);

  /// The resolved Tailwind class string for this preset.
  final String classes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextBlockStyle &&
          runtimeType == other.runtimeType &&
          classes == other.classes;

  @override
  int get hashCode => classes.hashCode;
}

// ═══════════════════════════════════════════════════
// Element → base typography classes
// ═══════════════════════════════════════════════════

/// Maps a [CoreTextBlockElement] to its base typography Tailwind
/// classes — the Web mirror of the Flutter twin's element→role switch,
/// so `TextBlock(element: …)` renders the same type scale on both
/// platforms without the caller supplying presets. Heading levels map
/// to the display / headline / title scale; `strong` / `em` / `small`
/// carry the matching weight / style / size.
///
/// The two roles that draw a box state their own text — [blockQuote] for
/// `blockquote`, [inlineCode] for `pre` — because that text (role and
/// colour) is a design-system default of `CoreTextBlockStyle`, not a
/// property of the element name. They arrive as already-emitted class
/// strings.
String textBlockElementClassName(
  CoreTextBlockElement element, {
  required String blockQuote,
  required String inlineCode,
}) => switch (element) {
  .p || .span => 'text-${CoreTextStyles.bodyMedium.name}',
  .blockquote => blockQuote,
  .h1 => 'text-${CoreTextStyles.displaySmall.name}',
  .h2 => 'text-${CoreTextStyles.headlineLarge.name}',
  .h3 => 'text-${CoreTextStyles.headlineSmall.name}',
  .h4 => 'text-${CoreTextStyles.titleLarge.name}',
  .h5 => 'text-${CoreTextStyles.titleMedium.name}',
  .h6 => 'text-${CoreTextStyles.titleSmall.name}',
  .pre => inlineCode,
  .label => 'text-${CoreTextStyles.labelLarge.name}',
  .strong =>
    'text-${CoreTextStyles.bodyMedium.name} '
        'font-${CoreFontWeight.scale.bold}',
  .em => 'text-${CoreTextStyles.bodyMedium.name} italic',
  .small => 'text-${CoreTextStyles.bodySmall.name}',
};

// ═══════════════════════════════════════════════════
// className assembly — top-level pure functions
// ═══════════════════════════════════════════════════

/// Composes a [TextBlock]'s typography className. With [presets] the
/// preset class strings join into a single space-separated string;
/// without them the [element]'s base typography classes apply
/// (mirroring the Flutter twin, whose element base style always
/// underlies the presets). Presets replace the base rather than stack
/// on it — two Tailwind classes on the same axis (`text-*`) would race
/// on stylesheet order, so the overlap is avoided outright and a
/// preset is the complete typography contract.
String buildTextBlockClassName(
  List<TextBlockStyle>? presets, {
  required CoreTextBlockElement element,
  required String blockQuote,
  required String inlineCode,
}) {
  if (presets == null || presets.isEmpty) {
    return textBlockElementClassName(
      element,
      blockQuote: blockQuote,
      inlineCode: inlineCode,
    );
  }
  return presets.map((p) => p.classes).where((c) => c.isNotEmpty).join(' ');
}

// ═══════════════════════════════════════════════════
// Element → box chrome role
// ═══════════════════════════════════════════════════

/// Which of the two box chromes an element role draws.
typedef _TextBlockBoxes = ({bool blockQuote, bool inlineCode});

/// Answers whether [element] draws the `blockquote` accent box or the
/// `pre` inline-code box.
///
/// The Web mirror of the Flutter twin's `switch (element)` in `build`,
/// where `blockquote` renders inside a left-accent `DecoratedBox` and
/// `pre` inside a surface-filled one. Web owns a single styled root
/// instead of a wrapper, so the same two roles fold their chrome into
/// that root's inline CSS — the roles that carry a box are therefore the
/// same on both platforms.
///
/// Exhaustive rather than a pair of `==` comparisons so a new element
/// role cannot be added without stating whether it carries a box.
_TextBlockBoxes _textBlockBoxes(CoreTextBlockElement element) =>
    switch (element) {
      .blockquote => (blockQuote: true, inlineCode: false),
      .pre => (blockQuote: false, inlineCode: true),
      .p ||
      .span ||
      .h1 ||
      .h2 ||
      .h3 ||
      .h4 ||
      .h5 ||
      .h6 ||
      .label ||
      .strong ||
      .em ||
      .small => (blockQuote: false, inlineCode: false),
    };

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `TextBlock`.
///
/// DOM shape:
///
/// ```text
/// root (<p> | <h1>…<h6> | <blockquote> | <pre> | <span> | …)
///   └─ text | …children                  // text_block.dart picks one
/// ```
///
/// `text_block.dart` reads `resolved.root.className` and
/// `resolved.root.inlineStyles` straight off this object — no merge /
/// fallback / conversion in the widget body.
///
/// One styled root carries both axes. The typography axis is the
/// className ([buildTextBlockClassName] — the element's base role, or
/// the caller's presets). The box axis — `blockquote`'s left accent
/// border and indent, `pre`'s surface fill and corner radius — lands in
/// `inlineStyles`, which is also why there is no separate wrapper slot
/// here while the Flutter twin has two wrapper widgets.
class ResolvedTextBlock implements WebResolvedChrome {
  /// Creates a [ResolvedTextBlock].
  const ResolvedTextBlock({required this.root});

  /// Paint-ready chrome for the semantic root element.
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTextBlock] for the given [context].
///
/// Merge chain:
///
/// ```text
/// CoreTextBlockStyle.defaultX          // design-system default
///   → widget.textBlockStyle            // per-instance override
/// ```
///
/// Mirrors the Flutter resolver field for field — the same eight
/// [CoreTextBlockStyle] slots fall back to the same
/// `CoreTextBlockStyle.defaultX` constants, so the accent border, the
/// indent, the surface fill, the corner radius and the text of the two box
/// roles cannot drift between the two platforms. Web emits them
/// theme-free: a token colour reads `rgb(var(--coui-X))` and a token
/// stroke / radius reads `var(--coui-stroke-width-N)` /
/// `var(--coui-radius-N)`, which the browser resolves at runtime, so dark
/// mode stays reactive without a `scheme.resolve` (a no-op on Web).
///
/// The two text slots are composite, so they go through `emitTypography`:
/// the role rides a `text-{role}` class with the token colour on a
/// `text-{colour}` class, and only a caller's explicit scalar overlay lands
/// inline. They are the element's base typography, so — like the element
/// roles — they apply only when no [presets] are given; a preset is the
/// complete typography contract and replaces the base.
ResolvedTextBlock resolveTextBlock(
  BuildContext context, {
  required CoreTextBlockElement element,
  List<TextBlockStyle>? presets,
  CoreTextBlockStyle? textBlockStyle,
}) {
  // ─── Merge chain (design default → instance) ──────────
  final merged = resolveStyleChain(const CoreTextBlockStyle(), [
    textBlockStyle,
  ]);

  final boxes = _textBlockBoxes(element);

  // ─── Text of the two box roles (Stage1 RESOLVE → Stage2 EMIT, local) ──
  final blockQuoteText = emitTypography(
    merged.blockQuoteTextStyle,
    CoreTextBlockStyle.defaultBlockQuoteTextStyle,
  );
  final inlineCodeText = emitTypography(
    merged.inlineCodeTextStyle,
    CoreTextBlockStyle.defaultInlineCodeTextStyle,
  );
  final usesElementBase = presets == null || presets.isEmpty;

  // ─── Blockquote chrome (Stage1 RESOLVE → Stage2 EMIT, local) ──
  //
  // Emitted inline rather than as `border-{token}` / `bg-{token}`
  // classes because the caller can reach the same two surfaces through
  // the `quote` / `inlineCode` typography presets, and two utility
  // classes on one property would race on stylesheet order. An inline
  // token value is still `rgb(var(--coui-X))`, so dark mode stays
  // reactive and a `textBlockStyle` override always wins.
  final blockQuoteBorderColor =
      (merged.blockQuoteBorderColor ??
              CoreTextBlockStyle.defaultBlockQuoteBorderColor)
          .toValue();
  final blockQuoteBorderWidth = strokeWidthCss(
    merged.blockQuoteBorderWidth ??
        CoreTextBlockStyle.defaultBlockQuoteBorderWidth,
  );
  // `padding` longhands rather than the shorthand: the blockquote indent is
  // a reading-direction statement, so its default is a directional inset and
  // the physical shorthand throws on one by construction. A symmetric caller
  // override still comes back as the one-line shorthand.
  final blockQuotePadding =
      (merged.blockQuotePadding ?? CoreTextBlockStyle.defaultBlockQuotePadding)
          .toLogicalDeclarations('padding');

  // ─── Inline-code chrome (Stage1 RESOLVE → Stage2 EMIT, local) ──
  final inlineCodeBackgroundColor =
      (merged.inlineCodeBackgroundColor ??
              CoreTextBlockStyle.defaultInlineCodeBackgroundColor)
          .toValue();
  final inlineCodeRadius = radiusCss(
    merged.inlineCodeRadius ?? CoreTextBlockStyle.defaultInlineCodeRadius,
  );
  final inlineCodePadding =
      (merged.inlineCodePadding ?? CoreTextBlockStyle.defaultInlineCodePadding)
          .toLogicalDeclarations('padding');

  // ─── Local builders ───────────────────────────────────

  /// Composes the root element's Tailwind className — the typography
  /// axis only (the element's base role, or the caller's presets).
  String buildRootClassName() => buildTextBlockClassName(
    presets,
    element: element,
    blockQuote: blockQuoteText.className,
    inlineCode: inlineCodeText.className,
  );

  /// Composes the root element's inline-CSS bundle — the `blockquote`
  /// left accent border with its indent, or the `pre` surface box.
  ///
  /// The border is stated with the three `border-left-*` longhands so
  /// the accent draws on the left edge alone (mirroring Flutter's
  /// `Border(left: …)`) and does not depend on a CSS reset having zeroed
  /// the other three sides. Returns `null` for the element roles that
  /// draw no box, so those keep rendering as bare typography.
  Styles? buildRootInlineStyles() {
    final raw = <String, String>{
      // The caller's explicit scalar overlay on the role's text (empty for
      // the defaults, which are a role + token colour and ride classes).
      // Only while the element base is in force: a preset replaces it.
      if (usesElementBase && boxes.blockQuote) ...?blockQuoteText.inline,
      if (usesElementBase && boxes.inlineCode) ...?inlineCodeText.inline,
      if (boxes.blockQuote) ...{
        // The accent edge stays physical because the Flutter twin draws it
        // with `Border(left: …)`. Making this side logical here would mirror
        // the border in rtl while Flutter's stayed put, which is a new
        // divergence — the border side is the directional axis's next step,
        // not this component's to take alone.
        'border-left-style': 'solid',
        'border-left-width': blockQuoteBorderWidth,
        'border-left-color': blockQuoteBorderColor,
        ...blockQuotePadding,
      },
      if (boxes.inlineCode) ...{
        'background-color': inlineCodeBackgroundColor,
        'border-radius': inlineCodeRadius,
        ...inlineCodePadding,
      },
    };
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedTextBlock(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}
