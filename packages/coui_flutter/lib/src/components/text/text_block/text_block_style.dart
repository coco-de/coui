import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Element → base typography style
// ═══════════════════════════════════════════════════

/// Maps a [CoreTextBlockElement] to its base Flutter [TextStyle].
///
/// This half of the mapping is typography only — the heading level the
/// same element states to assistive technology is applied by `TextBlock`
/// itself, so a heading is both larger and announced. Heading levels map
/// here to the display / headline / title scale; `strong` / `em` /
/// `small` carry the matching weight / style / size.
///
/// The two roles that draw a box state their own text — [blockQuote] for
/// `blockquote`, [inlineCode] for `pre` — because that text (role and
/// colour) is a design-system default of `CoreTextBlockStyle`, not a
/// property of the element name. They arrive already resolved.
///
/// The result is the *base* style — [resolveTextBlock] then layers any
/// [TextBlockStyle] presets on top via [_mergeTextBlockPresets].
TextStyle _textBlockElementStyle(
  CoreTextBlockElement element,
  CoreTypography typography,
  ThemeData theme, {
  required TextStyle blockQuote,
  required TextStyle inlineCode,
}) {
  TextStyle role(CoreTextStyle style) => style.toValue(theme: theme);
  return switch (element) {
    .p || .span => role(typography.bodyMedium),
    .blockquote => blockQuote,
    .h1 => role(typography.displaySmall),
    .h2 => role(typography.headlineLarge),
    .h3 => role(typography.headlineSmall),
    .h4 => role(typography.titleLarge),
    .h5 => role(typography.titleMedium),
    .h6 => role(typography.titleSmall),
    .pre => inlineCode,
    .label => role(typography.labelLarge),
    .strong => role(
      typography.bodyMedium,
    ).merge(TextStyle(fontWeight: CoreFontWeight.bold.weight)),
    .em => role(
      typography.bodyMedium,
    ).merge(const TextStyle(fontStyle: .italic)),
    .small => role(typography.bodySmall),
  };
}

// ═══════════════════════════════════════════════════
// Typography preset — value class
// ═══════════════════════════════════════════════════

/// A typography preset for [TextBlock].
///
/// Flutter mirror of `coui_web`'s `TextBlockStyle`. Where the Web
/// preset carries a resolved Tailwind class string, the Flutter preset
/// carries a resolved [TextStyle] fragment that is merged onto the
/// element's base style. Presets compose left-to-right — later presets
/// win on conflicting fields ([TextStyle.merge] semantics).
///
/// Construct presets through the static helpers on [TextBlock]
/// (`TextBlock.paragraph`, `TextBlock.heading1(context)`, …) rather
/// than instantiating this class directly.
@immutable
class TextBlockStyle {
  /// Creates a [TextBlockStyle] from a resolved [TextStyle] fragment.
  const TextBlockStyle(this.style);

  /// The resolved [TextStyle] fragment for this preset.
  final TextStyle style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextBlockStyle &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}

// ═══════════════════════════════════════════════════
// Preset assembly — top-level private function
// ═══════════════════════════════════════════════════

/// Merges the [presets] of a [TextBlock] onto [base].
///
/// Mirrors `coui_web`'s `buildTextBlockClassName`: an empty / null
/// preset list leaves [base] untouched, otherwise each preset's
/// [TextStyle] fragment is merged in order so later presets win.
TextStyle _mergeTextBlockPresets(
  TextStyle base,
  List<TextBlockStyle>? presets,
) {
  if (presets == null || presets.isEmpty) return base;
  var merged = base;
  for (final preset in presets) {
    merged = merged.merge(preset.style);
  }
  return merged;
}

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `TextBlock`.
///
/// Widget tree (`text_block.dart` decides which branch renders for
/// the chosen [CoreTextBlockElement]):
///
/// ```text
/// switch (element)
///   ├─ blockquote → DecoratedBox (left accent border)
///   │                 └─ Padding (blockQuotePadding)
///   │                      └─ Text | DefaultTextStyle.merge(children)
///   ├─ pre        → DecoratedBox (surface box + radius)
///   │                 └─ Padding (inlineCodePadding)
///   │                      └─ Text | DefaultTextStyle.merge(children)
///   └─ else       → Text | DefaultTextStyle.merge(children)
/// ```
///
/// Field grouping:
///
/// 1. **Typography** — [textStyle] is the element base typography with
///    the [TextBlockStyle] presets merged in (`DefaultTextStyle.merge`
///    for children, `Text.style` for plain text). For `blockquote` and
///    `pre` the base is the `CoreTextBlockStyle` text slot of that role.
/// 2. **Blockquote chrome** — left accent border colour / width and the
///    indent padding, all paint-ready Flutter types.
/// 3. **Inline-code chrome** — surface background colour, corner radius
///    and the box padding, all paint-ready Flutter types.
class ResolvedTextBlock {
  /// Creates a [ResolvedTextBlock].
  const ResolvedTextBlock({
    required this.textStyle,
    required this.blockQuoteBorderColor,
    required this.blockQuoteBorderWidth,
    required this.blockQuotePadding,
    required this.inlineCodeBackgroundColor,
    required this.inlineCodeRadius,
    required this.inlineCodePadding,
  });

  // ── Typography ──────────────────────────────────────────────

  /// Paint-ready [TextStyle] — element base typography with every
  /// [TextBlockStyle] preset merged on top.
  final TextStyle textStyle;

  // ── Blockquote chrome ───────────────────────────────────────

  /// Left accent-border colour for the `blockquote` element.
  final Color blockQuoteBorderColor;

  /// Left accent-border stroke width for the `blockquote` element
  /// (logical px).
  final double blockQuoteBorderWidth;

  /// Left indent between the `blockquote` accent border and its text.
  final EdgeInsetsGeometry blockQuotePadding;

  // ── Inline-code chrome ──────────────────────────────────────

  /// Surface background colour for the `pre` inline-code box, resolved
  /// from the `surfaceContainer` design-system token.
  final Color inlineCodeBackgroundColor;

  /// Corner radius of the `pre` inline-code surface box.
  final BorderRadius inlineCodeRadius;

  /// Padding inside the `pre` inline-code surface box.
  final EdgeInsets inlineCodePadding;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTextBlock] for the given [context].
///
/// Walks the typography path ([element] base + [presets]) and the chrome
/// merge chain, applying the `CoreTextBlockStyle.defaultX` static const
/// fallback so the widget reads only fully-resolved Flutter-typed values:
///
/// ```text
/// CoreTextBlockStyle.defaultX           // design system default
///   → widget.textBlockStyle             // per-instance override
/// ```
///
/// `blockQuoteBorderColor` and `inlineCodeBackgroundColor` flow through
/// the `CoreTextBlockStyle.default{...}Color` design-system token
/// defaults (`outlineVariant` / `surfaceContainer`), resolved to a
/// paint-ready Flutter `Color` via `scheme.resolve(token).toValue()` so
/// they stay the single source of truth shared with Web's
/// `rgb(var(--coui-outline-variant))` / `rgb(var(--coui-surface-container))`.
///
/// `blockQuoteTextStyle` and `inlineCodeTextStyle` are composite slots, so
/// they follow the `default.merge(merged)` form (a caller who states only a
/// colour keeps the default role) and resolve through
/// `toValue(theme: theme)`, which also resolves the colour token.
ResolvedTextBlock resolveTextBlock(
  BuildContext context, {
  required CoreTextBlockElement element,
  List<TextBlockStyle>? presets,
  CoreTextBlockStyle? textBlockStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;

  // ─── Merge chain (design default → instance) ──────────
  final merged = resolveStyleChain(const CoreTextBlockStyle(), [
    textBlockStyle,
  ]);

  // ─── Typography (Stage1 RESOLVE → Stage2 EMIT, local) ──
  final blockQuoteTextStyle = CoreTextBlockStyle.defaultBlockQuoteTextStyle
      .merge(merged.blockQuoteTextStyle)
      .toValue(theme: theme);
  final inlineCodeTextStyle = CoreTextBlockStyle.defaultInlineCodeTextStyle
      .merge(merged.inlineCodeTextStyle)
      .toValue(theme: theme);
  final base = _textBlockElementStyle(
    element,
    theme.typography,
    theme,
    blockQuote: blockQuoteTextStyle,
    inlineCode: inlineCodeTextStyle,
  );
  final textStyle = _mergeTextBlockPresets(base, presets);

  // ─── Blockquote chrome (Stage1 RESOLVE → Stage2 EMIT, local) ──
  final blockQuoteBorderColor = scheme
      .resolve(
        merged.blockQuoteBorderColor ??
            CoreTextBlockStyle.defaultBlockQuoteBorderColor,
      )
      .toValue();
  final blockQuoteBorderWidth = theme.geometry.stroke(
    merged.blockQuoteBorderWidth ??
        CoreTextBlockStyle.defaultBlockQuoteBorderWidth,
    scaling: scaling,
  );
  final blockQuotePadding =
      (merged.blockQuotePadding ?? CoreTextBlockStyle.defaultBlockQuotePadding)
          .toGeometry(geometry: theme.geometry) *
      scaling;

  // ─── Inline-code chrome (Stage1 RESOLVE → Stage2 EMIT, local) ──
  final inlineCodeBackgroundColor = scheme
      .resolve(
        merged.inlineCodeBackgroundColor ??
            CoreTextBlockStyle.defaultInlineCodeBackgroundColor,
      )
      .toValue();
  final inlineCodeRadius = BorderRadius.circular(
    theme.geometry.radius(
          merged.inlineCodeRadius ?? CoreTextBlockStyle.defaultInlineCodeRadius,
        ) *
        scaling,
  );
  final inlineCodePadding =
      (merged.inlineCodePadding ?? CoreTextBlockStyle.defaultInlineCodePadding)
          .toValue(geometry: theme.geometry) *
      scaling;

  return ResolvedTextBlock(
    textStyle: textStyle,
    blockQuoteBorderColor: blockQuoteBorderColor,
    blockQuoteBorderWidth: blockQuoteBorderWidth,
    blockQuotePadding: blockQuotePadding,
    inlineCodeBackgroundColor: inlineCodeBackgroundColor,
    inlineCodeRadius: inlineCodeRadius,
    inlineCodePadding: inlineCodePadding,
  );
}
